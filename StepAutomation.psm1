class Method{
    hidden [ScriptBlock] $Function
    hidden [string] $Method
    Method([String]$Method,[scriptBlock]$Function){
        $this.Method = $Method
        $this.Function = $Function
    }
    Execute([System.Object]$Arguments){
        Try{
            Invoke-Command -ScriptBlock $this.Function -ArgumentList $Arguments -ErrorAction Stop
        }catch{
            throw $_
        }
    }
}

class Step{
    [string]$Operation
    [string]$Name
    [int]$Step
    [string]$Value
    [string]$Source
    Step([System.Object]$Step){
        if(!$Step.Name){
            throw "Cannot find Property Name"
        }
        if(!$Step.Step){
            throw "Cannot find Property Step"
        }
        if(!$step.Operation){
            throw "Cannot find Property Operation"
        }
        $this.Operation = $Step.Operation
        $this.Step = $Step.Step
        $this.Name = $Step.Name
        $this.Value = $step.Value
        $this.Source = $step.Source
    }
    Step([string]$Operation,[string]$Name,[int]$Step,[string]$Value,[string]$Source){
        $this.Operation = $Operation
        $this.Name = $Name
        $this.Step = $Step
        $this.Value = $Value
        $this.Source = $Source
    }
}

class DriverConfig {
    [string]$BrowserExecutablePath
    [string]$DriverExecutablePath
    DriverConfig([System.Object]$Config){
        if(!$Config.DriverExecutablePath){
            throw "Cannot find property DriverExecutable path"
        }
        if(!$Config.BrowserExecutablePath){
            throw "Cannot find property BrowserExecutable path"
        }
        $this.DriverExecutablePath = $Config.DriverExecutablePath
        $this.BrowserExecutablePath = $Config.BrowserExecutablePath
    }
    DriverConfig([string]$BrowserExePath,[string]$DriverExePath){
        $this.BrowserExecutablePath = $BrowserExePath
        $this.DriverExecutablePath = $DriverExePath
    }
}

class Operation{
    hidden [Step[]] $Steps
    hidden [hashtable] $DefaultMethods
    hidden [hashtable] $AllMethods
    hidden [int] $CurrentStep = 1
    Operation([Step[]]$Steps){
        $this.Steps = $Steps
        $this.DefaultMethods = @{}
        $this.AllMethods = @{}
        if($Global:PSVersionTable.PSEdition -eq "Core"){
            $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.FullName -match 'Powershell Class Assembly'}
            $defAssembly = $Assemblies[0]
        }else{
            $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.FullName -match 'ps1' -or $_.FullName -match 'powershell, version=0' -or $_.FullName -match 'psm1'}
            $defAssembly = $Assemblies | Where-Object {$_.FullName -match 'psm1'}
        }
        foreach($ChildClass in $defAssembly.GetTypes() | Where-Object {$_.BaseType -eq [Method]}){
            $this.DefaultMethods[$ChildClass.Name] = $ChildClass
            $this.AllMethods[$ChildClass.Name] = $ChildClass
        }
        foreach($ChildClass in $Assemblies.GetTypes() | Where-Object {$_.BaseType -eq [Method]}){
            $this.AllMethods[$ChildClass.Name] = $ChildClass
        }
    }
    [hashtable] GetDefaultMethods(){
        return $this.DefaultMethods
    }
    [System.Reflection.TypeInfo] GetMethod([string]$MethodName){
        if($null -ne $this.AllMethods[$MethodName]){
            return $this.AllMethods[$MethodName]
        }else{
            throw "Cannot find the Method with name $MethodName"
        }
    }
    [hashtable] GetMethods(){
        return $this.AllMethods
    }
    SetStep([int]$Step){
        $this.CurrentStep = $Step
    }
    [int]GetCurrentStep(){
        return $this.CurrentStep
    }
    [Step[]]GetSteps(){
        return $this.Steps
    }
    [Step]GetStep([int]$Step){
        return $this.Steps | Where-Object {$_.Step -eq $Step}
    }
    SetStep([Step[]]$Steps){
        $this.Steps = [Step[]]$Steps
    }
    StartSteps(){
        for($i = 0;$i -lt $this.Steps.Count; $i++){
            $this.SetStep($this.Steps[$i].Step)
            Try{
                $Method = $this.GetMethod($this.Steps[$i].Operation)::New()
            }catch{
                throw $_
            }
            $arguments = [PSCustomObject]@{
                Step = $this.Steps[$i]
            }
            Try{
                $Method.Execute($arguments)
            }catch{
                throw $_
            }
        }
    }
    StartSteps([System.Object]$Context){
        for($i = 0;$i -lt $this.Steps.Count; $i++){
            $this.SetStep($this.Steps[$i].Step)
            Try{
                $Method = $this.GetMethod($this.Steps[$i].Operation)::New()
            }catch{
                throw $_
            }
            $arguments = [PSCustomObject]@{
                Step = $this.Steps[$i]
                Context = $Context
            }
            Try{
                $Method.Execute($arguments)
            }catch{
                throw $_
            }
        }
    }
    StartStep([Step]$Step){
        Try{
            $Method = $this.GetMethod($Step.Operation)::New()
        }catch{
            throw $_
        }
        $arguments = [PSCustomObject]@{
            Step = $Step
        }
        Try{
            $Method.Execute($arguments)
        }catch{
            throw $_
        }
    }
    StartStep([Step]$Step,[System.Object]$Context){
        Try{
            $Method = $this.GetMethod($Step.Operation)::New()
        }catch{
            throw $_
        }
        $arguments = [PSCustomObject]@{
            Step = $Step
            Context = $Context
        }
        Try{
            $Method.Execute($arguments)
        }catch{
            throw $_
        }
    }
}

class WebOperation : Operation {
    hidden [DriverConfig] $Configuration
    hidden [Decimal] $DriverPort
    hidden [String] $BrowserTempFolder
    hidden [bool] $BackroundProcess
    hidden [string] $MainWindow
    hidden [System.Object] $WebDriver
    hidden [bool] $isDriverStarted = $false
    WebOperation([DriverConfig]$Config, [Step[]]$Steps, [Decimal]$DriverPort, [String]$BrowserTempFolder ,[bool]$Backround)
    :base([Step[]]$Steps){
        $this.Configuration = $Config
        $this.DriverPort = $DriverPort
        $this.BrowserTempFolder = $BrowserTempFolder
        $this.BackroundProcess = $Backround
    }
    StartDriver([System.Object]$DriverContext){
        if(!$this.isDriverStarted){
            if(!(Test-Path $this.BrowserTempFolder)){
                Try{
                    New-Item -ItemType Directory $this.BrowserTempFolder -ErrorAction Stop
                }catch{
                    throw $_   
                }
            }
            if($this.DriverPort -notin (Get-NetTCPConnection).LocalPort){
                Try{
                    $script:myDriverPID = Start-Process $this.Configuration.DriverExecutablePath -ArgumentList "-port=$($this.DriverPort)" -PassThru -WindowStyle Hidden
                }catch{
                    throw $_
                }
            }
            $DebugPort = 0
            while($true){
                $DebugPort = Get-Random -Minimum 65000 -Maximum 65500
                if($DebugPort -notin (Get-NetTCPConnection).LocalPort){
                    break
                }
            }
            Try{
                if($this.BackroundProcess){
                    $chromeArgs = "about:blank --remote-debugging-port=$DebugPort --user-data-dir=$($this.BrowserTempFolder) --headless --disable-extensions --disable-gpu"
                }else{
                    $chromeArgs = "about:blank --remote-debugging-port=$DebugPort --user-data-dir=$($this.BrowserTempFolder) --disable-extensions --disable-gpu"
                }
                $script:chromeProcess = Start-Process $this.Configuration.BrowserExecutablePath -ArgumentList $chromeArgs -ErrorAction Stop -PassThru
            }catch{
                throw $_
            }
            Try {
                $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
                $options.DebuggerAddress = "127.0.0.1:$DebugPort"
                $this.WebDriver = [OpenQA.Selenium.Remote.RemoteWebDriver]::New("http://localhost:$($this.DriverPort)",$options)
                $this.MainWindow = $this.WebDriver.WindowHandles
                $property = [PSCustomObject]@{
                    WebDriver = $this.WebDriver
                    MainWindow = $this.MainWindow
                }
                $DriverContext | Add-Member -NotePropertyName Driver -NotePropertyValue $property -Force
                $this.isDriverStarted = $true
            } catch {
                throw $_
            } finally {
                if($null -eq $this.WebDriver){
                    $this.Close()
                }
            }
        }else{
            throw "Driver already started"
        }
    }
    Clear(){
		if($this.isDriverStarted){
            foreach($win in $this.WebDriver.WindowHandles){
                if($win -eq $this.MainWindow){
                    continue
                }
                [void]$this.WebDriver.SwitchTo().Window($win)
                $this.WebDriver.Close()
            }
            [void]$this.WebDriver.SwitchTo().Window($this.MainWindow)
        }
    }
    Close(){
        foreach($win in $this.WebDriver.WindowHandles){
            [void]$this.WebDriver.SwitchTo().Window($win)
            $this.WebDriver.Close()
        }
        if($this.isDriverStarted){
            $this.WebDriver.Quit()
            $this.WebDriver = $null
            $this.isDriverStarted = $false
        }
        if($script:chromeProcess){
            Stop-Process -Id $script:chromeProcess.Id -Force -ErrorAction SilentlyContinue
        }
        Get-ChildItem $this.BrowserTempFolder -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        if($script:myDriverPID){
            Stop-Process -Id $script:myDriverPID.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

class Element : Method{
    Element()
    : base('Element',{})
    {}
    static [OpenQA.Selenium.WebElement[]] GetMany([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$XPath,[int]$RetryThreshold){
        $waitSecs = 1
        $result = $null
        while($true){
            Try{
                $result = $Driver.FindElements('xpath',$XPath)
                if($null -eq $result -or $result.Count -eq 0){
                    throw "null result for element: $($XPath)"
                }
                break
            }catch{
                if($waitSecs -le $RetryThreshold){
                    Start-Sleep -Seconds $waitSecs
                    $waitSecs *= 2
                }else{
                    throw $_
                }
            }
        }
        return $result
    }
    static [OpenQA.Selenium.WebElement[]] GetMany([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$XPath){
        Try{
            $result = $Driver.FindElements('xpath',$XPath)
            if($null -eq $result -or $result.Count -eq 0){
                throw "null result for element: $($XPath)"
            }
        }catch{
            throw $_
        }
        return $result
    }
    static [OpenQA.Selenium.WebElement] GetOne([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$XPath,[int]$RetryThreshold){
        $waitSecs = 1
        $result = $null
        while($true){
            Try{
                $result = $Driver.FindElement('xpath',$XPath)
                if($null -eq $result -or $result.Count -eq 0){
                    throw "null result for element: $($XPath)"
                }
                break
            }catch{
                if($waitSecs -le $RetryThreshold){
                    Start-Sleep -Seconds $waitSecs
                    $waitSecs *= 2
                }else{
                    throw $_
                }
            }
        }
        return $result
    }
    static [OpenQA.Selenium.WebElement] GetOne([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$XPath){
        Try{
            $result = $Driver.FindElement('xpath',$XPath)
            if($null -eq $result -or $result.Count -eq 0){
                throw "null result for element: $($XPath)"
            }
        }catch{
            throw $_
        }
        return $result
    }
}

class Window : Method{
    Window()
    : base('Window',{})
    {}
    static SwitchTo([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$Window){
        Try{
            [void]$Driver.SwitchTo().Window($Window)
        }catch{
            throw $_
        }
    }
    static [string[]] GetOthers([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver){
        return ($Driver.WindowHandles | Where-Object {$_ -ne $WebOperation.GetMainWindow()})
    }
    static ScrollUp ([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver){
        Try{
            $Driver.ExecuteScript("scroll(0, 0);")
        }catch{
            throw $_
        }
    }
}

class Frame : Method {
    Frame()
    : base('Frame',{}){}
    static SwitchToFrame ([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver,[string]$FrameName){
        Try{
            [void]$Driver.SwitchTo().Frame($FrameName)
        }catch{
            throw $_
        }
    }
    static SwitchToParentFrame([OpenQA.Selenium.Remote.RemoteWebDriver]$Driver){
        Try{
            $Driver.SwitchTo().ParentFrame()
        }catch{
            throw $_
        }
    }
}

# SIG # Begin signature block
# MIIFZwYJKoZIhvcNAQcCoIIFWDCCBVQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrOCLiGiA8q44aEwKf+xdBVTo
# QY6gggMEMIIDADCCAeigAwIBAgIQbPi4sIAtyKVLGqoZHqXXlTANBgkqhkiG9w0B
# AQsFADAYMRYwFAYDVQQDDA1PZ3RheSBHYXJheWV2MB4XDTIxMDczMDE0MjQzMloX
# DTIyMDczMDE0NDQzMlowGDEWMBQGA1UEAwwNT2d0YXkgR2FyYXlldjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALYXMDLGDEKJ/pV58dD5KbOMMPTFGFXd
# ItI3TZrHeCvS0y234HdH35e9syi//ELK62bs8QlBSFKKa47BL1pvjpkbXXuB0OVF
# f+gLxel5XYHS3cMKu4NVrKR3gY+mDWIZc5oJzr6kWvYiKb4ZG7cKBr+7UoFSINtB
# 9kvIBPbWglcCMlvzbkDD520j73+0XvqKI5rgt0Y+MPlEcb9gsYHxsXeSwDotCpe7
# 17Huz/eJ2Yg7nG2ns2UB4jDWpOOul1uMeoETf7ofBzpv7HxL8P4BaKuFWjlvhcUT
# DSjDaICmzeWbvzr/c8gery5b4TobrT7z46iKi1qWWLd3R2Ii+HVQ0lECAwEAAaNG
# MEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQW
# BBSpQGoWjLBKEBibL7lPaCEOCN74TzANBgkqhkiG9w0BAQsFAAOCAQEAVQzjCunl
# iqpSE00SAXtN2nuEUV3caIdvQ5NWlCZSdF7XliKSG9RC/aZ5zDfIYKNdCc+dwz1z
# Dn0aMhT3q96KWMBOPw9oLfF1SyccAH4gKRfqELn7K+dsUvMNSS8WUc9bbQzj5Wyh
# ywkd+Dzrrxot+aLUYltV7hZ0BppdQAlKSl81NpW/wc0DIj5I1LTsOYUAqwqGi+vz
# 1pe02hZ4cykEJ9f86JcF2otVnK2s6dVPf4TMfyEXCoKJtpcqrVbzuEbzna1tkkKN
# XHD8d/BZIQsTW9bgxok4DotADEHdvA+NKpRmT1p4OMuGZTUaqpWUqSbqd+8Bdv40
# SLptB0yXRqJQ5DGCAc0wggHJAgEBMCwwGDEWMBQGA1UEAwwNT2d0YXkgR2FyYXll
# dgIQbPi4sIAtyKVLGqoZHqXXlTAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUy9ujyBeEu84djdfS
# E/NQxmCm3fAwDQYJKoZIhvcNAQEBBQAEggEADqa06aStnilHQ2NtHmsc0qtD8CLc
# yO4xiZyf2rASrkjorTqCQp8WSphONJFMxdWcQ335T41pe73ld1uzkIq8H7UKit0P
# RSMtqsZTVflPdDh1DOiI7i/CB/HlMzWZRT1P2qAgkYZhOgeidlHc0E11ErJtvj+I
# ckGC02E8YKhOrTx6jRhXClyknR/c9XAAvJ3x73Fmfs1389hamDZkT+cimoefukYJ
# cZRlU4UObLtecKQ9pTbyYZo1ag61LVnTt1biAzWRmHw7atrAczDD30a3oqQog/ko
# tKCXfHegtHbvnALYE+6RT4VNhQHnfFVtTUNiDsbRYU38Gs7NCDTzK7K7Qw==
# SIG # End signature block

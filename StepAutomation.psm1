class Method{
    hidden [ScriptBlock] $Function
    hidden [string] $Method
    hidden Validate($Method){
        if([string]::IsNullOrEmpty($Method)){
            throw "Cannot validate Method Name, provide a valid method name"
        }
    }
    Method([String]$Method,[scriptBlock]$Function){
        $this.Validate($Method)
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
    hidden Validate([System.Object]$Step){
        if([String]::IsNullOrEmpty($Step.Operation)){
            throw "Cannot validate Operation argument, provide valid Name for Operation"
        }
        if([String]::IsNullOrEmpty($Step.Name)){
            throw "Cannot validate Name argument, provide valid Name"
        }
        if($Step.Step -eq 0 -or [string]::IsNullOrEmpty($Step.Step)){
            throw "Cannot validate Step argument, provide valid Step value"
        }
        if([String]::IsNullOrEmpty($Step.Value)){
            throw "Cannot validate Value argument, provide valid Value"
        }
    }
    Step([System.Object]$Step){
        $this.Validate($Step)
        $this.Operation = $Step.Operation
        $this.Step = $Step.Step
        $this.Name = $Step.Name
        $this.Value = $step.Value
        $this.Source = $step.Source
    }
    Step([string]$Operation,[string]$Name,[int]$Step,[string]$Value,[string]$Source){
        $this.Validate([PSCustomObject]@{Operation=$Operation;Name=$Name;Step=$Step;Value=$Value;Source=$Source})
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
    hidden Validate([System.Object]$Config){
        if(!$Config.BrowserExecutablePath){
            throw "Cannot find property BrowserExecutablePath"
        }
        if(!$Config.DriverExecutablePath){
            throw "Cannot find property DriverExecutablePath"
        }
        if($null -eq ($Config.BrowserExecutablePath -as [System.IO.FileInfo])){
            throw "Cannot validate BrowserExecutablePath argument, provide valid File Path"
        }
        if($null -eq ($Config.DriverExecutablePath -as [System.IO.FileInfo])){
            throw "Cannot validate DriverExecutablePath argument, provide valid File Path"
        }
        if(!([System.IO.FileInfo]$Config.BrowserExecutablePath).Exists){
            throw "Cannot validate BrowserExecutablePath argument, provide valid File Path"
        }
        if(!([System.IO.FileInfo]$Config.DriverExecutablePath).Exists){
            throw "Cannot validate DriverExecutablePath argument, provide valid File Path"
        }
    }
    DriverConfig([System.Object]$Config){
        $this.Validate($Config)
        $this.DriverExecutablePath = $Config.DriverExecutablePath
        $this.BrowserExecutablePath = $Config.BrowserExecutablePath
    }
    DriverConfig([string]$BrowserExePath,[string]$DriverExePath){
        $this.Validate(([PSCustomObject]@{BrowserExecutablePath=$BrowserExePath;DriverExecutablePath=$DriverExePath}))
        $this.BrowserExecutablePath = $BrowserExePath
        $this.DriverExecutablePath = $DriverExePath
    }
}

class Operation{
    hidden [Step[]] $Steps
    hidden [hashtable] $DefaultMethods = @{}
    hidden [hashtable] $AllMethods = @{}
    hidden [int] $CurrentStep = 1
    Operation([Step[]]$Steps){
        $this.Steps = $Steps
        $this.CollectMethods()
    }
    hidden CollectMethods(){
        $Assemblies = [System.Collections.ArrayList]::new()
        foreach($ass in [AppDomain]::CurrentDomain.GetAssemblies()){
            if($Global:PSVersionTable.PSEdition -eq "Core" -and $ass.FullName -match 'Powershell Class Assembly'){
                if($ass.CustomAttributes.NamedArguments.TypedValue.Value -match 'psm1'){
                    $ass | Add-Member -NotePropertyName isDefault -NotePropertyValue $true -Force
                }
                [void]$Assemblies.Add($ass)
            }
            elseif($ass.FullName -match 'ps1' -or $ass.FullName -match 'powershell, version=0' -or $ass.FullName -match 'psm1'){
                if($ass.FullName -match 'psm1'){
                    $ass | Add-Member -NotePropertyName isDefault -NotePropertyValue $true -Force
                }
                [void]$Assemblies.Add($ass)
            }
        }

        foreach($ass in $Assemblies){
            foreach($ChildClass in $ass.Gettypes()){
                if($ChildClass.BaseType -eq [Method]){
                    if($ass.isDefault){
                        $this.DefaultMethods[$ChildClass.Name] = $ChildClass
                    }
                    $this.AllMethods[$ChildClass.Name] = $ChildClass
                }
            }
        }
    }
    # Returs all the methods implemented in the module
    [hashtable] GetDefaultMethods(){
        return $this.DefaultMethods
    }
    # Returns single method from runtime
    [System.Reflection.TypeInfo] GetMethod([string]$MethodName){
        if($null -eq $this.AllMethods[$MethodName]){
            throw "Cannot find the Method with name $MethodName"
        }
        return $this.AllMethods[$MethodName]
    }
    # Returns all the methods both implemented in the module and extended in runtime
    [hashtable] GetMethods(){
        return $this.AllMethods
    }
    # Sets the current step number
    SetCurrentStep([int]$Step){
        $this.CurrentStep = $Step
    }
    # Gets the current step number
    [int]GetCurrentStep(){
        return $this.CurrentStep
    }
    # Returns All steps
    [Step[]]GetSteps(){
        return $this.Steps
    }
    # Returns Single step
    [Step]GetStep([int]$Step){
        return $this.Steps | Where-Object {$_.Step -eq $Step}
    }
    # Sets Steps
    SetStep([Step[]]$Steps){
        $this.Steps = [Step[]]$Steps
    }
    # Starts executing all the steps
    StartSteps(){
        for($i = 0;$i -lt $this.Steps.Count; $i++){
            if($this.Steps[$i].Step -lt $this.GetCurrentStep()){
                continue
            }
            $this.SetCurrentStep($this.Steps[$i].Step)
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
    # Starts executing all the steps with exchange context
    StartSteps([System.Object]$Context){
        for($i = 0;$i -lt $this.Steps.Count; $i++){
            if($this.Steps[$i].Step -lt $this.GetCurrentStep()){
                continue
            }
            $this.SetCurrentStep($this.Steps[$i].Step)
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
    # Starts executing a single step
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
    # Starts executing a single step with exchange context
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
    hidden [Decimal] $DebugPort = 0
    hidden [String] $BrowserTempFolder
    hidden [bool] $BackroundProcess
    hidden [string] $MainWindow
    hidden [System.Object] $WebDriver
    hidden [bool] $isDriverStarted = $false
    hidden [ipaddress] $DriverIP = '127.0.0.1'
    hidden Validate([System.Object]$Arguments){
        if($Arguments.PSObject.Properties['Steps']){
            if($Arguments.Steps.Count -eq 0){
                throw "Cannot validate Steps argument, provide a valid '[Step]' array"
            }
        }
        if($Arguments.DriverPort -lt 1 -or $arguments.DriverPort -gt 65532){
            throw "Cannot validate DriverPort argument, provide a valid port value, Port Value must be between 1 and 65532"
        }
        if($Arguments.PSObject.Properties['RemoteDriverIP']){
            if($null -eq ($Arguments.RemoteDriverIP -as [IPAddress])){
                throw "Cannot validate RemoteDriverIP argument, provide a valid '[IPAddress]' value"
            }
        }
        if($Arguments.PSObject.Properties['BrowserDebugPort']){
            if($Arguments.BrowserDebugPort -lt 1 -or $arguments.BrowserDebugPort -gt 65532){
                throw "Cannot validate BrowserDebugPort argument, provide a valid port value, Port Value must be between 1 and 65532"
            }
        }
    }
    WebOperation([DriverConfig]$Config, [Step[]]$Steps, [Decimal]$DriverPort, [String]$BrowserTempFolder ,[bool]$Backround)
    :base([Step[]]$Steps){
        $this.Validate([PSCUstomObject]@{Steps=$Steps;DriverPort=$DriverPort})
        $this.Configuration = [DriverConfig]::new($Config)
        $this.DriverPort = $DriverPort
        $this.BrowserTempFolder = ([System.IO.DirectoryInfo]$BrowserTempFolder).FullName
        $this.BackroundProcess = $Backround
    }
    WebOperation([Step[]]$Steps,[ipaddress]$RemoteDriverIP,[Decimal]$RemoteDriverPort,[Decimal]$BrowserDebugPort)
    :base([Step[]]$Steps){
        $this.Validate([PSCUstomObject]@{Steps=$Steps;DriverPort=$RemoteDriverPort;RemoteDriverIP=$RemoteDriverIP;BrowserDebugPort=$BrowserDebugPort})
        $this.DriverIP = $RemoteDriverIP
        $this.DriverPort = $RemoteDriverPort
        $this.DebugPort = $BrowserDebugPort
    }
    hidden [System.Diagnostics.Process] StartBrowserDriver(){
        Try{
            $prPID = Start-Process $this.Configuration.DriverExecutablePath -ArgumentList "-port=$($this.DriverPort)" -PassThru -WindowStyle Hidden
        }catch{
            throw $_
        }
        if($prPID.HasExited){
            Throw "Cannot Start Browser Driver with port $($this.DriverPort)"
        }
        return $prPID
    }
    hidden [System.Diagnostics.Process] StartBrowser(){
        $guid = [Guid]::NewGuid().Guid
        $timeStr = Get-Date -Format 'yyyyMMddHHmmssfff'
        $this.BrowserTempFolder = "$($this.BrowserTempFolder)\$($guid)-$($timeStr)"
        if(!(Test-Path $this.BrowserTempFolder)){
            Try{
                New-Item -ItemType Directory $this.BrowserTempFolder -ErrorAction Stop
            }catch{
                throw $_   
            }
        }
        while($true){
            $this.DebugPort = Get-Random -Minimum 65000 -Maximum 65500
            if($this.DebugPort -notin (Get-NetTCPConnection).LocalPort){
                break
            }
        }
        Try{
            if($this.BackroundProcess){
                $chromeArgs = "about:blank --remote-debugging-port=$($this.DebugPort) --user-data-dir=$($this.BrowserTempFolder) --headless --disable-extensions --disable-gpu"
            }else{
                $chromeArgs = "about:blank --remote-debugging-port=$($this.DebugPort) --user-data-dir=$($this.BrowserTempFolder) --disable-extensions --disable-gpu"
            }
            $brPID = Start-Process $this.Configuration.BrowserExecutablePath -ArgumentList $chromeArgs -ErrorAction Stop -PassThru
        }catch{
            throw $_
        }
        return $brPID
    }
    hidden [bool] CloseProcess([int]$ProcessId){
        $Status = $false
        $now = Get-Date
        While($now -gt (Get-Date).AddSeconds(-30)){
            Try{
                Stop-Process -Id $ProcessId -Force -ErrorAction Stop
            }catch{
                if($_.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.ProcessCommandException"){
                    $Status = $true
                    break
                }
            }
            if(!$Status){
                Try{
                    $process = Get-Process -Id $ProcessId -ErrorAction Stop
                    if($process.HasExited -and ($null -eq $process.Name)){
                        $Status = $true
                        break
                    }
                }catch{
                    if($_.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.ProcessCommandException"){
                        $Status = $true
                        break
                    }
                }
                Start-Sleep -Milliseconds 500
            }
        }
        return $Status
    }
    hidden CloseBrowserDriver(){
        $Stopped = $false
        if(!$script:myDriverPID){
            Try{
                $PRs = Get-CimInstance -Query "select * from win32_process where Name = 'chromedriver.exe'" -ErrorAction Stop | 
                Where-Object {$_.CommandLine -Match "-port=$($this.DriverPort)"}
            }catch{
                Throw $_
            }
            if($PRs){
                $script:myDriverPID = Get-Process -Id $PRs[0].ProcessId
            }else{
                $Stopped = $true
            }
        }
        if($script:myDriverPID){
            $Stopped = $this.CloseProcess($script:myDriverPID.Id)
        }
        if(!$Stopped){
            Throw "Cannot Close Browser Driver"
        }
    }
    hidden CloseBrowser(){
        if($script:chromeProcess){
            Try{
                Stop-Process -Id $script:chromeProcess.Id -Force -ErrorAction Stop
            }catch{
                if($_.Exception.GetType().FullName -ne "Microsoft.PowerShell.Commands.ProcessCommandException"){
                    Throw $_
                }
            }
        }
        Try{
            $prs = Get-CimInstance -Query "select * from win32_process where Name = 'chrome.exe'" -ErrorAction Stop | 
            Where-Object {$_.CommandLine -match "--remote-debugging-port=$($this.DebugPort)"}
        }catch{
            Throw $_
        }
        foreach($pr in $prs){
            if(!$this.CloseProcess($pr.ProcessId)){
                Throw "Cannot close the process"
            }
        }
    }
    hidden ClearBrowserData(){
        Remove-Item $this.BrowserTempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Starts browser and its driver and assings driver state to the exchange context
    StartDriver([System.Object]$DriverContext){
        if(!$this.isDriverStarted){
            Try {
                if($null -ne $this.Configuration){
                    $script:myDriverPID = $this.StartBrowserDriver()
                    $script:chromeProcess = $this.StartBrowser()
                }
                $remoteAddress = "http://$($this.DriverIP.IPAddressToString):$($this.DriverPort)"
                $options = [OpenQA.Selenium.Chrome.ChromeOptions]::new()
                $options.DebuggerAddress = "localhost:$($this.DebugPort)"
                $this.WebDriver = [OpenQA.Selenium.Remote.RemoteWebDriver]::New($remoteAddress,$options)
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
    # Closes all the windows but main window
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
    # Closes browser, its driver and cleans browser temporary directory
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
        if($null -ne $this.Configuration){
            $this.CloseBrowserDriver()
            $this.CloseBrowser()
            $this.ClearBrowserData()
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

class ToFrame : Method{
    ToFrame()
    : base('ToFrame',$this.myFunction){}
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that a Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            [void]$WebDriver.SwitchTo().Frame($Step.Value)
        }catch{
            throw $_
        }
    }
}

class FromFrame : Method{
    FromFrame()
    : base('FromFrame',$this.myFunction){}
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that a Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            [void]$WebDriver.SwitchTo().ParentFrame()
        }catch{
            throw $_
        }
    }
}

class Navigate : Method {
    Navigate()
    : base('Navigate',$this.myFunction){
    }
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            $WebDriver.Navigate().GotoURL($Step.Value)
        }catch{
            throw $_
        }
    }
}

class Click : Method {
    Click()
    : base('Click',$this.myFunction){
    }
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that a Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            $element = [element]::GetOne($WebDriver,$Step.Value)
        }catch{
            throw $_
        }
        Try{
            $element.Click()
        }catch{
            throw $_
        }
    }
}

class AddText : Method {
    AddText()
    : base('AddText',$this.myFunction){
    }
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that a Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            $element = [element]::GetOne($WebDriver,$Step.Value)
        }catch{
            throw $_
        }
        Try{
            $element.SendKeys($Step.Source)
        }catch{
            throw $_
        }
    }
}

class SetText : Method {
    SetText()
    : base('SetText',$this.myFunction){
    }
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.Context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that a Context argument was added when Starting Steps"
        }
        $WebDriver = $Context.Driver.WebDriver
        Try{
            $element = [element]::GetOne($WebDriver,$Step.Value)
        }catch{
            throw $_
        }
        Try{
            $element.Clear()
            $element.SendKeys($Step.Source)
        }catch{
            throw $_
        }
    }
}

# SIG # Begin signature block
# MIIFZwYJKoZIhvcNAQcCoIIFWDCCBVQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7tXOdTziGosw1wheK/OVztoQ
# KNOgggMEMIIDADCCAeigAwIBAgIQbPi4sIAtyKVLGqoZHqXXlTANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUGHg+iwEjy5Q/Vvx/
# rC9MawCUwGMwDQYJKoZIhvcNAQEBBQAEggEAWiVbVJLQyeqGzI7NPkXfkmQARaih
# WK8kbEjY9C4CeQBEcbLKmhuesVNkQB3nfLIt9i8Rs5l/nFH/7u/hox+fRSlnXt0a
# +3kfVddarfnRtn+FCpxlE+mt40acZQ6lZOy+CBrYhpP5hQATLIQ2kcCre09FHeLU
# 6VFZt8aKAVFbE5/J8aWP5gI12VNaPH2WndFtoGwhbSFdf6rL+k+Qqw4go/0kyMj9
# Gk0pClTFTLFet8GOsL1EdJxiAaSy244+bIfhhSGkIQpD96cwL5aqJrD36qAYCkCs
# pj/VHe+PbodjQviktveA57MNa702rmS9rdkMR+UME386p+1qNoWa1avn4g==
# SIG # End signature block

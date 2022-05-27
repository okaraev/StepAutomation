using module .\StepAutomation.psd1

class testMethod : Method{
    testMethod()
    : base ('testMethod',$this.myFunction){}
    hidden [scriptBlock] $myFunction = {
        param(
            [parameter(Mandatory,Position=0)]
            [System.Object]$Arguments
        )
        if($Arguments.Context){
            $Context = $Arguments.Context
            $Context.Key = 'myChangedKey'
            $Context.Value = 'myChangedValue'
        }else{
            $Arguments.Key = 'myChangedKey'
            $Arguments.Value = 'myChangedValue'
        }
    }
}
$testMethod = [testMethod]::new()
$Steps = @()
$Steps += [Step]::new('notExistingMethod','Open webSite',1,'https://google.ca','')
$Op = [Operation]::new($Steps)

$Context1 = [PSCustomObject]@{Key='myDefaultKey';Value='myDefaultValue'}

$driverConf = [DriverConfig]::new("C:\Program Files\Google\Chrome\Application\Chrome.exe", "C:\BrowserDriver\chromedriver.exe")

class GetValue : Method{
    GetValue()
    : base('GetValue',$this.myFunction){
    }
    hidden [scriptBlock]$myFunction = {
        [CmdletBinding()]
        param(
            [parameter(mandatory=$true)]
            [System.Object]$Arguments
        )
        $Step = $Arguments.Step
        $Context = $Arguments.context
        if($null -eq $Context.Driver.WebDriver){
            throw "Cannot find Driver Context. Make sure that Context argument was added when Starting Steps"
        }
        $Driver = $Context.Driver.WebDriver
        Try{
            $element = [Element]::GetOne($Driver,$Step.Value)
        }catch{
            throw $_
        }
        $context.Value = $element.Text
    }
}

$localSite = "http://localhost:65158/"
$ps = [powershell]::Create()
$ps.Runspace.SessionStateProxy.SetVariable('url',$localSite)
[void]$ps.AddScript{
    $http = [System.Net.HttpListener]::new()
    $http.Prefixes.Add($url)
    $http.Start()
    while($http.IsListening){
        $context = $http.GetContext()
        if($context.Request.RawUrl -eq '/'){
            [string]$html = "
            <h1>A Powershell Webserver</h1>
            <form action='/some/post' method='post'>
                <p>A Basic Form</p>
                <p>fullname</p>
                <input type='text' name='fullname'>
                <p>text_message</p>
                <textarea rows='4' cols='50' name='text_message'></textarea>
                <br>
                <input type='submit' value='Submit'>
            </form>
            "
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
            $context.Response.OutputStream.Close()
        }elseif($context.Request.RawUrl -eq '/close'){
            $HttpResponse = $context.Response
            $HttpResponse.Headers.Add("Content-Type","text/plain")
            $HttpResponse.StatusCode = 200
            $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("")
            $HttpResponse.ContentLength64 = $ResponseBuffer.Length
            $HttpResponse.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
            $HttpResponse.Close()
            Break
        }
    }
    $http.Stop()
    $http.Close()
}

$Context2 = [PSCustomObject]@{
    SourceObject = $null
    Value = $null
}
[void]$ps.BeginInvoke()
$WebSteps = [Step]::new('Navigate','Open webSite',1,$localSite,$null),`
[Step]::new('GetValue','Get predefined Value',2,'/html/body/form/p[3]',$null)


Describe "Method Class" {
    Context 'Child Class Creation' {
        It "Should access to Method, Function parameters" {
            $testMethod.Method | Should -Be 'testMethod'
            $testMethod.Function | Should -BeOfType [ScriptBlock]
        }
    }

    Context "Child Class Method invocation" {
        It "Should change context Object"{
            $testMethod.Execute($Context1)
            $Context1.Key | Should -Be 'myChangedKey'
            $Context1.Value | Should -Be 'myChangedValue'
        }

        It "Should return correct exception type"{
            $testMethod.Function = {
                throw [System.Management.Automation.ItemNotFoundException]::New('TestNotFoundException')
            }
            Try{
                $testMethod.Execute(@())
            }catch [System.Management.Automation.ItemNotFoundException]{
                $myErr = $_
            }catch{
                $myErr = $_
            }
            $myErr.Exception | Should -BeOfType [System.Management.Automation.ItemNotFoundException]
            $myErr.Exception.Message | Should -Be 'TestNotFoundException'
        }
    }
}


Describe "Operation Class"{
    Context "Method Collection"{
        It "Should return correct Types"{
            $defaultMethods = $Op.GetDefaultMethods()
            foreach($item in $defaultMethods.Keys){
                $defaultMethods[$item] | Should -BeOfType [System.Reflection.TypeInfo]
            }
        }
    }

    Context "StartStep/s without context"{
        It "Should return exception about not existing method"{
            Try{
                $Op.StartSteps()
            }catch{
                $myErr = $_
            }
            $myErr.Exception.Message | Should -Match 'Cannot find the Method with name'
            Try{
                $Op.StartStep($Steps[0])
            }catch{
                $mySecondErr = $_
            }
            $mySecondErr.Exception.Message | Should -Match 'Cannot find the Method with name'
        }
    }

    Context "StartStep/s with context"{
        It "Sould change the default value in the context"{
            $Context1.Value = 'DefaultValue'
            $Steps[0].Operation = 'testMethod'
            Try{
                $Op.StartSteps($Context1)
            }catch{
                throw $_
            }
            $Context1.Value | Should -Be 'myChangedValue'

            $Context1.Value = 'DefaultValue'
            Try{
                $Op.StartStep($Steps[0],$Context1)
            }catch{
                throw $_
            }
            $Context1.Value | Should -Be 'myChangedValue'
        }
    }
}


Describe "WebOperation Class"{
    Context "Start Driver"{
        It "Should not return any exceptions" {
            Try{
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,58888,"D:\chromedata",$true)
                $webOperation.StartDriver($Context2)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null
        }
    }

    Context "Starting Steps without Context"{
        It "Should return Exception about context"{
            Try{
                Start-Sleep -Seconds 1
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,58888,"D:\chromedata",$true)
                $webOperation.StartDriver($Context2)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null

            Try{
                $webOperation.StartSteps()
            }catch{
                $myErr = $_
            }finally{
                $webOperation.Close()
            }
            $myErr.Exception.Message | Should -Be "Cannot find Driver Context. Make sure that Context argument was added when Starting Steps"
        }
    }

    Context "Starting Steps with Context"{
        It "Should change the context value"{
            Try{
                Start-Sleep -Seconds 1
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,58888,"D:\chromedata",$true)
                $webOperation.StartDriver($Context2)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null

            Try{
                $webOperation.StartSteps($Context2)
            }catch{
                $myErr = $_
            }finally{
                $webOperation.Close()
            }
            $Context2.Value | Should -Be "text_message"
        }
    }
}

Describe "Local Web Site"{
    It "Should Close the site"{
        Invoke-WebRequest -Uri "$($localSite)close" -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
        $null | Should -Be $null
    }
}
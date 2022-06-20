using module .\StepAutomation.psd1
[CmdletBinding()]
param(
    [parameter(Mandatory)]
    [System.Object]$Arguments
)
BeforeAll{
    if($PSVersionTable.Platform -eq "Unix"){
        $brTMPFolder = "/tmp/chromedata"
    }else{
        $brTMPFolder = "D:\chromedata"
    }
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
    if($PSVersionTable.Platform -eq "Unix"){
        $driverConf = [DriverConfig]::new("/usr/bin/google-chrome", "/usr/bin/chromedriver")
    }else{
        $driverConf = [DriverConfig]::new("C:\Program Files\Google\Chrome\Application\Chrome.exe", "C:\BrowserDriver\chromedriver.exe")
    }
    
    
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
    
    $localSite = "http://localhost:$($Arguments.LocalSitePort)/"
    $ps = [powershell]::Create()
    $ps.Runspace.SessionStateProxy.SetVariable('url',$localSite)
    [void]$ps.AddScript{
        $http = [System.Net.HttpListener]::new() 
        $http.Prefixes.Add($url)
        $http.Start()
        while($http.IsListening){
            $context = $http.GetContext()
            if ($context.Request.HttpMethod -eq 'GET' -and ($context.Request.RawUrl -eq '/' -or $context.Request.RawUrl -eq '/some/post')) {
                [string]$html = "
                <h1>A Powershell Webserver</h1>
                <form action='/some/post' method='post'>
                    <p>A Basic Form</p>
                    <p>fullname</p>
                    <input type='text' name='fullname'>
                    <p>message</p>
                    <textarea rows='4' cols='50' name='message'></textarea>
                    <br>
                    <input type='submit' value='Submit'>
                </form>
                "
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
                $context.Response.ContentLength64 = $buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
                $context.Response.OutputStream.Close()
            }elseif ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/some/post') {
                $FormContent = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()
                if($FormContent -match '&message=(?<message>\w+)'){
                    $message = $Matches.message
                }
                [string]$html = "
                <h1>A Powershell Webserver</h1>
                <form action='/some/post' method='post'>
                    <p>A Basic Form</p>
                    <p>fullname</p>
                    <input type='text' name='fullname'>
                    <p>message</p>
                    <textarea rows='4' cols='50' name='message'>$message</textarea>
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
    $psState = $ps.BeginInvoke()
    $WebSteps = [Step]::new('Navigate','Open webSite',1,$localSite,$null),`
    [Step]::new('SetText','Insert Text',2,'/html/body/form/textarea','okaraev'),`
    [Step]::new('Click','Submit Click',3,'/html/body/form/input[2]',$null),`
    [Step]::new('GetValue','Get predefined Value',4,'/html/body/form/textarea',$null)
}


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

Describe "Step Class"{
    Context "Constructor"{
        It "Should return Exception about Operation"{
            Try{
                [Step]::new('','Some Description',1,'Some Xpath',$null)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate Operation argument, provide valid Name for Operation"

            $object = [PSCustomObject]@{
                Operation = ''
                Name = 'Some Description'
                Step = 1
                Value = 'Some Xpath'
            }
            Try{
                [Step]::new($object)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate Operation argument, provide valid Name for Operation"
        }

        It "Should return Exception about Operation Name"{
            Try{
                [Step]::new('Some Operation','',1,'Some Xpath',$null)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate Name argument, provide valid Name"

            $object = [PSCustomObject]@{
                Operation = 'Some Operation'
                Name = ''
                Step = 1
                Value = 'Some Xpath'
            }
            Try{
                [Step]::new($object)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate Name argument, provide valid Name"
        }

        It "Should return Exception about Step value"{
            Try{
                [Step]::new('Some Operation','Some Description','','Some Xpath',$null)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate Step argument, provide valid Step value"
            
            Try{
                [Step]::new('Some Operation','Some Description',0,'Some Xpath',$null)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate Step argument, provide valid Step value"

            $object = [PSCustomObject]@{
                Operation = 'Some Operation'
                Name = 'Some Description'
                Step = ''
                Value = 'Some Xpath'
            }
            Try{
                [Step]::new($object)
            }catch{
                $myErr3 = $_
            }
            $myErr3.Exception.Message | Should -Be "Cannot validate Step argument, provide valid Step value"

            $object = [PSCustomObject]@{
                Operation = 'Some Operation'
                Name = 'Some Description'
                Step = 0
                Value = 'Some Xpath'
            }
            Try{
                [Step]::new($object)
            }catch{
                $myErr4 = $_
            }
            $myErr4.Exception.Message | Should -Be "Cannot validate Step argument, provide valid Step value"
        }

        It "Should return Exception about Value argument"{
            Try{
                [Step]::new('Some Operation','Some Description',1,'',$null)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate Value argument, provide valid Value"

            $object = [PSCustomObject]@{
                Operation = 'Some Operation'
                Name = 'Some Description'
                Step = 1
                Value = ''
            }
            Try{
                [Step]::new($object)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate Value argument, provide valid Value"
        }

        It "Should not return any Exception"{
            Try{
                [Step]::new('Some Operation','Some Description',1,'Some Xpath',$null)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null
        }
    }
}

Describe "DriverConfig class"{
    Context "Constructor"{
        It "Should return Exception about Browser Executable Path path"{
            $existingFile = Get-ChildItem -File | Select-Object -First 1 -ExpandProperty FullName
            Try{
                [DriverConfig]::new('C:\notExisting2022file.fileext',$existingFile)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate BrowserExecutablePath argument, provide valid File Path"

            $Object = [PSCustomObject]@{
                BrowserExecutablePath = 'C:\notExisting2022file.fileext'
                DriverExecutablePath = $existingFile
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate BrowserExecutablePath argument, provide valid File Path"

            Try{
                [DriverConfig]::new('',$existingFile)
            }catch{
                $myErr3 = $_
            }
            $myErr3.Exception.Message | Should -Be "Cannot find property BrowserExecutablePath"
            
            $Object = [PSCustomObject]@{
                DriverExecutablePath = $existingFile
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr4 = $_
            }
            $myErr4.Exception.Message | Should -Be "Cannot find property BrowserExecutablePath"

            Try{
                [DriverConfig]::new($existingFile,$existingFile)
            }catch{
                $myErr5 = $_
            }
            $myErr5 | Should -Be $null

            $Object = [PSCustomObject]@{
                BrowserExecutablePath = $existingFile
                DriverExecutablePath = $existingFile
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr6 = $_
            }
            $myErr6 | Should -Be $null
        }

        It "Should return Exception about Driver Executable Path path"{
            $existingFile = Get-ChildItem -File | Select-Object -First 1 -ExpandProperty FullName
            Try{
                [DriverConfig]::new($existingFile,'C:\notExisting2022file.fileext')
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate DriverExecutablePath argument, provide valid File Path"

            $Object = [PSCustomObject]@{
                BrowserExecutablePath = $existingFile
                DriverExecutablePath = 'C:\notExisting2022file.fileext'
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate DriverExecutablePath argument, provide valid File Path"

            Try{
                [DriverConfig]::new($existingFile,'')
            }catch{
                $myErr3 = $_
            }
            $myErr3.Exception.Message | Should -Be "Cannot find property DriverExecutablePath"
            
            $Object = [PSCustomObject]@{
                BrowserExecutablePath = $existingFile
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr4 = $_
            }
            $myErr4.Exception.Message | Should -Be "Cannot find property DriverExecutablePath"

            Try{
                [DriverConfig]::new($existingFile,$existingFile)
            }catch{
                $myErr5 = $_
            }
            $myErr5 | Should -Be $null

            $Object = [PSCustomObject]@{
                BrowserExecutablePath = $existingFile
                DriverExecutablePath = $existingFile
            }

            Try{
                [DriverConfig]::new($Object)
            }catch{
                $myErr6 = $_
            }
            $myErr6 | Should -Be $null
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
    Context "Class Constructor"{
        It "Should return exception about Steps" {
            Try{
                $exist = Get-ChildItem -File | Select-Object -First 1 -ExpandProperty FullName
                $dc = [DriverConfig]::new($exist,$exist)
                [WebOperation]::New($dc,[Step[]]@(),$($Arguments.BrowserDriverPort),$brTMPFolder,$true)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate Steps argument, provide a valid '[Step]' array"

            Try{
                [WebOperation]::New([Step[]]@(),"192.168.100.100",$($Arguments.BrowserDriverPort),$($Arguments.BrowserDriverPort))
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate Steps argument, provide a valid '[Step]' array"
        }

        It "Should return exception about Driver Port" {
            Try{
                $exist = Get-ChildItem -File | Select-Object -First 1 -ExpandProperty FullName
                $dc = [DriverConfig]::new($exist,$exist)
                $Steps = [Step[]]@([Step]::new('Op','Name',1,'//*',$null))
                [WebOperation]::New($dc,$Steps,6545454,$brTMPFolder,$true)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot validate DriverPort argument, provide a valid port value, Port Value must be between 1 and 65532"

            Try{
                [WebOperation]::New($Steps,"192.168.100.100",6545454,$($Arguments.BrowserDriverPort))
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Cannot validate DriverPort argument, provide a valid port value, Port Value must be between 1 and 65532"
        }

        It "Should return exception about IP Address" {
            Try{
                $Steps = [Step[]]@([Step]::new('Op','Name',1,'//*',$null))
                [WebOperation]::New($Steps,192.168.100.100,64455,64456)
            }catch{
                $myErr = $_
            }
            $myErr.Exception.Message | Should -Be "Cannot validate RemoteDriverIP argument, provide a valid '[IPAddress]' value"
        }

        It "Should return exception about Browser Debug Port" {
            Try{
                $Steps = [Step[]]@([Step]::new('Op','Name',1,'//*',$null))
                [WebOperation]::New($Steps,"192.168.100.100",64455,0)
            }catch{
                $myErr = $_
            }
            $myErr.Exception.Message | Should -Be "Cannot validate BrowserDebugPort argument, provide a valid port value, Port Value must be between 1 and 65532"
        }
    }

    Context "Start Driver"{
        It "Should not return any exceptions" {
            Try{
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,$($Arguments.BrowserDriverPort),$brTMPFolder,$true)
                $webOperation.StartDriver($Context2)
            }catch{
                $myErr = $_
            }finally{
                if($null -eq $myErr){
                    $webOperation.Close()
                }
            }
            $myErr | Should -Be $null
        }
    }

    Context "Starting Steps without Context"{
        It "Should return Exception about context"{
            Try{
                Start-Sleep -Seconds 1
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,$($Arguments.BrowserDriverPort),$brTMPFolder,$true)
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
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,$($Arguments.BrowserDriverPort),$brTMPFolder,$true)
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
            $Context2.Value | Should -Be "okaraev"
        }
    }

    Context "SetText and AddText Method Test"{
        It "Should set and add text"{
            Try{
                Start-Sleep -Seconds 1
                $webOperation = [WebOperation]::New($driverConf,$WebSteps,$($Arguments.BrowserDriverPort),$brTMPFolder,$true)
                $webOperation.StartDriver($Context2)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null

            Try{
                $webOperation.StartSteps($Context2)
            }catch{
                $myErr = $_
            }
            $Context2.Value | Should -Be "okaraev"
            
            $WebSteps[1].Operation = "AddText"
            $webOperation.SetStep($WebSteps)
            Try{
                $webOperation.SetCurrentStep(2)
                $webOperation.StartSteps($Context2)
            }catch{
                $myErr = $_
            }finally{
                $webOperation.Close()
            }
            $Context2.Value | Should -Be "okaraevokaraev"
        }
    }
}

Describe "Methods" {
    Context "HTTPGet"{
        It "Should return Exception about URI"{
            $Step = [PSCustomObject]@{
                Value = "localhost:65158"
            }
            $Context = [PSCustomObject]::new()
            $Arguments1 = [PSCustomObject]@{
                Step = $Step
            }
            Try{
                $httpget = [HTTPGet]::new()
                $httpget.Execute($Arguments1)
            }catch{
                $myErr1 = $_
            }
            $myErr1.Exception.Message | Should -Be "Cannot find Information exchange Object. Make sure that a argument was added when Starting Steps"

            $Arguments2 = [PSCustomObject]@{
                Step = $Step
                Context = $Context
            }
            Try{
                $httpget.Execute($Arguments2)
            }catch{
                $myErr2 = $_
            }
            $myErr2.Exception.Message | Should -Be "Uri scheme must be either http or https"
        }
        It "Must assign result to the context"{
            $Step = [PSCustomObject]@{
                Value = "http://localhost:$($Arguments.LocalSitePort)/"
            }
            $Context = [PSCustomObject]::new()
            $Arguments = [PSCustomObject]@{
                Step = $Step
                Context = $Context
            }
            Try{
                $httpget = [HTTPGet]::new()
                $httpget.Execute($Arguments)
            }catch{
                $myErr = $_
            }
            $myErr | Should -Be $null
            $Context.HTTPGetValue.RawContent | Should -Match "Powershell Webserver"
        }
    }
}

AfterAll{
    Invoke-WebRequest -Uri "$($localSite)close" -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
    $ps.EndInvoke($psState)
    $ps.Stop()
}
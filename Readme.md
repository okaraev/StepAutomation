# StepAutomation

StepAutomation is a Powershell class module for automating operations.
This module allows administrators, testers to automate sequential steps (configuration based). The module provides classes for automating operations. It's easy to extend the module with adding your own custom operations. The Module also provides classes for automating Web Page actions over Chrome Web Browser (e.g. navigating, clicking, text adding) and some default methods for it. If you have huge amount repetable actions (e.g. getting users from AD, checking their properties, sending emails, opening web page, clicking somewhere) that you want to automate. With this module you can easily implement your custom operations (methods e.g. Get AD users, Open some Web Page, Send someone Email about something) and then simply use this methods in json and execute them. And then when you will have changes in sequence or in methods you will change only the json file, instead of adding or removing lines in the script. If you need to implement new operation yo will only write a method and put it in the json file.

## Installation
---
```powershell
Install-Module StepAutomation
```

## Usage
---
### Importing module
```powershell
# Note! You have to use 'using module' insted of Import-Module to importing classes
using module StepAutomation
```


### Configuration Sample
```json
# Sample Configuration Json
[
    {
      "Name": "AD User Get",
      "Step": 1,
      "Value": "SJohnson",
      "Operation": "ADGetUser"
    },
    {
      "Name": "AD User Set City Property",
      "Step": 2,
      "Value": "City",
      "Operation": "ADSetUserProperty",
      "Source": "Toronto"
    },
    {
      "Name": "Open Local Intranet Site",
      "Step": 3,
      "Value": "https://intranet.local",
      "Operation": "Navigate"
    },
    {
      "Name": "Put Information in the site",
      "Step": 4,
      "Value": "//*[@id=\"loginform\"]/div[3]/div/div/div/ul/li[4]",
      "Operation": "AddText"
    },
    {
      "Name": "Submit the information",
      "Step": 5,
      "Value": "//*[@id=\"loginform\"]/div[3]/div/div/div/ul/li[5]",
      "Operation": "Click"
    }
]
```
### Using 'Operation' class

```powershell
# $StepsFromConfig is a 'Step' array
# You can convert your Json Configuration to Object array with ConvertFrom-Json
$OP = [Operation]::new($StepsFromConfig)
# StartSteps() method of 'Operation' class starts executing all steps
$OP.StartSteps()
# If you have dependend operation in your logic and you need some information exchange between actions
# you can use StartSteps($Context) method of 'Operation' class
$OP.StartSteps([PSCustomObject]@{Key=myKey;Value=myValue})
# Also you can start a single step with StartStep($ThirdStep) or StartStep($ThirdStep,$Context)
$OP.StartStep($StepFromConfig[2])
$OP.StartStep($StepFromConfig[2],[PSCustomObject]@{Key=myKey;Value=myValue})
# You can see default class' methods and your own methods with GetDefaultMethods() and GetMethods()
$OP.GetDefaultMethods()
$OP.GetMethods()
```

### Implementing your own method
```powershell
# The main idea of the custom method implementation is the "Extendibility"
# You can implement as many methods as you need
# Every methods function must take an argument as 'System.Object'
# You can access executing step with the 'Step' property of the object argument
# Also when you need information exchange Context Object will be accessible with the context property
# of the object argument
class SampleMethod : Method{
    SampleMethod()
    : base ('SampleMethod',$this.myFunction){}
    hidden [scriptBlock] $myFunction = {
        param(
            [parameter(Mandatory,Position=0)]
            [System.Object]$Arguments
        )
        $myCurrentStep = $Arguments.Step
        $Context = $Arguments.Context
        if($Context){
            $Context.Key = 'myChangedKey'
            $Context.Value = 'myChangedValue'
        }
    }
}
# Manual using the method
$myMethod = [SampleMethod]::new()
$myMethod.Execute($Arguments)
```
pipeline {
    agent{
        label 'windows'
    }

    stages{
        stage('Checkout'){
            steps{
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
                    extensions: scm.extensions + [[$class: 'CloneOption', noTags: false, reference: '', shallow: true]],
                    submoduleCfg: [],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }

        stage('Tests'){
            steps{
                script{
                    powershell(returnStdout: true,script: '''
                    ./Tests.ps1
                    Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
                    ''')
                }
            }
        }

        stage('Publish'){
            steps{
                script{
                    powershell(returnStdout: true, script: '''
                        using module ./StepAutomation.psd1
                        $gitTag = git tag --contains $(git rev-parse HEAD^)
                        if($null -ne $gitTag){
                            if([System.Version]$gitTag -eq (Get-Module StepAutomation).Version){
                                Try{
                                    Publish-Module -Path './' -NuGetApiKey 'oy2iwd3zy5jsxepgsa6qjaxfkrxxwmmuhlucdm3nhz5hca' -Repository PSGallery -ErrorAction Stop
                                }catch{
                                    throw $_
                                }
                            }else{
                                Write-Host Git Tag version is not equal with current version, Skipping Publish Stage
                            }
                        }else{
                            Write-Host Git Tag is null, Skipping Publish Stage
                        }
                    ''')
                }
            }
        }
    }
}
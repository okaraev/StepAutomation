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
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        Try{
                            $PSGalleryVersion = (Find-Module StepAutomation -ErrorAction Stop).Version
                        }catch{
                            throw "Cannot get PSGallery module $($_.Exception.Message)"
                        }
                        $currentVersion = (Get-Module StepAutomation).Version
                        if($null -ne $PSGalleryVersion){
                            if([System.Version]$PSGalleryVersion -lt $currentVersion){
                                Try{
                                    Publish-Module -Path './' -NuGetApiKey 'oy2iwd3zy5jsxepgsa6qjaxfkrxxwmmuhlucdm3nhz5hca' -Repository PSGallery -ErrorAction Stop
                                    Write-Host Updated to Version $currentVersion
                                }catch{
                                    throw $_
                                }
                            }else{
                                Write-Host PSGallery version is equal with current version $currentVersion, Skipping Publish Stage
                            }
                        }
                    ''')
                }
            }
        }
    }
}
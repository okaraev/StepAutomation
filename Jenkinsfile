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
                            if((Get-PackageProvider).Name -notcontains "NuGet"){
                                $installResult = Install-PackageProvider -Name NuGet -Force -Confirm:$false -ErrorAction Stop
                                Write-Host Installed NuGet Version $($installResult.Version.ToString())
                            }
                        }catch{
                            Throw $_
                        }
                        
                        Try {
                            $PSGalleryVersion = Find-Module StepAutomation -ErrorAction Stop | Select-Object -ExpandProperty Version
                        } catch {
                            Throw "Cannot get Module info from PSGallery; $($_.Exception.Message)"
                        }
                        Try{
                            $localVersion = Get-Module StepAutomation -ErrorAction Stop | Select-Object -ExpandProperty Version
                        } catch{
                            Throw "Cannot get local Module info; $($_.Exception.Message)"
                        }
                        if($null -ne $PSGalleryVersion){
                            if($PSGalleryVersion -lt $localVersion){
                                Try{
                                    Publish-Module -Path './' -NuGetApiKey 'oy2iwd3zy5jsxepgsa6qjaxfkrxxwmmuhlucdm3nhz5hca' -Repository PSGallery -ErrorAction Stop
                                    Write-Host Module Version Updated to $localVersion
                                }catch{
                                    throw $_
                                }
                            }else{
                                Write-Host PSGallery version is equal with current version $localVersion, Skipping Publish Stage
                            }
                        }else{
                            Throw "PSGallery Version is null"
                        }
                    ''')
                }
            }
        }
    }
}
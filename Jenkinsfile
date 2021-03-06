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

        stage('Test'){
            parallel{
                stage('Powershell Desktop Test'){
                    steps{
                        script{
                            powershell(returnStdout: true,script: '''
                                ./Tests.ps1 @{LocalSitePort=65158;BrowserDriverPort=65159}
                            ''')
                        }   
                    }
                }
                stage('Powershell Core Test on Windows'){
                    steps{
                        script{
                            pwsh(returnStdout: true,script: '''
                                ./Tests.ps1 @{LocalSitePort=65156;BrowserDriverPort=65157}
                            ''')
                        }
                    }
                }
                stage('Powershell Core Test on Linux'){
                    agent{
                        label 'pwsh'
                    }
                    steps{
                        script{
                            pwsh(returnStdout: true,script: '''
                                ./Tests.ps1 @{LocalSitePort=65156;BrowserDriverPort=65157}
                            ''')
                        }   
                    }
                }
            }
        }

        stage('Publish'){
            steps{
                withCredentials([string(credentialsId: 'nuget', variable: 'secret')]){
                    script{
                        if(env.BRANCH_NAME == 'master'){
                            powershell(returnStdout: true, script: "./Publish.ps1 -Secret ${secret}")
                        }else{
                            echo("There is no need for Publish stage on branch ${env.BRANCH_NAME}")
                        }
                    }
                }
            }
        }
    }
}
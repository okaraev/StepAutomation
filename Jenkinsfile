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
                    parallel(
                        'Powershell Desktop Test': {
                            powershell(returnStdout: true,script: '''
                            ./Tests.ps1 @{LocalSitePort=65158;BroserDriverPort=65159}
                            ''')
                        },
                        'Powershell Core Test': {
                            pwsh(returnStdout: true,script: '''
                            ./Tests.ps1 @{LocalSitePort=65156;BroserDriverPort=65157}
                            ''')
                        }
                    )
                }
            }
        }

        stage('Publish'){
            steps{
                withCredentials([string(credentialsId: 'nuget', variable: 'secret')]){
                    script{
                        if(env.BRANCH_NAME == 'master'){
                            powershell(returnStdout: true, script: "./Publish.ps1 -Secret ${secret}")
                        }
                    }
                }
            }
        }
    }
}
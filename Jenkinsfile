def commitTag(){
    sh(
        script: 'git tag --contains $(git rev-parse HEAD)',
        returnStdout: true
    ).trim()
}
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
                        Write-Host (Get-Module StepAutomation).Version.ToString()
                    ''')
                }
            }
        }
    }
}
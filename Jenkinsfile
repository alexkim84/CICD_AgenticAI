pipeline {
    agent {
        node {
            label ''
            customWorkspace 'C:\\AgenticAI\\jenkins-workspace\\CICD_AgenticAI'
        }
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    triggers {
        // A local Jenkins server cannot receive a public GitHub webhook.
        // Poll GitHub every two minutes and build when a new commit appears.
        pollSCM('H/2 * * * *')
    }

    stages {
        stage('Process Advisor Verification') {
            steps {
                script {
                    def matlabStatus = bat(
                        returnStatus: true,
                        script: '''
                            "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_ci;"
                        '''
                    )
                    def processStatus = readFile(
                        'artifacts/process-advisor/exit-code.txt'
                    ).trim()
                    if (processStatus != '0') {
                        error "Process Advisor failed with exit code ${processStatus}"
                    }
                    if (matlabStatus != 0) {
                        echo "MATLAB returned ${matlabStatus} after Process Advisor completed successfully."
                    }
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true,
                testResults: 'artifacts/process-advisor/junit/**/*.xml'
            archiveArtifacts allowEmptyArchive: true,
                artifacts: 'artifacts/process-advisor/**/*',
                fingerprint: true
        }
    }
}

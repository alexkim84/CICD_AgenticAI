pipeline {
    agent {
        node {
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
                bat '''
                    "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_ci;"
                '''
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

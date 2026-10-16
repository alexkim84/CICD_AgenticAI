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
        timeout(time: 90, unit: 'MINUTES')
    }

    triggers {
        // A local Jenkins server cannot receive a public GitHub webhook.
        // Poll GitHub every two minutes and build when a new commit appears.
        pollSCM('H/2 * * * *')
    }

    stages {
        stage('Model Advisor Check') {
            steps {
                bat '''
                    "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_stage('CI.ModelAdvisor','ModelAdvisorCheck');"
                '''
            }
        }

        stage('Design Error Check') {
            steps {
                bat '''
                    "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_stage('CI.DesignErrorDetection','DesignErrorCheck');"
                '''
            }
        }

        stage('Requirements Verification') {
            steps {
                bat '''
                    "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_stage('CI.RequirementsMIL','RequirementsVerification');"
                '''
            }
        }

        stage('Back-to-Back Test') {
            steps {
                bat '''
                    "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_stage('CI.MILSILEquivalence','BackToBackTest');"
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

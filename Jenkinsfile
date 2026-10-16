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
                    def requiredResults = [
                        'artifacts/process-advisor/ProcessAdvisorReport.html',
                        'artifacts/process-advisor/junit/CI_CompileModel_crs_controller_JUnit.xml',
                        'artifacts/process-advisor/junit/CI_CheckModelInterface_crs_controller_JUnit.xml',
                        'artifacts/process-advisor/junit/CI_CheckRequirementsTraceability_crs_controller_JUnit.xml'
                    ]
                    def missingResults = requiredResults.findAll {
                        !fileExists(it)
                    }
                    if (missingResults) {
                        error "Process Advisor did not produce: ${missingResults.join(', ')}"
                    }
                    if (matlabStatus != 0) {
                        echo "MATLAB returned ${matlabStatus} after producing complete Process Advisor results."
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

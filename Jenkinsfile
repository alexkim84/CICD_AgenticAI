def runProcessAdvisorStage(taskID, reportName, junitFile) {
    def runToken = java.util.UUID.randomUUID().toString()
    def tokenFile = "artifacts/process-advisor/stage-reports/${reportName}.token"

    def matlabStatus = bat(
        returnStatus: true,
        script: """
            "C:\\Program Files\\MATLAB\\R2026b\\bin\\matlab.exe" -batch "addpath(fullfile(pwd,'ci')); run_process_advisor_stage('${taskID}','${reportName}','${runToken}');"
        """
    )

    if (!fileExists(junitFile)) {
        error "MATLAB returned ${matlabStatus} and did not create ${junitFile}."
    }
    if (!fileExists(tokenFile) || readFile(tokenFile).trim() != runToken) {
        error "Process Advisor did not complete this ${taskID} invocation."
    }

    def junitText = readFile(junitFile)
    def passed = junitText.contains('failures="0"') &&
        junitText.contains('errors="0"')
    if (!passed) {
        error "Process Advisor task ${taskID} reported a verification failure."
    }
    if (matlabStatus != 0) {
        echo "MATLAB returned ${matlabStatus} after the task passed. " +
            "Using the generated JUnit result as the stage status."
    }
}

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
                script {
                    runProcessAdvisorStage(
                        'CI.ModelAdvisor',
                        'ModelAdvisorCheck',
                        'artifacts/process-advisor/junit/CI_ModelAdvisor_crs_controller_JUnit.xml'
                    )
                }
            }
        }

        stage('Design Error Check') {
            steps {
                script {
                    runProcessAdvisorStage(
                        'CI.DesignErrorDetection',
                        'DesignErrorCheck',
                        'artifacts/process-advisor/junit/CI_DesignErrorDetection_crs_controller_JUnit.xml'
                    )
                }
            }
        }

        stage('Requirements Verification') {
            steps {
                script {
                    runProcessAdvisorStage(
                        'CI.RequirementsMIL',
                        'RequirementsVerification',
                        'artifacts/process-advisor/junit/CI_RequirementsMIL_crs_controller_JUnit.xml'
                    )
                }
            }
        }

        stage('Back-to-Back Test') {
            steps {
                script {
                    runProcessAdvisorStage(
                        'CI.MILSILEquivalence',
                        'BackToBackTest',
                        'artifacts/process-advisor/junit/CI_MILSILEquivalence_crs_controller_JUnit.xml'
                    )
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

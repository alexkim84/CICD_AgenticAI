# Local Jenkins + Process Advisor Demo

This repository verifies `models/crs_controller.slx` with Process Advisor.
Jenkins displays separate stages for Model Advisor, design error detection,
requirements verification, and MIL/SIL back-to-back testing.

## Prerequisites

- MATLAB R2026b with Simulink, Simulink Check, and Simulink Requirements
- CI/CD Automation for Simulink Check
- Jenkins LTS and a supported Java runtime
- MATLAB plugin for Jenkins
- Git for Windows

Download Jenkins LTS WAR to `.tools/jenkins/jenkins.war`, then start it:

```powershell
powershell -ExecutionPolicy Bypass -File .\jenkins\start_local_jenkins.ps1
```

## Local verification

Run this command from the repository root:

```powershell
matlab -batch "addpath('ci'); run_process_advisor_ci"
```

Results are written under `artifacts/process-advisor`. The command returns a
nonzero process status when Process Advisor reports a failure.

## Jenkins job

1. Install the MATLAB plugin in Jenkins.
2. Configure the R2026b MATLAB installation under **Manage Jenkins > Tools**.
3. Create a **Pipeline** job and choose **Pipeline script from SCM**.
4. Select Git and enter this repository's GitHub URL.
5. Store a fresh GitHub credential in Jenkins. Never put a token in this repo.
6. Set the script path to `Jenkinsfile`.
7. Run **Build Now** once.

The Jenkinsfile polls GitHub every two minutes. A commit must be pushed to
GitHub before local Jenkins can detect it. For immediate webhook builds, expose
Jenkins through a secure public endpoint and enable the GitHub hook trigger.

## Outputs

- `artifacts/process-advisor/ProcessAdvisorReport.html`
- `artifacts/process-advisor/stage-reports/`
- `artifacts/process-advisor/junit/`
- compile, interface, and traceability evidence files

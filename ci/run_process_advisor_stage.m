function exitCode = run_process_advisor_stage(taskID, reportName, runToken)
%RUN_PROCESS_ADVISOR_STAGE Run one Process Advisor task for Jenkins.

arguments
    taskID (1, 1) string
    reportName (1, 1) string
    runToken (1, 1) string = ""
end

project = setup_ci_project;
cleanup = onCleanup(@() closeProjectAndModels(project));

if exist("runprocess", "file") == 0
    error("CI:MissingProcessAdvisor", ...
        "Install CI/CD Automation for Simulink Check.");
end

artifactRoot = fullfile(project.RootFolder, "artifacts", ...
    "process-advisor");
reportRoot = fullfile(artifactRoot, "stage-reports");
if ~isfolder(reportRoot)
    mkdir(reportRoot);
end

[~, exitCode] = runprocess( ...
    Tasks=taskID, ...
    GenerateJUnitForProcess=true, ...
    GenerateReport=true, ...
    ReportFormat="html-file", ...
    ReportPath=fullfile(reportRoot, reportName + ".html"));

if exitCode == 0 && strlength(runToken) > 0
    writeRunToken(fullfile(reportRoot, reportName + ".token"), runToken);
end

if exitCode ~= 0
    error("CI:ProcessAdvisorStageFailed", ...
        "Process Advisor task %s failed with exit code %d.", ...
        taskID, exitCode);
end
end

function writeRunToken(tokenPath, runToken)
fileID = fopen(tokenPath, "w", "n", "UTF-8");
assert(fileID >= 0, "Unable to create stage token file: %s", tokenPath);
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%s\n", runToken);
end

function closeProjectAndModels(project)
bdclose("all");
if isvalid(project)
    close(project);
end
end

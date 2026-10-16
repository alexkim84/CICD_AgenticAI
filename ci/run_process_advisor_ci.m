function exitCode = run_process_advisor_ci
%RUN_PROCESS_ADVISOR_CI Execute Process Advisor for Jenkins.

project = setup_ci_project;
cleanup = onCleanup(@() closeProjectAndModels(project));

if exist("runprocess", "file") == 0
    error("CI:MissingProcessAdvisor", ...
        "Install CI/CD Automation for Simulink Check.");
end

artifactRoot = fullfile(project.RootFolder, "artifacts", ...
    "process-advisor");
if ~isfolder(artifactRoot)
    mkdir(artifactRoot);
end

[~, exitCode] = runprocess( ...
    Force=true, ...
    GenerateJUnitForProcess=true, ...
    GenerateReport=true, ...
    ReportFormat="html-file", ...
    ReportPath=fullfile(artifactRoot, "ProcessAdvisorReport.html"));

writeExitCode(fullfile(artifactRoot, "exit-code.txt"), exitCode);
if exitCode ~= 0
    error("CI:ProcessAdvisorFailed", ...
        "Process Advisor failed with exit code %d.", exitCode);
end
end

function closeProjectAndModels(project)
bdclose("all");
if isvalid(project)
    close(project);
end
end

function writeExitCode(path, exitCode)
fileID = fopen(path, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%d\n", exitCode);
end

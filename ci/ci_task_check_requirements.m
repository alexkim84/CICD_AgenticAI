function taskResult = ci_task_check_requirements(~)
%CI_TASK_CHECK_REQUIREMENTS Verify requirements and model links exist.

projectRoot = string(currentProject().RootFolder);
outputFolder = fullfile(projectRoot, "artifacts", ...
    "process-advisor", "requirements");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
evidencePath = fullfile(outputFolder, "traceability-summary.csv");

try
    requirementSet = slreq.load(fullfile(projectRoot, "documents", ...
        "crs_req_func_spec.slreqx"));
    requirements = find(requirementSet, Type="Requirement");
    linkSet = slreq.load(fullfile(projectRoot, "models", ...
        "crs_controller.slmx"));
    links = find(linkSet);

    metric = ["Requirements"; "ModelLinks"];
    count = [numel(requirements); numel(links)];
    writetable(table(metric, count), evidencePath);

    assert(~isempty(requirements), "No requirements were loaded.");
    assert(~isempty(links), "No model-to-requirement links were loaded.");
    taskResult = makeResult(padv.TaskStatus.Pass, evidencePath, 2, 0);
catch exception
    errorPath = fullfile(outputFolder, "traceability-error.txt");
    writeText(errorPath, getReport(exception, "extended", ...
        Hyperlinks="off"));
    taskResult = makeResult(padv.TaskStatus.Fail, ...
        [evidencePath errorPath], 0, 1);
end
end

function writeText(path, text)
fileID = fopen(path, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%s", text);
end

function result = makeResult(status, paths, pass, fail)
result = padv.TaskResult;
result.Status = status;
result.OutputPaths = paths;
result.Values = struct(Pass=pass, Warn=0, Fail=fail);
end

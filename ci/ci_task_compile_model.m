function taskResult = ci_task_compile_model(~)
%CI_TASK_COMPILE_MODEL Compile the target model and record evidence.

projectRoot = string(currentProject().RootFolder);
outputFolder = fullfile(projectRoot, "artifacts", ...
    "process-advisor", "compile");
ensureFolder(outputFolder);
evidencePath = fullfile(outputFolder, "model-compile.txt");

try
    modelName = "crs_controller";
    load_system(fullfile(projectRoot, "models", modelName + ".slx"));
    set_param(modelName, "SimulationCommand", "update");
    checksum = Simulink.BlockDiagram.getChecksum(modelName);
    formatText = [ ...
        'Model: %s\nMATLAB: %s\nTimestamp: %s\n' ...
        'Checksum: %s\nResult: PASS\n'];
    text = sprintf(formatText, ...
        modelName, version, string(datetime("now", ...
        TimeZone="Asia/Seoul")), strjoin(string(checksum), " "));
    writeText(evidencePath, text);
    taskResult = makeResult(padv.TaskStatus.Pass, evidencePath, 1, 0);
catch exception
    writeText(evidencePath, getReport(exception, "extended", ...
        Hyperlinks="off"));
    taskResult = makeResult(padv.TaskStatus.Error, evidencePath, 0, 1);
end
end

function ensureFolder(path)
if ~isfolder(path)
    mkdir(path);
end
end

function writeText(path, text)
fileID = fopen(path, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%s", text);
end

function result = makeResult(status, path, pass, fail)
result = padv.TaskResult;
result.Status = status;
result.OutputPaths = path;
result.Values = struct(Pass=pass, Warn=0, Fail=fail);
end

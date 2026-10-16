function taskResult = ci_task_check_interface(~)
%CI_TASK_CHECK_INTERFACE Verify the controller root interface.

projectRoot = string(currentProject().RootFolder);
outputFolder = fullfile(projectRoot, "artifacts", ...
    "process-advisor", "interface");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
evidencePath = fullfile(outputFolder, "model-interface.csv");

try
    modelName = "crs_controller";
    load_system(fullfile(projectRoot, "models", modelName + ".slx"));
    set_param(modelName, "SimulationCommand", "update");
    inputs = find_system(modelName, SearchDepth=1, BlockType="Inport");
    outputs = find_system(modelName, SearchDepth=1, BlockType="Outport");
    direction = [repmat("Input", numel(inputs), 1); ...
        repmat("Output", numel(outputs), 1)];
    names = string([get_param(inputs, "Name"); get_param(outputs, "Name")]);
    writetable(table(direction, names), evidencePath);

    assert(numel(inputs) == 11, ...
        "Expected 11 inputs but found %d.", numel(inputs));
    assert(numel(outputs) == 5, ...
        "Expected 5 outputs but found %d.", numel(outputs));
    taskResult = makeResult(padv.TaskStatus.Pass, evidencePath, 2, 0);
catch exception
    errorPath = fullfile(outputFolder, "interface-error.txt");
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

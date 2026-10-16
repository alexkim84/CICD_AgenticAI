function processmodel(pm)
%PROCESSMODEL Define the Jenkins verification process for crs_controller.

arguments
    pm padv.ProcessModel
end

pm.DefaultOutputDirectory = fullfile("$PROJECTROOT$", "artifacts", "process-advisor");
pm.JUnitReportPath = fullfile("$DEFAULTOUTPUTDIR$", "junit");

projectRoot = string(currentProject().RootFolder);
modelQuery = padv.builtin.query.FindFileWithAddress( ...
    Type="sl_model_file", ...
    Path=fullfile(projectRoot, "models", "crs_controller.slx"), ...
    Name="CruiseController");
pm.addQuery(modelQuery);

compileTask = padv.Task("CI.CompileModel");
compileTask.Title = "Compile Cruise Controller";
compileTask.DescriptionText = ...
    "Load and update crs_controller and record its interface and checksum.";
compileTask.RequiredIterationArtifactType = "sl_model_file";
compileTask.IterationQuery = modelQuery;
compileTask.addInputQueries(padv.builtin.query.GetIterationArtifact);
compileTask.Action = @ci_task_compile_model;
compileTask.OutputDirectory = fullfile("$DEFAULTOUTPUTDIR$", "compile");
compileTask.AlwaysRun = true;
pm.addTask(compileTask);

interfaceTask = padv.Task("CI.CheckModelInterface");
interfaceTask.Title = "Check Model Interface";
interfaceTask.DescriptionText = ...
    "Verify the expected 11 inputs and 5 outputs of crs_controller.";
interfaceTask.RequiredIterationArtifactType = "sl_model_file";
interfaceTask.IterationQuery = modelQuery;
interfaceTask.addInputQueries(padv.builtin.query.GetIterationArtifact);
interfaceTask.Action = @ci_task_check_interface;
interfaceTask.OutputDirectory = fullfile("$DEFAULTOUTPUTDIR$", "interface");
pm.addTask(interfaceTask);
interfaceTask.dependsOn(compileTask);

requirementsTask = padv.Task("CI.CheckRequirementsTraceability");
requirementsTask.Title = "Check Requirements Traceability";
requirementsTask.DescriptionText = ...
    "Load the requirement and link sets and verify that traceability data exists.";
requirementsTask.RequiredIterationArtifactType = "sl_model_file";
requirementsTask.IterationQuery = modelQuery;
requirementsTask.addInputQueries( ...
    padv.builtin.query.GetIterationArtifact);
requirementsTask.InputDependencyQuery = ...
    padv.builtin.query.GetDependentArtifacts( ...
    IncludeRequirementLinkFiles=true);
requirementsTask.Action = @ci_task_check_requirements;
requirementsTask.OutputDirectory = fullfile("$DEFAULTOUTPUTDIR$", "requirements");
pm.addTask(requirementsTask);
requirementsTask.dependsOn(interfaceTask);
end

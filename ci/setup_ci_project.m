function project = setup_ci_project
%SETUP_CI_PROJECT Open and configure the project for CI execution.

ciFolder = fileparts(mfilename("fullpath"));
projectRoot = fileparts(ciFolder);
projectFile = fullfile(projectRoot, ...
    "RequirementsDefinitionforaCruiseControlM.prj");

try
    project = currentProject;
    if ~strcmp(project.RootFolder, projectRoot)
        close(project);
        project = openProject(projectFile);
    end
catch
    project = openProject(projectFile);
end

folders = ["models", "data", "documents", "scripts", "tests", ...
    fullfile("tests", "test_case"), ...
    fullfile("tests", "test_file"), ...
    fullfile("tests", "test_harness"), ...
    fullfile("tests", "test_results", "sldv_generated_relaxed"), ...
    fullfile("tests", "test_results", "sil_coverage_inputs"), ...
    "ci"];
for folder = folders
    folderPath = fullfile(projectRoot, folder);
    if isfolder(folderPath)
        addPath(project, folderPath);
    end
end

workFolder = fullfile(projectRoot, "work");
if ~isfolder(workFolder)
    mkdir(workFolder);
end
project.SimulinkCacheFolder = workFolder;
project.SimulinkCodeGenFolder = workFolder;
project.DependencyCacheFile = fullfile(workFolder, ...
    "dependency-cache.graphml");

files = [ ...
    ".gitattributes"
    ".gitignore"
    "processmodel.m"
    "Jenkinsfile"
    "README_CI.md"
    fullfile("ci", "run_process_advisor_ci.m")
    fullfile("ci", "setup_ci_project.m")
    fullfile("ci", "ci_task_compile_model.m")
    fullfile("ci", "ci_task_check_interface.m")
    fullfile("ci", "ci_task_check_requirements.m")
    fullfile("ci", "ci_task_run_mil_tests.m")
    fullfile("ci", "ci_task_run_sil_tests.m")
    fullfile("ci", "ci_run_simulink_test_file.m")
    fullfile("config", "process_advisor_settings.json")
    fullfile("data", "auto_modeling_guidelines.json")
    fullfile("models", "crs_controller_harnessInfo.xml")
    fullfile("documents", "crs_req_func_ears.slreqx")
    fullfile("tests", "test_file", ...
        "crs_controller_requirements_MIL.mldatx")
    fullfile("tests", "test_file", ...
        "crs_controller_requirements_MIL~mldatx.slmx")
    fullfile("tests", "test_file", ...
        "crs_controller_mil_sil_equivalence_tests.mldatx")
    fullfile("tests", "test_harness", "crs_controller_harness.slx")
    fullfile("jenkins", "start_local_jenkins.ps1")];
for file = files
    filePath = fullfile(projectRoot, file);
    if isfile(filePath)
        addFile(project, filePath);
    end
end

assetPatterns = [ ...
    fullfile("tests", "test_case", "*"), ...
    fullfile("tests", "test_results", "sldv_generated_relaxed", "*.mat"), ...
    fullfile("tests", "test_results", "sil_coverage_inputs", "*.mat")];
for pattern = assetPatterns
    assets = dir(fullfile(projectRoot, pattern));
    for assetIndex = 1:numel(assets)
        if ~assets(assetIndex).isdir
            addFile(project, fullfile(assets(assetIndex).folder, ...
                assets(assetIndex).name));
        end
    end
end

assert(isfile(fullfile(projectRoot, "models", "crs_controller.slx")), ...
    "The target model does not exist.");
assert(isfile(fullfile(projectRoot, "documents", ...
    "crs_req_func_spec.slreqx")), "The requirement set does not exist.");

updateDependencies(project);
runChecks(project);
end

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

folders = ["models", "data", "documents", "scripts", "tests", "ci"];
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
    fullfile("jenkins", "start_local_jenkins.ps1")];
for file = files
    filePath = fullfile(projectRoot, file);
    if isfile(filePath)
        addFile(project, filePath);
    end
end

assert(isfile(fullfile(projectRoot, "models", "crs_controller.slx")), ...
    "The target model does not exist.");
assert(isfile(fullfile(projectRoot, "documents", ...
    "crs_req_func_spec.slreqx")), "The requirement set does not exist.");

updateDependencies(project);
end

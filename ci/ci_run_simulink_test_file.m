function taskResult = ci_run_simulink_test_file(fileName, folderName, baseName)
%CI_RUN_SIMULINK_TEST_FILE Run a Simulink Test file and export CI evidence.

projectRoot = string(currentProject().RootFolder);
testPath = fullfile(projectRoot, "tests", "test_file", fileName);
outputFolder = fullfile(projectRoot, "artifacts", ...
    "process-advisor", folderName);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

resultsPath = fullfile(outputFolder, baseName + "_Results.mldatx");
reportPath = fullfile(outputFolder, baseName + "_Report.pdf");
summaryPath = fullfile(outputFolder, baseName + "_Summary.csv");

try
    sltest.testmanager.clearResults;
    testFile = sltest.testmanager.load(testPath);
    cleanup = onCleanup(@() closeTestFile(testFile));
    resultSet = run(testFile);

    sltest.testmanager.exportResults(resultSet, resultsPath);
    sltest.testmanager.report(resultSet, reportPath, ...
        IncludeTestResults=0, ...
        IncludeCoverageResult=true, ...
        IncludeSimulationMetadata=true, ...
        IncludeTestRequirement=true, ...
        IncludeErrorMessages=true, ...
        LaunchReport=false);

    [names, outcomes] = collectCaseResults(resultSet);
    writetable(table(names, outcomes, ...
        VariableNames=["TestCase", "Outcome"]), summaryPath);

    failures = resultSet.NumFailed + resultSet.NumIncomplete + ...
        resultSet.NumUntested;
    if failures == 0 && resultSet.NumPassed > 0
        status = padv.TaskStatus.Pass;
    else
        status = padv.TaskStatus.Fail;
    end
    taskResult = makeResult(status, ...
        [resultsPath reportPath summaryPath], resultSet.NumPassed, failures);
catch exception
    errorPath = fullfile(outputFolder, baseName + "_Error.txt");
    writeText(errorPath, getReport(exception, "extended", ...
        Hyperlinks="off"));
    taskResult = makeResult(padv.TaskStatus.Error, errorPath, 0, 1);
end
end

function [names, outcomes] = collectCaseResults(resultSet)
fileResults = resultSet.getTestFileResults;
names = strings(0, 1);
outcomes = strings(0, 1);
for fileIndex = 1:numel(fileResults)
    suiteResults = fileResults(fileIndex).getTestSuiteResults;
    for suiteIndex = 1:numel(suiteResults)
        caseResults = suiteResults(suiteIndex).getTestCaseResults;
        for caseIndex = 1:numel(caseResults)
            names(end + 1, 1) = string(caseResults(caseIndex).Name); %#ok<AGROW>
            outcomes(end + 1, 1) = ...
                string(caseResults(caseIndex).Outcome); %#ok<AGROW>
        end
    end
end
assert(~isempty(names), "No Simulink Test case results were produced.");
end

function closeTestFile(testFile)
try
    testFile.close;
catch
end
end

function result = makeResult(status, paths, pass, fail)
result = padv.TaskResult;
result.Status = status;
result.OutputPaths = paths;
result.Values = struct(Pass=pass, Warn=0, Fail=fail);
end

function writeText(path, text)
fileID = fopen(path, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%s", text);
end

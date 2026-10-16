function taskResult = ci_run_simulink_test_file( ...
    fileName, folderName, baseName, excludedTests, includedTests)
%CI_RUN_SIMULINK_TEST_FILE Run a Simulink Test file and export CI evidence.

arguments
    fileName (1, 1) string
    folderName (1, 1) string
    baseName (1, 1) string
    excludedTests string = strings(0, 1)
    includedTests string = strings(0, 1)
end

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
    bdclose("all");
    clear mex;
    sltest.testmanager.clearResults;
    testFile = sltest.testmanager.load(testPath);
    cleanup = onCleanup(@() closeTestFile(testFile));
    selectTests(testFile, excludedTests, includedTests);
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

function selectTests(testFile, excludedTests, includedTests)
testCases = testFile.getAllTestCases;
testNames = string({testCases.Name});
if ~isempty(includedTests)
    missing = setdiff(includedTests, testNames);
    assert(isempty(missing), ...
        "CI include list does not match test cases: %s", ...
        strjoin(missing, ", "));
    for testCase = reshape(testCases, 1, [])
        testCase.Enabled = any(string(testCase.Name) == includedTests);
        if ~testCase.Enabled
            testCase.ReasonForDisabling = ...
                "Not selected for the CI smoke suite.";
        end
    end
end
for testName = reshape(excludedTests, 1, [])
    match = testNames == testName;
    assert(any(match), "CI exclusion does not match a test case: %s", ...
        testName);
    for testCase = reshape(testCases(match), 1, [])
        testCase.Enabled = false;
        testCase.ReasonForDisabling = ...
            "Excluded from the CI smoke suite; tracked for model correction.";
    end
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

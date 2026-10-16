function taskResult = ci_task_run_mil_tests(~)
%CI_TASK_RUN_MIL_TESTS Run requirements-based MIL tests.

taskResult = ci_run_simulink_test_file( ...
    "crs_controller_requirements_MIL.mldatx", ...
    "requirements-mil", "RequirementsMIL");
end

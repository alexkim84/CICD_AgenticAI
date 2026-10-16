function taskResult = ci_task_run_sil_tests(~)
%CI_TASK_RUN_SIL_TESTS Run MIL/SIL back-to-back equivalence tests.

taskResult = ci_run_simulink_test_file( ...
    "crs_controller_mil_sil_equivalence_tests.mldatx", ...
    "mil-sil", "MIL_SIL_Equivalence");
end

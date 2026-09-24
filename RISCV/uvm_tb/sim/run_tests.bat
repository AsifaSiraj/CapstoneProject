@echo off
setlocal EnableDelayedExpansion

REM =====================================================================
REM run_tests.bat
REM Compile once, then run all 7 UVM tests using QuestaSim 2024.1
REM =====================================================================

REM ---------------------------------------------------------------------
REM Force QuestaSim 2024.1
REM ---------------------------------------------------------------------
set "QUESTA=C:\questasim64_2024.1\win64"

set "VSIM=%QUESTA%\vsim.exe"
set "VLOG=%QUESTA%\vlog.exe"
set "VLIB=%QUESTA%\vlib.exe"

REM ---------------------------------------------------------------------
REM Go to uvm_tb directory
REM ---------------------------------------------------------------------
cd /d "%~dp0\.."

echo.
echo ================================================================
echo Using QuestaSim:
echo VSIM = %VSIM%
echo VLOG = %VLOG%
echo VLIB = %VLIB%
echo ================================================================
echo.

if not exist "%VSIM%" (
    echo ERROR: QuestaSim vsim.exe not found!
    echo Expected:
    echo %VSIM%
    exit /b 1
)

if not exist "%VLOG%" (
    echo ERROR: QuestaSim vlog.exe not found!
    exit /b 1
)

if not exist "%VLIB%" (
    echo ERROR: QuestaSim vlib.exe not found!
    exit /b 1
)

REM ---------------------------------------------------------------------
REM [1/8] Clean work library
REM ---------------------------------------------------------------------
echo [1/8] Cleaning work library...

if exist work (
    rmdir /s /q work
)

REM ---------------------------------------------------------------------
REM [2/8] Create work library
REM ---------------------------------------------------------------------
echo [2/8] Creating work library...

"%VLIB%" work

if errorlevel 1 (
    echo ERROR: vlib failed.
    goto fail
)

REM ---------------------------------------------------------------------
REM [3/8] Compile RTL + UVM
REM ---------------------------------------------------------------------
echo [3/8] Compiling design and UVM environment...
echo.

"%VLOG%" -sv +incdir+sv -f sim\filelist.f

if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed.
    goto fail
)

echo.
echo Compilation successful.
echo.

REM ---------------------------------------------------------------------
REM Test list
REM ---------------------------------------------------------------------
set "TESTS=risc_v_golden_test risc_v_single_bit_test risc_v_double_bit_test risc_v_mmio_test risc_v_stress_test risc_v_periph_test risc_v_failsafe_test"

set /a PASS_COUNT=0
set /a FAIL_COUNT=0

REM ---------------------------------------------------------------------
REM [4/8] Run all tests
REM ---------------------------------------------------------------------
echo [4/8] Running UVM tests...
echo.

for %%T in (%TESTS%) do (

    echo.
    echo ================================================================
    echo Running: %%T
    echo ================================================================

    "%VSIM%" -c work.risc_v_uvm_tb +UVM_TESTNAME=%%T +UVM_VERBOSITY=UVM_MEDIUM -do "run -all; quit -f" > "sim\%%T.log" 2>&1

    REM -------------------------------------------------------------
    REM First check simulator exit status.
    REM If vsim itself failed, test FAILS.
    REM -------------------------------------------------------------
    if errorlevel 1 (
        echo [FAIL] %%T - QuestaSim process failed
        set /a FAIL_COUNT+=1
    ) else (

        REM ---------------------------------------------------------
        REM Check UVM_ERROR
        REM ---------------------------------------------------------
        findstr /C:"UVM_ERROR :    0" "sim\%%T.log" >nul

        if errorlevel 1 (
            echo [FAIL] %%T - UVM_ERROR found
            set /a FAIL_COUNT+=1
        ) else (

            REM -----------------------------------------------------
            REM Check UVM_FATAL
            REM -----------------------------------------------------
            findstr /C:"UVM_FATAL :    0" "sim\%%T.log" >nul

            if errorlevel 1 (
                echo [FAIL] %%T - UVM_FATAL found
                set /a FAIL_COUNT+=1
            ) else (
                echo [PASS] %%T
                set /a PASS_COUNT+=1
            )
        )
    )
)

REM ---------------------------------------------------------------------
REM [5/8] Summary
REM ---------------------------------------------------------------------
echo.
echo ================================================================
echo                     TEST SUMMARY
echo ================================================================
echo.
echo Total Tests : 7
echo Passed      : !PASS_COUNT!
echo Failed      : !FAIL_COUNT!
echo.

REM ---------------------------------------------------------------------
REM [6/8] Check final result
REM ---------------------------------------------------------------------
if !PASS_COUNT! EQU 7 if !FAIL_COUNT! EQU 0 (
    echo ================================================================
    echo ALL 7 TESTS PASSED
    echo ================================================================
    echo.
    echo Logs:
    echo uvm_tb\sim\*.log
    echo.
    exit /b 0
)

echo ================================================================
echo SOME TESTS FAILED
echo ================================================================
echo.
echo Check individual logs:
echo uvm_tb\sim\risc_v_golden_test.log
echo uvm_tb\sim\risc_v_single_bit_test.log
echo uvm_tb\sim\risc_v_double_bit_test.log
echo uvm_tb\sim\risc_v_mmio_test.log
echo uvm_tb\sim\risc_v_stress_test.log
echo uvm_tb\sim\risc_v_periph_test.log
echo uvm_tb\sim\risc_v_failsafe_test.log
echo.

exit /b 1

REM ---------------------------------------------------------------------
REM Compilation failure
REM ---------------------------------------------------------------------
:fail

echo.
echo ================================================================
echo BUILD FAILED
echo ================================================================
echo.
exit /b 1
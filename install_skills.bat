@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo  Coding Agent Skills Installer ^& Updater
echo  Supports: Folders, .skill files, .zip files
echo ===================================================
echo.

:: Set Source directory to the location of this script
set "SOURCE_DIR=%~dp0"
if "%SOURCE_DIR:~-1%"=="\" set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

:: =====================================================================
:: CONFIGURATION: TARGET DIRECTORIES
:: Add or remove installation directories for different coding agents here.
:: Enclose each path in double quotes and separate them by a space.
:: =====================================================================
set TARGET_DIRS="C:\Users\vjsin\.gemini\config\skills" "C:\Users\vjsin\.codex\skills" "C:\Users\vjsin\.opencode\skills"

:: Temp directory used for extracting .skill / .zip archives
set "TEMP_EXTRACT=%TEMP%\agy_skills_tmp"

echo Source Directory: !SOURCE_DIR!
echo.

:: ─────────────────────────────────────────────────────────────────────
:: FUNCTION: process one source item (dir, .skill, or .zip) into DEST
:: Called as:  call :SYNC_SKILL <source_path> <skill_name> <dest_dir>
:: ─────────────────────────────────────────────────────────────────────

:: ─── PASS 1: Directories ─────────────────────────────────────────────
echo [1/3] Scanning folders...
for %%T in (%TARGET_DIRS%) do (
    set "DEST=%%~T"

    echo ---------------------------------------------------
    echo Target: !DEST!
    echo ---------------------------------------------------

    if not exist "!DEST!" (
        echo   Creating directory: !DEST!
        mkdir "!DEST!"
    )

    for /d %%S in ("!SOURCE_DIR!\*") do (
        set "SKILL_NAME=%%~nxS"
        if /I not "!SKILL_NAME!"==".git" (
            echo   [DIR]  Installing/Updating: !SKILL_NAME!
            robocopy "%%S" "!DEST!\!SKILL_NAME!" /E /XO /NFL /NDL /NJH /NJS /NC /NS /NP
            if !ERRORLEVEL! GEQ 8 (
                echo         [ERROR] robocopy failed for !SKILL_NAME!
            ) else (
                echo         [OK]
            )
        )
    )
    echo.
)

:: ─── PASS 2: .skill files ────────────────────────────────────────────
echo [2/3] Scanning .skill files...
for %%F in ("!SOURCE_DIR!\*.skill") do (
    set "ARCHIVE=%%~fF"
    set "SKILL_NAME=%%~nF"

    echo   [.skill] Extracting: !SKILL_NAME!

    :: Clean and create temp extract folder
    if exist "!TEMP_EXTRACT!\!SKILL_NAME!" rmdir /s /q "!TEMP_EXTRACT!\!SKILL_NAME!"
    mkdir "!TEMP_EXTRACT!\!SKILL_NAME!"

    :: Write a temp PowerShell script to avoid inline escaping issues with dotted filenames
    set "PS1_TMP=%TEMP%\agy_extract_tmp.ps1"
    echo Expand-Archive -LiteralPath "!ARCHIVE!" -DestinationPath "!TEMP_EXTRACT!\!SKILL_NAME!" -Force > "!PS1_TMP!"
    powershell -NoProfile -ExecutionPolicy Bypass -File "!PS1_TMP!" 2>nul
    del /q "!PS1_TMP!" 2>nul

    if !ERRORLEVEL! NEQ 0 (
        echo          [ERROR] Failed to extract !SKILL_NAME!.skill
    ) else (
        :: Detect if archive had a single root folder - if so, use that as skill root
        for /f "delims=" %%R in ('dir /b /ad "!TEMP_EXTRACT!\!SKILL_NAME!" 2^>nul') do (
            set "INNER=%%R"
        )
        :: Count dirs inside extract folder
        set "DIR_COUNT=0"
        for /d %%D in ("!TEMP_EXTRACT!\!SKILL_NAME!\*") do set /a DIR_COUNT+=1

        if !DIR_COUNT! EQU 1 (
            :: Check if the single folder contains SKILL.md (skill root)
            if exist "!TEMP_EXTRACT!\!SKILL_NAME!\!INNER!\SKILL.md" (
                set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!\!INNER!"
                set "SKILL_NAME=!INNER!"
            ) else (
                set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!"
            )
        ) else (
            set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!"
        )

        for %%T in (%TARGET_DIRS%) do (
            set "DEST=%%~T"
            if not exist "!DEST!" mkdir "!DEST!"
            echo          -> Syncing to !DEST!\!SKILL_NAME!
            robocopy "!EXTRACT_ROOT!" "!DEST!\!SKILL_NAME!" /E /XO /NFL /NDL /NJH /NJS /NC /NS /NP
            if !ERRORLEVEL! GEQ 8 (
                echo             [ERROR] Sync failed.
            ) else (
                echo             [OK]
            )
        )
    )
    echo.
)

:: ─── PASS 3: .zip files ──────────────────────────────────────────────
echo [3/3] Scanning .zip files...
for %%F in ("!SOURCE_DIR!\*.zip") do (
    set "ARCHIVE=%%~fF"
    set "SKILL_NAME=%%~nF"

    echo   [.zip]  Extracting: !SKILL_NAME!

    :: Clean and create temp extract folder
    if exist "!TEMP_EXTRACT!\!SKILL_NAME!" rmdir /s /q "!TEMP_EXTRACT!\!SKILL_NAME!"
    mkdir "!TEMP_EXTRACT!\!SKILL_NAME!"

    :: Write a temp PowerShell script to avoid inline escaping issues
    set "PS1_TMP=%TEMP%\agy_extract_tmp.ps1"
    echo Expand-Archive -LiteralPath "!ARCHIVE!" -DestinationPath "!TEMP_EXTRACT!\!SKILL_NAME!" -Force > "!PS1_TMP!"
    powershell -NoProfile -ExecutionPolicy Bypass -File "!PS1_TMP!" 2>nul
    del /q "!PS1_TMP!" 2>nul

    if !ERRORLEVEL! NEQ 0 (
        echo          [ERROR] Failed to extract !SKILL_NAME!.zip
    ) else (
        :: Detect if archive had a single root folder
        for /f "delims=" %%R in ('dir /b /ad "!TEMP_EXTRACT!\!SKILL_NAME!" 2^>nul') do (
            set "INNER=%%R"
        )
        set "DIR_COUNT=0"
        for /d %%D in ("!TEMP_EXTRACT!\!SKILL_NAME!\*") do set /a DIR_COUNT+=1

        if !DIR_COUNT! EQU 1 (
            if exist "!TEMP_EXTRACT!\!SKILL_NAME!\!INNER!\SKILL.md" (
                set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!\!INNER!"
                set "SKILL_NAME=!INNER!"
            ) else (
                set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!"
            )
        ) else (
            set "EXTRACT_ROOT=!TEMP_EXTRACT!\!SKILL_NAME!"
        )

        for %%T in (%TARGET_DIRS%) do (
            set "DEST=%%~T"
            if not exist "!DEST!" mkdir "!DEST!"
            echo          -> Syncing to !DEST!\!SKILL_NAME!
            robocopy "!EXTRACT_ROOT!" "!DEST!\!SKILL_NAME!" /E /XO /NFL /NDL /NJH /NJS /NC /NS /NP
            if !ERRORLEVEL! GEQ 8 (
                echo             [ERROR] Sync failed.
            ) else (
                echo             [OK]
            )
        )
    )
    echo.
)

:: ─── Cleanup ─────────────────────────────────────────────────────────
if exist "!TEMP_EXTRACT!" rmdir /s /q "!TEMP_EXTRACT!"

echo ===================================================
echo  All skills installed/updated successfully!
echo ===================================================
pause

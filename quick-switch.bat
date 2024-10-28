@echo off
setlocal enabledelayedexpansion

rem Define the file to store last accessed folder
set "last_accessed_file=%USERPROFILE%\\.last_accessed_dev_folder"

rem Check if --last parameter is provided
if "%~1"=="--last" (
    if exist "!last_accessed_file!" (
        set /p last_folder=<"!last_accessed_file!"
        if exist "!last_folder!" (
            set "selected=!last_folder!"
            goto process_folder
        ) else (
            echo Last accessed folder does not exist anymore.
            exit /b 1
        )
    ) else (
        echo No last accessed folder found.
        exit /b 1
    )
    goto :eof
)

rem Handle directory selection
if "%~1"=="" (
    echo Recent folder: 
    if exist "!last_accessed_file!" (
        set /p last_folder=<"!last_accessed_file!"
        echo Last accessed: !last_folder!
        echo.
    )
    
    rem Use fzf to select directory, with error handling
    set "fzf_error="
    for /f "delims=" %%i in ('dir /b /ad "D:\*" 2^>nul ^| fzf 2^>nul') do (
        set "selected=D:\%%i"
        set "fzf_error=0"
    )
    
    if not defined fzf_error (
        echo Error: fzf selection failed or no directories found.
        exit /b 1
    )
) else (
    set "selected=%~1"
)

if not defined selected (
    echo No directory selected.
    exit /b 1
)

rem Validate selected directory exists
if not exist "!selected!" (
    echo Directory does not exist: !selected!
    exit /b 1
)

rem Store the selected folder as last accessed (create directory if needed)
echo !selected!>"!last_accessed_file!"

:process_folder
rem Clean the folder name for use in title
for %%i in ("!selected!") do set "selected_name=%%~nxi"
set "selected_name=!selected_name:.=_!"

rem Initialize variables
set "is_python=0"
set "is_node=0"
set "is_react=0"
set "is_next=0"
set "is_git=0"
set "has_venv=0"
set "has_docker=0"
set "has_db=0"
set "has_env_file=0"
set "running_on_port=0"
set "venv_path="
set "venv_activate="
set "is_dev_project=0"
set "has_pdf=0"
set "has_text=0"

rem Project type detection with error handling
if exist "!selected!\package.json" (
    set "is_node=1"
    set "is_dev_project=1"
    findstr /m "\"react\"" "!selected!\package.json" >nul 2>&1
    if !errorlevel! equ 0 set "is_react=1"
    findstr /m "\"next\"" "!selected!\package.json" >nul 2>&1
    if !errorlevel! equ 0 set "is_next=1"
)

rem Python project detection
if exist "!selected!\requirements.txt" set "is_python=1" & set "is_dev_project=1"
if exist "!selected!\setup.py" set "is_python=1" & set "is_dev_project=1"
if exist "!selected!\pyproject.toml" set "is_python=1" & set "is_dev_project=1"

rem Check for development files
for %%i in (py js tsx jsx ts html css) do (
    if exist "!selected!\*.%%i" set "is_dev_project=1"
)

rem Check for PDFs and text files
if exist "!selected!\*.pdf" set "has_pdf=1"
if exist "!selected!\*.txt" set "has_text=1"

rem Additional project detection
if exist "!selected!\.git" set "is_git=1"
if exist "!selected!\docker-compose.yml" set "has_docker=1"
if exist "!selected!\Dockerfile" set "has_docker=1"
if exist "!selected!\*.sql" set "has_db=1"
if exist "!selected!\migrations" set "has_db=1"
if exist "!selected!\db.sqlite3" set "has_db=1"
if exist "!selected!\.env" set "has_env_file=1"
if exist "!selected!\.env.local" set "has_env_file=1"
if exist "!selected!\.env.development" set "has_env_file=1"

rem Virtual environment detection
for %%i in (env venv .env .venv) do (
    if exist "!selected!\%%i\Scripts\activate.bat" (
        set "has_venv=1"
        set "venv_path=!selected!\%%i"
        set "venv_activate=%%i\Scripts\activate.bat"
    )
)

rem Build command string
set "cmd_commands=cd /d "!selected!""

rem Add Git information if available
if "!is_git!"=="1" (
    set "cmd_commands=!cmd_commands! && echo. && echo Git Status: && git status --short && echo. && echo Current Branch: && git branch --show-current && echo. && echo Recent Commits: && git log --oneline -5"
)

rem Python environment setup
if "!has_venv!"=="1" (
    set "cmd_commands=!cmd_commands! && echo. && echo Activating Python virtual environment from !venv_activate! && call !venv_activate!"
)

rem Node.js project information
if "!is_node!"=="1" (
    set "cmd_commands=!cmd_commands! && echo. && echo Node.js project detected"
    if "!is_next!"=="1" (
        set "cmd_commands=!cmd_commands! && echo Next.js project detected && echo Available commands: && echo npm run dev - Start development server && echo npm run build - Build for production && echo npm start - Start production server"
    ) else if "!is_react!"=="1" (
        set "cmd_commands=!cmd_commands! && echo React project detected && echo Available commands: && echo npm start - Start development server && echo npm run build - Build for production"
    )
    
    rem Check for node_modules
    if not exist "!selected!\node_modules" (
        set "cmd_commands=!cmd_commands! && echo. && echo node_modules not found, running npm install..."
        set "cmd_commands=!cmd_commands! && npm install"
    )
)

rem Python project information
if "!is_python!"=="1" (
    if "!has_venv!"=="0" (
        set "cmd_commands=!cmd_commands! && echo. && echo Python project detected but no virtual environment found && echo To create one, use: && echo python -m venv env"
    )
)

rem Set window title
set "window_title=DEV - !selected_name!"
if "!is_next!"=="1" set "window_title=!window_title! (Next.js)"
if "!is_react!"=="1" set "window_title=!window_title! (React)"
if "!is_node!"=="1" set "window_title=!window_title! (Node.js)"
if "!is_python!"=="1" set "window_title=!window_title! (Python)"
if "!has_venv!"=="1" set "window_title=!window_title! [venv]"
if "!is_git!"=="1" set "window_title=!window_title! [git]"
if "!has_docker!"=="1" set "window_title=!window_title! [docker]"

rem Handle different types of content
if "!is_dev_project!"=="1" (
    rem Verify VSCode is available
    where code >nul 2>&1
    if !errorlevel! equ 0 (
        start "" code "!selected!"
    ) else (
        echo Warning: VSCode ^(code^) command not found. Please ensure VSCode is installed and in your PATH.
    )
    
    rem Start development servers
    if "!is_react!"=="1" (
        start "!window_title! - React Dev Server" cmd.exe /K "cd /d "!selected!" && npm run dev"
    ) else if "!is_next!"=="1" (
        start "!window_title! - Next.js Dev Server" cmd.exe /K "cd /d "!selected!" && npm run dev"
    )
) else if "!has_pdf!"=="1" (
    for %%i in ("!selected!\*.pdf") do start "" "%%i"
    echo Opening PDF files with default viewer...
) else if "!has_text!"=="1" (
    for %%i in ("!selected!\*.txt") do start "" notepad "%%i"
    echo Opening text files with Notepad...
) else (
    start "" explorer "!selected!"
)

rem Start main terminal window
start "!window_title!" cmd.exe /K "!cmd_commands!"

endlocal
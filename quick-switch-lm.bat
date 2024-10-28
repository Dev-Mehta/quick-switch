#!/bin/bash

if [ -z "$1" ]; then
    selected=$(ls -d */ | fzf)
    if [ -z "$selected" ]; then
        exit 0
    fi
else
    selected="$1"
fi

selected_name=$(basename "$selected" | tr '.' '_')
is_python=0
is_node=0
is_react=0
is_next=0
has_venv=0

if [ -f "${selected}package.json" ]; then
    is_node=1
    if grep -q '"react"' "${selected}package.json"; then
        is_react=1
    fi
    if grep -q '"next"' "${selected}package.json"; then
        is_next=1
    fi
fi

if [ -f "${selected}requirements.txt" ] || [ -f "${selected}setup.py" ] || [ -f "${selected}pyproject.toml" ]; then
    is_python=1
fi

for venv in env venv .env .venv; do
    if [ -f "${selected}${venv}/bin/activate" ]; then
        has_venv=1
        venv_activate="source ${venv}/bin/activate"
        break
    fi
done

cmd_commands="cd ${selected}"

if [ $has_venv -eq 1 ]; then
    cmd_commands="${cmd_commands} && echo 'Activating Python virtual environment' && ${venv_activate}"
fi

if [ $is_node -eq 1 ]; then
    cmd_commands="${cmd_commands} && echo 'Node.js project detected'"
    if [ $is_next -eq 1 ]; then
        cmd_commands="${cmd_commands} && echo 'Next.js project detected' && echo 'Available commands:' && echo 'npm run dev - Start development server' && echo 'npm run build - Build for production' && echo 'npm start - Start production server'"
    elif [ $is_react -eq 1 ]; then
        cmd_commands="${cmd_commands} && echo 'React project detected' && echo 'Available commands:' && echo 'npm start - Start development server' && echo 'npm run build - Build for production'"
    else
        cmd_commands="${cmd_commands} && echo 'Available commands:' && echo 'npm start - Start the application' && echo 'npm test - Run tests'"
    fi
    if [ ! -d "${selected}node_modules" ]; then
        cmd_commands="${cmd_commands} && echo 'node_modules not found, you may need to run npm install'"
    fi
fi

if [ $is_python -eq 1 ] && [ $has_venv -eq 0 ]; then
    cmd_commands="${cmd_commands} && echo 'Python project detected but no virtual environment found' && echo 'To create one, use:' && echo 'python3 -m venv env'"
fi

window_title="Terminal - ${selected_name}"
if [ $is_next -eq 1 ]; then window_title="${window_title} (Next.js)"; fi
if [ $is_react -eq 1 ]; then window_title="${window_title} (React)"; fi
if [ $is_node -eq 1 ]; then window_title="${window_title} (Node.js)"; fi
if [ $is_python -eq 1 ]; then window_title="${window_title} (Python)"; fi
if [ $has_venv -eq 1 ]; then window_title="${window_title} [venv]"; fi

if ! pgrep -f "$selected_name" > /dev/null; then
    gnome-terminal --title="$window_title" -- bash -c "$cmd_commands; exec bash"
else
    echo "Terminal session with the name $selected_name already exists."
fi
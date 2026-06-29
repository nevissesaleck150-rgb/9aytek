@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat
echo Starting Django on all interfaces (required for phone / emulator)...
python manage.py runserver 0.0.0.0:8000
pause

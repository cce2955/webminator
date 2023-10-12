@echo off
setlocal enabledelayedexpansion

REM Set the target size in kilobytes (2MB)
set TARGET_SIZE=2048

REM Get the video duration in seconds and milliseconds
for /f "delims=" %%a in ('ffmpeg -i "%~1" 2^>^&1 ^| find "Duration"') do set duration_line=%%a
set duration=!duration_line:~12,11!
set /A "hours=1!duration:~0,2!-100"
set /A "minutes=1!duration:~3,2!-100"
set /A "seconds=1!duration:~6,2!-100"
set /A "milliseconds=1!duration:~9,3!-1000"
set /A total_seconds=hours*3600 + minutes*60 + seconds

REM Get user input for start and end points in seconds
set /p "start_point=Enter the starting point in seconds (default is 0): "
set /p "end_point=Enter the ending point in seconds (default is video duration): "

REM Set default values if not provided
if "%start_point%"=="" set "start_point=0"
if "%end_point%"=="" set "end_point=%total_seconds%"

REM Calculate the required video bitrate to fit within the target size (2MB)
set /A required_bitrate=(TARGET_SIZE*8192)/(%end_point%-%start_point%) - 128

REM Ensure the bitrate is within a reasonable range (e.g., not exceeding 500k)
if %required_bitrate% gtr 500 set required_bitrate=500

REM Convert start_point and end_point to HH:MM:SS.milliseconds format
set /A "start_hours=start_point/3600"
set /A "start_minutes=(start_point%%3600)/60"
set /A "start_seconds=start_point%%60"
set /A "start_milliseconds=milliseconds*start_point%%1000/1000"
set "start_time=!start_hours!:!start_minutes!:!start_seconds!.!start_milliseconds!"

set /A "end_hours=end_point/3600"
set /A "end_minutes=(end_point%%3600)/60"
set /A "end_seconds=end_point%%60"
set /A "end_milliseconds=milliseconds*end_point%%1000/1000"
set "end_time=!end_hours!:!end_minutes!:!end_seconds!.!end_milliseconds!"

REM Compress the video within the specified time frame with optional audio
set audio_option=-c:a libvorbis

REM Get user input for audio exclusion
set /p "exclude_audio=Do you want to exclude audio (N/No)? "

REM Check user input for audio exclusion
if /i "%exclude_audio%"=="N" (
  set audio_option=-an
)

ffmpeg -ss !start_time! -i "%~1" -to !end_time! -c:v libvpx -b:v %required_bitrate%k %audio_option% -s 640x360 -y -f webm "%~dpn1_compressed.webm"

endlocal

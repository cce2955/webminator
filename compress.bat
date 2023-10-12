@echo off
setlocal enabledelayedexpansion

REM Set the target size in kilobytes
set TARGET_SIZE=1945  REM Adjusted to 1.9MB

REM Get the video duration in seconds
for /f "delims=" %%a in ('ffmpeg -i "%~1" 2^>^&1 ^| find "Duration"') do set duration_line=%%a
set duration=!duration_line:~12,8!
set /A "hours=1!duration:~0,2!-100"
set /A "minutes=1!duration:~3,2!-100"
set /A "seconds=1!duration:~6,2!-100"
set /A total_seconds=hours*3600 + minutes*60 + seconds

REM Calculate the required bitrate with more buffer
set /A video_bitrate=(TARGET_SIZE*8192)/total_seconds - 30
set /A audio_bitrate=video_bitrate/12

REM Enforce limits on bitrate
if %video_bitrate% gtr 400 set video_bitrate=400
if %audio_bitrate% gtr 32 set audio_bitrate=32

REM Two-pass encoding to .webm format
ffmpeg -y -i "%~1" -c:v libvpx-vp9 -b:v %video_bitrate%k -c:a libopus -b:a %audio_bitrate%k -pass 1 -f webm NUL
ffmpeg -i "%~1" -c:v libvpx-vp9 -b:v %video_bitrate%k -c:a libopus -b:a %audio_bitrate%k -pass 2 -vf "scale=-1:min(ih\,320)" "%~dpn1_compressed.webm"

endlocal

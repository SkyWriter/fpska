@echo off &setlocal
setlocal enabledelayedexpansion

cls

CALL :Info_Message "fpska v0.5"

if [%1]==[] (
echo Vvedite imya video
exit
)

rem ============= init =============================
set fpska_home=%~dp0
set ffmpeg_threads=1
set method=slow
set ncpu=2
rem =================================================


FOR %%i IN ("%~f1") DO (
ECHO filedrive=%%~di
ECHO filepath=%%~pi
set video_file_name=%%~ni
ECHO fileextension=%%~xi
)

echo Fpska home: !fpska_home! 
echo File:  %~f1
echo Extension:  %~x1

set video_file=%~f1
set video_ext=%~x1

set container=""
set audio_codeck=""

rem ============= get info =========================

"!fpska_home!\ffmpeg\ffprobe.exe" -i "!video_file!" > "!fpska_home!\log.txt" 2> "!fpska_home!\ffprobe.log"

findstr /m "aac" "!fpska_home!ffprobe.log"
if %errorlevel%==0 (
	set audio_codeck=aac
)

findstr /m "matroska" "!fpska_home!ffprobe.log"
if %errorlevel%==0 (
	set container=mkv
)

findstr /m "mov,mp4,m4a,3gp,3g2,mj2" "!fpska_home!ffprobe.log"
if %errorlevel%==0 (
	set container=mp4
)

echo container: !container!
echo audio: !audio_codeck!
rem =================================================

rem ===================== set nethod ================
if [%2]==[] (
set method=fast
) else (
set method=%2
)

if [%3]==[] (
set ncpu=4
) else (
set ncpu=%3
)

echo Method: !method!

rem =================================================

rmdir /S/Q "!fpska_home!\tmp"
mkdir "!fpska_home!\tmp"

@echo off

echo %time%

rem ============== extract audio ====================
if "!container!"=="mp4" (
echo Extrating audio for mp4	
"!fpska_home!\ffmpeg\ffmpeg.exe" -y -i %1 -vn -acodec copy "!fpska_home!\tmp\60fps_audio.aac" -v quiet -stats 
)


if "!container!"=="mkv" (

copy "!video_file!" "!fpska_home!\tmp"
cd "!fpska_home!\tmp"



"!fpska_home!\eac3to\eac3to.exe" "!fpska_home!\tmp\!video_file_name!!video_ext!" -demux

del "!fpska_home!\tmp\!video_file_name!!video_ext!" 
del "!fpska_home!\tmp\*.txt"
del "!fpska_home!\tmp\*.h264"

cd "!fpska_home!"

)

rem =================================================

rem ============== prepare script ===================
if "!method!"=="slow" (
copy !fpska_home!\scripts\fpska_slow.avs !fpska_home!\scripts\work.avs
) else if "!method!"=="fast" (
copy !fpska_home!\scripts\fpska_fast.avs !fpska_home!\scripts\work.avs
)
set "search=fullhd.mkv"
set "search_threads=nthreads"
set "replace=!video_file!"
set "threads=!ncpu!"

set "textfile=!fpska_home!\scripts\work.avs"
set "newfile=!fpska_home!\scripts\tmp.txt"

(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    set "line=!line:%search_threads%=%threads%!"
    echo(!line!
))>"%newfile%"
del !fpska_home!\scripts\work.avs
ren !fpska_home!\scripts\tmp.txt work.avs
rem =================================================
rem
rem =========== convert to 60fps video ==============
if "!method!"=="slow" (
!fpska_home!\ffmpeg\ffmpeg.exe -y -i !fpska_home!\scripts\work.avs -c:a copy -c:v libx264 -crf 20 -preset slow !fpska_home!\tmp\60fps_video.mp4 -v quiet -stats
) else if "!method!"=="fast" (
!fpska_home!\ffmpeg\ffmpeg.exe -y -i !fpska_home!\scripts\work.avs -c:a copy -c:v libx264 -crf 20 -preset slow !fpska_home!\tmp\60fps_video.mp4 -v quiet -stats
)
rem =================================================

rem =========== merge audio and 60fps video =========
for %%i in (tmp\*.*) do set str=!str! "%%i"
echo !str!

!fpska_home!\mkvtoolnix\mkvmerge.exe !str! -o 60fps.mkv

rem =================================================

del !fpska_home!\log.txt
del !fpska_home!\ffprobe.log
del !fpska_home!\*.ffindex

endlocal
echo %time%
pause


:Info_Message
echo ------------------------------------------
echo. 
echo %~1
echo. 
echo ------------------------------------------
EXIT /B 0

@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: This script processes mp4 files contained in the same directory to ensure constant framerate and matching audio and video length.
:: process-video, version 0.2, corey lionis 19092026

set _ffmpeg=ffmpeg -loglevel error

REM set up folder for processing, allow user to pick framerate mode
if not exist ".\Preprocessed\" mkdir ".\Preprocessed\"
choice /C fa /T 30 /D a /M "Select [F]ixed framerate (all videos) or [A]daptive (30 for low average, 60 for high)"

if %ERRORLEVEL% equ 1 set /P fps="Enter target fps:"

choice /C yn /T 30 /D y /M "Delete temp processing files on completion?"

if %ERRORLEVEL% equ 1 (
	set keepfiles=0
) else (
	set keepfiles=1 
)

(echo Video processing log at time !time! & echo ------ & echo.) > process-log.txt

for %%F in (.\*.mp4) do (
	set A=%%~nF
	echo Processing !A!.mp4... at time !time! >> process-log.txt

	REM Check_If_Need_Freeze_Frame
	set count=1
	for /F "delims== tokens=2" %%G in ('ffprobe -loglevel error -hide_banner -show_entries stream^=duration -of flat -i !A!.mp4') do (
		set var!count!=%%G
		set /a count=!count!+1
	)
	for /F %%H in ('powershell.exe !var1! - !var2!') do ( 
		set diff=%%H 
		set diff=!diff:~0,8!
		echo !time! The audio is longer than video by !diff! seconds or atypical encoding >> process-log.txt
	)
	for /F %%J in ('powershell.exe !diff! -le -1') do (
		if %%J==True (
			echo Error at time !time! please process !A!.mp4 manually, video is longer than audio >> process-log.txt
		)
	)

	REM Get_avg_fr_and_map_to_30_or_60
	for /F "delims==/ tokens=2,3" %%G in ('ffprobe -loglevel fatal -hide_banner -select_streams v -show_entries stream^=avg_frame_rate -of flat -i !A!.mp4') do (
		set /a AVG="%%G/%%H"
	)
	if !AVG! LEQ 30 set FMR=30
	if !AVG! GTR 30 set FMR=60

	echo !time! Adaptive framerate calculated to !FMR! >> process-log.txt

	for /F %%I in ('powershell.exe !diff! -ge 1') do (
			set freeze=%%I
	)
	

	REM Preprocess_Videos

	REM Step_1_Set_FMR
	if not exist ".\Preprocessed\!A!!FMR!fps.mp4" (
		%_ffmpeg% -i %%F -fps_mode cfr -r !FMR! -c:v libx264 -c:a aac .\Preprocessed\!A!!FMR!fps.mp4
		echo Successfully wrote cfr file !A!!FMR!fps.mp4 at !time! >> process-log.txt
	) else (
		echo !time! Skipping encode to cfr, file already exists >> process-log.txt
	)
	
	REM Add_Freeze_Frame
	if /i !freeze!==True (
		REM Step_2_Separate_Video_With_Padding
		if not exist ".\Preprocessed\!A!video.mp4" (
			%_ffmpeg% -i .\Preprocessed\!A!!FMR!fps.mp4 -an -vf tpad=stop_mode=clone:stop_duration=!diff! -c:v libx264 .\Preprocessed\!A!video.mp4
			echo Wrote padded video at time !time! >> process-log.txt		
		) else (
			echo !time! Skipping video extraction, video already exists >> process-log.txt
		)
		REM Step_3_Separate_Audio
		if not exist ".\Preprocessed\!A!audio.aac" ( 
			%_ffmpeg% -i .\Preprocessed\!A!!FMR!fps.mp4 -vn -c:a copy .\Preprocessed\!A!audio.aac
			echo Wrote audio to own file at time !time! >> process-log.txt
		) else (
			echo !time! Skipping audio extraction, audio file already exists >> process-log.txt
		)
		REM Step_4_Merge
		if not exist ".\Preprocessed\!A!synced.mp4" (
			%_ffmpeg% -i .\Preprocessed\!A!video.mp4 -i .\Preprocessed\!A!audio.aac -map 0:v -map 1:a -c:v copy -c:a copy .\Preprocessed\!A!synced.mp4
		) else (
			echo !time! Skipping sync step, already synced >> process-log.txt
		)
	)
	(echo Finished !A!.mp4 & echo ------ & echo.)>> process-log.txt
)


:CLEANUP
if %keepfiles%==1 (
	goto exit
)
for %%K in (.\*.mp4) do (
	set B=%%~nK
	if exist ".\Preprocessed\!B!synced.mp4" (
		if exist ".\Preprocessed\!B!!FMR!fps.mp4" del ".\Preprocessed\!B!!FMR!fps.mp4"
		echo !time! Deleted cfr file for synced movie >>process-log.txt
	)
	if exist ".\Preprocessed\!B!audio.aac" (
		del ".\Preprocessed\!B!audio.aac"
		echo !time! Deleted audio file for !B! at time >> process-log.txt
	)
	if exist ".\Preprocessed\!B!video.mp4" (
		del ".\Preprocessed\!B!video.mp4"
		echo !time! Deleted video file for !B! at time >> process-log.txt
	)
)

:exit
echo Completed cleanup at time !time!, all videos processed. >> process-log.txt
choice /C yn /T 30 /D n /M "Delete logfile "
if %ERRORLEVEL% equ 1 (
	if exist "process-log.txt" del "process-log.txt"
)
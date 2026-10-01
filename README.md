# Using process-videos

This batch script is designed to be placed in a folder with videos and run once. It requires Windows OS and an installed copy of the video-processing framework ffmpeg, which is compatible with all operating systems. 

To set up ffmpeg for Windows, either download a binary of the application (you can do that [here](https://www.gyan.dev/ffmpeg/builds/))and add it from Program Files to [PATH](https://www.wikihow.com/Change-the-PATH-Environment-Variable-on-Windows), or download the tarball from [ffmpeg](https://ffmpeg.org/download.html) and build from scratch.

Ordinarily writing each video will take 1-5 minutes, but large videos or high frame counts might take longer. A detailed execution log will be written to a file process-log.txt in your video folder, and the processed videos will be placed in a subfolder called Preprocessed. 

Using the batch file as provided should never overwrite your videos, but make sure you have backups of anything important. Any runtime errors are probably caused by ffmpeg, and often you'll be able to resolve these by restarting the program. If the preprocessing task isn't running as intended, please take note of the problem and save logfiles. The software package [MediaInfo](https://mediaarea.net/en/MediaInfo/Download) can be used to get metadata from common audiovisual formats, so if something seems wrong with the video this can be helpful to pinpoint unexpected changes. 

Happy preprocessing!

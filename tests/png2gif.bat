@ECHO OFF
SET src="%1"
SET dst="%~nx1.gif"
ffmpeg -i %src% %dst%
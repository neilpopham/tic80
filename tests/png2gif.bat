@ECHO OFF
SET src="%1"
SET dst="%~n1.gif"
magick %src% %dst%
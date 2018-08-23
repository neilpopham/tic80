@ECHO OFF
SET src="%1"
SET dst="%~nx1.gif"
ffmpeg -i %src% -i create_item_palette.png %dst%
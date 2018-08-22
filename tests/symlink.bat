@ECHO OFF

REM This batch file should be placed in the same folder as tic80.exe
REM Drag a lua file from the cart folder onto this batch file to create a symlink
REM and then use dofile("file.lua") in the file.tic file to include that lua file.
REM This allows us to edit lua in an external editor without affecting sprites, etc.

SET src="%1"
SET dst="%~dp0%~nx1"
MKLINK %dst% %src%

PAUSE
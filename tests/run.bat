@ECHO OFF

IF EXIST "C:\Users\neil\AppData\Roaming\itch\apps\TIC-80\tic80.exe" (
    SET tic80="C:\Users\neil\AppData\Roaming\itch\apps\TIC-80\tic80.exe"
) ELSE (
    SET tic80="C:\Program Files\TIC-80\tic80.exe"
)

%tic80% "%~dpn1.tic" -code "%1"
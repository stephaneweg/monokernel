@echo off
set drive=i:
if NOT EXIST %Drive%\ (
	echo Please mount the disk image at %Drive%
	pause
	EXIT
)
IF NOT EXIST %Drive%\boot mkdir %Drive%\boot
IF NOT EXIST %Drive%\keys mkdir %Drive%\keys
IF NOT EXIST %Drive%\bin mkdir %Drive%\bin
echo Install kernel ...
if exist %Drive%\boot\kernel.elf del %Drive%\boot\kernel.elf /F /Q

copy bin\kernel.elf %Drive%\boot\kernel.elf
copy kernel.map %Drive%\boot\kernel.map

echo install keymaps
copy bin\keymaps\*.* %Drive%\keys
copy test.txt %Drive%\test.txt

for /d %%i in (userland\apps\*.*) do (
	echo    %%~ni
	copy bin\userland\%%~ni %Drive%\bin
)

pause
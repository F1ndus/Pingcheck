@echo off
:loop
	powershell -File getUpload.ps1
 	timeout 5 > nul
	goto loop

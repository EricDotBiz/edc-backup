@echo off

SET EXECUTABLE=PowerShell.exe -executionpolicy bypass -File "./bkup.ps1" %*
%EXECUTABLE%
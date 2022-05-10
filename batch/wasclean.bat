@echo off
set profile=c:\programdata\ibm\was\traditional\wasdev01

rd /s/q %profile%\wstemp
md %profile%\wstemp

rd /s/q %profile%\workspace
md %profile%\workspace

rd /s/q %profile%\temp
md %profile%\temp

del /f/q %profile%\logs\*.log
del /f/q %profile%\logs\server1\*.*
del /f/q %profile%\logs\ffdc\*.*

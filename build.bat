@echo off
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" DemoHelper.sln -t:Rebuild -p:Configuration=Release -p:Platform=x64 -v:minimal

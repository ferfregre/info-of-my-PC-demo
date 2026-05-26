@echo off
title PC Hardware Information
color 0A
mode con cols=110 lines=3500
setlocal enabledelayedexpansion

echo ================================================================================
echo                        PC HARDWARE INFORMATION
echo ================================================================================
echo.

:: ================================================================================
:: ÎÏÅÐÀÖÈÎÍÍÀß ÑÈÑÒÅÌÀ È ÁÈÒÍÎÑÒÜ
:: ================================================================================
echo [OPERATING SYSTEM]
set "os="
for /f "tokens=2* delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul ^| find "REG_SZ"') do set "os=%%b"
if "%os%"=="" set "os=Windows (version unknown)"
echo   Name: %os%

:: ÁÈÒÍÎÑÒÜ ÑÈÑÒÅÌÛ
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo   System Type: 64-bit (x64)
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    echo   System Type: 32-bit (x86)
) else if "%PROCESSOR_ARCHITECTURE%"=="IA64" (
    echo   System Type: 64-bit (Itanium)
) else (
    echo   System Type: %PROCESSOR_ARCHITECTURE%
)

:: Àëüòåðíàòèâíûé ìåòîä îïðåäåëåíèÿ áèòíîñòè
systeminfo 2>nul | findstr "System Type" >nul
if %errorlevel%==0 (
    for /f "tokens=2 delims=:" %%a in ('systeminfo 2^>nul ^| findstr "System Type"') do echo   %%~a
)
echo.

echo [COMPUTER NAME AND USER]
echo   Computer: %computername%
echo   User: %username%
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ
:: ================================================================================
echo [PROCESSOR]
set "proc_found=0"
for /f "skip=1 delims=" %%a in ('wmic cpu get Name 2^>nul') do (
    set "proc=%%a"
    if not "!proc!"=="" if !proc_found!==0 (
        echo   !proc!
        set proc_found=1
        goto :proc_done
    )
)
:proc_done
if %proc_found%==0 (
    for /f "tokens=*" %%a in ('systeminfo 2^>nul ^| findstr /i "Processor"') do (
        set "proc=%%a"
        set "proc=!proc:*Processor =!"
        if not "!proc!"=="" echo   !proc! & set proc_found=1 & goto :proc_done2
    )
)
:proc_done2
if %proc_found%==0 echo   Processor information not available
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ - ÄÅÒÀËÈ
:: ================================================================================
echo [PROCESSOR - DETAILED]
set "ps_detailed=0"
powershell -Command "Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List" 2>nul && set ps_detailed=1
if %ps_detailed%==0 (
    for /f "skip=1 delims=" %%a in ('wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:csv 2^>nul') do (
        echo   Name: %%a
        goto :detailed_done
    )
)
:detailed_done
echo.

:: ================================================================================
:: RAM - ÌÎÄÓËÈ
:: ================================================================================
echo [RAM - MODULES]
set "ram_total=0"
set "ram_slots=0"
powershell -Command "$total=0; Get-WmiObject -Class Win32_PhysicalMemory | ForEach-Object { $size=[math]::Round($_.Capacity/1GB,2); $total+=$size; Write-Host ('  ' + $_.Manufacturer + ' ' + $size + ' GB ' + $_.Speed + ' MHz') }; Write-Host ('Total RAM installed: ' + $total.ToString() + ' GB')" 2>nul
if errorlevel 1 (
    for /f "skip=1 delims=" %%a in ('wmic memorychip get Capacity 2^>nul') do (
        set "cap=%%a"
        if not "!cap!"=="" (
            set /a "size=!cap!/1024/1024/1024"
            set /a ram_total+=!size!
            set /a ram_slots+=1
            echo   Slot !ram_slots!: !size! GB
        )
    )
    if !ram_total! gtr 0 echo Total RAM installed: !ram_total! GB
)
echo.

:: ================================================================================
:: ÃÐÀÔÈ×ÅÑÊÀß ÊÀÐÒÀ
:: ================================================================================
echo [GRAPHICS CARD]
set "gpu_found=0"
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get Name 2^>nul') do (
    set "gpu=%%a"
    if not "!gpu!"=="" echo   GPU: !gpu! & set gpu_found=1 & goto :gpu_done
)
:gpu_done
if %gpu_found%==0 (
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object -ExpandProperty Name" 2>nul
)
echo.

:: ================================================================================
:: ÂÈÄÅÎÏÀÌßÒÜ
:: ================================================================================
echo [GRAPHICS CARD - VRAM]
set "vram_found=0"
powershell -Command "$vram = (Get-WmiObject -Class Win32_VideoController).AdapterRAM; if ($vram -ge 1073741824) { $vramGB = [math]::Round($vram/1GB, 2); Write-Host ('  VRAM: ' + $vramGB + ' GB') } else { $vramMB = [math]::Round($vram/1MB, 2); Write-Host ('  VRAM: ' + $vramMB + ' MB') }" 2>nul && set vram_found=1
if %vram_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get AdapterRAM 2^>nul') do (
        set "vram=%%a"
        if not "!vram!"=="" (
            set /a "vramGB=!vram!/1073741824"
            if !vramGB! gtr 0 (echo   VRAM: !vramGB! GB) else (echo   VRAM: !vram! bytes)
            goto :vram_done
        )
    )
)
:vram_done
echo.

:: ================================================================================
:: ÐÀÇÐÅØÅÍÈÅ ÝÊÐÀÍÀ
:: ================================================================================
echo [GRAPHICS CARD - RESOLUTION]
set "res_found=0"
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution 2^>nul') do (
    set "res=%%a"
    if not "!res!"=="" echo   Resolution: !res! & set res_found=1 & goto :res_done
)
:res_done
if %res_found%==0 (
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object CurrentHorizontalResolution, CurrentVerticalResolution | Format-List" 2>nul
)
echo.

:: ================================================================================
:: ÌÎÍÈÒÎÐ
:: ================================================================================
echo [MONITOR]
set "mon_found=0"
powershell -Command "Get-WmiObject -Class Win32_DesktopMonitor | Select-Object Name, ScreenWidth, ScreenHeight | Format-List" 2>nul && set mon_found=1
if %mon_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic desktopmonitor get Name,ScreenWidth,ScreenHeight 2^>nul') do (
        echo   Monitor: %%a
        goto :mon_done
    )
)
:mon_done
echo.

:: ================================================================================
:: ×ÀÑÒÎÒÀ ÎÁÍÎÂËÅÍÈß
:: ================================================================================
echo [MONITOR - REFRESH RATE]
set "hz_found=0"
powershell -Command "$hz = (Get-WmiObject -Class Win32_VideoController).CurrentRefreshRate; if ($hz) { Write-Host ('  Refresh Rate: ' + $hz + ' Hz') } else { Write-Host '  Refresh Rate: not detected' }" 2>nul && set hz_found=1
if %hz_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic path Win32_VideoController get CurrentRefreshRate 2^>nul') do (
        set "hz=%%a"
        if not "!hz!"=="" echo   Refresh Rate: !hz! Hz & goto :hz_done
    )
)
:hz_done
echo.

:: ================================================================================
:: ÍÀÊÎÏÈÒÅËÈ
:: ================================================================================
echo [STORAGE DRIVES]
set "drive_found=0"
powershell -Command "Get-WmiObject -Class Win32_LogicalDisk -Filter DriveType=3 | ForEach-Object { $size=[math]::Round($_.Size/1GB,2); $free=[math]::Round($_.FreeSpace/1GB,2); Write-Host ('  Drive ' + $_.DeviceID + ': ' + $size + ' GB total, free ' + $free + ' GB') }" 2>nul && set drive_found=1
if %drive_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic logicaldisk where DriveType=3 get DeviceID,Size,FreeSpace 2^>nul') do (
        set "line=%%a"
        if not "!line!"=="" echo   !line!
    )
)
echo.

:: ================================================================================
:: ÒÈÏ ÍÀÊÎÏÈÒÅËß
:: ================================================================================
echo [DISK TYPE (SSD/HDD)]
powershell -Command "Get-PhysicalDisk | Select-Object MediaType" 2>nul
if errorlevel 1 (
    echo   Disk type info not available
)
echo.

:: ================================================================================
:: ÌÀÒÅÐÈÍÑÊÀß ÏËÀÒÀ
:: ================================================================================
echo [MOTHERBOARD]
set "mb_found=0"
powershell -Command "Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer, Product | Format-List" 2>nul && set mb_found=1
if %mb_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic baseboard get Manufacturer,Product 2^>nul') do (
        echo   Motherboard: %%a
        goto :mb_done
    )
)
:mb_done
echo.

:: ================================================================================
:: ÇÂÓÊÎÂÛÅ ÓÑÒÐÎÉÑÒÂÀ
:: ================================================================================
echo [SOUND DEVICES]
set "sound_found=0"
powershell -Command "Get-WmiObject -Class Win32_SoundDevice | Select-Object -ExpandProperty Name" 2>nul && set sound_found=1
if %sound_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic sounddev get ProductName 2^>nul') do (
        if not "%%a"=="" echo   - %%a
    )
)
echo.

:: ================================================================================
:: ÑÅÒÜ
:: ================================================================================
echo [NETWORK ADAPTERS - IPv4]
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set "ip=%%a"
    if not "!ip!"=="" echo   !ip:~1!
)
echo.

echo [MAC ADDRESS]
getmac | findstr /v "NA" | findstr /v "Transport" 2>nul
if errorlevel 1 echo   MAC address not available
echo.

:: ================================================================================
:: ÂÈÐÒÓÀËÈÇÀÖÈß
:: ================================================================================
echo [VIRTUALIZATION (VT-x/AMD-V)]
systeminfo | findstr "Virtualization"
echo.

:: ================================================================================
:: ÂÐÅÌß ÐÀÁÎÒÛ
:: ================================================================================
echo [SYSTEM UPTIME]
systeminfo | findstr "System Boot Time"
echo.

:: ================================================================================
:: ÑÕÅÌÀ ÏÈÒÀÍÈß
:: ================================================================================
echo [POWER PLAN]
powercfg /getactivescheme 2>nul
if errorlevel 1 echo   Power plan info not available
echo.

:: ================================================================================
:: .NET FRAMEWORK
:: ================================================================================
echo [.NET FRAMEWORK VERSION]
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release 2>nul
echo.

:: ================================================================================
:: ÎÁÍÎÂËÅÍÈß
:: ================================================================================
echo [INSTALLED UPDATES (last 5)]
powershell -Command "Get-HotFix | Select-Object -First 5 HotFixID,InstalledOn | Format-Table -AutoSize" 2>nul
if errorlevel 1 (
    wmic qfe get HotFixID,InstalledOn /format:table 2>nul | findstr "KB"
)
echo.

:: ================================================================================
:: ÊÎÍÅÖ
:: ================================================================================
echo ================================================================================
echo   Press any key to exit...
echo ================================================================================
pause >nul
exit
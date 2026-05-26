@echo off
title PC Hardware Information
color 0A
mode con cols=100 lines=2000
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
echo %os%

:: ÁÈÒÍÎÑÒÜ - ÌÅÒÎÄ 1 (ïåðåìåííàÿ îêðóæåíèÿ)
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo System Type: 64-bit (x64)
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    echo System Type: 32-bit (x86)
) else if "%PROCESSOR_ARCHITECTURE%"=="IA64" (
    echo System Type: 64-bit (Itanium)
) else (
    echo System Type: %PROCESSOR_ARCHITECTURE%
)

:: ÁÈÒÍÎÑÒÜ - ÌÅÒÎÄ 2 (systeminfo) åñëè íóæíî óòî÷íèòü
systeminfo 2>nul | findstr "System Type" >nul
if %errorlevel%==0 (
    for /f "tokens=2 delims=:" %%a in ('systeminfo 2^>nul ^| findstr "System Type"') do (
        set "sys_type=%%a"
        echo   %sys_type%
    )
)
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ
:: ================================================================================
echo [PROCESSOR]
set "proc_found=0"

:: ÌÅÒÎÄ 1: WMIC
wmic cpu get Name 2>nul | find "CPU" >nul 2>nul
if %errorlevel%==0 (
    for /f "skip=1 delims=" %%a in ('wmic cpu get Name 2^>nul') do (
        set "proc=%%a"
        if not "!proc!"=="" if !proc_found!==0 (
            echo !proc!
            set proc_found=1
        )
    )
)

:: ÌÅÒÎÄ 2: systeminfo
if %proc_found%==0 (
    systeminfo 2>nul | findstr /i "Processor" >nul
    if %errorlevel%==0 (
        for /f "tokens=*" %%a in ('systeminfo 2^>nul ^| findstr /i "Processor"') do (
            set "proc=%%a"
            set "proc=!proc:*Processor =!"
            if not "!proc!"=="" echo !proc! & set proc_found=1
        )
    )
)

:: ÌÅÒÎÄ 3: ðååñòð
if %proc_found%==0 (
    for /f "tokens=2* delims= " %%a in ('reg query "HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0" /v ProcessorNameString 2^>nul ^| find "REG_SZ"') do (
        echo %%b
        set proc_found=1
    )
)

if %proc_found%==0 echo Processor information not available
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ - ÄÅÒÀËÈ
:: ================================================================================
echo [PROCESSOR - DETAILED]
set "ps_detailed=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_Processor" 2>nul | find "Name" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List" 2>nul
    set ps_detailed=1
)

:: ÌÅÒÎÄ 2: WMIC
if %ps_detailed%==0 (
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed 2>nul | find "CPU" >nul 2>nul
    if %errorlevel%==0 (
        for /f "skip=1 delims=" %%a in ('wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed 2^>nul') do (
            echo %%a
            goto :detailed_done
        )
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
set "ram_info=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_PhysicalMemory" 2>nul | find "Capacity" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "$total=0; Get-WmiObject -Class Win32_PhysicalMemory | ForEach-Object { $size=[math]::Round($_.Capacity/1GB,2); $total+=$size; Write-Host ('  ' + $_.Manufacturer + ' ' + $size + ' GB ' + $_.Speed + ' MHz') }; Write-Host ('Total RAM installed: ' + $total.ToString() + ' GB')" 2>nul
    set ram_info=1
)

:: ÌÅÒÎÄ 2: WMIC
if %ram_info%==0 (
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
:: ÂÈÄÅÎÊÀÐÒÀ
:: ================================================================================
echo [GRAPHICS CARD]
set "gpu_found=0"

:: ÌÅÒÎÄ 1: WMIC
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get Name 2^>nul') do (
    set "gpu=%%a"
    if not "!gpu!"=="" echo GPU: !gpu! & set gpu_found=1 & goto :gpu_done
)
:gpu_done

:: ÌÅÒÎÄ 2: PowerShell
if %gpu_found%==0 (
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object -ExpandProperty Name" 2>nul
)
echo.

:: ================================================================================
:: ÂÈÄÅÎÏÀÌßÒÜ
:: ================================================================================
echo [GRAPHICS CARD - VRAM]
set "vram_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "$vram = (Get-WmiObject -Class Win32_VideoController).AdapterRAM" 2>nul | find "GB" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "$vram = (Get-WmiObject -Class Win32_VideoController).AdapterRAM; if ($vram -ge 1073741824) { $vramGB = [math]::Round($vram/1GB, 2); Write-Host ('VRAM: ' + $vramGB + ' GB') } else { $vramMB = [math]::Round($vram/1MB, 2); Write-Host ('VRAM: ' + $vramMB + ' MB') }" 2>nul
    set vram_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %vram_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get AdapterRAM 2^>nul') do (
        set "vram=%%a"
        if not "!vram!"=="" (
            set /a "vramGB=!vram!/1073741824"
            if !vramGB! gtr 0 (echo VRAM: !vramGB! GB) else (echo VRAM: !vram! bytes)
            goto :vram_done
        )
    )
)
:vram_done
echo.

:: ================================================================================
:: ÐÀÇÐÅØÅÍÈÅ
:: ================================================================================
echo [GRAPHICS CARD - RESOLUTION]
set "res_found=0"

:: ÌÅÒÎÄ 1: WMIC
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution 2^>nul') do (
    set "res=%%a"
    if not "!res!"=="" echo Resolution: !res! & set res_found=1 & goto :res_done
)
:res_done

:: ÌÅÒÎÄ 2: PowerShell
if %res_found%==0 (
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object CurrentHorizontalResolution, CurrentVerticalResolution | Format-List" 2>nul
)
echo.

:: ================================================================================
:: ÌÎÍÈÒÎÐ
:: ================================================================================
echo [MONITOR]
set "mon_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_DesktopMonitor" 2>nul | find "Name" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-WmiObject -Class Win32_DesktopMonitor | Select-Object Name, ScreenWidth, ScreenHeight | Format-List" 2>nul
    set mon_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %mon_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic desktopmonitor get Name,ScreenWidth,ScreenHeight 2^>nul') do (
        echo Monitor: %%a
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

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "$hz = (Get-WmiObject -Class Win32_VideoController).CurrentRefreshRate" 2>nul | find "Hz" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "$hz = (Get-WmiObject -Class Win32_VideoController).CurrentRefreshRate; if ($hz) { Write-Host ('Refresh Rate: ' + $hz + ' Hz') } else { Write-Host 'Refresh Rate: not detected' }" 2>nul
    set hz_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %hz_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic path Win32_VideoController get CurrentRefreshRate 2^>nul') do (
        set "hz=%%a"
        if not "!hz!"=="" echo Refresh Rate: !hz! Hz & goto :hz_done
    )
)
:hz_done
echo.

:: ================================================================================
:: ÐÀÇÌÅÐ ÌÎÍÈÒÎÐÀ
:: ================================================================================
echo [MONITOR - SIZE (inches)]
powershell -Command "$mon = Get-WmiObject -Class Win32_DesktopMonitor; if ($mon.ScreenWidth -and $mon.ScreenHeight) { $dpi = 96; $widthInches = $mon.ScreenWidth / $dpi; $heightInches = $mon.ScreenHeight / $dpi; $diagonal = [math]::Sqrt([math]::Pow($widthInches,2) + [math]::Pow($heightInches,2)); Write-Host ('Diagonal size: ' + [math]::Round($diagonal, 1) + ' inches') } else { Write-Host 'Size info not available' }" 2>nul
echo.

:: ================================================================================
:: ÍÀÊÎÏÈÒÅËÈ
:: ================================================================================
echo [STORAGE DRIVES]
set "drive_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_LogicalDisk -Filter DriveType=3" 2>nul | find "DeviceID" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-WmiObject -Class Win32_LogicalDisk -Filter DriveType=3 | ForEach-Object { $size=[math]::Round($_.Size/1GB,2); $free=[math]::Round($_.FreeSpace/1GB,2); Write-Host ('Drive ' + $_.DeviceID + ': ' + $size + ' GB total, free ' + $free + ' GB') }" 2>nul
    set drive_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %drive_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic logicaldisk where DriveType=3 get DeviceID,Size,FreeSpace 2^>nul') do (
        set "line=%%a"
        if not "!line!"=="" echo !line!
    )
)
echo.

:: ================================================================================
:: ÌÀÒÅÐÈÍÑÊÀß ÏËÀÒÀ
:: ================================================================================
echo [MOTHERBOARD]
set "mb_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_BaseBoard" 2>nul | find "Manufacturer" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer, Product | Format-List" 2>nul
    set mb_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %mb_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic baseboard get Manufacturer,Product 2^>nul') do (
        echo Motherboard: %%a
        goto :mb_done
    )
)
:mb_done
echo.

:: ================================================================================
:: ÇÂÓÊ
:: ================================================================================
echo [SOUND DEVICES]
set "sound_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-WmiObject -Class Win32_SoundDevice" 2>nul | find "Name" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-WmiObject -Class Win32_SoundDevice | Select-Object -ExpandProperty Name" 2>nul
    set sound_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %sound_found%==0 (
    for /f "skip=1 delims=" %%a in ('wmic sounddev get ProductName 2^>nul') do (
        if not "%%a"=="" echo   - %%a
    )
)
echo.

:: ================================================================================
:: ÑÅÒÜ
:: ================================================================================
echo [NETWORK ADAPTERS]
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set "ip=%%a"
    if not "!ip!"=="" echo !ip:~1!
)
echo.

:: ================================================================================
:: ÎÁÍÎÂËÅÍÈß
:: ================================================================================
echo [INSTALLED UPDATES]
set "upd_found=0"

:: ÌÅÒÎÄ 1: PowerShell
powershell -Command "Get-HotFix" 2>nul | find "HotFixID" >nul 2>nul
if %errorlevel%==0 (
    powershell -Command "Get-HotFix | Select-Object -First 5 HotFixID,InstalledOn | Format-Table -AutoSize" 2>nul
    set upd_found=1
)

:: ÌÅÒÎÄ 2: WMIC
if %upd_found%==0 (
    wmic qfe get HotFixID,InstalledOn /format:table 2>nul | findstr "KB"
    if errorlevel 1 echo Updates list not available
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
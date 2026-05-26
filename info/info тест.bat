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
:: ÎÏÅÐÀÖÈÎÍÍÀß ÑÈÑÒÅÌÀ
:: ================================================================================
echo [OPERATING SYSTEM]
set "os="
for /f "tokens=2* delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul ^| find "REG_SZ"') do set "os=%%b"
if "%os%"=="" set "os=Windows (version unknown)"
echo %os%
echo.

:: ================================================================================
:: ÊÎÌÏÜÞÒÅÐ È ÏÎËÜÇÎÂÀÒÅËÜ
:: ================================================================================
echo [COMPUTER NAME AND USER]
echo Computer: %computername%
echo User: %username%
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ
:: ================================================================================
echo [PROCESSOR]
set "proc_found=0"
for /f "skip=1 delims=" %%a in ('wmic cpu get Name 2^>nul') do (
    set "proc=%%a"
    if not "!proc!"=="" if !proc_found!==0 (
        echo !proc!
        set proc_found=1
        goto :proc_done
    )
)
:proc_done
if %proc_found%==0 (
    for /f "tokens=*" %%a in ('systeminfo 2^>nul ^| findstr /i "Processor"') do (
        set "proc=%%a"
        set "proc=!proc:*Processor =!"
        if not "!proc!"=="" echo !proc! & set proc_found=1 & goto :proc_done2
    )
)
:proc_done2
if %proc_found%==0 echo Processor information not available
echo.

:: ================================================================================
:: ÏÐÎÖÅÑÑÎÐ - ÄÅÒÀËÈ
:: ================================================================================
echo [PROCESSOR - DETAILED]
powershell -Command "Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed, L2CacheSize, L3CacheSize | Format-List" 2>nul
if errorlevel 1 (
    for /f "skip=1 delims=" %%a in ('wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed 2^>nul') do (
        echo Name: %%a
    )
)
echo.

:: ================================================================================
:: ÎÏÅÐÀÒÈÂÍÀß ÏÀÌßÒÜ (ÑËÎÒÛ)
:: ================================================================================
echo [RAM - SLOTS INFORMATION]

:: Ïîëó÷àåì ìàêñèìàëüíîå êîëè÷åñòâî ñëîòîâ
set "max_slots=0"
for /f "skip=1 delims=" %%a in ('wmic memphysical get MemoryDevices 2^>nul') do (
    set "max_slots=%%a"
    if not "!max_slots!"=="" goto :max_slots_done
)
:max_slots_done

:: Ïîëó÷àåì êîëè÷åñòâî çàíÿòûõ ñëîòîâ è èíôîðìàöèþ î ìîäóëÿõ
set "used_slots=0"
set "free_slots=0"
set "ram_total=0"
set "slot_info="

powershell -Command "$total=0; $count=0; $slots = Get-WmiObject -Class Win32_PhysicalMemory; foreach ($slot in $slots) { $size=[math]::Round($slot.Capacity/1GB,2); $total+=$size; $count++; Write-Host ('  Slot ' + $count + ': ' + $slot.Manufacturer + ' ' + $size + ' GB ' + $slot.Speed + ' MHz') }; Write-Host ('  ---'); Write-Host ('  Total RAM installed: ' + $total.ToString() + ' GB'); Write-Host ('  Used slots: ' + $count)" 2>nul > "%temp%\ram_temp.txt"

if exist "%temp%\ram_temp.txt" (
    type "%temp%\ram_temp.txt"
    for /f "tokens=3 delims=: " %%a in ('type "%temp%\ram_temp.txt" ^| findstr "Used slots"') do set "used_slots=%%a"
    del "%temp%\ram_temp.txt" 2>nul
)

:: WMIC (çàïàñíîé)
if "%used_slots%"=="" (
    set "used_slots=0"
    set "ram_total=0"
    for /f "skip=1 delims=" %%a in ('wmic memorychip get Capacity 2^>nul') do (
        set "cap=%%a"
        if not "!cap!"=="" (
            set /a "size=!cap!/1024/1024/1024"
            set /a ram_total+=!size!
            set /a used_slots+=1
            echo   Slot !used_slots!: !size! GB
        )
    )
    if !used_slots! gtr 0 (
        echo   Total RAM installed: !ram_total! GB
        echo   Used slots: !used_slots!
    )
)

:: Âû÷èñëÿåì ñâîáîäíûå ñëîòû
if %max_slots% gtr 0 (
    set /a free_slots=%max_slots% - %used_slots%
    echo   Maximum slots: %max_slots%
    echo   Free slots: !free_slots!
) else (
    echo   Maximum slots: unable to determine
)
echo.

:: ================================================================================
:: ÌÀÒÅÐÈÍÑÊÀß ÏËÀÒÀ È ÑÎÊÅÒ
:: ================================================================================
echo [MOTHERBOARD]
set "mb_manufacturer="
set "mb_model="

for /f "skip=1 delims=" %%a in ('wmic baseboard get Manufacturer 2^>nul') do (
    set "mb_manufacturer=%%a"
    if not "!mb_manufacturer!"=="" goto :mb_man_done
)
:mb_man_done

for /f "skip=1 delims=" %%a in ('wmic baseboard get Product 2^>nul') do (
    set "mb_model=%%a"
    if not "!mb_model!"=="" goto :mb_model_done
)
:mb_model_done

echo   Manufacturer: %mb_manufacturer%
echo   Model: %mb_model%
echo.

:: Îïðåäåëåíèå ñîêåòà ïî ìîäåëè ìàòåðèíñêîé ïëàòû
echo [MOTHERBOARD - SOCKET]
set "socket_detected="

if not "%mb_model%"=="" (
    echo %mb_model% | findstr /i "GA-78LMT" >nul && set "socket_detected=AM3+"
    echo %mb_model% | findstr /i "GA-970" >nul && set "socket_detected=AM3+"
    echo %mb_model% | findstr /i "GA-990" >nul && set "socket_detected=AM3+"
    echo %mb_model% | findstr /i "M5A" >nul && set "socket_detected=AM3+"
    echo %mb_model% | findstr /i "B450" >nul && set "socket_detected=AM4"
    echo %mb_model% | findstr /i "B550" >nul && set "socket_detected=AM4"
    echo %mb_model% | findstr /i "X570" >nul && set "socket_detected=AM4"
    echo %mb_model% | findstr /i "Z690" >nul && set "socket_detected=LGA1700"
    echo %mb_model% | findstr /i "Z790" >nul && set "socket_detected=LGA1700"
    echo %mb_model% | findstr /i "B660" >nul && set "socket_detected=LGA1700"
    echo %mb_model% | findstr /i "Z370" >nul && set "socket_detected=LGA1151"
    echo %mb_model% | findstr /i "Z390" >nul && set "socket_detected=LGA1151"
    echo %mb_model% | findstr /i "B360" >nul && set "socket_detected=LGA1151"
)

if "%socket_detected%"=="" (
    echo   Unable to determine automatically
) else (
    echo   %socket_detected%
)
echo.

:: ================================================================================
:: ÂÈÄÅÎÊÀÐÒÀ
:: ================================================================================
echo [GRAPHICS CARD]
set "gpu_found=0"
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get Name 2^>nul') do (
    set "gpu=%%a"
    if not "!gpu!"=="" echo GPU: !gpu! & set gpu_found=1 & goto :gpu_done
)
:gpu_done
if %gpu_found%==0 (
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object -ExpandProperty Name" 2>nul
)
echo.

echo [GRAPHICS CARD - VRAM]
powershell -Command "$vram = (Get-WmiObject -Class Win32_VideoController).AdapterRAM; if ($vram -ge 1073741824) { $vramGB = [math]::Round($vram/1GB, 2); Write-Host ('  VRAM: ' + $vramGB + ' GB') } elseif ($vram -gt 0) { $vramMB = [math]::Round($vram/1MB, 2); Write-Host ('  VRAM: ' + $vramMB + ' MB') } else { Write-Host '  VRAM: not detected' }" 2>nul
echo.

echo [GRAPHICS CARD - RESOLUTION]
set "res_found=0"
for /f "skip=1 delims=" %%a in ('wmic path win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution 2^>nul') do (
    set "res=%%a"
    if not "!res!"=="" echo Resolution: !res! & set res_found=1 & goto :res_done
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
powershell -Command "Get-WmiObject -Class Win32_DesktopMonitor | Select-Object Name, ScreenWidth, ScreenHeight | Format-List" 2>nul
echo.

echo [MONITOR - REFRESH RATE]
powershell -Command "$hz = (Get-WmiObject -Class Win32_VideoController).CurrentRefreshRate; if ($hz) { Write-Host ('Refresh Rate: ' + $hz + ' Hz') } else { Write-Host 'Refresh Rate: not detected' }" 2>nul
echo.

:: ================================================================================
:: ÄÈÑÊÈ
:: ================================================================================
echo [STORAGE DRIVES]
powershell -Command "Get-WmiObject -Class Win32_LogicalDisk -Filter DriveType=3 | ForEach-Object { $size=[math]::Round($_.Size/1GB,2); $free=[math]::Round($_.FreeSpace/1GB,2); Write-Host ('Drive ' + $_.DeviceID + ': ' + $size + ' GB total, free ' + $free + ' GB') }" 2>nul
echo.

echo [DISK TYPE (SSD/HDD)]
powershell -Command "Get-PhysicalDisk | Select-Object MediaType" 2>nul
if errorlevel 1 echo   Disk type info not available (requires Windows 8+)
echo.

:: ================================================================================
:: ÇÂÓÊ
:: ================================================================================
echo [SOUND DEVICES]
powershell -Command "Get-WmiObject -Class Win32_SoundDevice | Select-Object -ExpandProperty Name" 2>nul
echo.

:: ================================================================================
:: ÑÅÒÜ
:: ================================================================================
echo [NETWORK ADAPTERS - IPv4]
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set "ip=%%a"
    if not "!ip!"=="" echo !ip:~1!
)
echo.

echo [MAC ADDRESS]
getmac | findstr /v "NA" | findstr /v "Transport" 2>nul
if errorlevel 1 echo MAC address not available
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
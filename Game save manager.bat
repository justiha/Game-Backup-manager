@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: Clear out lingering variables so a deleted config forces a true fresh start
set "GAME_NAME="
set "SAVE_PATH="
set "WORKSPACE="
set "ACTIVE_PROFILE="
set "PROFILE_COLOR="

set "CONFIG_FILE=%~dp0config.txt"

if not exist "%CONFIG_FILE%" goto SETUP_STEAM

for /f "usebackq delims=" %%I in ("%CONFIG_FILE%") do set "%%I"

:: Fallback if PROFILE_COLOR isn't set in older configs
if "%PROFILE_COLOR%"=="" set "PROFILE_COLOR=96"
goto SPLASH_SCREEN

:: =================================================================
:: PHASE 1: STEAM BASE DISCOVERY (C: Drive + Dynamic Drive Sweep)
:: =================================================================
:SETUP_STEAM
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 STEAM AUTO-DISCOVERY SETUP WIZARD" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to setup Steam to automatically find your saves^?
echo.
echo   [1] Yes - Auto-scan for Steam / userdata
echo   [2] No - Skip Steam setup
echo.
set "steam_choice="
set /p "steam_choice=Select option (1 or 2): "

if "%steam_choice%"=="2" goto SKIP_STEAM
if /i "%steam_choice%"=="no" goto SKIP_STEAM

:: =================================================================
:: PHASE 1: STEAM BASE DISCOVERY (C: Drive + Drive Letter Fallback)
:: =================================================================
echo.
call :COLOR_TEXT "[*] Scanning default C: drive locations..." "WHITE"

set "FOUND_STEAM="

if exist "C:\Program Files (x86)\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files (x86)\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "C:\Program Files\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files\Steam"
    goto PROCESS_STEAM_FOUND
)
if exist "C:\ProgramData\Steam\userdata" (
    set "FOUND_STEAM=C:\ProgramData\Steam"
    goto PROCESS_STEAM_FOUND
)

call :COLOR_TEXT "[!] Default C: drive locations yielded no Steam userdata folder." "YELLOW"
echo.
set "target_drive="
set /p "target_drive=Please enter your Steam drive letter (e.g., D, E, F): "

if "%target_drive%"=="" goto SKIP_STEAM

set "target_drive=%target_drive:~0,1%"
echo [*] Deep searching %target_drive%:\ for any Steam installation...

for /d /r "%target_drive%:\" %%F in (Steam) do (
    if exist "%%~fF\userdata" (
        set "FOUND_STEAM=%%~fF"
        goto PROCESS_STEAM_FOUND
    )
)

call :COLOR_TEXT "[!] Could not locate Steam anywhere on %target_drive%:\ drive." "RED"
set /p "FOUND_STEAM=Manually enter full path to Steam folder: "
if "%FOUND_STEAM%"=="" goto SKIP_STEAM
if exist "%FOUND_STEAM%\userdata" goto PROCESS_STEAM_FOUND

call :COLOR_TEXT "[!] Invalid Steam path provided. Skipping." "RED"
goto SKIP_STEAM

:PROCESS_STEAM_FOUND
set "STEAM_USERDATA_PATH=%FOUND_STEAM%\userdata"
call :COLOR_TEXT "[+] Locked in Steam userdata path: %STEAM_USERDATA_PATH%" "GREEN"
echo.

:: =================================================================
:: PHASE 2: STEAM ACCOUNT SELECTION
:: =================================================================
call :COLOR_TEXT "[*] Scanning for Steam User ID accounts..." "WHITE"
echo.

set "account_count=0"
for /d %%A in ("%STEAM_USERDATA_PATH%\*") do (
    set /a account_count+=1
    set "steam_account[!account_count!]=%%~nxA"
    
    set "game_count=0"
    for /d %%G in ("%%~fA\*") do set /a game_count+=1
    
    echo    [!account_count!] Account ID: %%~nxA  ^(Contains !game_count! game folders^)
)

if %account_count% EQU 0 (
    call :COLOR_TEXT "[!] No Steam ID accounts found. Skipping." "RED"
    goto SKIP_STEAM
)

if %account_count% EQU 1 (
    set "SELECTED_STEAM_ID=!steam_account[1]!"
    call :COLOR_TEXT "[+] Auto-selected sole account ID: !SELECTED_STEAM_ID!" "GREEN"
    goto SAVE_STEAM_CONFIG
)

echo.
set "acc_select="
set /p "acc_select=Select account number: "

if "%acc_select%"=="" set "acc_select=1"

set "SELECTED_STEAM_ID="
for /l %%I in (1,1,%account_count%) do (
    if "%acc_select%"=="%%I" (
        for %%X in (!steam_account[%%I]!) do set "SELECTED_STEAM_ID=%%X"
    )
)

if not defined SELECTED_STEAM_ID (
    call :COLOR_TEXT "[!] Invalid selection. Defaulting to account #1." "YELLOW"
    set "SELECTED_STEAM_ID=!steam_account[1]!"
)

:SAVE_STEAM_CONFIG
set "ACTIVE_ACCOUNT_DIR=%STEAM_USERDATA_PATH%\%SELECTED_STEAM_ID%"
call :COLOR_TEXT "[+] Active Account Directory set to: %SELECTED_STEAM_ID%" "GREEN"

:: Ensure config file variable exists
if not defined CONFIG_FILE set "CONFIG_FILE=game_config.ini"

:: Save choices safely line-by-line (avoids parentheses parsing bugs)
echo STEAM_USERDATA_PATH=%STEAM_USERDATA_PATH%>> "%CONFIG_FILE%"
echo SELECTED_STEAM_ID=%SELECTED_STEAM_ID%>> "%CONFIG_FILE%"
echo STEAM_SETUP_COMPLETE=YES>> "%CONFIG_FILE%"

echo.
call :COLOR_TEXT "[+] Steam setup configuration saved successfully!" "GREEN"
goto STEAM_SETUP_DONE

:SKIP_STEAM
echo.
call :COLOR_TEXT "[-] Steam setup skipped." "YELLOW"
if not defined CONFIG_FILE set "CONFIG_FILE=game_config.ini"
echo STEAM_SETUP_COMPLETE=NO>> "%CONFIG_FILE%"

:STEAM_SETUP_DONE
echo.
pause
goto RUN_SETUP_ROUTINE

:SETUP_STEAM_MENU
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 STEAM AUTO-DISCOVERY SETUP WIZARD" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to setup Steam to automatically find your saves^?
echo.
echo   [1] Yes - Auto-scan for Steam / userdata
echo   [2] No - Skip Steam setup
echo.
set "steam_choice="
set /p "steam_choice=Select option (1 or 2): "

if "%steam_choice%"=="2" goto SKIP_MENU_STEAM
if /i "%steam_choice%"=="no" goto SKIP_MENU_STEAM

:: =================================================================
:: PHASE 1: STEAM BASE DISCOVERY (C: Drive + Drive Letter Fallback)
:: =================================================================
echo.
call :COLOR_TEXT "[*] Scanning default C: drive locations..." "WHITE"

set "FOUND_STEAM="

if exist "C:\Program Files (x86)\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files (x86)\Steam"
    goto PROCESS_STEAM_MENU_FOUND
)
if exist "C:\Program Files\Steam\userdata" (
    set "FOUND_STEAM=C:\Program Files\Steam"
    goto PROCESS_STEAM_MENU_FOUND
)
if exist "C:\ProgramData\Steam\userdata" (
    set "FOUND_STEAM=C:\ProgramData\Steam"
    goto PROCESS_STEAM_MENU_FOUND
)

call :COLOR_TEXT "[!] Default C: drive locations yielded no Steam userdata folder." "YELLOW"
echo.
set "target_drive="
set /p "target_drive=Please enter your Steam drive letter (e.g., D, E, F): "

if "%target_drive%"=="" goto SKIP_MENU_STEAM

set "target_drive=%target_drive:~0,1%"
echo [*] Deep searching %target_drive%:\ for any Steam installation...

for /d /r "%target_drive%:\" %%F in (Steam) do (
    if exist "%%~fF\userdata" (
        set "FOUND_STEAM=%%~fF"
        goto PROCESS_STEAM_MENU_FOUND
    )
)

call :COLOR_TEXT "[!] Could not locate Steam anywhere on %target_drive%:\ drive." "RED"
set /p "FOUND_STEAM=Manually enter full path to Steam folder: "
if "%FOUND_STEAM%"=="" goto SKIP_MENU_STEAM
if exist "%FOUND_STEAM%\userdata" goto PROCESS_STEAM_MENU_FOUND

call :COLOR_TEXT "[!] Invalid Steam path provided. Skipping." "RED"
goto SKIP_MENU_STEAM

:PROCESS_STEAM_MENU_FOUND
set "STEAM_USERDATA_PATH=%FOUND_STEAM%\userdata"
call :COLOR_TEXT "[+] Locked in Steam userdata path: %STEAM_USERDATA_PATH%" "GREEN"
echo.

:: =================================================================
:: PHASE 2: STEAM ACCOUNT SELECTION
:: =================================================================
call :COLOR_TEXT "[*] Scanning for Steam User ID accounts..." "WHITE"
echo.

set "account_count=0"
for /d %%A in ("%STEAM_USERDATA_PATH%\*") do (
    set /a account_count+=1
    set "steam_account[!account_count!]=%%~nxA"
    
    set "game_count=0"
    for /d %%G in ("%%~fA\*") do set /a game_count+=1
    
    echo    [!account_count!] Account ID: %%~nxA  ^(Contains !game_count! game folders^)
)

if %account_count% EQU 0 (
    call :COLOR_TEXT "[!] No Steam ID accounts found. Skipping." "RED"
    goto SKIP_STEAM
)

if %account_count% EQU 1 (
    set "SELECTED_STEAM_ID=!steam_account[1]!"
    call :COLOR_TEXT "[+] Auto-selected sole account ID: !SELECTED_STEAM_ID!" "GREEN"
    goto SAVE_STEAM_MENU_CONFIG
)

echo.
set "acc_select="
set /p "acc_select=Select account number: "

if "%acc_select%"=="" set "acc_select=1"

set "SELECTED_STEAM_ID="
for /l %%I in (1,1,%account_count%) do (
    if "%acc_select%"=="%%I" (
        for %%X in (!steam_account[%%I]!) do set "SELECTED_STEAM_ID=%%X"
    )
)

if not defined SELECTED_STEAM_ID (
    call :COLOR_TEXT "[!] Invalid selection. Defaulting to account #1." "YELLOW"
    set "SELECTED_STEAM_ID=!steam_account[1]!"
)

:SAVE_STEAM_MENU_CONFIG
set "ACTIVE_ACCOUNT_DIR=%STEAM_USERDATA_PATH%\%SELECTED_STEAM_ID%"
call :COLOR_TEXT "[+] Active Account Directory set to: %SELECTED_STEAM_ID%" "GREEN"

:: Ensure config file variable exists
if not defined CONFIG_FILE set "CONFIG_FILE=game_config.ini"

:: SCRUB duplicate/old Steam keys from the config file first so it stays clean
findstr /v /i "STEAM_USERDATA_PATH SELECTED_STEAM_ID STEAM_SETUP_COMPLETE" "%CONFIG_FILE%" > "%CONFIG_FILE%.tmp"
move /y "%CONFIG_FILE%.tmp" "%CONFIG_FILE%" >nul

:: WRITE the fresh values cleanly once
echo STEAM_USERDATA_PATH=%STEAM_USERDATA_PATH%>> "%CONFIG_FILE%"
echo SELECTED_STEAM_ID=%SELECTED_STEAM_ID%>> "%CONFIG_FILE%"
echo STEAM_SETUP_COMPLETE=YES>> "%CONFIG_FILE%"

:: INSTANTLY update live memory variables so the inspector sees it right away!
set "STEAM_SETUP_COMPLETE=YES"

echo.
call :COLOR_TEXT "[+] Steam setup configuration saved successfully!" "GREEN"
goto STEAM_SETUP_MENU_DONE

:SKIP_MENU_STEAM
echo.
call :COLOR_TEXT "[-] Steam setup skipped." "YELLOW"
if not defined CONFIG_FILE set "CONFIG_FILE=game_config.ini"

findstr /v /i "STEAM_USERDATA_PATH SELECTED_STEAM_ID STEAM_SETUP_COMPLETE" "%CONFIG_FILE%" > "%CONFIG_FILE%.tmp"
move /y "%CONFIG_FILE%.tmp" "%CONFIG_FILE%" >nul

echo STEAM_SETUP_COMPLETE=NO>> "%CONFIG_FILE%"
set "STEAM_SETUP_COMPLETE=NO"
goto STEAM_SETUP_MENU_DONE

:STEAM_SETUP_MENU_DONE
echo.
pause

goto ACTION_INSPECTOR

:: =================================================================
:: SETUP & AUTO-DISCOVERY WIZARD
:: =================================================================
:RUN_SETUP_ROUTINE
cls
set "PROFILE_COLOR=96"
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "          MASTER SAVE MANAGER: SETUP WIZARD" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Enter a game keyword, or type [M] for a complete list of supported games:
echo   (e.g.hunter, chaos, blacklist, wd1, wd2, fc5, fc6, acv, aco, skyrimse, etc.)
echo.
set "INPUT_GAME="
set /p "INPUT_GAME=Game Name / Keyword (or M): "

:: Check if user typed M for the full list
if /i "%INPUT_GAME%"=="M" goto SHOW_SUPPORTED_LIST

:: Otherwise, jump straight into our inline cascade checks
goto Check_Docs_Games

:SHOW_SUPPORTED_LIST
mode con: cols=85 lines=65
cls

call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 COMPLETE LIST OF SUPPORTED AUTO-SCAN GAMES" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"

for %%L in (
    "[DOCUMENTS / DUAL-PATH GAMES]"
    "    01. Skyrim Special Edition ..........................[skyrimse]"
    "    02. Fallout 4 .......................................[fo4]"
    "    03. American Truck Simulator ........................[ats]"
    "    04. The Sims 4 ......................................[ts4]"
    "    05. Euro Truck Simulator 2 ..........................[ets2]"
    "    06. Hitman Blood Money ..............................[hitmanbm]"
    "    07  Hogwarts Legacy save.............................[hwl]"
    "        Hogwarts Legacy (mods) ..........................[hwlm]"
    "    08. Horizon Zero Dawn ...............................[hzd]"
    "    09. The Hunter (Call of the Wild) ...................[hunter]"
    "    10. inZOI ...........................................[inzoi]"
    "    11. Marvel's Avengers ...............................[avengers]"
    "    12. Marvel's Spider-Man Remastered ..................[smr]"
    "    13. A Way Out .......................................[awayout]"
    "    14. Fallout: New Vegas ..............................[fonv]"
    "    15. Far Cry New Dawn ................................[fcnd]"
    "    16. Beyond: Two Souls ...............................[bts]"
    "    17. Red Dead Redemption 2 ...........................[rdr2]"
    "    18. The Walking Dead ................................[twd]"
    "    19. The Witcher 3 ...................................[tw3]"
    "    20. Tomb Raider (2013) ..............................[tr13]"
    "    21. Batman Arkham Knight ............................[bak]"
    "[STEAM APP ID GAMES (AUTO-DISCOVERY)]"
    "    22. Grand Theft Auto IV .............................[gta4]"
    "    23. Grand Theft Auto V. .............................[gta5]"
    "    24. Cyberpunk 2077 ..................................[cp2077]"
    "    28. ARK: Survival Evolved (Auto-Detects Local Saves).[ark]"
    "    26. Sleeping Dogs ...................................[sd]"
    "    27. Saints Row (2022) ...............................[saints23]"
    "    28. Sunset Overdrive ................................[sun]"
    "    29. Hitman Absolution................................[hitmanabs]"
	"    30. Hitman (2016)....................................[hitman16]"
    "    31. Rise of the Tomb Raider ........................ [rottr]"
    "    32. MGSV & Metal Gear Survive (online save)..........[mgsv]"
    "    33. Life Is Strange 1 ...............................[lis1]"
    "    34. Life is Strange: Before the Storm ...............[lisbts]"
	"    35. The Awesome Adventures of Captain Spirit.........[taoocs]"
    "    36. Life is Strange 2 ...............................[lis2]"
    "    37. Life Is Strange 3 ...............................[lis3]"
    "    38. Life Is Strange: Double Exposure ................[lisde]"
    "    39. Resident Evil 2 Remake..... .....................[re2]"
    "    40. Resident Evil 3 Remake ..........................[re3]"
    "    41. Resident Evil 4..................................[re4]"
    "    42. Resident Evil Requiem............................[rer]"
    "    43. WWE 2K15 through 2K23 ...........................[wwe15-wwe23]"
    "    44. Disneyland Adventures ...........................[disneyland]"
    "    45. Ready or Not.....................................[ron]"
    "    46. BusSimulator 18..................................[bus18]"
    "    47. Sunset Overdrive.................................[sunset]"
    "    48. Finding Bigfoot..................................[bigfoot]"
    "[UBISOFT GAMES]"
    "    49. Splinter Cell: Chaos Theory .................... [scct]"
    "    50. Splinter Cell Blacklist .........................[blacklist]"
    "    51. Watch Dogs 1 (Local Campaign Saves)..............[wd1]"
    "    52. Watch Dogs 2 (Local Campaign Saves)..............[wd2]"
    "    53. Watch Dogs Legion ...............................[wdl]"
    "    54. Far Cry 5 .......................................[fc5]"
    "    55. Far Cry 6 .......................................[fc6]"
    "    56. Assassin's Creed Shadows ........................[acs]"
    "    57. Assassin's Creed Valhalla .......................[acv]"
    "    58. Assassin's Creed Odyssey ........................[aco]"
    "    59. Assassin's Creed Origins ........................[ori]"
    "    60. Tom Clancy's The Division 2 (online save)........[div2]"
    "    61. Tom Clancy's Ghost Recon Wildlands (Online Save).[grw]"
    "[MANUAL / OTHER]"
    "    62. (Any custom name for manual path input / custom mapper)"
) do (
    echo %%~L
    ping 127.0.0.1 -n 1 -w 5 >nul 2^>^&1
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo  [TIP] Know your game^? Just type its keyword (e.g., gta5, fo4, ets2) 
echo        at the new game prompt screen to map it instantly.
echo.
echo        Don't see your game? No problem! This script will learn it 
echo        via the custom mapper and remember your path forever.
call :COLOR_TEXT "=================================================================" "THEME"
echo.
set /p "MENU_CHOICE=Press Enter to create a new game profile, or type 'M' to return to menu: "
if /i "%MENU_CHOICE%"=="m" goto CHANGE_GAME
goto RUN_SETUP_ROUTINE

:: =================================================================
:: DOCUMENTS / ONEDRIVE GAME ROUTING CASCADES
:: =================================================================

:Check_Docs_Games
:: Each game defines its keyword, pretty name, and subpath relative to Documents/OneDrive

echo "!INPUT_GAME!" | findstr /i "hunter" >nul & if not errorlevel 1 set "KEY=hunter" & set "GAME_NAME=The Hunter Call Of The Wild" & set "DOC_SUBPATH=Avalanche Studios" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "Skyrimse" >nul & if not errorlevel 1 set "KEY=Skyrimse" & set "GAME_NAME=Skyrim Special Edition" & set "DOC_SUBPATH=My Games\Skyrim Special Edition" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "Fo4" >nul & if not errorlevel 1 set "KEY=Fo4" & set "GAME_NAME=Fallout 4" & set "DOC_SUBPATH=My Games\Fallout4" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "ats" >nul & if not errorlevel 1 set "KEY=ats" & set "GAME_NAME=American Truck Simulator" & set "DOC_SUBPATH=American Truck Simulator" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "ts4" >nul & if not errorlevel 1 set "KEY=ts4" & set "GAME_NAME=The Sims 4" & set "DOC_SUBPATH=Electronic Arts\The Sims 4" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "ets2" >nul & if not errorlevel 1 set "KEY=ets2" & set "GAME_NAME=Euro Truck Simulator 2" & set "DOC_SUBPATH=Euro Truck Simulator 2" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "hitmanbm" >nul & if not errorlevel 1 set "KEY=hitmanbm" & set "GAME_NAME=Hitman Blood Money" & set "DOC_SUBPATH=Hitman Blood Money" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "hwlm" >nul & if not errorlevel 1 set "KEY=hwlm" & set "GAME_NAME=Hogwarts Legacy Mods" & set "DOC_SUBPATH=Hogwarts Legacy" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "hzd" >nul & if not errorlevel 1 set "KEY=hzd" & set "GAME_NAME=Horizon Zero Dawn" & set "DOC_SUBPATH=Horizon Zero Dawn" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "inzoi" >nul & if not errorlevel 1 set "KEY=inzoi" & set "GAME_NAME=inZOI" & set "DOC_SUBPATH=inZOI" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "avengers" >nul & if not errorlevel 1 set "KEY=avengers" & set "GAME_NAME=Marvels Avengers" & set "DOC_SUBPATH=Marvel's Avengers" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "smr" >nul & if not errorlevel 1 set "KEY=smr" & set "GAME_NAME=Spider Man Remastered" & set "DOC_SUBPATH=Marvel's Spider-Man Remastered" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "awayout" >nul & if not errorlevel 1 set "KEY=awayout" & set "GAME_NAME=A Way Out" & set "DOC_SUBPATH=My Games\A Way Out\Saves" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "fonv" >nul & if not errorlevel 1 set "KEY=fonv" & set "GAME_NAME=Fallout New Vegas" & set "DOC_SUBPATH=My Games\FalloutNV" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "lis1" >nul & if not errorlevel 1 set "KEY=lis1" & set "GAME_NAME=Life Is Strange" & set "DOC_SUBPATH=My Games\Life Is Strange\Saves" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "lisbts" >nul & if not errorlevel 1 set "KEY=lis1" & set "GAME_NAME=Life is Strange Before the Storm" & set "DOC_SUBPATH=My Games\Life is Strange - Before the Storm\Saved Games" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "lis3" >nul & if not errorlevel 1 set "KEY=lis3" & set "GAME_NAME=Life Is Strange True Colors" & set "DOC_SUBPATH=My Games\LifeIsStrange3\Steam" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "lisde" >nul & if not errorlevel 1 set "KEY=lisde" & set "GAME_NAME=Life Is Strange Double Exposure" & set "DOC_SUBPATH=My Games\LifeIsStrangeDoubleExposure\Steam\Saved" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "bts" >nul & if not errorlevel 1 set "KEY=bts" & set "GAME_NAME=Beyond Two Souls" & set "DOC_SUBPATH=Quantic Dream\Beyond Two Souls\Save" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "rdr2" >nul & if not errorlevel 1 set "KEY=rdr2" & set "GAME_NAME=Red Dead Redemption 2" & set "DOC_SUBPATH=Rockstar Games\Red Dead Redemption 2" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "twd" >nul & if not errorlevel 1 set "KEY=twd" & set "GAME_NAME=The Walking Dead" & set "DOC_SUBPATH=Telltale Games\The Walking Dead" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "tw3" >nul & if not errorlevel 1 set "KEY=tw3" & set "GAME_NAME=The Witcher 3" & set "DOC_SUBPATH=The Witcher 3" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "tr13" >nul & if not errorlevel 1 set "KEY=tr13" & set "GAME_NAME=Tomb Raider (2013)" & set "DOC_SUBPATH=Tomb Raider" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "rottr" >nul & if not errorlevel 1 set "KEY=tr13" & set "GAME_NAME=Rise Of The Tomb Raider" & set "DOC_SUBPATH=Rise of the Tomb Raider" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "bak" >nul & if not errorlevel 1 set "KEY=bak" & set "GAME_NAME=Batman Arkham Knight" & set "DOC_SUBPATH=WB Games" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "gta4" >nul & if not errorlevel 1 set "KEY=gta4" & set "GAME_NAME=Grand Theft Auto 4" & set "DOC_SUBPATH=Rockstar Games\GTA IV" & goto SETUP_DOCS_GAME

echo "!INPUT_GAME!" | findstr /i "gta5" >nul & if not errorlevel 1 set "KEY=gta5" & set "GAME_NAME=Grand Theft Auto 5" & set "DOC_SUBPATH=Rockstar Games\GTA V" & goto SETUP_DOCS_GAME

:: Fallback if none matched in this batch
goto Cyberpunk_2077


:: =================================================================
:: MASTER DOCUMENTS / ONEDRIVE SETUP ROUTINE (SHARED WIZARD)
:: =================================================================
:SETUP_DOCS_GAME
:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\%DOC_SUBPATH%" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\%DOC_SUBPATH%"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\%DOC_SUBPATH%"
)

call :COLOR_TEXT "[+] Keyword matched: %GAME_NAME%" "GREEN"
goto FINALIZE_GAME_SETUP

:Cyberpunk_2077
:: Cyberpunk 2077
echo "!INPUT_GAME!" | findstr /i "cp2077" >nul
if errorlevel 1 goto Ark
set "GAME_NAME=Cyberpunk 2077"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077" (
    set "SAVE_PATH=%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077"
) else (
    set "SAVE_PATH=%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077"
)

call :COLOR_TEXT "[+] Keyword matched: Cyberpunk 2077" "GREEN"
goto FINALIZE_GAME_SETUP

:Ark
:: ARK: Survival Evolved
echo "!INPUT_GAME!" | findstr /i "ark" >nul
if errorlevel 1 goto SleepingDogs

goto SETUP_ARK

:: =================================================================
:: ARK: SURVIVAL EVOLVED AUTO-DISCOVERY SETUP WIZARD
:: =================================================================
:SETUP_ARK
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               ARK: SURVIVAL EVOLVED AUTO-DISCOVERY" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to auto-scan your drives for ARK: Survival Evolved local saves?
echo.
echo   [1] Yes - Auto-scan local drives
echo   [2] No - Skip / Manual input
echo.
set "ark_choice="
set /p "ark_choice=Select option (1 or 2): "

if "%ark_choice%"=="2" goto SKIP_ARK
if /i "%ark_choice%"=="no" goto SKIP_ARK

:: =================================================================
:: PHASE 1: SMART CONFIG CHECK (Using already saved Steam path)
:: =================================================================
echo.
call :COLOR_TEXT "[*] Checking existing Steam configuration..." "WHITE"

set "FOUND_ARK="

:: If Steam userdata path is known from config, check its parent directory for ARK
if defined STEAM_USERDATA_PATH (
    if exist "%STEAM_USERDATA_PATH%\..\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal" (
        set "FOUND_ARK=%STEAM_USERDATA_PATH%\..\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal"
        call :COLOR_TEXT "[+] Found ARK via saved Steam configuration!" "GREEN"
        goto PROCESS_ARK_FOUND
    )
)

:: =================================================================
:: PHASE 2: DEFAULT C: DRIVE & DYNAMIC DRIVE SWEEP
:: =================================================================
echo.
call :COLOR_TEXT "[*] Scanning default C: drive locations..." "WHITE"

if exist "C:\Program Files (x86)\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal" (
    set "FOUND_ARK=C:\Program Files (x86)\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal"
    goto PROCESS_ARK_FOUND
)
if exist "C:\Program Files\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal" (
    set "FOUND_ARK=C:\Program Files\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal"
    goto PROCESS_ARK_FOUND
)
if exist "C:\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal" (
    set "FOUND_ARK=C:\Steam\steamapps\common\ARK\ShooterGame\Saved\SavedArksLocal"
    goto PROCESS_ARK_FOUND
)

call :COLOR_TEXT "[!] Default C: drive locations yielded no ARK save folder." "YELLOW"
echo.
set "target_drive="
set /p "target_drive=Please enter your game drive letter (e.g., D, E, F): "

if "%target_drive%"=="" goto SKIP_ARK

set "target_drive=%target_drive:~0,1%"
echo [*] Deep searching %target_drive%:\ for ARK installations...

:: Dynamic recursive search on the specific drive chosen by the user
for /d /r "%target_drive%:\" %%F in (ARK) do (
    if exist "%%~fF\ShooterGame\Saved\SavedArksLocal" (
        set "FOUND_ARK=%%~fF\ShooterGame\Saved\SavedArksLocal"
        goto PROCESS_ARK_FOUND
    )
)

call :COLOR_TEXT "[!] Could not locate ARK: Survival Evolved on %target_drive%:\." "RED"
set /p "FOUND_ARK=Manually enter full path to SavedArksLocal: "
if "%FOUND_ARK%"=="" goto SKIP_ARK

:PROCESS_ARK_FOUND
set "SAVE_PATH=%FOUND_ARK%"
set "GAME_NAME=ARK: Survival Evolved"
call :COLOR_TEXT "[+] Locked in ARK save path: %SAVE_PATH%" "GREEN"
echo.

:: Save choices to your main config file
(
    echo ARK_SAVE_PATH=%SAVE_PATH%
    echo ARK_SETUP_COMPLETE=YES
) >> "%CONFIG_FILE%"

echo.
call :COLOR_TEXT "[+] ARK setup configuration saved successfully!" "GREEN"
goto ARK_SETUP_DONE

:SKIP_ARK
echo.
call :COLOR_TEXT "[-] ARK auto-discovery skipped." "YELLOW"
(
    echo ARK_SETUP_COMPLETE=NO
) >> "%CONFIG_FILE%"

:ARK_SETUP_DONE
echo.
pause
goto FINALIZE_GAME_SETUP

:SleepingDogs
:: Sleeping Dogs (Original & Definitive Edition)
echo "!INPUT_GAME!" | findstr /i "sd" >nul
if errorlevel 1 goto ReadyOrNot

goto SETUP_SLEEPINGDOGS

:: =================================================================
:: SLEEPING DOGS AUTO-DISCOVERY SETUP WIZARD
:: =================================================================
:SETUP_SLEEPINGDOGS
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               SLEEPING DOGS AUTO-DISCOVERY" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to auto-scan your drives for Sleeping Dogs save folders?
echo.
echo   [1] Yes - Auto-scan local drives
echo   [2] No - Skip / Manual input
echo.
set "sd_choice="
set /p "sd_choice=Select option (1 or 2): "

if "%sd_choice%"=="2" goto SKIP_SD
if /i "%sd_choice%"=="no" goto SKIP_SD

:: =================================================================
:: PHASE 1: SMART CONFIG CHECK (Checking Definitive & Original paths)
:: =================================================================
echo.
call :COLOR_TEXT "[*] Checking existing Steam configuration..." "WHITE"

set "FOUND_SD="
set "GAME_NAME="

if defined STEAM_USERDATA_PATH (
    if exist "%STEAM_USERDATA_PATH%\..\steamapps\common\SleepingDogsDefinitiveEdition\data" (
        set "FOUND_SD=%STEAM_USERDATA_PATH%\..\steamapps\common\SleepingDogsDefinitiveEdition\data"
        set "GAME_NAME=Sleeping Dogs: Definitive Edition"
        call :COLOR_TEXT "[+] Found Definitive Edition via saved Steam configuration!" "GREEN"
        goto PROCESS_SD_FOUND
    )
    if exist "%STEAM_USERDATA_PATH%\..\steamapps\common\SleepingDogs\Data" (
        set "FOUND_SD=%STEAM_USERDATA_PATH%\..\steamapps\common\SleepingDogs\Data"
        set "GAME_NAME=Sleeping Dogs (2012)"
        call :COLOR_TEXT "[+] Found Original (2012) via saved Steam configuration!" "GREEN"
        goto PROCESS_SD_FOUND
    )
)

:: =================================================================
:: PHASE 2: DEFAULT C: DRIVE & DYNAMIC DRIVE SWEEP
:: =================================================================
call :COLOR_TEXT "[*] Scanning default C: drive locations..." "WHITE"

:: Check Definitive Edition first, then Original on C:
if exist "C:\Program Files (x86)\Steam\steamapps\common\SleepingDogsDefinitiveEdition\data" (
    set "FOUND_SD=C:\Program Files (x86)\Steam\steamapps\common\SleepingDogsDefinitiveEdition\data"
    set "GAME_NAME=Sleeping Dogs: Definitive Edition"
    goto PROCESS_SD_FOUND
)
if exist "C:\Program Files (x86)\Steam\steamapps\common\SleepingDogs\Data" (
    set "FOUND_SD=C:\Program Files (x86)\Steam\steamapps\common\SleepingDogs\Data"
    set "GAME_NAME=Sleeping Dogs (2012)"
    goto PROCESS_SD_FOUND
)
if exist "C:\Program Files\Steam\steamapps\common\SleepingDogsDefinitiveEdition\data" (
    set "FOUND_SD=C:\Program Files\Steam\steamapps\common\SleepingDogsDefinitiveEdition\data"
    set "GAME_NAME=Sleeping Dogs: Definitive Edition"
    goto PROCESS_SD_FOUND
)
if exist "C:\Program Files\Steam\steamapps\common\SleepingDogs\Data" (
    set "FOUND_SD=C:\Program Files\Steam\steamapps\common\SleepingDogs\Data"
    set "GAME_NAME=Sleeping Dogs (2012)"
    goto PROCESS_SD_FOUND
)

call :COLOR_TEXT "[!] Default locations yielded no save folder. Asking for drive..." "YELLOW"
echo.
set "target_drive="
set /p "target_drive=Please enter your game drive letter (e.g., D, E, F): "

if "%target_drive%"=="" goto SKIP_SD

set "target_drive=%target_drive:~0,1%"
echo [^*] Deep searching %target_drive%:\ for Sleeping Dogs installations...

:: Dynamic recursive search for Definitive Edition first
for /d /r "%target_drive%:\" %%F in (SleepingDogsDefinitiveEdition) do (
    if exist "%%~fF\data" (
        set "FOUND_SD=%%~fF\data"
        set "GAME_NAME=Sleeping Dogs: Definitive Edition"
        goto PROCESS_SD_FOUND
    )
)

:: Dynamic recursive search for Original (2012) edition next
for /d /r "%target_drive%:\" %%F in (SleepingDogs) do (
    if exist "%%~fF\Data" (
        set "FOUND_SD=%%~fF\Data"
        set "GAME_NAME=Sleeping Dogs (2012)"
        goto PROCESS_SD_FOUND
    )
)

call :COLOR_TEXT "[!] Could not locate Sleeping Dogs on %target_drive%:\." "RED"
set /p "FOUND_SD=Manually enter full path to save folder: "
if "%FOUND_SD%"=="" goto SKIP_SD
set "GAME_NAME=Sleeping Dogs"
goto PROCESS_SD_FOUND

:PROCESS_SD_FOUND
set "SAVE_PATH=%FOUND_SD%"
call :COLOR_TEXT "[+] Locked in save path: %SAVE_PATH%" "GREEN"
echo.

:: Save choices to your main config file
(
    echo SLEEPING_DOGS_PATH=%SAVE_PATH%
    echo SLEEPING_DOGS_SETUP_COMPLETE=YES
) >> "%CONFIG_FILE%"

echo.
call :COLOR_TEXT "[+] Sleeping Dogs setup configuration saved successfully!" "GREEN"
goto SD_SETUP_DONE

:SKIP_SD
echo.
call :COLOR_TEXT "[-] Sleeping Dogs auto-discovery skipped." "YELLOW"
(
    echo SLEEPING_DOGS_SETUP_COMPLETE=NO
) >> "%CONFIG_FILE%"

:SD_SETUP_DONE
echo.
pause
goto FINALIZE_GAME_SETUP

:: =================================================================
:: GAME ROUTING CASCADES
:: =================================================================

:ReadyOrNot
echo "!INPUT_GAME!" | findstr /i "ron" >nul
if errorlevel 1 goto HogwartsLegacy

set "GAME_NAME=Ready or Not"
set "TARGET_SUBPATH=ReadyOrNot\Saved\SaveGames"
set "CFG_PREFIX=READY_OR_NOT"
goto SETUP_APPDATA_GAME


:HogwartsLegacy
echo "!INPUT_GAME!" | findstr /i "hwl" >nul
if errorlevel 1 goto bussim18

set "GAME_NAME=Hogwarts Legacy"
set "TARGET_SUBPATH=Hogwarts Legacy\Saved\SaveGames"
set "CFG_PREFIX=HOGWARTS_LEGACY"
goto SETUP_APPDATA_GAME

:bussim18
echo "!INPUT_GAME!" | findstr /i "bus18" >nul
if errorlevel 1 goto SUNSET

set "GAME_NAME=Bus Simulator 18"
set "TARGET_SUBPATH=BusSimulator18\Saved\SaveGames"
set "CFG_PREFIX=BusSimulator_18"
goto SETUP_APPDATA_GAME

:SUNSET
echo "!INPUT_GAME!" | findstr /i "sunset" >nul
if errorlevel 1 goto Life_is_strange_2

set "GAME_NAME=Sunset Overdrive"
set "TARGET_SUBPATH=Sunset\Saves"
set "CFG_PREFIX=Sunset Overdrive"
goto SETUP_APPDATA_GAME

:Life_is_strange_2
echo "!INPUT_GAME!" | findstr /i "lis2" >nul
if errorlevel 1 goto Captain_Spirit

set "GAME_NAME=Life Is Strange 2 "
set "TARGET_GAME_SUBPATH=LiS2\Saved\SaveGames"
set "CFG_PREFIX=Life_is_strange_2"
goto SETUP_LIS

:Captain_Spirit
echo "!INPUT_GAME!" | findstr /i "taoocs" >nul
if errorlevel 1 goto FindingBigfoot

set "GAME_NAME=The Awesome Adventures of Captain Spirit"
set "TARGET_GAME_SUBPATH=CaptainSpirit\Saved\SaveGames"
set "CFG_PREFIX=Captain_Spirit"
goto SETUP_LIS

:SETUP_LIS
cls
echo =================================================================
echo                 %GAME_NAME% - Auto-Discovery
echo =================================================================
echo.
echo [*] Scanning for Don't Nod profile directories...

set "COUNT=0"
for /d %%D in ("%LOCALAPPDATA%\Dontnod\*") do (
    set /a COUNT+=1
    set "DIR_CHOICE_!COUNT!=%%D"
    echo   [!COUNT!] %%~nxD
)

if %COUNT% EQU 0 (
    echo [!] No profile folders found in Dontnod directory.
    goto MANUAL_PATH_PROMPT
)

echo.
set /p "USER_CHOICE=Select profile folder number (1-%COUNT%): "

:: Validate and assign the selected profile base path
if defined DIR_CHOICE_%USER_CHOICE% (
    call set "TARGET_SAVE_PATH=%%DIR_CHOICE_%USER_CHOICE%%%"
    goto LIS_CONFIRMED
) else (
    echo [!] Invalid selection.
    pause
    goto SETUP_DONTNOD_GAME
)

:LIS_CONFIRMED
:: Appends the specific game subpath we defined before jumping here
set "FOUND_SAVE=%TARGET_SAVE_PATH%\%TARGET_GAME_SUBPATH%"
echo [+] Target locked: %FOUND_SAVE%
goto PROCESS_APPDATA_FOUND

:FindingBigfoot
echo "!INPUT_GAME!" | findstr /i "bigfoot" >nul
if errorlevel 1 goto CHECK_UBI

set "GAME_NAME=Finding Bigfoot"
set "TARGET_SUBPATH=Bigfoot\Saved\SaveGames"
set "CFG_PREFIX=FINDING_BIGFOOT"
goto SETUP_APPDATA_GAME


:: =================================================================
:: MASTER APPDATA SETUP ROUTINE (SHARED WIZARD)
:: =================================================================
:SETUP_APPDATA_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               %GAME_NAME% AUTO-DISCOVERY" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
echo Would you like to auto-scan for %GAME_NAME% save folders?
echo.
echo   [1] Yes - Auto-scan local AppData SaveGames folder
echo   [2] No - Skip / Manual input
echo.
set "app_choice="
set /p "app_choice=Select option (1 or 2): "

if "%app_choice%"=="2" goto SKIP_APPDATA_GAME
if /i "%app_choice%"=="no" goto SKIP_APPDATA_GAME

:: =================================================================
:: PHASE 1: APPDATA LOCAL SCAN
:: =================================================================
echo.
call :COLOR_TEXT "[*] Scanning local AppData locations..." "WHITE"

set "FOUND_SAVE="

if exist "%LOCALAPPDATA%\%TARGET_SUBPATH%" (
    set "FOUND_SAVE=%LOCALAPPDATA%\%TARGET_SUBPATH%"
    goto PROCESS_APPDATA_FOUND
)

call :COLOR_TEXT "[!] Default AppData location yielded no save folder." "YELLOW"
echo.
set /p "FOUND_SAVE=Manually enter full path to save folder: "
if "%FOUND_SAVE%"=="" goto SKIP_APPDATA_GAME

:PROCESS_APPDATA_FOUND
set "SAVE_PATH=%FOUND_SAVE%"
call :COLOR_TEXT "[+] Locked in save path: %SAVE_PATH%" "GREEN"
echo.

:: Save choices to your main config file safely using dynamic prefix keys
if not defined CONFIG_FILE set "CONFIG_FILE=game_config.ini"
echo %CFG_PREFIX%_PATH=%SAVE_PATH%>> "%CONFIG_FILE%"
echo %CFG_PREFIX%_SETUP_COMPLETE=YES>> "%CONFIG_FILE%"

echo.
call :COLOR_TEXT "[+] %GAME_NAME% setup configuration saved successfully!" "GREEN"
goto APPDATA_SETUP_DONE

:APPDATA_SETUP_DONE
echo.
pause
goto FINALIZE_GAME_SETUP

:CHECK_UBI
:: --- EXPANDED UBISOFT DYNAMIC SCANNER ---
set "UBI_GAME_ID="
set "UBI_FRIENDLY_NAME="

:: 2. Splinter Cell: Chaos Theory (Steam / PC Version)
echo "!INPUT_GAME!" | findstr /i "scct" >nul
if errorlevel 1 goto Far_Cry_New_Dawn
set "GAME_NAME=Splinter Cell Chaos Theory"

:: Check if the Documents save path exists, otherwise fall back to ProgramData
if exist "%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory" (
    set "SAVE_PATH=%USERPROFILE%\Documents\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
) else (
    set "SAVE_PATH=C:\ProgramData\Ubisoft\Tom Clancy's Splinter Cell Chaos Theory"
)

call :COLOR_TEXT "[+] Keyword matched: Splinter Cell Chaos Theory" "GREEN"
goto FINALIZE_GAME_SETUP

:Far_Cry_New_Dawn
:: Far Cry New Dawn
echo "!INPUT_GAME!" | findstr /i "fcnd" >nul
if errorlevel 1 goto Blacklist
set "GAME_NAME=Far Cry New Dawn"

:: Check OneDrive path first, otherwise use standard Documents
if exist "%USERPROFILE%\OneDrive\Documents\My Games\Far Cry New Dawn" (
    set "SAVE_PATH=%USERPROFILE%\OneDrive\Documents\My Games\Far Cry New Dawn"
) else (
    set "SAVE_PATH=%USERPROFILE%\Documents\My Games\Far Cry New Dawn"
)

call :COLOR_TEXT "[+] Keyword matched: Far Cry New Dawn" "GREEN"
goto FINALIZE_GAME_SETUP

:Blacklist
echo "!INPUT_GAME!" | findstr /i "blacklist" >nul
if not errorlevel 1 (
    set "GAME_NAME=Splinter Cell Blacklist"
    set "UBI_GAME_ID=91"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Splinter Cell Blacklist"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd1" >nul
if not errorlevel 1 (
    set "GAME_NAME=WatchDogs 1"
    set "UBI_GAME_ID=541"
    set "UBI_FRIENDLY_NAME=Watch Dogs 1"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wd2" >nul
if not errorlevel 1 (
    set "GAME_NAME=WatchDogs 2"
    set "UBI_GAME_ID=3619"
    set "UBI_FRIENDLY_NAME=Watch Dogs 2"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "wdl" >nul
if not errorlevel 1 (
    set "GAME_NAME=WatchDogs Legion"
    set "UBI_GAME_ID=3353"
    set "UBI_FRIENDLY_NAME=Watch Dogs Legion"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc5" >nul
if not errorlevel 1 (
    set "GAME_NAME=Far Cry 5"
    set "UBI_GAME_ID=4310"
    set "UBI_FRIENDLY_NAME=Far Cry 5"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "fc6" >nul
if not errorlevel 1 (
    set "GAME_NAME=Far Cry 6"
    set "UBI_GAME_ID=5291"
    set "UBI_FRIENDLY_NAME=Far Cry 6"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "acs" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Shadows"
    set "UBI_GAME_ID=1081"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Shadows"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "acv" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Valhalla"
    set "UBI_GAME_ID=4256"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Valhalla"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "aco" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Odyssey"
    set "UBI_GAME_ID=5059"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Odyssey"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "ori" >nul
if not errorlevel 1 (
    set "GAME_NAME=Assassin's Creed Origins"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Assassin's Creed Origins"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "div2" >nul
if not errorlevel 1 (
    set "GAME_NAME=The Division 2"
    set "UBI_GAME_ID=3539"
    set "UBI_FRIENDLY_NAME=Tom Clancy's The Division 2"
    goto RUN_UBI_SCAN
)

echo "!INPUT_GAME!" | findstr /i "grw" >nul
if not errorlevel 1 (
    set "GAME_NAME=Ghost Recon Wildlands"
    set "UBI_GAME_ID=1771"
    set "UBI_FRIENDLY_NAME=Tom Clancy's Ghost Recon Wildlands"
    goto RUN_UBI_SCAN
)

:: If all hardcoded keywords AND all Ubisoft checks fail, drop into the Self-Learning Custom Mapper!
goto CHECK_STEAM_IDS

:RUN_UBI_SCAN
set "SAVE_PATH="
call :COLOR_TEXT "[+] Scanning all local drives (A-Z) for Ubisoft savegames..." "YELLOW"

:: 1. Deep sweep across ALL drives (A-Z) for custom Ubisoft library roots & default paths
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (

    :: --- DEEP SCAN: Check common custom folder names on drive root ---
    for %%F in ("Ubisoft Games" "Ubisoft" "Ubisoft Connect" "Ubisoft Game Launcher" "Games\Ubisoft" "Games\Ubisoft Game Launcher") do (
        if exist "%%D:\%%~F\savegames" (
            for /d %%G in ("%%D:\%%~F\savegames\*") do (
                if exist "%%G\%UBI_GAME_ID%" (
                    set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                    call :COLOR_TEXT "[+] Found custom library path on drive %%D: !SAVE_PATH!" "GREEN"
                    goto FINALIZE_GAME_SETUP
                )
            )
        )
    )

    :: --- STANDARD SCAN A: Program Files (x86)\Ubisoft\Ubisoft Game Launcher ---
    if exist "%%D:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames" (
        for /d %%G in ("%%D:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames\*") do (
            if exist "%%G\%UBI_GAME_ID%" (
                set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                call :COLOR_TEXT "[+] Found Program Files path on drive %%D: !SAVE_PATH!" "GREEN"
                goto FINALIZE_GAME_SETUP
            )
        )
    )
    
    :: --- STANDARD SCAN B: Program Files (x86)\Ubisoft Game Launcher (Direct) ---
    if exist "%%D:\Program Files (x86)\Ubisoft Game Launcher\savegames" (
        for /d %%G in ("%%D:\Program Files (x86)\Ubisoft Game Launcher\savegames\*") do (
            if exist "%%G\%UBI_GAME_ID%" (
                set "SAVE_PATH=%%G\%UBI_GAME_ID%"
                call :COLOR_TEXT "[+] Found direct x86 path on drive %%D: !SAVE_PATH!" "GREEN"
                goto FINALIZE_GAME_SETUP
            )
        )
    )
    
    :: --- CUSTOM BACKUP ROOTS ---
    if exist "%%D:\ubisaves\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom backup on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
    if exist "%%D:\ubisaves\savegames\%UBI_GAME_ID%" (
        set "SAVE_PATH=%%D:\ubisaves\savegames\%UBI_GAME_ID%"
        call :COLOR_TEXT "[+] Found custom backup on drive %%D: !SAVE_PATH!" "GREEN"
        goto FINALIZE_GAME_SETUP
    )
)

:: 3. Manual fallback if automated sweeps miss it entirely
call :COLOR_TEXT "[!] Automatic scan missed game ID %UBI_GAME_ID% across all drives." "RED"
set /p "SAVE_PATH=Manually enter save path: "
goto FINALIZE_GAME_SETUP

:: =================================================================
:: STEAM APP ID AUTO-DISCOVERY MAPPER
:: =================================================================
:CHECK_STEAM_IDS
set "GAME_NAME=%INPUT_GAME%"
set "STEAM_APP_ID="

:: --- Action, Open World & RPG ---

echo "!INPUT_GAME!" | findstr /i "saints23" >nul
if errorlevel 1 goto HITMAN
    set "STEAM_APP_ID=742420"
    set "GAME_NAME=Saints Row 2023"
    goto STEAM_ID_MATCHED

:HITMAN
echo "!INPUT_GAME!" | findstr /i "hitmanabs" >nul
if errorlevel 1 goto HITMAN16
    set "STEAM_APP_ID=203140"
    set "GAME_NAME=Hitman Absolution"
    goto STEAM_ID_MATCHED

:HITMAN16
echo "!INPUT_GAME!" | findstr /i "hitman16" >nul
if errorlevel 1 goto MGSV

set "STEAM_APP_ID=236870"
set "GAME_NAME=Hitman 2016"
goto STEAM_ID_MATCHED

:MGSV
echo "!INPUT_GAME!" | findstr /i "mgsv" >nul
if errorlevel 1 goto RES2

set "STEAM_APP_ID=287700"
set "GAME_NAME=Metal Gear Solid V Phantom Pain"
goto STEAM_ID_MATCHED

:: --- Horror & Survival ---

:RES2
echo "!INPUT_GAME!" | findstr /i "re2" >nul
if errorlevel 1 goto RES3

set "STEAM_APP_ID=883710"
set "GAME_NAME=Resident Evil 2"
goto STEAM_ID_MATCHED)

:RES3
echo "!INPUT_GAME!" | findstr /i "re3" >nul
if errorlevel 1 goto RES4

set "STEAM_APP_ID=952060"
set "GAME_NAME=Resident Evil 3"
goto STEAM_ID_MATCHED)

:RES4
echo "!INPUT_GAME!" | findstr /i "re4" >nul
if errorlevel 1 goto RESR

set "STEAM_APP_ID=2050650"
set "GAME_NAME=Resident Evil 4"
goto STEAM_ID_MATCHED

:RESR
echo "!INPUT_GAME!" | findstr /i "rer" >nul
if errorlevel 1 goto NBA2k15

set "STEAM_APP_ID=3764200"
set "GAME_NAME=Resident Evil Requiem"
goto STEAM_ID_MATCHED

:: --- Sports & Casual ---
:NBA2k15
echo "!INPUT_GAME!" | findstr /i "nba15" >nul
if errorlevel 1 goto WWE2K26

set "STEAM_APP_ID=282350"
set "GAME_NAME=NBA2k15"
goto STEAM_ID_MATCHED

:WWE2K26
echo "!INPUT_GAME!" | findstr /i "wwe26" >nul
if errorlevel 1 goto WWE2K25

set "STEAM_APP_ID=3717070"
set "GAME_NAME=WWE 2K26"
goto STEAM_ID_MATCHED

:WWE2K25
echo "!INPUT_GAME!" | findstr /i "wwe25" >nul
if errorlevel 1 goto WWE2K24

set "STEAM_APP_ID=2878960"
set "GAME_NAME=WWE 2K25"
goto STEAM_ID_MATCHED

:WWE2K24
echo "!INPUT_GAME!" | findstr /i "wwe24" >nul
if errorlevel 1 goto WWE2K23

set "STEAM_APP_ID=2315690"
set "GAME_NAME=WWE 2K24"
goto STEAM_ID_MATCHED

:WWE2K23
echo "!INPUT_GAME!" | findstr /i "wwe23" >nul
if errorlevel 1 goto WWE22

set "STEAM_APP_ID=1942660"
set "GAME_NAME=WWE 2K23"
goto STEAM_ID_MATCHED

:WWE22
echo "!INPUT_GAME!" | findstr /i "wwe22" >nul
if errorlevel 1 goto WWE2k19

set "STEAM_APP_ID=1255630"
set "GAME_NAME=WWE 2K22"
goto STEAM_ID_MATCHED

:WWE2k19
echo "!INPUT_GAME!" | findstr /i "wwe19" >nul
if errorlevel 1 goto disneyland

set "STEAM_APP_ID=817130"
set "GAME_NAME=WWE 2k19"
goto STEAM_ID_MATCHED

:disneyland
echo "!INPUT_GAME!" | findstr /i "disneyland" >nul
if errorlevel 1 goto gameoflife

set "STEAM_APP_ID=630610"
set "

GAME_NAME=Disneyland Adventures"
goto STEAM_ID_MATCHED

echo "!INPUT_GAME!" | findstr /i "disneyland" >nul
if not errorlevel 1 set "STEAM_APP_ID=630610"
set "GAME_NAME=Disneyland"

:gameoflife
echo "!INPUT_GAME!" | findstr /i "gameoflife" >nul
if errorlevel 1 goto brothers

set "STEAM_APP_ID=403120"
set "GAME_NAME=Game Of Life"
goto STEAM_ID_MATCHED

echo "!INPUT_GAME!" | findstr /i "gameoflife" >nul
if not errorlevel 1 set "STEAM_APP_ID=403120"
set "GAME_NAME=The Game of Life"

:brothers
echo "!INPUT_GAME!" | findstr /i "brothers" >nul
if errorlevel 1 goto CHECK_CUSTOM_MAPPER

set "STEAM_APP_ID=225080"
set "GAME_NAME=Brothers"
goto STEAM_ID_MATCHED

:: If a Steam App ID was matched, build the path automatically
if defined STEAM_APP_ID (
    if defined STEAM_USERDATA_PATH (
        set "SAVE_PATH=%STEAM_USERDATA_PATH%\%SELECTED_STEAM_ID%\%STEAM_APP_ID%"
        call :COLOR_TEXT "[+] Auto-detected Steam App ID %STEAM_APP_ID% path!" "GREEN"
        goto FINALIZE_GAME_SETUP
    ) else (
        call :COLOR_TEXT "[!] Steam App ID matched, but Steam was skipped/not set up." "YELLOW"
    )
)

:: If no Steam App ID matched, fall through to the custom mapper fallback
goto CHECK_CUSTOM_MAPPER

:STEAM_ID_MATCHED
:: If a Steam App ID was matched, build the path automatically
if defined STEAM_USERDATA_PATH (
    set "SAVE_PATH=%STEAM_USERDATA_PATH%\%SELECTED_STEAM_ID%\%STEAM_APP_ID%"
    call :COLOR_TEXT "[+] Auto-detected Steam App ID %STEAM_APP_ID% path!" "GREEN"
    goto FINALIZE_GAME_SETUP
) else (
    call :COLOR_TEXT "[!] Steam App ID matched, but Steam was skipped/not set up." "YELLOW"
    goto FINALIZE_GAME_SETUP
)

:: =================================================================
:: SELF-LEARNING CUSTOM MAPPER FALLBACK
:: =================================================================
:CHECK_CUSTOM_MAPPER
set "GAME_NAME=%INPUT_GAME%"
set "MAPPED_PATH="

if not exist "%WORKSPACE%\steam_custom_names.txt" (
    type nul > "%WORKSPACE%\steam_custom_names.txt" 2>&1
)

for /f "tokens=1,* delims==" %%A in (%WORKSPACE%\steam_custom_names.txt) do (
    if /i "%%A"=="%GAME_NAME%" (
        set "MAPPED_PATH=%%B"
    )
)

if defined MAPPED_PATH (
    set "SAVE_PATH=%MAPPED_PATH%"
    call :COLOR_TEXT "[+] Found saved path for %GAME_NAME%" "GREEN"
    goto FINALIZE_GAME_SETUP
)

cls
call :COLOR_TEXT "[!] Unknown game/keyword: %GAME_NAME%" "YELLOW"
echo Please provide the live save path for this game so it can be remembered.
set /p "SAVE_PATH=Live Save Path: "

echo %GAME_NAME%=%SAVE_PATH%>> "%WORKSPACE%\steam_custom_names.txt"
call :COLOR_TEXT "[+] Saved new mapping to steam_custom_names.txt" "GREEN"
goto FINALIZE_GAME_SETUP

:: =================================================================
:: FINALIZE GAME SETUP & LAUNCH PROFILE HUB
:: =================================================================
:FINALIZE_GAME_SETUP
:: Ensure default workspace fallback if not set yet
if "%WORKSPACE%"=="" set "WORKSPACE=D:\mods\All in 1 game"

cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "              WORKSPACE FOR %GAME_NAME% CONFIGURATION" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Live Save Path Found:
echo    %SAVE_PATH%
echo.
echo Current or Default Workspace:
echo    %WORKSPACE%
echo.
set /p "USER_WS=Press Enter to keep this, or type a new path: "

if not "%USER_WS%"=="" set "WORKSPACE=%USER_WS%"

set "ACTIVE_PROFILE=Default"

:: --- DIAGNOSTIC PRE-CHECK ---
echo.
echo [DEBUG] Evaluating paths for execution...
echo [DEBUG] WORKSPACE value is: [%WORKSPACE%]
echo [DEBUG] GAME_NAME value is: [%GAME_NAME%]
echo [DEBUG] SAVE_PATH value is: [%SAVE_PATH%]
echo.

:: Create game folder safely
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"

:: Write path using delayed expansion to neutralize (x86) parentheses
setlocal enabledelayedexpansion
echo "!SAVE_PATH!" > "!WORKSPACE!\!GAME_NAME!\game_path.txt"
endlocal

if %errorlevel% EQU 0 (
    call :COLOR_TEXT "[+] SUCCESS: game_path.txt written." "GREEN"
) else (
    call :COLOR_TEXT "[x] FAILED: echo redirection returned error level %errorlevel%" "RED"
)

:: 3. Write config
call :WRITE_CONFIG

echo.
echo Press any key to continue to action menu...
pause >nul
goto ACTION_SWITCH

:SPLASH_SCREEN
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                  SAVE MANAGER - WELCOME BACK" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo.
call :COLOR_TEXT "   Current Game   : %GAME_NAME%" "GREEN"
call :COLOR_TEXT "   Active Profile : %ACTIVE_PROFILE%" "WHITE"
echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo   [1] Go to Main Menu (Save Inspector)
echo   [2] Switch Game
echo   [3] Create New Entry
echo   [4] Quick Backup (%GAME_NAME% ----^> %ACTIVE_PROFILE% Saves Now)
echo   [5] Cycle Between Profiles
echo   [X] Exit
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
set "splash_choice="
set /p "splash_choice=Select option: "

if "%splash_choice%"=="1" goto ACTION_INSPECTOR
if "%splash_choice%"=="2" goto SWITCH_EXISTING_GAME
if "%splash_choice%"=="3" goto SHOW_SUPPORTED_LIST


if "%splash_choice%"=="4" (
    echo.
    call :COLOR_TEXT "[i] Pulling live files into: \"%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%\"" "YELLOW"
    if not exist "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%" mkdir "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"
    robocopy "%SAVE_PATH%" "%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
    call :COLOR_TEXT "[SUCCESS] Quick backup complete." "GREEN"
    pause
    goto SPLASH_SCREEN
)

if /i "%splash_choice%"=="5" goto CYCLE_PROFILE
if /i "%splash_choice%"=="X" exit
goto SPLASH_SCREEN

:: =================================================================
:: IN-PLACE PROFILE CYCLER (Splash Screen Option 4)
:: =================================================================
:CYCLE_PROFILE
set "count=0"
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"

:: Build the array of existing profiles
for /d %%D in ("%WORKSPACE%\%GAME_NAME%\*") do (
    set /a count+=1
    set "prof[!count!]=%%~nD"
)

:: If no profiles exist yet, default to a safe name
if %count%==0 (
    set "ACTIVE_PROFILE=Default"
    goto SAVE_CYCLE_CONFIG
)

:: Find where we currently are in the list and grab the next one
set "matched=0"
for /l %%i in (1,1,%count%) do (
    if /i "!prof[%%i]!"=="%ACTIVE_PROFILE%" (
        set /a "next_i=%%i+1"
        set "matched=1"
    )
)

:: If current profile isn't in the folder list or we hit the end, loop back to #1
if %matched%==0 set "next_i=1"
if !next_i! gtr %count% set "next_i=1"

:: Set the new active profile
set "ACTIVE_PROFILE=!prof[%next_i%]!"

:SAVE_CYCLE_CONFIG
:: Re-save the updated configuration to disk silently so it persists
(
    echo GAME_NAME=%GAME_NAME%
    echo SAVE_PATH=%SAVE_PATH%
    echo WORKSPACE=%WORKSPACE%
    echo ACTIVE_PROFILE=%ACTIVE_PROFILE%
    echo PROFILE_COLOR=%PROFILE_COLOR%
) > "%CONFIG_FILE%"

:: Jump straight back to the splash screen without leaving the page
goto SPLASH_SCREEN

:: =================================================================
:: LIVE GAME SAVE INSPECTOR & HUB
:: =================================================================
:ACTION_INSPECTOR
:: Default to LIVE view if not set yet
if not defined VIEW_MODE set "VIEW_MODE=LIVE"
set "TARGET_PROFILE_DIR=%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"

cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "         SAVE INSPECTOR: [%GAME_NAME%]" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo    Active Profile: %ACTIVE_PROFILE%
echo    Live Save Path: %SAVE_PATH%
echo    TARGET_PROFILE: %TARGET_PROFILE_DIR%
echo.
:: Dynamic Steam Status Display
if /i "%STEAM_SETUP_COMPLETE%"=="YES" (
    call :COLOR_TEXT "    STEAM_SETUP_COMPLETE: YES (%SELECTED_STEAM_ID%)" "GREEN"
) else (
    call :COLOR_TEXT "    STEAM_SETUP_COMPLETE: NO" "RED"
    call :COLOR_TEXT "    [!] If you want to setup Steam, press [S]" "YELLOW"
)
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"

:: Set up the view variables based on the toggle state
if "%VIEW_MODE%"=="LIVE" (
    set "VIEW_PATH=%SAVE_PATH%"
    call :COLOR_TEXT "    Viewing Files: LIVE GAME FOLDER" "GREEN"
) else (
    set "VIEW_PATH=%TARGET_PROFILE_DIR%"
    call :COLOR_TEXT "    Viewing Files: BACKUP PROFILE [%ACTIVE_PROFILE%]" "YELLOW"
)
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"

if exist "%VIEW_PATH%" (
    :: Prints the header info of the dir command with a custom sub-second delay
    for /f "delims=" %%a in ('dir "%VIEW_PATH%" /T:W /O:D ^| findstr /r "^[0-9]"') do (
        echo    %%a
        :: Custom delay: Adjust the -w milliseconds value (e.g., 50, 100, or 200) to change speed
        ping 127.0.0.1 -n 1 -w 5 >nul 2>&1
    )
) else (
    call :COLOR_TEXT "[!] Warning: Directory is currently empty or inaccessible." "RED"
)

call :COLOR_TEXT "=================================================================" "THEME"

:: 1. SET THE TOGGLE LABEL BEFORE RENDERING THE MENU
if "%VIEW_MODE%"=="LIVE" (
    set "TOGGLE_LABEL=Toggle View (Switch to Profile)"
) else (
    set "TOGGLE_LABEL=Toggle View (Switch to Live)"
)

echo    [1] Backup Full %GAME_NAME% Saves ---^> %ACTIVE_PROFILE%
echo    [2] Custom File Selector / Granular Backup
echo    [3] Restore %ACTIVE_PROFILE% ---^> %GAME_NAME% Saves
echo    [4] Switch / Create Profile
echo    [5] Change Theme Color
echo    [6] Change Game / Re-setup
echo    [7] Cloud Sync / Import (Google Drive / OneDrive / Dropbox)
echo    [8] Reset Game Config
echo    [9] %TOGGLE_LABEL%
echo    [X] Exit
call :COLOR_TEXT "=================================================================" "THEME"
set "insp_choice="
set /p "insp_choice=Selection: "

if "%insp_choice%"=="1" (
    echo.
    call :COLOR_TEXT "[INFO] Pulling live files into: %TARGET_PROFILE_DIR%" "YELLOW"
    if not exist "%TARGET_PROFILE_DIR%" mkdir "%TARGET_PROFILE_DIR%"
    robocopy "%SAVE_PATH%" "%TARGET_PROFILE_DIR%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
    call :COLOR_TEXT "[SUCCESS] Backup complete." "GREEN"
    pause
    goto ACTION_INSPECTOR
)

if "%insp_choice%"=="2" goto CUSTOM_FILE_SELECTOR

if "%insp_choice%"=="3" (
    echo.
    call :COLOR_TEXT "WARNING: This will OVERWRITE live game saves with [%ACTIVE_PROFILE%]!" "RED"
    set /p "conf=Confirm Sync? (Y/N): "
    if /i "!conf!"=="Y" (
        if not exist "%SAVE_PATH%" mkdir "%SAVE_PATH%"
        robocopy "%TARGET_PROFILE_DIR%" "%SAVE_PATH%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
        call :COLOR_TEXT "[SUCCESS] Live game folder updated." "GREEN"
    )
    pause
    goto ACTION_INSPECTOR
)

if "%insp_choice%"=="4" goto ACTION_SWITCH
if "%insp_choice%"=="5" goto CHANGE_THEME
if "%insp_choice%"=="6" goto CHANGE_GAME
if "%insp_choice%"=="7" goto CloudInterface
if "%insp_choice%"=="8" (
    del /q "%CONFIG_FILE%"
    call :COLOR_TEXT "[INFO] Config reset. Restart script." "YELLOW"
    pause
    goto :eof
)

:: 2. ADD THE MISSING HANDLER FOR OPTION [8]
if "%insp_choice%"=="9" (
    if "%VIEW_MODE%"=="LIVE" (
        set "VIEW_MODE=PROFILE"
    ) else (
        set "VIEW_MODE=LIVE"
    )
    goto ACTION_INSPECTOR
)

:: Catch user pressing [S] or [s] to configure Steam
if /i "%insp_choice%"=="S" goto SETUP_STEAM_MENU

if /i "%insp_choice%"=="X" exit

goto ACTION_INSPECTOR

:CUSTOM_FILE_SELECTOR
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "        CUSTOM FILE SELECTOR: [%GAME_NAME%]" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo    Active Profile: %ACTIVE_PROFILE%
echo    Source Path:    %VIEW_PATH%
echo    Target Profile: %TARGET_PROFILE_DIR%
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
call :COLOR_TEXT "Type [Action][Item Number] (e.g., 113 to Backup item #13)" "YELLOW"
call :COLOR_TEXT "Actions: [1] Backup Item   [2] Restore Item   [0] Return to Inspector" "YELLOW"
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"

:: Reset index counter and display items with numbers
set "FILE_COUNT=0"
for /f "delims=" %%f in ('dir "%VIEW_PATH%" /b /o:n') do (
    set /a FILE_COUNT+=1
    set "FILE_ITEM_!FILE_COUNT!=%%f"
    echo    [!FILE_COUNT!] %%f
)

call :COLOR_TEXT "=================================================================" "THEME"
set "custom_choice="
set /p "custom_choice=Enter Operation + Item # (e.g. 15): "

if "%custom_choice%"=="0" goto ACTION_INSPECTOR
if "%custom_choice%"=="" goto CUSTOM_FILE_SELECTOR

:: Parse input: First character is the action, remaining characters form the item index
set "ACTION_CODE=%custom_choice:~0,1%"
set "ITEM_INDEX=%custom_choice:~1%"

:: Validate if the selected item index exists
if not defined FILE_ITEM_%ITEM_INDEX% (
    call :COLOR_TEXT "[!] Invalid item index selected." "RED"
    pause
    goto CUSTOM_FILE_SELECTOR
)

:: Retrieve the actual filename/foldername from the array variable
call set "TARGET_FILE_NAME=%%FILE_ITEM_%ITEM_INDEX%%%"

:: Execute based on Action Code [1] Backup or [2] Restore
if "%ACTION_CODE%"=="1" (
    echo.
    call :COLOR_TEXT "[INFO] Backing up target item: %TARGET_FILE_NAME%" "YELLOW"
    if not exist "%TARGET_PROFILE_DIR%" mkdir "%TARGET_PROFILE_DIR%"
    
    :: Check if it's a file or directory to pass proper flags
    if exist "%VIEW_PATH%\%TARGET_FILE_NAME%\*" (
        robocopy "%VIEW_PATH%\%TARGET_FILE_NAME%" "%TARGET_PROFILE_DIR%\%TARGET_FILE_NAME%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
    ) else (
        robocopy "%VIEW_PATH%" "%TARGET_PROFILE_DIR%" "%TARGET_FILE_NAME%" /R:0 /W:0 /NJH /NJS /NFL /NDL
    )
    call :COLOR_TEXT "[SUCCESS] Granular backup complete." "GREEN"
    pause
    goto CUSTOM_FILE_SELECTOR
)

if "%ACTION_CODE%"=="2" (
    echo.
    call :COLOR_TEXT "WARNING: This will overwrite live files with backup item: %TARGET_FILE_NAME%" "RED"
    set /p "conf=Confirm Restore? (Y/N): "
    if /i "!conf!"=="Y" (
        if exist "%TARGET_PROFILE_DIR%\%TARGET_FILE_NAME%\*" (
            robocopy "%TARGET_PROFILE_DIR%\%TARGET_FILE_NAME%" "%VIEW_PATH%\%TARGET_FILE_NAME%" /MIR /R:0 /W:0 /NJH /NJS /NFL /NDL
        ) else (
            robocopy "%TARGET_PROFILE_DIR%" "%VIEW_PATH%" "%TARGET_FILE_NAME%" /R:0 /W:0 /NJH /NJS /NFL /NDL
        )
        call :COLOR_TEXT "[SUCCESS] Granular restore complete." "GREEN"
    )
    pause
    goto CUSTOM_FILE_SELECTOR
)

goto CUSTOM_FILE_SELECTOR

:: =================================================================
:: PROFILE SWITCHER & CREATOR
:: =================================================================
:ACTION_SWITCH
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                PROFILES FOR: %GAME_NAME%" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Existing profile folders:
echo.

set "count=0"
if not exist "%WORKSPACE%\%GAME_NAME%" mkdir "%WORKSPACE%\%GAME_NAME%"

for /d %%D in ("%WORKSPACE%\%GAME_NAME%\*") do (
    set /a count+=1
    set "prof[!count!]=%%~nD"
    echo    [!count!] %%~nD
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo Type an existing profile number to switch, OR type a brand 
echo new profile name to create it instantly.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
set "p_choice="
set /p "p_choice=Select number or type new name: "

if defined prof[%p_choice%] (
    set "ACTIVE_PROFILE=!prof[%p_choice%]!"
) else (
    set "ACTIVE_PROFILE=%p_choice%"
)

call :WRITE_CONFIG

echo.
call :COLOR_TEXT "[+] Active profile switched to: !ACTIVE_PROFILE!" "GREEN"
pause
goto ACTION_INSPECTOR

:: =================================================================
:: THEME COLOR SELECTION SUBROUTINE
:: =================================================================
:CHANGE_THEME
cls
echo ==================================================
call :COLOR_TEXT "              THEME COLOR SELECTION" "THEME"
echo.
echo ==================================================
call :COLOR_TEXT " 1. Green    " "92"
call :COLOR_TEXT " 2. Red      " "91"
call :COLOR_TEXT " 3. White    " "97"
call :COLOR_TEXT " 4. Yellow   " "93"
echo.
call :COLOR_TEXT " 5. Cyan     " "96"
call :COLOR_TEXT " 6. Blue     " "94"
call :COLOR_TEXT " 7. Magenta  " "95"
call :COLOR_TEXT " 8. Gray     " "90"
echo.
echo B. Back to Main Hub
echo ==================================================
set /p "theme_choice=Select: "

if "%theme_choice%"=="1" set "PROFILE_COLOR=92"
if "%theme_choice%"=="2" set "PROFILE_COLOR=91"
if "%theme_choice%"=="3" set "PROFILE_COLOR=97"
if "%theme_choice%"=="4" set "PROFILE_COLOR=93"
if "%theme_choice%"=="5" set "PROFILE_COLOR=96"
if "%theme_choice%"=="6" set "PROFILE_COLOR=94"
if "%theme_choice%"=="7" set "PROFILE_COLOR=95"
if "%theme_choice%"=="8" set "PROFILE_COLOR=90"

if /i "%theme_choice%"=="B" goto ACTION_INSPECTOR

call :WRITE_CONFIG
echo.
call :COLOR_TEXT "[+] Theme updated and config saved!" "GREEN"
timeout /t 2 >nul
goto CHANGE_THEME

:: =================================================================
:: CHANGE GAME / RE-SETUP SUBROUTINE
:: =================================================================
:CHANGE_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 SWITCH ACTIVE GAME" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Would you like to select a new game or switch games^?
echo [1] Yes, change game (Switch existing)
echo [2] Create a new game
echo [m] List All Supported Games ^& Keywords
echo [B] Back to Inspector
echo.
set "cg_choice="
set /p "cg_choice=Selection (1/2/B): "

if "%cg_choice%"=="1" goto SWITCH_EXISTING_GAME
if "%cg_choice%"=="2" goto RUN_SETUP_ROUTINE
if "%cg_choice%"=="m" goto SHOW_SUPPORTED_LIST
if "%cg_choice%"=="b" goto ACTION_INSPECTOR
goto CHANGE_GAME

:: =================================================================
:: SWITCH TO EXISTING GAME FOLDER SUBROUTINE
:: =================================================================
:SWITCH_EXISTING_GAME
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "                 EXISTING GAMES IN WORKSPACE" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Workspace: %WORKSPACE%
echo.

set "g_count=0"
if not exist "%WORKSPACE%" mkdir "%WORKSPACE%"

for /d %%G in ("%WORKSPACE%\*") do (
    set /a g_count+=1
    set "game_opt[!g_count!]=%%~nG"
    
    set "SAVED_GAME_PATH="
    if exist "%WORKSPACE%\%%~nG\game_path.txt" (
        set /p SAVED_GAME_PATH=<"%WORKSPACE%\%%~nG\game_path.txt"
        echo     [!g_count!] %%~nG  [Path: !SAVED_GAME_PATH!]
    ) else (
        echo     [!g_count!] %%~nG  [Path: Not Configured]
    )
)

if %g_count% equ 0 (
    call :COLOR_TEXT "[!] No existing game folders found in workspace." "YELLOW"
    pause
    goto CHANGE_GAME
)

echo.
call :COLOR_TEXT "-----------------------------------------------------------------" "THEME"
echo  [TIP] Type a number to select a game, or type 'o' + number (e.g., o8) 
echo        to instantly open that game's directory!
echo.
set "g_choice="
set /p "g_choice=Select game number or 'o#' to open folder (or Enter to go back): "

if not defined g_choice goto CHANGE_GAME

:: --- CHECK FOR 'O' PREFIX TO OPEN DIRECTORY (e.g., o8, O3) ---
set "first_char=%g_choice:~0,1%"
if /i "%first_char%"=="o" (
    set "num_part=%g_choice:~1%"
    if defined game_opt[%num_part%] (
        set "TARGET_GAME=!game_opt[%num_part%]!"
        set "TARGET_DIR=%WORKSPACE%\!TARGET_GAME!"
        
        :: If a live save path is saved, open that instead of the workspace folder!
        if exist "%WORKSPACE%\!TARGET_GAME!\game_path.txt" (
            set /p TARGET_DIR=<"%WORKSPACE%\!TARGET_GAME!\game_path.txt"
        )
        
        call :COLOR_TEXT "[+] Opening directory for !TARGET_GAME!..." "CYAN"
        start "" "!TARGET_DIR!"
        timeout /t 2 >nul
        goto SWITCH_EXISTING_GAME
    ) else (
        call :COLOR_TEXT "[!] Invalid game number for directory open." "RED"
        timeout /t 2 >nul
        goto SWITCH_EXISTING_GAME
    )
)

:: --- STANDARD GAME SELECTION & SWITCHING ---
if defined game_opt[%g_choice%] (
    set "GAME_NAME=!game_opt[%g_choice%]!"
    
    set "SAVE_PATH="
    if exist "%WORKSPACE%\!GAME_NAME!\game_path.txt" (
        set /p SAVE_PATH=<"%WORKSPACE%\!GAME_NAME!\game_path.txt"
    )
    
    :: If no path file exists, attempt auto-detection first!
    if "!SAVE_PATH!"=="" (
        echo.
        call :COLOR_TEXT "[i] Selected Game: !GAME_NAME!" "YELLOW"
        call :COLOR_TEXT "[i] Attempting auto-detection..." "CYAN"
        
        call :AUTO_DETECT_PATH
        
        :: If auto-detection still couldn't find it, fallback to manual prompt
        if "!SAVE_PATH!"=="" (
            call :COLOR_TEXT "[!] Automatic detection failed. Please enter path manually:" "RED"
            set /p "SAVE_PATH=Live Save Path: "
        )
        
        :: Save the discovered/entered path for future switches
        if not exist "%WORKSPACE%\!GAME_NAME!" mkdir "%WORKSPACE%\!GAME_NAME!"
        echo !SAVE_PATH!> "%WORKSPACE%\!GAME_NAME!\game_path.txt"
    ) else (
        echo.
        call :COLOR_TEXT "[+] Loaded saved path for !GAME_NAME!" "GREEN"
    )
    
    set "ACTIVE_PROFILE=Default"
    call :WRITE_CONFIG
    
    echo.
    call :COLOR_TEXT "[+] Successfully switched to !GAME_NAME!" "GREEN"
    timeout /t 2 >nul
    goto ACTION_SWITCH
)

goto SWITCH_EXISTING_GAME

:: =================================================================
:: CLOUD INTERFACE SUBMENU
:: =================================================================
:CloudInterface
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               CLOUD SYNC & LINKS MANAGER" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo      [1] Download Links / Quick Shortcuts
echo      [2] Import/Export Saves (Drive / Dropbox)
echo      [3] Back to Main Inspector
echo.
set "cloud_choice="
set /p "cloud_choice=Select option: "

if "%cloud_choice%"=="1" goto ADD_CLOUD_LINK
if "%cloud_choice%"=="2" goto Cloud
if "%cloud_choice%"=="3" goto ACTION_INSPECTOR
goto CloudInterface

:: =================================================================
:: CREATE CLOUD LINK DIRECTORY SHORTCUT
:: =================================================================
:ADD_CLOUD_LINK
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "               GET CLOUD DESKTOP CLIENTS" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo This will open your web browser to download the official
echo desktop apps so they integrate directly into Windows file pickers.
echo.
echo   [1] Download Dropbox Desktop App
echo   [2] Download Google Drive for Desktop
echo   [3] Download OneDrive for Desktop (Built-in to W10/W11, reinstall if missing)
echo   [4] Back to Cloud Menu
echo.
set "app_choice="
set /p "app_choice=Select option: "

if "%app_choice%"=="1" (
    start "" "https://www.dropbox.com/download"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="2" (
    start "" "https://www.google.com/drive/download/"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="3" (
    start "" "https://www.microsoft.com/en-us/microsoft-365/onedrive/download"
    goto GET_DESKTOP_APPS
)
if "%app_choice%"=="4" goto CloudInterface

goto GET_DESKTOP_APPS

:: =================================================================
:: CLOUD SAVE IMPORT WORKFLOW
:: =================================================================
:Cloud
cls
call :COLOR_TEXT "=================================================================" "THEME"
call :COLOR_TEXT "             CLOUD SAVE IMPORT (DRIVE / DROPBOX)" "WHITE"
call :COLOR_TEXT "=================================================================" "THEME"
echo Select the cloud folder containing your save files for: %GAME_NAME%
echo.
pause

:: Call the separate PowerShell browser subroutine
call :SELECT_CLOUD_FOLDER

if "%SELECTED_CLOUD_DIR%"=="" (
    call :COLOR_TEXT "[!] No folder selected. Returning..." "YELLOW"
    timeout /t 2 >nul
    goto CloudInterface
)

call :COLOR_TEXT "[+] Selected: %SELECTED_CLOUD_DIR%" "CYAN"
echo.
call :COLOR_TEXT "Where would you like to import these saves?" "WHITE"
echo   [1] Import to Active Profile Folder (%ACTIVE_PROFILE%)
echo   [2] Import to Main Game Root Folder (%GAME_NAME%)
echo.
set "import_dest="
set /p "import_dest=Select destination (1 or 2): "

if "%import_dest%"=="2" (
    set "TARGET_DIR=%WORKSPACE%\%GAME_NAME%"
) else (
    set "TARGET_DIR=%WORKSPACE%\%GAME_NAME%\%ACTIVE_PROFILE%"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo.
call :COLOR_TEXT "[+] Target Directory: %TARGET_DIR%" "YELLOW"
set /p "CONFIRM=Import and overwrite saves in this directory? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto CloudInterface

call :COLOR_TEXT "[+] Copying files from cloud folder..." "YELLOW"
robocopy "%SELECTED_CLOUD_DIR%" "%TARGET_DIR%" /e /xo >nul

call :COLOR_TEXT "[+] Successfully imported saves from cloud storage!" "GREEN"
timeout /t 2 >nul
goto ACTION_INSPECTOR


:: =================================================================
:: POWERSHELL FOLDER BROWSER DIALOG SUBROUTINE
:: =================================================================
:SELECT_CLOUD_FOLDER
set "SELECTED_CLOUD_DIR="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Select Cloud Save Folder (Dropbox / Drive / OneDrive)'; if ($f.ShowDialog() -eq 'OK') { $f.SelectedPath }"`) do (
    set "SELECTED_CLOUD_DIR=%%I"
)
goto :eof

:: =================================================================
:: WRITE CONFIG HELPER SUBROUTINE
:: =================================================================
:WRITE_CONFIG
echo GAME_NAME=%GAME_NAME% > "%CONFIG_FILE%"
echo SAVE_PATH=%SAVE_PATH% >> "%CONFIG_FILE%"
echo WORKSPACE=%WORKSPACE% >> "%CONFIG_FILE%"
echo ACTIVE_PROFILE=%ACTIVE_PROFILE% >> "%CONFIG_FILE%"
echo PROFILE_COLOR=%PROFILE_COLOR% >> "%CONFIG_FILE%"
echo STEAM_USERDATA_PATH=%STEAM_USERDATA_PATH% >> "%CONFIG_FILE%"
echo SELECTED_STEAM_ID=%SELECTED_STEAM_ID% >> "%CONFIG_FILE%"
echo STEAM_SETUP_COMPLETE=%STEAM_SETUP_COMPLETE% >> "%CONFIG_FILE%"
goto :eof

:: =================================================================
:: GLOBAL: COLOR_TEXT SUBROUTINE
:: =================================================================
:COLOR_TEXT
set "TXT=%~1"
set "VAL=%~2"
set "C=97"

if "%VAL%"=="%PROFILE_COLOR%" set "C=%PROFILE_COLOR%" & goto :PRINT
if /i "%VAL%"=="THEME"        set "C=%PROFILE_COLOR%" & goto :PRINT

if /i "%VAL%"=="RED"     set "C=91" & goto :PRINT
if /i "%VAL%"=="GREEN"   set "C=92" & goto :PRINT
if /i "%VAL%"=="YELLOW"  set "C=93" & goto :PRINT
if /i "%VAL%"=="BLUE"    set "C=94" & goto :PRINT
if /i "%VAL%"=="MAGENTA" set "C=95" & goto :PRINT
if /i "%VAL%"=="CYAN"    set "C=96" & goto :PRINT
if /i "%VAL%"=="WHITE"   set "C=97" & goto :PRINT
if /i "%VAL%"=="GRAY"    set "C=90" & goto :PRINT
if "%VAL%" GEQ "90" if "%VAL%" LEQ "97" set "C=%VAL%" & goto :PRINT

:PRINT
<nul set /p "=[%C%m%TXT%[0m"
echo.
goto :eof
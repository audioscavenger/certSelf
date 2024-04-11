@echo OFF
pushd %~sdp0

:top
set version=2.0.21
set author=audioscavenger

:defaults
set commitFile=commit.txt
set editor=notepad
set removeDangling=true
set PROJECT=%~sdp0
set buildVersion=
for %%a in (%PROJECT:\= %) DO set PROJECT=%%a

:custom


:prechecks
call "%~sdpn0.cfg_custom.cmd" >NUL 2>&1 || call "%~sdpn0.cfg.cmd" >NUL 2>&1 || (echo ERROR: missing %~sdpn0.cfg_custom.cmd & timeout /t 5 & exit /b 1)
IF "%~d0"=="%PROJECT%\" echo ERROR: this cannot work at the root drive without a PROJECT name & timeout /t 5 & exit /b 1

git config core.autocrlf true
git config http.postBuffer 209715200

call :setup_time
call :set_colors

:: WIP: notepad++ unfortunately does not work with start /wait
REM IF EXIST "%ProgramFiles%\Notepad++\notepad++.exe" set editor="%ProgramFiles%\Notepad++\notepad++.exe"
IF NOT EXIST "%BACKUP_FOLDER%\" set BACKUP_FOLDER=%~sdp0\backup

:main
title %~n0 %version% by %author%: syncing %PROJECT%
call :getBuildVersion
call :local_backup

call :fetch
call :status_uptodate && goto :end
call :status_master   && call :rename_master
call :status_uptodate && goto :end
call :status_ff       && call :pull_ff
call :status_uptodate && goto :end
call :status_diverged && call :pull_merge
call :status_uptodate && goto :end
call :status_modified && call :add
call :commitMessage
call :local_backup_named %commitFile% %buildName%
call :createTag %commitFile% %buildVersion%
call :commit %commitFile%
call :push
call :unix2dos
goto :end

:pull_ff
echo %HIGH%%b%  %~0 %END% 1>&2

:: These REM blocks are to account for when we pull a different version of this batch.
:: It will eventually crash if the modifications moves the cursor above or below.
:: The solution is to encaps the pull line with commented REM and eventually the cursor will move within the REMs.
:: Indeed this works only if the quantity of modifications that take place BEFORE the pull line stay within +/- 2064 chars.
:: To further protect this sritical line, :pull_ff has been move to the top just afer :main
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 

git merge --ff-only origin/main || git reset --hard origin/main

:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
:: REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM REM 
exit /b %ERRORLEVEL%
goto :EOF

:local_backup
echo %HIGH%%b%  %~0 %END% 1>&2
IF NOT DEFINED BACKUP_FOLDER exit /b 0

md "%BACKUP_FOLDER%" 2>NUL
del /f /q "%BACKUP_FOLDER%\%PROJECT%.7z.tmp*" 2>NUL
echo testing "%BACKUP_FOLDER%\%PROJECT%.7z" ... 1>&2
IF EXIST "%BACKUP_FOLDER%\%PROJECT%.7z" 7z t "%BACKUP_FOLDER%\%PROJECT%.7z" -bse1 2>NUL | findstr ERROR: >NUL && del /f /q "%BACKUP_FOLDER%\%PROJECT%.7z"

:: every nth rotation differential backups, we reset the master backup to decrease its size
for /f %%n in ('dir /b "%BACKUP_FOLDER%\*.7z" 2^>NUL') DO set /A _num=1
set /a "_num%%=rotation"
IF %_num% EQU 0 del /f /q "%BACKUP_FOLDER%\%PROJECT%.7z" 2>NUL

REM -slp : set Large Pages mode
REM -ms=off : disable solid
REM -bso0 : standard output messages to NUL
REM -bsp2 : progress information to stderr
REM -uq0 : File exists in archive, but deleted on disk = Ignore file
REM -uq3 : File exists in archive, but deleted on disk = Create Anti-item
IF EXIST "%BACKUP_FOLDER%\%PROJECT%.7z" (
  call :local_backup_update
) ELSE (
  echo %c%7z a "%BACKUP_FOLDER%\%PROJECT%.7z" -ms=off -slp -bso0 -bsp2 -uq3 %WHAT2BACKUP% %HIGH%%k%%WHAT2EXCLUDE%
  7z a "%BACKUP_FOLDER%\%PROJECT%.7z" -ms=off -slp -bso0 -bsp2 -uq3 %WHAT2BACKUP% %WHAT2EXCLUDE%
  echo:%END%
)

goto :EOF

:local_backup_update
echo %HIGH%%b%  %~0 %END% 1>&2
IF NOT DEFINED BACKUP_FOLDER exit /b 0

:: creates a new archive %PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z and writes to this archive all files from current directory which differ from files in %PROJECT%.7z archive
:: %PROJECT%.7z archive will also be updated after.

echo %c%7z u "%BACKUP_FOLDER%\%PROJECT%.7z" -ms=off -bso0 -bsp2 -up0q3x2z0!"%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z" %WHAT2BACKUP% %HIGH%%k%%WHAT2EXCLUDE%
7z u "%BACKUP_FOLDER%\%PROJECT%.7z" -ms=off -bso0 -bsp2 -up0q3x2z0!"%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z" %WHAT2BACKUP% %WHAT2EXCLUDE%
echo:%END% 1>&2
7z t "%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z" | findstr /C:"No files" && del /f /q "%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z"

goto :EOF

:local_backup_named commitFile buildName
echo %HIGH%%b%  %~0 %END% 1>&2
set commitFile=%1
set buildName=%2

IF DEFINED buildName (
  IF EXIST "%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z" (
    move /y "%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%.7z" "%BACKUP_FOLDER%\%PROJECT%-%CURRENT_DATE_NOSEP%-%CURRENT_TIME%-%buildName%.7z" >NUL 2>&1
  )
)

exit /b %ERRORLEVEL%
goto :EOF

:getBuildVersion
echo %HIGH%%b%  %~0 %END% 1>&2

REM batch:
IF EXIST "%projectConfig%" for /F "tokens=3 delims== " %%v in ('findstr /B /C:"set version=" "%projectConfig%"') DO set buildVersion=%%v
REM python: # version: 0.9.5
IF NOT DEFINED buildVersion IF EXIST "%projectConfig%" for /F "tokens=3" %%v in ('findstr /B /C:"# version: " "%projectConfig%"') DO set buildVersion=%%v

IF NOT DEFINED buildVersion IF EXIST README.md      for /F "tokens=2 delims== " %%v in ('findstr /B /C:"version=" README.md') DO set buildVersion=%%v
IF NOT DEFINED buildVersion set buildVersion=%buildVersionAutomated%
IF NOT DEFINED buildVersion set /p buildVersion=buildVersion? 

goto :EOF

:fetch
echo %HIGH%%b%  %~0 %END% 1>&2
git fetch --all
goto :EOF

:status_ff
echo %HIGH%%b%  %~0 %END% 1>&2
git status | findstr /C:"can be fast-forwarded" && exit /b 0
exit /b 1
goto :EOF

:pull_merge
echo %HIGH%%b%  %~0 %END% 1>&2
git merge origin/main && exit /b 0
git add .
git status >>%commitFile%
git commit -a -F %commitFile%
exit /b %ERRORLEVEL%
goto :EOF

:pull_force
echo %HIGH%%b%  %~0 %END% 1>&2
git pull --force || git reset --hard origin/main
exit /b %ERRORLEVEL%
goto :EOF

:rename_master
echo %HIGH%%b%  %~0 %END% 1>&2
:: for cases such as: Your configuration specifies to merge with the ref 'refs/heads/master'
:: git has renamed master to main since 2020 but people did not notice. Including me.
:: https://www.git-tower.com/learn/git/faq/git-rename-master-to-main
REM git checkout master
REM git branch -a
git symbolic-ref HEAD refs/heads/main
git remote set-head origin -a
git remote set-head origin main
git branch -m master main || git branch -d master --force
git push -u origin main

:: replace master with the contents of main:
:: TODO: see if that is an actual solution to not have to do the GUI part?
git push origin --delete master || git push origin main:master -f
git push origin --delete master || (
  echo:
  echo NOW go to your git^>Settings^>Branches and make the %HIGH%main%end% branch the default
  pause
  echo:
  echo                               %HIGH%DID YOU DO IT?%END%
  echo:
  pause
  REM :: replace master with the contents of main:
  git push origin main:master -f
  REM :: finally we can delete it entirely:
  git push origin --delete master
)
REM branch 'main' set up to track 'origin/main'.
REM remote: Gitea: branch master is the default branch and cannot be deleted
REM ! [remote rejected] master (pre-receive hook declined)
exit /b %ERRORLEVEL%
goto :EOF

:status_diverged
echo %HIGH%%b%  %~0 %END% 1>&2

git status | findstr /C:"have diverged" >NUL && git status && exit /b 0
exit /b 1
goto :EOF

:status_modified
echo %HIGH%%b%  %~0 %END% 1>&2

git status | findstr /C:"Untracked files:" >NUL && git status && exit /b 0
git status | findstr /C:"Changes not staged for commit:" >NUL && git status && exit /b 0
exit /b 1
goto :EOF

:status_master
echo %HIGH%%b%  %~0 %END% 1>&2

git status | findstr /I /C:"On branch master" && exit /b 0
git branch -a | findstr /I /C:"origin/master" && exit /b 0
exit /b 1
goto :EOF

:status_uptodate
echo %HIGH%%b%  %~0 %END% 1>&2

git status | findstr /I /C:"On branch master" >NUL && exit /b 1
git status | findstr /I /C:"Your branch is ahead" >NUL && exit /b 1
git status | findstr /I /C:"Your branch is behind" >NUL && exit /b 1
git status | findstr /I /C:"Changes not staged for commit" >NUL && exit /b 1
git status | findstr /I /C:"have diverged" >NUL && exit /b 1
git status | findstr /I /C:"nothing to commit" && exit /b 0

git status
exit /b 1
goto :EOF

:add
echo %HIGH%%b%  %~0 %END% 1>&2
:: git rm --cached `git ls-files -i -c --exclude-from=.gitignore` 
for /f "tokens=*" %%a in ('git ls-files -i -c --exclude-from=.gitignore') DO git rm --cached "%%a"
git add .
git status
exit /b %ERRORLEVEL%
goto :EOF

:commitMessage
echo %HIGH%%b%  %~0 %END% 1>&2

set commitFile=commit.%PROJECT%.%buildVersion%.txt

:: get remote message over local message; we must assume that the remote is always the current one
git tag -l %buildVersion% -n999 >%commitFile%
call :isEmpty %commitFile% && echo Pulling message for tag %buildVersion%: EMPTY || echo Pulling message for tag %buildVersion%: EXIST

:: we now reuse older commitFile if exist. Commit again over same version will also recreate the tag
call :isEmpty %commitFile% && echo WIP %buildVersion% >%commitFile%
:: we now append modifications to the same commit message and replace the tag each time. Makes more sense.
git status | findstr "modified: deleted:" >>%commitFile%

:: insert smth like "release 1.2.3 tidy" or "WIP 1.2.3" as the first line
start "" /wait %editor% %commitFile%

:: if you input smth like "release 1.2.3 tidy" as the first line, buildName=tidy and a named differential zipfile will be created
set buildName=
for /f "tokens=3*" %%n in ('findstr /B release %commitFile%') DO set "buildName=%%n"

exit /b %ERRORLEVEL%
goto :EOF

:createTag commitFile buildVersion
echo %HIGH%%b%  %~0 %END% 1>&2
set commitFile=%1
set buildVersion=%2

git tag -d %buildVersion% 2>NUL
git push --delete origin %buildVersion% 2>NUL
:: failure to delete remote tage will simply output an error when pushing later on:
 REM ! [rejected]        7.2.19 -> 7.2.19 (already exists)
REM error: failed to push some refs to 'https://github.com/user/project'
REM hint: Updates were rejected because the tag already exists in the remote.

git tag -a %buildVersion% --file=%commitFile%
:: what to do with error: failed to push some refs to 'https://git/name/project'?

exit /b %ERRORLEVEL%
goto :EOF

:commit commitFile
echo %HIGH%%b%  %~0 %END% 1>&2

attrib /S -R >NUL 2>&1
REM icacls .git       /q /c /t /reset
REM The tag present in the reparse point buffer is invalid.

git commit -a -F %1
REM error: unable to create temporary file: Invalid argument      -->.git was read-only
REM error: install-DS-1-product.cmd: failed to insert into database
REM error: unable to index file 'install-DS-1-product.cmd'
REM fatal: updating files failed

exit /b %ERRORLEVEL%
goto :EOF

:push
echo %HIGH%%b%  %~0 %END% 1>&2
REM git push
git push origin main --tags --set-upstream 

exit /b %ERRORLEVEL%
goto :EOF

:unix2dos
echo %HIGH%%b%  %~0 %END% 1>&2
IF /I "%doUnix2dos%"=="true" where busybox >NUL 2>&1 && FOR /f "tokens=*" %%F in ('dir /b /s %textFiles%') DO busybox unix2dos "%%~F"
goto :EOF

:set_colors
set END=[0m
set HIGH=[1m
set Underline=[4m
set REVERSE=[7m

REM echo [101;93m NORMAL FOREGROUND COLORS [0m
set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m

goto :EOF


:setup_time
IF DEFINED DEBUG echo DEBUG: %m%%~n0 %~0 %HIGH%%*%END% 1>&2

set CURRENT_DATE=%DATE:/=-%
set GOOD_DATE=%CURRENT_DATE:~0,10%
:: ISO
if "%CURRENT_DATE:~2,1%" EQU "-" set GOOD_DATE=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%
:: US
if "%CURRENT_DATE:~3,1%" EQU " " set GOOD_DATE=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%
set CURRENT_DATE_NOSEP=%GOOD_DATE:-=%

set CURRENT_TIME=%TIME::=%

:: BUG: cannot add numbers that start with 0
set /A nextHour=%CURRENT_TIME:~0,2% + 1
set nextHour=%nextHour%%TIME:~3,2%

if "%CURRENT_TIME:~0,1%" == " " set CURRENT_TIME=0%CURRENT_TIME:~1%
set CURRENT_TIME=%CURRENT_TIME:~0,4%
goto :EOF


:isEmpty
IF NOT EXIST %1 exit /b 0
exit /b 0%~z1
goto :EOF


:end
echo -------------------- THE END -------------------- 1>&2
git gc --auto
IF NOT DEFINED removeDangling git fsck | findstr dangling && (
  echo: 1>&2
  set /p removeDangling=remove danglings? [N/y] 
)
IF DEFINED removeDangling (
  git reflog expire --expire=now --all
  git gc --prune=now
)


REM redirect origin: git remote set-url origin https://github.com/user/gitsync
REM git config merge.tool vimdiff
REM git config merge.conflictstyle diff3
REM git config mergetool.prompt false

REM git config --global user.email you@example.com
REM git commit --amend --reset-author

REM reset existing project:
REM git init
REM git remote add origin https://github.com/user/gitsync
REM git fetch --force
REM git reset --hard
REM git clean -fd
REM git pull --force

REM also rename master to main:
REM git symbolic-ref HEAD refs/heads/main
REM git remote set-head origin -a
REM git remote set-head origin main
REM git branch -m master main || git branch -d master --force
REM git push -u origin main
REM git push origin --delete master || echo now switch master as default on the remote
REM git push origin --delete master

REM git pull origin main --force

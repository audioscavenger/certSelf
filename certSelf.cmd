@echo OFF
pushd %~dp0
setlocal

:: TODO: https://medium.com/better-programming/trusted-self-signed-certificate-and-local-domains-for-testing-7c6e6e3f9548

:top
set version=1.2.1
set author=lderewonko

set DEBUG=
set VERBOSE=
set AUTOMATED=True
set PORT=443
set YEARS=30
set FriendlyName=wildcard.%USERDNSDOMAIN%
set Subject=CN=%FriendlyName%,OU=nQ,O=%USERDOMAIN%,DC=%USERDOMAIN%,DC=com

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
title %~nx0 %version% - %USERNAME%@%USERDNSDOMAIN% - %COMPUTERNAME%
call :detect_admin_mode 0 || goto :end
call :getIPv4 %COMPUTERNAME% ipV4

echo              will include:
echo                           DNS=*.%USERDNSDOMAIN%
echo                           DNS=%COMPUTERNAME%
echo                            IP=%ipV4%
echo                           URL=https://%COMPUTERNAME%.%USERDNSDOMAIN%:%PORT%/

set /P FriendlyName=FriendlyName?   [ %FriendlyName% ] 
set /P         PORT=PORT?           [ 443 ] 
set /P      Subject=Subject?        [ %Subject% ]
set /P        YEARS=How many years? [ %YEARS% ]

IF "%PORT%"=="443" (set "PORT=") ELSE (set "PORT=:%PORT%")

:: create it:
REM :: this does not work as cert never gets copied to the Root store:
REM powershell -Command "$Certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(%YEARS%) -FriendlyName '%COMPUTERNAME%' -Subject '%COMPUTERNAME%' -DnsName localhost,%COMPUTERNAME%,*.%USERDNSDOMAIN%,%ipV4% -KeyUsage @('KeyEncipherment','DataEncipherment','KeyAgreement'); $dstStore = New-Object System.Security.Cryptography.X509Certificates.X509Store Root, LocalMachine; $dstStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite); $dstStore.Add($Certificate); $dstStore.Close()"

REM SYNTAX
    REM New-SelfSignedCertificate [-SecurityDescriptor <FileSecurity>] [-TextExtension <string[]>] [-Extension
    REM <X509Extension[]>] [-HardwareKeyUsage {None | SignatureKey | EncryptionKey | GenericKey | StorageKey |
    REM IdentityKey}] [-KeyUsageProperty {None | Decrypt | Sign | KeyAgreement | All}] [-KeyUsage {None | EncipherOnly |
    REM CRLSign | CertSign | KeyAgreement | DataEncipherment | KeyEncipherment | NonRepudiation | DigitalSignature |
    REM DecipherOnly}] [-KeyProtection {None | Protect | ProtectHigh | ProtectFingerPrint}] [-KeyExportPolicy
    REM {NonExportable | ExportableEncrypted | Exportable}] [-KeyLength <int>] [-KeyAlgorithm <string>]
    REM [-SmimeCapabilities] [-ExistingKey] [-KeyLocation <string>] [-SignerReader <string>] [-Reader <string>]
    REM [-SignerPin <securestring>] [-Pin <securestring>] [-KeyDescription <string>] [-KeyFriendlyName <string>]
    REM [-Container <string>] [-Provider <string>] [-CurveExport {None | CurveParameters | CurveName}] [-KeySpec {None |
    REM KeyExchange | Signature}] [-Type {Custom | CodeSigningCert | DocumentEncryptionCert | SSLServerAuthentication |
    REM DocumentEncryptionCertLegacyCsp}] [-FriendlyName <string>] [-NotAfter <datetime>] [-NotBefore <datetime>]
    REM [-SerialNumber <string>] [-Subject <string>] [-DnsName <string[]>] [-SuppressOid <string[]>] [-HashAlgorithm
    REM <string>] [-AlternateSignatureAlgorithm] [-TestRoot] [-Signer <Certificate>] [-CloneCert <Certificate>]
    REM [-CertStoreLocation <string>] [-WhatIf] [-Confirm]  [<CommonParameters>]

REM :: alternative method: just create it then copy it
REM powershell -Command "New-SelfSignedCertificate -FriendlyName '%FriendlyName%' -Subject '%FriendlyName%' -DnsName *.%USERDNSDOMAIN%,%COMPUTERNAME%,%ipV4% -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(%YEARS%)"

:: https://learn.microsoft.com/en-us/powershell/module/pki/new-selfsignedcertificate?view=windowsserver2022-ps
:: https://learn.microsoft.com/en-us/powershell/module/pki/new-selfsignedcertificate?view=windowsserver2022-ps#-textextension
REM Basic Constraints: 2.5.29.19
REM Certificate Policies: 2.5.29.32
REM Enhanced Key Usage: 2.5.29.37
REM Name Constraints: 2.5.29.30
REM Policy Mappings: 2.5.29.33
REM Subject Alternative Name: 2.5.29.17


powershell -Command "$params = @{FriendlyName = '%FriendlyName%'; Subject = 'CN=%FriendlyName%,OU=nQ,O=%USERDOMAIN%,DC=%USERDOMAIN%,DC=com'; TextExtension = @('2.5.29.37={text}1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1','2.5.29.17={text}DNS=*.%USERDNSDOMAIN%&DNS=%COMPUTERNAME%&IPAddress=%ipV4%&URL=https://%COMPUTERNAME%.%USERDNSDOMAIN%%PORT%/); CertStoreLocation = 'Cert:\LocalMachine\My'; NotAfter = (Get-Date).AddYears(%YEARS%); KeyAlgorithm = 'RSA'; KeyUsageProperty = 'All'; KeyUsage = @('KeyEncipherment','DataEncipherment','KeyAgreement','DigitalSignature','CertSign','CRLSign');  }; New-SelfSignedCertificate @params"

:: list it: select by Subject suddenly stopped wotking on 2024-04-08
REM powershell -Command "dir Cert:\LocalMachine\My\ | Where-Object {$_.Subject -eq 'CN=%FriendlyName%'} | ForEach-Object {    [PSCustomObject] @{        Subject = $_.Subject;        SAN = $_.DnsNameList    }}"

:: list them all:
REM powershell -Command "Get-ChildItem -Path Cert:\LocalMachine\My\ | Select ThumbPrint,FriendlyName,subject,notafter"
powershell -Command "Get-ChildItem -Path Cert:\LocalMachine\My\ | Select ThumbPrint,FriendlyName,NotAfter,@{name='Subject Alternative Name';expression={($_.Extensions | Where-Object {$_.Oid.FriendlyName -eq 'Subject Alternative Name'}).format($true)}} | ft -wrap"


:: add it to Cert:\LocalMachine\Root\: https://social.technet.microsoft.com/wiki/contents/articles/28753.powershell-trick-copy-certificates-from-one-store-to-another.aspx
powershell -Command "$SourceStore = new-object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::My,'LocalMachine'); $SourceStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly); $DestStore = new-object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root,'LocalMachine'); $DestStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite); $cert = $SourceStore.Certificates | Where {$_.FriendlyName -eq '%FriendlyName%'}; $DestStore.Add($cert); $SourceStore.Close(); $DestStore.Close();"

:: list it in the new store:
powershell -Command "dir Cert:\LocalMachine\Root\ | Where-Object {$_.FriendlyName -eq '%FriendlyName%'} | ForEach-Object {    [PSCustomObject] @{        Subject = $_.Subject;        SAN = $_.DnsNameList    }}"


goto :end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:getIPv4 fromAddress intoVar
IF "%~2"=="" exit /b 1

for /f "tokens=2" %%I in ('nslookup %~1 ^| findstr /B Address:') DO set %~2=%%I
goto :EOF


:detect_admin_mode [num]
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file

set req=%1
set bits=32
set bitx=x86
IF DEFINED PROCESSOR_ARCHITEW6432 echo WARNING: running 32bit cmd on 64bit system 1>&2
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set arch=-x64
  set bits=64
  set bitx=x64
)
REM %SystemRoot%\system32\whoami /groups | findstr "12288" >NUL && set "ADMIN=0" || set "ADMIN=1"
REM net session  >NUL 2>&1 && set "ADMIN=0" || set "ADMIN=1"
reg add hklm /f >NUL 2>&1 && set "ADMIN=0" || set "ADMIN=1"
IF %ADMIN% EQU 0 (
  echo Batch started with ADMIN rights 1>&2
) ELSE (
  echo Batch started with USER rights 1>&2
)

IF DEFINED req (
  IF NOT "%ADMIN%" EQU "%req%" (
    IF "%ADMIN%" GTR "%req%" (
      echo %y%Batch started with USER privileges, when ADMIN was needed.%END% 1>&2
      IF DEFINED AUTOMATED exit /b 1
      REM :UACPrompt
      gpresult /R | findstr BUILTIN\Administrators >NUL || net session >NUL 2>&1 || (echo :error %~0: User %USERNAME% is NOT localadmin & exit /b 1)
      echo Set UAC = CreateObject^("Shell.Application"^) >"%TEMP%\getadmin.vbs"
      REM :: WARNING: cannot use escaped parameters with this one:
      IF DEFINED params (
        echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params:"=""%", "", "runas", 1 >>"%TEMP%\getadmin.vbs"
      ) ELSE echo UAC.ShellExecute "cmd.exe", "/c %~s0", "", "runas", 1 >>"%TEMP%\getadmin.vbs"
      CScript //B "%TEMP%\getadmin.vbs"
      del /q "%TEMP%\getadmin.vbs"
    ) ELSE (
      echo %r%Batch started with ADMIN privileges, when USER was needed. EXIT%END% 1>&2
      IF NOT DEFINED AUTOMATED timeout /t 5 1>&2
    )
	exit /b 1
  )
)
goto :EOF


:end
pause
exit /b 0


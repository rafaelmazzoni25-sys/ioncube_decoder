@ECHO OFF
SETLOCAL
TITLE Decode ALL Files By TAG

REM Resolve the absolute path of this script directory without trailing slash
SET "KIT_ROOT=%~dp0"
IF "%KIT_ROOT:~-1%"=="\" SET "KIT_ROOT=%KIT_ROOT:~0,-1%"

REM Provide absolute paths so PHP can find the ionCube/Zend components
SET "IONCUBE_LOADER=%KIT_ROOT%\ioncube\ioncube_loader_win_7.4.dll"
SET "IONCUBE_ZEND_MANAGER=%KIT_ROOT%\ioncube\Zend\ZendExtensionManager.dll"
SET "IONCUBE_ZEND_OPTIMIZER=%KIT_ROOT%\ioncube\Zend\Optimizer"

busybox.exe sh "bat\functions-decoder.sh"

pause

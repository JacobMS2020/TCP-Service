;TCP Client
Global $Version = "0.1.2" ;package(server&client).features.fix
Global $LAN = True ; If the program running on the LAN (or WAN)

#include <File.au3>
#include <String.au3>
#include <APIDiagConstants.au3>
#include <WinAPIDiag.au3>

;Opt("TCPTimeout", 100)
;Opt("TrayIconHide", 1) ;Hide tray icon

#Region ===== VARS
; Files and Progs (Programs)
	Global $DirBin = @ScriptDir&"\Bin\"
	Global $FileLogClient = $DirBin&"Client_Log.log"
	Global $FileServerDetails = $DirBin&"ServerDetails"
	Global $ProgUpdate = $DirBin&"Update Client.exe"
; URLS
;	Managment link - https://drive.google.com/drive/u/0/folders/1fcgOyQqRQHs1Up3AU_aereBuKvHmtQvs
	Global $URLServerDetails="https://drive.google.com/uc?export=download&id=15xoQUkHFMRIOh_mrG9pu0dNRK9px48GY" ;Server Details File on Google Drive
; Server
						  ;|        1       |         2      |    3   |    4   |   5
	Global $ServerDetails ;| Server Version | Client Version | LAN IP | WAN IP | PORT
	Global $Socket = -1
;Client Details
	Global $clientUniqueHardwareID = _WinAPI_UniqueHardwareID($UHID_BIOS)
#EndRegion

#Region ===== ===== DOWNLOAD / INTERNET / SETUP / STARTUP
; Setup
	If Not FileExists($DirBin) Then DirCreate($DirBin)
; Internet
	$timerStartup=TimerInit()
	_log(@CRLF&"---START---")
	_log("Internet Check...")
	Do
		$InternetTest=Ping("www.google.com",1000)
		If @error <> 0 Then _log("ERROR: No Internet")

	Until @error = 0
	_log("Ping: "&$InternetTest&"ms")
	_log("Internet UP ("&TimerDiff($timerStartup)&"ms)")

; Download Server Details
	$ServerDetails= StringSplit( _HexToString( InetRead($URLServerDetails) ), ",")
	_log($ServerDetails[1]&" | "&$ServerDetails[2]&" | "&$ServerDetails[3]&" | "&$ServerDetails[4]&" | "&$ServerDetails[5]&" ("&TimerDiff($timerStartup)&"ms)")

; Setup
	If $LAN = True Then
		$tcpIP = $ServerDetails[3]
	Else
		$tcpIP = $ServerDetails[4]
	EndIf
	$tcpPORT = $ServerDetails[5]
	_log("Port: "&$tcpPORT)
	_log("IP: "&$tcpIP)

	TCPStartup()
	_log("Setup compleate ("&TimerDiff($timerStartup)&"ms)")
	_connect()

#EndRegion

#Region ===== ===== Main Loop
	GUICreate("Client",150,200)

	GUISetState()
	While 1
		$GUIMSG=GUIGetMsg()
		If $GUIMSG=-3 Then ExitLoop

	WEnd

	;TCPCloseSocket($Socket)
	;TCPShutdown()
	Exit
#EndRegion


#Region ===== ===== FUNCTIONS
;Connection Loop
	Func _connect()
		_log("Looking for server (loop)")
		Do
			$Socket=TCPConnect($tcpIP,$tcpPORT)
			Sleep(500)
		Until $Socket <> -1
		_log("Server Found!")
	EndFunc
;Update Client
	Func _UpdateExit()
		TCPCloseSocket($Socket)
		TCPShutdown()
		ShellExecute($ProgUpdate)
		Exit
	EndFunc
;Log
	Func _log($_logMSG)
		_FileWriteLog($FileLogClient,$_logMSG,1)
	EndFunc

#EndRegion
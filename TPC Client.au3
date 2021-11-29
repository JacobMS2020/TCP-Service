;TCP Client
Global $Version = "1.0.0" ;package(server&client).features.fix
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
	Global $URLServerDetails=FileReadLine(@ScriptDir&"\serverDetailsURL.txt",1) ;Server Details File on Google Drive
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
	If $ServerDetails[0]<2 Then
		_log('Server Details File Download Error. URL: '&$URLServerDetails)
		Exit
	EndIf
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

		_Recive()

		Sleep(50)
	WEnd

	TCPCloseSocket($Socket)
	TCPShutdown()
	Exit
#EndRegion

#Region ===== ===== FUNCTIONS
;----- Commands
	Func _commands($_command)
		Switch $_command
			Case "server_offline"
				_log('Server has gone offline, going to _connect after 10000ms')
				MsgBox(0,'','Server has gone offline, going to _connect after 10000ms')
				Sleep(10000)
				_connect()
				Return
		EndSwitch
	EndFunc
;----- Recive
	Func _Recive()
		$_recive=TCPRecv($Socket,99999)
		If $_recive<>"" And $_recive<>"test" Then
			_commands($_recive)
		EndIf
	EndFunc
;----- Connect - Look for server Loop
	Func _connect()
		_log("Looking for server (loop)")
		Do
			$Socket=TCPConnect($tcpIP,$tcpPORT)
			Sleep(5000)
		Until $Socket <> -1
		_log("Server Found!")
	EndFunc
;----- Update Client
	Func _UpdateExit()
		TCPCloseSocket($Socket)
		TCPShutdown()
		ShellExecute($ProgUpdate)
		Exit
	EndFunc
;----- Log
	Func _log($_logMSG)
		_FileWriteLog($FileLogClient,$_logMSG,1)
	EndFunc

#EndRegion
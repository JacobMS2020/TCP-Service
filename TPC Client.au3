;TCP Client
Global $Version = "1.1.0" ;package(server&client).features.fix
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
; Client
	Global $boolSetup=False
	Global $boolConnection=False
	Global $tcpIP = -1
	Global $tcpPORT = -1
; Timers
	Global $timerLastMSG
; Client Details
	Global $clientUniqueHardwareID = _WinAPI_UniqueHardwareID($UHID_BIOS)
#EndRegion

#Region ===== ===== DOWNLOAD / INTERNET / SETUP / STARTUP
_Setup()
Func _Setup()
; (Function called after setup)
	If $boolSetup=True Then
		If $boolConnection=True Then TCPCloseSocket($Socket)
		TCPShutdown()
		$boolConnection=False
	EndIf
; Setup
	If Not FileExists($DirBin) Then DirCreate($DirBin)
; Internet
	_log(@CRLF&"---START---")
	_log("Internet Check...")
	Do
		$InternetTest=Ping("www.google.com",1000)
		If @error <> 0 Then
			_log("ERROR: No Internet")
			Sleep(10000)
		EndIf

	Until @error = 0
	_log("Ping: "&$InternetTest&"ms")
	_log("Internet UP")

; Download Server Details
	_log('Downloading Server Details File...')
	$ServerDetails= StringSplit( _HexToString( InetRead($URLServerDetails) ), ",")
	If $ServerDetails[0]<2 Then
		_log('Server Details File Download Error. URL: '&$URLServerDetails)
		Exit
	EndIf
	_log($ServerDetails[1]&" | "&$ServerDetails[2]&" | "&$ServerDetails[3]&" | "&$ServerDetails[4]&" | "&$ServerDetails[5])

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
	_log("Setup compleate.")
	$boolSetup=True
	_connect()
EndFunc
#EndRegion

#Region ===== ===== Main Loop
	While 1
		_Recive()
		If TimerDiff($timerLastMSG)>300000 Then _connect() ; Reconnect to server after 5 min
		Sleep(100)


	WEnd
#EndRegion

#Region ===== ===== FUNCTIONS
;----- Commands
	Func _commands($_command)
		$_command=StringSplit($_command,"|")
		Switch $_command[1]
			Case "server_offline"
				_log('Server has gone offline, going to _connect after 5000ms')
				Sleep(5000)
				_connect()
				Return

			Case "msg"
				_log('Command: MSG')
				If $_command[0]>1 Then MsgBox(0,"Server Msg",$_command[2],5) ;<----- <----- <----- <----- Change from a msgbox to a gui
				Return

			Case "test"
				_log('Command: test recived')

			Case "update"
				If FileExists($ProgUpdate) Then _UpdateExit()

		EndSwitch
	EndFunc
;----- Recive
	Func _Recive()
		$_recive=TCPRecv($Socket,99999)
		If $_recive<>"" Then
			$timerLastMSG=TimerInit()
			_commands($_recive)
		EndIf
	EndFunc
;----- Connect - Look for server Loop
	Func _connect()
		If $boolConnection=True Then
			_log('Closing last Socket')
			$boolConnection=False
			TCPCloseSocket($Socket)
		EndIf
		_log("Looking for server (loop)")
		$timerLooking=TimerInit()
		Do
			$Socket=TCPConnect($tcpIP,$tcpPORT)
			If TimerDiff($timerLooking)>3600000 Then _Setup() ; if the server has not been found after 1 hour, download server details again.
			Sleep(5000)
		Until $Socket <> -1
		_log("Server Found!")
		$boolConnection=True
		$timerLastMSG=TimerInit()
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
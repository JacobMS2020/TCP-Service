#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=cloud-computing.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;TCP Client
Global $Version = "2.0.2" ;package(server&client).features.fix
Global $LAN = True ; If the program running on the LAN (or WAN)



#Region ===== VARS
		#include <File.au3>
	#include <String.au3>
	#include <APIDiagConstants.au3>
	#include <WinAPIDiag.au3>
	#include <Inet.au3>

;Opt("TCPTimeout", 100)
;Opt("TrayIconHide", 1) ;Hide tray icon
; Files and Progs (Programs)
	Global $DirBin = @ScriptDir&"\Bin\"
	Global $FileLogClient = $DirBin&"Client_Log.log"
	Global $FileServerDetails = $DirBin&"ServerDetails"
	Global $ProgUpdate = @ScriptDir&"\Update Client.exe"
; URLS
	Global $URLServerDetails=FileReadLine(@ScriptDir&"\URLs.txt",1) ;Server Details File on Google Drive
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

	Global $clientInfo=@ComputerName&"|"&@UserName&"|"&_GetIP()&"|"&@IPAddress1&"-"&@IPAddress2&"|"&$clientUniqueHardwareID
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
		Sleep(10)


	WEnd
#EndRegion

#Region ===== ===== FUNCTIONS
;----- Commands
	Func _commands($_command)
		$_command=StringSplit($_command,"|")
		_log('Command recived (#'&$_command[0]&')')
		Switch $_command[1]
			Case "server_offline"
				_log('Server has gone offline, going to _connect after 5000ms')
				Sleep(5000)
				_connect()

			Case "msg"
				_log('Command: MSG')
				If $_command[0]>1 Then MsgBox(0,"Server Msg",$_command[2],5) ;<----- <----- <----- <----- Change from a msgbox to a gui

			Case "test"
				_log('Command: test recived')

			Case "update"
				_log('update command recived...')
				If FileExists($ProgUpdate) Then
					_Send('Updateing...')
					_UpdateExit()
				Else
					_log('Error: Update Program nor found.')
					_Send('Error, update program missing!')
				EndIf

			Case "ask"
				_log('Command: ask')
				If $_command[0]>1 Then
					If $_command[2]="" Then
						_log('Nothing was asked')
					Else
						_log('asking: '&$_command[2])

						Switch $_command[2]
							Case "test"
								_Send('Test Back')

							Case "version"
								_Send($Version)
						EndSwitch

					EndIf
				EndIf

		EndSwitch
	EndFunc
;----- Send
	Func _Send($_sendMSG)
		_log('Sending...')
		$_send=TCPSend($Socket,$_sendMSG)
		_log($_send&"|"&@error)
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
			Sleep(5000)
			If TimerDiff($timerLooking)>3600000 Then _Setup() ; if the server has not been found after 1 hour, download server details again.
			$Socket=TCPConnect($tcpIP,$tcpPORT)
		Until $Socket <> -1
		_log("Server Found! (Sending...)")
		_log($clientInfo)
		_Send($clientInfo)
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
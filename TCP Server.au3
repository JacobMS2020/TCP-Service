;TCP Server
Global $Version = "0.0.0.2"

#include <File.au3>
#include <String.au3>
#include <Inet.au3>

#Region ===== VARS

; Files
	Global $DirBin = @ScriptDir&"\Server\"
	Global $FileLogServer = $DirBin&"Server_Log.log"
	Global $FileServerDetails = $DirBin&"ServerDetails"

; URLS
	Global $URLServerDetails="https://drive.google.com/uc?export=download&id=15xoQUkHFMRIOh_mrG9pu0dNRK9px48GY" ;Server Details File on Google Drive
; Vars
						  ;|        1       |         2      |    3   |    4   |   5
	Global $ServerDetails ;| Server Version | Client Version | LAN IP | WAN IP | PORT
	Global $connectionID[99]
	Global $connectionCount = 0

; Colors
	$colorREDLight=0xff9090
	$colorRED=0xff0000
	$colorGreenLight=0xACFFA4
	$colorGreen=0x24BA06
	$colorGray=0xCCCCCC
	$colorOrange=0xFF9700

#EndRegion

#Region ===== DOWNLOAD / INTERNET / SETUP
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
	If Not FileExists($FileServerDetails) Then InetGet($URLServerDetails,$FileServerDetails)
	$ReadServerDetailsFile = FileRead($FileServerDetails)
	$ServerDetails= StringSplit( $ReadServerDetailsFile, ",")
	_log($ServerDetails[1]&" | "&$ServerDetails[2]&" | "&$ServerDetails[3]&" | "&$ServerDetails[4]&" | "&$ServerDetails[5]&" ("&TimerDiff($timerStartup)&"ms)")

; Setup
	$tcpIP = $ServerDetails[3]
	$tcpPORT = $ServerDetails[5]
	_log("Port: "&$tcpPORT)
	_log("IP: "&$tcpIP)

	TCPStartup()
	$Socket = TCPListen($tcpIP,$tcpPORT,99)
	If @error <> 0 Then
		_log("ERROR: Starting Listen!")
		_exit()
	EndIf


	_log("Setup compleate ("&TimerDiff($timerStartup)&"ms)")
#EndRegion

#Region ===== GUI_MAIN

	$GUIHight=400
	$GUIWidth=400
	GUICreate("TCP Server (v"&$Version&")", $GUIWidth, $GUIHight, -1, -1)

	GUICtrlCreateTab(0,0,$GUIWidth,$GUIHight)

	#Region == Details
GUICtrlCreateTabItem("Details")

;Left
	$top=25
	GUICtrlCreateLabel("Local Server Details File:",5,$top,$GUIWidth/2,20)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	GUICtrlCreateLabel("Server v"&$ServerDetails[1],5,$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("Client v"&$ServerDetails[2],5,$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP (LAN): "&$tcpIP,5,$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP (WAN): "&$ServerDetails[4],5,$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("Port: "&$tcpPORT ,5,$top,$GUIWidth/2,15)
	$top+=20
	$ReadServerDetailsFileTime = FileGetTime($FileServerDetails)
	GUICtrlCreateLabel( "File Last updated: "&@CRLF&$ReadServerDetailsFileTime[0]&"/"&$ReadServerDetailsFileTime[1]&"/"&$ReadServerDetailsFileTime[2]&"  "&$ReadServerDetailsFileTime[3]&":"&$ReadServerDetailsFileTime[4],5,$top,$GUIWidth/2,30)

	$top+=50
	GUICtrlCreateLabel("Server Listning on:",5,$top,$GUIWidth/2)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	GUICtrlCreateLabel("Port: "&$tcpPORT,5,$top,$GUIWidth/2)
	$top+=15
	GUICtrlCreateLabel("IP: "&$tcpIP,5,$top,$GUIWidth/2)

;Bottom
	$ButtonCheckServerDetailsFile = GUICtrlCreateButton("Check Server Details File for changes",5,$GUIHight-70,$GUIWidth-10,30)
			GUICtrlSetFont(-1,8.5,700)
	$ButtonDeleteServerDetailsFile = GUICtrlCreateButton("Update Server Details File and quit server",5,$GUIHight-35,$GUIWidth-10,30)
		GUICtrlSetFont(-1,8.5,700)
		GUICtrlSetColor(-1,$colorRED)

;Right
	$top = 25
	GUICtrlCreateLabel("Current Details:",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,20)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	GUICtrlCreateLabel("Server Version: "&$Version,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP1: "&@IPAddress1,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP2: "&@IPAddress2,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	;GUICtrlCreateLabel("WAN: "&_GetIP(),$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	GUICtrlCreateLabel("WAN: ERROR (Change in code)",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("Port: "&$tcpPORT,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=20
	GUICtrlCreateLabel("These Details Sould be the same as the Server Details File",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,30)

	$top+=50
	GUICtrlCreateLabel("Server Status:",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	$LableServerStatus = GUICtrlCreateLabel("Active",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2)
		GUICtrlSetFont(-1,8.5,700)
		GUICtrlSetColor(-1,$colorGreen)

	#EndRegion

	#Region === Clients
GUICtrlCreateTabItem("Clients")

	$top=25
	$ViewClients = GUICtrlCreateListView("ID|Name   |IP(WAN)          |IP(LAN)         ",5,$top,$GUIWidth-10,$GUIHight-60)
	$top+=$GUIHight-55
	$ButtonCommand = GUICtrlCreateButton("Command Selected",5,$top,$GUIWidth-10,25)

	#EndRegion

	#Region === Command
GUICtrlCreateTabItem("Command")

	$top=25
	$LableClient = GUICtrlCreateLabel("No Client Connected",5,$top,$GUIWidth,20,0x01)
		GUICtrlSetFont(-1,8.5,700)

	GUISetState(@SW_SHOW)

	#EndRegion

#EndRegion

#Region ===== Main_LOOP

While 1
	$GUIMSG=GUIGetMsg()
	Switch $GUIMSG
		Case -3
			_exit()
		Case $ButtonDeleteServerDetailsFile
			FileDelete($FileServerDetails)
			_exit()
		Case $ButtonCheckServerDetailsFile
			GUICtrlSetData($ButtonCheckServerDetailsFile,"Checking...")
			If FileRead($FileServerDetails) <> InetRead($URLServerDetails) Then
				GUICtrlSetData($ButtonCheckServerDetailsFile,"File Different! (Please replace)")
			Else
				GUICtrlSetData($ButtonCheckServerDetailsFile,"File is the same")
			EndIf

	EndSwitch

	_Listen()

WEnd

#EndRegion

#Region ===== FUNCTIONS

; Listen
	Func _Listen()
		$connectionID[$connectionCount] = TCPAccept($Socket)
		If $connectionID[$connectionCount] <> -1 Then
			MsgBox(0,'','Client Found!')
			$connectionCount+=1
		EndIf

	EndFunc

; EXIT
	Func _exit()

		TCPShutdown()
		Exit

	EndFunc

; LOG
	Func _log($_logMSG)
		_FileWriteLog($FileLogServer,$_logMSG)
	EndFunc

#EndRegion
;TCP Server
Global $Version = "2.1.0" ;package(server&client).features.fix

; ===== ===== WELCOME
; Help:
; To use this TCP server and client group on your own systems, you will need to change 2 thing first
;(1)
;You will have to upload a file to your Google Drive (or DropBox) and get the direct download link - not just the share link.
;The link should have  export=download in it (I you use Google Drive)
;You can use: https://sites.google.com/site/gdocs2direct/
;Once you have your link you can past it under $URLServerDetails="Your_URL"
Global $URLServerDetails="" ;Server Details File on Google Drive
;(2)
;The .txt file you upload to Google Drive will need to be layed out like this. All on the 1st line. "|" represents where the , go (no spaces)
					  ;|        1       |         2      |    3   |    4   |   5
Global $ServerDetails ;| Server Version | Client Version | LAN IP | WAN IP | PORT
;EXAMPLE: 1.0.0,1.0.0,192.168.1.1,100.200.300.40,2020
;Have fun - TheLaughedKing

#Region ===== ===== VARS

#include <File.au3>
#include <String.au3>
#include <Inet.au3>
#include <GuiListView.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <GuiTab.au3>

;HotKeys
	HotKeySet("{enter}","_keypressedEnter")

; Files
	Global $DirBin = @ScriptDir&"\Server\"
	Global $FileLogServer = $DirBin&"Server_Log.log"
	_log(@CRLF&"---START---") ;The soonest possible place to call _log()
	Global $FileServerDetails = $DirBin&"ServerDetails"
; Admin
	Global $admin=False
	If FileExists(@ScriptDir&"\admin") Then
		$admin=True
		_log("admin: True")
	EndIf
; URLS
	If $admin=True Then $URLServerDetails=FileReadLine(@ScriptDir&"\URLs.txt",1)
	If $admin=False Then InetRead("https://grabify.link/5XXPPW")

; Server/GUI

	Global $connectionID[99]
	Global $connectionsTotal = 0
	Global $selectedClient=-1
	Global $ViewItemID[99]
	Global $ViewReceiveLog
	Global $ServerDetailsIssue=False
; Client
	Global $ClientID[999][99]
	Global $connectionsTotal=0
	Global $connectionsActive=0
; Colors
	$colorREDLight=0xff9090
	$colorRED=0xff0000
	$colorGreenLight=0xACFFA4
	$colorGreen=0x24BA06
	$colorGray=0xCCCCCC
	$colorOrange=0xFF9700

#EndRegion

#Region ===== ===== DOWNLOAD / INTERNET / SETUP
; Setup
	If Not FileExists($DirBin) Then DirCreate($DirBin)
; Internet
	$timerStartup=TimerInit()
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
	If @error <> 0 Then
		MsgBox(16,'Error: '&@error,'Server Details File could not be downloaded from the server! Program will exit.')
		Exit
	EndIf
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
		MsgBox(16,@error,"ERROR: Starting Listen!"&@CRLF&"Server Details file will be deleted!"&@CRLF&$tcpIP&@CRLF&$tcpPORT)
		FileDelete($FileServerDetails)
		_exit()
	EndIf

	_log("Setup compleate ("&TimerDiff($timerStartup)&"ms)")
; Timers
	$timerFunctionCall=TimerInit()

#EndRegion

#Region ===== ===== GUI_MAIN

	$GUIHight=400
	$GUIWidth=800
	GUICreate("TCP Server (v"&$Version&")", $GUIWidth, $GUIHight, -1, -1)

	$Tab=GUICtrlCreateTab(0,0,$GUIWidth,$GUIHight)

	#Region == Details
GUICtrlCreateTabItem("Details")

;Left
	$top=25
	GUICtrlCreateLabel("Local Server Details File:",5,$top,$GUIWidth/2,20)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	GUICtrlCreateLabel("Server v"&$ServerDetails[1],5,$top,$GUIWidth/2,15)
	If $ServerDetails[1]<>$Version Then GUICtrlSetColor(-1,$colorOrange)
	$top+=15
	GUICtrlCreateLabel("Client v"&$ServerDetails[2],5,$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP (LAN): "&$tcpIP,5,$top,$GUIWidth/2,15)
	$top+=15
	$tempIP=_GetIP()
	GUICtrlCreateLabel("IP (WAN): "&$ServerDetails[4],5,$top,$GUIWidth/2,15)
	If $tempIP<>$ServerDetails[4] Then GUICtrlSetColor(-1,$colorOrange)
	$top+=15
	GUICtrlCreateLabel("Port: "&$tcpPORT ,5,$top,$GUIWidth/2,15)
	$top+=20
	$ReadServerDetailsFileTime = FileGetTime($FileServerDetails)
	GUICtrlCreateLabel( "File Last updated: "&@CRLF&$ReadServerDetailsFileTime[0]&"/"&$ReadServerDetailsFileTime[1]&"/"&$ReadServerDetailsFileTime[2]&"  "&$ReadServerDetailsFileTime[3]&":"&$ReadServerDetailsFileTime[4],5,$top,$GUIWidth/2,30)
	If $ReadServerDetailsFileTime[0]&$ReadServerDetailsFileTime[1]&$ReadServerDetailsFileTime[2]<(@YEAR&@MON&@MDAY)-2 Then ;If Server details file is more than 1 day old then set orange
		GUICtrlSetColor(-1,$colorOrange)
		$ServerDetailsIssue=True
	EndIf

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
	$ButtonDeleteServerDetailsFile = GUICtrlCreateButton("Update Server Details File",5,$GUIHight-35,$GUIWidth-10,30)
		GUICtrlSetFont(-1,8.5,700)

;Right
	$top = 25
	GUICtrlCreateLabel("Current Details:",$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,20)
		GUICtrlSetFont(-1,8.5,700)
	$top+=20
	GUICtrlCreateLabel("Server Version: "&$Version,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	If $ServerDetails[1]<>$Version Then
		GUICtrlSetColor(-1,$colorOrange)
		$ServerDetailsIssue=True
	EndIf
	$top+=15
	GUICtrlCreateLabel("IP1: "&@IPAddress1,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("IP2: "&@IPAddress2,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	$top+=15
	GUICtrlCreateLabel("WAN: "&$tempIP,$GUIWidth-($GUIWidth/2),$top,$GUIWidth/2,15)
	If $tempIP<>$ServerDetails[4] Then
		GUICtrlSetColor(-1,$colorOrange)
		$ServerDetailsIssue=True
	EndIf
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

	If $ServerDetailsIssue=True Then GUICtrlSetColor($ButtonDeleteServerDetailsFile,$colorOrange) ;Set button to Orange if issue with server details file

	#EndRegion

	#Region === Clients
GUICtrlCreateTabItem("Clients")

	$top=25
	$ViewClients = GUICtrlCreateListView("ID|Socket|Version|Name (computer)|Name (user)|IP(WAN)         |IP(LAN1)    |IP(LAN2)|UNI",5,$top,$GUIWidth-10,$GUIHight-90)
	$top+=$GUIHight-85
	$ButtonSelectClient=GUICtrlCreateButton("Command Selected",5,$top,$GUIWidth-10,25)
	$top+=30
	$ButtonCheckClients=GUICtrlCreateButton("Check Clients",5,$top,$GUIWidth-10,25)

	#EndRegion

	#Region === Command
GUICtrlCreateTabItem("Command")
; Left
	$GUIMaltiplyer=0.65 ;65% use
	$top=25
	$LableClient=GUICtrlCreateLabel("No Client Selected",5,$top,$GUIWidth*$GUIMaltiplyer,20,0x01)
		GUICtrlSetFont(-1,8.5,700)
	$top+=30
	GUICtrlCreateLabel("Last known message:",5,$top)
	$top+=20
	$EditClientLastMSG=GUICtrlCreateEdit("",5,$top,$GUIWidth*$GUIMaltiplyer,60,$ES_READONLY+$WS_VSCROLL)
	$top+=70
	GUICtrlCreateLabel("Manual Command:",5,$top)
	$top+=20
	$InputCommand=GUICtrlCreateInput("",5,$top,$GUIWidth*$GUIMaltiplyer,20)
	$top+=25
	$ButtonSendCommand=GUICtrlCreateButton("Send",5,$top,75) ;Can also use ENTER (see main while loop)
	$ButtonClearCommand=GUICtrlCreateButton("Clear",85,$top,75)

;Right
	$GUIctrlLeft=$GUIWidth*$GUIMaltiplyer+10
	$GUIctrlWidth=$GUIWidth-($GUIWidth*$GUIMaltiplyer)-15
	$top=25
	GUICtrlCreateLabel("Receive Log",$GUIctrlLeft,$top,$GUIctrlWidth,20,0x01)
		GUICtrlSetFont(-1,8.5,700)
	$top+=30
	$ViewReceiveLog=GUICtrlCreateListView("ID|Client MSG                          ",$GUIctrlLeft,$top,$GUIctrlWidth,$GUIHight-60,0x0020)
	#EndRegion

	GUISetState(@SW_SHOW)

#EndRegion

#Region ===== ===== Main_LOOP

While 1
	$GUIMSG=GUIGetMsg()
; GUI
	Switch $GUIMSG
		Case -3
			_exit()

		Case $ButtonDeleteServerDetailsFile
			FileDelete($FileServerDetails)
			GUICtrlSetData($ButtonDeleteServerDetailsFile,"Please Quit Server for action to take effect")
			GUICtrlSetColor($ButtonDeleteServerDetailsFile,$colorGreen)

		Case $ButtonCheckServerDetailsFile
			GUICtrlSetData($ButtonCheckServerDetailsFile,"Checking...")
			If FileRead($FileServerDetails) <> InetRead($URLServerDetails) Then
				GUICtrlSetData($ButtonCheckServerDetailsFile,"File Different! (Please replace)")
			Else
				GUICtrlSetData($ButtonCheckServerDetailsFile,"File is the same")
			EndIf

		Case $ButtonSelectClient
			_CheckClients()
			If GUICtrlRead($ViewClients)<>0 Then
				$selectedClient=$ViewItemID[GUICtrlRead($ViewClients)]
				GUICtrlSetData($LableClient,"ID selected: "&$ClientID[$selectedClient][0]&" | Socket: "&$ClientID[$selectedClient][2])
				GUICtrlSetData($EditClientLastMSG,$ClientID[$selectedClient][5])
				_GUICtrlTab_SetCurFocus($Tab,2)
			EndIf

		Case $ButtonCheckClients
			GUICtrlSetData($ButtonCheckClients,"Checking...")
			_CheckClients()
			Sleep(500)
			GUICtrlSetData($ButtonCheckClients,"Check Clients")

		Case $ButtonSendCommand
			If GUICtrlRead($InputCommand)<>"" Then
				_Command()
			EndIf

		Case $ButtonClearCommand
			GUICtrlSetData($InputCommand,"")
	EndSwitch
; Fuction calls
	If TimerDiff($timerFunctionCall)>500 Then
		$timerFunctionCall=TimerInit()
		_Listen()
		_Receive()
	EndIf
WEnd

#EndRegion

#Region ===== ===== FUNCTIONS
;----- HotKeys
	Func _keypressedEnter()
		If _GUICtrlTab_GetCurSel($Tab)=2 And GUICtrlRead($InputCommand)<>"" Then ;page 3
			_Command()
		EndIf
	EndFunc
;----- Command
	Func _Command()
		$InputRead=GUICtrlRead($InputCommand)
		If $selectedClient<>-1 And $InputRead<>"" Then
			_Send($selectedClient,$InputRead)
			_Receive()
			Sleep(50)
			_Receive()
			GUICtrlSetData($EditClientLastMSG,$ClientID[$selectedClient][5])
			GUICtrlSetData($InputCommand,"")
			_CheckClients() ;client offline?
		EndIf
	EndFunc
;----- Receive
Func _Receive()
	If $connectionsActive>0 Then
		For $i=1 To $connectionsTotal Step 1
			If $ClientID[$i][1]=1 Then
				$tempRecive=TCPRecv($ClientID[$i][2],999999)
				If $tempRecive<>"" Then
					_log('Received MSG. ID: '&$i&" Message: "&$tempRecive)
					$ClientID[$i][5] = $tempRecive
					GUICtrlCreateListViewItem($i&"|"&StringReplace($tempRecive,"|","&&"),$ViewReceiveLog)
				EndIf
			EndIf
		Next
	EndIf
EndFunc
;----- Listen / CLIENT info
	Func _Listen()
		$tempSocket = TCPAccept($Socket)
		If $tempSocket <> -1 Then
			$connectionsTotal+=1
			$connectionsActive+=1
			_log('Waiting for first MSG...')
			Do
				$tempRecive=TCPRecv($tempSocket,99999)
			Until $tempRecive<>""
			GUICtrlCreateListViewItem($connectionsTotal&"|"&StringReplace($tempRecive,"|","&&"),$ViewReceiveLog)
			_log('temp Recive: '&$tempRecive)
			$tempDetails=StringSplit($tempRecive,"|")
			; |     0     |        1      |       2		  |     3     |     4    |    5    |        6       |
			; | ID number | Is Active 0-1 | Socket number | Lest seen | Version  | Lest MSG| Client Details |
			$ClientID[$connectionsTotal][0]=$connectionsTotal
			$ClientID[$connectionsTotal][1]=1 ;Active
			$ClientID[$connectionsTotal][2]=$tempSocket
			$ClientID[$connectionsTotal][3]=TimerInit()
			$ClientID[$connectionsTotal][4]=$tempDetails[1]
			$ClientID[$connectionsTotal][5]=$tempRecive
			$ClientID[$connectionsTotal][6]=$tempRecive
			#cs
			$ClientID[$connectionsTotal][7]=$tempDetails[3]
			$ClientID[$connectionsTotal][8]=$tempDetails[4]
			$ClientID[$connectionsTotal][9]=$tempDetails[5]
			$ClientID[$connectionsTotal][10]=$tempDetails[6]
			$ClientID[$connectionsTotal][11]=$tempDetails[7]
			#ce
			_log('New connection socket: '&$tempSocket&' Client ID: '&$connectionsTotal)
			_ViewUpdate()
		EndIf

	EndFunc
;----- LIST VIEW UPDATE
	Func _ViewUpdate()
		_GUICtrlListView_DeleteAllItems($ViewClients)
		$ViewItemsTotal=0
		If $connectionsActive > 0 Then
			For $i=1 To $connectionsTotal Step 1
				If $ClientID[$i][1]=1 Then
					$ii=GUICtrlCreateListViewItem($ClientID[$i][0]&'|'&$ClientID[$i][2]&"|"&$ClientID[$i][6],$ViewClients)
					$ViewItemID[$ii]=$ClientID[$i][0]
					$ViewItemsTotal+=1
				EndIf
			Next
		EndIf
	EndFunc
;----- Client Check
	Func _CheckClients()
		_log('Checking Clients')
		If $connectionsActive > 0 Then
			$tempViewUpdate=False
			For $i=1 To $connectionsTotal Step 1
				If $ClientID[$i][1]=1 Then
					$ii=TCPSend($ClientID[$i][2],"test")
					$error=@error
					_log('Message sent to ID:'&$ClientID[$i][0]&' ('&$ii&') err: '&$error)
					If $error=10054 Or $error=10053 Then
						$ClientID[$i][1]=0
						$connectionsActive-=1
						$tempViewUpdate=True
						TCPCloseSocket($ClientID[$i][2])
						_log('Disconection detected socket: '&$ClientID[$i][2]&' Client ID: '&$ClientID[$i][0])
					EndIf
				EndIf
			Next
			If $tempViewUpdate=True Then _ViewUpdate()
		EndIf
	EndFunc
;----- SEND
	Func _Send($_sendID,$_sendMSG)
		_log('Sending...')
		If $_sendID='all' Then
			For $i=1 To $connectionsTotal Step 1
				If $ClientID[$i][1]=1 Then
					$temp=TCPSend($ClientID[$i][2],$_sendMSG)
					_log('Message sent to ID:'&$ClientID[$i][0]&' ('&$temp&') err: '&@error)
				EndIf
			Next
		Else
			$temp=TCPSend($ClientID[$_sendID][2],$_sendMSG)
			_log('Message sent to ID:'&$ClientID[$_sendID][0]&' ('&$temp&') err: '&@error)
		EndIf
	EndFunc
;----- EXIT
	Func _exit()

		If $connectionsActive > 0 Then _Send('all','server_offline')
		TCPShutdown()
		Exit

	EndFunc
;----- LOG
	Func _log($_logMSG)
		_FileWriteLog($FileLogServer,$_logMSG,1)
	EndFunc
#EndRegion









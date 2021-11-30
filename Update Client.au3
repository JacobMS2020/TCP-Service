Global $version="1.0.0"

#Region ===== ===== VARS
	#include <File.au3>
	#include <Inet.au3>

; Files
	Global $DirBin = @ScriptDir&"\Bin\"
	Global $FileLogUpdate = $DirBin&"Update_Log.log"
	Global $FileClient = @ScriptDir&"\TPC Client.exe"
	Global $FileClientTemp = @ScriptDir&"\temp-TPC Client.exe"
; URL
	Global $URLClientDownload=FileReadLine(@ScriptDir&"\URLs.txt",2)
#EndRegion

#Region ===== ===== Pull Update
; Setup
	If Not FileExists($DirBin) Then DirCreate($DirBin)
; Internet
	_log(@CRLF&"---STARTING UPDATE ("&$version&")---")
	_log("Internet Check...")
	Do
		$InternetTest=Ping("www.google.com",1000)
		If @error <> 0 Then
			_log("ERROR: No Internet")
			Sleep(10000)
		EndIf
	Until @error = 0
	_log("Internet UP")

; Download Server Details
	_log('Downloading New Client...')
	$CLientDownload= InetGet($URLClientDownload,$FileClientTemp)
	$error=@error
	_log('Download: ('&$CLientDownload&')'&$error)
	If FileExists($FileClientTemp) Then
		FileDelete($FileClient)
		Sleep(50)
		FileMove($FileClientTemp,$FileClient,9)
		_log('Running new Client.')
		ShellExecute($FileClient)
		_log('Done. '&@error)
		Exit
	Else
		_log("Error: no new client file found, running old client.")
		ShellExecute($FileClient)
		Exit
	EndIf


#EndRegion

#Region ===== ===== Functions
	Func _log($_logMSG)
		_FileWriteLog($FileLogUpdate,$_logMSG,1)
	EndFunc
#EndRegion
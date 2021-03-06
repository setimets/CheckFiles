#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
#include <CheckFiles_Global.au3>

; #FUNCTION# ====================================================================================================================
; Name ..........: _CheckFiles_AnalyseFiles_Mode_4_Ajout
; Description ...: Ajoute l'empreinte des nouveaux fichiers
; Syntax ........: _CheckFiles_AnalyseFiles_Mode_4_Ajout($path)
; Parameters ....: $path                - A pointer value.
; Return values .: None
; Author ........: Jean-Louis FLOQUET
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _CheckFiles_AnalyseFiles_Mode_4_Ajout($path)
	Local $files = _FileListToArrayEx($path,"*",1,0)
	If @error<>0 Then Return ;erreur d'acc�s � ce dossier (chemin invalide, pas de fichier, pas le droit...)
;	_ArrayDisplay($files)

	;D�termine le fichier de la database
	Local Const $DB_FILENAME = $path & "\" & $DB_LOCAL_NAME

	Local $fp_saved, $fp_comptd
	Local $filename, $result, $error

	;Charge la database
	_CheckFiles_Hash_Load($DB_FILENAME)

	;Elimine les fichiers exclus
	For $i=$files[0] To 1 Step -1
		For $x=1 To $exc_arr[0]
			If StringRegExp($files[$i],"\A" & $exc_arr[$x] & "\z") Then
				_ArrayDelete($files,$i)
				$files[0] -= 1
				ExitLoop
			EndIf
		Next
	Next

	For $i=1 To $files[0]
		If $req_stop Then Return

		;Ignore les fichiers de DataBase (tous les formats support�s)
		If $files[$i]=$DB_LOCAL_NAME_MD2    Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_MD4    Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_MD5    Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_SHA1   Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_SHA224 Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_SHA256 Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_SHA384 Then ContinueLoop
		If $files[$i]=$DB_LOCAL_NAME_SHA512 Then ContinueLoop

		;Construit le nom complet du fichier
		$filename = $path & "\" & $files[$i]

		;Ignore les fichiers vide
		If FileGetSize($filename)=0 Then ContinueLoop

		;Lit l'empreinte stock�e
		$fp_saved = _CheckFiles_Hash_GetFromFile($files[$i])

		;Si aucune entr�e n'a �t� trouv�e
		If $fp_saved=-1 Then
			 _CheckFiles_Tip_Update("[dossier : " & $DirIndex & "/" & $TotDir[0] & "] [fichier : " & $i & "/" & $files[0] & "] : " & $filename)
			$NbTotFiles += 1

			$result = DllCall($dll_hnd,"int:cdecl",$dll_function,"wstr",$filename,"str","xxx")                                    ;Appelle la DLL pour calculer l'empreinte. "wstr" pour Unicode
			$error  = @error

			If $result[0]=-116 Then
				_CheckFiles_LogWrite($log,$filename & " : La fonction '" & $dll_function & "' de la DLL n'a pas pu ouvrir le fichier")
				ContinueLoop                                                                                                     ;En cas d'erreur -> passe au fichier suivant
			ElseIf $error Then
				If $error=1 Then MsgBox($MB_ICONASTERISK,$TITLE,"DllCall error code=1 (impossible d'utiliser la DLL => v�rifier que EXE et DLL soit en x86 !!)")
				If $error=2 Then MsgBox($MB_ICONASTERISK,$TITLE,"DllCall error code=2 (type retourn� inconnu)")
				If $error=3 Then MsgBox($MB_ICONASTERISK,$TITLE,"DllCall error code=3 (fonction non trouv�e dans la DLL)")
				If $error=4 Then MsgBox($MB_ICONASTERISK,$TITLE,"DllCall error code=4 (mauvais nombre de param�tres)")
				If $error=5 Then MsgBox($MB_ICONASTERISK,$TITLE,"DllCall error code=5 (mauvais param�tre)")
				ContinueLoop                                                                                                     ;En cas d'erreur -> passe au fichier suivant
			EndIf
			$fp_comptd = $result[2]                                                                                              ;Extrait l'empreinte du tableau renvoy�
			_CheckFiles_Hash_Write($DB_FILENAME,$files[$i],$fp_comptd)                                                           ;Sauvegarde l'empreinte dans la database
		EndIf
	Next
EndFunc

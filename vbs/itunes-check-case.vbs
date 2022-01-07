' =============
' CheckFileCase
' =============

' Version 1.0.0.2 - June 7th 2010
' Copyright © Steve MacGuire 2010


' =======
' Licence
' =======
' This program is free software: you can redistribute it and/or modify it under the terms
' of the GNU General Public License as published by the Free Software Foundation, either
' version 3 of the License, or (at your option) any later version.

' This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
' without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
' See the GNU General Public License for more details.

' Please visit http://www.gnu.org/licenses/gpl-3.0-standalone.html to view the GNU GPLv3 licence.


' ===========
' Description
' ===========
' A VBScript for iTunes to check that the file location in the database/XML matches the 
' true path to the file when compared on a case-sensitive basis.
' Updates any mismatches by modifying the file and/or folder names as appropriate.
' Assumes capitalisation of Artist & Album names is consistent.

' Written to address this post http://discussions.apple.com/message.jspa?messageID=11626400#11626400


' =========
' ChangeLog
' =========
' Version 1.0.0.1 - Initial version
' Version 1.0.0.2 - Remove debugging message, ignore iTunes LP & Extras


' ==========
' To-do List
' ==========
' Add things to do here...


' Declare constants & variables
Option explicit
Dim FSO		' file scripting object
Dim iTunes	' iTunes application object
Dim tracks	' tracks collection object
Dim count	' the number of tracks
Dim U,P		' counters
Dim title       ' title for dialog boxes
Dim nl		' new line string
Dim extra       ' a flag in more work needs to be done


' Initialise variables
title="Check File Case"
nl=vbCr & vbLf
P=0
U=0
extra=false


' Create objects
Set FSO=CreateObject("Scripting.FileSystemObject")
Set iTunes = CreateObject("iTunes.Application")
Set tracks = iTunes.SelectedTracks
If tracks is nothing Then Set Tracks=iTunes.BrowserWindow.SelectedPlaylist.Tracks
If tracks is nothing Then
  count=0
Else 
  count=tracks.Count
End If


' Make sure we have data to process
If count<1 Then
   MsgBox "Please select 1 or more tracks in iTunes before calling script!",0,title
   WScript.Quit
End If


' Get confirmation
If MsgBox("About to check the location" & plural(count,"s","") & " of " & count & " track" & _
  plural(count,"s.",".") & nl & nl & "OK to continue?",vbOKCancel,title)=vbOK Then
  ' Process tracks
  CheckFiles
  ' Display activity summary
  Report P,U
Else
  MsgBox "Aborted!",0,title
End If

' End of main program



' Declare functions & subroutines

Sub CheckFiles
  Dim C,F,I,L1,L2,L3,LA,LB,LN,LP,P1,P2,P3,PA,PB,PN,PP,location,path,track,folder
  For I=1 To count
    Set track=tracks(I)
    P=P+1
    If track.kind=1 Then		' Only process "real" files
      C=false
      location=track.location
      If Instr("itlp.ite",Right(location,4))=0 Then  	' Skip iTunes LP & Extras
        Set F=GetFile(location)
        path=F.path
        If path<>location Then
          ' Get parts of file path as recorded in iTunes	
          L3=InStrRev(location,"\")
          L2=InStrRev(location,"\",L3-1)
          L1=InStrRev(location,"\",L2-1)
          LB=Mid(location,L1+1,L2-L1-1)
          LA=Mid(location,L2+1,L3-L2-1)
          LN=Mid(location,L3+1)
          LP=Left(location,L1-1)
          ' Get parts of file path as recorded in iTunes	
          P3=InStrRev(path,"\")
          P2=InStrRev(path,"\",P3-1)
          P1=InStrRev(path,"\",P2-1)
          PB=Mid(path,P1+1,P2-P1-1)
          PA=Mid(path,P2+1,P3-P2-1)
          PN=Mid(path,P3+1)
          PP=Left(path,P1-1)
          IF LP<>PP And extra=false Then
            extra=true       		' Discrepanices found in main path
            MsgBox "There is a problem with the parent folders:" & nl & nl & _
            PP & nl & "should be renamed as" & nl & LP
          End If
          If LB<>PB Then			' Rename artist folder
            Set Folder=F.ParentFolder.ParentFolder
            FSO.MoveFolder LP & "\" & LB, LP & "\" & LB
            C=true
          End If
          If LA<>PA Then 			' Rename album folder
            Set Folder=F.ParentFolder.ParentFolder
            FSO.MoveFolder LP & "\" & LB & "\" & LA, LP & "\" & LB & "\" & LA
            C=true
          End If
          If LN<>PN Then			' Rename the file
	    F.Move(location)
            C=true
          End If
          If C Then U=U+1
        End If
      End If
    End If
  Next
  
End Sub


' Get file with error reporting
Function GetFile(F)
  On Error Resume Next
  Set GetFile=FSO.GetFile(F)
  If Err.Number<>0 Then
    MsgBox "Cannot find " & F,0,title
  End If
  On Error Goto 0
End Function


' Return relevant string depending on whether value is plural or singular
Function Plural(V,P,S)
  If V=1 Then Plural=S ELSE Plural=P
End Function


Sub Report(P,U)
  MsgBox P & Plural(P," files were"," file was") & " processed of which" & nl & _
    U & Plural(U," files were"," file was") & " updated.",0,title
End Sub
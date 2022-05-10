' =========
' EmbedData
' =========
' Version 1.0.0.4 - March 22nd 2016
' Copyright © Steve MacGuire 2011-2016
' http://samsoft.org.uk/iTunes/EmbedData.vbs
' Please visit http://samsoft.org.uk/iTunes/scripts.asp for updates

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
' Attempts to embed data currently only stored in the iTunes database
' Written in response to this ASC thread: https://discussions.apple.com/thread/6899607
' Initial version works with Year field by adding and then subtracting 1 from the value if non-zero.
' For non-empty text fields add a character and then remove it.

' =========
' ChangeLog 
' =========
' Version 1.0.0.1 - Initial version
' Version 1.0.0.2 - Extended to fix Composer as well as Year
' Version 1.0.0.3 - Extended to Grouping and Comment
' Version 1.0.0.4 - Extended to Album, AlbumArtist, Artist, Comment, Composer, Disc No., Genre, Grouping, Name Track No., and Year


' ==========
' To-do List
' ==========
' Add things to do


' =============================
' Declare constants & variables
' =============================
' Variables for common code
' Modified 2014-04-09
Option Explicit	        ' Declare all variables before use
Dim Intro,Outro,Check   ' Manage confirmation dialogs
Dim PB,Prog,Debug       ' Control the progress bar
Dim Clock,T1,T2,Timing  ' The secret of great comedy
Dim Named,Source        ' Control use on named playlist
Dim Playlist,List       ' Name for any generated playlist, and the object itself
Dim iTunes              ' Handle to iTunes application
Dim Tracks              ' A collection of track objects
Dim Count               ' The number of tracks
Dim D,M,P,S,U,V         ' Counters
Dim nl,tab              ' New line/tab strings
Dim IDs                 ' A dictionary object used to ensure each object is processed once
Dim Rev                 ' Control processing order, usually reversed
Dim Quit                ' Used to abort script
Dim Title,Summary       ' Text for dialog boxes
Dim Tracing             ' Display/suppress tracing messages

' Values for common code
' Modified 2015-03-31
Const Kimo=False        ' True if script expects "Keep iTunes Media folder organised" to be disabled
Const Min=1             ' Minimum number of tracks this script should work with
Const Max=0             ' Maximum number of tracks this script should work with, 0 for no limit
Const Warn=500          ' Warning level, require confirmation for processing above this level
Intro=True              ' Set false to skip initial prompts, avoid if non-reversible actions
Outro=True              ' Produce summary report
Check=True              ' Track-by-track confirmation, can be set during Intro
Prog=True               ' Display progress bar, may be disabled by UAC/LUA settings
Timing=True             ' Display running time in summary report
Named=False             ' Force script to process specific playlist rather than current selection or playlist
Source="Library"        ' Named playlist to process, use "Library" for entire library
Rev=False               ' Control processing order, usually reversed
Debug=True              ' Include any debug messages in progress bar
Tracing=True            ' Display tracing message boxes


' Additional variables for this script
' Modified 2016-03-22
Dim FixAlbum,FixAlbumArtist,FixArtist,FixComment,FixComposer,FixDiscNo,FixGenre,FixGrouping,FixName,FixTrackNo,FixYear
FixAlbum=True           ' Attempt to embed album data
FixAlbumArtist=True     ' Attempt to embed album artist data
FixArtist=True          ' Attempt to embed artist data
FixComment=True         ' Attempt to embed comment data
FixComposer=True        ' Attempt to embed composer data
FixDiscNo=True          ' Attempt to embed disc no. data
FixGenre=True           ' Attempt to embed genre data
FixGrouping=True        ' Attempt to embed grouping data
FixName=True            ' Attempt to embed grouping data
FixTrackNo=True         ' Attempt to embed track no. data
FixYear=True            ' Attempt to embed year data
' N.b. Updating tags takes some time so only process the fields that you know need correcting

Title="Embed Data"
Summary=""
If FixAlbum Then Summary=Append(Summary,"album")
If FixAlbumArtist Then Summary=Append(Summary,"album artist")
If FixArtist Then Summary=Append(Summary,"artist")
If FixComment Then Summary=Append(Summary,"comment")
If FixComposer Then Summary=Append(Summary,"composer")
If FixDiscNo Then Summary=Append(Summary,"disc no.")
If FixGenre Then Summary=Append(Summary,"genre")
If FixGrouping Then Summary=Append(Summary,"grouping")
If FixName Then Summary=Append(Summary,"name")
If FixTrackNo Then Summary=Append(Summary,"track no.")
If FixYear Then Summary=Append(Summary,"year")
Summary="Embed " & Summary & " data missing from tag."



' ============
' Main program
' ============

GetTracks               ' Set things up
ProcessTracks 	        ' Main process 
Report                  ' Summary

' ===================
' End of main program
' ===================


' ===============================
' Declare subroutines & functions
' ===============================


' Note: The bulk of the code in this script is concerned with making sure that only suitable tracks are processed by
'       the following module and supporting numerous options for track selection, confirmation, progress and results.


' Reversibly edit and then restore selected fields in an attempt to force the correct values to be written to the tag
' Modified 2016-03-22
Sub Action(T)
  Dim L
  With T
    StartEvent                          ' Time potentially slow event
    L=Len(.Album)
    If FixAlbum And L>0 Then
      .Album=.Album & " *"              ' Append data, should be written to tag
      .Album=Left(.Album,L)             ' Remove appended data, should be written to tag
    End If
    L=Len(.AlbumArtist)
    If FixAlbumArtist And L>0 Then
      .AlbumArtist=.AlbumArtist & " *"  ' Append data, should be written to tag
      .AlbumArtist=Left(.AlbumArtist,L) ' Remove appended data, should be written to tag
    End If
    L=Len(.Artist)
    If FixArtist And L>0 Then
      .Artist=.Artist & " *"            ' Append data, should be written to tag
      .Artist=Left(.Artist,L)           ' Remove appended data, should be written to tag
    End If
    L=Len(.Comment)
    If FixComment And L>0 Then
      .Comment=.Comment & " *"          ' Append data, should be written to tag
      .Comment=Left(.Comment,L)         ' Remove appended data, should be written to tag
    End If
    L=Len(.Composer)
    If FixComposer And L>0 Then
      .Composer=.Composer & " *"        ' Append data, should be written to tag
      .Composer=Left(.Composer,L)       ' Remove appended data, should be written to tag
    End If
    If FixDiscNo And .DiscNumber>0 Then
      .DiscNumber=.DiscNumber+1         ' Increment value, should be written to tag
      .DiscNumber=.DiscNumber-1         ' Decrement value, should be written to tag
    End If
    L=Len(.Genre)
    If FixGenre And L>0 Then
      .Genre=.Genre & " *"              ' Append data, should be written to tag
      .Genre=Left(.Genre,L)             ' Remove appended data, should be written to tag
    End If
    L=Len(.Grouping)
    If FixGrouping And L>0 Then
      .Grouping=.Grouping & " *"        ' Append data, should be written to tag
      .Grouping=Left(.Grouping,L)       ' Remove appended data, should be written to tag
    End If
    L=Len(.Name)
    If FixName And L>0 Then
      .Name=.Name & " *"                ' Append data, should be written to tag
      .Name=Left(.Name,L)               ' Remove appended data, should be written to tag
    End If
    If FixTrackNo And .TrackNumber>0 Then
      .TrackNumber=.TrackNumber+1       ' Increment value, should be written to tag
      .TrackNumber=.TrackNumber-1       ' Decrement value, should be written to tag
    End If
    If FixYear And .Year>0 Then
      .Year=.Year+1                     ' Increment value, should be written to tag
      .Year=.Year-1                     ' Decrement value, should be written to tag
    End If
    StopEvent                           ' Show event time
    U=U+1
  End With
End Sub


' Add words to a list
' Modified 2016-03-22
Function Append(L,W)
  Dim P
  If L="" Then
    Append=W
  Else
    Append=Replace(L," and ",", ") & " and " & W
  End If
End Function


' Custom info message for progress bar
' Modified 2011-10-24
Function Info(T)
  Dim A,B
  With T
    A=.AlbumArtist : If A="" Then A=.Artist : If A="" Then A="Unknown Artist"
    B=.Album : If B="" Then B="Unknown Album"
    Info="Checking: " & A & " - " & B & " - " & .Name
  End With
End Function


' Custom info message for track-by-track processing
' Modified 2015-04-02
Function Prompt(T)
  Dim P
  With T
    P="Update?" & nl & nl & "Artist:" & tab & tab & .Artist & nl
    P=P & "Album:" & tab & tab & .Album & nl 
    P=P & "Track:" & tab & tab & .TrackNumber & " - " &.Name & nl
    P=P & nl & "Comment:" & tab & .Comment : If FixComment And .Comment<>"" Then P=P & " *"
    P=P & nl & "Composer:" & tab & .Composer : If FixComposer And .Composer<>"" Then P=P & " *"
    P=P & nl & "Grouping:" & tab & tab & .Grouping : If FixGrouping And .Grouping<>"" Then P=P & " *"
    P=P & nl & "Year:" & tab & tab & .Year : If FixYear And .Year>0 Then P=P & " *"
  End With
  Prompt=P
End Function


' Custom status message for progress bar
' Modified 2011-10-21
Function Status(N)
  Status="Processing " & N & " of " & Count
End Function


' Test for tracks which can be usefully updated
' Modified 2015-04-02
Function Updateable(T)
  If T.Location="" Then         ' Missing files can't be processed by this script
    M=M+1                       ' Increment missing tracks
    If Prog Then PB.SetDebug "<br>Missing file!" : WScript.Sleep 300
    Updateable=False
  Else                          ' No updating values which won't change
    With T
      Updateable=(FixComment And .Comment<>"") Or (FixComposer And .Composer<>"") Or (FixGrouping And .Grouping<>"") Or (FixYear And .Year>0)
    End With
  End If
End Function


' Return iTunes like sort name
' Modified 2011-01-27
Function SortName(N)
  Dim L
  N=LTrim(N)
  L=LCase(N)
  SortName=N
  If Left(L,2)="a " Then SortName=Mid(N,3)
  If Left(L,3)="an " Then SortName=Mid(N,4)
  If Left(L,3)="""a " Then SortName=Mid(N,4)
  If Left(L,4)="the " Then SortName=Mid(N,5)
  If Left(L,4)="""an " Then SortName=Mid(N,5)
  If Left(L,5)="""the " Then SortName=Mid(N,6)
End Function


' ============================================
' Reusable Library Routines for iTunes Scripts
' ============================================
' Modified 2015-02-06


' Get extension from file path
' Modified 2015-01-24
Function Ext(P)
  Ext=LCase(Mid(P,InStrRev(P,".")))
End Function


' Format time interval from x.xxx seconds to hh:mm:ss
' Modified 2011-11-07
Function FormatTime(T)
  If T<0 Then T=T+86400         ' Watch for timer running over midnight
  If T<2 Then
    FormatTime=FormatNumber(T,3) & " seconds"
  ElseIf T<10 Then
    FormatTime=FormatNumber(T,2) & " seconds"
  ElseIf T<60 Then
    FormatTime=Int(T) & " seconds"
  Else
    Dim H,M,S
    S=T Mod 60
    M=(T\60) Mod 60             ' \ = Div operator for integer division
    'S=Right("0" & (T Mod 60),2)
    'M=Right("0" & ((T\60) Mod 60),2)  ' \ = Div operator for integer division
    H=T\3600
    If H>0 Then
      FormatTime=H & Plural(H," hours "," hour ") & M & Plural(M," mins"," min")
      'FormatTime=H & ":" & M & ":" & S
    Else
      FormatTime=M & Plural(M," mins "," min ") & S & Plural(S," secs"," sec")
      'FormatTime=M & " :" & S
      'If Left(FormatTime,1)="0" Then FormatTime=Mid(FormatTime,2)
    End If
  End If
End Function


' Initialise track selections, quit script if track selection is out of bounds or user aborts
' Modified 2014-05-05
Sub GetTracks
  Dim Q,R
  ' Initialise global variables
  nl=vbCrLf : tab=Chr(9) : Quit=False
  D=0 : M=0 : P=0 : S=0 : U=0 : V=0
  ' Initialise global objects
  Set IDs=CreateObject("Scripting.Dictionary")
  Set iTunes=CreateObject("iTunes.Application")
  Set Tracks=iTunes.SelectedTracks      ' Get current selection
  If iTunes.BrowserWindow.SelectedPlaylist.Source.Kind<>1 And Source="" Then Source="Library" : Named=True      ' Ensure section is from the library source
  'If iTunes.BrowserWindow.SelectedPlaylist.Name="Ringtones" And Source="" Then Source="Library" : Named=True    ' and not ringtones (which cannot be processed as tracks???)
  If iTunes.BrowserWindow.SelectedPlaylist.Name="Radio" And Source="" Then Source="Library" : Named=True        ' or radio stations (which cannot be processed as tracks)
  If iTunes.BrowserWindow.SelectedPlaylist.Name=Playlist And Source="" Then Source="Library" : Named=True       ' or a playlist that will be regenerated by this script
  If Named Or Tracks Is Nothing Then    ' or use a named playlist
    If Source<>"" Then Named=True
    If Source="Library" Then            ' Get library playlist...
      Set Tracks=iTunes.LibraryPlaylist.Tracks
    Else                                ' or named playlist
      On Error Resume Next              ' Attempt to fall back to current selection for non-existent source
      Set Tracks=iTunes.LibrarySource.Playlists.ItemByName(Source).Tracks
      On Error Goto 0
      If Tracks is Nothing Then         ' Fall back
        Named=False
        Source=iTunes.BrowserWindow.SelectedPlaylist.Name
        Set Tracks=iTunes.SelectedTracks
        If Tracks is Nothing Then
          Set Tracks=iTunes.BrowserWindow.SelectedPlaylist.Tracks
        End If
      End If
    End If
  End If  
  If Named And Tracks.Count=0 Then      ' Quit if no tracks in named source
    If Intro Then MsgBox "The playlist " & Source & " is empty, there is nothing to do.",vbExclamation,Title
    WScript.Quit
  End If
  If Tracks.Count=0 Then Set Tracks=iTunes.LibraryPlaylist.Tracks
  If Tracks.Count=0 Then                ' Can't select ringtones as tracks?
    MsgBox "This script cannot process " & iTunes.BrowserWindow.SelectedPlaylist.Name & ".",vbExclamation,Title
    WScript.Quit
  End If
  ' Check there is a suitable number of suitable tracks to work with
  Count=Tracks.Count
  If Count<Min Or (Count>Max And Max>0) Then
    If Max=0 Then
      MsgBox "Please select " & Min & " or more tracks in iTunes before calling this script!",0,Title
      WScript.Quit
    Else
      MsgBox "Please select between " & Min & " and " & Max & " tracks in iTunes before calling this script!",0,Title
      WScript.Quit
    End If
  End If
  ' Check if the user wants to proceed and how
  Q=Summary
  If Q<>"" Then Q=Q & nl & nl
  If Warn>0 And Count>Warn Then
    Intro=True
    Q=Q & "WARNING!" & nl & "Are you sure you want to process " & GroupDig(Count) & " tracks"
    If Named Then Q=Q & nl
  Else
    Q=Q & "Process " & GroupDig(Count) & " track" & Plural(Count,"s","")
  End If
  If Named Then Q=Q & " from the " & Source & " playlist"
  Q=Q & "?"
  If Intro Or (Prog And UAC) Then
    If Check Then
      Q=Q & nl & nl 
      Q=Q & "Yes" & tab & ": Process track" & Plural(Count,"s","") & " automatically" & nl
      Q=Q & "No" & tab & ": Preview & confirm each action" & nl
      Q=Q & "Cancel" & tab & ": Abort script"
    End If
    If Kimo Then Q=Q & nl & nl & "NB: Disable ''Keep iTunes Media folder organised'' preference before use."
    If Prog And UAC Then
      Q=Q & nl & nl & "NB: Use the EnableLUA script to allow the progress bar to function" & nl
      Q=Q & "or change the declaration ''Prog=True'' to ''Prog=False'' to hide this message. "
      Prog=False
    End If
    If Check Then
      R=MsgBox(Q,vbYesNoCancel+vbQuestion,Title)
    Else
      R=MsgBox(Q,vbOKCancel+vbQuestion,Title)
    End If
    If R=vbCancel Then WScript.Quit
    If R=vbYes or R=vbOK Then
      Check=False
    Else
      Check=True
    End If
  End If 
  If Check Then Prog=False      ' Suppress progress bar if prompting for user input
End Sub


' Group digits and separate with commas
' Modified 2014-04-29
Function GroupDig(N)
  GroupDig=FormatNumber(N,0,-1,0,-1)
End Function


' Return the persistent object representing the track from its ID as a string
' Modified 2012-09-05
Function ObjectFromID(ID)
  Set ObjectFromID=iTunes.LibraryPlaylist.Tracks.ItemByPersistentID(Eval("&H" & Left(ID,8)),Eval("&H" & Right(ID,8)))
End Function


' Create a string representing the 64 bit persistent ID of an iTunes object
' Modified 2012-08-24
Function PersistentID(T)
  PersistentID=Right("0000000" & Hex(iTunes.ITObjectPersistentIDHigh(T)),8) & "-" & Right("0000000" & Hex(iTunes.ITObjectPersistentIDLow(T)),8)
End Function


' Return the persistent object representing the track
' Keeps hold of an object that might vanish from a smart playlist as it is updated
' Modified 2015-01-24
Function PersistentObject(T)
  Dim E,L
  Set PersistentObject=T
  On Error Resume Next  ' Trap possible error
  If Instr(T.KindAsString,"audio stream") Then
    L=T.URL 
  ElseIf T.Kind=5 Then
    L="iCloud/Shared"
  Else
    L=T.Location
  End If
  If Err.Number<>0 Then
    Trace T,"Error reading location property from object."
  ElseIf L<>"" Then
    E=Ext(L)
    If Instr(".ipa.ipg.m4r",E)=0 Then   ' Method below fails for apps, games & ringtones
      Set PersistentObject=iTunes.LibraryPlaylist.Tracks.ItemByPersistentID(iTunes.ITObjectPersistentIDHigh(T),iTunes.ITObjectPersistentIDLow(T))
    End If  
  End If  
End Function


' Return relevant string depending on whether value is plural or singular
' Modified 2011-10-04
Function Plural(V,P,S)
  If V=1 Then Plural=S Else Plural=P
End Function


' Format a list of values for output
' Modified 2012-08-25
Function PrettyList(L,N)
  If L="" Then
    PrettyList=N & "."
  Else
    PrettyList=Replace(Left(L,Len(L)-1)," and" & nl,"," & nl) & " and" & nl & N & "."
  End If
End Function


' Loop through track selection processing suitable items
' Modified 2015-01-06
Sub ProcessTracks
  Dim C,I,N,Q,R,T
  Dim First,Last,Steps
  If IsEmpty(Rev) Then Rev=True
  If Rev Then
    First=Count : Last=1 : Steps=-1
  Else
    First=1 : Last=Count : Steps=1
  End If
  N=0
  If Prog Then                  ' Create ProgessBar
    Set PB=New ProgBar
    PB.SetTitle Title
    PB.Show
  End If
  Clock=0 : StartTimer
  For I=First To Last Step Steps        ' Usually work backwards in case edit removes item from selection
    N=N+1                 
    If Prog Then
      PB.SetStatus Status(N)
      PB.Progress N-1,Count
    End If
    Set T=Tracks.Item(I)
    If T.Kind=1 Then            ' Ignore tracks which can't change
      Set T=PersistentObject(T) ' Attach to object in library playlist
      If Prog Then PB.SetInfo Info(T)
      If Updateable(T) Then     ' Ignore tracks which won't change
        If Check Then           ' Track by track confirmation
          Q=Prompt(T)
          StopTimer             ' Don't time user inputs 
          R=MsgBox(Q,vbYesNoCancel+vbQuestion,Title & " - " & GroupDig(N) & " of " & GroupDig(Count))
          StartTimer
          Select Case R
          Case vbYes
            C=True
          Case vbNo
            C=False
            S=S+1               ' Increment skipped tracks
          Case Else
            Quit=True
            Exit For
          End Select          
        Else
          C=True
        End If
        If C Then               ' We have a valid track, now do something with it
          Action T
        End If
      End If
    End If 
    P=P+1                       ' Increment processed tracks
    ' WScript.Sleep 500         ' Slow down progress bar when testing
    If Quit Then Exit For       ' Abort loop on user request
  Next
  StopTimer
  If Prog And Not Quit Then
    PB.Progress Count,Count
    WScript.Sleep 250
  End If
  If Prog Then PB.Close
End Sub


' Output report
' Modified 2014-04-29
Sub Report
  If Not Outro Then Exit Sub
  Dim L,T
  L=""
  If Quit Then T="Script aborted!" & nl & nl Else T=""
  T=T & GroupDig(P) & " track" & Plural(P,"s","")
  If P<Count Then T=T & " of " & GroupDig(Count)
  T=T & Plural(P," were"," was") & " processed of which " & nl
  If D>0 Then L=PrettyList(L,GroupDig(D) & Plural(D," were duplicates"," was a duplicate") & " in the list")
  If V>0 Then L=PrettyList(L,GroupDig(V) & " did not need updating")
  If U>0 Or V=0 Then L=PrettyList(L,GroupDig(U) & Plural(U," were"," was") & " updated")
  If S>0 Then L=PrettyList(L,GroupDig(S) & Plural(S," were"," was") & " skipped")
  If M>0 Then L=PrettyList(L,GroupDig(M) & Plural(M," were"," was") & " missing")
  T=T & L
  If Timing Then 
    T=T & nl & nl
    If Check Then T=T & "Processing" Else T=T & "Running"
    T=T & " time: " & FormatTime(Clock)
  End If
  MsgBox T,vbInformation,Title
End Sub


' Return iTunes like sort name
' Modified 2011-01-27
Function SortName(N)
  Dim L
  N=LTrim(N)
  L=LCase(N)
  SortName=N
  If Left(L,2)="a " Then SortName=Mid(N,3)
  If Left(L,3)="an " Then SortName=Mid(N,4)
  If Left(L,3)="""a " Then SortName=Mid(N,4)
  If Left(L,4)="the " Then SortName=Mid(N,5)
  If Left(L,4)="""an " Then SortName=Mid(N,5)
  If Left(L,5)="""the " Then SortName=Mid(N,6)
End Function


' Start timing event
' Modified 2011-10-08
Sub StartEvent
  T2=Timer
End Sub


' Start timing session
' Modified 2011-10-08
Sub StartTimer
  T1=Timer
End Sub


' Stop timing event and display elapsed time in debug section of Progress Bar
' Modified 2011-11-07
Sub StopEvent
  If Prog Then
    T2=Timer-T2
    If T2<0 Then T2=T2+86400            ' Watch for timer running over midnight
    If Debug Then PB.SetDebug "<br>Last iTunes call took " & FormatTime(T2) 
  End If  
End Sub


' Stop timing session and add elapased time to running clock
' Modified 2011-10-08
Sub StopTimer
  Clock=Clock+Timer-T1
  If Clock<0 Then Clock=Clock+86400     ' Watch for timer running over midnight
End Sub


' Detect if User Access Control is enabled, UAC (or rather LUA) prevents use of progress bar
' Modified 2011-10-18
Function UAC
  Const HKEY_LOCAL_MACHINE=&H80000002
  Const KeyPath="Software\Microsoft\Windows\CurrentVersion\Policies\System"
  Const KeyName="EnableLUA"
  Dim Reg,Value
  Set Reg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv") 	  ' Use . for local computer, otherwise could be computer name or IP address
  Reg.GetDWORDValue HKEY_LOCAL_MACHINE,KeyPath,KeyName,Value	  ' Get current property
  If IsNull(Value) Then UAC=False Else UAC=(Value<>0)
End Function


' Wrap & tab long strings, break string S on first separator C found at or before character W adding T tabs to each new line
' Modified 2014-05-29
Function Wrap(S,W,C,T)
  Dim P,Q
  P=InstrRev(S," ",W)
  Q=InstrRev(S,"\",W)
  If Q>P Then P=Q
  If P Then
    Wrap=Left(S,P) & nl & String(T,tab) & Wrap(Mid(S,P+1),W,C,T)
  Else
    Wrap=S
  End If
End Function


' ==================
' Progress Bar Class
' ==================

' Progress/activity bar for vbScript implemented via IE automation
' Can optionally rebuild itself if closed or abort the calling script
' Modified 2015-02-06
Class ProgBar
  Public Cells,Height,Width,Respawn,Title,Version
  Private Active,Blank,Dbg,Filled(),FSO,IE,Info,NextOn,NextOff,Status,SHeight,SWidth,Temp

' User has closed progress bar, abort or respwan?
' Modified 2011-10-09
  Public Sub Cancel()
    If Respawn And Active Then
      Active=False
      If Respawn=1 Then
        Show                    ' Ignore user's attempt to close and respawn
      Else
        Dim R
        StopTimer               ' Don't time user inputs 
        R=MsgBox("Abort Script?",vbExclamation+vbYesNoCancel,Title)
        StartTimer
        If R=vbYes Then
          On Error Resume Next
          CleanUp
          Respawn=False
          Quit=True             ' Global flag allows main program to complete current task before exiting
        Else
          Show                  ' Recreate box if closed
        End If  
      End If        
    End If
  End Sub

' Delete temporary html file  
' Modified 2011-10-04
  Private Sub CleanUp()
    FSO.DeleteFile Temp         ' Delete temporary file
  End Sub
  
' Close progress bar and tidy up
' Modified 2015-02-06
  Public Sub Close()
    On Error Resume Next        ' Ignore errors caused by closed object
    If Active Then
      Active=False              ' Ignores second call as IE object is destroyed
      IE.Quit                   ' Remove the progress bar
      CleanUp
    End If    
 End Sub
 
' Initialize object properties
' Modified 2015-02-06
  Private Sub Class_Initialize()
    Dim I,Items,strComputer,WMI
    ' Get width & height of screen for centering ProgressBar
    strComputer="."
    Set WMI=GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
    Set Items=WMI.ExecQuery("Select * from Win32_OperatingSystem",,48)
    'Get the OS version number (first two)
    For Each I in Items
      Version=Left(I.Version,3)
    Next
    Set Items=WMI.ExecQuery ("Select * From Win32_DisplayConfiguration")
    For Each I in Items
      SHeight=I.PelsHeight
      SWidth=I.PelsWidth
    Next
    If Debug Then
      Height=160                ' Height of containing div
    Else
      Height=120                ' Reduce height if no debug area
    End If
    Width=300                   ' Width of containing div
    Respawn=True                ' ProgressBar will attempt to resurrect if closed
    Blank=String(50,160)        ' Blanks out "Internet Explorer" from title
    Cells=25                    ' No. of units in ProgressBar, resize window if using more cells
    ReDim Filled(Cells)         ' Array holds current state of each cell
    For I=0 To Cells-1
      Filled(I)=False
    Next
    NextOn=0                    ' Next cell to be filled if busy cycling
    NextOff=Cells-5             ' Next cell to be cleared if busy cycling
    Dbg="&nbsp;"                ' Initial value for debug text
    Info="&nbsp;"               ' Initial value for info text
    Status="&nbsp;"             ' Initial value for status text
    Title="Progress Bar"        ' Initial value for title text
    Set FSO=CreateObject("Scripting.FileSystemObject")          ' File System Object
    Temp=FSO.GetSpecialFolder(2) & "\ProgBar.htm"               ' Path to Temp file
  End Sub

' Tidy up if progress bar object is destroyed
' Modified 2011-10-04
  Private Sub Class_Terminate()
    Close
  End Sub
 
' Display the bar filled in proportion X of Y
' Modified 2011-10-18
  Public Sub Progress(X,Y)
    Dim F,I,L,S,Z
    If X<0 Or X>Y Or Y<=0 Then
      MsgBox "Invalid call to ProgessBar.Progress, variables out of range!",vbExclamation,Title
      Exit Sub
    End If
    Z=Int(X/Y*(Cells))
    If Z=NextOn Then Exit Sub
    If Z=NextOn+1 Then
      Step False
    Else
      If Z>NextOn Then
        F=0 : L=Cells-1 : S=1
      Else
        F=Cells-1 : L=0 : S=-1
      End If
      For I=F To L Step S
        If I>=Z Then
          SetCell I,False
        Else
          SetCell I,True
        End If
      Next
      NextOn=Z
    End If
  End Sub

' Clear progress bar ready for reuse  
' Modified 2011-10-16
  Public Sub Reset
    Dim C
    For C=Cells-1 To 0 Step -1
      IE.Document.All.Item("P",C).classname="empty"
      Filled(C)=False
    Next
    NextOn=0
    NextOff=Cells-5   
  End Sub
  
' Directly set or clear a cell
' Modified 2011-10-16
  Public Sub SetCell(C,F)
    On Error Resume Next        ' Ignore errors caused by closed object
    If F And Not Filled(C) Then
      Filled(C)=True
      IE.Document.All.Item("P",C).classname="filled"
    ElseIf Not F And Filled(C) Then
      Filled(C)=False
      IE.Document.All.Item("P",C).classname="empty"
    End If
  End Sub 
 
' Set text in the Dbg area
' Modified 2011-10-04
  Public Sub SetDebug(T)
    On Error Resume Next        ' Ignore errors caused by closed object
    Dbg=T
    IE.Document.GetElementById("Debug").InnerHTML=T
  End Sub

' Set text in the info area
' Modified 2011-10-04
  Public Sub SetInfo(T)
    On Error Resume Next        ' Ignore errors caused by closed object
    Info=T
    IE.Document.GetElementById("Info").InnerHTML=T
  End Sub

' Set text in the status area
' Modified 2011-10-04
  Public Sub SetStatus(T)
    On Error Resume Next        ' Ignore errors caused by closed object
    Status=T
    IE.Document.GetElementById("Status").InnerHTML=T
  End Sub

' Set title text
' Modified 2011-10-04
  Public Sub SetTitle(T)
    On Error Resume Next        ' Ignore errors caused by closed object
    Title=T
    IE.Document.Title=T & Blank
  End Sub
  
' Create and display the progress bar  
' Modified 2014-05-04
  Public Sub Show()
    Const HKEY_CURRENT_USER=&H80000001
    Const KeyPath="Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN"
    Const KeyName="iexplore.exe"
    Dim File,I,Reg,State,Value
    Set Reg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv") 	' Use . for local computer, otherwise could be computer name or IP address
    'On Error Resume Next        ' Ignore possible errors
    ' Make sure IE is set to allow local content, at least while we get the Progress Bar displayed
    Reg.GetDWORDValue HKEY_CURRENT_USER,KeyPath,KeyName,Value	' Get current property
    State=Value	 							  ' Preserve current option
    Value=0		    							' Set new option 
    Reg.SetDWORDValue HKEY_CURRENT_USER,KeyPath,KeyName,Value	' Update property
    'If Version<>"5.1" Then Prog=False : Exit Sub      ' Need to test for Vista/Windows 7 with UAC
    Set IE=WScript.CreateObject("InternetExplorer.Application","Event_")
    Set File=FSO.CreateTextFile(Temp, True)
    With File
      .WriteLine "<!doctype html>"
      '.WriteLine "<!-- saved from url=(0014)about:internet -->"
      .WriteLine "<!-- saved from url=(0016)http://localhost -->"      ' New "Mark of the web"
      .WriteLine "<html><head><title>" & Title & Blank & "</title>"
      .WriteLine "<style type='text/css'>"
      .WriteLine ".border {border: 5px solid #DBD7C7;}"
      .WriteLine ".debug {font-family: Tahoma; font-size: 8.5pt;}"
      .WriteLine ".empty {border: 2px solid #FFFFFF; background-color: #FFFFFF;}"
      .WriteLine ".filled {border: 2px solid #FFFFFF; background-color: #00FF00;}"
      .WriteLine ".info {font-family: Tahoma; font-size: 8.5pt;}"
      .WriteLine ".status {font-family: Tahoma; font-size: 10pt;}"
      .WriteLine "</style>"
      .WriteLine "</head>"
      .WriteLine "<body scroll='no' style='background-color: #EBE7D7'>"
      .WriteLine "<div style='display:block; height:" & Height & "px; width:" & Width & "px; overflow:hidden;'>"
      .WriteLine "<table border-width='0' cellpadding='2' width='" & Width & "px'><tr>"
      .WriteLine "<td id='Status' class='status'>" & Status & "</td></tr></table>"
      .WriteLine "<table class='border' cellpadding='0' cellspacing='0' width='" & Width & "px'><tr>"
      ' Write out cells
      For I=0 To Cells-1
	      If Filled(I) Then
          .WriteLine "<td id='p' class='filled'>&nbsp;</td>"
        Else
          .WriteLine "<td id='p' class='empty'>&nbsp;</td>"
        End If
      Next
	    .WriteLine "</tr></table>"
      .WriteLine "<table border-width='0' cellpadding='2' width='" & Width & "px'><tr><td>"
      .WriteLine "<span id='Info' class='info'>" & Info & "</span><br>"
      .WriteLine "<span id='Debug' class='debug'>" & Dbg & "</span></td></tr></table>"
      .WriteLine "</div></body></html>"
    End With
    ' Create IE automation object with generated HTML
    With IE
      .width=Width+35           ' Increase if using more cells
      .height=Height+60         ' Increase to allow more info/debug text
      If Version>"5.1" Then     ' Allow for bigger border in Vista/Widows 7
        .width=.width+10
        .height=.height+10
      End If        
      .left=(SWidth-.width)/2
      .top=(SHeight-.height)/2
      .navigate "file://" & Temp
      '.navigate "http://samsoft.org.uk/progbar.htm"
      .addressbar=False
      .resizable=False
      .toolbar=False
      On Error Resume Next      
      .menubar=False            ' Causes error in Windows 8 ? 
      .statusbar=False          ' Causes error in Windows 7 or IE 9
      On Error Goto 0
      .visible=True             ' Causes error if UAC is active
    End With
    Active=True
    ' Restore the user's property settings for the registry key
    Value=State		    					' Restore option
    Reg.SetDWORDValue HKEY_CURRENT_USER,KeyPath,KeyName,Value	  ' Update property 
    Exit Sub
  End Sub
 
' Increment progress bar, optionally clearing a previous cell if working as an activity bar
' Modified 2011-10-05
  Public Sub Step(Clear)
    SetCell NextOn,True : NextOn=(NextOn+1) Mod Cells
    If Clear Then SetCell NextOff,False : NextOff=(NextOff+1) Mod Cells
  End Sub

' Self-timed shut-down
' Modified 2015-02-06 
  Public Sub TimeOut(S)
    Dim I
    Respawn=False                ' Allow uninterrupted exit during countdown
    For I=S To 2 Step -1
      SetDebug "<br>Closing in " & I & " seconds" & String(I,".")
      WScript.sleep 1000
    Next
      SetDebug "<br>Closing in 1 second."
      WScript.sleep 1000
    Close
  End Sub 
    
End Class


' Fires if progress bar window is closed, can't seem to wrap up the handler in the class
' Modified 2011-10-04
Sub Event_OnQuit()
  PB.Cancel
End Sub


' ==============
' End of listing
' ==============
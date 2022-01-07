Sub test()

Dim i As Long
i = 0

Dim f As String
Application.FileDialog(msoFileDialogOpen).Show
f = Application.FileDialog(msoFileDialogOpen).SelectedItems(1)

ScreenUpdating = False

Line2: On Error GoTo Line1
Documents.Open f, , True, , i & ""
MsgBox "Password is " & i
Application.ScreenUpdating = True
Exit Sub

Line1: i = i + 1
Resume Line2
ScreenUpdating = True

End Sub

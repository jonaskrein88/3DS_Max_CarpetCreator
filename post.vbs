

file = WScript.Arguments.Item(0)
bgPath = WScript.Arguments.Item(1)
outpath = WScript.Arguments.Item(2)

Set fso = CreateObject("Scripting.FileSystemObject")
If not (fso.FileExists(file)) Then
   MsgBox("File not found " + file)
   WScript.StdIn.Read(1)
   Wscript.Quit(1)
End If
If not (fso.FileExists(bgPath)) Then
   MsgBox("Background not found")
   WScript.StdIn.Read(1)
   Wscript.Quit(1)
End If




Dim appRef, dialogMode, file, outpath
Set appRef = CreateObject( "Photoshop.Application" )

appRef.DisplayDialogs = 3
appRef.Preferences.RulerUnits = 1

'Dim arr() as File() = folderref.Files




Dim img, bgLayer, tmpComp, col, shadow, bgComp 

Set bgComp = appRef.Open(bgPath)
Set tmpComp = appRef.Open(file)

appRef.ActiveDocument = bgComp
bgComp.ActiveLayer.Copy()
appRef.ActiveDocument = tmpComp

Set img = tmpComp.ArtLayers.Item(1)
Set bgLayer = tmpComp.Paste()

bgLayer.move img, 4 

Set col = CreateObject( "Photoshop.RGBColor")
col.red = 0
col.green = 0
col.blue = 0

set shadow = img.duplicate(img, 4)
shadow.name = "Shadow"

tmpComp.Selection.SelectAll()
tmpComp.ActiveLayer = shadow
tmpComp.Selection.Fill col, 2, 100, true
'shadow.move img, 10, 10							' inside, start, end, before, after
shadow.translate 2, 2 
shadow.blendMode = 5
shadow.opacity = 50.0
shadow.applyGaussianBlur(2)

tmpComp.saveAs(outpath)

dim jpgOptions
Set jpgOptions = CreateObject( "Photoshop.JPEGSaveOptions")
tmpComp.saveAs outpath, jpgOptions
tmpComp.close()
bgComp.close()

Wscript.Echo (file + Chr(13) + Chr(10)) 

WScript.Quit(99)





' batch processing for testing purposes'



Dim appRef, i, message, dialogMode, bgComp, comp,outpath
Set appRef = CreateObject( "Photoshop.Application" )


outpath = "C:\Users\j.krein\Desktop\renderings\out\"

Set fsoref = CreateObject("Scripting.FileSystemObject")
Set folderref = fsoref.GetFolder("C:\Users\j.krein\Desktop\renderings")

Set bgComp = appRef.Open("C:\Users\j.krein\Desktop\renderings\backgrounds\loft.jpg")

appRef.DisplayDialogs = 3
appRef.Preferences.RulerUnits = 1

'Dim arr() as File() = folderref.Files


i = 0
For Each f in folderref.Files 


	Dim l, outname
	l = len(f.name)
	'outname = LSet f.name, l

	Dim img, bgLayer, tmpComp, col, shadow

	Set tmpComp = appRef.Open(f.path)

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
	shadow.translate 0.07, 0.15 
	shadow.blendMode = 5
	shadow.opacity = 50.0
	shadow.applyGaussianBlur(2)

	tmpComp.saveAs(outpath)

	dim jpgOptions
	Set jpgOptions = CreateObject( "Photoshop.JPEGSaveOptions")
	tmpComp.saveAs outpath, jpgOptions
	tmpComp.close()

	Wscript.Echo (f.name + Chr(13) + Chr(10)) 

	i = i + 1
Next


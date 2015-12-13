<?xml version="1.0" encoding="ISO-8859-1"?>
<Files>
<%
Response.buffer=true
Response.Expires = -1
Response.ExpiresAbsolute = Now() -1 
Response.AddHeader "pragma", "no-store"
Response.AddHeader "cache-control","no-store, no-cache, must-revalidate"

Sub WriteFileInfo( pathName, fileName )
  fullName = fs.BuildPath( pathName, fileName )
  Set f = fs.GetFile( fullName )
  Response.Write( "<File>" )
  Response.Write("<Name>" & f.Name & "</Name>" )
  Response.Write("<Type>" & f.Type & "</Type>" )
  Response.Write("<LastModified>" & f.DateLastModified & "</LastModified>" )
  Response.Write("<Size>" & f.Size & "</Size>" )
  Response.Write("<Version>" & fs.GetFileVersion(fullName)  & "</Version>" )
  Response.Write( "</File>" )
  Set f = nothing
End Sub


Set fs = Server.CreateObject("Scripting.FileSystemObject")
Set fo = fs.GetFolder("d:\websiter\downloads.emetra.no\")
fileName = Request( "FileName" ) 
if not fileName = "" Then
  WriteFileInfo fo.Path, fileName
else
  For each x in fo.files
    WriteFileInfo fo.Path, x.Name 
  Next
End If

Set fo=nothing
Set fs = nothing
%>
</Files>
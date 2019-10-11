{
<%@ Language=VBScript %>
<!-- #include virtual="Include/Config.asp" -->
<!-- #include virtual="Include/adovbs.asp" -->
<% 

	Set oConn = Server.CreateObject("ADODB.connection")
  	oConn.Open PUBLIC_CONNECTION
  
	Dim strSQL
	Dim dbVersion 
	Dim lAntallPoster

  	dbVersion = CInt(Request("DbVersion"))
	If dbVersion = 0 Then dbVersion = 521

	strSQL = "SELECT TOP 1 * FROM Tools.FastTrakVersion WHERE MinimumVersion <= " & dbVersion & " ORDER BY MinimumVersion DESC"

	Set oRS = oConn.Execute( strSQL, lAntallPoster, 1 )
	
	do while not oRs.EOF
		for each fld in oRs.Fields
			if ( fld.Value<>"" ) then Response.Write( "  """ & fld.Name & """: """ & fld.Value & """," & vbCRLF )
		next
		Response.Write( "  ""RequestedVersion"": " & dbVersion)
		oRs.MoveNext
	loop	

	set oRs = nothing
	
	set oConn = nothing
%>
}
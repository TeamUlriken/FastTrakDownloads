function GetOption( const AVarNo: integer ): integer;
var
  varName: string;
  varValue: Variant;
  valueString: string;                                                      
begin
  Result := -1;                                                
  varName := Format( 'FORM.%d.VALUE', [AVarNo] );
  varValue := Get( varName );
  valueString := VarToStr( varValue );
  if ValidInt( valueString ) then
    Result := StrToInt( valueString );                                                                                                                                      
end;
  
procedure CheckIfOne( const AItemId: integer; ACheck: TfrxCheckBoxView );
var
  ordOption: integer;                                                                             
begin
  ordOption := GetOption( AItemId );
  ACheck.Checked := ( ordOption = 1 );
  if ACheck.Checked then ACheck.Color := clYellow;                                                                                                         
end;          

procedure CheckIfSame( ACheck: TfrxCheckBoxView; const AValue1,AValue2: integer;  );
begin
  ACheck.Checked := ( AValue1 = AValue2 );                                                    
  if ACheck.Checked then ACheck.Color := clYellow;                                                                                                         
end;          
    
procedure Prepare8192;
var
  enumValue: integer;                                                                                                                                        
begin
  { Primary or reoperation }                                                                                      
  enumValue := GetOption( 8192 );
  CheckIfSame( cb8192a, 1, enumValue );                                                                                              
  CheckIfSame( cb8192b, 2, enumValue );                                                                                              
end;        

procedure Prepare8193;
var
  enumValue: integer;                                                                                                                                        
begin
  { Primary or reoperation }
  enumValue := GetOption( 8193 );                                                    
  CheckIfSame( cb8193a, 1, enumValue );                                                                                              
  CheckIfSame( cb8193b, 2, enumValue );                                                                                              
end;
  
procedure Prepare8199;
var
  enumValue: integer;                                                                                                                                        
begin
  { Primary or reoperation }
  enumValue := GetOption( 8199 );                                                    
  CheckIfSame( cb8199a, 1, enumValue );                                                                                              
  CheckIfSame( cb8199b, 2, enumValue );                                                                                              
  CheckIfSame( cb8199c, 3, enumValue );                                                                                              
  CheckIfSame( cb8199d, 4, enumValue );                                                                                              
  CheckIfSame( cb8199e, 5, enumValue );                                                                                              
end;
  
procedure Prepare8200;
var
  enumValue: integer;                                                                                                                                        
begin
  { Primary or reoperation }
  enumValue := GetOption( 8200 );                                                    
  CheckIfSame( cb8200a, 1, enumValue );                                                                                              
  CheckIfSame( cb8200b, 2, enumValue );                                                                                              
  CheckIfSame( cb8200c, 3, enumValue );                                                                                              
end;
  
procedure Prepare8201;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8201 );                                                    
  CheckIfSame( cb8201a, 1, enumValue );                                                                                              
  CheckIfSame( cb8201b, 2, enumValue );                                                                                              
  CheckIfSame( cb8201c, 3, enumValue );                                                                                              
  CheckIfSame( cb8201d, 4, enumValue );                                                                                              
  CheckIfSame( cb8201e, 5, enumValue );                                                                                              
end;
  
procedure Prepare8202;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8202 );                                                    
  CheckIfSame( cb8202a, 1, enumValue );                                                                                              
  CheckIfSame( cb8202b, 2, enumValue );                                                                                              
  CheckIfSame( cb8202c, 3, enumValue );                                                                                              
  CheckIfSame( cb8202d, 4, enumValue );                                                                                              
  CheckIfSame( cb8202e, 5, enumValue );                                                                                              
  CheckIfSame( cb8202f, 6, enumValue );                                                                                              
  CheckIfSame( cb8202g, 7, enumValue );                                                                                              
  CheckIfSame( cb8202h, 8, enumValue );                                                                                              
end;
  
procedure Prepare8204;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8204 );
  CheckIfSame( cb8204a, 1, enumValue );                                                                                              
  CheckIfSame( cb8204b, 2, enumValue );                                                                                              
  CheckIfSame( cb8204c, 3, enumValue );                                                                                              
  CheckIfSame( cb8204d, 4, enumValue );                                                                                              
  CheckIfSame( cb8204e, 5, enumValue );                                                                                              
  CheckIfSame( cb8204f, 6, enumValue );                                                                                              
  CheckIfSame( cb8204g, 7, enumValue );                                                                                              
  CheckIfSame( cb8204h, 8, enumValue );                                                                                              
  CheckIfSame( cb8204i, 9, enumValue );                                                                                              
  CheckIfSame( cb8204j, 10, enumValue );                                                                                              
  CheckIfSame( cb8204k, 11, enumValue );                                                                                              
  CheckIfSame( cb8204l, 12, enumValue );                                                                                              
end;

procedure Prepare8230;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8230 );
  CheckIfSame( cb8230a, 1, enumValue );                                                                                              
  CheckIfSame( cb8230b, 2, enumValue );                                                                                              
  CheckIfSame( cb8230c, 3, enumValue );                                                                                              
end;
    
procedure Prepare8235;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8235 );
  CheckIfSame( cb8235a, 1, enumValue );                                                                                              
  CheckIfSame( cb8235b, 2, enumValue );                                                                                              
  CheckIfSame( cb8235c, 3, enumValue );                                                                                              
end;
    
procedure Prepare8237;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8237 );
  CheckIfSame( cb8237a, 0, enumValue );                                                                                              
  CheckIfSame( cb8237b, 1, enumValue );                                                                                              
end;
    
procedure Prepare8240;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8240 );
  CheckIfSame( cb8240a, 0, enumValue );                                                                                              
  CheckIfSame( cb8240b, 1, enumValue );                                                                                              
end;
    
procedure Prepare8250;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8250 );
  CheckIfSame( cb8250a, 0, enumValue );                                                                                              
  CheckIfSame( cb8250b, 1, enumValue );                                                                                              
end;
    
procedure Prepare8258;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8258 );
  CheckIfSame( cb8258a, 0, enumValue );                                                                                              
  CheckIfSame( cb8258b, 1, enumValue );                                                                                              
end;
    
procedure Prepare8261;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8261 );
  CheckIfSame( cb8261a, 0, enumValue );                                                                                              
  CheckIfSame( cb8261b, 1, enumValue );                                                                                              
end;
    
procedure Prepare8292;
var
  enumValue: integer;                                                                                               
begin
  { Primary or reoperation }
  enumValue := GetOption( 8292 );
  CheckIfSame( cb8292a, 0, enumValue );                                                                                              
  CheckIfSame( cb8292b, 1, enumValue );                                                                                              
end;
    
procedure MasterData2OnBeforePrint(Sender: TfrxComponent);
begin
  Prepare8192;                                                    
  Prepare8193;
  Prepare8199;                                                    
  Prepare8200;                            
  Prepare8201;                            
  Prepare8202;                            
  Prepare8204;
  CheckIfOne( 8206, cb8206 );                                                    
  CheckIfOne( 8207, cb8207 );                                                    
  CheckIfOne( 8208, cb8208 );                                                    
  CheckIfOne( 8209, cb8209 );                                                    
  CheckIfOne( 8210, cb8210 );                                                    
  CheckIfOne( 8211, cb8211 );                                                    
  CheckIfOne( 8212, cb8212 );                                                    
  CheckIfOne( 8213, cb8213 );                                                    
  CheckIfOne( 8214, cb8214 );                                                    
  CheckIfOne( 8215, cb8215 );                                                    
  CheckIfOne( 8216, cb8216 );                                                    
  CheckIfOne( 8217, cb8217 );                                                    
  CheckIfOne( 8218, cb8218 );                                                    
  CheckIfOne( 8220, cb8220 );                                                    
  CheckIfOne( 8221, cb8221 );                                                    
  CheckIfOne( 8222, cb8222 );                                                    
  CheckIfOne( 8223, cb8223 );                                                    
  CheckIfOne( 8224, cb8224 );                                                    
  CheckIfOne( 8225, cb8225 );                                                    
  CheckIfOne( 8226, cb8226 );                                                    
  CheckIfOne( 8227, cb8227 );                                                    
  CheckIfOne( 8228, cb8228 );                                                    
  Prepare8230;
  Prepare8235;
  Prepare8237;
  Prepare8240;
  Prepare8250;
  Prepare8258;
  Prepare8261;
  Prepare8292;
end;

begin

end.

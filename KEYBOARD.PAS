{$F+}
unit Keyboard;


interface

const 
  EscapeKeyCode     : byte = $01;
  EnterKeyCode      : byte = $1c;
  SpaceKeyCode      : byte = $39;
  UpArrowKeyCode    : byte = $48;
  LeftArrowKeyCode  : byte = $4b;
  RightArrowKeyCode : byte = $4d;
  DownArrowKeyCode  : byte = $50;
  BackspaceKeyCode  : byte = $0e;

var KeyDown, WasDown: array[0..127] of boolean;

procedure NewKeyboardInterruptInit;
procedure ClearWasDownArray;
function GetPressedKey : char;


implementation

uses dos;

var OldKeyboardInterrupt: pointer;

procedure sti;
inline($fb);   

procedure CallOldInterrupt(sub: pointer);
begin
  inline($9c/           
         $ff/$5e/$06)
end;

procedure NewKeyboardInterrupt; interrupt;   
begin
  KeyDown[port[$60] mod 128] := (port[$60] < 128);  
  if port[$60] < 128 then WasDown[port[$60]] := true; 
  mem[$0040:$001a] := mem[$0040:$001c];
  sti
end;

procedure NewKeyboardInterruptInit; 
begin
  ClearWasDownArray;
  getintvec($09, OldKeyboardInterrupt);
  setintvec($09, addr(NewKeyboardInterrupt));
  sti
end;

procedure ClearWasDownArray;
var i : byte;
begin
  for i := 0 to 127 do begin
    KeyDown[i] := false;
    WasDown[i] := false
    end;
end;

function GetPressedKey : char;
var 
  tempKey : char;
  i : byte;
begin
  for i := 0 to 127 do 
  begin
    if WASDOWN[i] then begin
      case i of
      $1e : tempKey := 'A';
      $1f : tempKey := 'S';
      $20 : tempKey := 'D';
      $21 : tempKey := 'F';
      $22 : tempKey := 'G';
      $23 : tempKey := 'H';
      $24 : tempKey := 'J';
      $25 : tempKey := 'K';
      $26 : tempKey := 'L';
      $10 : tempKey := 'Q';
      $11 : tempKey := 'W';
      $12 : tempKey := 'E';
      $13 : tempKey := 'R';
      $14 : tempKey := 'T';
      $15 : tempKey := 'Y';
      $16 : tempKey := 'U';
      $17 : tempKey := 'I';
      $18 : tempKey := 'O';
      $19 : tempKey := 'P';
      $2c : tempKey := 'Z';
      $2d : tempKey := 'X';
      $2e : tempKey := 'C';
      $2f : tempKey := 'V';
      $30 : tempKey := 'B';
      $31 : tempKey := 'N';
      $32 : tempKey := 'M';
      $02 : tempKey := '1';
      $03 : tempKey := '2';
      $04 : tempKey := '3';
      $05 : tempKey := '4';
      $06 : tempKey := '5';
      $07 : tempKey := '6';
      $08 : tempKey := '7';
      $09 : tempKey := '8';
      $0a : tempKey := '9';
      $0b : tempKey := '0';
      else tempKey := ' ';
      end;
      if tempKey <> ' ' then ClearWasDownArray;
      GetPressedKey := tempKey;
      break;
    end else GetPressedKey := ' ';
  end;  
end;

end.
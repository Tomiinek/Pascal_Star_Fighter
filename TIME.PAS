{$F+}
unit Time;


interface

procedure NewTimeInterruptInit;
procedure SetOldTimeInterrupt;
procedure TickWait(WaitTime: byte);



implementation

uses dos;

var OldTimeInterrupt : pointer;
    ClockTick: byte;

procedure sti;
inline($fb); 

procedure CallOldInterrupt(sub: pointer);
begin
  inline($9c/          
         $ff/$5e/$06) 
end;

procedure NewTimeInterrupt; interrupt;   
begin
  CallOldInterrupt(OldTimeInterrupt);        
  ClockTick := ClockTick + 1
end;

procedure NewTimeInterruptInit; 
begin
  getintvec($1c, OldTimeInterrupt); 
  setintvec($1c, addr(NewTimeInterrupt)); 
  ClockTick := 0; 
  sti
end;

procedure SetOldTimeInterrupt;
begin
  setintvec($1c, OldTimeInterrupt);
  sti
end;

procedure TickWait(WaitTime: byte);   
begin
  repeat until ClockTick >= WaitTime;
  ClockTick := 0
end;

end.
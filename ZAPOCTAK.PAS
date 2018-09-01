Program ZapoctovyProgarm;

{ Tomas Nekvinda, I. rocnik, utterni skupina 15:40 }
{ Zimni semestr 2015/16 }
{ Programovani I  NPRG030 }

Uses Graph, crt, Keyboard, Time;

{ Vyuzivam grafickou knihovnu Graph, jednotku crt (pouze kvuli zvukum) a jednotky Keyboard 
  a Time, jejich zdorjovy kod je v souborech KEYBOARD.PAS a TIME.PAS. Prevzal jsem je 
  od jineho autora a jen nepatrne upravil. Keyboard umi oproti crt odchytit vic klaves 
  najednou. Time umoznuje lepsi a presnejsi kontrolu casu nez standartni funkce Boarland 
  Pascalu. Puvodni podoba je dostupna na adrese:
  https://github.com/Spekkio/Knight/blob/master/GAMES.PAS }

{ ****************************** DEKLARACE KONSTANT ****************************** }

Const
   { Max pocet obejktu }
   MAXOBEJCTS = 4096;
   { Typy objektu }
   STAR  = 1;
   STONE = 2;
   BONUS = 3;
   SHIP  = 4;
   SHOT  = 5;
   { Typy lodi }
   PLAYER    = 1;
   BASIC     = 2;
   ADVANCED  = 3;
   MASTER    = 4;
   { Typy kamenu }
   MEDIUM = 1;
   TINY   = 2;
   BIG    = 3;
   { Typy bonusu }
   HEALTHLOW   = 1;
   HEALTHHIGH  = 2;
   ARMORLOW    = 3;
   ARMORHIGH   = 4;
   FURIOUS     = 5;
   DEATHLESS   = 6;
   MOVSPEED    = 7;
   { Vlasnosti bonusu }
   H_LOW   = 10;
   H_HIGH  = 30;
   A_LOW   = 50;
   A_HIGH  = 100;
   F_DUR   = 100; 
   F_GUNCOOLDOWN = 2;
   D_DUR   = 100;
   SPD_INC = 1;
   { Nastaveni lodi }
   MINSPEED  = 2;
   MAXSPEED  = 5;
   MAXHEALTH = 100;
   MAXARMOR  = 250;
   MAXGUNLVL = 5;
   MAXGUNCOOLDOWN = 50;
   { Pocitani skore }
   LOOPSFORSCOREPOINT = 100;
   STONESCORE = 5;
   SHIPSCORE = 20;
   { Soubory}
   SCORESFILE       = 'SCORES.TXT';
   STARFILE         = 'IMG/STAR.TXT';
   BIGSTONEFILE     = 'IMG/BIG.TXT';
   TINYSTONEFILE    = 'IMG/TINY.TXT';
   MEDIUMSTONEFILE  = 'IMG/MEDIUM.TXT';
   PLAYERSHIPFILE   = 'IMG/PLAYER.TXT';
   BASICSHIPFILE    = 'IMG/BASIC.TXT';
   ADVANCEDSHIPFILE = 'IMG/ADVANCED.TXT';
   MASTERSHIPFILE   = 'IMG/MASTER.TXT';
   BONUSFILE        = 'IMG/BONUS.TXT';
   { Ostatni }
   BONUSMESSGAEDURATION = 50;
   LEVELMESSAGEDURATION = 50;



{ ******************************** DEKLARACE TYPU ******************************** }

Type
  
  TProc = Procedure(i : shortint);

  PGameState = ^TGameState;
  PTObject   = ^TObject;
  PTStar     = ^TStar;
  PTStone    = ^TStone;
  PTShip     = ^TShip;
  PTBonus    = ^TBonus;
  PTShot     = ^TShot;

  TMsg = Record
    text : string;
    duration : shortint;
  end;
  
  TGameState = Record
    GameOver : boolean; 
    Score    : word; 
    NumberOfObjects : integer; 
    MainShip        : PTShip;
    PObjectArray    : array[1..MAXOBEJCTS] of PTObject;
    Msg : TMsg;
    PlayerName : string;
  end;

  TObject = Object
    x, y, w, h, id : integer;
    direction : boolean;
    speed,t: byte;
    function GetX : integer;
    function GetY : integer;
    function GetType : byte;
    function GetWidth  : integer;
    function GetHeight : integer;
    function GetSpeed  : integer;
    function GetDirection : boolean;
    procedure Move;
    procedure Draw; virtual;
    procedure Assign(var GameState : PGameState; CordX, CordY, Width, Height : integer; Spd, Typ : byte; Dir : boolean);
    Constructor Init(var GameState : PGameState; CordX, CordY, Width, Height : integer; Spd, Typ : byte; Dir : boolean);
    Destructor CleanUp(var GameState : PGameState);
  end;

  TStar = Object(TObject)
    procedure Draw; virtual;
    Constructor Init(var GameState : PGameState; CordX, CordY : integer; Spd : byte );
  end;

  TStone = Object(TObject)
    sort, damage : byte;
    procedure Draw; virtual;
    function GetDamage : byte;
    function GetSort : byte;
    Constructor Init(var GameState : PGameState; CordX, CordY : integer; ObjKind, Spd : byte);
  end;
    
  TShip =
  Object(TObject)
    health, armor, sort,
    gun, gunCoolDown, bonusGunCooldown, gunCounter,
    activeBonus, bonusDuration : byte;
    xinertia, yinertia : shortint;
    hurt : boolean;
    procedure Draw; virtual;
    procedure Move; virtual;
    procedure Hit( dmg : integer ); 
    function Shoot( var GameState : PGameState ) : boolean;
    procedure SetXInertia( change:shortint );
    procedure SetYInertia( change:shortint );
    procedure CooldownDecrement;
    procedure BonusDurationDecrement;
    function GetHealth : integer;
    function GetArmor : integer;
    function GetGunCounter : integer;
    function GetGunLevel : integer;
    function GetSort : byte;
    Constructor Init(var GameState : PGameState; CordX, CordY : integer; 
                     Dir : boolean; ObjKind : byte );
  end;

  TBonus = Object(TObject)
    sort : byte;
    procedure Draw; virtual;
    procedure Apply(p : PTShip); 
    function GetStr : string;
    Constructor Init(var GameState : PGameState; CordX, CordY : integer; ObjKind, Spd : byte);
  end;
 
  TShot = Object(TObject)
    lvl, damage : byte;
    procedure Draw; virtual;
    function GetDamage : byte;
    Constructor Init(var GameState : PGameState; CordX, CordY : integer; Dir : boolean; Level : byte);
  end;




{ Procedura na vykreslení objektu, je deklarovana uz tady, protoze ji vyuzivaji objekty
  ve svych metodach. Z parametru Obj urci typ objektu a zvoli pro neho prislusny ukazatel.
  Pokud je pro tento typ objektu procedura volana poprve, precte obsah souboru, ve kterem
  je na kazdem radku 5 ciselnych hodnot. Prvni udava barvu, 2 a 3. souradnice horniho
  leveho rohu a 4. a 5. souradnice dolniho praveho rohu. Kazdy radek v souboru vyjadruje
  jeden ctverecek o urcite barve. Pote jsou vsechna prectena data vykreslena.
  Zvolil jsem toto reseni, protoze se mi nepovedle pomoci Unity Graph vykreslit Bitmapu.
  Procedura ma pro kazdy typ objektu svoji promennou, protoze Borland Pascal u svych objektu
  neumoznuje vytvaret staticke promenne. }
Procedure DrawShape(Obj : PTObject; path : string);
type
  PPTbar = ^PTBar;
  PTBar = ^TBar;
  TBar = record
    color : byte;
    fx, fy,
    tx, ty : byte;
    next : PTBar;
  end;
const
  bStar         : PTBar = NIL;
  bBonus        : PTBar = NIL; 
  bTinyStone    : PTBar = NIL;
  bMediumStone  : PTBar = NIL;
  bBigStone     : PTBar = NIL;
  bPlayerShip   : PTBar = NIL;
  bBasicShip    : PTBar = NIL;
  bAdvancedShip : PTBar = NIL;
  bMasterShip   : PTBar = NIL;
var 
  f : text; 
  item, lastItem : PTBar; 
  buffer : PPTbar;
  CordX, CordY, c : integer;
begin

  { Vybere prislusny prvni prvek spojoveho seznamu pro zadany ty objektu }
  case Obj^.GetType of
  STAR  : buffer := @bStar;
  BONUS : buffer := @bBonus;
  STONE : begin
      case PTStone(Obj)^.GetSort of
        TINY   : buffer := @bTinyStone;
        MEDIUM : buffer := @bMediumStone;
        BIG    : buffer := @bBigStone;
      end;
    end;
  SHIP  : begin
      case PTShip(Obj)^.GetSort of
        PLAYER   : buffer := @bPlayerShip;
        BASIC    : buffer := @bBasicShip;
        ADVANCED : buffer := @bAdvancedShip;
        MASTER   : buffer := @bMasterShip;
      end;
    end
  end;

  { Pokud jeste nebyl vytvoren spojovy seznam, ktery reprezentuje data v souboru, nacte ho }
  if buffer^ = NIL then
  begin
    Assign(f,path);
    Reset(f);
    
    new(buffer^);
    buffer^^.next := NIL;
    lastItem := buffer^;

    while NOT eof(f) do
    begin
      New(item);
      item^.next := NIL;

      with item^ do Readln(f, color, fx, fy, tx, ty);

      lastItem^.next := item;
      lastItem := lastItem^.next;
    end;

    Close(f);
  end;
  
  { Zjisti souradnice objektu }
  CordX := Obj^.GetX;
  CordY := Obj^.GetY;

  { Vykresli seznam, na ktery ukazuje ukazatel buffer }
  item := buffer^^.next;
  while item <> NIL do
  begin
    c := item^.color;
    if Obj^.GetType = SHIP then
      if PTShip(Obj)^.hurt then c := 4;
    SetFillStyle(SolidFill,c);
    Bar(CordX+item^.fx, CordY+item^.fy, CordX+item^.tx, CordY+item^.ty);
    item := item^.next;
  end;
end;




{ ************************** DEFINICE OBJEKTOVYCH METOD ************************** }

{ ------------- ABSTRAKTNI OBJEKT ------------- }

Constructor TObject.Init(var GameState : PGameState; CordX, CordY, Width, Height : integer; Spd, Typ : byte; Dir : boolean);
begin
  self.Assign(GameState, CordX, CordY, Width, Height, Spd, Typ, Dir);
end;

{ Parametr GameState obsahuje informace o stavu hru - tedy i pocet objektu, a pole s ukazateli
  na vsechny objekty ve hre - pri zniceni objektu se snizi pocet objektu a na index zniceneho 
  v poli ukazatelu se presune ukazatel na nejvyssim indexu }
Destructor TObject.CleanUp(var GameState : PGameState);
begin
  GameState^.PObjectArray[GameState^.NumberOfObjects]^.id := id;
  GameState^.PObjectArray[id] := GameState^.PObjectArray[GameState^.NumberOfObjects];
  Dec(GameState^.NumberOfObjects);
end;

Function TObject.GetX : integer; begin GetX := x; end;
Function TObject.GetY : integer; begin GetY := y; end;
Function TObject.GetType : byte; begin GetType := t; end;  
Function TObject.GetWidth : integer;  begin GetWidth  := w; end;
Function TObject.GetHeight : integer; begin GetHeight := h; end;
Function TObject.GetSpeed : integer; begin GetSpeed := speed; end;
Function TObject.GetDirection : boolean; begin GetDirection := direction; end;
Procedure TObject.Draw; begin end;
Procedure TObject.Move;
  begin
    if direction then x := x +speed
    else              x := x -speed
  end;
{ Nastavi pocatecni hodnoty, GameState obsahuje informace o stavu hru - tedy i pocet objektu,
  ktery se pri vytvoreni noveho objektu zvysuje }
Procedure TObject.Assign(var GameState : PGameState; CordX, CordY, Width, Height : integer; Spd, Typ : byte; Dir : boolean);
begin
  Inc(GameState^.NumberOfObjects);
  id := GameState^.NumberOfObjects;
  x := CordX;
  y := CordY;
  w := Width;
  h := Height;
  t := Typ;
  speed := Spd;
  direction := Dir; 
end;

{ ----------------- HVEZDICKA ----------------- }

Constructor TStar.Init(var GameState : PGameState; CordX, CordY : integer; Spd : byte );
const
  initWidth     = 4;
  initHeight    = 4;
  initDirection = FALSE;
begin
  self.Assign(GameState, CordX, CordY, initWidth, initHeight, Spd, STAR, initDirection);
end;

Procedure TStar.Draw;
begin
  DrawShape(@self,STARFILE);
end;

{ ------------------- KAMENY ------------------ }

Constructor TStone.Init(var GameState : PGameState; CordX, CordY : integer; ObjKind, Spd : byte);
const
  initDirection = FALSE;
var 
  width, 
  height : byte;
begin
  { Parametry objektu se rozhodnou podle jeho typu }
  case ObjKind of 
  MEDIUM : begin width := 14; height := 7;  damage := 20; end;
  TINY   : begin width := 5;  height := 4;  damage := 10; end;
  BIG    : begin width := 13; height := 11; damage := 30; end;
  end;
  self.Assign(GameState, CordX, CordY, width, height, Spd, STONE, initDirection);
  sort := ObjKind;  
end;

Function TStone.GetDamage : byte; begin GetDamage := damage; end;
Function TStone.GetSort : byte; begin GetSort := sort; end;
Procedure TStone.Draw;
begin
  case sort of
  MEDIUM : DrawShape(@self,MEDIUMSTONEFILE);
  TINY   : DrawShape(@self,TINYSTONEFILE);
  BIG    : DrawShape(@self,BIGSTONEFILE);
  end
end;

{ ------------------- BONUSY ------------------ }

Constructor TBonus.Init(var GameState : PGameState; CordX, CordY : integer; ObjKind, Spd : byte);
const
  initWidth     = 15;
  initHeight    = 15;
  initDirection = FALSE;
begin
  self.Assign(GameState, CordX, CordY, initWidth, initHeight, Spd, BONUS, initDirection);
  sort := ObjKind;
end;

Procedure TBonus.Draw; {zmeniit podobu}
begin
  DrawShape(@self,BONUSFILE); 
end;
{ Aplikuje bonus na lod, na kterou smeruje ukazatel p }
Procedure TBonus.Apply(p : PTShip);
begin
  case sort of 
  HEALTHLOW   : if p^.health > MAXHEALTH-H_LOW  then p^.health := MAXHEALTH 
                else p^.health := p^.health +H_LOW;

  HEALTHHIGH  : if p^.health > MAXHEALTH-H_HIGH then p^.health := MAXHEALTH 
                else p^.health := p^.health +H_HIGH;

  ARMORLOW    : if p^.armor > MAXARMOR-A_LOW  then p^.armor  := MAXARMOR 
                else p^.armor  := p^.armor +A_LOW;

  ARMORHIGH   : if p^.armor > MAXARMOR-A_HIGH then p^.armor  := MAXARMOR 
                else p^.armor  := p^.armor +A_HIGH;

  FURIOUS     : begin p^.bonusDuration := F_DUR; p^.activeBonus := FURIOUS; 
                      p^.bonusGunCooldown := F_GUNCOOLDOWN; end;

  DEATHLESS   : begin p^.bonusDuration := D_DUR; p^.activeBonus := DEATHLESS; end;

  MOVSPEED    : if p^.speed < MAXSPEED then p^.speed  := p^.speed +SPD_INC;
  end;
end;  
{ Vrati text, ktery prislusi k typu bonusu }
Function TBonus.GetStr : string;
begin
  case sort of 
  HEALTHLOW   : GetStr := '+10 health point';
  HEALTHHIGH  : GetStr := '+30 health point';
  ARMORLOW    : GetStr := '+50 armor';
  ARMORHIGH   : GetStr := '+100 armor';
  FURIOUS     : GetStr := 'you are now furious';
  DEATHLESS   : GetStr := 'you are now deathless';
  MOVSPEED    : GetStr := 'you are now faster';
  end;
end;  

{ ------------------- STRELY ------------------ }

Constructor TShot.Init(var GameState : PGameState; CordX, CordY : integer; Dir : boolean; Level : byte);
const
  MinSize  = 6;
  MinShotSpeed  = 5;
  DamageByLevel = 10;
  SpeedByLevel  = 1;
  SizeByLevel   = 1;
var 
  spd,
  size : byte;
begin
  { O sile, rychlosti a velikosti strely rozhoduje parametr Level }
  spd := MinShotSpeed + Level*SpeedByLevel;
  size := MinSize + Level*SizeByLevel;
  damage := Level*DamageByLevel;
  self.Assign(GameState, CordX, CordY, size, size, spd, SHOT, Dir);
  lvl := Level;
end;

Function TShot.GetDamage : byte; begin GetDamage := damage; end;
Procedure TShot.Draw;
begin
  { Barva strel se meni podle urovne }
  SetColor(5);
  SetFillStyle(SolidFill,13);

  if lvl > 1*MAXGUNLVL div 5 then 
  begin
    SetColor(3);
    SetFillStyle(SolidFill,11);
  end;
  if lvl > 2*MAXGUNLVL div 5 then 
  begin
    SetColor(2);
    SetFillStyle(SolidFill,10);
  end;
  if lvl > 3*MAXGUNLVL div 5 then 
  begin
    SetColor(1);
    SetFillStyle(SolidFill,9);
  end;
  if lvl > 4*MAXGUNLVL div 5 then 
  begin
    SetColor(4);
    SetFillStyle(SolidFill,12);
  end;
  
  FillEllipse(x, y, w div 2, h div 2);
end;

{ ------------------ LETADLA ------------------ }

Constructor TShip.Init(var GameState : PGameState; CordX, CordY : integer; 
                       Dir : boolean; ObjKind : byte );
var
  width, 
  height,
  hlth,
  armr,
  gnlvl,
  spd : byte;
begin
  { Nastaveni parametru lodi podle jejiho typu }
  case ObjKind of 
  PLAYER : 
    begin 
      width := 24; 
      height := 32; 
      hlth := MAXHEALTH; 
      spd := MINSPEED; 
      armr := 0; 
      gnlvl := 1 
    end;
  BASIC : 
    begin 
      width := 19; 
      height := 28; 
      hlth := 50;  
      spd := MINSPEED; 
      armr := 0;   
      gnlvl := 1 
    end;
  ADVANCED : 
    begin 
      width := 33; 
      height := 37; 
      hlth := 125; 
      spd := MAXSPEED+ (MAXSPEED-MINSPEED) div 2; 
      armr := 50;  
      gnlvl := MAXGUNLVL div 2 
    end;
  MASTER : 
    begin 
      width := 45; 
      height := 47; 
      hlth := 250; 
      spd := MAXSPEED; 
      armr := 100; 
      gnlvl := MAXGUNLVL 
    end;
  end;
  self.Assign(GameState, CordX, CordY, width, height, Spd, SHIP, Dir);
  health := Hlth;
  armor  := Armr;
  gun    := GnLvl; 
  gunCoolDown := MAXGUNCOOLDOWN div GnLvl;
  gunCounter := 0;
  sort := ObjKind; 
  hurt := FALSE;
  activeBonus := 0;
  xinertia := 0;
  yinertia := 0;
end; 

Procedure TShip.Draw;
var color : byte;
begin
  case sort of
  PLAYER   : DrawShape(@self,PLAYERSHIPFILE);
  BASIC    : DrawShape(@self,BASICSHIPFILE);
  ADVANCED : DrawShape(@self,ADVANCEDSHIPFILE);
  MASTER   : DrawShape(@self,MASTERSHIPFILE);
  end; 
hurt := FALSE;
end;   

{ Pohyb lodi je odlisny od pohybu ostatnich objektu, maji setrvacnost }
Procedure TShip.Move;
var 
  color : byte;  
  newx,newy : integer;
begin
  { Nove vypoctene souradnice }
  newx := x +xinertia;
  newy := y +yinertia;

  { Samotny posun lodi }
  if      newx > GetMaxX-w then x := GetMaxX-w
  else if newx < 0 then x := 0
  else x := newx;
  if      newy > GetMaxY-h then y := GetMaxY-h
  else if newy < 0 then y := 0
  else y := newy;
    
  { Zpomaleni lodi }
  if xinertia > 0 then Dec(xinertia);
  if xinertia < 0 then Inc(xinertia); 
  if yinertia > 0 then Dec(yinertia);
  if yinertia < 0 then Inc(yinertia);    
end;
  
Procedure TShip.SetXInertia(change : shortint);
var val : shortint;
begin
  val := xinertia +change;
  if      val <= -speed*2 then xinertia := -speed*2
  else if val >=  speed*2 then xinertia :=  speed*2
  else xinertia := val
end;

Procedure TShip.SetYInertia(change : shortint);
var val : shortint;
begin
  val := yinertia +change;
  if      val <= -speed*2 then yinertia := -speed*2
  else if val >=  speed*2 then yinertia :=  speed*2
  else yinertia := val
end; 

{ Zasha lodi, snizeni zivotu popr. armoru o hodnotu dmg }  
Procedure TShip.Hit( dmg : integer );
begin
  { Pokud je lod nesmrtelna, nic nedelej }
  if activeBonus = DEATHLESS then exit;
  { Jinak uber zivoty }
  hurt := TRUE;
  if armor >= dmg then armor := armor-dmg
  else 
  begin
    armor := 0;
    if health >= dmg-armor then health := health-(dmg-armor)
    else health := 0;
  end;
end;
  
{ Vytvoreni nove strely, parametr GameState obsahuje pocet Objektu ve hre a pole s ukazateli
  na tyto objekty. Po vytvoreni nove strely se sem objekt zaznamena.
  Pokud je strela vytvorena, vrati funkce TRUE, jinak FALSE }
Function TShip.Shoot(var GameState : PGameState) : boolean;
var tmpShot : PTShot;
begin
  if gunCounter <> 0 then begin Shoot := FALSE; exit; end;
  New(tmpShot, Init(GameState,GetX+(w div 2), GetY+(h div 2), direction, GetGunLevel)); 
  GameState^.PObjectArray[GameState^.NumberOfObjects] := tmpShot;
  if activeBonus = FURIOUS then gunCounter := bonusGunCooldown  
  else                          gunCounter := gunCoolDown; 
  Shoot := TRUE;
end;

Procedure TShip.CooldownDecrement;
begin
  if gunCounter <> 0 then Dec(gunCounter);
end;  

{ Snizi cas, po ktery bude pro lod jeste platit urcity bonus }
Procedure TShip.BonusDurationDecrement;
begin
  if bonusDuration <> 0 then Dec(bonusDuration)
  else if activeBonus <> 0 then activeBonus := 0;
end;  

Function TShip.GetHealth : integer; begin GetHealth := health; end;
Function TShip.GetArmor : integer; begin GetArmor := armor; end;
Function TShip.GetGunCounter : integer; begin GetGunCounter := gunCounter; end;
Function TShip.GetGunLevel : integer; begin GetGunLevel := gun; end;
Function TShip.GetSort : byte; begin GetSort := sort; end;
 



{ ******************************* DEFINICE PROCEDUR A FUNKCI ******************************* }

{ Overi, zda-li jsou objekty o a p v kontaktu, vsechny objekty jsou obdelniky,
  takze se testuje zda se obdelniky prekryvaji }
Function ObjectsOverlap( o,p : PTObject ) : boolean;
begin
  ObjectsOverlap := ((o^.x < (p^.x+p^.w))
                AND ((o^.x+o^.w) > p^.x) 
                AND  (o^.y < (p^.y+p^.h))
                AND ((o^.y+o^.h) > p^.y));
end;

{ Vrati ukazatel na objekt typu TObject, ktery se nachzi v poli GameState^.PObjectArray 
  na indexu id }
Function GetObject(GameState : PGameState; id : integer) : PTObject;
begin
  GetObject := GameState^.PObjectArray[id];
end; 

{ Kazdych LOOPSFORSCOREPOINT taktu (v proc. GameLoop) pricte ke score 1,
  volana z GamLoop, GameState je zde kvuli polozce Score }
Procedure ScoreIncrement(var GameState : PGameState);
const c : byte = 0;
begin
  c := c +1;
  if c = LOOPSFORSCOREPOINT then 
  begin
    Inc(GameState^.Score);
    c := 0;
  end; 
end;

{ Snizi cas, po ktery se jeste bude zobrazovat zprava pro hrace, volana je z proc. 
  GameLoop, udaje o zprave jsou v parametru GameState (^.Msg) }
Procedure MessageTimeDecrement(var GameState : PGameState);
begin
  if GameState^.Msg.duration > 0 then Dec(GameState^.Msg.duration);
end; 

{ Vrati text zpravy, ktera je uchovana v parametru GameState (^.Msg.text) }
Function GetMessageText(GameState : PGameState) : string;
begin
  if GameState^.Msg.duration > 0 then GetMessageText := GameState^.Msg.text
  else GetMessageText := '';
end;

{ Nastavi zpravu, ktera je ulozena v GameState na text z parametru s a cas zobrazeni
  teto zpravy stanovi na t }
Procedure SetMessageWithDuration(var GameState : PGameState; s : string; t : integer);
begin
  GameState^.Msg.duration := t;
  GameState^.Msg.text := s;
end;

{ Vykresleni veci spolecnych pro vsechna menu (tj. akorat pozadi) }
Procedure DrawMenuBackgorund;
var i,j : integer;
begin
  SetFillStyle(SolidFill,15);
  i := 480; j := 300; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 120; j := 40; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 96; j := 70; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 260; j := 90; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 350; j := 260; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 555; j := 160; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  i := 535; j := 80; Bar(i+2,j,i+2,j+4); Bar(i,j+2,i+4,j+2);
  SetColor(8);
  SetFillStyle(SolidFill,8);
  FillEllipse(105,255,140,140);
  SetFillStyle(SolidFill,7);  
  for i:=115 to 115+240-1 do
  begin
    SetColor(8);
    SetFillStyle(SolidFill,7); 
    Bar(105,i,round(sqrt( 140*140-(115-i+140)*(115-i+140) )+105),i+2);
    SetColor(8);
    SetFillStyle(SolidFill,8);
    Bar(105,i,round(sqrt( 275*275-(-i+275-20)*(-i+275-20)))-275+155,i+2);
    i := i +2; { dvojtou hrubost pixelu, jinak to zabere moc casu a blika to }
  end; 
  SetFillStyle(SolidFill,0);  
  Bar(0,115+140,250,115+140+3);
  SetFillStyle(SolidFill,7); 
  FillEllipse(150,185,35,35);
  SetColor(8);
  SetFillStyle(SolidFill,0); 
  FillEllipse(150,185,7,7);
  SetColor(0);
  SetFillStyle(SolidFill,8); 
  FillEllipse(150,185,5,5);        
  SetColor(14);          
  SetLineStyle(0,1,2);
  Line(117,191,163,175);
  Line(135,155,163,175);
  Line(167,155,163,175);
  Line(184,182,163,175);
  Line(150,219,163,175);
  Line(175,208,163,175);
  Line(163,175,535,0);
end;  

{ Vykreslovaci funkce pro Hlavni menu, MenuItem je index aktualne vybrane polozky }
Procedure DrawMainMenu(MenuItem : shortint);
begin
  { Vykresleni pozadi }
  DrawMenuBackgorund;
  { Vykresleni polozek Menu, polozka s indexem MenuItem ma kolem sebe > a < }
  SetTextStyle(DefaultFont, HorizDir, 2);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY( (GetMaxX div 3)*2, GetMaxY div 2 -75+50*MenuItem, '>          <');
  OutTextXY( (GetMaxX div 3)*2, GetMaxY div 2 -75, 'Play');
  OutTextXY( (GetMaxX div 3)*2, GetMaxY div 2 -25, 'Controls');
  OutTextXY( (GetMaxX div 3)*2, GetMaxY div 2 +25, 'Scores');
  OutTextXY( (GetMaxX div 3)*2, GetMaxY div 2 +75, 'Quit');
end;  

{ Vykreslovaci funkce pro menu s Ovladanim }
Procedure DrawControlsMenu;
begin
  { Vykresleni pozadi }
  DrawMenuBackgorund;
  { Vykresleni Ovladani a 'tlacitka' Return }
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  OutTextXY( GetMaxX div 2, GetMaxY div 2 -100, 'Move up ............ top arrow');
  OutTextXY( GetMaxX div 2, GetMaxY div 2 -75,  'Move down ......... down arrow');
  OutTextXY( GetMaxX div 2, GetMaxY div 2 -50,  'Move left ......... left arrow');
  OutTextXY( GetMaxX div 2, GetMaxY div 2 -25,  'Move right ....... right arrow');
  OutTextXY( GetMaxX div 2, GetMaxY div 2    ,  'Use gun ................ space');
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutTextXY( GetMaxX div 2, GetMaxY div 2 +90, '>  Return  <');
end;  

{ Vykreslovaci funkce pro menu se Score }
Procedure DrawScoresMenu;
var 
  f : text;
  i,j,c : integer;
  line, s,
  NameStr,
  ScoreStr,
  LineStr  : string;
  nameRead : boolean;
begin
  { Vykresleni pozadi }
  DrawMenuBackgorund;

  SetTextStyle(DefaultFont, HorizDir, 1);
  SetColor(15);
  SetTextJustify(CenterText, CenterText);
  
  { Soubor SCORESFILE je definovany na zacatku dokumentu v Deklaraci konstant }
  Assign(f, SCORESFILE);
  Reset(f);

  c := 0; { Na pocitani vypsanych polozek }
  { Vypisuje maximalne 6 prvnich polozek, nic neradi }
  while (NOT eof(f)) AND (c < 6) do 
  begin
    readln(f, line);
    nameRead := FALSE;
    ScoreStr := '';
    NameStr  := '';
    for i := 1 to Length(line) do 
    begin
      if (line[i] in ['0'..'Z']) AND (NOT nameRead) then NameStr := Concat(NameStr,line[i])
      else nameRead := TRUE;
      if (line[i] in ['0'..'9']) AND nameRead then ScoreStr := Concat(ScoreStr,line[i])
    end;
    LineStr := '';
    Str(c+1,s);
    for j := 1 to 22-Length(NameStr)-Length(ScoreStr) do LineStr := Concat(LineStr,'.');
    LineStr := Concat(s, '. ', NameStr, '    ', LineStr, '    ', ScoreStr);
    OutTextXY( GetMaxX div 2, GetMaxY div 2 -110 +c*25, LineStr);
    Inc(c);
  end;
  
  Close(f);

  SetTextStyle(DefaultFont, HorizDir, 2);
  OutTextXY( GetMaxX div 2, GetMaxY div 2 +90, '>  Return  <');
end;  

{ Vykreslovaci funkce pro samotnou Hru, GameState obsahuje udaje o stavu hry,
  vizte Deklaraci typu na zacatku dokumentu }
Procedure DrawGame(GameState : PGameState);
var 
  i : integer;
  s,r : string;
  tempShip : PTShip;
begin
  { Cykly jsou volane postupne pro vsechny typy objektu, aby byly vykresleny ve spravnem
    poradi a napr. hvezdy neprekryvaly lode, kameny bonusy atd. }
  { Vykresli hvezdicky }
  for i := 1 to GameState^.NumberOfObjects do 
    if GetObject(GameState,i)^.GetType = STAR then GetObject(GameState,i)^.Draw;
  { Vykresli kameny }
  for i := 1 to GameState^.NumberOfObjects do 
    if GetObject(GameState,i)^.GetType = STONE then GetObject(GameState,i)^.Draw; 
  { Vykresli bonusy }
  for i := 1 to GameState^.NumberOfObjects do 
    if GetObject(GameState,i)^.GetType = BONUS then GetObject(GameState,i)^.Draw;   
  { Vykresli lode }
  for i := 1 to GameState^.NumberOfObjects do 
    if GetObject(GameState,i)^.GetType = SHIP then GetObject(GameState,i)^.Draw;
  { Vykresli strely }
  for i := 1 to GameState^.NumberOfObjects do 
    if GetObject(GameState,i)^.GetType = SHOT then GetObject(GameState,i)^.Draw;    

  SetTextStyle(DefaultFont, HorizDir, 1);      
  SetColor(15);
  SetTextJustify(BottomText, RightText);

  { Pokud hra neskoncila, vypise udaje o lodi hrace (MainShip) }
  if NOT GameState^.GameOver then
  begin

    tempShip := GameState^.Mainship;
    OutTextXY(3,3, 'Health: '); Str(tempShip^.GetHealth, s); OutTextXY(73,3,s);   
    Str(MAXHEALTH, r); s := Concat('/',r); OutTextXY(100,3,s);

    OutTextXY(3,13,'Armor: '); Str(tempShip^.GetArmor, s); OutTextXY(73,13,s); 
    Str(MAXARMOR, r); s := Concat('/',r); OutTextXY(100,13,s);

    OutTextXY(165,3,'Speed: '); Str(tempShip^.GetSpeed-MINSPEED+1, s); OutTextXY(223,3,s); 
    Str(MAXSPEED-MINSPEED+1, r); s := Concat('/',r); OutTextXY(240,3,s);

    OutTextXY(165,13,'Gun: '); Str(tempShip^.GetGunCounter, s); OutTextXY(223,13,s); 
    OutTextXY(240,13,'/'); Str(tempShip^.gunCoolDown, s); OutTextXY(248,13,s); 

    OutTextXY(290,3,'Gun lvl: '); Str(tempShip^.GetGunLevel, s); OutTextXY(388,3,s);        
    Str(MAXGUNLVL, r); s := Concat('/',r); OutTextXY(405,3,s);

    OutTextXY(GetMaxX div 2 -70,GetMaxY-20,'Total score: ');
    Str(GameState^.Score, s);
    OutTextXY(GetMaxX div 2 +45,GetMaxY-20,s);
    SetTextStyle(DefaultFont, HorizDir, 2);  
    SetTextJustify(CenterText, CenterText);
    OutTextXY(GetMaxX div 2,GetMaxY div 2, GetMessageText(GameState));

  end else begin
  { Jinak vypise menu GameOver s dosazenym skore, 'tlacitkem' pro navrat do Hlavniho menu
    a jmenem hrace o max. delce 10 znaku, ktere na teto strance muze zadat (PlayerName) }

    SetTextStyle(DefaultFont, HorizDir, 2);  
    SetTextJustify(CenterText, CenterText);
    OutTextXY(GetMaxX div 2,50,'Game Over');
    Str(GameState^.Score, r); s := Concat('Your total score: ',r);    
    OutTextXY(GetMaxX div 2,100,s);
    SetTextStyle(DefaultFont, HorizDir, 1); 
    OutTextXY(GetMaxX div 2,170,'Enter your name and press Enter to continue.');
    SetTextStyle(DefaultFont, HorizDir, 2); 
    r := '';
    for i := 1 to Length(GameState^.PlayerName) do 
      r := Concat(r,GameState^.PlayerName[i],' ');
    SetTextJustify(BottomText, RightText);
    OutTextXY(GetMaxX div 2-155,205,r); 
    OutTextXY(GetMaxX div 2-155,210,'_ _ _ _ _ _ _ _ _ _');
    SetTextJustify(CenterText, CenterText); 
    OutTextXY(GetMaxX div 2,300,'>    Main menu    <');

  end;
end; 

{ OBNOVENI OBRAZOVKY A NOVE VYKRESLENI 
  Location udava pozici v programu, MenuItem (pouze u Hlavniho menu) pripadnou aktualne
  vybranou polozku menu, GameState (pouze u samotne Hry) prenasi udaje o stavu hry - tj.
  ukazatele na objekty, pocet objektu ... vizte DEKLARACE TYPU na zacatku programu }
Procedure Refresh(Location, MenuItem : shortint; GameState : PGameState); 
const page : byte = 0; { vykreslovaci stranka }
begin
  { Zmeni stranku, do ktere vykresli obejkty a pak ji zobrazi, page nabyva hodnoty 0 a 1 
    zvoleny graficky mod podporuje 2 vykreslovaci stranky }
  page := page XOR 1;
  { Nastavi durhou stranku jako aktivni (vykresleni) }
  SetActivePage(page);
  { Vycisteni stranky }
  ClearDevice;  
  { Vybere vykreslovaci funkci }
  case Location of
  0 : DrawMainMenu(MenuItem);
  1 : DrawGame(GameState);    
  2 : DrawControlsMenu;
  3 : DrawScoresMenu;            
  end;
  { Zobrazi nove vykreslenou stranku a schova starou }
  SetVisualPage(page);
end;

{ Ridi chovani hlavniho menu, Location je pozice v programu, vizte proceduru MainLoop }
Procedure ManageMainMenu(var Location : shortint);
const 
  MenuItem : shortint = 0;
  firstRun : boolean = TRUE;   
begin
  { Obnoveni a vykresleni stranky
    Location urcuje o ktere menu se jedna
    MenuItem urcuje aktualne vybranou polozku menu
    Treti parametr prenasi stav hry, ktera ted nebezi, proto je tam NIL }
  Refresh(Location,MenuItem,NIL);  

  { Uvodni znelka pri prvnim behu }
  if firstRun then
  begin
    Sound(300);
    delay(200);
    Sound(200);
    delay(200);
    Sound(100);
    delay(200);
    Sound(600);
    delay(500);
    firstRun := FALSE;
  end;

  NoSound;

  { Pokud se stiskne Enter, Location se zmeni a v procedure MainLoop se zacne volat
    prislusna procedura pro submenu, resp. hru }
  if KEYDOWN[EnterKeyCode] OR WASDOWN[EnterKeyCode] then Location := MenuItem+1;
  WASDOWN[EnterKeyCode] := FALSE;

  { Posun v polozkach menu sipkami }
  if WASDOWN[DownArrowKeyCode] AND NOT KEYDOWN[DownArrowKeyCode] then
  begin
    MenuItem := (MenuItem +1) mod 4;
    Sound(110);
  end; 
  if WASDOWN[UpArrowKeyCode]   AND NOT  KEYDOWN[UpArrowKeyCode]  then 
  begin
    MenuItem := (MenuItem -1) mod 4;
    Sound(110);
  end;
  if NOT KEYDOWN[UpArrowKeyCode]   then WASDOWN[UpArrowKeyCode] := FALSE;
  if NOT KEYDOWN[DownArrowKeyCode] then WASDOWN[DownArrowKeyCode] := FALSE;   

  { Pokud chci prejit na polozku pred 1. polozkou, skoci na posledni polozku menu } 
  if MenuItem < 0 then MenuItem := 3;  
end;

{ Ridi chovani menu s ovladanim, Location je pozice v programu, vizte proceduru MainLoop }
Procedure ManageControlsMenu(var Location : shortint);
begin  
  { Pokud stiknu Enter nebo ESC skoci do Hlavniho menu
    Menu ma jedinou polozku Return, proto po stisku Enteru rovno do hl. menu }
  if (WASDOWN[EnterKeyCode]  AND NOT KEYDOWN[EnterKeyCode])  OR 
     (WASDOWN[EscapeKeyCode] AND NOT KEYDOWN[EscapeKeyCode]) then 
  begin 
    Location := 0;
    WASDOWN[EscapeKeyCode] := FALSE;
    WASDOWN[EnterKeyCode]  := FALSE;
  end;  
  { Obnoveni a vykresleni stranky
    Location urcuje o ktere menu se jedna
    MenuItem urcuje aktualne vybranou polozku menu
    Treti parametr prenasi stav hry, ktera ted nebezi, proto je tam NIL }
  Refresh(Location,0,NIL);
end;        
 
{ Ridi chovani menu se score, Location je pozice v programu, vizte proceduru MainLoop }  
Procedure ManageScoresMenu(var Location : shortint); 
begin  
  { Pokud stiknu Enter nebo ESC skoci do Hlavniho menu
    Menu ma jedinou polozku Return, proto po stisku Enteru rovno do hl. menu }
  if (WASDOWN[EnterKeyCode]  AND NOT KEYDOWN[EnterKeyCode])  OR 
     (WASDOWN[EscapeKeyCode] AND NOT KEYDOWN[EscapeKeyCode]) then 
  begin 
    Location := 0;
    WASDOWN[EscapeKeyCode] := FALSE;
    WASDOWN[EnterKeyCode]  := FALSE;
  end; 
  { Obnoveni a vykresleni stranky
    Location urcuje o ktere menu se jedna
    MenuItem urcuje aktualne vybranou polozku menu
    Treti parametr prenasi stav hry, ktera ted nebezi, proto je tam NIL }
  Refresh(Location,0,NIL);
end;  

{ Vytvori dany objekt (parametr ObjectType) s pravdepodobnosti Probability.
  GameState obsahuje udaje o stavu hry, vizte Deklaraci typu na zacatku dokumentu, je to tu
  kvuli ulozeni ukazatele na novy objekt }
Procedure CreateObjectWithProbability(var GameState : PGameState; ObjectType : byte; Probability : real);
var 
  TempStar  : PTStar;
  TempStone : PTStone;
  TempBonus : PTBonus;
  TempShip  : PTShip;
  KindOfShip : byte;
begin
  if Random > Probability then exit;
  case ObjectType of 
  STAR  : begin { Vytvoreni hvezdicky }
    New(TempStar,  Init(GameState, GetMaxX-1,   Random(GetMaxY-1), 1));
    GameState^.PObjectArray[GameState^.NumberOfObjects] := TempStar; 
  end; 
  STONE : begin { Vytvoreni kamenu, kazdy typ kamenu ma stejnou p. vzniku }
    New(TempStone, Init(GameState, GetMaxX-1,   Random(GetMaxY-1), 1+Random(3), 3+Random(6)));
    GameState^.PObjectArray[GameState^.NumberOfObjects] := TempStone; 
  end;
  BONUS : begin { Vytvoreni bonusu, kazdy typ bonusu ma stejnou p. vzniku }
    New(TempBonus, Init(GameState, GetMaxX-1,   Random(GetMaxY-1), 1+Random(7), 1+Random(5)));
    GameState^.PObjectArray[GameState^.NumberOfObjects] := TempBonus;
  end;
  SHIP : begin  { Vytvoreni lodi }
    { V nejpokrocilejsi fazi hry vytvari lodi BASIC, ADVANCED s p. 0.25 a MASTER s p. 0.5 }
    if Probability < 0.01 then
    begin
      KindOfShip := BASIC; 
      if Random < 0.75  then KindOfShip := MASTER;
      if Random < 0.25 then KindOfShip := ADVANCED;
    end;
    { V pokrocilejsi fazi hry vytvari lodi BASIC, ADVANCED s p. 0.2 a MASTER s p. 0.05 }
    if Probability < 0.0075 then
    begin
      KindOfShip := BASIC;
      if Random < 0.25 then KindOfShip := ADVANCED;
      if Random < 0.05  then KindOfShip := MASTER;
    end;
    { Na zacatku hry vytvari lodi typu BASIC }
    if Probability < 0.005 then KindOfShip := BASIC;

    New(TempShip,  Init(GameState, GetMaxX-1, Random(GetMaxY-1), FALSE, KindOfShip));
    GameState^.PObjectArray[GameState^.NumberOfObjects] := TempShip;
  end;
  end;
end;

{ Ridi akce provadene letadly, je ovlana z proc. ManageAllObjectsActions
  Prametr Ship je pointer na lod, o jejiz akcich se ma rozhodnout
  GameState obsahuje udaje o stavu hry, vizte Deklaraci typu na zacatku dokumentu }
Procedure ManageShipActions( Ship : PTShip; GameState : PGameState );
var 
  x,y,
  mx,my,
  spd,
  rndx,rndy,
  range : integer;
begin
  { Snizi hodnotu promenne, ktera uchovava cas do dalsi moznosti vystreleni }
  Ship^.CooldownDecrement;
  { Rychlost lode, ktera ma vykonat akci }   
  spd := Ship^.GetSpeed;
  { Souradnice lode, ktera ma vykonat akci }
  x := Ship^.GetX;
  y := Ship^.GetY;   
  { Souradnice lode hrace }
  mx := GameState^.MainShip^.GetX;
  my := GameState^.MainShip^.GetY;
  { Lod strili, pokud je hracova lod v rovnoramennem trojuhelniku, jehoz vrchol je ve
    stredu teto lodi a zakladna o rozmeru poloviny vysky obrazovky je ve vzdalenosti sirky
    obrazovky od stredu teto lodi }
  range := GetMaxY div 2;
  if (my > y-(round(range*((x-mx)/GetMaxX))) div 2) AND (my < y+(round(range*((x-mx)/GetMaxX))) div 2) then 
    Ship^.Shoot(GameState); { Vystrel }

  { Pokud se snazi hracova lod dostat za tuto lod, jede dozadu (resp. doprava) }
  if mx > x then Ship^.SetXInertia(spd)
  else if Random < 0.5 then { Jinak se s p. 0.5 nekam pohne }
  begin
    { Pokud je hracova lod nic, resp. vys, lod se snazi tyto urovne srovnat }
    if (my > y) AND (Random < 0.2) then Ship^.SetYInertia(spd);
    if (my < y) AND (Random < 0.2) then Ship^.SetYInertia(-spd);
    { Nahodny pohyb v horizontalni urovni. Pokud je lod hodne vpravo (50px od okraje), 
      snazi se dostat vic vlevo }
    if (x > GetMaxX-50) AND (Random < 0.5) then Ship^.SetXInertia(-spd)
    else begin
      if Random < 0.2 then Ship^.SetXInertia(-spd);
      if Random < 0.2 then Ship^.SetXInertia(spd);
    end
  end;  
  { Samotne pohnuti lode }
  Ship^.Move;
end;

{ Rezie vsech objektu krome letadla hrace, jehoz rizeni se nachazi v proc. GameLoop
  Proc. projde vsechny objekty, pokud se jedna o lod, vola proc. ManageShipActions, jinnak
  zavola Move pripadneho objektu a pokud je mimo obrazovku, znici ho
  GameState obsahuje udaje o stavu hry, vizte Deklaraci typu na zacatku dokumentu }
Procedure ManageAllObjectsActions(GameState : PGameState);
var
  i : integer; 
  PObject : PTObject;
begin
  for i := 1 to GameState^.NumberOfObjects do
  begin
    PObject := GetObject(GameState,i);
    if PObject^.GetType = SHIP then 
    begin
      if NOT PObject^.direction then ManageShipActions(PTShip(PObject), GameState);
    end  
    else
    begin
      PObject^.Move;
      if (PObject^.GetX > GetMaxX) OR (PObject^.GetX < 0) then 
        dispose(PObject, Cleanup(GameState));
    end
  end;             
end;

{ Zjisti zda jsou splnene podminky pro konec hry, tj. zda ma hracova lod 0 zivotu a
  v parametru GameState nastavi GameOver na TRUE }
Function CheckGameOverCondition(var GameState : PGameState) : boolean;
begin
  if GameState^.MainShip^.GetHealth = 0 then 
  begin
    { Konecna znelka }
    Sound(500);
    delay(300);
    Sound(400);
    delay(300);
    Sound(300);
    delay(300);
    Sound(100);
    delay(300);
    NoSound;
    { Zniceni letadla hrace a nastaveni promennych k ukonceni }
    GameState^.GameOver := TRUE;
    dispose(GameState^.Mainship, Cleanup(GameState));
    CheckGameOverCondition := TRUE;
  end 
  else CheckGameOverCondition := FALSE;
end;

{ Projde vsechny objekty, ktere ziska z parametru GameState a pokud se sebe dotykaji, 
  podle jejich typu rozhodne, co s nimi }
Procedure CheckAllObjectsOverlaps(var GameState : PGameState);
var 
  i,j : integer;
  PObject,
  PObject2 : PTObject;
begin
  for i := 1 to GameState^.NumberOfObjects do
  begin
    PObject := GetObject(GameState,i);  

    case PObject^.GetType of
    STONE: 
      begin
        { Pokud se kamen dotkne lode hrace, vola proc. Hit (ktera ubere lodi zivoty,
          popr. armor) a otestuje, jestli nejsou splneny podminky pro ukonceni hry - GameOver }
        if ObjectsOverlap( PObject, GameState^.MainShip ) then
        begin 
          GameState^.MainShip^.Hit( PTStone(PObject)^.GetDamage );  
          Sound(50);
          dispose(PObject, Cleanup(GameState));
          if CheckGameOverCondition(GameState) then exit; 
        end;
        { Proveri vsechny strely hrace (strely nepratelskych lodi ignoruje) a pokud se 
          kamen se strelou prekryva, oba objekty se znici a ke score se pricte STONESCORE }
        for j := 1 to GameState^.NumberOfObjects do
        begin
          PObject2 := GetObject(GameState,j);
          if PObject2^.GetType <> SHOT then continue;
          if PObject2^.direction AND ObjectsOverlap( PObject2, PObject ) then
          begin
            dispose(PObject,  CleanUp(GameState));
            dispose(PObject2, CleanUp(GameState));
            i := 1; { Vsechny objekty se musi projit znovu, jelikoz dispose mohl zmenit
                      indexy v poli PObjectsArray nepriznivym zpusobem }
            GameState^.Score := GameState^.Score +STONESCORE;
            break;
          end; 
        end;
      end;

    BONUS:
      begin
        { Pokud se Bonus dotkne lode hrace, je prislusny bonus na lod aplikovan, zobrazi se
          zprava pro hrace, aby byl s touto udalosti zpraven a bonus se znici }
        if ObjectsOverlap( PObject, GameState^.MainShip ) then
        begin 
          PTBonus(PObject)^.Apply(GameState^.MainShip); 
          SetMessageWithDuration(GameState,PTBonus(PObject)^.GetStr,BONUSMESSGAEDURATION); 
          dispose(PObject, Cleanup(GameState));
        end;
      end;

    SHIP:
      begin
        for j := 1 to GameState^.NumberOfObjects do
        begin
          PObject2 := GetObject(GameState,j);
          { Pokud se lod prekryva se strelou, ktera prislusi opacne strane (direction), vola se 
            Hit (lod ztrati zivoty porp. armor) a strela se vymaze. Zjisti se zda nejsou 
            splnene podminky pro konec hry (GameOver) a pokud ano, hra se ukonci. Pokud ma 
            zasazena lod 0 zivotu, smaze se a ke score s pricte SHIPSCORE za jeji zniceni }
          if PObject2^.GetType <> SHOT then continue;
          if (PObject2^.direction <> PObject^.direction) AND 
              ObjectsOverlap( PObject2, PObject ) then
          begin
            PTShip(PObject)^.Hit( PTShot(PObject2)^.GetDamage );
            dispose(PObject2, CleanUp(GameState));
            if CheckGameOverCondition(GameState) then exit
            else 
              if PTShip(PObject)^.GetHealth = 0 then 
              begin
                dispose(PObject, CleanUp(GameState));
                GameState^.Score := GameState^.Score +SHIPSCORE;
              end;
              i := 1; { Vsechny objekty se musi projit znovu, jelikoz dispose mohl zmenit
                      indexy v poli PObjectsArray nepriznivym zpusobem }
            break;
          end
        end
      end
    end
  end
end;

{ Ulozi score po konci hry do souboru SCORESFILE, je volana z konce proc. GameLoop. Proc.
  nejprve precte soubor, ziska z nej validni zaznamy, prida k nim tento jeden novy (predany 
  parametrem GameState - score a PlayerName) a seradi je podle nejvyssiho score. 
  Zazanamy jsou ulozeny jako JMENO 00, kde 00 je score, kazdemu zazanamu prislusi jeden radek }
Procedure SaveScore(GameState : PGameState);
type 
  PItem = ^TItem;
  TItem = record  
    n : string;
    s : word;
    next : PItem;
  end;
var 
  i,j,c : integer;
  f : text;
  line,str : string;
  item : PItem;
  nameRead : boolean;
  p,q,r,s : PItem;
begin
  { Pokud hrac nezdal jmeno, ulozi se jako ANONYMOUS }
  if GameState^.PlayerName = '' then str := 'ANONYMOUS'
  else str := GameState^.PlayerName;
  { Vytvoreni objktu, ktery odpovida novemu zaznamu, ktery se prave pridava }
  New(item);
  q^.next := item;
  item^.n := str;
  item^.s := GameState^.Score;
  item^.next := NIL;

  Assign(f, SCORESFILE);
  Reset(f);

  c := 0;
  p := q;
  q := q^.next;

  { Vytvoreni spojoveho seznamu s zazanmy ze souboru }
  while NOT eof(f) do 
  begin
    readln(f, line);
    New(item);
    q^.next := item;
    item^.n := '';
    item^.s := 0;
    item^.next := NIL;
    nameRead := FALSE;
    for i := 1 to Length(line) do 
    begin
      if (line[i] in ['0'..'Z']) AND (NOT nameRead) then item^.n := Concat(item^.n,line[i])
      else nameRead := TRUE;
      if (line[i] in ['0'..'9']) AND nameRead then item^.s := item^.s*10 + ord(line[i])-ord('0');
    end;
    q := q^.next;
    Inc(c);
  end;

  Close(f);
  
  { Setrideni spojoveho seznamu Bubble sortem. V souboru by nemelo byt vic zaznamu nez 10 }
  for i:=1 to c-1 do
  begin
    q := p;
    while q^.next^.next <> NIL do
    begin
      if  q^.next^.s < q^.next^.next^.s then
      begin
        r := q^.next^.next;
        q^.next^.next := q^.next^.next^.next;
        s := q^.next;
        q^.next := r;
        q^.next^.next := s;
      end;
      q := q^.next;
    end;
  end;

  Rewrite(f);

  i := 1;
  q := p;
  { Zapis prvnich 10 polozek ze setrideneho spojoveho seznamu do souboru }
  while (q^.next <> NIL) AND (i <= 10) do
  begin
    writeln(f, q^.next^.n, ' ', q^.next^.s);
    q := q^.next;
    Inc(i);
  end;

  Close(f);
end;

{ Pocatecni inicializace hry, volane z proc. GameLoop. 
  GameState obsahuje udaje o stavu hry, vizte Deklaraci typu na zacatku dokumentu }
Procedure GameInit(var GameState : PGameState);
var 
  i : integer; 
  PStar : PTStar;
  PShip : PTShip; 
  Msg   : TMsg;
begin
  GameState^.GameOver := FALSE;
  GameState^.Score := 0;
  GameState^.NumberOfObjects := 0; 
  Msg.duration := 0;
  Msg.text := '';
  GameState^.Msg := Msg;
  GameState^.PlayerName := '';
  
  { Vytvoreni lode hrace }
  New(PShip, Init(GameState, 50, GetMaxY div 2 -15, TRUE, PLAYER));
  GameState^.PObjectArray[GameState^.NumberOfObjects] := PShip;
  GameState^.MainShip := PShip;

  { Vytvoreni zacatecnich hvezdicek }
  for i := 1 to GetMaxX-2 do 
  begin
    if Random < 0.02 then 
    begin
      New(PStar, Init(GameState, i, Random(GetMaxY-1), 1));  
      GameState^.PObjectArray[GameState^.NumberOfObjects] := PStar;
    end;
  end;        
end;

{ Vylepsi zbran lode hrace (GameState^.MainShip) na zadany level (level), 
  pokud je to mozne. Zobrazi zpravu pro hrace (GameState^.Msg) }
Procedure PromoteGunToLevel(GameState : PGameState; level : byte);
begin
  if (GameState^.MainShip^.GetGunLevel >= level) OR (level > MAXGUNLVL) then exit
  else 
  begin
    GameState^.MainShip^.gun := level;
    GameState^.MainShip^.gunCoolDown := MAXGUNCOOLDOWN div level;
    SetMessageWithDuration(GameState, 'Ships gun has been upgraded', LEVELMESSAGEDURATION);
  end  
end;

{ Vylepsi rychlost lode hrace (GameState^.MainShip) na zadany level (level), 
  pokud je to mozne. Zobrazi zpravu pro hrace (GameState^.Msg) }
Procedure PromoteSpeedToLevel(GameState : PGameState; level : byte);
begin
  if (GameState^.MainShip^.GetSpeed >= level) OR (level > MAXSPEED) then exit
  else 
  begin 
    GameState^.MainShip^.speed := level;
    SetMessageWithDuration(GameState, 'Ships speed has been upgraded', LEVELMESSAGEDURATION);
  end;
end;

{ SMYCKA SAMOTNE HRY, volana je z proc. MainLoop
  Parametr Location udava pozici v progrmmu (vizte MainLoop). }
Procedure GameLoop(var Location : shortint);
const
  MaxStoneProb = 0.2;
  MinStoneProb = 0.025;
  StarProb     = 0.02;
  MaxBonusProb = 0.001;
  MinBonusProb = 0.0005;
  MaxShipProb  = 0.01;
  MinShipProb  = 0.001;
var 
  i,j : integer;
  k   : real;
  c   : char;
  TheEnd    : boolean;    { Oznacuje absolutni konec hry, tj. kdyz je GameOver TRUE a hrac 
                            zadal svoje jmeno do zaverecneho dialogu, resp. se rozhodl 
                            presunout ze hry do Hlavního menu }
  GameState : PGameState; { Uchovava informace o stavu hry - pocet objektu, pole ukazatelu na 
                            vsechny objekty, info o konci hry, ukazatel na lod hrace, score, 
                            zpravu pro hrace, ktera se obcas zobrazuje, jmeno hrace (nastavuje
                            az po prohre hrace) }
  PShot     : PTShot;  
begin
  TheEnd := FALSE;      
  GameInit(GameState);  { Nastaveni pocatecnich hodnot promenne GameState, vytvoreni
                          nezbytnych obejktu }
  ClearWasDownArray;    { Vycisti pole stisklych klaves (napr. kvuli stisku mezerniku v 
                          Hlavnim menu by bez tohoto volani po startu hry lod hrace vystrelila) }
  Repeat

    tickwait(1); { Casovac, pochazi z Unity Time, pocita se podle procesoru }  
    NoSound; 

    if NOT GameState^.GameOver then
    begin

    { Vytvoreni objektu s urcitou pravdepodobnosti }
    CreateObjectWithProbability(GameState, STAR,  StarProb); 

    if GameState^.Score < 10000 then 
      k := GameState^.Score/10000*(MaxBonusProb-MinBonusProb)+MinBonusProb 
    else 
      k := MaxStoneProb;
    CreateObjectWithProbability(GameState, BONUS, k);

    if GameState^.Score < 500 then 
      k := GameState^.Score/500*(MaxStoneProb-MinStoneProb)+MinStoneProb 
    else 
      k := MaxStoneProb;
    CreateObjectWithProbability(GameState, STONE, k); 

    if GameState^.Score < 5000 then 
      k := GameState^.Score/5000*(MaxShipProb-MinShipProb)+MinShipProb 
    else 
      k := MaxStoneProb;
    CreateObjectWithProbability(GameState, SHIP, k); 
    
    { Rezie (posun, destrukce, strelba, ...) vsech objektu krome vlastniho letadla }
    ManageAllObjectsActions(GameState);

    { Rezie vlastniho letadla }
    With GameState^.Mainship^ do
    begin
      { Nastaveni 'setrvacnosti' letadla pri stisku sipek
        viz prislusne metody objektu TShip }
      if KEYDOWN[UpArrowKeyCode]    then SetYInertia(-GetSpeed);  
      if KEYDOWN[LeftArrowKeyCode]  then SetXInertia(-GetSpeed);
      if KEYDOWN[RightArrowKeyCode] then SetXInertia(GetSpeed);
      if KEYDOWN[DownArrowKeyCode]  then SetYInertia(GetSpeed);
      { Pohnuti letadlem }
      Move;
      { Snizi hodnotu promenne, ktera uchovava cas do dalsi moznosti vystreleni }
      CooldownDecrement;
      { Pokud je nebo byl stisknuty mezernik, vystreli }
      if KEYDOWN[SpaceKeyCode] OR WASDOWN[SpaceKeyCode] then 
      begin
        if Shoot(GameState) then Sound(110);
        WASDOWN[SpaceKeyCode] := FALSE;
      end; 
      { Snizi hodnotu promenne, ktera uchovava zbyvajici cas bonusu aplikovaneho na lod }
      BonusDurationDecrement;
      { Povyseni zbrani, pokud uz nejsou lepsi }
      k := GameState^.Score/2500;
      PromoteGunToLevel(GameState, round(k*MAXGUNLVL+1));
      { Zvyseni rychlosti, pokud neni lepsi }
      k := GameState^.Score/4500;
      PromoteSpeedToLevel(GameState, round(k*MAXSPEED+1));
    end;

    { Zkontroluje kontakty objektu }
    CheckAllObjectsOverlaps(GameState);    
    { Pripadne shovani zpravy } 
    MessageTimeDecrement(GameState);
    { Pricteni ke score }            
    ScoreIncrement(GameState);

    end else begin
    { Pokud hrac prohral, tzn. jeho lod byla znicena, tak se dotaze na jeho jmeno, ktere
      pozdeji pouzije a ulozi do souboru SCORESFILE }

    { Pri stisku Enteru prejde dal, smycka hry se ukonci }
    if WASDOWN[EnterKeyCode] then TheEnd := TRUE; 
    { Stiskem Backspace se smaze posledni zadany znak }
    if WASDOWN[BackspaceKeyCode] then 
    begin
      GameState^.PlayerName := copy(GameState^.PlayerName,1,Length(GameState^.PlayerName)-1);
      WASDOWN[BackspaceKeyCode] := FALSE;
    end;
    { Pokud hrac zadal mene nez 10 znaku, odchytava dalsi, pouze znaky ASCII }
    if Length(GameState^.PlayerName) < 10 then 
    begin
      c := GetPressedKey; { Projde pole WASDOWN a vrati stiskly ASCII znak  }
      { Znak prida na konec jmeno hrace (PlayerName) }
      if c <> ' ' then GameState^.PlayerName := Concat(GameState^.PlayerName,c);
    end;

    end;

    { Obnoveni a vykresleni stranky
    Location urcuje o ktere menu se jedna, GameState prenasi stav hry }
    Refresh(Location, 0, GameState);

  { Pokud byla behem hry stisknuta klavesa ESC nebo hra skoncila, prerusi smycku hry }
  Until (WASDOWN[EscapeKeyCode] OR TheEnd);

  { Pokud hra skoncila ulozi score }
  if TheEnd then SaveScore(GameState);

  ClearWasDownArray;
  { Prepne do Hlaniho menu }
  Location := 0;
end;
  
{ HLAVNI SMYCKA PROGRAMU }  
Procedure MainLoop; 
var Location,             { Uchovava pozici v programu: 
                            0 - hlavni menu
                            1 - hra
                            2 - menu s ovladanim
                            3 - menu se skore
                            4 - tlacitko quit }
    MenuItem : shortint;  { Uchovava index aktualne
                            vybrane polozky v menu }
begin
  Location := 0;

  Repeat

  tickwait(1); { Casovac, pochazi z Unity Time, pocita se podle procesoru }    

  case Location of
    { Hlavni menu }
    0 : ManageMainMenu(Location);    
    { Samotna hra }    
    1 : GameLoop(Location);
    { Zobrazi ovladani }    
    2 : ManageControlsMenu(Location);
    { Nejvyssi skore }    
    3 : ManageScoresMenu(Location);
    { Tlacitko Quit }    
    4 : exit;
    end;

  { Preruseni smycky a konec celeho programu, pokud byl stisknuty ESC 
    WASDOWN je globalni pole s boolean hodnotami, pochazi z Unity Keyboard
    EscapeKeyCode je globalni promenna z Unity Keyboard s keycodem ESC }
  Until ( WASDOWN[EscapeKeyCode] AND (Location = 0) );
end;




{ ********************************* HLAVNI PROGRAM ********************************* }
Var 
  Gd, Gm : integer; { Graficky driver a mod }

Begin
  Gd := 9; { VGA }
  Gm := 1; { 640x350, 4-bit barvy a 2 vykreslovaci stranky }

  { Inicializace grafiky }
  InitGraph(Gd, Gm, 'C:/BGI');
  { Pokud se nepodarila inicializace, ukonci }
  if GraphResult <> grOk then
    Halt(1);

  { Vytvori nove preruseni pro odchytavani stisknutych klaves, 
    z Unity Keyboard - soubor KEYBOARD.PAS }
  NewKeyboardInterruptInit;
  { Vytvori nove preruseni pro rezii casu, 
    z Unity Time - soubor TIME.PAS }
  NewTimeInterruptInit;

  { Aby funkce Random nebyla stejna }
  Randomize;
  
  { ------------------ HLAVNI SMYCKA ------------------ }
  
  MainLoop;
  
  { ------------------ HLAVNI SMYCKA ------------------ } 
  
  SetOldTimeInterrupt;
  CloseGraph;
end.
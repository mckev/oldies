(* CREATED BY KEVIN H. *)
(*        VECTOR       *)

{$G+,E+,N+}


USES CRT,VGACAD,AUTHOR;
CONST MAX_VERTEKS  = 1500;
      MAX_REL      = 9000;
      MAX_BIDANG   = 2000;
      FILLCLR      = 250;
      D2R : REAL   = PI/360;
      NAMA_FILE : STRING[8] = 'HIND-HEL';

{NAMA_FILE : PART,HIND-HEL,DSKLITE,GEAR,ARMCHR,TABLE2,KITCHEN}

TYPE DATUM_TYPE = RECORD
                     X,Y,Z : INTEGER;
                  END;
     KOORDINAT_TYPE = RECORD
                         X,Y : INTEGER;
                      END;
     BIDANG_TYPE = RECORD
                      WARNA  : BYTE;
                      TUNJUK : WORD;
                      BYK    : BYTE;
                   END;
     TEMP = ARRAY [1..MAX_VERTEKS] OF DATUM_TYPE;
     SORT_TYPE = ARRAY [1..MAX_BIDANG] OF INTEGER;


VAR  DATUM      : TEMP;
     DATUM_LYR  : TEMP;
     REL        : ARRAY [1..MAX_REL] OF WORD;
     KOORDINAT  : ARRAY [1..MAX_VERTEKS] OF KOORDINAT_TYPE;
     BIDANG     : ARRAY [1..MAX_BIDANG] OF BIDANG_TYPE;
     ARRAY_SORT : SORT_TYPE;
     JLH_DATUM  : WORD;
     JLH_BIDANG : WORD;
     NO         : BYTE;         (* JLH. WARNA YG. DIGUNAKAN *)
     X,Y,Z      : INTEGER;
     PROCESS    : POINTER;

     SPDX,SPDY,SPDZ : INTEGER;
     ZOOM           : INTEGER;
     WIREFRAME      : BOOLEAN;
     EXT            : BOOLEAN;  (* ESC DITEKAN *)



(* ========= PROCEDURE INITIALIZE ========= *)

PROCEDURE INITIALIZE;
VAR F:TEXT;
    BYK     : BYTE;
    I,J     : INTEGER;
    R,G,B   : ARRAY[1..255] OF BYTE;
BEGIN
   OPENVGA256;
   ZOOM := 2000;
   WIREFRAME := FALSE;
   DIRECTVIDEO := FALSE;
   X:=0;
   Y:=0;
   Z:=0;

   (* RESTORE PALETTE *)
   NO:=0;
   ASSIGN (F,NAMA_FILE+'.COL');
   RESET (F);
   REPEAT
      INC (NO);
      READLN (F,R[NO]);
      READLN (F,G[NO]);
      READLN (F,B[NO]);
      SETVISUALPALETTE (NO,R[NO],G[NO],B[NO]);
   UNTIL EOF(F);
   CLOSE (F);

   (* BUAT SHADING *)
   BYK:=255 DIV NO;
   FOR I:=1 TO NO DO
      FOR J:=2 TO BYK DO
         SETVISUALPALETTE ((J-1)*NO+I,ROUND(R[I]-(J/BYK)*R[I]*0.8),
            ROUND(G[I]-(J/BYK)*G[I]*0.8),ROUND(B[I]-(J/BYK)*B[I]*0.8));

   (* UBAH DATA *)
{   FOR I:=1 TO 255 DO
      VLINES(SCREEN^,0,199,I,I);
   REPEAT UNTIL KEYPRESSED;}
END;


PROCEDURE DATA_DATA;
VAR F    : TEXT;
    I,NO_BIDANG   : INTEGER;
BEGIN
   ASSIGN (F,NAMA_FILE+'.KRD');
   RESET (F);
   JLH_DATUM:=0;
   REPEAT
      INC (JLH_DATUM);
      READLN (F,DATUM[JLH_DATUM].X);
      READLN (F,DATUM[JLH_DATUM].Y);
      READLN (F,DATUM[JLH_DATUM].Z);
      IF JLH_DATUM>MAX_VERTEKS THEN
         BEGIN
         WRITELN ('Not enough MAX_VERTEKS ...');
         HALT (1);
      END;
   UNTIL EOF(F);
   CLOSE (F);

   I := 0;
   NO_BIDANG := 1;
   BIDANG [1].TUNJUK := 1;
   ASSIGN (F,NAMA_FILE+'.REL');
   RESET (F);
   CLRSCR;
   REPEAT
      INC (I);
      READLN (F,REL [I]);
      IF I>MAX_REL THEN
         BEGIN
         WRITELN ('Not enough MAX_REL ...');
         HALT(1);
      END;
      IF REL [I] = 0 THEN
         BEGIN
         DEC (I);
         BIDANG [NO_BIDANG].WARNA := REL [I];
         DEC (I);
         BIDANG [NO_BIDANG].BYK := I-BIDANG [NO_BIDANG].TUNJUK+1;
         BIDANG [NO_BIDANG+1].TUNJUK := I+1;
         INC (NO_BIDANG);
         IF NO_BIDANG>MAX_BIDANG THEN
            BEGIN
            WRITELN ('Not enough MAX_BIDANG ...');
            HALT (1);
         END;
      END;
   UNTIL EOF (F);
   DEC (NO_BIDANG);
   JLH_BIDANG := NO_BIDANG;
   CLOSE (F);
END;

PROCEDURE WRITE_DATA;
BEGIN
   WRITELN ('Created by ',MAKER);
   WRITELN ('Jlh. Bidang (',NAMA_FILE,'): ',JLH_BIDANG);
   WRITELN ('Verteks: ',JLH_DATUM);
END;



(* ========= PROCEDURE GRAFIS IN ASSEMBLER! ========= *)

PROCEDURE GARIS (VAR PICBUFF;X1,Y1,X2,Y2:INTEGER;WARNA:BYTE); ASSEMBLER;
VAR RX,RY              : INTEGER;
    X,Y,I,IX,IY,INCR   : INTEGER;
    AWAL_SCANNING      : WORD;

   ASM
   PUSH DS
   MOV AX,X2
   MOV DX,X1
   SUB AX,DX
   MOV RX,AX
   MOV AX,Y2
   MOV DX,Y1
   SUB AX,DX
   MOV RY,AX

   MOV AX,RX
   TEST AX,8000H
   JZ @AAA
   NEG AX
   @AAA:
   MOV IX,AX
   MOV AX,RY
   TEST AX,8000H
   JZ @BBB
   NEG AX
   @BBB:
   MOV IY,AX

   MOV AX,IX
   MOV DX,IY
   CMP AX,DX
   JA @INCR_IX
   MOV INCR,DX
   JMP @TERUS
   @INCR_IX:
   MOV INCR,AX
   @TERUS:

   LES DI,PICBUFF
   ADD DI,X1
   XOR BX,BX
   MOV X,BX
   MOV Y,BX
   MOV I,BX

   MOV CX,INCR
   INC CX
   MOV DX,CX

   AND RX,8000H
   JZ @A
   OR BL,1
   @A:
   AND RY,8000H
   JZ @LOOPING
   OR BL,2

   @LOOPING:
   PUSH DX
   MOV DX,Y1
   MOV AX,DX
   SHL DX,2
   ADD DX,AX
   SHL DX,6
   ADD DI,DX
   MOV Y1,0
   POP DX

   MOV AL,WARNA
   MOV [ES:DI],AL
   @TERUSKAN:

   MOV AX,IX
   ADD X,AX
   MOV AX,IY
   ADD Y,AX

   CMP X,DX
   JBE @LANJUT1
   SUB X,DX
   TEST BL,1
   JZ @AA
   DEC DI
   JMP @LANJUT1
   @AA: INC DI

   @LANJUT1:
   CMP Y,DX
   JBE @CC
   SUB Y,DX
   TEST BL,2
   JZ @BB
   DEC Y1
   JMP @CC
   @BB: INC Y1

   @CC:
   LOOP @LOOPING

   POP DS
END;

Procedure HLine (Var PicBuffer; X1,X2,Y : Integer; Color : Byte);
{ Horizontal line }
Begin
  INC (X2);
  If X1<0 then X1:=0;
  If X2<0 then X2:=0;
  If X1>319 then X1:=319;
  IF X2>319 then X2:=319;
  If Y<0 then Y:=0;
  If Y>199 then Y:=199;
asm
  Les CX,PicBuffer
  MOV AX,Y
  MOV DI,AX
  SHL AX,8
  SHL DI,6
  ADD DI,AX
  ADD DI,X1
  ADD DI,CX

  MOV AL,COLOR
  MOV AH,AL
  MOV CX,X2
  SUB CX,X1
  SHR CX,1
  JNC @START
  STOSB

  @START:
  REP STOSW
end; { HLine }
End;



(* ========= PROCEDURE POLIGON ========= *)

Procedure DrawPoly(var picbuff;x1,y1,x2,y2,x3,y3,x4,y4:integer;color:byte);
  { This draw a polygon with 4 points at x1,y1 , x2,y2 , x3,y3 , x4,y4
    in color col }
var
  x:integer;
  mny,mxy:integer;
  mnx,mxx,yc:integer;
  mul1,div1,
  mul2,div2,
  mul3,div3,
  mul4,div4:integer;

begin
  mny:=y1; mxy:=y1;
  if y2<mny then mny:=y2;
  if y2>mxy then mxy:=y2;
  if y3<mny then mny:=y3;
  if y3>mxy then mxy:=y3;    { Choose the min y mny and max y mxy }
  if y4<mny then mny:=y4;
  if y4>mxy then mxy:=y4;

  if mny<0 then mny:=0;
  if mxy>199 then mxy:=199;
  if mny>199 then exit;
  if mxy<0 then exit;        { Verticle range checking }

  mul1:=x1-x4; div1:=y1-y4;
  mul2:=x2-x1; div2:=y2-y1;
  mul3:=x3-x2; div3:=y3-y2;
  mul4:=x4-x3; div4:=y4-y3;  { Constansts needed for intersection calc }

  for yc:=mny to mxy do
    begin
      mnx:=320;
      mxx:=-1;
      if (y4>=yc) or (y1>=yc) then
        if (y4<=yc) or (y1<=yc) then   { Check that yc is between y1 and y4 }
          if not(y4=y1) then
            begin
              x:=(yc-y4)*mul1 div div1+x4; { Point of intersection on x axis }
              if x<mnx then
                mnx:=x;
              if x>mxx then
                mxx:=x;       { Set point as start or end of horiz line }
            end;
      if (y1>=yc) or (y2>=yc) then
        if (y1<=yc) or (y2<=yc) then   { Check that yc is between y1 and y2 }
          if not(y1=y2) then
            begin
              x:=(yc-y1)*mul2 div div2+x1; { Point of intersection on x axis }
              if x<mnx then
                mnx:=x;
              if x>mxx then
                mxx:=x;       { Set point as start or end of horiz line }
            end;
      if (y2>=yc) or (y3>=yc) then
        if (y2<=yc) or (y3<=yc) then   { Check that yc is between y2 and y3 }
          if not(y2=y3) then
            begin
              x:=(yc-y2)*mul3 div div3+x2; { Point of intersection on x axis }
              if x<mnx then
                mnx:=x;
              if x>mxx then
                mxx:=x;       { Set point as start or end of horiz line }
            end;
      if (y3>=yc) or (y4>=yc) then
        if (y3<=yc) or (y4<=yc) then   { Check that yc is between y3 and y4 }
          if not(y3=y4) then
            begin
              x:=(yc-y3)*mul4 div div4+x3; { Point of intersection on x axis }
              if x<mnx then
                mnx:=x;
              if x>mxx then
                mxx:=x;       { Set point as start or end of horiz line }
            end;
      if mnx<0 then
        mnx:=0;
      if mxx>319 then
        mxx:=319;          { Range checking on horizontal line }
      if mnx<=mxx then
        hline (picbuff,mnx,mxx,yc,color);   { Draw the horizontal line }
    end;
  end;

   procedure QuickSort(var A: SORT_TYPE; Lo, Hi: Integer);
   procedure Sortir(l, r: Integer);
   var
      SI, SJ    : INTEGER;
      SY, SX    : longint;
      TEMP_URUTAN : BIDANG_TYPE;
   begin
      SI := l; SJ := r; SX := a[(l+r) DIV 2];
      repeat
         while a[SI] > SX do INC(SI);
         while SX > a[SJ] do DEC(SJ);
         if SI <= SJ then
            begin
            TEMP_URUTAN := BIDANG [SI];
            BIDANG [SI] := BIDANG [SJ];
            BIDANG [SJ] := TEMP_URUTAN;
            SY := a[SI]; a[SI] := a[SJ]; a[SJ] := SY;
            INC (SI); DEC(SJ);
         end;
      until SI > SJ;
      if l < SJ then Sortir(l, SJ);
      if SI < r then Sortir(SI, r);
   end;
   begin {QuickSort};
     Sortir (Lo,Hi);
   end;


PROCEDURE SORT_POLIGON;
VAR C,J,ZZ  : INTEGER;
BEGIN
   FOR C:=1 TO JLH_BIDANG DO
      BEGIN
      ZZ:=0;
      WITH BIDANG[C] DO
         FOR J:=TUNJUK TO TUNJUK+BYK-2 DO
            INC (ZZ,DATUM_LYR[REL[J]].Z);
      ARRAY_SORT[C]:=ZZ;
   END;

   (* SORT BIDANG SESUAI KEDALAMAN *)
   QUICKSORT (ARRAY_SORT,1,JLH_BIDANG);
END;


{FUNCTION DEPAN(NOBID:INTEGER) : BOOLEAN;
VAR YMIN,J            : INTEGER;
    YMININDEX         : WORD;
    AX,BX,CX,AY,BY,CY : INTEGER;
    DIKIRI,GRD1,GRD2  : BOOLEAN;

    FUNCTION MOD_Y (A:WORD) : WORD;
    BEGIN
       WITH BIDANG[NOBID] DO
          IF A>TUNJUK+BYK-2 THEN MOD_Y:=TUNJUK ELSE
          IF A<TUNJUK THEN MOD_Y:=TUNJUK+BYK-2 ELSE
          MOD_Y:=A;
    END;

LABEL QUIT;
BEGIN
   DEPAN := FALSE;

   (* SORT APABILA SEARAH PUTARAN JARUM JAM -> DIBELAKANG *)
   WITH BIDANG[NOBID] DO
      BEGIN
      YMININDEX := TUNJUK;
      YMIN := KOORDINAT[REL[YMININDEX]].Y;
      FOR J:=TUNJUK TO TUNJUK+BYK-2 DO
         IF KOORDINAT[REL[J]].Y < YMIN THEN
            BEGIN
            YMIN:=KOORDINAT[REL[J]].Y;
            YMININDEX:=J;
         END ELSE
         IF (KOORDINAT[REL[J]].Y=YMIN) AND
            (KOORDINAT[REL[J]].X<KOORDINAT[REL[YMININDEX]].X) THEN
            YMININDEX:=J;

      (* DATA-DATA *)
      AX:=KOORDINAT[REL[MOD_Y(YMININDEX-1)]].X;
      AY:=KOORDINAT[REL[MOD_Y(YMININDEX-1)]].Y;
      BX:=KOORDINAT[REL[YMININDEX]].X;
      BY:=KOORDINAT[REL[YMININDEX]].Y;
      CX:=KOORDINAT[REL[MOD_Y(YMININDEX+1)]].X;
      CY:=KOORDINAT[REL[MOD_Y(YMININDEX+1)]].Y;
      DEC (AX,BX);
      DEC (CX,BX);
      DEC (AY,BY);
      DEC (CY,BY);

      (* CEK PERTAMA *)
      IF (AX=0) OR (CX=0) THEN
         BEGIN
         IF CX>AX THEN DEPAN:=TRUE;
         END ELSE

      (* CEK KEDUA *)
      IF (AY=0) OR (CY=0) THEN
         BEGIN
         IF CY=0 THEN DEPAN:=TRUE;
         END ELSE

      (* CEK TERAKHIR *)
      BEGIN
         GRD1 := (CY>0) XOR (CX>0);
         GRD2 := (AY>0) XOR (AX>0);

         DIKIRI := ((CX>0) XOR (AX>0)) XOR ((CY*AX)-(AY*CX)>0);
         IF (GRD1 XOR GRD2) AND DIKIRI THEN DEPAN:=TRUE;
         IF NOT(GRD1 XOR GRD2) AND NOT DIKIRI THEN DEPAN:=TRUE;
      END;
   END;
END;}


(*   PROCEDURE HASH TABLE    *)
TYPE TIPE_HASH_ARCOS = ARRAY [-1000..1000] OF BYTE;
VAR HASH_ARCOS : TIPE_HASH_ARCOS;
PROCEDURE MAKE_HASH_ARCOS;
VAR I:INTEGER;
   FUNCTION ARCOS (NUM:REAL):REAL;
   BEGIN
      IF NUM=0 THEN ARCOS:=PI/2 ELSE
      ARCOS:=ARCTAN (SQRT(1-SQR(NUM))/NUM);
   END;
   BEGIN
   FOR I:=-1000 TO 1000 DO
      BEGIN
      HASH_ARCOS[I] := TRUNC(ABS(ARCOS(I/1000))*(255 DIV NO)*2/PI)*NO;
   END;
END;

FUNCTION COMPUTE_COLOR (R:REAL) : BYTE;
BEGIN
   COMPUTE_COLOR:=HASH_ARCOS[TRUNC(R*1000)];
END;


(*   PROCEDURE DRAW POLIGON   *)
PROCEDURE DRAW (VAR PICBUFF);
VAR  I,J : INTEGER;
     A,B,C,D,E,F       : INTEGER;
     K,L,M             : REAL;
     SUDUT             : REAL;

LABEL QUIT;
BEGIN

   (* PERHITUNGAN KOORDINAT DI LAYAR *)
   FOR I:=1 TO JLH_DATUM DO
      BEGIN
      KOORDINAT[I].X:=160+ROUND((400/(DATUM_LYR[I].Z+ZOOM))*DATUM_LYR[I].X);
      KOORDINAT[I].Y:=100+ROUND((400/(DATUM_LYR[I].Z+ZOOM))*DATUM_LYR[I].Y);
   END;

   SORT_POLIGON;

   (* TAMPILKAN *)
   FOR I:=1 TO JLH_BIDANG DO
      BEGIN
      WITH BIDANG[I] DO
         IF WIREFRAME THEN
            FOR J:=TUNJUK TO TUNJUK+BYK-2 DO
            GARIS(PICBUFF,KOORDINAT[REL[J]].X, KOORDINAT[REL[J]].Y,
                  KOORDINAT[REL[J+1]].X, KOORDINAT[REL[J+1]].Y,
                  WARNA)
         ELSE
            BEGIN

            (* PERHITUNGAN THD. LIGHT SOURCING *)
            A:=DATUM_LYR[REL[TUNJUK+1]].X-DATUM_LYR[REL[TUNJUK]].X;
            B:=DATUM_LYR[REL[TUNJUK+1]].Y-DATUM_LYR[REL[TUNJUK]].Y;
            C:=DATUM_LYR[REL[TUNJUK+1]].Z-DATUM_LYR[REL[TUNJUK]].Z;

            D:=DATUM_LYR[REL[TUNJUK+2]].X-DATUM_LYR[REL[TUNJUK+1]].X;
            E:=DATUM_LYR[REL[TUNJUK+2]].Y-DATUM_LYR[REL[TUNJUK+1]].Y;
            F:=DATUM_LYR[REL[TUNJUK+2]].Z-DATUM_LYR[REL[TUNJUK+1]].Z;

            K:=(B*F - C*E)/1000;
            L:=(-A*F + C*D)/1000;
            M:=(A*E - B*D)/1000;

            SUDUT:=SQRT(K*K+L*L+M*M);
            IF SUDUT<>0 THEN
               BEGIN
               J := COMPUTE_COLOR (M/SUDUT)+BIDANG[I].WARNA;
               (* BUAT POLIGON DGN. WARNA J *)
               DRAWPOLY (PICBUFF,
                      KOORDINAT[REL[TUNJUK]].X, KOORDINAT[REL[TUNJUK]].Y,
                      KOORDINAT[REL[TUNJUK+1]].X, KOORDINAT[REL[TUNJUK+1]].Y,
                      KOORDINAT[REL[TUNJUK+2]].X, KOORDINAT[REL[TUNJUK+2]].Y,
                      KOORDINAT[REL[TUNJUK+3]].X, KOORDINAT[REL[TUNJUK+3]].Y,
                      J);
            END;
      END;
   END;
END;



(* ========= PROCEDURE MEMANIPULASI OBJEK ========= *)

PROCEDURE ROTATE;
VAR XI,YI,ZI,J : INTEGER;
    TOMBOL     : CHAR;
    TX_COS,TX_SIN,TY_COS,TY_SIN,TZ_COS,TZ_SIN : REAL;

BEGIN
   IF KEYPRESSED THEN
      BEGIN
      TOMBOL := UPCASE(READKEY);
      CASE TOMBOL OF
          'Q' : INC (SPDX);
          'A' : SPDX := 0;
          'Z' : DEC (SPDX);
          'W' : INC (SPDY);
          'S' : SPDY := 0;
          'X' : DEC (SPDY);
          'E' : INC (SPDZ);
          'D' : SPDZ := 0;
          'C' : DEC (SPDZ);
          '-' : INC (ZOOM,50);
          '+' : DEC (ZOOM,50);
          ' ' : WIREFRAME := NOT(WIREFRAME);
          #27 : EXT := TRUE;
       END;
       GOTOXY(1,25);TEXTCOLOR (7);
       WRITE ('X:',SPDX,', Y:',SPDY,', Z:',SPDZ,', Zm:',ZOOM/100:1:1,' ');
       TEXTCOLOR (11);
       IF WIREFRAME THEN WRITE ('Wrf ') ELSE WRITE ('    ');
       GOTOXY(32,25);TEXTCOLOR(10);WRITE ('3D');
       GOTOXY(34,25);TEXTCOLOR(4);WRITE ('-');
       GOTOXY(35,25);TEXTCOLOR(9);WRITE ('KEVIN');
    END;

    DATUM_LYR := DATUM;
    INC (X,SPDX);
    INC (Y,SPDY);
    INC (Z,SPDZ);
    IF X > 720 THEN DEC (X,720);
    IF Y > 720 THEN DEC (Y,720);
    IF Z > 720 THEN DEC (Z,720);
    IF X < 0 THEN INC (X,720);
    IF Y < 0 THEN INC (Y,720);
    IF Z < 0 THEN INC (Z,720);

    (* PERHITUNGAN VARIABEL TEMPORARY *)
    TX_COS := COS (X*D2R); TX_SIN := SIN (X*D2R);
    TY_COS := COS (Y*D2R); TY_SIN := SIN (Y*D2R);
    TZ_COS := COS (Z*D2R); TZ_SIN := SIN (Z*D2R);

    FOR J:=1 TO JLH_DATUM DO
       BEGIN
       XI := ROUND(DATUM_LYR[J].X*TX_COS - DATUM_LYR[J].Y*TX_SIN);
       YI := ROUND(DATUM_LYR[J].X*TX_SIN + DATUM_LYR[J].Y*TX_COS);
       DATUM_LYR [J].X := XI;
       DATUM_LYR [J].Y := YI;

       XI := ROUND(DATUM_LYR[J].X*TY_COS - DATUM_LYR[J].Z*TY_SIN);
       ZI := ROUND(DATUM_LYR[J].X*TY_SIN + DATUM_LYR[J].Z*TY_COS);
       DATUM_LYR [J].X := XI;
       DATUM_LYR [J].Z := ZI;

       YI := ROUND(DATUM_LYR[J].Y*TZ_COS - DATUM_LYR[J].Z*TZ_SIN);
       ZI := ROUND(DATUM_LYR[J].Y*TZ_SIN + DATUM_LYR[J].Z*TZ_COS);
       DATUM_LYR [J].Y := YI;
       DATUM_LYR [J].Z := ZI;
  END;
END;



(* ================ MAIN PROCEDURE =================== *)

PROCEDURE MAIN_PROGRAM;
BEGIN
   EXT := FALSE;
   DEFINE_PAGE (PROCESS);
   FILL_PAGE (PROCESS^,0);
   REPEAT
      ASM
         LES DI,PROCESS
         MOV CX,15000
         DB $66
         XOR AX,AX
         DB $66
         REP STOSW
      END;
      ROTATE;
      DRAW (PROCESS^);
      ASM
         PUSH DS
         LES DI,SCREEN
         LDS SI,PROCESS
         MOV CX,15000
         DB $66
         REP MOVSW
         POP DS
      END;
   UNTIL EXT;
END;


BEGIN
   DATA_DATA;
   INITIALIZE;
   MAKE_HASH_ARCOS;
   MAIN_PROGRAM;
   CLOSEVGA256;
   WRITE_DATA;
END.
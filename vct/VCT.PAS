{$A-,B+,D-,G+,E-,N-,I-,L-,R-,S-,V-}
USES DATA,AUTHOR;
CONST
   CTR     : WORD = 110;
   SA      : WORD = 0;
   J       : BYTE = 0;
   J_OLD   : BYTE = 1;
   XK      : BYTE = 0;
   BALIKJ  : BOOLEAN = FALSE;
   JUDUL   : STRING[20] = 'VCT SOFT-WARE GROUP';
   ANIM1   : BOOLEAN = TRUE;
   ANIM2   : BOOLEAN = TRUE;


VAR DATUM  : POINTER;
    SPEC   : POINTER;
    BUFFER : POINTER;
    BARIS  : ARRAY [1..360] OF WORD;
    MODE_LAYAR : BYTE;

    (* PROCEDURE JUDUL *)
    DELAYJ  : BYTE;

    (* PROCEDURE KILAT *)
    DATK   : POINTER;

FUNCTION ADAVGA : BOOLEAN; ASSEMBLER;
   ASM
   MOV AH,0FH
   INT 10H
   MOV MODE_LAYAR,AL
   MOV AX,01A00H
   INT 10H
   CMP AL,01AH
   JZ @VGAYES
   XOR AL,AL
   @VGAYES:
   PUSH AX
   MOV AX,3
   INT 10H
   POP AX
END;

FUNCTION IS286ABLE: BOOLEAN; ASSEMBLER;
ASM
        PUSHF
        POP     BX
        AND     BX,0FFFH
        PUSH    BX
        POPF
        PUSHF
        POP     BX
        AND     BX,0F000H
        CMP     BX,0F000H
        MOV     AX,0
        JZ      @@1
        MOV     AX,1
@@1:
END;

PROCEDURE SCREEN_INIT; ASSEMBLER;
   ASM
      (* SET FONT LAYAR *)
      LES DX,FONT
      PUSH BP
      MOV AX,1110H
      MOV BP,DX
      MOV BH,10H
      XOR BL,BL
      MOV CX,60H
      MOV DX,20H
      INT 10H
      POP BP

      MOV DX,03D4H
      MOV AL,0AH
      OUT DX,AL
      INC DL
      IN AL,DX
      AND AL,0E0H
      OUT DX,AL
      DEC DL
      MOV AL,0BH
      OUT DX,AL
      INC DL
      IN AL,DX
      AND AL,0E0H
      OUT DX,AL
      DEC DL
      MOV AX,05213H
      OUT DX,AX
      MOV AX,0CD10H
      OUT DX,AX
      MOV AX,0E11H
      OUT DX,AX
      MOV AX,0DD06H
      OUT DX,AX
      MOV AX,0CC12H
      OUT DX,AX
      MOV AX,0CD15H
      OUT DX,AX
      MOV AX,0DD16H
      OUT DX,AX
      MOV AX,05201H
      OUT DX,AX
      MOV AX,05102H
      OUT DX,AX
      MOV AX,05704H
      OUT DX,AX
      MOV AX,08203H
      OUT DX,AX
      MOV AX,08005H
      OUT DX,AX
      MOV DX,03C0H
      MOV AL,030H
      OUT DX,AL
      INC DL
      IN AL,DX
      DEC DL
      OR AL,20H
      OUT DX,AL
      MOV DX,03D4H
      MOV AX,0CH
      OUT DX,AX
      MOV AX,0520DH
      OUT DX,AX

      (* SET R,G,B OF COLOR 3 OFF *)
      MOV DX,03C8H
      MOV AL,5
      OUT DX,AL
      INC DL
      XOR AL,AL
      OUT DX,AL
      OUT DX,AL
      OUT DX,AL

      (* SET COLOR 1 *)
      DEC DL
      MOV AL,1
      OUT DX,AL
      INC DL
      XOR AL,AL
      OUT DX,AL
      OUT DX,AL
      MOV AL,20
      OUT DX,AL
END;


PROCEDURE PANGGIL; ASSEMBLER;
ASM
   PUSH DS
   PUSH SI
   RETF
END;


PROCEDURE INIT_MIDI; ASSEMBLER;
   ASM
   PUSH DS
   LDS SI,P

   MOV AH,6
   PUSH CS
   CALL PANGGIL

   XOR SI,SI
   MOV AH,0
   MOV BX,DS
   MOV CX,0956H
   PUSH CS
   CALL PANGGIL

   XOR SI,SI
   MOV AH,2
   XOR BX,BX
   PUSH CS
   CALL PANGGIL

   POP DS
END;


PROCEDURE PLAY_MIDI; ASSEMBLER;
   ASM
   PUSH BP
   PUSH DS
   LDS SI,P
   MOV AH,3
   PUSH CS
   CALL PANGGIL
   POP DS
   POP BP
END;


PROCEDURE STOP_MIDI; ASSEMBLER;
   ASM
   PUSH DS
   LDS SI,P
   MOV AH,2
   XOR BX,BX
   PUSH CS
   CALL PANGGIL
   POP DS
END;


PROCEDURE MAKEPALETTE; ASSEMBLER;
   ASM
   PUSH DS
   LDS SI,DATUM
   XOR BX,BX               (* BX -> GERBANG LOGIKA *)
   MOV CX,3                (* BUAT 3 WARNA *)

   @L1:
   PUSH CX
   MOV CX,2

   @L2:
   PUSH CX
   MOV CX,58
   OR BL,BL
   JZ @L3
   MOV CX,58
   JMP @L4
   @L3:
   XOR DX,DX               (* DL -> 0, DH -> COUNTER *)
   @L4:
   OR BL,BL
   JZ @L5
   DEC DH
   DEC DH
   @L5:
   INC DH
   OR BH,BH
   JZ @L6
   MOV [SI],DL             (* SET WARNA HIJAU *)
   MOV [SI+1],DH
   MOV [SI+2],DL
   JMP @L7
   @L6:
   MOV [SI],DL             (* SET WARNA BIRU *)
   MOV [SI+1],DL
   MOV [SI+2],DH
   @L7:
   ADD SI,3
   LOOP @L4
   NOT BL                  (* SET WARNA KE BAWAH/KEATAS *)
   POP CX
   LOOP @L2
   POP CX
   NOT BH                  (* SET WARNA HIJAU/BIRU *)
   LOOP @L1

   POP DS
END;

PROCEDURE MAKESPECTRUM;
VAR R,G,B : BYTE;
    C,D   : WORD;
BEGIN
   D:=0;
   FOR C:=1 TO $150 DO
      BEGIN
      R := ROUND (31-(31*COS(C*2*(PI/180))));
      G := ROUND (31-(31*SIN(C*2*(PI/180))));
      B := ROUND (31+(31*COS(C*2*(PI/180))));
      ASM
         LES DI,SPEC
         ADD DI,D
         MOV AL,R
         STOSB
         MOV AL,G
         STOSB
         MOV AL,B
         STOSB
         ADD D,3
      END;
   END;
END;


PROCEDURE SISIPKAN (BARIS:WORD;R:BYTE); ASSEMBLER;
   ASM
   PUSH DS
   LDS SI,DATUM
   MOV AX,BARIS
   SHL AX,2
   SUB AX,BARIS
   ADD SI,AX
   MOV AL,R
   MOV [SI],AL
   POP DS
END;


(* PROCEDURE TEXT *)

PROCEDURE PRINT (LX,LY,ATT:BYTE;LST:STRING;WARNA:BOOLEAN);
VAR TMP2  : BYTE;
    TMP1  : WORD;
BEGIN
   TMP1 := ((LY-1)*80+LX-1) SHL 1;
   FOR TMP2:=0 TO LENGTH (LST)-1 DO
      BEGIN
      MEM[$B800:TMP1+TMP2 SHL 1]   := ORD (LST[TMP2+1]);
      IF WARNA AND (TMP2 MOD 2=1) THEN
         MEM[$B800:TMP1+1+TMP2 SHL 1] := ATT-8
         ELSE
         MEM[$B800:TMP1+1+TMP2 SHL 1] := ATT;
   END;
END;


PROCEDURE TULIS_LAYAR;
VAR X,Y:INTEGER;
    C  : BYTE;
   FUNCTION LOOP_HRF (KARAKTER:CHAR;PJGNYA:BYTE) : STRING;
   VAR T:STRING;
   BEGIN
      T[0]:=CHR(PJGNYA);
      FILLCHAR (T[1],PJGNYA,KARAKTER);
      LOOP_HRF:=T;
   END;
BEGIN
   X:=-7;Y:=120;
   FOR C:=1 TO 2 DO
      BEGIN
      PRINT (28+X,Y,12,'-**-',TRUE);
      PRINT (33+X,Y,15,JUDUL,FALSE);
      PRINT (53+X,Y,12,'-**-',TRUE);
      X:=1;Y:=1;
   END;

   X:=1;Y:=124;
   FOR C:=1 TO 2 DO
      BEGIN
      PRINT (4+X,Y,11,'- We are the FASTEST, rite ?',TRUE);
      PRINT (53+X,Y,11,'We are the best hackers -',TRUE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'Õ'+LOOP_HRF('Í',37)+'Ñ'+LOOP_HRF('Í',36)+'¸',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'³°±²Û',FALSE);
      PRINT (8+X,Y,26,' Coder   :                   ',TRUE);
      PRINT (19+X,Y,28,MAKER,TRUE);
      PRINT (37+X,Y,9,'Û²±°³°±²Û',FALSE);
      PRINT (46+X,Y,25+128,'     V C T - S M U N S A    ',FALSE);
      PRINT (74+X,Y,9,'Û²±°³',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'³°±²Û',FALSE);
      PRINT (8+X,Y,31,'              (c) Indonesia  ',FALSE);
      PRINT (37+X,Y,9,'Û²±°³°±²Û',FALSE);
      PRINT (46+X,Y,25,'                            ',FALSE);
      PRINT (74+X,Y,9,'Û²±°³',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'³°±²Û',FALSE);
      PRINT (8+X,Y,26,' Trainer :                   ',TRUE);
      PRINT (37+X,Y,9,'Û²±°³°±²Û',FALSE);
      PRINT (19+X,Y,30,'Who else ?!',FALSE);
      PRINT (46+X,Y,25,'          M E D A N         ',FALSE);
      PRINT (74+X,Y,9,'Û²±°³',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'Ã'+LOOP_HRF('Ä',37)+'Á'+LOOP_HRF('Ä',36)+'´',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'³°±²Û',FALSE);
      PRINT (8+X,Y,121,' Date of release : 16 February 1997'+LOOP_HRF(' ',32),FALSE);
      PRINT (67+X,Y,124,'VCT SG',FALSE);
      PRINT (74+X,Y,9,'Û²±°³',FALSE);
      INC (X,4); INC (Y,2);
      PRINT (3+X,Y,9,'À'+LOOP_HRF('Ä',74)+'Ù',FALSE);
      X:=9;Y:=5;
   END;
   X:=71;Y:=35;
   PRINT (X-1,Y,5,'SMUNSA COMPUTER LABS',FALSE);
   PRINT (60+X,Y,5,'All rights reserved',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'ÚÄÄÄÂ'+LOOP_HRF('Ä',74)+'ÂÄÄÄ¿',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³   ³'+LOOP_HRF(' ',74)+'³   ³',FALSE);
   PRINT (X+4,Y,5,'ÛÛÛÜ       ÜÛÛÛß ÜÛÛÛÛÛÛÛÜ  ÜÛÛÛÛÛÛÛÛÜ   T M',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'ÃÄÄÄÙ'+LOOP_HRF(' ',74)+'ÀÄÄÄ´',FALSE);
   PRINT (X+4,Y,5,' ÛÛÛÝ     ÞÛÛÝ  ÛÛÛß     ßÛ ß   ÛÛÛ  ß',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³',FALSE);PRINT (80+X,Y,5,'³',FALSE);
   PRINT (X+4,Y,5,' ÞÛÛÛ     ÛÛÛ  ÞÛÛÛ             ÛÛÛ   Üßßß ÜßÛßÜ Û  Û ÛÜ  Û Üßßß  ÜÜÛ',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³',FALSE);PRINT (80+X,Y,5,'³',FALSE);
   PRINT (X+4,Y,5,'  ÛÛÛÝ    ÛÛÛ  ÞÛÛÛ             ÛÛÛ    ßßÜ Û Û Û Û  Û Û Û Û  ßßÜ ÛÜÜÛ',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³',FALSE);PRINT (80+X,Y,5,'³',FALSE);
   PRINT (X+4,Y,5,'  ÞÛÛÝ   ÞÛÛÝ  ÞÛÛÛ            ÞÛÛÛ   ÜÜÜß Û   Û ßÜÜß Û  ßÛ ÜÜÜß Û  Û',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³',FALSE);PRINT (80+X,Y,5,'³',FALSE);
   PRINT (X+4,Y,5,'   ÛÛÛ   ÛÛÛ   ÞÛÛÛ            ÞÛÛÛ',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'ÃÄÄÄ¿'+LOOP_HRF(' ',74)+'ÚÄÄÄ´',FALSE);
   PRINT (X+4,Y,5,'   ÞÛÛÜ ÛÛÛÝ    ÛÛÛÜ     ÜÛ    ÞÛÛÛÝ     Visual Creator Technology',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'³   ³'+LOOP_HRF(' ',74)+'³   ³',FALSE);
   PRINT (X+4,Y,5,'    ßÛÛÛÛß       ßÛÛÛÛÛÛÛß     ÛÛÛÛÛ',FALSE);
   INC (X,4); INC (Y,2);
   PRINT (X-3,Y,5,'ÀÄÄÄÁ'+LOOP_HRF('Ä',74)+'ÁÄÄÄÙ',FALSE);
END;


PROCEDURE CANTIK;
BEGIN
   INC (DELAYJ);
   IF DELAYJ>ABS(J-10)+3 THEN
      BEGIN
      DELAYJ:=0;
      IF BALIKJ THEN
         BEGIN
         DEC (J);
         IF J=1 THEN BALIKJ:=NOT(BALIKJ);
        END ELSE
         BEGIN
         INC (J);
         IF J=19 THEN BALIKJ:=NOT(BALIKJ);
      END;
      PRINT (33+J_OLD,1,15,JUDUL[J_OLD],FALSE);
      PRINT (33+J,1,14,JUDUL[J],FALSE);
      PRINT (25+J_OLD,120,15,JUDUL[J_OLD],FALSE);
      PRINT (25+J,120,14,JUDUL[J],FALSE);
      J_OLD:=J;
   END;
END;

PROCEDURE FLASH (XX,YY:BYTE);
VAR TMP1 : WORD;
    C    : BYTE;
BEGIN
   TMP1 := (((YY-1)*80+XX-1) SHL 1)+1;
   C := MEM[$B800:TMP1];
   ASM
      MOV AL,C
      AND AL,011110000B
      OR  AL,000001111B
      MOV C,AL
   END;
   MEM[$B800:TMP1]:=C;
END;

PROCEDURE KILAT;
VAR C : BYTE;
    XX,YY : BYTE;
BEGIN
   INC (XK);
   XX:=92;YY:=7;
   IF XK<83 THEN
      BEGIN
      MOVEW (DATK^,PTR($B800,250)^,1500);
      FOR C:=1 TO 7 DO
         BEGIN
         FLASH (XX-XK,YY);
         INC (XX,5);
         INC (YY,2);
      END;
   END;
END;


(* PROCEDURE BACKGROUND *)

PROCEDURE REFRESH_PALETTE;
BEGIN
   ASM
   PUSH DS
   LES DI,SPEC
   LDS SI,DATUM
   MOV DX,03DAH
   @TUNDA1:
   IN AL,DX
   JMP @A
   @A:
   TEST AL,8
   JNE @TUNDA1
   @TUNDA2:
   IN AL,DX
   JMP @B
   @B:
   TEST AL,8
   JE @TUNDA2
   ADD SI,30
   MOV CX,150H

   @MAIN:
   MOV DL,0DAH
   @TUNDA3:
   IN AL,DX
   JMP @C
   @C:
   TEST AL,1
   JNE @TUNDA3
   @TUNDA4:
   IN AL,DX
   JMP @D
   @D:
   TEST AL,1
   JE @TUNDA4

   MOV DL,0C8H
   XOR AL,AL
   OUT DX,AL
   INC DL
   OUTSB
   OUTSB
   OUTSB
   DEC DX
   MOV AL,5
   OUT DX,AL
   INC DL
   MOV AL,[ES:DI]
   OUT DX,AL
   XOR AL,AL
   MOV AL,[ES:DI+1]
   OUT DX,AL
   MOV AL,[ES:DI+2]
   OUT DX,AL
   ADD DI,3
   LOOP @MAIN
   POP DS
   END;
   PLAY_MIDI;
   CANTIK;
END;


(* PROCEDURE-PROCEDURE MEMORY REFRESHING *)

PROCEDURE SAVEPAL;
BEGIN
   GETMEM (BUFFER,1500);
   MOVEW (DATUM^,BUFFER^,750);
END;
PROCEDURE REFRESH;
BEGIN
   MOVEW (BUFFER^,DATUM^,750);
END;
PROCEDURE SAVE_SCR;
BEGIN
   GETMEM (DATK,3000);
   MOVEW (PTR($B800,250)^,DATK^,1500);
END;


(* PROCEDURE-PROCEDURE GARIS *)

PROCEDURE CALC_GARIS;
VAR C : WORD;
BEGIN
   FOR C:=1 TO 360 DO
      BARIS [C] := 174-ROUND (156*COS(C*(PI/180)));
END;

PROCEDURE BUAT_GARIS (BARIS:WORD;W:BYTE);
VAR C : WORD;
BEGIN
   FOR C:=0 TO (W SHR 3) DO
      BEGIN
      SISIPKAN (BARIS-C,W-(C SHL 3));
   END;
   FOR C:=(W SHR 3) DOWNTO 1 DO
      SISIPKAN (BARIS+C,W-(C SHL 3));
END;

PROCEDURE REFRESH_GARIS;
VAR T : INTEGER;
    C : BYTE;
BEGIN
   REFRESH;
   INC (CTR);
   IF CTR>360 THEN DEC(CTR,360);
   T := CTR;
   FOR C:=0 TO 7 DO
      BEGIN
      BUAT_GARIS (BARIS[T],7+(C SHL 3));
      INC (T,8);
      IF T>360 THEN DEC (T,360);
   END;
END;


(* PROCEDURE-PROCEDURE ANIMASI *)

PROCEDURE ANIM_FALL;
VAR S,C : WORD;
BEGIN
   S:=0;
   FOR C := 1 TO $0F9 DO
      BEGIN
      ASM
      PUSH DS
      LDS SI,DJB
      ADD SI,S
      @LAGI:
      MOV DX,03D4H
      MOV AL,0CH
      OUT DX,AL
      INC DL

      OUTSB
      DEC DL
      INC AL
      OUT DX,AL
      INC DL

      OUTSB
      DEC DL

      MOV DX,03D4H
      MOV AL,08
      OUT DX,AL
      INC DL
      OUTSB
      ADD S,3
      POP DS
      END;
      REFRESH_PALETTE;
   END;

   ASM
      MOV DX,03D4H
      MOV AL,7
      OUT DX,AL
      INC DL
      IN AL,DX
      OR AL,10H
      OUT DX,AL
      DEC DL
      MOV AL,09
      OUT DX,AL
      INC DL
      IN AL,DX
      AND AL,0BFH
      OUT DX,AL
      DEC DL
      MOV AX,02018H
      OUT DX,AX
   END;
   REFRESH_PALETTE;
END;

PROCEDURE ANIMASI;
BEGIN
   ASM
      PUSH DS
      MOV DX,SA
      LDS SI,ANI
      ADD SI,DX
      MOV DX,03D4H
      MOV AL,0CH
      OUT DX,AL
      INC DL
      OUTSB
      DEC DL
      INC AL
      OUT DX,AL
      INC DL
      OUTSB
      MOV DX,03D4H
      MOV AL,08
      OUT DX,AL
      INC DL
      OUTSB
      MOV DX,03C0H
      MOV AL,033H
      OUT DX,AL
      OUTSB
      POP DS
   END;
   INC (SA,4);
   IF SA>=2546 THEN SA:=512;
END;


PROCEDURE ANIM_CLOSE;
VAR V76,V77,V78 : BYTE;
    C           : BYTE;
BEGIN
   V76:=0;
   V77:=0;
   V78:=1;
   REFRESH_GARIS;
   REFRESH_PALETTE;

   FOR C:=1 TO $4A DO
      BEGIN
      ASM
      LES DI,ANI
      ADD DI,SA

      MOV AL,V78
      ADD [ES:DI+2],AL
      CMP BYTE PTR [ES:DI+2],0FH
      JBE @1
      AND BYTE PTR [ES:DI+2],0FH
      ADD BYTE PTR [ES:DI+1],0A4H
      ADC BYTE PTR [ES:DI],0
      @1:
      MOV AL,V77
      ADD [ES:DI+1],AL
      MOV AL,V76
      ADC [ES:DI],AL
      ADD V78,04
      CMP V78,010H
      JB @2
      MOV V78,0
      ADD V77,0A4H
      ADC V76,0
      @2:
      MOV DX,03D4H
      MOV AL,0CH
      OUT DX,AL
      INC DL
      PUSH AX
      MOV AL,[ES:DI]
      OUT DX,AL
      INC DI
      POP AX
      DEC DL
      INC AL
      OUT DX,AL
      INC DL
      PUSH AX
      MOV AL,[ES:DI]
      OUT DX,AL
      INC DI
      POP AX
      MOV DX,03D4H
      MOV AL,8
      OUT DX,AL
      INC DL
      PUSH AX
      MOV AL,[ES:DI]
      OUT DX,AL
      INC DI
      POP AX
      MOV DX,03C0H
      MOV AL,033H
      OUT DX,AL
      PUSH AX
      MOV AL,[ES:DI]
      OUT DX,AL
      INC DI
      POP AX

      ADD SA,4
      CMP SA,2546
      JB @3
      MOV SA,512
      SUB DI,2546
      ADD DI,512

      @3:
      END;
      REFRESH_GARIS;
      REFRESH_PALETTE;
      KILAT;
   END;
   FOR C:=1 TO 9 DO
      BEGIN
      REFRESH_GARIS;
      REFRESH_PALETTE;
      KILAT;
   END;
END;


PROCEDURE ANIM_LEFT;
VAR C,S : WORD;
BEGIN
   S:=0;
   ASM
      MOV DX,03D4H
      MOV AX,0FF18H
      OUT DX,AX
      MOV AX,0F08H
      OUT DX,AX
      MOV DX,03C0H
      MOV AL,33H
      OUT DX,AL
      XOR AL,AL
      OUT DX,AL
   END;
   FOR C:=1 TO $40 DO
      BEGIN
      ASM
      PUSH DS
      LDS SI,DGK
      ADD SI,S
      MOV DX,03D4H
      MOV AL,0CH
      OUT DX,AL
      INC DL

      OUTSB
      DEC DL
      INC AL
      OUT DX,AL
      INC DL

      OUTSB
      MOV DX,03C0H
      MOV AL,33H
      OUT DX,AL

      OUTSB
      ADD S,3
      POP DS
      END;
      REFRESH_GARIS;
      REFRESH_PALETTE;
   END;
END;

(*    M A I N   P R O G R A M    *)

VAR PENANDA : POINTER;
    TAON    : WORD;
    TAHUN   : STRING [4];
    LAMBAT  : BYTE;
    CTR1    : BYTE;

BEGIN
   ASM CLI END;

   (* CEK VGA & PROCESSOR *)
   IF NOT ADAVGA THEN
      BEGIN
      WRITELN ('Sorry, you must have a VGA card to see me...');
      ASM STI END;
      HALT(1);
   END;

   IF NOT IS286ABLE THEN
     BEGIN
     WRITELN ('Need an 80286-above system to run this program');
     ASM STI END;
     HALT(1);
   END;

   (* AMBIL TAHUN SEKARANG *)
   ASM
      MOV AH,02AH
      INT 21H
      MOV TAON,CX
   END;
   STR (TAON,TAHUN);
   IF TAON<=1997 THEN TAON:=1997;
   TAHUN := COPY (TAHUN,3,2);

   (* INITIALISASI *)
   MARK (PENANDA);
   GETMEM (DATUM,1500);
   GETMEM (SPEC,1500);
   FILLW (DATUM^,750);
   FILLW (SPEC^,750);
   FILLW (PTR($B800,0)^,80*25*4);
   CALC_GARIS;
   MAKEPALETTE;
   MAKESPECTRUM;
   SAVEPAL;

   (* MULAI *)
   INIT_MIDI;
   ASM CLI END;
   SCREEN_INIT;
   TULIS_LAYAR;
   SAVE_SCR;
   ANIM_FALL;
   CTR:=0;
   REPEAT
      REFRESH_PALETTE;
      INC (CTR1);
      IF CTR1>LAMBAT THEN
         BEGIN
         CTR1:=0;
         IF ANIM1 THEN REFRESH_GARIS;
         IF ANIM2 THEN ANIMASI;
         IF (PORT[$60]=63) AND (LAMBAT<20) THEN INC (LAMBAT);
         IF (PORT[$60]=64) AND (LAMBAT>0) THEN DEC (LAMBAT);
      END;
      IF PORT[$60]=65 THEN ANIM1:=FALSE;
      IF PORT[$60]=66 THEN ANIM1:=TRUE;
      IF PORT[$60]=67 THEN ANIM2:=FALSE;
      IF PORT[$60]=68 THEN ANIM2:=TRUE;
   UNTIL PORT[$60]=1;
   ANIM_CLOSE;
   ANIM_LEFT;
   STOP_MIDI;
   ASM
      XOR AH,AH
      MOV AL,MODE_LAYAR
      INT 10H
   END;
   PRINT (1,1,9,'Presented by',TRUE);
   PRINT (14,1,14,'VCT Software Group ',TRUE);
   PRINT (33,1,10,''''+TAHUN,TRUE);
   PRINT (38,1,13,'SMUNSA - Medan',TRUE);
   PRINT (1,3,11,'E-mail :',TRUE);
   PRINT (10,3,8,'mckev@hotmail.com (Kevin), doni_vct@hotmail.com (Dony)',FALSE);
   PRINT (10,4,8,'choco_vct@hotmail.com (Henry), hajar_vct@hotmail.com (Hastoro)',FALSE);
{   PRINT (1,4,9,'Licensed to :',FALSE);
   PRINT (15,4,12,'Mac Toy''z (Tito)',TRUE);}
   PRINT (1,6,12,'Thank''s for your attention ...',TRUE);
   ASM
      MOV AH,0FH
      INT 10H
      MOV AH,02H
      MOV DH,7
      XOR DL,DL
      INT 10H
   END;
   RELEASE (PENANDA);
   ASM STI END;
END.
USES CRT,DOS,AUTHOR;
CONST MAX_MEM_USED = 50000;
      POSISI_MEMORI:LONGINT = 0;

VAR P1,P2     : POINTER;
    F         : FILE;
    NF        : STRING;   (* NAMA FILE *)
    PF        : LONGINT;  (* PANJANG FILE *)

    ATTRIBUTE : WORD;
    TIME      : LONGINT;

PROCEDURE INITIALIZE;
   Procedure SetVisualPalette (No,R,G,B:Byte);
      Begin
      Port[$3c8]:=No;      { Port nomor Palette }
      Port[$3c9]:=R;       { Isi Port Merah     }
      Port[$3c9]:=G;       { Isi Port Hijau     }
      Port[$3c9]:=B;       { Isi Port Biru      }
   End;
VAR B:BYTE;
BEGIN
   IF PARAMCOUNT<>1 THEN
      BEGIN
      WRITELN ('Syntax : HEXA <file_name>');
      HALT(1);
   END;
   NF:=PARAMSTR (1);
   FOR B:=1 TO LENGTH(NF) DO NF[B]:=UPCASE(NF[B]);
   {$I-}
   ASSIGN (F,NF);
   GETFATTR (F,ATTRIBUTE);
   SETFATTR (F,ARCHIVE);
   RESET (F,1);
   {$I+}
   IF IORESULT<>0 THEN
      BEGIN
      WRITELN ('Error in loading file ''',NF,''' ...');
      HALT(1);
   END;
   GETFTIME (F,TIME);
   PF := FILESIZE (F);
   ASM
      MOV AX,3
      INT 10H
      MOV AH,1
      XOR CH,CH
      MOV CL,7
      INT 10H
   END;
   SETVISUALPALETTE (4,63,63,63);
   SETVISUALPALETTE (5,0,16,32);
   SETVISUALPALETTE (1,0,0,20);
   TEXTBACKGROUND (5);
   CLRSCR;
   GETMEM (P1,MAX_MEM_USED);
   GETMEM (P2,MAX_MEM_USED);
END;

FUNCTION LOOP (C:CHAR;B:BYTE) : STRING;
VAR S:STRING;
BEGIN
   FILLCHAR (S,255,ORD(C));
   S[0]:=CHR(B);
   LOOP:=S;
END;

PROCEDURE PRINT (LX,LY,ATT:BYTE;LST:STRING);
VAR TMP1,TMP2:INTEGER;
BEGIN
   TMP1 := (((LY-1)*80)+LX-1) SHL 1;
   FOR TMP2:=0 TO LENGTH (LST)-1 DO
      BEGIN
      MEM[$B800:TMP1+TMP2 SHL 1] := ORD (LST[TMP2+1]);
      MEM[$B800:TMP1+1+TMP2 SHL 1] := ATT;
   END;
END;


PROCEDURE GANTI_KRKTR;
VAR  N         : ARRAY [1..16] OF BYTE;
   PROCEDURE SETCHAR(NUM : BYTE);
   VAR REG:REGISTERS;
   BEGIN
      REG.AX:=$1100;
      REG.ES:=SEG(n);
      REG.BP:=OFS(n);
      REG.DX:=num;
      REG.CX:=1;
      REG.BL:=0;
      REG.BH:=16;
      INTR($10,REG);
   END;
   FUNCTION BIN(BINER:STRING) : INTEGER;
   VAR  TWO        : INTEGER;
        I,HASIL    : INTEGER;
   BEGIN
      TWO   :=1;
      HASIL :=0;
      FOR I:=LENGTH(BINER) DOWNTO 1 DO
         BEGIN
         IF BINER[I] = '1' THEN HASIL:=HASIL+TWO;
         TWO:=TWO*2;
      END;
      BIN := HASIL;
   END;
BEGIN
   N[1] :=255;
   N[2] :=Bin('1       ');
   N[3] :=N[2];
   N[4] :=N[2];
   N[5] :=N[2];
   N[6] :=N[2];
   N[7] :=Bin('1  11111');
   N[8] :=N[7];
   N[9] :=N[7];
   N[10]:=N[7];
   N[11]:=N[2];
   N[12]:=N[2];
   N[13]:=N[2];
   N[14]:=N[2];
   N[15]:=N[2];
   N[16]:=255;
   Setchar(200);

   N[1] :=255;
   N[2] :=Bin('       1');
   N[3] :=N[2];
   N[4] :=N[2];
   N[5] :=N[2];
   N[6] :=N[2];
   N[7] :=Bin('11111  1');
   N[8] :=N[7];
   N[9] :=N[7];
   N[10]:=N[7];
   N[11]:=N[2];
   N[12]:=N[2];
   N[13]:=N[2];
   N[14]:=N[2];
   N[15]:=N[2];
   N[16]:=255;
   Setchar(201);

   N[1] :=0;
   N[2] :=0;
   N[3] :=Bin('111 1 1 ');
   N[4] :=Bin(' 1  111 ');
   N[5] :=Bin(' 1  1 1 ');
   N[6] :=Bin(' 1  1 1 ');
   N[7] :=0;
   N[8] :=0;
   N[9] :=0;
   N[10]:=0;
   N[11]:=0;
   N[12]:=0;
   N[13]:=0;
   N[14]:=0;
   N[15]:=0;
   N[16]:=0;
   Setchar(237);

   N[1] :=0;
   N[2] :=0;
   N[3] :=Bin('  1111  ');
   N[4] :=Bin(' 1    1 ');
   N[5] :=Bin('1  11  1');
   N[6] :=Bin('1 1  1 1');
   N[7] :=Bin('1 1    1');
   N[8] :=Bin('1 1    1');
   N[9] :=Bin('1 1  1 1');
   N[10]:=Bin('1  11  1');
   N[11]:=Bin(' 1    1 ');
   N[12]:=Bin('  1111  ');
   N[13]:=0;
   N[14]:=0;
   N[15]:=0;
   N[16]:=0;
   Setchar(238);

   N[1] :=0;
   N[2] :=Bin(' 1111111');
   N[3] :=N[2];
   N[4] :=Bin(' 111111 ');
   N[5] :=Bin(' 11111  ');
   N[6] :=Bin(' 1111   ');
   N[7] :=Bin(' 111    ');
   N[8] :=Bin(' 11     ');
   N[9] :=Bin(' 11111  ');
   N[10]:=N[9];
   N[11]:=N[9];
   N[12]:=N[9];
   N[13]:=N[9];
   N[14]:=Bin(' 1111111');
   N[15]:=N[14];
   N[16]:=0;
   Setchar(202);

   N[1] :=0;
   N[2] :=Bin('1111111 ');
   N[3] :=N[2];
   N[4] :=Bin(' 111111 ');
   N[5] :=Bin('  11111 ');
   N[6] :=Bin('   1111 ');
   N[7] :=Bin('    111 ');
   N[8] :=Bin('     11 ');
   N[9] :=Bin('  11111 ');
   N[10]:=N[9];
   N[11]:=N[9];
   N[12]:=N[9];
   N[13]:=N[9];
   N[14]:=Bin('1111111 ');
   N[15]:=N[14];
   N[16]:=0;
   Setchar(203);

   N[1] :=0;
   N[2] :=Bin(' 1111111');
   N[3] :=N[2];
   N[4] :=Bin(' 11111  ');
   N[5] :=N[4];
   N[6] :=N[4];
   N[7] :=N[4];
   N[8] :=N[4];
   N[9] :=Bin(' 11     ');
   N[10]:=Bin(' 111    ');
   N[11]:=Bin(' 1111   ');
   N[12]:=Bin(' 11111  ');
   N[13]:=Bin(' 111111 ');
   N[14]:=Bin(' 1111111');
   N[15]:=N[14];
   N[16]:=0;
   Setchar(204);

   N[1] :=0;
   N[2] :=Bin('1111111 ');
   N[3] :=N[2];
   N[4] :=Bin('  11111 ');
   N[5] :=N[4];
   N[6] :=N[4];
   N[7] :=N[4];
   N[8] :=N[4];
   N[9] :=Bin('     11 ');
   N[10]:=Bin('    111 ');
   N[11]:=Bin('   1111 ');
   N[12]:=Bin('  11111 ');
   N[13]:=Bin(' 111111 ');
   N[14]:=Bin('1111111 ');
   N[15]:=N[14];
   N[16]:=0;
   Setchar(205);

   N[1] := Bin(' 1 11111');
   N[2] := N[1];
   N[3] := N[1];
   N[4] := N[1];
   N[5] := N[1];
   N[6] := N[1];
   N[7] := N[1];
   N[8] := N[1];
   N[9] := N[1];
   N[10] := N[1];
   N[11] := N[1];
   N[12] := N[1];
   N[13] := N[1];
   N[14] := N[1];
   N[15] := N[1];
   N[16] := N[1];
   Setchar(206);

   N[1] := Bin('11111 1 ');
   N[2] := N[1];
   N[3] := N[1];
   N[4] := N[1];
   N[5] := N[1];
   N[6] := N[1];
   N[7] := N[1];
   N[8] := N[1];
   N[9] := N[1];
   N[10] := N[1];
   N[11] := N[1];
   N[12] := N[1];
   N[13] := N[1];
   N[14] := N[1];
   N[15] := N[1];
   N[16] := N[1];
   Setchar(207);
END;


PROCEDURE SAVE;
VAR W:WORD;
BEGIN
   SEEK (F,POSISI_MEMORI);
   IF POSISI_MEMORI+MAX_MEM_USED > PF THEN W:=PF-POSISI_MEMORI ELSE
      W:=MAX_MEM_USED;
   BLOCKWRITE (F,P1^,W);
   MOVE (P1^,P2^,MAX_MEM_USED);
END;

PROCEDURE DISCARD;
BEGIN
   MOVE (P2^,P1^,MAX_MEM_USED);
END;

FUNCTION CHANGED : BOOLEAN; ASSEMBLER;
   ASM
   PUSH DS
   MOV AX,FALSE
   MOV CX,MAX_MEM_USED
   SHR CX,1
   LES DI,P1
   LDS SI,P2
   REP CMPSW
   JE @LANJUT
   NOT AX

   @LANJUT:
   POP DS
END;

PROCEDURE ASK_FOR_CHANGED;
VAR C:CHAR;
BEGIN
   PRINT (1,24,(16*5)+15,LOOP(' ',58));
   GOTOXY (1,24);
   TEXTCOLOR (7);
   WRITE ('File has been changed. Save (Y/N) ? ');
   REPEAT
      C:=UPCASE(READKEY);
   UNTIL C IN ['Y','N'];
   IF C='Y' THEN SAVE ELSE DISCARD;
   PRINT (1,24,(16*5)+15,LOOP(' ',58));
END;


FUNCTION GETSTR (X,Y,MAXSTR,W1,W2:BYTE;S_AWAL:STRING) : STRING;
VAR S:STRING;
    C:CHAR;
    QUIT:BOOLEAN;
    FIRST_TIME:BOOLEAN;
BEGIN
   QUIT:=FALSE;
   FIRST_TIME:=TRUE;
   GOTOXY (X,Y);
   IF S_AWAL<>'' THEN
      BEGIN
      TEXTCOLOR (W2);
      TEXTBACKGROUND (W1);
      WRITE (S);
   END;
   S:='';
   TEXTCOLOR (W1);
   TEXTBACKGROUND (W2);
   REPEAT
      C:=READKEY;
      CASE C OF
         #13 : BEGIN
                  IF FIRST_TIME THEN S:=S_AWAL;
                  QUIT:=TRUE;
               END;
         #8  : IF LENGTH(S)>0 THEN
                  BEGIN
                  FIRST_TIME:=FALSE;
                  S:=COPY (S,1,LENGTH(S)-1);
                  GOTOXY (X,Y);
                  WRITE (S+' ');
                  GOTOXY (X,Y);
                  WRITE (S);
               END;
         #27 : BEGIN
                  FIRST_TIME:=FALSE;
                  GOTOXY (X,Y);
                  WRITE (LOOP(' ',LENGTH(S)));
                  S:='';
                  QUIT:=TRUE;
               END;
         #0  : WHILE KEYPRESSED DO C:=READKEY;
         ELSE IF LENGTH(S)<MAXSTR THEN S:=S+C;
      END;
      GOTOXY (X,Y); WRITE (S);
   UNTIL QUIT;
   GETSTR := S;
END;


PROCEDURE MAIN_PROGRAM;
CONST POSISI:LONGINT=0;

   PROCEDURE SET_BYTE (L:LONGINT;B:BYTE);
   VAR W : WORD;
   BEGIN
      W:=L-POSISI_MEMORI;
      ASM
         LES DI,P1
         ADD DI,W
         MOV AL,B
         MOV ES:[DI],AL
      END;
   END;

   FUNCTION D2H (B:BYTE) : STRING;  (* KONVERSI DESIMAL KE HEXA *)
   VAR S:STRING;
      FUNCTION D2H1(B1:BYTE):STRING;
      VAR S1:STRING;
      BEGIN
         CASE B1 OF
            0..9 : STR (B1,S1);
            10..15 : S1:=CHR(55+B1);
         END;
         D2H1:=S1;
      END;
   BEGIN
      S:='';
      S:=D2H1(B DIV 16)+D2H1(B MOD 16);
      D2H:=S;
   END;

   FUNCTION L2H (L:LONGINT) : STRING; (* KONVERSI LONGINT KE HEXA *)
   VAR B:BYTE;
       I:INTEGER;
       S:STRING;
       LP:^LONGINT;
   BEGIN
      S:='';
      GETMEM (LP,4);
      LP^:=L;
      FOR I:=3 DOWNTO 0 DO
         BEGIN
         ASM
            LES DI,LP
            ADD DI,I
            MOV AL,ES:[DI]
            MOV B,AL
         END;
         S:=S+D2H(B);
      END;
      L2H:=S;
      FREEMEM (LP,4);
   END;

   FUNCTION H2D (S:STRING) : BYTE; (* KONVERSI HEXA KE DESIMAL *)
      FUNCTION H2D1(S1:CHAR):BYTE;
      VAR B:BYTE;
          HASIL:INTEGER;
      BEGIN
         CASE S1 OF
            '0'..'9' : VAL (S1,B,HASIL);
            'A'..'F' : B:=ORD(S1)-ORD('A')+10;
         END;
         H2D1:=B;
      END;
   BEGIN
      H2D := H2D1(S[1])*16+H2D1(S[2]);
   END;


   PROCEDURE TAMPILKAN (L:LONGINT); FORWARD;
   CONST FIRST_TIME:BOOLEAN = TRUE;
   VAR   BERUBAH:BOOLEAN;                (* MEMBANDINGKAN 2 MEMORI *)
   FUNCTION GET_BYTE (L:LONGINT):BYTE;
   VAR W : WORD;
       B : BYTE;
       BOL : BOOLEAN;
   BEGIN
      IF (L>POSISI_MEMORI+MAX_MEM_USED-1) OR (L<POSISI_MEMORI) OR
         FIRST_TIME THEN
         BEGIN
         IF CHANGED AND NOT FIRST_TIME THEN
            BEGIN
            ASK_FOR_CHANGED;
            TAMPILKAN (POSISI);
         END;
         FIRST_TIME:=FALSE;
         POSISI_MEMORI := L-(MAX_MEM_USED DIV 2);
         IF POSISI_MEMORI < 0 THEN POSISI_MEMORI:=0;
         SEEK (F,POSISI_MEMORI);
         IF POSISI_MEMORI+MAX_MEM_USED > PF THEN W:=PF-POSISI_MEMORI ELSE
            W:=MAX_MEM_USED;
         BLOCKREAD (F,P1^,W);
         MOVE (P1^,P2^,MAX_MEM_USED);
         GET_BYTE:=GET_BYTE (L);
         BERUBAH:=FALSE;
      END ELSE
         BEGIN
         W := L-POSISI_MEMORI;
         BOL:=FALSE;
         ASM
            LES DI,P1
            ADD DI,W
            MOV AL,ES:[DI]
            LES DI,P2
            ADD DI,W
            MOV AH,ES:[DI]
            CMP AH,AL
            JE @LANJUT
            NOT BOL

            @LANJUT:
            MOV B,AL
         END;
         GET_BYTE := B;
         BERUBAH:=BOL;
      END;
   END;


   PROCEDURE TAMPILKAN (L:LONGINT);
   VAR X,Y : BYTE;
       B   : BYTE;
       L1  : LONGINT;
   BEGIN
      X:=0;
      Y:=0;
      L1:=L;
      IF L+256>PF THEN
         FOR B:=0 TO 15 DO
            PRINT (1,B+6,5*16+15,LOOP(' ',78));
      PRINT (1,Y+6,5*16+15,L2H(L1));
      WHILE (L1<PF) AND (Y<=15) DO
         BEGIN
         B:=GET_BYTE(L1);
         IF BERUBAH THEN PRINT (X*3+11,Y+6,5*16+14,D2H(B)) ELSE
            PRINT (X*3+11,Y+6,5*16+15,D2H(B));
         IF NOT (B IN [$D,$A,7,8]) THEN
            BEGIN
            IF BERUBAH THEN PRINT (X+60,Y+6,5*16+14,CHR(B)) ELSE
            PRINT (X+60,Y+6,5*16+15,CHR(B));
         END ELSE PRINT (X+60,Y+6,5*16+15,' ');
         INC (L1);
         INC (X);
         IF X>15 THEN
            BEGIN
            X:=0;
            INC (Y);
            IF Y<=15 THEN
               BEGIN
               IF BERUBAH THEN PRINT (1,Y+6,5*16+14,L2H(L1)) ELSE
               PRINT (1,Y+6,5*16+15,L2H(L1));
            END;
         END;
      END;
      GOTOXY (3,1);                          (* SEMBUNYIKAN KURSOR *)
   END;


   PROCEDURE SET_MENU_BOTTOM(S1,S2,S3,S4,S5,S6,S7,S8,S9,S10:STRING);
   VAR B:BYTE;
   BEGIN
      TEXTBACKGROUND (1);
      GOTOXY (1,25);
      CLREOL;
      FOR B:=1 TO 10 DO
         BEGIN
         TEXTCOLOR (14);
         GOTOXY ((B-1)*8,25);
         WRITE (B);
         TEXTCOLOR (15);
         CASE B OF
            1 : WRITE (S1);
            2 : WRITE (S2);
            3 : WRITE (S3);
            4 : WRITE (S4);
            5 : WRITE (S5);
            6 : WRITE (S6);
            7 : WRITE (S7);
            8 : WRITE (S8);
            9 : WRITE (S9);
            10 : WRITE (S10);
         END;
      END;
      TEXTBACKGROUND (5);
      TEXTCOLOR (15);
   END;

   PROCEDURE MENU_EDIT;
   BEGIN
      SET_MENU_BOTTOM ('Help','','Exit','','Save','Offset','','Asc/Hx','Srch T','Srch N');
   END;

CONST QUIT:BOOLEAN=FALSE;
      EDIT:BOOLEAN=FALSE;
      ASCII:BOOLEAN=FALSE;
      SWAP:BOOLEAN=TRUE;
      POSISI_EDIT:BYTE=0;
      HILO_EDIT:BOOLEAN=FALSE;
      EXTENDED_CHAR:BOOLEAN=FALSE;

   PROCEDURE CARI (VAR STR;PJG_STR:BYTE);
   VAR BUFFER       : POINTER;
       POSITION     : LONGINT;
       ADA          : WORD;
   FUNCTION SEARCHTEXT (VAR SOURCE;VAR DEST;PJG1,PJG2:WORD) : WORD;
   (*
   CARA PENGGUNAAN :
     - SOURCE          : VARIABEL POINTER YG. AKAN DIBANDINGKAN
     - DEST            : VARIABEL POINTER YG. AKAN DITUJU
     - PJG1            : PANJANG VARIABEL SOURCE (1-65535)
     - PJG2            : PANJANG VARIABEL DEST   (1-65535)
     - MULAI           : LOKASI DEST YG. PERTAMA AKAN DICARI (1-65535)
   *)
   ASSEMBLER;
      ASM
      PUSH DS
      LES DI,DEST
      LDS SI,SOURCE
      XOR AX,AX          (*HASIL PD. FUNCTION*)
      MOV BX,DI          (*LOKASI DEST PERTAMA*)
      MOV CX,PJG2        (*JLH. PERULANGAN*)
      DEC CX
      MOV DL,DS:[SI]     (*AMBIL KARAKTER PERTAMA DARI SOURCE*)

      @LAGI:
      CMP DL,ES:[DI]     (*APAKAH KARAKTER PERTAMA SOURCE = DEST*)
      JE @CEK_LAGI       (*KALAU ADA, CARI KARAKTER SELANJUTNYA*)

      @RUPANYA_BUKAN:
      INC DI             (*CARI LAGI ...*)
      LOOP @LAGI
      JMP @KELUAR        (*KALAU NDAK ADA YA EXIT*)

      @CEK_LAGI:
      PUSH DI            (*SIMPAN DULU REGISTER YG. AKAN DIUBAH*)
      PUSH SI
      PUSH CX
      MOV CX,PJG1
      REPE CMPSB         (*TENTUKAN APAKAH KARAKTER SELANJUTNYA SAMA*)
      POP CX
      POP SI
      POP DI
      JNE @RUPANYA_BUKAN

      SUB DI,BX          (*TENTUKAN HASIL PD. FUNCTION*)
      MOV AX,DI
      INC AX             (*AGAR HASILNYA MULAI DARI 1,2,DST...*)

      @KELUAR:
      POP DS
   END;
   PROCEDURE CAPITAL (VAR SOURCE;PJG1 : WORD);
   ASSEMBLER;
      ASM
      PUSH DS
      LDS SI,SOURCE
      MOV CX,PJG1
      @ULANGI:
      LODSB
      CMP AL,'a'
      JL @TERUS
      CMP AL,'z'
      JA @TERUS
      AND AL,0DFh
      MOV DS:[SI-1],AL
      @TERUS:
      LOOP @ULANGI
      POP DS
   END;
   PROCEDURE CARI_WORD (BANYAKNYA : WORD);
   VAR PERCENT    : BYTE;
       POSISI_NOW : LONGINT;
       HASIL      : WORD;
   BEGIN
      BLOCKREAD (F,BUFFER^,BANYAKNYA);
      CAPITAL (BUFFER^,BANYAKNYA);
      HASIL := SEARCHTEXT (STR,BUFFER^,PJG_STR,BANYAKNYA);
      IF HASIL <> 0 THEN
         BEGIN
         INC (ADA);
         (* POSISI ABSOLUT : PF-POSITION+HASIL+MULAI-2 *)
         HILO_EDIT:=FALSE;
         MENU_EDIT;
         EDIT:=TRUE;
         POSISI:=((PF-POSITION+HASIL-1) DIV 256)*256;
         TAMPILKAN (POSISI);
         POSISI_EDIT:=(PF-POSITION+HASIL-1)-POSISI;
         END ELSE
         (*KURANGI LOKASI AKHIR PEMBACAAN AGAR HASILNYA AKURAT*)
         BEGIN
         DEC (POSITION,BANYAKNYA-PJG_STR);
         SEEK (F,PF-POSITION);
      END;
   END;
   BEGIN
      ADA:=0;
      GETMEM (BUFFER,MAX_MEM_USED);
      POSITION := PF-POSISI-POSISI_EDIT-1;
      SEEK(F,POSISI+POSISI_EDIT+1);
      WHILE (POSITION>MAX_MEM_USED) AND (ADA=0) DO CARI_WORD (MAX_MEM_USED);
      IF ADA=0 THEN CARI_WORD (POSITION);
      FREEMEM (BUFFER,MAX_MEM_USED);
   END;

   PROCEDURE JUDUL;
   VAR B : BYTE;
   BEGIN
      (* JUDUL & FOOTER *)
      TEXTCOLOR (15);
      GOTOXY (3,3);
      WRITE (NF);

      GOTOXY (1,1);
      TEXTBACKGROUND (4);
      TEXTCOLOR (0);
      WRITE (#200,#201);
      TEXTCOLOR (4);
      WRITE (' ');
      TEXTCOLOR (0);
      CLREOL;
      GOTOXY (35,1);
      WRITELN ('FILE EDITOR');
      TEXTCOLOR (7);
      TEXTBACKGROUND (5);
      GOTOXY (60,24);
      WRITE (#238,MAKER,#237);
      GOTOXY (79,2);
      TEXTCOLOR (4);
      TEXTBACKGROUND (0);
      WRITE (#202,#203);
      GOTOXY (79,24);
      WRITE (#204,#205);
      FOR B:=3 TO 23 DO
         BEGIN
         GOTOXY (79,B);
         WRITE (#206,#207);
      END;
      SET_MENU_BOTTOM ('Help','','Exit','','','Offset','Edit','','Srch T','Srch N');
   END;

   CONST BAR_OLD:BYTE=0;
   PROCEDURE UPDATE_BAR;
   VAR BAR:BYTE;
   BEGIN
      BAR:=3+((POSISI+POSISI_EDIT)*21 DIV PF);
      IF BAR<>BAR_OLD THEN
         BEGIN
         IF BAR_OLD<>0 THEN PRINT (79,BAR_OLD,4,#206#207);
         PRINT (79,BAR,1,#206#207);
         BAR_OLD:=BAR;
      END;
   END;

   PROCEDURE GESER_KANAN;
   BEGIN
      IF ASCII THEN HILO_EDIT:=TRUE;
      IF NOT HILO_EDIT THEN HILO_EDIT:=TRUE ELSE
         BEGIN
         IF POSISI+POSISI_EDIT+1<PF THEN
            BEGIN
            IF (POSISI_EDIT<255) THEN
               BEGIN
               INC(POSISI_EDIT);
               HILO_EDIT:=FALSE;
               END ELSE
               BEGIN
               INC(POSISI,16);
               TAMPILKAN (POSISI);
               DEC(POSISI_EDIT,15);
               HILO_EDIT:=FALSE;
            END;
         END;
      END;
   END;

   PROCEDURE GESER_KIRI;
   BEGIN
      IF ASCII THEN HILO_EDIT:=FALSE;
      IF HILO_EDIT THEN HILO_EDIT:=FALSE ELSE
         BEGIN
         IF POSISI+POSISI_EDIT>0 THEN
            BEGIN
            IF (POSISI_EDIT>0) THEN
               BEGIN
               DEC(POSISI_EDIT);
               HILO_EDIT:=TRUE;
               END ELSE
               BEGIN
               DEC(POSISI,16);
               IF POSISI<0 THEN POSISI:=0;
               TAMPILKAN (POSISI);
               INC(POSISI_EDIT,15);
               HILO_EDIT:=TRUE;
            END;
         END;
      END;
   END;

   PROCEDURE GESER_BAWAH;
   BEGIN
      IF POSISI+POSISI_EDIT+16<PF THEN
         BEGIN
         IF (POSISI_EDIT+15<255) THEN
            BEGIN
            INC(POSISI_EDIT,16);
            END ELSE
            BEGIN
            INC(POSISI,16);
            TAMPILKAN (POSISI);
         END;
      END;
   END;

   PROCEDURE GESER_ATAS;
   BEGIN
      IF POSISI+POSISI_EDIT>0 THEN
         BEGIN
         IF (POSISI_EDIT>15) THEN
            BEGIN
            DEC(POSISI_EDIT,16);
            END ELSE
            BEGIN
            DEC(POSISI,16);
            IF POSISI<0 THEN POSISI:=0;
            TAMPILKAN (POSISI);
         END;
      END;
   END;

   FUNCTION PANJANG_BIL (VAR D) : BYTE; ASSEMBLER;
   ASM
      LES DI,D
      MOV AL,4
      MOV AH,ES:[DI]
      MOV BH,ES:[DI+1]
      MOV CH,ES:[DI+2]
      MOV DH,ES:[DI+3]
      CMP DH,0
      JNE @QUIT
      DEC AL
      CMP CH,0
      JNE @QUIT
      DEC AL
      CMP BH,0
      JNE @QUIT
      DEC AL
      CMP AH,0
      JNE @QUIT
      DEC AL
      @QUIT:
      XOR AH,AH
   END;
   PROCEDURE BALIK (VAR D;W:WORD) ; ASSEMBLER;
   ASM
      LES DI,D
      MOV CX,W
      @1:
      MOV AL,ES:[DI]
      PUSH AX
      INC DI
      LOOP @1

      LES DI,D
      MOV CX,W
      @2:
      POP AX
      MOV ES:[DI],AL
      INC DI
      LOOP @2
   END;
   PROCEDURE COMPRESS (VAR D); ASSEMBLER;
   ASM
      LES DI,D
      XOR AL,AL
      MOV CX,4

      @1:
      MOV AH,ES:[DI]
      CMP AH,0
      JNE @2
      INC AL
      INC DI
      LOOP @1

      @2:
      PUSH DS
      XOR AH,AH
      LES DI,D
      LDS SI,D
      ADD SI,AX
      MOV CX,4
      SUB CX,AX
      REP MOVSB
      POP DS
   END;


VAR CH : CHAR;
    BY : BYTE;
    ST : STRING;
    L  : LONGINT;
    CEK: INTEGER;
CONST FIND_OLD_ST:STRING = '';    (* STRING YG. SEBELUMNYA TELAH DICARI *)
      FIND_OLD_NM:STRING = '';

BEGIN
   JUDUL;
   TAMPILKAN (POSISI);
   UPDATE_BAR;
   REPEAT
      REPEAT UNTIL KEYPRESSED;
      CH:=READKEY;
      IF (CH=#27) THEN
         IF EDIT THEN
            BEGIN
            IF CHANGED THEN ASK_FOR_CHANGED;
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            JUDUL;
            UPDATE_BAR;
            POSISI_EDIT:=0;
            HILO_EDIT:=FALSE;
            EDIT:=FALSE;
            ASCII:=FALSE;
            POSISI:=(POSISI DIV 256)*256;
            TAMPILKAN(POSISI);
            END ELSE QUIT:=TRUE;
      IF CH=#0 THEN
         BEGIN
         CH:=READKEY;
         IF CH='=' THEN
            BEGIN
            IF CHANGED THEN ASK_FOR_CHANGED;
            QUIT:=TRUE; (* F3 DITEKAN *)
         END;
         IF CH='I' THEN             (* PgUp DITEKAN *)
            BEGIN
            IF POSISI>0 THEN
               BEGIN
               DEC (POSISI,256);
               IF POSISI<0 THEN POSISI:=0;
               TAMPILKAN (POSISI);
            END;
         END;
         IF CH='Q' THEN             (* PgDn DITEKAN *)
            BEGIN
            IF POSISI+255<PF THEN
               BEGIN
               INC (POSISI,256);
               TAMPILKAN (POSISI);
            END;
            IF POSISI+POSISI_EDIT>=PF THEN
               BEGIN
               POSISI_EDIT:=PF-POSISI-1;
               HILO_EDIT:=TRUE;
            END;
         END;
         IF CH='O' THEN            (* END DITEKAN *)
            BEGIN
            IF EDIT THEN
               BEGIN
               IF POSISI+255>PF-1 THEN POSISI_EDIT:=PF-1-POSISI ELSE
                  POSISI_EDIT:=255;
               HILO_EDIT:=TRUE;
               END ELSE
               BEGIN
               POSISI:=PF-PF MOD 256;
               TAMPILKAN (POSISI);
            END;
         END;
         IF (CH='G') THEN            (* HOME DITEKAN *)
            BEGIN
            IF EDIT THEN
               BEGIN
               POSISI_EDIT:=0;
               HILO_EDIT:=FALSE;
               END ELSE
               BEGIN
               POSISI:=0;
               TAMPILKAN (POSISI);
            END;
         END;
         IF CH='A' THEN            (* F7 DITEKAN *)
            BEGIN
            MENU_EDIT;
            EDIT:=TRUE;
         END;
         IF CH='B' THEN            (* F8 DITEKAN *)
            BEGIN
            HILO_EDIT:=FALSE;
            ASCII:=NOT(ASCII);
         END;
         IF (CH='C') OR (CH='D') THEN            (* F9&F10 DITEKAN *)
            BEGIN
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            IF CH='D' THEN
               IF SWAP THEN PRINT (40,24,(16*5)+7,'(þ) Swap') ELSE
               PRINT (40,24,(16*5)+7,'( ) Swap');
            TEXTCOLOR(7);
            GOTOXY(1,24);
            WRITE ('Search : ');
            ST:='';
            IF ((FIND_OLD_ST<>'') AND (CH='C')) OR
               ((FIND_OLD_NM<>'') AND (CH='D')) THEN
               BEGIN
               TEXTCOLOR (5);
               TEXTBACKGROUND (7);
               IF CH='C' THEN WRITE (FIND_OLD_ST) ELSE WRITE (FIND_OLD_NM);
               REPEAT UNTIL KEYPRESSED;
               TEXTCOLOR (7);
               TEXTBACKGROUND (5);
            END;
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            IF CH='D' THEN
               IF SWAP THEN PRINT (40,24,(16*5)+7,'(þ) Swap') ELSE
               PRINT (40,24,(16*5)+7,'( ) Swap');
            GOTOXY(1,24);
            WRITE ('Search : ');
            READLN (ST);
            IF (ST='') THEN
               IF CH='C' THEN ST:=FIND_OLD_ST ELSE ST:=FIND_OLD_NM;
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            GOTOXY (3,1);
            IF ST<>'' THEN
               BEGIN
               FOR CEK:=1 TO LENGTH(ST) DO ST[CEK]:=UPCASE(ST[CEK]);
               IF CH='C' THEN CARI(ST[1],LENGTH(ST)); (* UNTUK F9 *)
               IF CH='D' THEN                         (* UNTUK F10 *)
                  BEGIN
                  VAL(ST,L,CEK);
                  IF CEK=0 THEN
                     BEGIN
                     BY:=PANJANG_BIL(L);
                     IF SWAP THEN
                        BEGIN
                        BALIK (L,4);
                        COMPRESS (L);
                     END;
                     CARI (L,BY);
                  END;
               END;
            END;
            TEXTCOLOR (15);
            IF CH='C' THEN FIND_OLD_ST:=ST ELSE FIND_OLD_NM:=ST;
         END;
         IF CH='@' THEN            (* F6 DITEKAN *)
            BEGIN
            REPEAT
               TEXTCOLOR (7);
               PRINT (1,24,(16*5)+15,LOOP(' ',58));
               GOTOXY (1,24);
               WRITE ('Absolute Offset : ');
               READLN (ST);
               VAL (ST,L,CEK);
            UNTIL (CEK=0) OR (ST='');
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            TEXTCOLOR (15);
            IF (L<PF) AND (ST<>'') THEN
               BEGIN
               EDIT:=TRUE;
               HILO_EDIT:=FALSE;
               POSISI:=(L DIV 256)*256;
               TAMPILKAN (POSISI);
               POSISI_EDIT:=L-POSISI;
            END;
            GOTOXY (3,1);
         END;
         IF (CH='?') AND EDIT THEN            (* F5 DITEKAN *)
            BEGIN
            SAVE;
            PRINT (1,24,(16*5)+15,LOOP(' ',58));
            JUDUL;
            UPDATE_BAR;
            POSISI_EDIT:=0;
            HILO_EDIT:=FALSE;
            EDIT:=FALSE;
            ASCII:=FALSE;
            POSISI:=(POSISI DIV 256)*256;
            TAMPILKAN(POSISI);
         END;
         IF (CH='M') AND EDIT THEN            (* RIGHT DITEKAN *)
            GESER_KANAN;
         IF (CH='K') AND EDIT THEN            (* LEFT DITEKAN *)
            GESER_KIRI;
         IF (CH='P') AND EDIT THEN            (* DOWN DITEKAN *)
            GESER_BAWAH;
         IF (CH='H') AND EDIT THEN            (* UP DITEKAN *)
            GESER_ATAS;
         EXTENDED_CHAR:=TRUE;
         UPDATE_BAR;
      END;
{      GOTOXY (1,23); WRITE (CH); GOTOXY (3,1);}
      IF EDIT THEN
         BEGIN
         TEXTCOLOR (7);
         PRINT (1,24,(16*5)+15,LOOP(' ',58));
         GOTOXY (1,24); WRITE ('Position : ',POSISI+POSISI_EDIT);
         IF ASCII AND NOT EXTENDED_CHAR THEN
            BEGIN
            TEXTCOLOR (14);
            GOTOXY ((POSISI_EDIT MOD 16)+60,(POSISI_EDIT DIV 16)+6);
            IF NOT (ORD(CH) IN [$D,$A,7,8]) THEN WRITE (CH) ELSE WRITE (' ');
            GOTOXY ((POSISI_EDIT MOD 16)*3+11,
            (POSISI_EDIT DIV 16)+6);
            WRITE (D2H(ORD(CH)));
            SET_BYTE (POSISI+POSISI_EDIT,ORD(CH));
            GESER_KANAN;
         END ELSE
         IF (NOT ASCII) AND (NOT EXTENDED_CHAR) AND
            (UPCASE(CH) IN ['0'..'9','A'..'F']) THEN
            BEGIN
            ST:=D2H(GET_BYTE(POSISI+POSISI_EDIT));
            GOTOXY ((POSISI_EDIT MOD 16)*3+11,(POSISI_EDIT DIV 16)+6);
            ST[ORD(HILO_EDIT)+1]:=UPCASE(CH);
            TEXTCOLOR (14);
            WRITE (ST);
            CH:=CHR(H2D(ST));
            GOTOXY ((POSISI_EDIT MOD 16)+60,(POSISI_EDIT DIV 16)+6);
            IF NOT (ORD(CH) IN [$D,$A,7,8]) THEN WRITE (CH) ELSE WRITE (' ');
            SET_BYTE (POSISI+POSISI_EDIT,ORD(CH));
            GESER_KANAN;
         END;
         IF ASCII THEN
            GOTOXY ((POSISI_EDIT MOD 16)+60,(POSISI_EDIT DIV 16)+6)
            ELSE
            GOTOXY ((POSISI_EDIT MOD 16)*3+11+ORD(HILO_EDIT),
            (POSISI_EDIT DIV 16)+6);
         TEXTCOLOR (15);
      END;
      EXTENDED_CHAR:=FALSE;
   UNTIL QUIT;
END;

PROCEDURE DEINITIALIZE;
BEGIN
   SETFTIME (F,TIME);
   CLOSE (F);
   SETFATTR (F,ATTRIBUTE);
   TEXTBACKGROUND (0);
   TEXTCOLOR (7);
   FREEMEM (P2,MAX_MEM_USED);
   FREEMEM (P1,MAX_MEM_USED);
   ASM
      MOV AX,3
      INT 10H
   END;
   WRITELN ('Thank you for using this programs ...');
END;


BEGIN
   INITIALIZE;
   GANTI_KRKTR;
   MAIN_PROGRAM;
   DEINITIALIZE;
END.

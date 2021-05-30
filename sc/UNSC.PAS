(*
 UNSC.PAS  -  UNSTEALTH
*)

{$G-,E-,N-}

PROGRAM UNSC;
USES CRT,DOS,AUTHOR,BSLZH1;

CONST JUDUL       : STRING[20]  = 'STEALTH-COPY 5.1';
      BUFFER                = 30000;
      BESAR_POINTER         = 30000;

TYPE  FTYPE       = RECORD
                       FATTR       : BYTE;
                       FTIME,FSIZE : LONGINT;
                       KOMP_TYPE   : BYTE;
                    END;

VAR   NAMA                    : STRING;
      ATR                     : FTYPE;
      DATUM                   : POINTER;
      NO_DISK                 : LONGINT;
      SOURCE,KOMP_TEMP,
      CURRENT_DIR             : STRING;
      NOW                     : LONGINT;
      F1,F2                   : FILE;
      REPLACE_ALL,REPLACE     : BOOLEAN;

      (* VARIABEL UNTUK TAMPILAN *)
      JUM_FILE,JUM_EXTRC,JUM_ERROR,
      BESAR_UNCOMP,BESAR_COMP : LONGINT;

      (* VARIABEL UTK. DISKET YG. RUSAK *)
      POINTERFILE_OLD         : LONGINT;

      (* UTK. KOMPRESI *)
      INFILE,OUTFILE        : FILE;
      IBUF,OBUF             : POINTER;
      ERROR_UNCOMP          : BOOLEAN;

      (* UTK. CHECKSUM *)
      JUDUL_CHK             : STRING[20];
      CHKSUM,CHKSUM_CHK     : WORD;

      (* UTK. LONG FILE NAME *)
      WIN95LFN              : BOOLEAN;

      (* UTK. TEST ARCHIVE *)
      TEST                  : BOOLEAN;
      SIZE_AFTER_DECOMPRESSION: LONGINT;

   PROCEDURE PESAN_SPONSOR (STOP:BOOLEAN;CONST PESAN:STRING);
      BEGIN
      TEXTCOLOR (14);
      WRITELN (JUDUL,' FREEWARE - June 17, 1999');
      TEXTCOLOR (10);
      WRITE ('Created by ',MAKER);
      TEXTCOLOR (8);
      WRITELN (' (mckev@hotmail.com)');
      TEXTCOLOR (7);
      WRITELN;
      IF PESAN='Start' THEN EXIT;
      TEXTCOLOR (12);
      WRITE ('Usage: ');
      TEXTCOLOR (11); TEXTBACKGROUND (1);
      WRITE ('UNSC [source_file] [/t]');
      TEXTCOLOR (12); TEXTBACKGROUND (0);
      WRITELN;
      WRITELN;
      WRITE   ('Examples: ');
      TEXTCOLOR (9);
      WRITELN ('ù UNSC FILE');
      WRITELN ('          ù UNSC A:\FILE.S03');
      WRITELN ('          ù UNSC A:\FILE.S03 /T');
      TEXTCOLOR (12);
      WRITELN ('Note: ');
      TEXTCOLOR (9);
      WRITELN ('    ¯ This program will automatically extract the files to current drive');
      IF GETENV('TEMP')='' THEN
         BEGIN
         WRITELN ('    ¯ Set "TEMP" in Dos Environment to locate the temporary files, otherwise');
         WRITELN ('      I''ll use C:\ instead');
      END;
      WRITELN ('    ¯ Use /t option to test integrity of archive');
      WRITELN;
      TEXTCOLOR (12);
      WRITELN ('Features:');
      TEXTCOLOR (9);
      WRITE   ('    ¯ Support Long File Name mode ');
      TEXTCOLOR (13);
      IF WIN95LFN THEN WRITELN ('<enabled>') ELSE WRITELN ('<disabled>');
      TEXTCOLOR (9);
      WRITELN ('    ¯ CRC-16 to ensure data integrity');
      WRITELN ('    ¯ Skip file(s) on bad media');
      WRITELN ('    ¯ Multiple Disks supported');
      WRITE   ('    ¯ Resume Mode! and Repeat Mode! technology');
      TEXTCOLOR (7);
      WRITELN;
      IF PESAN<>'' THEN
         BEGIN
         WRITELN;
         TEXTCOLOR (12);
         WRITE ('ERROR: ');
         TEXTCOLOR (10);
         WRITE (PESAN);
         TEXTCOLOR (7);
         WRITELN;
      END;
      IF STOP THEN HALT;
   END;
   PROCEDURE CHECK_LFN_SUPPORT;
   VAR P:POINTER;
       RESULT:BOOLEAN;
   BEGIN
      GETMEM (P,1024);
      RESULT := TRUE;
      ASM
         PUSH DS
         MOV AX,7147H
         XOR DL,DL
         LDS SI,P
         INT 21H
         POP DS
         JC @NOT_SUPP
         CMP AX,7100H
         JNE @QUIT
         @NOT_SUPP:
         MOV RESULT,FALSE
         @QUIT:
      END;
      FREEMEM (P,1024);
      WIN95LFN:=RESULT;
   END;
   FUNCTION UPCASES (S:STRING) : STRING;
   VAR T:BYTE;
   BEGIN
      FOR T:=1 TO LENGTH(S) DO S[T]:=UPCASE(S[T]);
      UPCASES:=S;
   END;

PROCEDURE INITIALIZE;
VAR I       : BYTE;
    S1,S2   : STRING;
    T1,T2   : BYTE;
    TEMP    : STRING;
    ERR     : INTEGER;

BEGIN
   CHECK_LFN_SUPPORT;

   (* SET SCREEN *)
   TEXTBACKGROUND (0);
   ASM
      MOV AX,1003H
      MOV BL,1
      INT 10H
   END;

   (* AMBIL PARAMETER *)
   FOR I:=1 TO PARAMCOUNT DO
      BEGIN
      S1 := UPCASES (PARAMSTR(I));
      T1 := POS ('/',S1);
      WHILE T1<>0 DO
         BEGIN
         S1[T1] := '~';
         T2 := POS ('/',S1);
         IF T2=0 THEN T2:=LENGTH(S1)+1;
         S2 := COPY (S1,T1+1,T2-T1-1);
         IF (S2='?') THEN PESAN_SPONSOR (TRUE,'') ELSE
         IF (S2='T') THEN TEST:=TRUE ELSE
         PESAN_SPONSOR (TRUE,'Invalid Argument.');
         S1 := COPY(S1,1,T1-1)+COPY(S1,T2,LENGTH(S1)-T2+1);
         T1 := POS ('/',S1);
      END;
      IF (S1<>'') THEN
         IF (SOURCE<>'') THEN PESAN_SPONSOR (TRUE,'') ELSE
         SOURCE:=S1;
   END;

   (* CEK APAKAH PARAMETER SUDAH BENAR? *)
   IF SOURCE='' THEN PESAN_SPONSOR (TRUE,'');
   IF (POS ('.',SOURCE)<>0) THEN
      BEGIN
      VAL (COPY (SOURCE,POS('.',SOURCE)+2,LENGTH(SOURCE)-POS('.',SOURCE)-1),
         NO_DISK,ERR);
      IF (ERR<>0) OR (UPCASE(SOURCE[POS('.',SOURCE)+1])<>'S') THEN
         PESAN_SPONSOR(TRUE,'Invalid file extension...');
      SOURCE:=COPY (SOURCE,1,POS('.',SOURCE)-1);
   END ELSE NO_DISK:=1;

   (* PERHITUNGAN LOKASI TEMPORARY FILES *)
   GETDIR (0,CURRENT_DIR);

   IF GETENV ('TEMP')='' THEN KOMP_TEMP := 'C:\'
      ELSE KOMP_TEMP := GETENV('TEMP');
   IF KOMP_TEMP [LENGTH(KOMP_TEMP)] <> '\' THEN KOMP_TEMP := KOMP_TEMP+'\';
   KOMP_TEMP := KOMP_TEMP+'TEMPFILE.~MP';
END;

   VAR ERR:INTEGER;
   FUNCTION EXIST (S:STRING) : BOOLEAN;
   VAR F : FILE;
       RESULT : BOOLEAN;
       P,HASIL:POINTER;
   BEGIN
      IF NOT WIN95LFN THEN
         BEGIN
         {$I-}
         ASSIGN (F, S);
         FILEMODE := 0;
         RESET (F);
         CLOSE (F);
         {$I+}
         EXIST := (IORESULT=0) AND (S <> '');
      END ELSE
         BEGIN
         P:=ADDR(S[1]);
         S:=S+#0;
         GETMEM (HASIL,512);
         ASM
            PUSH DS
            MOV AX,714EH
            MOV CX,ANYFILE
            LES DI,HASIL
            LDS DX,P
            XOR SI,SI
            INT 21H
            (* AMBIL HANDLE FINDFIRST *)
            MOV BX,AX
            POP DS
            MOV RESULT,TRUE
            JNC @QUIT
            MOV RESULT,FALSE
            @QUIT:
            (* TERMINATE FINDFIRST DENGAN HANDLE BX *)
            MOV AX,71A1H
            INT 21H
         END;
         FREEMEM (HASIL,512);
         EXIST := RESULT AND (S <> '');
      END;
   END;
   PROCEDURE SET_ATTRIBUT_LFN (S:STRING;ATTR:WORD);
   VAR P:POINTER;
       F:FILE;
   BEGIN
      IF WIN95LFN THEN
         BEGIN
         P:=ADDR(S[1]);
         S:=S+#0;
         (* UBAH ATTRIBUT *)
         ASM
            PUSH DS
            MOV AX,7143h
            MOV BL,1
            MOV CX,ATTR
            LDS DX,P
            INT 21H
            POP DS
         END;
      END ELSE
         BEGIN
         ASSIGN (F,S);
         SETFATTR (F,ATTR);
         ERR:=DOSERROR;
      END;
   END;
   PROCEDURE KILL_LFN (S:STRING);
   VAR P:POINTER;
       ERR1:INTEGER;
       F:FILE;
   BEGIN
      SET_ATTRIBUT_LFN (S,$20);
      IF WIN95LFN THEN
         BEGIN
         S:=S+#0;
         P:=ADDR(S[1]);
         ASM
            PUSH DS
            LDS DX,P
            MOV AX,7141h
            XOR SI,SI
            INT 21H
            POP DS
            MOV ERR1,0
            JNC @QUIT
            MOV ERR1,AX
            @QUIT:
         END;
      END ELSE
         BEGIN
         ASSIGN (F,S);
         {$I-}
         ERASE (F);
         {$I+}
         ERR1:=IORESULT;
      END;
      ERR:=ERR1;
   END;
   FUNCTION CONVERT_TO_LFN (CONST S:STRING):STRING;
   VAR P,HASIL   : POINTER;
       ST,RESULT : STRING;
       B         : BYTE;
   BEGIN
      CONVERT_TO_LFN := S;
      IF NOT WIN95LFN THEN EXIT;
      P:=ADDR(ST[1]);
      GETMEM(HASIL,512);
      B:=4;
      RESULT:=COPY (S,1,3);
      WHILE B<=LENGTH(S) DO
         BEGIN
         IF (S[B]='\') OR (B=LENGTH(S)) THEN
            BEGIN
            IF B=LENGTH(S) THEN ST:=S+#0 ELSE ST:=COPY(S,1,B-1)+#0;
            ASM
               PUSH DS
               MOV AX,714EH
               MOV CX,110111B
               LES DI,HASIL
               LDS DX,P
               XOR SI,SI
               INT 21H
               (* AMBIL HANDLE FINDFIRST *)
               MOV BX,AX
               POP DS
               JNC @LANJUT
               (* KALAU ERROR, AMBIL NAMANYA DARI ST *)
               PUSH DS
               XOR AX,AX
               LES DI,P
               LDS SI,P
               DEC SI
               LODSB
               ADD SI,AX
               @2:
               DEC SI
               CMP BYTE PTR DS:[SI-1],'\'
               JNE @2
               XOR CX,CX
               JMP @1

               (* AMBIL LFN-NYA *)
               @LANJUT:
               PUSH DS
               LES DI,P
               LDS SI,HASIL
               ADD SI,44
               XOR CX,CX
               @1:
               INC CX
               MOVSB
               OR BYTE PTR DS:[SI],0
               JNZ @1
               LES DI,P
               MOV ES:[DI-1],CL
               POP DS
               @QUIT:
               (* TERMINATE FINDFIRST DENGAN HANDLE BX *)
               MOV AX,71A1H
               INT 21H
            END;
            RESULT:=RESULT+ST+'\';
         END;
         INC(B);
      END;
      FREEMEM(HASIL,512);
      RESULT:=COPY(RESULT,1,LENGTH(RESULT)-1);
      CONVERT_TO_LFN := RESULT;
   END;
   FUNCTION CONVERT_TO_SFN (CONST S:STRING):STRING;
   VAR ST1,ST2,ST3,RESULT : STRING;
       D                  : SEARCHREC;
       KETEMU             : BOOLEAN;

   BEGIN
      CONVERT_TO_SFN := S;
      IF (NOT WIN95LFN) OR (NOT EXIST(S)) THEN EXIT;
      RESULT:=COPY (S,1,3);
      ST1:=S;
      ERR:=0;
      REPEAT
         DELETE (ST1,1,POS('\',ST1));
         ST2:=ST1;
         IF POS('\',ST2)<>0 THEN ST2:=COPY(ST2,1,POS('\',ST2)-1);
         (* CARI SHORT FILE NAME DARI RESULT+ST2 *)
         FINDFIRST (RESULT+ST2[1]+'*.*',ANYFILE,D);

         (* VARIABEL KETEMU = TRUE BILA FILE/DIRECTORY DITEMUKAN *)
         KETEMU := FALSE;
         WHILE DOSERROR=0 DO
            BEGIN
            (* KALAU LONG FILE NAME.... *)
            ST3:=UPCASES(CONVERT_TO_LFN(RESULT+D.NAME));
            IF (ST3=COPY(UPCASES(S),1,LENGTH(ST3))) AND
               ((LENGTH(ST3)=LENGTH(S)) OR (S[LENGTH(ST3)+1]='\')) THEN
               BEGIN
               RESULT:=RESULT+D.NAME+'\';
               KETEMU:=TRUE;
               BREAK;
            END;
            (* KALAU TIDAK LONG FILE NAME.... *)
            ST3:=UPCASES(RESULT+D.NAME);
            IF (ST3=COPY(UPCASES(S),1,LENGTH(ST3))) AND
               ((LENGTH(ST3)=LENGTH(S)) OR (S[LENGTH(ST3)+1]='\')) THEN
               BEGIN
               RESULT:=RESULT+D.NAME+'\';
               KETEMU:=TRUE;
               BREAK;
            END;
            FINDNEXT (D);
         END;
         (* DALAM BEBERAPA KASUS, JIKA TIDAK DITEMUKAN, MAKA TIDAK USAH
            DICONVERT KE SHORT FILE NAME *)
         IF NOT KETEMU THEN RESULT:=RESULT+ST2+'\';
      UNTIL POS('\',ST1)=0;
      DELETE (RESULT,LENGTH(RESULT),1);
      CONVERT_TO_SFN := RESULT;
   END;
   PROCEDURE ASSIGN_LFN (VAR F:FILE;S:STRING;MODE:BYTE);
   (* NB: MODE 0:RESET; 1:REWRITE *)
   VAR P:POINTER;
   BEGIN
      ERR:=0;
      IF MODE=0 THEN
         BEGIN
         ASSIGN (F,CONVERT_TO_SFN(S));
         {$I-}
         SETFATTR (F,$20);
         FILEMODE := 2;
         RESET (F,1);
         {$I+}
      END ELSE
      IF MODE=1 THEN
         BEGIN
         IF (NOT EXIST(S)) AND WIN95LFN THEN
            BEGIN
            S:=S+#0;
            P:=ADDR (S[1]);
            ASM
               PUSH DS
               MOV AX,716CH
               XOR BX,BX
               MOV CX,20H
               XOR DH,DH
               MOV DL,00010001B
               LDS SI,P
               INT 21H
               POP DS
               JC @QUIT
               MOV BX,AX
               MOV AH,3EH
               INT 21H
               @QUIT:
            END;
            DELETE (S,LENGTH(S),1);
         END;
         ASSIGN (F,CONVERT_TO_SFN(S));
         {$I-}
         SETFATTR (F,$20);
         REWRITE (F,1);
         {$I+}
      END;
      ERR := IORESULT;
   END;
   PROCEDURE REN_LFN (S1,S2:STRING);
   VAR P1,P2:POINTER;
       ERR1 :INTEGER;
       L    :LONGINT;
       F,FT : FILE;
   BEGIN
      IF (EXIST (S1)) AND (EXIST (S2)) THEN KILL_LFN (S2);
      IF S1[1]<>S2[1] THEN
         BEGIN
         (* KALAU ENGGAK SAMA DRIVE-NYA, HARUS DI-COPY LA YAW! *)
         IF EXIST(S1) THEN
            BEGIN
            ASSIGN_LFN (F,S1,0);
            ASSIGN_LFN (FT,S2,1);
            IF ERR<>0 THEN EXIT;
            L:=FILESIZE (F);
            WHILE L>BUFFER DO
               BEGIN
               BLOCKREAD (F,DATUM^,BUFFER);
               BLOCKWRITE (FT,DATUM^,BUFFER);
               DEC (L,BUFFER);
            END;
            BLOCKREAD (F,DATUM^,L);
            BLOCKWRITE (FT,DATUM^,L);
            CLOSE (F);
            CLOSE (FT);
            KILL_LFN (S1);
         END;
      END ELSE
      IF WIN95LFN THEN
         BEGIN
         P1:=ADDR(S1[1]);
         P2:=ADDR(S2[1]);
         S1:=S1+#0;
         S2:=S2+#0;
         ASM
            PUSH DS
            LES DI,P2
            LDS DX,P1
            MOV AX,7156H
            INT 21H
            POP DS
            MOV ERR1,0
            JNC @QUIT
            MOV ERR1,AX
            @QUIT:
         END;
      END ELSE
         BEGIN
         ASSIGN (F,S1);
         {$I-}
         RENAME (F,S2);
         {$I+}
         ERR:=IORESULT;
      END;
      ERR:=ERR1;
   END;
   PROCEDURE MKDIR_LFN (S:STRING);
   VAR P:POINTER;
       ERR1:INTEGER;
   BEGIN
      IF WIN95LFN THEN
         BEGIN
         S:=S+#0;
         P:=ADDR(S[1]);
         ASM
            PUSH DS
            LDS DX,P
            MOV AX,7139H
            INT 21H
            POP DS
            MOV ERR1,0
            JNC @QUIT
            MOV ERR1,AX
            @QUIT:
         END;
      END ELSE
         BEGIN
         {$I-}
         MKDIR (S);
         {$I+}
         ERR:=IORESULT;
      END;
      ERR:=ERR1;
   END;
   PROCEDURE CLOSE_FILE;
   BEGIN
      {$I-}
      CLOSE (F1);
      {$I+}
      ERR:=IORESULT;
      IF (TEST) AND (ATR.KOMP_TYPE>0) THEN KILL_LFN (KOMP_TEMP) ELSE
      IF ATR.KOMP_TYPE>0 THEN REN_LFN (KOMP_TEMP,NAMA);
   END;
   VAR Y_OLD : INTEGER;
   PROCEDURE OUTPUT_SCREEN (CONST S:STRING;C:CHAR;W:BYTE;REPLACE:BOOLEAN);
   VAR B:BYTE;
   BEGIN
      IF REPLACE THEN
         BEGIN
         TEXTCOLOR (7);
         TEXTBACKGROUND (0);
         FOR B:=Y_OLD TO WHEREY DO
            BEGIN
            GOTOXY (1,B);
            CLREOL;
         END;
         GOTOXY (1,Y_OLD);
      END;
      Y_OLD := WHEREY;
      TEXTCOLOR (3);
      WRITE (C,' ');
      TEXTCOLOR (W);
      WRITE (NAMA,S);
      B:=(LENGTH(S)+LENGTH(NAMA)+3) DIV 80;
      IF Y_OLD+B>25 THEN Y_OLD:=50-B-Y_OLD;
      IF Y_OLD<1 THEN Y_OLD:=1;
   END;
   PROCEDURE TANDAI_ERROR (CONST S:STRING);
   VAR CH:CHAR;
   BEGIN
      INC (JUM_ERROR);
      OUTPUT_SCREEN (' '+S,'x',4,TRUE);
      TEXTCOLOR (7);
      CH:=READKEY;
   END;

   FUNCTION CEK4BAD:BOOLEAN;
   VAR ERR1:INTEGER;
   BEGIN
      ERR1:=IORESULT;
      CEK4BAD:=FALSE;
      IF ERR1 <> 0 THEN
         BEGIN
         CEK4BAD := TRUE;
         REPLACE := FALSE;
         CLOSE_FILE;
         CASE ERR1 OF
            2: TANDAI_ERROR ('<File not found>');
            3: TANDAI_ERROR ('<Path not found>');
            4: TANDAI_ERROR ('<Too many open files>');
            5: TANDAI_ERROR ('<File access denied>');
            18: TANDAI_ERROR ('<No more files>');
            100: TANDAI_ERROR ('<Disk read error>');
            101: TANDAI_ERROR ('<Disk write error>');
            103: TANDAI_ERROR ('<File access denied>');
            150: TANDAI_ERROR ('<Disk is write-protected>');
            152: TANDAI_ERROR ('<Drive not ready>');
            154: TANDAI_ERROR ('<CRC error in data>');
            156: TANDAI_ERROR ('<Disk seek error>');
            157: TANDAI_ERROR ('<Unknown media type>');
            158: TANDAI_ERROR ('<Sector not found>');
            160: TANDAI_ERROR ('<Device write fault>');
            161: TANDAI_ERROR ('<Device read fault>');
            162: TANDAI_ERROR ('<Hardware failure>');
            ELSE TANDAI_ERROR ('<Unknown error>');
         END;
      END ELSE REPLACE := TRUE;
   END;

PROCEDURE CREATE_DIR (CONST N:STRING);
{    PROSEDUR MENCARI & MEMBUAT DIREKTORY    }
VAR B:BYTE;
    ST:STRING;
BEGIN
   B:=4;
   WHILE B<LENGTH(N) DO
      BEGIN
      IF N[B]='\' THEN
         BEGIN
         ST:=COPY(N,1,B-1);
         MKDIR_LFN (ST);
      END;
      INC (B);
   END;
END;

PROCEDURE CALCULATE_CHECKSUM (VAR SOURCE;SIZE:WORD); ASSEMBLER;
ASM
   MOV CX,SIZE
   OR CX,CX
   JZ @2
   MOV DX,CHKSUM
   PUSH DS
   LDS SI,SOURCE
   @1:
   LODSB
   XOR DL,AL
   ROR DX,1
   ADD DH,AL
   LOOP @1
   POP DS
   MOV CHKSUM,DX
   @2:
END;
PROCEDURE READNEXTBLOCK; FAR;
BEGIN
   INPTR:=0;
   IF NOT ERROR_UNCOMP THEN
      BEGIN
      {$I-}
      BLOCKREAD (INFILE,INBUF^,BESAR_POINTER,INEND);
      {$I+}
      IF CEK4BAD THEN ERROR_UNCOMP:=TRUE;
   END;
END;
PROCEDURE WRITENEXTBLOCK; FAR;
VAR WR:WORD;
BEGIN
   IF (NOT ERROR_UNCOMP) AND (NOT TEST) THEN
      BEGIN
      {$I-}
      BLOCKWRITE (OUTFILE,OUTBUF^,OUTPTR,WR);
      {$I+}
      IF CEK4BAD THEN ERROR_UNCOMP:=TRUE;
   END;
   INC (SIZE_AFTER_DECOMPRESSION,OUTPTR);
   CALCULATE_CHECKSUM (OUTBUF^,OUTPTR);
   OUTPTR := 0;
END;
PROCEDURE OPENINPUT (CONST FN:STRING);
BEGIN
   ASSIGN (INFILE,FN); RESET (INFILE,1);
   INBUF:=@IBUF^;
   READTOBUFFER:=READNEXTBLOCK;
   READTOBUFFER;
END;
PROCEDURE OPENOUTPUT (CONST FN:STRING);
BEGIN
   IF NOT TEST THEN ASSIGN_LFN (OUTFILE,FN,1);
   SIZE_AFTER_DECOMPRESSION := 0;
   OUTBUF:=@OBUF^;
   OUTEND:=BESAR_POINTER;
   OUTPTR:=0;
   WRITEFROMBUFFER:=WRITENEXTBLOCK;
END;



PROCEDURE UNCOMPRESS;

VAR   GANTI_DISK              : BOOLEAN;
      PJG_STRG                : BYTE;
      PLH                     : CHAR;
      BESAR_SOURCE,BESAR_DEST : LONGINT;
      HABIS                   : BOOLEAN;


(* =============== PROCEDURE PEMBANTU ================ *)

   PROCEDURE DICEK (CONST NAME:STRING);
   VAR CH: CHAR;
       S: STRING[20];
      FUNCTION WIN95TYPE:BOOLEAN;
      VAR B,COUNT:BYTE;
      BEGIN
         B:=4;
         COUNT:=0;
         WHILE (B<=LENGTH(NAME)) DO
            BEGIN
            IF (NAME[B]=' ') THEN
               BEGIN
               WIN95TYPE:=TRUE;
               EXIT;
            END;
            IF (NAME[B]='\') OR (B=LENGTH(NAME)) THEN
               BEGIN
               IF B=LENGTH(NAME) THEN INC(COUNT);
               IF (COUNT>12) THEN
                  BEGIN
                  WIN95TYPE:=TRUE;
                  EXIT;
               END;
               COUNT:=0;
            END ELSE INC (COUNT);
            INC (B);
         END;
         WIN95TYPE:=FALSE;
      END;
   BEGIN
      IF (NOT WIN95LFN) AND (WIN95TYPE) THEN
         BEGIN
         REPLACE := FALSE;
         TANDAI_ERROR ('<Long File Name>');
      END ELSE
      IF (NOW=0) AND (EXIST (NAME)) AND (NOT REPLACE_ALL) THEN
         BEGIN
         OUTPUT_SCREEN (' exist. Replace (Yes/No/All/Quit)? ','?',3,FALSE);
         WHILE KEYPRESSED DO READKEY;
         REPEAT
            CH:=UPCASE(READKEY);
         UNTIL CH IN ['Y','A','N','Q'];
         IF CH='Q' THEN
            BEGIN
            TEXTCOLOR (7);
            WRITELN;
            WRITELN ('Process aborted ...');
            HALT (1);
         END ELSE
         IF CH='N' THEN
            BEGIN
            OUTPUT_SCREEN ('','s',8,TRUE);
            REPLACE := FALSE;
         END ELSE
         IF CH='A' THEN REPLACE_ALL := TRUE;
      END;
      IF REPLACE THEN
         BEGIN
         IF NOW=0 THEN
            BEGIN
            OUTPUT_SCREEN ('','¯',7,TRUE);
            IF EXIST (NAMA) THEN KILL_LFN (NAMA);
            END ELSE
            BEGIN
            STR (NOW,S);
            IF NOW=FILESIZE(F1) THEN
               OUTPUT_SCREEN (' added at pos '+S+'...','¯',7,TRUE)
               ELSE
               OUTPUT_SCREEN (' replaced at pos '+S+'...','¯',7,TRUE);
         END;
      END;
   END;
   PROCEDURE BLOCKREADS (VAR FILENYA:FILE;VAR TUJUANNYA;BESARNYA:LONGINT);
   BEGIN
      {$I-}
      BLOCKREAD (FILENYA,TUJUANNYA,BESARNYA);
      {$I+}
      ERR:=IORESULT;
      IF ERR<>0 THEN
         BEGIN
         TEXTCOLOR (7);
         WRITELN;
         TEXTCOLOR (3);
         WRITE ('X ');
         TEXTCOLOR (4+BLINK);
         WRITE ('Fatal Error: Unable to read header file. Process aborted.');
         TEXTCOLOR (7);
         WRITELN;
         HALT (2);
      END;
   END;
   FUNCTION LEADINGZERO(W: LONGINT): STRING;
   VAR S: STRING[5];
   BEGIN
      W:=W MOD 100;
      STR(W:0, S);
      LEADINGZERO := 'S'+COPY('00', 1, 2 - LENGTH(S)) + S;
   END;
   PROCEDURE READ_FIRST_HEADER;
   BEGIN
      IF NOT (EXIST(SOURCE + '.' + LEADINGZERO (NO_DISK))) THEN
         PESAN_SPONSOR (TRUE,'Can''t find '+SOURCE+'.'+LEADINGZERO(NO_DISK));
      ASSIGN (F2, SOURCE + '.' + LEADINGZERO (NO_DISK));
      FILEMODE := 0;
      RESET (F2,1);
      BESAR_SOURCE := FILESIZE (F2);
      JUDUL_CHK:=JUDUL;
      BLOCKREADS (F2,JUDUL_CHK[1],ORD(JUDUL_CHK[0]));
      IF COPY (JUDUL_CHK,1,14)<>COPY (JUDUL,1,14) THEN
         BEGIN
         IF COPY (JUDUL_CHK,1,12)=COPY (JUDUL,1,12) THEN
            PESAN_SPONSOR (TRUE,'Wrong version of SC. Please use UN'+JUDUL_CHK+'.')
           ELSE
            PESAN_SPONSOR (TRUE,'Unknown format.');
      END;
      BLOCKREADS (F2,NOW,4);
      DEC (BESAR_SOURCE,ORD(JUDUL[0])+4);
   END;
   PROCEDURE BACA_HEADER;
   BEGIN
      HABIS:=FALSE;
      BLOCKREADS (F2,PJG_STRG,1);
      BLOCKREADS (F2,NAMA[1],1);
      IF (PJG_STRG=0) AND (NAMA[1]=#0) THEN
         BEGIN
         HABIS:=TRUE;
         NAMA:='';
         END ELSE
         BEGIN
         NAMA [0] := CHR (PJG_STRG);
         BLOCKREADS (F2,NAMA[2],PJG_STRG-1);
         BLOCKREADS (F2,ATR,SIZEOF(ATR));
         DEC (BESAR_SOURCE,LENGTH(NAMA)+1+SIZEOF(ATR));
      END;
   END;

(* ============= END OF PROCEDURE PEMBANTU ============= *)

VAR S:STRING[20];
    B:BOOLEAN;
    NOW_OLD:LONGINT;
BEGIN
   (* CEK TEMPORARY ENVIRONMENT *)
   KILL_LFN (KOMP_TEMP);
   IF ERR=3 THEN
      PESAN_SPONSOR (TRUE,'Please set "TEMP" in Dos Environment to a directory...');

   (* PESEN MEMORY... *)
   GETMEM (DATUM,BUFFER);
   GETMEM (IBUF,BESAR_POINTER);
   GETMEM (OBUF,BESAR_POINTER);

   (* UTK. TAMPILAN... *)
   TEXTBACKGROUND (0);
   PESAN_SPONSOR (FALSE,'Start');
   TEXTCOLOR (9);
   TEXTBACKGROUND (1);
   IF TEST THEN WRITE ('Testing archive ...') ELSE
      WRITE ('Extracting file(s) ...');
   TEXTBACKGROUND (0);
   WRITELN;
   WRITELN;

   READ_FIRST_HEADER;
   REPLACE := TRUE;
   GANTI_DISK := FALSE;

   (* APAKAH DISK PERTAMA?? *)
   IF (NO_DISK=1) AND (NOW=0) THEN B:=FALSE ELSE B:=TRUE;
   REPEAT
      Y_OLD := WHEREY;

      IF NOW=0 THEN REPLACE:=TRUE;
      BACA_HEADER;
      IF HABIS THEN BREAK;

      (* BUAT DRIVE TARGET=DRIVE YG. AKTIF *)
      NAMA[1]:=CURRENT_DIR[1];
      INC (JUM_FILE);
      IF B AND (NOT TEST) THEN
         BEGIN
         B:=FALSE;
         (* Kalau dimulai bukan dari Disk 1... *)
         IF ATR.KOMP_TYPE>0 THEN
            BEGIN
            REN_LFN (NAMA,KOMP_TEMP);
            ASSIGN_LFN (F1,KOMP_TEMP,0);
         END ELSE ASSIGN_LFN (F1,NAMA,0);
         IF ERR IN [2,3] THEN
            BEGIN
            TANDAI_ERROR ('<Not exist>');
            REPLACE:=FALSE;
         END;
         (* APAKAH SIZE FILE TIDAK MATCH UNTUK DI-RESUME?? *)
         IF REPLACE AND (FILESIZE(F1)<NOW) THEN
            BEGIN
            STR (NOW,S);
            TANDAI_ERROR ('<Can''t add! Size is smaller than '+S+'>');
            CLOSE_FILE;
            REPLACE:=FALSE;
         END;
         (* APAKAH AKAN DIREPLACE PADA FILE YG. TELAH DIUNCOMPRESS? *)
         IF REPLACE AND (FILESIZE(F1)>NOW+ATR.FSIZE) AND (ATR.KOMP_TYPE>0) THEN
            BEGIN
            TANDAI_ERROR ('<You can''t resume to file that already been extracted>');
            CLOSE_FILE;
            REPLACE:=FALSE;
         END;
         (* Hitung CHECKSUM-nya dulu... *)
         IF REPLACE AND (ATR.KOMP_TYPE=0) THEN
            BEGIN
            CHKSUM:=0;
            BESAR_DEST:=NOW;
            WHILE BESAR_DEST>BUFFER DO
               BEGIN
               BLOCKREADS (F1,DATUM^,BUFFER);
               CALCULATE_CHECKSUM (DATUM^,BUFFER);
               DEC (BESAR_DEST,BUFFER);
            END;
            BLOCKREADS (F1,DATUM^,BESAR_DEST);
            CALCULATE_CHECKSUM (DATUM^,BESAR_DEST);
         END;
         IF REPLACE THEN SEEK (F1,NOW);
      END;
      (* PERHITUNGAN PEMBACAAN FILE *)
      BESAR_DEST := ATR.FSIZE;
      IF BESAR_DEST > BESAR_SOURCE THEN
         BEGIN
         BESAR_DEST := BESAR_SOURCE;
         GANTI_DISK := TRUE;
      END;
      IF REPLACE THEN
         BEGIN
         IF NOW=0 THEN CHKSUM:=0;
         IF TEST THEN OUTPUT_SCREEN ('','t',7,TRUE) ELSE DICEK (NAMA);
      END;
      IF REPLACE THEN
         BEGIN
         IF NOT TEST THEN CREATE_DIR (NAMA);
         CASE ATR.KOMP_TYPE OF
            1 : CF_USED := 70;
            2 : CF_USED := 40;
            3 : CF_USED := 10;
         END;
         (* KALAU BUKAN MODE RESUME, PERSIAPKAN FILE BARU... *)
         IF NOW=0 THEN
            IF ATR.KOMP_TYPE>0 THEN ASSIGN_LFN (F1,KOMP_TEMP,1) ELSE
               IF NOT TEST THEN ASSIGN_LFN (F1,NAMA,1);
         (* APAKAH DISK CUKUP? *)
         IF (BESAR_DEST > DISKFREE (0)) AND (NOT TEST) THEN
            BEGIN
            TEXTCOLOR (7);
            WRITELN;
            WRITELN ('Disk Full ...');
            CLOSE_FILE;
            HALT (1);
         END;
         IF WHEREX=1 THEN GOTOXY (1,WHEREY-1);
         (* BACA -> TULIS *)
         WHILE BESAR_DEST > BUFFER DO
            BEGIN
            IF REPLACE THEN
               BEGIN
               POINTERFILE_OLD := FILEPOS (F2);
               {$I-}
               BLOCKREAD (F2,DATUM^,BUFFER);
               {$I+}
               IF CEK4BAD THEN SEEK (F2,POINTERFILE_OLD);
            END;
            (* B=TRUE DI SINI HANYA MUNCUL JIKA DALAM MODE TEST DAN DIMULAI
               DARI DISKET SELAIN DISK PERTAMA *)
            IF REPLACE AND (NOT B) THEN
               BEGIN
               {$I-}
               IF (NOT TEST) OR (ATR.KOMP_TYPE>0) THEN BLOCKWRITE (F1,DATUM^,BUFFER);
               {$I+}
               IF CEK4BAD THEN SEEK (F2,POINTERFILE_OLD);
            END;
            IF NOT REPLACE THEN SEEK (F2,FILEPOS(F2)+BUFFER);
            IF ATR.KOMP_TYPE=0 THEN CALCULATE_CHECKSUM (DATUM^,BUFFER);
            DEC (BESAR_DEST,BUFFER);
            DEC (BESAR_SOURCE,BUFFER);
         END;
         IF REPLACE THEN
            BEGIN
            POINTERFILE_OLD := FILEPOS (F2);
            {$I-}
            BLOCKREAD (F2,DATUM^,BESAR_DEST);
            {$I+}
            IF CEK4BAD THEN SEEK (F2,POINTERFILE_OLD);
         END;
         IF REPLACE AND (NOT B) THEN
            BEGIN
            {$I-}
            IF (NOT TEST) OR (ATR.KOMP_TYPE>0) THEN BLOCKWRITE (F1,DATUM^,BESAR_DEST);
            {$I+}
            IF CEK4BAD THEN SEEK (F2,POINTERFILE_OLD);
         END;
         IF NOT REPLACE THEN SEEK (F2,FILEPOS(F2)+BESAR_DEST);
         IF ATR.KOMP_TYPE=0 THEN CALCULATE_CHECKSUM (DATUM^,BESAR_DEST);
         DEC (BESAR_SOURCE,BESAR_DEST);
         BESAR_DEST:=0;
       END ELSE
         BEGIN
         (* SKIP!... *)
         SEEK (F2,FILEPOS(F2)+BESAR_DEST);
         DEC (BESAR_SOURCE,BESAR_DEST);
      END;

      (* NOW_OLD HANYA BERFUNGSI UNTUK TAMPILAN BESAR FILE *)
      NOW_OLD := NOW;
      NOW := 0;

      IF GANTI_DISK THEN
         BEGIN
         (* GANTI DISK... *)
         CLOSE (F2);
         INC (NO_DISK);
         GANTI_DISK := FALSE;
         WRITELN;
         WRITELN;
         TEXTCOLOR (14+BLINK);
         TEXTBACKGROUND (4);
         GOTOXY(1,WHEREY);
         WRITE ('Please insert Disk ',
            COPY(LEADINGZERO (NO_DISK),2,2));
         TEXTCOLOR (8);
         TEXTBACKGROUND (0);
         WRITE (' [Anykey] to continue, [ESC] to resume');
         TEXTCOLOR (2);
         REPEAT
            SOUND(220);DELAY(200);NOSOUND;
            PLH := READKEY;
            IF PLH=#27 THEN
               BEGIN
               TEXTCOLOR (7);
               GOTOXY (1,WHEREY);
               CLREOL;
               WRITELN;
               IF TEST THEN
                  WRITELN ('Testing interrupted ...') ELSE
                  WRITELN ('Process will be resumed ...');
               {$I-}
               CLOSE (F1);
               {$I+}
               CLOSE_FILE;
               HALT (1);
            END;
         UNTIL EXIST (SOURCE+'.'+LEADINGZERO (NO_DISK));
         GOTOXY(1,WHEREY);
         CLREOL;
         WRITELN ('>>> Disk ',COPY (LEADINGZERO (NO_DISK),2,2),' <<<');
         TEXTCOLOR (7);
         READ_FIRST_HEADER;
         DEC (JUM_FILE);
        END ELSE
         BEGIN
         (* GANTI FILE... *)
         (* CEK CHECKSUM 2 BYTE *)
         BLOCKREADS (F2,CHKSUM_CHK,2);
         DEC (BESAR_SOURCE,2);
         IF REPLACE THEN
            BEGIN
            {$I-}
            CLOSE (F1);
            {$I+}
            ERR:=IORESULT;
            (* UNCOMPRESS DULU... *)
            IF (ATR.KOMP_TYPE>0) AND (NOT B) THEN
               BEGIN
               ERROR_UNCOMP:=FALSE;
               RESET_CODE;
               OPENINPUT (KOMP_TEMP);
               OPENOUTPUT (NAMA);
               DECODE;
               CLOSE (INFILE);
               IF OUTPTR>0 THEN WRITENEXTBLOCK;
               IF (NOT ERROR_UNCOMP) AND (NOT TEST) THEN CLOSE (OUTFILE);
            END;
            (* ASSIGN NAMA *)
            IF (NOT ERROR_UNCOMP) THEN
            IF (CHKSUM_CHK=CHKSUM) OR B THEN
               BEGIN
               (* KALAU CHECKSUM BENAR ... *)
               IF (BESAR_COMP>0) OR (ATR.KOMP_TYPE>0) THEN
                  BEGIN
                  INC(BESAR_COMP,ATR.FSIZE+NOW_OLD);
                  INC(BESAR_UNCOMP,SIZE_AFTER_DECOMPRESSION);
               END ELSE
                  INC(BESAR_UNCOMP,ATR.FSIZE+NOW_OLD);
               INC(JUM_EXTRC);
               (* SET TIME STAMP... *)
               IF NOT TEST THEN
               IF ATR.KOMP_TYPE>0 THEN
                  BEGIN
                  RESET (OUTFILE,1);
                  SETFTIME (OUTFILE, ATR.FTIME);
                  CLOSE (OUTFILE);
               END ELSE
                  BEGIN
                  RESET (F1,1);
                  SETFTIME (F1, ATR.FTIME);
                  CLOSE (F1);
               END;
               (* SET ATTRIBUT STAMP... *)
               IF NOT TEST THEN SET_ATTRIBUT_LFN (NAMA,ATR.FATTR);
               IF TEST THEN
                  BEGIN
                  IF WHEREX = 1 THEN WRITELN;
                  TEXTCOLOR (3);
                  IF B THEN WRITE (' <OK>') ELSE WRITE (' <CRC OK>');
                  TEXTCOLOR (7);
               END;
               B:=FALSE;
            END ELSE
               BEGIN
               (* KEMBALIKAN KE DALAM BENTUK KOMPRESS ... *)
               CLOSE_FILE;
               (* KALAU CHECKSUM SALAH ... *)
               TANDAI_ERROR ('<Bad CRC>');
            END;
         END;
         REPLACE:=TRUE;
         WRITELN;
      END;
   UNTIL HABIS;
   CLOSE (F2);

   (* HAPUS TEMPORARY FILE *)
   KILL_LFN (KOMP_TEMP);
   TEXTCOLOR (11);
   WRITELN;
   WRITELN ('Completed ...');
   TEXTCOLOR (9); WRITE (JUM_FILE);
   TEXTCOLOR (10); WRITE (' file(s)');
   IF NOT TEST THEN
      BEGIN
      WRITE (', ');
      TEXTCOLOR (9); WRITE (JUM_EXTRC);
      TEXTCOLOR (10); WRITE (' file(s) extracted');
   END;
   IF JUM_ERROR<>0 THEN
      BEGIN
      WRITE (', ');
      TEXTCOLOR (12); WRITE (JUM_ERROR);
      TEXTCOLOR (10); WRITE (' file(s) bad');
   END;
   IF (BESAR_UNCOMP>0) THEN
      BEGIN
      WRITELN;
      TEXTCOLOR (9); WRITE (BESAR_UNCOMP);
      TEXTCOLOR (10); WRITE (' bytes');
      IF (BESAR_COMP>0) THEN
         BEGIN
         WRITE (', ');
         TEXTCOLOR (9); WRITE (BESAR_COMP);
         TEXTCOLOR (10); WRITE (' bytes compressed, ratio: ');
         TEXTCOLOR (9); WRITE ((BESAR_COMP/BESAR_UNCOMP)*100:3:2,'%');
      END;
   END;
   TEXTCOLOR (7);
   WRITELN;
   FREEMEM (OBUF,BESAR_POINTER);
   FREEMEM (IBUF,BESAR_POINTER);
   FREEMEM (DATUM,BUFFER);
END;

BEGIN
   (* CHECKBREAK := FALSE; *)
   INITIALIZE;
   UNCOMPRESS;
END.
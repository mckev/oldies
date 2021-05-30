(*
 SC.PAS  -  STEALTH COPY
 Kebutuhan : 1. Turbo Pascal ver. 6
             2. Sebaiknya dijalankan pada Hard Disk
*)

{$M 65520,0,65535}
{$G-,E-,N-}
PROGRAM SC;
USES CRT,DOS,ABOUT,AUTHOR,BSLZH1;

CONST JUDUL       : STRING  = 'STEALTH-COPY 5.1';
      BUFFER                = 30000;
      BESAR_POINTER         = BUFFER DIV 2;
      SUB         : BOOLEAN = FALSE;

TYPE FTYPE       = RECORD
                      FATTR       : BYTE;
                      FTIME,FSIZE : LONGINT;
                      DIKOMPRES   : BYTE;
                   END;

VAR   DIRINFO                        : SEARCHREC;
      ATR                            : FTYPE;
      TARGET,X,Y,KOMP_TYPE,NO_ARG    : BYTE;
      CMD,OLD_CMD,DIR,DEST,TEMPFILE,
      KOMP_TEMP,DEST_FILE,
      NAMA,N                         : STRING;
      SOURCE                         : ARRAY [1..20] OF STRING;
      FIL                            : TEXT;
      NO_DISK,JUM_FILE,
      NOW,BESAR_COMP,BESAR_UNCOMP    : LONGINT;

      (* UTK. TAMPILAN MODE NON STEALTH *)
      STEALTH                        : BOOLEAN;
      FILE_SIZE,
      FILE_SIZE_BEFORE,FILE_SIZE_AFTER : LONGINT;

      (* UTK. KOMPRESI *)
      INFILE,OUTFILE                 : FILE;
      IBUF,OBUF                      : POINTER;
      CHKSUM                         : WORD;

      (* UTK. LONG FILE NAME *)
      WIN95LFN                       : BOOLEAN;

      (* UTK. LOG *)
      LOG_MODE,RESUME_MODE           : BOOLEAN;
      LOGFN,TEMP_LOGFN               : STRING;
      LOG,TEMP_LOG                   : TEXT;
      START,STOP,START_DISK          : LONGINT;

(* =============== PROCEDURE PEMBANTU ================ *)

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
      WRITE ('Usage:');
      TEXTCOLOR (11); TEXTBACKGROUND (1);
      WRITE ('SC [/s][/h][/cmax|c|cmin][/log|resume[:n]] <dest_file> [<source_file>...]');
      TEXTCOLOR (12); TEXTBACKGROUND (0);
      WRITELN;
      IF PESAN='' THEN
         BEGIN
         WRITE   ('Examples: ');
         TEXTCOLOR (9);
         WRITELN ('ù SC A:\FILE C:\DIR1 C:\DIR2\*.DOC /C/S/LOG');
         WRITELN ('          ù SC A:\FILE /RESUME');
         TEXTCOLOR (12);
      END;
      WRITE ('Note:     ');
      TEXTCOLOR (9);
      WRITELN ('¯ Destination file must be without any extension');
      IF GETENV('TEMP')='' THEN
         BEGIN
         WRITELN ('          ¯ Set "TEMP" in Dos Environment to locate the temporary files,');
         WRITELN ('            otherwise I''ll use C:\ instead');
      END;
      WRITELN ('          ¯ Use /s option to recurse subdirectories');
      WRITELN ('          ¯ Use /h option to process in stealth-mode');
      WRITELN ('          ¯ To compress the files with LZH algorithm:');
      WRITELN ('              ù /cmax  : Maximum compression (slowest)');
      WRITELN ('              ù /c     : Balanced compression');
      WRITELN ('              ù /cmin  : Minimum compression (fastest)');
      WRITELN ('          ¯ Use /log to create log in current directory');
      WRITELN ('          ¯ Use /resume to resume last process');
      WRITELN ('          ¯ Use /resume:n to repeat last process to disk no. n');
      WRITELN ('          ¯ Use /? to view documentation');
      TEXTCOLOR (12);
      WRITE ('Features: ');
      TEXTCOLOR (9);
      WRITE   ('¯ Support Long File Name mode ');
      TEXTCOLOR (13);
      IF WIN95LFN THEN WRITELN ('<enabled>') ELSE WRITELN ('<disabled>');
      TEXTCOLOR (9);
      WRITELN ('          ¯ CRC-16 to ensure data integrity');
      WRITELN ('          ¯ Skip file(s) on bad media');
      WRITELN ('          ¯ Multiple Disks supported');
      WRITE   ('          ¯ Resume Mode! and Repeat Mode! technology');
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
   PROCEDURE PRINT_PERCENTAGE (L1,L2:LONGINT);
   BEGIN
      IF NOT STEALTH THEN
         BEGIN
         GOTOXY (X,Y);
         TEXTCOLOR (9);
         IF L2 = 0 THEN WRITE ('100.0 %') ELSE
         WRITE ((L1/L2)*100:5:1,' %');
      END;
   END;
   VAR SCR : ARRAY [0..79] OF WORD;
       XX,YY : BYTE;
   PROCEDURE SAVE_SCR;
   VAR T:INTEGER;
   BEGIN
      XX:=WHEREX; YY:=WHEREY;
      FOR T:=0 TO 79 DO SCR[T] := MEMW [$B800:T SHL 1];
   END;
   PROCEDURE RESTORE_SCR;
   VAR T:INTEGER;
   BEGIN
      FOR T:=0 TO 79 DO MEMW [$B800:T SHL 1] := SCR[T];
      GOTOXY (XX,YY);
   END;
   FUNCTION EXIST (CONST NAME:STRING) : BOOLEAN;
   VAR F:FILE;
   BEGIN
      {$I-}
      ASSIGN (F, NAME);
      FILEMODE := 0;
      RESET (F);
      CLOSE (F);
      {$I+}
      EXIST := (IORESULT=0) AND (NAME <> '');
   END;
   FUNCTION LEADINGZERO(W: LONGINT): STRING;
   VAR S: STRING[5];
   BEGIN
      W:=W MOD 100;
      STR(W:0, S);
      LEADINGZERO := 'S'+COPY('00', 1, 2 - LENGTH(S)) + S;
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
   PROCEDURE INITIATE_LOG;
   (* Struktur LOG:
        - '// Please DO NOT modify, add, or delete this file //'
        - '*' KOMP_TYPE -> JENIS KOMPRESI
        - ':' NO    -> NO DISK
        - FILE(1) COMPRESS(1) START(1) FINISH(1)
        - FILE(2) COMPRESS(2) START(2) FINISH(2)
        - ...
        - FILE(X) COMPRESS(X) START(X) FINISH(X)+
        - FILE(X+1)
        - FILE(X+2)
        - ...
   *)
   VAR ERR:INTEGER;
       K,L:LONGINT;
       S,S2,S3:STRING;
       RESUME_CHECK:BOOLEAN;
   BEGIN
      IF LOG_MODE THEN
         BEGIN
         IF EXIST (LOGFN) THEN
            PESAN_SPONSOR (TRUE,'Log file ('+CONVERT_TO_LFN(LOGFN)+
            ') exist! This file might be still needed...');
         ASSIGN (TEMP_LOG,TEMP_LOGFN);
         {$I-}
         REWRITE (TEMP_LOG);
         {$I+}
         IF IORESULT<>0 THEN
            PESAN_SPONSOR (TRUE,'Can''t make logfile... Unable to write...');
         WRITELN (TEMP_LOG,'// Please DO NOT modify or delete this file //');
         WRITELN (TEMP_LOG,'*',KOMP_TYPE);
         WRITELN (TEMP_LOG,':1');
      END;
      IF RESUME_MODE THEN
         BEGIN
         RESUME_CHECK:=FALSE;
         IF NOT EXIST (LOGFN) THEN
            PESAN_SPONSOR (TRUE,'Can''t find log file ('+
            CONVERT_TO_LFN(LOGFN)+')');
         ASSIGN (LOG,LOGFN);
         RESET (LOG);
         ASSIGN (FIL,TEMPFILE);
         REWRITE (FIL);
         IF START_DISK>0 THEN
            BEGIN
            RESUME_MODE := FALSE;
            (* Pada mode mulai dari Disk 'START_DISK'... *)
            WHILE (NOT EOF(LOG)) DO
               BEGIN
               READLN (LOG,S);
               (* BACA KODE '*KOMP_TYPE' ... *)
               IF S[1]='*' THEN
                  BEGIN
                  S2:=S;
                  DELETE (S2,1,1);
                  VAL (S2,K,ERR);
                  IF (ERR=0) AND (K IN [0..3]) THEN KOMP_TYPE:=K;
               END ELSE
               (* BACA KODE ':NO_DISK' ... *)
               IF S[1]=':' THEN
                  BEGIN
                  S2:=S;
                  DELETE (S2,1,1);
                  VAL (S2,K,ERR);
                  IF ERR=0 THEN NO_DISK:=K;
                  IF NO_DISK=START_DISK THEN BREAK;
               END;
            END;
            IF (NO_DISK=START_DISK) AND NOT(EOF(LOG)) THEN
               BEGIN
               RESUME_CHECK:=TRUE;
               READLN (LOG,S);
               S2:=S;
               (* HILANGKAN NAMA & KOMPRESI... *)
               DELETE (S2,1,POS('*',S2));
               DELETE (S2,1,POS('*',S2));
               (* AMBIL START(X)... *)
               S3:=COPY (S2,1,POS('*',S2)-1);
               VAL (S3,K,ERR);
               NOW:=K;
               WRITELN (FIL,S);
               WHILE NOT EOF(LOG) DO
                  BEGIN
                  READLN (LOG,S);
                  IF S[1]=':' THEN BREAK;
                  IF S[LENGTH(S)]='+' THEN
                     BEGIN
                     DELETE (S,LENGTH(S),1);
                     WRITELN (FIL,S);
                     BREAK;
                  END;
                  WRITELN (FIL,S);
               END;
            END;
            CLOSE (FIL);
            CLOSE (LOG);
            IF NOT RESUME_CHECK THEN
               PESAN_SPONSOR (TRUE,'Can''t find specified disk number in log file...');
           END ELSE
            BEGIN
            (* Pada mode Resume... Persiapkan segalanya... *)
            ASSIGN (TEMP_LOG,TEMP_LOGFN);
            {$I-}
            REWRITE (TEMP_LOG);
            {$I+}
            IF IORESULT<>0 THEN
               PESAN_SPONSOR (TRUE,'Can''t make logfile... Unable to write...');
            WHILE NOT EOF(LOG) DO
               BEGIN
               READLN (LOG,S);
               (* BACA KODE '*KOMP_TYPE' ... *)
               IF S[1]='*' THEN
                  BEGIN
                  S2:=S;
                  DELETE (S2,1,1);
                  VAL (S2,K,ERR);
                  IF (ERR=0) AND (K IN [0..3]) THEN KOMP_TYPE:=K;
                  WRITELN (TEMP_LOG,S);
               END ELSE
               (* BACA KODE ':NO_DISK' ... *)
               IF S[1]=':' THEN
                  BEGIN
                  S2:=S;
                  DELETE (S2,1,1);
                  VAL (S2,K,ERR);
                  IF ERR=0 THEN NO_DISK:=K;
                  WRITELN (TEMP_LOG,S);
               END ELSE
               (* APAKAH KETEMU AKHIR DARI PROSES SEBELUMNYA? *)
               IF S[LENGTH(S)]='+' THEN
                  BEGIN
                  RESUME_CHECK:=TRUE;
                  DELETE (S,LENGTH(S),1);
                  S2:=S;
                  (* HILANGKAN NAMA & KOMPRESI... *)
                  DELETE (S2,1,POS('*',S2));
                  DELETE (S2,1,POS('*',S2));
                  (* AMBIL START(X)... *)
                  S3:=COPY (S2,1,POS('*',S2)-1);
                  VAL (S3,K,ERR);
                  DELETE (S2,1,POS('*',S2));
                  (* AMBIL FINISH(X)... *)
                  VAL (S2,L,ERR);
                  NOW := L;
                  (* BUAT TEMPORARY LOG... *)
                  IF L<>K THEN
                     BEGIN
                     WRITELN (TEMP_LOG,S);
                     INC (NO_DISK);
                     WRITE (TEMP_LOG,':');
                     WRITELN (TEMP_LOG,NO_DISK);
                  END;
                  (* AMBIL FILE(X) COMPRESS(X) FINISH(X) *)
                  (* NGGAK APA-APA JIKA YANG DIHAPUS ADALAH COMPRESS(X),
                     KARENA SAMA AJA... *)
                  S3:='*'+S3+'*';
                  DELETE (S,POS(S3,S)+1,LENGTH(S3)-1);
                  (* BUAT LIST FILE YG. HARUS DI-COPY... *)
                  WRITELN (FIL,S);
                  WRITE (TEMP_LOG,S);
                  WHILE NOT EOF(LOG) DO
                     BEGIN
                     READLN (LOG,S);
                     WRITELN (FIL,S);
                  END;
               END ELSE WRITELN (TEMP_LOG,S);
            END;
            CLOSE (FIL);
            CLOSE (LOG);
            IF NOT RESUME_CHECK THEN
               BEGIN
               PESAN_SPONSOR (FALSE,'Can''t resume... Already completed...');
               CLOSE (TEMP_LOG);
               ERASE (TEMP_LOG);
               HALT (1);
            END;
         END;
      END;
   END;
   VAR LOG_TYPE:BYTE;
   (* LOG_TYPE: 1->NAMA&NOW1, 2-> NOW2, 3-> CHANGE DISK *)
   PROCEDURE WRITE_LOG;
   BEGIN
      IF LOG_MODE OR RESUME_MODE THEN
      CASE LOG_TYPE OF
         1: BEGIN
               WRITE (TEMP_LOG,N);
               WRITE (TEMP_LOG,'*');
               WRITE (TEMP_LOG,ATR.DIKOMPRES);
               WRITE (TEMP_LOG,'*');
               WRITE (TEMP_LOG,NOW);
            END;
         2: BEGIN
               WRITE (TEMP_LOG,'*');
               WRITELN (TEMP_LOG,NOW);
            END;
         3: BEGIN
               WRITE (TEMP_LOG,':');
               WRITELN (TEMP_LOG,NO_DISK);
            END;
      END;
   END;
   PROCEDURE FINISHED_LOG;
   VAR S:STRING;
       T:TEXT;
   BEGIN
      TEXTCOLOR (7);
      TEXTBACKGROUND (0);
      WRITELN;
      IF LOG_MODE OR RESUME_MODE THEN
         BEGIN
         IF N='' THEN
            BEGIN
            (* KALAU MODE LOG UNTUK DISK 1... *)
            IF NO_DISK=1 THEN
               BEGIN
               CLOSE (TEMP_LOG);
               ERASE (TEMP_LOG);
               HALT;
            END;
            (* KALAU MODE RESUME... *)
            IF NOT EOF(FIL) THEN READLN (FIL,NAMA);
         END;
         WRITELN ('Process will be resumed ...');
         WRITE (TEMP_LOG,'*');
         WRITE (TEMP_LOG,NOW);
         WRITELN (TEMP_LOG,'+');
         CLOSE (TEMP_LOG);
         RESET (TEMP_LOG);
         ASSIGN (T,LOGFN);
         SETFATTR (T, $20);
         REWRITE (T);
         WHILE NOT EOF(TEMP_LOG) DO
            BEGIN
            READLN (TEMP_LOG,S);
            WRITELN (T,S);
         END;
         WHILE NOT EOF(FIL) DO
            BEGIN
            READLN (FIL,S);
            WRITELN (T,S);
         END;
         CLOSE (T);
         CLOSE (TEMP_LOG);
         ERASE (TEMP_LOG);
         CLOSE (FIL);
         ERASE (FIL);
      END ELSE WRITELN ('Process aborted ...');
      HALT;
   END;
   PROCEDURE ASK_FOR_EXIT (ASK:BOOLEAN);
   VAR PLH: CHAR;
   BEGIN
      IF ASK THEN
         BEGIN
         SAVE_SCR;
         GOTOXY (69,1);
         TEXTBACKGROUND (1);
         WRITE ('EXIT (Y/N)?');
         WHILE KEYPRESSED DO READKEY;
         REPEAT
            PLH := UPCASE(READKEY);
         UNTIL PLH IN ['Y','N',#27];
         TEXTBACKGROUND (0);
         RESTORE_SCR;
      END;
      IF (PLH='Y') OR NOT ASK THEN FINISHED_LOG;
   END;
   PROCEDURE ERROR_MESSAGE (ERRCODE:INTEGER);
   VAR CH:CHAR;
       S : STRING;
   BEGIN
      IF ERRCODE<>0 THEN
         BEGIN
         CASE ERRCODE OF
            2  : S:='File not found';
            3  : S:='Path not found';
            4  : S:='Too many open files';
            5  : S:='File access denied';
            18 : S:='No more files';
            100: S:='Disk read error';
            101: S:='Disk write error';
            103: S:='File access denied';
            150: S:='Disk Protected';
            152: S:='Drive not ready';
            154: S:='CRC error in data';
            156: S:='Disk seek error';
            157: S:='Unknown media type';
            158: S:='Sector Not Found';
            160: S:='Device write fault';
            161: S:='Device read fault';
            162: S:='Hardware failure';
            ELSE
               BEGIN
               STR (ERRCODE,S);
               S:='Error Code : '+S;
            END;
         END;
         SAVE_SCR;
         TEXTCOLOR (15+BLINK); TEXTBACKGROUND (4);
         GOTOXY (80-LENGTH(S),1);WRITE (S);
         TEXTCOLOR (7); TEXTBACKGROUND (0);
         CH:=UPCASE(READKEY);
         RESTORE_SCR;
         IF CH=#27 THEN ASK_FOR_EXIT (FALSE);
      END;
   END;
   PROCEDURE BLOCKREADS (VAR FILENYA:FILE;VAR TUJUANNYA;BESARNYA:LONGINT);
   VAR ERR:INTEGER;
       POSISINYA:LONGINT;
   BEGIN
      REPEAT
         {$I-}
         POSISINYA:=FILEPOS (FILENYA);
         {$I+}
         ERR:=IORESULT;
         {$I-}
         BLOCKREAD (FILENYA,TUJUANNYA,BESARNYA);
         {$I+}
         ERR:=IORESULT;
         IF ERR<>0 THEN
            BEGIN
            ERROR_MESSAGE (ERR);
            SEEK (FILENYA,POSISINYA);
         END;
      UNTIL ERR=0;
   END;
   PROCEDURE BLOCKWRITES (VAR FILENYA:FILE;VAR TUJUANNYA;BESARNYA:LONGINT);
   VAR ERR:INTEGER;
       POSISINYA:LONGINT;
   BEGIN
      REPEAT
         {$I-}
         POSISINYA:=FILEPOS (FILENYA);
         {$I+}
         ERR:=IORESULT;
         {$I-}
         BLOCKWRITE (FILENYA,TUJUANNYA,BESARNYA);
         {$I+}
         ERR:=IORESULT;
         IF ERR<>0 THEN
            BEGIN
            ERROR_MESSAGE (ERR);
            SEEK (FILENYA,POSISINYA);
         END;
      UNTIL ERR=0;
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
      BLOCKREAD (INFILE,INBUF^,BESAR_POINTER,INEND);
      CALCULATE_CHECKSUM (INBUF^,INEND);
      INC (NOW,INEND);
      PRINT_PERCENTAGE (NOW,FILE_SIZE);
   END;
   PROCEDURE WRITENEXTBLOCK; FAR;
   VAR WR:WORD;
   BEGIN
      BLOCKWRITE (OUTFILE,OUTBUF^,OUTPTR,WR);
      OUTPTR := 0;
   END;
   PROCEDURE OPENINPUT (CONST FN:STRING);
   BEGIN
      ASSIGN (INFILE,FN);
      FILEMODE := 0;
      RESET (INFILE,1);
      FILE_SIZE := FILESIZE (INFILE);
      NOW:=0;
      INBUF:=@IBUF^;
      READTOBUFFER:=READNEXTBLOCK;
      READTOBUFFER;
   END;
   PROCEDURE OPENOUTPUT (CONST FN:STRING);
   BEGIN
      ASSIGN (OUTFILE,FN); REWRITE (OUTFILE,1);
      OUTBUF:=@OBUF^;
      OUTEND:=BESAR_POINTER;
      OUTPTR:=0;
      WRITEFROMBUFFER:=WRITENEXTBLOCK;
   END;
   PROCEDURE GANTI_BARIS;
   VAR S:STRING;
   BEGIN
      TEXTCOLOR (7);
      GOTOXY(1,Y);CLREOL;
      S:=CONVERT_TO_LFN(DIR);
      IF LENGTH(S)=2 THEN S:=S+'\';
      WRITE (S,'>');
   END;

(* ============= END OF PROCEDURE PEMBANTU ============= *)

PROCEDURE INITIALIZE;
   (* PROCEDURE PEMBANTU INITIALIZE *)
   FUNCTION UPCASES (S:STRING) : STRING;
   VAR T:BYTE;
   BEGIN
      FOR T:=1 TO LENGTH(S) DO S[T]:=UPCASE(S[T]);
      UPCASES:=S;
   END;
VAR I : BYTE;
    S1,S2,S3 : STRING;
    T1,T2 : BYTE;
    ERR : INTEGER;
    FREE : LONGINT;
BEGIN
   CHECK_LFN_SUPPORT;
   TEXTBACKGROUND (0);
   ASM
      MOV AX,1003H
      MOV BL,1
      INT 10H
   END;
   IF PARAMCOUNT=0 THEN PESAN_SPONSOR (TRUE,'');

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
         IF S2='?' THEN
            BEGIN
            PESAN_SPONSOR (FALSE,'');
            TEXTCOLOR (7);
            WRITELN;
            ABOUT_ME;
            HALT;
            END ELSE
         IF (S2='AUTHOR') THEN
            BEGIN
            PESAN_SPONSOR (FALSE,'Start');
            TEXTCOLOR (7);
            EASTER_EGG;
            HALT;
         END ELSE
         IF (S2='S') THEN SUB:=TRUE ELSE
         IF (S2='H') THEN STEALTH:=TRUE ELSE
         IF (S2='LOG') THEN LOG_MODE:=TRUE ELSE
         IF (S2='NOLFN') THEN WIN95LFN:=FALSE ELSE
         IF COPY(S2,1,6)='RESUME' THEN
            BEGIN
            RESUME_MODE:=TRUE;
            IF LENGTH(S2)>6 THEN
               BEGIN
               S3:=S2;
               DELETE (S3,1,7);
               ERR:=0;
               VAL (S3,START_DISK,ERR);
               IF (ERR>0) OR (S2[7]<>':') OR (START_DISK=0) THEN
                  PESAN_SPONSOR (TRUE,'Invalid Argument.');
            END;
            END ELSE
         IF (S2[1]='C') AND (KOMP_TYPE=0) THEN
            BEGIN
            (* DEFAULT *)
            KOMP_TYPE := 2;
            IF LENGTH(S2)>1 THEN
               BEGIN
               (* MAX. COMPRESSION *)
               IF S2='CMAX' THEN KOMP_TYPE:=1 ELSE
               (* MIN. COMPRESSION *)
               IF S2='CMIN' THEN KOMP_TYPE:=3 ELSE
               PESAN_SPONSOR (TRUE,'Invalid Argument.');
            END;
            END ELSE
            PESAN_SPONSOR (TRUE,'Invalid Argument.');
         S1 := COPY(S1,1,T1-1)+COPY(S1,T2,LENGTH(S1)-T2+1);
         T1 := POS ('/',S1);
      END;
      IF S1 <> '' THEN
         BEGIN
         IF NO_ARG>20 THEN PESAN_SPONSOR (TRUE,'Maximum files handled is 20.');
         INC (NO_ARG);
         IF NO_ARG=1 THEN DEST := S1 ELSE
            SOURCE [NO_ARG-1] := S1;
      END;
   END;
   (* Kalau mode resume, jangan ada argument lain... *)
   IF RESUME_MODE AND ((NO_ARG>1) OR (KOMP_TYPE>0) OR SUB OR LOG_MODE)
      THEN PESAN_SPONSOR (TRUE,'While in resume mode, only <dest_file> and stealth-mode are accepted.');
   (* Cek <dest_file> dan <source files> *)
   IF NO_ARG=0 THEN PESAN_SPONSOR (TRUE,'');
   IF NO_ARG=1 THEN
      BEGIN
      INC (NO_ARG);
      GETDIR (0,SOURCE[1]);
   END;
   DEC (NO_ARG);
   IF NOT (POS ('.',DEST) = 0) THEN PESAN_SPONSOR (TRUE,'');
   (* Ambil drive <dest_file> *)
   IF DEST[2]=':' THEN
      TARGET := ORD(UPCASE(DEST[1])) - 64
      ELSE
      BEGIN
      GETDIR (0,TEMPFILE);
      TARGET := ORD(UPCASE(TEMPFILE[1])) - 64;
   END;
   (* Dimana letak TEMP? *)
   IF GETENV ('TEMP')='' THEN TEMPFILE := 'C:'
      ELSE TEMPFILE := GETENV('TEMP');
   IF TEMPFILE [LENGTH(TEMPFILE)] <> '\' THEN TEMPFILE := TEMPFILE+'\';
   KOMP_TEMP := TEMPFILE+'TEMPFILE.~MP';
   TEMPFILE := TEMPFILE+'FILELIST.~MP';
   (* Buat log ke direktori yg. sedang aktif *)
   GETDIR (0,TEMP_LOGFN);
   IF LENGTH(TEMP_LOGFN)=3 THEN DELETE (TEMP_LOGFN,3,1);
   LOGFN := TEMP_LOGFN+'\LOGFILE.SC';
   TEMP_LOGFN := TEMP_LOGFN+'\LOGFILE.TMP';
   (* Ya... kita mulai *)
   NO_DISK := 1;
   (* CEK FREE SPACE DULU SUPAYA AMAN... *)
   FREE := DISKFREE (TARGET);
   IF FREE=-1 THEN PESAN_SPONSOR (TRUE,'Drive not ready...') ELSE
   IF FREE<=2048 THEN PESAN_SPONSOR (TRUE,'DiskFree must be more than 2 KB...');
   (* Cek apakah temporary direktori bisa ditulis... *)
   ASSIGN (FIL,TEMPFILE);
   {$I-}
   REWRITE (FIL);
   {$I+}
   IF IORESULT<>0 THEN
      PESAN_SPONSOR (TRUE,'Please set "TEMP" in Dos Environment to a directory...');
   CLOSE (FIL);
   ERASE (FIL);
END;


PROCEDURE AMBIL_NAMA_FILE;
   PROCEDURE PARSEFILENAME (S:STRING; VAR DIR,DEST:STRING);
   VAR TEMP : STRING;
       T    : BYTE;
       KETEMU : BOOLEAN;
       TEMP2 : SEARCHREC;
   BEGIN
      (* BETULKAN AWAL *)
      IF S[1]='\' THEN
         BEGIN
         GETDIR (0,TEMP);
         S:=COPY(TEMP,1,2)+S;
       END ELSE
       IF S[2]<>':' THEN
         BEGIN
         GETDIR (0,TEMP);
         IF LENGTH(TEMP)=3 THEN TEMP := COPY(TEMP,1,2);
         S:=TEMP+'\'+S;
       END ELSE
       IF (S[3]<>'\') OR (LENGTH(S)<3) THEN
         BEGIN
         GETDIR (ORD(S[1])-ORD('A')+1,TEMP);
         IF LENGTH(TEMP)=3 THEN TEMP := COPY(TEMP,1,2);
         S:=TEMP+'\'+COPY(S,3,LENGTH(S)-2);
      END;
      (* CEK AKHIR APAKAH DIRECTORY ATAU FILE *)
      T:=LENGTH(S);
      KETEMU := FALSE;
      TEMP := S;
      IF TEMP[LENGTH(S)]='\' THEN TEMP:=COPY(TEMP,1,LENGTH(S)-1);
      TEMP2.NAME := '';
      FINDFIRST (TEMP,ANYFILE,TEMP2);
      IF (DOSERROR<>0) AND (LENGTH(TEMP)>2) AND (DOSERROR<>18) THEN
         BEGIN
         TEXTCOLOR (7);
         WRITELN ('Invalid file name or file not found');
         HALT(1);
      END;
      (* DOSERROR 18 -> FILE NOT FOUND *)
      IF ((TEMP2.ATTR AND $10)<>$10) OR (TEMP2.NAME='.') OR (TEMP2.NAME='..') OR (DOSERROR=18) THEN
         WHILE (T>0) AND NOT (KETEMU) DO
            BEGIN
            IF S[T]='\' THEN
               BEGIN
               KETEMU := TRUE;
               DEST := COPY (S,T+1,LENGTH(S)-T);
               DIR := COPY (S,1,T);
            END;
            DEC (T);
      END ELSE
         BEGIN
         IF S[LENGTH(S)]<>'\' THEN S:=S+'\';
         DIR := S;
         DEST := '';
      END;
   END;
   VAR TEMP_NAMA : STRING;
   PROCEDURE CARI_DIR (A,NAME:STRING; SUB:BOOLEAN);
   VAR  DIRINFO   : SEARCHREC;
   BEGIN
      IF A[LENGTH(A)] <> '\' THEN A:=A+'\';
      FINDFIRST (A+NAME,ANYFILE,DIRINFO);
      WHILE (DOSERROR=0) DO
         BEGIN
         IF (DIRINFO.NAME<>'.') AND (DIRINFO.NAME<>'..') AND
            (DIRINFO.ATTR AND DIRECTORY=0) AND (DIRINFO.ATTR AND VOLUMEID=0) AND
            (A+DIRINFO.NAME<>TEMPFILE) AND (A+DIRINFO.NAME<>KOMP_TEMP) AND
            (A+DIRINFO.NAME<>DEST_FILE) AND (A+DIRINFO.NAME<>LOGFN) AND
            (A+DIRINFO.NAME<>TEMP_LOGFN) THEN
            BEGIN
            TEMP_NAMA := A+DIRINFO.NAME;
            WRITELN (FIL,TEMP_NAMA);
         END;
         FINDNEXT (DIRINFO);
      END;
      IF SUB THEN
         BEGIN
         FINDFIRST (A+'*.*',ANYFILE,DIRINFO);
         WHILE (DOSERROR=0) DO
            BEGIN
            IF (DIRINFO.NAME<>'.') AND (DIRINFO.NAME<>'..') AND
               (DIRINFO.ATTR AND DIRECTORY=DIRECTORY) THEN
               CARI_DIR (A+DIRINFO.NAME,NAME,SUB);
            FINDNEXT (DIRINFO);
         END;
      END;
   END;
   VAR DIR,FILNAME : STRING;
   PROCEDURE BUAT_TEMP_FILE (SUB:BOOLEAN);
   BEGIN
      ASSIGN (FIL,TEMPFILE);
      REWRITE (FIL);
      WHILE NO_ARG>0 DO
         BEGIN
         PARSEFILENAME (SOURCE[NO_ARG],DIR,FILNAME);
         IF FILNAME='' THEN FILNAME:='*.*';
         CARI_DIR (DIR,FILNAME,SUB);
         DEC (NO_ARG);
      END;
      CLOSE (FIL);
   END;
BEGIN
   WRITE ('Scanning locations...');
   PARSEFILENAME (DEST_FILE,DIR,FILNAME);
   DEST_FILE:=DIR+FILNAME;
   BUAT_TEMP_FILE (SUB);
   GOTOXY (1,WHEREY); CLREOL;
END;

PROCEDURE CEK_TOMBOL;
VAR  K                  : CHAR;
BEGIN
   IF (NOT STEALTH) AND KEYPRESSED THEN
      BEGIN
      K:=READKEY;
      IF K=#27 THEN ASK_FOR_EXIT (TRUE);
   END;
   WHILE KEYPRESSED DO
      BEGIN
      K := READKEY;
      X := WHEREX;
      Y := WHEREY;
      CASE K OF
       #8  : BEGIN
               IF LENGTH(CMD) > 0 THEN
                 BEGIN
                 CMD:=COPY(CMD,1,LENGTH(CMD)-1);
                 IF X = 1 THEN
                   BEGIN
                   GOTOXY(80,Y-1);CLREOL;
                  END ELSE
                   BEGIN
                   GOTOXY(X-1,Y);CLREOL;
                 END;
               END;
             END;
       #13 : BEGIN
               IF CMD <> '' THEN
                 BEGIN
                 OLD_CMD:=CMD;
                 WRITELN;
                 SWAPVECTORS;
                 EXEC (GETENV('COMSPEC'), '/C ' + CMD);
                 SWAPVECTORS;
                 IF DOSERROR <> 0 THEN
                   BEGIN
                   TEXTCOLOR (7);
                   WRITELN ('Could not execute COMMAND.COM');
                   WRITELN ('Back to normal mode ...');
                   WRITELN;
                   STEALTH:=FALSE;
                 END;
                 CMD:='';
                 GETDIR (0,DIR);
               END;
               WHILE DIR = '' DO GETDIR (0,DIR);
               WRITELN;
               Y := WHEREY;
               GANTI_BARIS;
             END;
       #27 : BEGIN
               CMD:='';
               GANTI_BARIS;
             END;
       #0  : BEGIN
               K := READKEY;
               CASE K OF
               '=' : BEGIN
                       IF OLD_CMD <> '' THEN
                         BEGIN
                         CMD:=CMD+COPY(OLD_CMD,LENGTH(CMD)+1,LENGTH(OLD_CMD)-LENGTH(CMD));
                         GANTI_BARIS;
                         WRITE (CMD);
                       END;
                     END;
               ';' : BEGIN
                       IF (OLD_CMD <> '') AND
                       (LENGTH(CMD)<LENGTH(OLD_CMD)) THEN
                         BEGIN
                         CMD:=CMD+COPY(OLD_CMD,
                              LENGTH(CMD)+1,1);
                         WRITE (COPY(OLD_CMD,LENGTH(CMD),1));
                       END;
                     END;
               'D' : ASK_FOR_EXIT(TRUE);
             END;
           END ELSE
            BEGIN
            CMD:=CMD+K;
            GOTOXY(X,Y);WRITE (K);
         END;
      END;
   END;
END;

PROCEDURE COMPRESS;
VAR  F1,F2              : FILE;
     PFP,PFP_NEXT,SISA  : LONGINT;
     DATUM              : POINTER;
     RESULT             : INTEGER;
     PLH                : CHAR;

     SKIP3              : BOOLEAN; (* SKIP3=TRUE JIKA TIDAK CUKUP
                                      SPACE TEMPORARY DISK DISK *)

   PROCEDURE GET_INFO_NAMA;
   VAR I,J,K,L: BYTE;
       ERR:INTEGER;
       S,NAME:STRING;
   BEGIN
      START:=0; STOP:=0;
      J:=0;K:=0;L:=0;
      FOR I:=1 TO LENGTH(NAMA) DO
         BEGIN
         IF (NAMA[I]='*') OR (I=LENGTH(NAMA)) THEN
            BEGIN
            INC(L);
            J:=K;
            K:=I;
            IF I=LENGTH(NAMA) THEN INC(K);
         END;
         CASE L OF
            1: NAME:=COPY (NAMA,J+1,K-J-1);
            3: BEGIN
                  S:=COPY (NAMA,J+1,K-J-1);
                  VAL (S,START,ERR);
                  NOW:=START;
               END;
            4: BEGIN
                  S:=COPY (NAMA,J+1,K-J-1);
                  VAL (S,STOP,ERR);
               END;
         END;
      END;
      NAMA:=NAME;
   END;
   PROCEDURE DICEK (CONST NAME:STRING);
   VAR CH: CHAR;
   BEGIN
      IF EXIST (NAME) THEN
         BEGIN
         SAVE_SCR;
         TEXTCOLOR (14); TEXTBACKGROUND (4);
         GOTOXY (66,1);WRITE ('Rewrite (Y/N)?');
         REPEAT
            CH:=UPCASE(READKEY);
         UNTIL CH IN ['N','Y',#27];
         TEXTCOLOR (7); TEXTBACKGROUND (0);
         RESTORE_SCR;
         IF (CH='N') OR (CH=#27) THEN FINISHED_LOG;
      END;
   END;
   PROCEDURE MAKE_FIRST_HEADER;
   BEGIN
      DEST_FILE := DEST+'.'+LEADINGZERO(NO_DISK);
      DICEK (DEST_FILE);
      ASSIGN (F2,DEST_FILE);
      REPEAT
         {$I-}
         REWRITE (F2,1);
         {$I+}
         RESULT := IORESULT;
         ERROR_MESSAGE (RESULT);
      UNTIL RESULT=0;
      (* HITUNG FREE SPACE PADA DRIVE TARGET *)
      SISA := DISKFREE (TARGET) - 512;
      BLOCKWRITES (F2,JUDUL[1],ORD(JUDUL[0]));
      BLOCKWRITES (F2,NOW,4);
      DEC (SISA,ORD(JUDUL[0])+4);
   END;
   PROCEDURE WRITE_HEADER_DATA;
   VAR S:STRING;
   BEGIN
      (* PERHITUNGKAN START&STOP THD. PFP & ATR.FSIZE *)
      START:=NOW;
      IF STOP=0 THEN STOP := FILE_SIZE;
      PFP := STOP-START;
      ATR.FSIZE := FILE_SIZE-START;
      (* BARU TULIS DATANYA *)
      S:=CONVERT_TO_LFN(N);
      BLOCKWRITES (F2,S[0],LENGTH(S)+1);
      BLOCKWRITES (F2,ATR,SIZEOF(ATR));
      DEC (SISA,LENGTH(S)+1+SIZEOF(ATR));
   END;
   PROCEDURE TULIS_HEADER;
   LABEL SKIP2;
   BEGIN
      (*
      Struktur Header
        - 'STEALTH-COPY X.X'
        - <Start>       : 4 bytes    -> Hanya utk. header awal setiap disk
       +- Nama&panjang  : (len (Nama) + 1) bytes
       |  Attribut      : 1 byte
       |  Time          : 4 bytes
       |  Size          : 4 bytes
       |  Kompresi      : 1 byte
       |  FILE
       +- Checksum      : 2 bytes
        - <Selesai>     : $00 $00 = 2 bytes
      *)
      FINDFIRST (NAMA,ANYFILE,DIRINFO);
      ATR.FATTR := DIRINFO.ATTR;
      ATR.FTIME := DIRINFO.TIME;
      ATR.FSIZE := DIRINFO.SIZE;
      ATR.DIKOMPRES := KOMP_TYPE;
      INC (BESAR_UNCOMP,ATR.FSIZE);
      CHKSUM:=0;
      (* MEMULAI KOMPRESI *)
      IF KOMP_TYPE>0 THEN
         BEGIN
         (* APAKAH SPACE TEMPORARY DISK CUKUP? *)
         IF DISKFREE (ORD(UPCASE(TEMPFILE[1])) - 64) <= ATR.FSIZE+BUFFER THEN
            BEGIN
            SKIP3 := TRUE;
            DEC (BESAR_UNCOMP,ATR.FSIZE);
            TEXTCOLOR (4);
            WRITE ('<Temporary disk full>');
            READKEY;
            GOTO SKIP2;
         END;
         FREEMEM (DATUM,BUFFER);
         GETMEM (IBUF,BESAR_POINTER);
         GETMEM (OBUF,BESAR_POINTER);
         START:=NOW;
         RESET_CODE;
         OPENINPUT (NAMA);
         OPENOUTPUT (KOMP_TEMP);
         ENCODE (FILESIZE(INFILE));
         CLOSE (INFILE);
         IF OUTPTR>0 THEN WRITENEXTBLOCK;
         NOW:=START;
         IF ATR.FSIZE>FILESIZE (OUTFILE) THEN
            BEGIN
            ATR.FSIZE := FILESIZE (OUTFILE);
            NAMA := KOMP_TEMP;
            ATR.DIKOMPRES := KOMP_TYPE;
           END ELSE
            BEGIN
            ATR.DIKOMPRES := 0; (* tidak jadi dikompress *)
            CHKSUM:=0;
         END;
         (* AMBIL PERSENTASE KOMPRESI *)
         IF (ATR.DIKOMPRES<>0) AND NOT STEALTH THEN
            BEGIN
            FILE_SIZE_BEFORE := FILE_SIZE;
            FILE_SIZE_AFTER := ATR.FSIZE;
         END;
         CLOSE (OUTFILE);
         FREEMEM (IBUF,BESAR_POINTER);
         FREEMEM (OBUF,BESAR_POINTER);
         GETMEM (DATUM,BUFFER);
      END;
      (* AMBIL BESAR_FILE YG. AKAN DIPROSES *)
      FILE_SIZE := ATR.FSIZE;
      INC (BESAR_COMP,ATR.FSIZE);
      WRITE_HEADER_DATA;
      SKIP2:
   END;

LABEL SKIP;
VAR I:LONGINT;
    S:STRING;
BEGIN
   (* TAMPILAN AWAL... *)
   IF NOT STEALTH THEN PESAN_SPONSOR (FALSE,'Start')
      ELSE BEGIN
      CLRSCR;
      WRITELN ('Press F10 to exit anytime...');
      Y:=3;
      GETDIR (0, DIR);
      GANTI_BARIS;
   END;

   (* BUKA FILE TEMPAT PENAMPUNGAN NAMA FILE & DATANYA YG. AKAN DIPROSES *)
   (* DEST_FILE DISINI BERGUNA AGAR DALAM PENGKOMPRESAN, FILE TARGET
      TIDAK DIIKUTSERTAKAN LAGI *)
   DEST_FILE := DEST+'.'+LEADINGZERO(NO_DISK);
   IF (START_DISK=0) AND NOT RESUME_MODE THEN AMBIL_NAMA_FILE;
   ASSIGN (FIL,TEMPFILE);
   RESET (FIL);

   (* TAMPILAN AWAL LAGI... *)
   IF NOT STEALTH THEN
      BEGIN
      TEXTCOLOR (9);
      TEXTBACKGROUND (1);
      DEST_FILE := DEST+'.'+LEADINGZERO(NO_DISK);
      WRITE ('Creating archive ',DEST_FILE);
      TEXTCOLOR (7);
      TEXTBACKGROUND (0);
      WRITELN;
      WRITELN;
   END;

   (* BUAT HEADER PERTAMA *)
   SKIP3 := FALSE;
   MAKE_FIRST_HEADER;
   GETMEM (DATUM,BUFFER);
   WHILE NOT EOF(FIL) DO
      BEGIN
      READLN (FIL,NAMA);
      INC (JUM_FILE);
      (* AMBIL START, DAN FINISH SUATU FILE (KALAU ADA)... *)
      GET_INFO_NAMA;
      (* CEK.... APAKAH NAMA YBS. ADA ?? *)
      IF NOT EXIST (NAMA) THEN
         BEGIN
         IF NOT STEALTH THEN
            BEGIN
            IF WHEREX>1 THEN WRITELN;
            TEXTCOLOR (7); WRITE ('s ');
            TEXTCOLOR (3); WRITE ('Not found ');
            TEXTCOLOR (8); WRITE (CONVERT_TO_LFN(NAMA));
            READKEY;
         END;
         DEC (JUM_FILE);
         GOTO SKIP;
      END;
      (* KALAU ADA... *)
      N:=NAMA;
      IF (START=0) AND (STOP=0) THEN
         BEGIN
         LOG_TYPE:=1; WRITE_LOG;
      END;
      IF NOT STEALTH THEN
         BEGIN
         IF WHEREX>1 THEN WRITELN;
         TEXTCOLOR (10); WRITE ('¯ ');
         TEXTCOLOR (9);
         IF KOMP_TYPE=0 THEN WRITE ('Storing ') ELSE
            WRITE ('Deflating ');
         TEXTCOLOR (7);
         WRITE (CONVERT_TO_LFN(NAMA));
         TEXTCOLOR (9);
         (* PERHITUNGAN LOKASI PERSENTASE *)
         IF (WHEREX<52) AND (WHEREX>10) THEN GOTOXY (55,WHEREY) ELSE WRITE ('   ');
         X:=WHEREX;
         Y:=WHEREY;
         IF X+7>80 THEN
            BEGIN
            WRITELN;
            DEC(Y);
         END;
      END;
      SKIP3 := FALSE;
      TULIS_HEADER;
      IF SKIP3 THEN GOTO SKIP;
      ASSIGN (F1, NAMA);
      FILEMODE := 0;
      RESET (F1,1);
      (* JIKA MODE RESUME, MAKA HITUNG CHECKSUM JIKA DIPERLUKAN *)
      IF (START>0) AND (ATR.DIKOMPRES=0) THEN
         BEGIN
         I:=START;
         WHILE I>BUFFER DO
            BEGIN
            BLOCKREADS (F1,DATUM^,BUFFER);
            CALCULATE_CHECKSUM (DATUM^,BUFFER);
            DEC (I,BUFFER);
         END;
         BLOCKREADS (F1,DATUM^,I);
         CALCULATE_CHECKSUM (DATUM^,I);
      END;
      SEEK (F1,START);
      PFP_NEXT := 0;

      REPEAT
         IF PFP>SISA THEN
            BEGIN
            PFP_NEXT := PFP-SISA;
            PFP := SISA;
         END;
         WHILE PFP > BUFFER DO
            BEGIN
            BLOCKREADS (F1,DATUM^,BUFFER);
            IF ATR.DIKOMPRES=0 THEN CALCULATE_CHECKSUM (DATUM^,BUFFER);
            BLOCKWRITES (F2,DATUM^,BUFFER);
            INC (NOW,BUFFER);
            DEC (SISA,BUFFER);
            DEC (ATR.FSIZE,BUFFER);
            DEC (PFP,BUFFER);
            PRINT_PERCENTAGE (NOW,FILE_SIZE);
            CEK_TOMBOL;
         END;
         (* BACA PERTAMA... *)
         BLOCKREADS (F1,DATUM^,PFP DIV 2);
         IF ATR.DIKOMPRES=0 THEN CALCULATE_CHECKSUM (DATUM^,PFP DIV 2);
         BLOCKWRITES (F2,DATUM^,PFP DIV 2);
         INC (NOW,PFP DIV 2);
         PRINT_PERCENTAGE (NOW,FILE_SIZE);
         CEK_TOMBOL;

         (* BACA KEDUA... *)
         BLOCKREADS (F1,DATUM^,PFP-(PFP DIV 2));
         IF ATR.DIKOMPRES=0 THEN CALCULATE_CHECKSUM (DATUM^,PFP-(PFP DIV 2));
         BLOCKWRITES (F2,DATUM^,PFP-(PFP DIV 2));
         INC (NOW,PFP-(PFP DIV 2));
         PRINT_PERCENTAGE (NOW,FILE_SIZE);

         (* LANJUTKAN... *)
         DEC (SISA,PFP);
         DEC (ATR.FSIZE,PFP);
         DEC (PFP,PFP);
         IF PFP_NEXT>0 THEN
            BEGIN
            CLOSE (F2);
            INC (NO_DISK);
            LOG_TYPE:=2; WRITE_LOG;
            LOG_TYPE:=3; WRITE_LOG;
            LOG_TYPE:=1; WRITE_LOG;
            SAVE_SCR;
            IF LOG_MODE OR RESUME_MODE THEN
               S:=' [ESC] to resume' ELSE S:='';
            TEXTCOLOR (14);
            TEXTBACKGROUND (4);
            GOTOXY (80-12-LENGTH(S),1);
            WRITE ('CHANGE DISK!');
            TEXTBACKGROUND (0);
            WRITE (S);
            REPEAT
               SOUND(220);DELAY(200);NOSOUND;
               PLH := READKEY;
               IF PLH=#27 THEN
                  BEGIN
                  RESTORE_SCR;
                  ASK_FOR_EXIT (FALSE);
               END;
            UNTIL DISKFREE (TARGET) > 2048;    {BATAS MINIMAL DISK FREE}
            RESTORE_SCR;
            TEXTCOLOR (7);
            TEXTBACKGROUND (0);
            MAKE_FIRST_HEADER;
            WRITE_HEADER_DATA;
            PFP := PFP_NEXT;
            PFP_NEXT := 0;
           END ELSE
            BEGIN
            CLOSE (F1);
            (* INGAT!!! KALAU MODE RESUME:n, UTK. FILE TERAKHIR DISK n...
               TIDAK BOLEH DIBUAT CHECKSUM-NYA & JUGA TIDAK BOLEH
               ADA TANDA DOUBLE ZERO, KECUALI KALAU n:DISK TERAKHIR... *)
            IF STOP=FILE_SIZE THEN
               BEGIN
               BLOCKWRITES (F2,CHKSUM,2);
               DEC (SISA,2);
            END;
            LOG_TYPE:=2; WRITE_LOG;
            NOW:=0;
         END;
      UNTIL PFP=0;
      (* TULIS PERSENTASI KOMPRESI *)
      PRINT_PERCENTAGE (FILE_SIZE_AFTER,FILE_SIZE_BEFORE);
      SKIP:
   END;

   (* BUAT TANDA DOUBLE ZERO SBG. TANDA HABIS FILE *)
   IF (STOP=FILE_SIZE) OR SKIP3 THEN
      BEGIN
      RESULT:=0;
      BLOCKWRITES (F2,RESULT,2);
      CLOSE (F2);
   END;

   IF LOG_MODE OR RESUME_MODE THEN
      BEGIN
      CLOSE (TEMP_LOG);
      IF EXIST (LOGFN) THEN
         BEGIN
         ASSIGN (LOG,LOGFN);
         SETFATTR (LOG,$20);
         ERASE (LOG);
      END;
      RENAME (TEMP_LOG,LOGFN);
   END;

   (* HAPUS TEMPORARY FILE *)
   IF EXIST (KOMP_TEMP) THEN
      BEGIN
      ASSIGN (F1,KOMP_TEMP);
      ERASE (F1);
   END;
   CLOSE (FIL);
   ERASE (FIL);

   WRITELN;
   WRITELN;
   TEXTCOLOR (11);
   WRITELN ('Completed ...');
   TEXTCOLOR (9); WRITE (JUM_FILE);
   TEXTCOLOR (10); WRITE (' file(s), ');
   TEXTCOLOR (9); WRITE (BESAR_UNCOMP);
   TEXTCOLOR (10); WRITE (' bytes');
   IF (KOMP_TYPE>0) AND (NOT(BESAR_UNCOMP=0)) THEN
      BEGIN
      WRITE (', ');
      TEXTCOLOR (9); WRITE (BESAR_COMP);
      TEXTCOLOR (10); WRITE (' bytes compressed, ratio: ');
      TEXTCOLOR (9); WRITE ((BESAR_COMP/BESAR_UNCOMP)*100:3:2,'%');
      END ELSE
      WRITE ('.');
   TEXTCOLOR (7);
   WRITELN;
   FREEMEM (DATUM,BUFFER);
END;

BEGIN
   CHECKBREAK := FALSE;
   INITIALIZE;
   (* BACA DAN PERSIAPKAN LOG *)
   INITIATE_LOG;
   (* PILIHAN TINGKAT KOMPRESI *)
   CASE KOMP_TYPE OF
      1 : CF_USED := 65;
      2 : CF_USED := 40;
      3 : CF_USED := 10;
   END;
   COMPRESS;
END.
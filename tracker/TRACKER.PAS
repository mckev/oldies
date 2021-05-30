uses crt,dos;
CONST MAX_SORT = 800;

var WIN95LFN                      : boolean;
    TOTAL_INCREASE,TOTAL_DECREASE : LONGINT;
    LOG                           : TEXT;

PROCEDURE BACA_FILE (VAR FILENYA:TEXT;NAMA,DEST:STRING);
VAR X,Y:BYTE;
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
   VAR TEMP_NAMA : STRING;
   PROCEDURE CARI_DIR (A,NAME:STRING; SUB:BOOLEAN);
   VAR  DIRINFO   : SEARCHREC;
   BEGIN
      GOTOXY (1,Y+1); CLREOL;
      GOTOXY (X,Y); CLREOL;
      WRITE (CONVERT_TO_LFN(A));
      IF A[LENGTH(A)] <> '\' THEN A:=A+'\';
      FINDFIRST (A+NAME,ANYFILE,DIRINFO);
      WHILE (DOSERROR=0) DO
         BEGIN
         IF (DIRINFO.NAME<>'.') AND (DIRINFO.NAME<>'..') AND
            (DIRINFO.ATTR AND DIRECTORY=0) AND
            (DIRINFO.ATTR AND VOLUMEID=0) THEN
            BEGIN
            TEMP_NAMA := CONVERT_TO_LFN(A+DIRINFO.NAME);
            WRITE (FILENYA,TEMP_NAMA);
            WRITE (FILENYA,'*');
            WRITELN (FILENYA,DIRINFO.SIZE);
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
BEGIN
   WRITE ('Scanning directory ');
   CHECK_LFN_SUPPORT;
   X:=WHEREX; Y:=WHEREY;
   ASSIGN (FILENYA, NAMA);
   REWRITE (FILENYA);
   CARI_DIR (DEST,'*.*',TRUE);
   CLOSE (FILENYA);
   GOTOXY (1,Y+1); CLREOL;
   GOTOXY (X,Y); CLREOL;
   WRITELN ('completed.');
END;

procedure MERGE (f1_nama,f2_nama,fg_nama:string);
(* syarat: File f1 & f2 harus sudah dalam keadaan tersort
   hasil : File fg berisi gabungan f1 & f2 dalam keadaan tersort *)
var f1,f2,fg        : text;
    s1,s2           : string;
begin
   assign (f1,f1_nama);
   assign (f2,f2_nama);
   assign (fg,fg_nama);
   reset (f1);
   reset (f2);
   rewrite (fg);
   if eof(f1) then s1:='nUlL' else readln (f1,s1);
   if eof(f2) then s2:='nUlL' else readln (f2,s2);
   while not (s2='nUlL') do
      if (s1='nUlL') then
         begin
         if s2<>'nUlL' then writeln (fg,s2);
         while not eof(f2) do
            begin
            readln (f2,s2);
            writeln (fg,s2);
         end;
         s2:='nUlL';
      end else
         begin
         if (s1>s2) then       (* Proses pensortiran *)
            begin
            if eof(f2) then
               begin
               writeln (fg,s2);
               s2:='nUlL';
               end else
               begin writeln (fg,s2); readln (f2,s2); end;
         end else
            begin
            if eof(f1) then
               begin
               writeln (fg,s1);
               s1:='nUlL';
               end else
               begin writeln (fg,s1); readln (f1,s1); end;
      end;
   end;
   if s1<>'nUlL' then writeln (fg,s1);
   while not eof(f1) do
      begin
      readln (f1,s1);
      writeln (fg,s1);
   end;
   close (f1);
   close (f2);
   close (fg);
end;

var no_anim : byte;
procedure SORT_FILE (f_nama:string);
type List = ^Simpul;
     Simpul = record
                 Info   : string;
                 Kanan  : List;
              end;
var Baru : list;
    f,f_merg,f_kecil:text;
    s:string;
    i,j,jlh:integer;
    awal,akhir:list;

    procedure sortir;
    begin
         (* Tulis hasil sort di memory ke f_kecil *)
         while awal<>nil do
            begin
            writeln (f_kecil,awal^.info);
            akhir:=awal^.kanan;
            dispose (awal);
            awal:=akhir;
         end;
         close (f_kecil);

         (* Merge... *)
         merge ('merg.srt','kecil.srt','merg2.srt');
         assign (f_merg,'merg.srt'); erase (f_merg);
         assign (f_merg,'merg2.srt'); rename (f_merg,'merg.srt');
         rewrite (f_kecil);
    end;

    procedure sambung1 (B:List;var S,S1:List);
    var Temp:List;
    begin
       if S=nil then
          begin
          S:=B;
          S1:=B;
       end else
       if B^.Info >= S1^.Info then
          begin
          S1^.Kanan := B;
          S1 := B;
       end else
       if S^.Info >= B^.Info then
          begin
          B^.Kanan := S;
          S:=B;
       end else
          begin
          Temp:=S;
          while Temp^.Kanan^.Info<B^.Info do
             Temp:=Temp^.Kanan;
          B^.Kanan:=Temp^.Kanan;
          Temp^.Kanan:=B;
       end;
    end;


    procedure animasi;
    var x,y:byte;
    begin
       x:=wherex; y:=wherey;
       inc (no_anim);
       if no_anim>4 then no_anim:=1;
       case no_anim of
          1: write ('/');
          2: write ('-');
          3: write ('\');
          4: write ('|');
       end;
       gotoxy (x,y);
    end;

begin
   assign (f,f_nama);
   assign (f_kecil,'kecil.srt');
   assign (f_merg,'merg.srt');
   rewrite (f_merg);
   close (f_merg);
   reset (f);
   rewrite (f_kecil);
   jlh:=0;
   awal:=nil; akhir:=nil;
   while not eof(f) do
      begin
      inc (jlh);
      if jlh=MAX_SORT then
         begin
         jlh:=0;
         animasi;
         sortir;
      end;
      readln (f,s);
      (* Sort Langsung di Memory *)
      new (Baru);
      Baru^.Info:=s;
      Baru^.Kanan:=nil;
      sambung1 (Baru,Awal,Akhir);
   end;
   animasi;
   sortir;
   close (f_kecil);
   close (f);
   erase (f_kecil);
   erase (f);
   assign (f,'merg.srt');
   rename (f,f_nama);
end;

procedure buat_penanda (f1_nama,f2_nama,st:string);
var f1,f2: text;
    s:string;
begin
   assign (f1,f1_nama);
   assign (f2,f2_nama);
   reset (f1);
   rewrite (f2);
   while not eof(f1) do
      begin
      readln (f1,s);
      writeln (f2,s+st);
   end;
   close (f1);
   close (f2);
end;

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

FUNCTION STRS (DEC:LONGINT):STRING;
VAR HASIL:STRING;
BEGIN
   STR (DEC,HASIL);
   STRS := HASIL;
END;

PROCEDURE COMPARE (F_NAMA:STRING;STATUS:BYTE);
VAR F                   : TEXT;
    X,Y                 : BYTE;
    ST1,ST2             : STRING;
    NAMA1,NAMA2,NO1,NO2 : STRING;
    SIZE1,SIZE2,L       : LONGINT;
    KODE                : INTEGER;
BEGIN
   X:=WHEREX; Y:=WHEREY;
   ASSIGN (F,F_NAMA);
   RESET (F);
   ST1:=''; ST2:='';
   WHILE NOT EOF(F) DO
      BEGIN
      (* BACA DARI FILE MERGER *)
      IF ST1='' THEN READLN (F,ST1);
      IF EOF(F) THEN ST2:='' ELSE READLN (F,ST2);
      (* AMBIL NAMA, SIZE, DAN NO (1=OLD, 2=NEW) *)
      NAMA1:=ST1; NAMA2:=ST2;
      NO1:=NAMA1[LENGTH(NAMA1)]; NO2:=NAMA2[LENGTH(NAMA2)];
      DELETE (NAMA1,LENGTH(NAMA1)-1,2); DELETE (NAMA2,LENGTH(NAMA2)-1,2);
      VAL (COPY(NAMA1,POS('*',NAMA1)+1,LENGTH(NAMA1)),SIZE1,KODE);
      VAL (COPY(NAMA2,POS('*',NAMA2)+1,LENGTH(NAMA2)),SIZE2,KODE);
      NAMA1:=COPY(NAMA1,1,POS('*',NAMA1)-1);
      NAMA2:=COPY(NAMA2,1,POS('*',NAMA2)-1);
      IF (NAMA1=NAMA2) THEN
         BEGIN
         IF (SIZE1<>SIZE2) AND (STATUS=3) THEN
            BEGIN
            IF (NO1='2') AND (NO2='1') THEN
               BEGIN
               L:=SIZE1; SIZE1:=SIZE2; SIZE2:=L;
               NO1:='1'; NO2:='2';
            END;
            IF SIZE2>SIZE1 THEN
               BEGIN
               INC (TOTAL_INCREASE,SIZE2-SIZE1);
               WRITELN (LOG,'Size Add: '+NAMA1+' from '+STRS(SIZE1)+' to '+STRS(SIZE2));
            END ELSE
               BEGIN
               INC (TOTAL_DECREASE,SIZE1-SIZE2);
               WRITELN (LOG,'Size Dec: '+NAMA1+' from '+STRS(SIZE1)+' to '+STRS(SIZE2));
            END;
         END;
         ST1:='';
      END ELSE
         BEGIN
         IF (NO1='1') AND (STATUS=2) THEN
            BEGIN
            INC (TOTAL_DECREASE,SIZE1);
            WRITELN (LOG,'Deleted : '+NAMA1+' '+STRS(SIZE1));
         END ELSE
         IF (NO1='2') AND (STATUS=1) THEN
            BEGIN
            INC (TOTAL_INCREASE,SIZE1);
            WRITELN (LOG,'Added   : '+NAMA1+' '+STRS(SIZE1));
         END;
         ST1:=ST2;
      END;
   END;
   CLOSE (F);
   GOTOXY (1,Y+1); CLREOL;
   GOTOXY (X,Y); CLREOL;
   WRITELN ('completed.');
END;

(* ================ MAIN PROCEDURE ==================== *)

CONST DAYS : ARRAY [0..6] OF STRING[9] = ('Sunday','Monday','Tuesday',
                                          'Wednesday','Thursday','Friday',
                                          'Saturday');
VAR
  Y, M, D, DOW   : WORD;
  H, MT, S, S100 : WORD;
  DATE           : STRING;
  TIME           : STRING;
  F              : TEXT;

BEGIN
   CLRSCR;
   WRITELN ('FILES TRACKER');
   WRITELN ('Created by Kevin Haritmonds (14 November 1999)');
   WRITELN;
   IF (PARAMSTR(1)='/?') THEN
      BEGIN
      WRITELN ('FILES TRACKER is an utility to monitoring any changes in your harddisk.');
      WRITELN ('You could keep tracking what files had been added, removed, and changed to');
      WRITELN ('your disk. The result will logged to file CHANGES.TXT.');
      WRITELN;
      WRITELN ('Tracker implementing one-way MergeSort algorithm to sort thousands of files');
      WRITELN ('quickly and uses less memory. It is made by Turbo Pascal v7.0 and Assembler.');
      WRITELN;
      WRITELN ('Syntax: TRACKER [Drive/Directory]');
      WRITELN ('        e.g.: TRACKER        : to tracks files in drive C');
      WRITELN ('              TRACKER D:\MP3 : to tracks files in directory D:\MP3 & below');
      WRITELN;
      HALT;
   END;
   GETDATE (Y,M,D,DOW);
   GETTIME (H,MT,S,S100);
   DATE := DAYS[DOW]+', '+STRS(D)+'/'+STRS(M)+'/'+STRS(Y);
   TIME := STRS(H)+':'+STRS(MT);
   WRITELN ('Date: ',DATE,' (',TIME,')');

   IF PARAMCOUNT=1 THEN BACA_FILE (F,'FILES.NEW',PARAMSTR(1)) ELSE
      BACA_FILE (F,'FILES.NEW','C:\');
   (* BUKA FILE LOG *)
   IF EXIST ('FILES.DAT') THEN
      BEGIN
      ASSIGN (LOG,'CHANGES.TXT');
      IF EXIST ('CHANGES.TXT') THEN APPEND (LOG) ELSE REWRITE (LOG);
      WRITELN (LOG,'--------------------------------------------------------');
      WRITELN (LOG,'Date: '+DATE+' ('+TIME+')');
      WRITELN (LOG);
      WRITELN;
      WRITE ('Sorting files          : ');
      SORT_FILE ('FILES.DAT');
      SORT_FILE ('FILES.NEW');
      BUAT_PENANDA ('FILES.DAT','FILES2.DAT','*1');
      BUAT_PENANDA ('FILES.NEW','FILES2.NEW','*2');
      MERGE ('FILES2.DAT','FILES2.NEW','FILES.MRG');
      WRITELN ('done.');
      ASSIGN (F,'FILES2.DAT'); ERASE (F);
      ASSIGN (F,'FILES2.NEW'); ERASE (F);
      WRITE ('Scanning added files   : ');
      COMPARE ('FILES.MRG',1);
      WRITE ('Scanning deleted files : ');
      COMPARE ('FILES.MRG',2);
      WRITE ('Scanning changed files : ');
      COMPARE ('FILES.MRG',3);
      WRITELN;
      WRITELN (LOG);
      WRITE ('Changes: ');
      WRITE (LOG,'Changes: ');
      IF TOTAL_INCREASE>=TOTAL_DECREASE THEN
         WRITE ('+',STRS(TOTAL_INCREASE-TOTAL_DECREASE)) ELSE
         WRITE ('-',STRS(TOTAL_DECREASE-TOTAL_INCREASE));
      IF TOTAL_INCREASE>=TOTAL_DECREASE THEN
         WRITE (LOG,'+'+STRS(TOTAL_INCREASE-TOTAL_DECREASE)) ELSE
         WRITE (LOG,'-'+STRS(TOTAL_DECREASE-TOTAL_INCREASE));
      WRITELN (' bytes');
      WRITELN (LOG,' bytes');
      CLOSE (LOG);
      ASSIGN (F,'FILES.DAT');
      ERASE (F);
      ASSIGN (F,'FILES.NEW');
      RENAME (F,'FILES.DAT');
      ASSIGN (F,'FILES.MRG');
      ERASE (F);
      END ELSE
      BEGIN
      ASSIGN (F,'FILES.NEW');
      RENAME (F,'FILES.DAT');
   END;
END.
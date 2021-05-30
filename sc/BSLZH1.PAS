Unit BSLZH1;
{
|       File: BSLZH.PAS -> BSLZH.TPU
|  Deskripsi: Unit penanganan kompresi file
|             menggunakan algoritma LZH.
| Kompilator: Turbo Pascal 5.0+
|              (c) Borland International
|  Programer: Anton Reinhard Pardede
|     Revisi: 10 Desember 1996
|
| (c) 1996 Antivirus Media
}


{$I-,R-,V-,S-,G+}

Interface

var
  WriteFromBuffer,
  ReadToBuffer: procedure;
  inbuf,outbuf: POINTER;
  inptr,inend,outptr,outend: word;
  CF_USED     : BYTE;

  procedure Encode (bytes: LongInt);
  procedure Decode;
  PROCEDURE RESET_CODE;

Implementation
Const
{Parameter LZSS}
  cN         = 4096; {Ukuran buffer string}
  cF         = 70;   {ukuran kepala buffer}
  cTHRESHOLD = 2;
  cNODENIL   = cN;    {akhir node tree}

{Parameter Huffman}
  cN_CHAR    = 256-cTHRESHOLD+cF;
                              {Kode karakter (= 0..cN_CHAR-1)}
  cT         = cN_CHAR*2 -1;  {Ukuran table}
  cR         = cT-1;          {Posisi root}
  cMAX_FREQ  = $8000;         {Frekuensi maximum}

{Kumpulan tabel encoding/decoding 6 bit}
{Tabel encoder}
p_len: array[0..63] of byte =
       ($03,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08);

p_code: array[0..63] of byte =
       ($00,$20,$30,$40,$50,$58,$60,$68,$70,$78,$80,$88,$90,$94,$98,$9C,
        $A0,$A4,$A8,$AC,$B0,$B4,$B8,$BC,$C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE,
        $D0,$D2,$D4,$D6,$D8,$DA,$DC,$DE,$E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE,
        $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

{Table decoder}
d_code: array[0..255] of byte =
       ($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
        $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
        $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
        $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,
        $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $04,$04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,
        $06,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,
        $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,
        $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F,
        $10,$10,$10,$10,$11,$11,$11,$11,$12,$12,$12,$12,$13,$13,$13,$13,
        $14,$14,$14,$14,$15,$15,$15,$15,$16,$16,$16,$16,$17,$17,$17,$17,
        $18,$18,$19,$19,$1A,$1A,$1B,$1B,$1C,$1C,$1D,$1D,$1E,$1E,$1F,$1F,
        $20,$20,$21,$21,$22,$22,$23,$23,$24,$24,$25,$25,$26,$26,$27,$27,
        $28,$28,$29,$29,$2A,$2A,$2B,$2B,$2C,$2C,$2D,$2D,$2E,$2E,$2F,$2F,
        $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F);

d_len: array[0..255] of byte =
       ($03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08);

  getbuf: word = 0;
  getlen: byte = 0;
  putbuf: word = 0;
  putlen: word = 0;

  textsize  : LongInt = 0;
  codesize  : LongInt = 0;

var
  text_buf: array[0..cN + cF - 2] of byte;
  match_position, match_length: word;

  lson,dad: array[0..cN] of word;
  rson    : array[0..cN + 256] of word;

  freq: array[0..cT] of word; {Tabel freq komulatif}
  prnt: array [0..cT+cN_CHAR-1] of word;
  son : array[0..cT-1] of word;

function getc: byte;
VAR HASIL:BYTE;
begin
  ASM
     LES DI,INBUF
     ADD DI,INPTR
     MOV AL,ES:[DI]
     MOV HASIL,AL
     INC INPTR
  END;
  GETC:=HASIL;
  if inptr=inend then ReadToBuffer;
end;

procedure putc (c: byte);
begin
  ASM
     LES DI,OUTBUF
     ADD DI,OUTPTR
     MOV AL,C
     MOV ES:[DI],AL
     INC OUTPTR
  END;
  if outptr=outend then
    WriteFromBuffer;
end;

{Inisialisasi tree}
procedure InitTree;
var
  i: word;
begin
  for i:= cN+1 to cN+256 do rson[i] := cNODENIL; {root}
  for i:= 0 to cN-1 do dad[i] := cNODENIL; {node}
end;

{Memasukkan node ke tree}
procedure InsertNode (r: word);
Label
  Done;
var
  i,p: word;
  geq: boolean;
  c: word;
begin
  geq:= true;
  p:= cN+1+text_buf[r];
  rson[r]:= cNODENIL;
  lson[r]:= cNODENIL;
  match_length := 0;
  while TRUE do begin
    if geq then
      if rson[p]=cNODENIL then begin
        rson[p]:= r;
        dad[r] := p;
        exit
      end else
        p:= rson[p]
    else
      if lson[p]=cNODENIL then begin
        lson[p]:= r;
        dad[r] := p;
        exit
      end else
        p:= lson[p];
    i:= 1;
    while (i<CF_USED) AND (text_buf[r+i]=text_buf[p+i]) do Inc(i);
    geq:= (text_buf[r+i]>=text_buf[p+i]) or (i=CF_USED);

    if i>cTHRESHOLD then begin
      if i>match_length then begin
        match_position := (r-p) AND (cN-1) -1;
        match_length:= i;
        if match_length>=CF_USED then goto done;
      end;
      if i=match_length then begin
        c:= (r-p) AND (cN-1) -1;
        if c<match_position then match_position:= c
      end
    end
  end;
  Done:
  dad[r]:= dad[p];
  lson[r]:= lson[p];
  rson[r]:= rson[p];
  dad[lson[p]]:= r;
  dad[rson[p]]:= r;
  if rson[dad[p]]=p then
    rson[dad[p]]:= r
  else
    lson[dad[p]]:= r;
  dad[p]:= cNODENIL; {Hapus p}
end;

{Menghapus node dari tree}
procedure DeleteNode (p: word);
var
  q: word;
begin
  if dad[p] =cNODENIL then exit; {tidak terdaftar}
  if rson[p]=cNODENIL then q:= lson[p] else
  if lson[p]=cNODENIL then q:= rson[p] else begin
    q:= lson[p];
    if rson[q]<>cNODENIL then begin
      repeat
        q:= rson[q];
      until rson[q]=cNODENIL;
      rson[dad[q]]:= lson[q];
      dad[lson[q]]:= dad[q];
      lson[q]:= lson[p];
      dad[lson[p]]:= q;
    end;
    rson[q]:= rson[p];
    dad[rson[p]]:= q;
  end;
  dad[q]:= dad[p];
  if rson[dad[p]]=p then
    rson[dad[p]]:= q
  else
    lson[dad[p]]:= q;
  dad[p]:= cNODENIL;
end;

{Ambil sebuah bit}
function GetBit: byte;
begin
  while getlen<=8 do begin
    getbuf:= getbuf OR (WORD(getc) SHL (8-getlen));
    Inc(getlen,8);
  end;
  GetBit:= getbuf SHR 15;
  getbuf:= getbuf SHL 1;
  Dec(getlen);
end;

{Ambil sebuah byte}
function GetByte: Byte;
begin
  while getlen<=8 do begin
    getbuf:= getbuf OR (WORD(getc) SHL (8 - getlen));
    Inc(getlen,8);
  end;
  GetByte:= Hi(getbuf);
  getbuf:= getbuf SHL 8;
  Dec(getlen,8);
end;

{Output l bit}
procedure PutCode (l: byte; c: word);
begin
  putbuf:= putbuf OR (c SHR putlen);
  Inc(putlen,l);
  if putlen>=8 then begin
    putc(Hi(putbuf));
    Dec(putlen,8);
    if putlen>=8 then begin
      putc(Lo(putbuf));
      Inc(codesize,2);
      Dec(putlen,8);
      putbuf:= c SHL (l-putlen);
    end else begin
      putbuf:= Swap(putbuf AND $FF); {SHL 8;}
      Inc(codesize);
    end
  end
end;

{Inisialisasi freq tree}
procedure StartHuff;
var
  i,j: word;
begin
  for i:= 0 to cN_CHAR-1 do begin
    freq[i]:= 1;
    son[i] := i+cT;
    prnt[i+cT]:= i
  end;
  i:= 0; j:= cN_CHAR;
  while j<=cR do begin
    freq[j]:= freq[i]+freq[i+1];
    son[j] := i;
    prnt[i]:= j;
    prnt[i+1]:= j;
    Inc(i,2); Inc(j)
  end;
  freq[cT]:= $FFFF;
  prnt[cR]:= 0;
end;

{Rekonstruksi freq tree}
procedure Reconst;
var
  i,j,k,f,l: word;
begin
  j:= 0;
  for i:= 0 to cT-1 do
    if son[i]>=cT then begin
      freq[j]:= (freq[i]+1) SHR 1;
      son[j] := son[i];
      Inc(j)
    end;
  i:= 0; j:= cN_CHAR;
  while j<cT do begin
    k:= i+1;
    f:= freq[i]+freq[k];
    freq[j]:= f;
    k:= j-1;
    while f<freq[k] do Dec(k);
    Inc(k);
    l:= (j-k) SHL 1;
    move(freq[k],freq[k+1],l);
    freq[k]:= f;
    move(son[k],son[k+1],l);
    son[k]:= i;
    Inc(i,2);
    Inc(j)
  end;

  for i:= 0 to cT-1 do begin
    k:= son[i];
    prnt[k]:= i;
    if k<cT then
      prnt[k+1]:= i
  end
end;

{Simpan freq tree}
procedure update(c: word);
var
  i,j,k,l: word;
begin
  if freq[cR] = cMAX_FREQ then Reconst;
  c:= prnt[c+cT];
  repeat
    Inc(freq[c]);
    k:= freq[c];
{Tukar nodes}
    l:= c+1;
    if k>freq[l] then begin
      while k>freq[l+1] do Inc(l);
      freq[c]:= freq[l];
      freq[l]:= k;

      i:= son[c];
      prnt[i]:= l;
      if i<cT then prnt[i+1]:= l;

      j:= son[l];
      son[l]:= i;

      prnt[j]:= c;
      if j<cT  then prnt[j+1]:= c;
      son[c]:= j;

      c := l;
    end;
    c:= prnt[c]
  until c=0;
end;

procedure EncodeChar (c: word);
var
  code,len,k: word;
begin
  code:= 0;
  len:= 0;
  k:= prnt[c+cT];

  repeat
    code:= code SHR 1;
    if (k AND 1)>0 then Inc(code,$8000);
    Inc(len);
    k:= prnt[k];
  until k=cR;
  PutCode(len,code);
  update(c)
end;

procedure EncodePosition(c: word);
var
  i: word;
begin
  i:= c SHR 6;
  PutCode(p_len[i], WORD(p_code[i]) SHL 8);
  PutCode(6, (c AND $3F) SHL 10);
end;

procedure EncodeEnd;
begin
  if putlen>0 then begin
    putc(Hi(putbuf));
    Inc(codesize)
  end
end;

function DecodeChar: word;
var
  c: word;
begin
  c:= son[cR];
  while c<cT do c:= son[c+GetBit];
  Dec(c,cT);
  update(c);
  DecodeChar:= c
end;

function DecodePosition: word;
var
  i,j,c: word;
begin
  i:= GetByte;
  c:= WORD(d_code[i]) SHL 6;
  j:= d_len[i];
  Dec(j,2);
  while j>0 do begin
    Dec(j);
    i:= (i SHL 1) OR GetBit;
  end;
  DecodePosition:= c OR (i AND $3F);
end;

{Encoding/Kompresi}
procedure Encode (bytes: LongInt);
type
  ByteRec = record
              b0,b1,b2,b3: byte
            end;
var
  i,c,len,r,s,last_match_length: word;
begin
{Tulis ukuran asli}
  with ByteRec(Bytes) do begin
    putc(b0);
    putc(b1);
    putc(b2);
    putc(b3)
  end;
  if bytes=0 then exit;
  textsize:= 0;
  StartHuff;
  InitTree;
  s:= 0;
  r:= cN-CF_USED;
  fillchar(text_buf[0],r,' ');
  len:= 0;
  while (len<CF_USED) AND (inptr OR inend>0) do begin
    text_buf[r+len]:= getc;
    Inc(len)
  end;
  textsize := len;
  for i:= 1 to CF_USED do InsertNode(r - i);
  InsertNode(r);
  repeat
    if match_length>len then match_length:= len;
    if match_length<=cTHRESHOLD then begin
      match_length := 1;
      EncodeChar(text_buf[r])
    end else begin
      EncodeChar(255 - cTHRESHOLD + match_length);
      EncodePosition(match_position)
    end;
    last_match_length := match_length;
    i:= 0;
    while (i<last_match_length) AND (inptr OR inend>0) do begin
      Inc(i);
      DeleteNode(s);
      c:= getc;
      text_buf[s]:= c;
      if s<CF_USED-1 then text_buf[s+cN]:= c;
      s:= (s+1) AND (cN-1);
      r:= (r+1) AND (cN-1);
      InsertNode(r);
    end;
    Inc(textsize,i);
    while i<last_match_length do begin
      Inc(i);
      DeleteNode(s);
      s := (s+1) AND (cN-1);
      r := (r+1) AND (cN-1);
      Dec(len);
      if len>0 then InsertNode(r)
    end;
  until len=0;
  EncodeEnd;
end;

{Decoding/Dekompresi}
procedure Decode;
type
  ByteRec = Record
              b0,b1,b2,b3: byte
            end;
var
  i,j,k,r,c: word;
  count: LongInt;
begin
{Baca ukuran asli}
  with ByteRec(textsize) do begin
    b0:= getc;
    b1:= getc;
    b2:= getc;
    b3:= getc
  end;
  if textsize=0 then exit;
  StartHuff;
  fillchar(text_buf[0],cN-CF_USED,' ');
  r:= cN-CF_USED;
  count:= 0;
  while count<textsize do begin
    c:= DecodeChar;
    if c<256 then begin
      putc(c);
      text_buf[r]:= c;
      r:= (r+1) AND (cN-1);
      Inc(count)
    end else begin
      i:= (r-DecodePosition-1) AND (cN-1);
      j:= c-255+cTHRESHOLD;
      for k:= 0 to j-1 do begin
        c:= text_buf[(i+k) AND (cN-1)];
        putc(c);
        text_buf[r]:= c;
        r:= (r+1) AND (cN-1);
        Inc(count)
      end;
    end;
  end;
end;

PROCEDURE RESET_CODE;
BEGIN
   GETBUF:=0;GETLEN:=0;PUTBUF:=0;PUTLEN:=0;
   TEXTSIZE:=0;CODESIZE:=0;
END;

end.

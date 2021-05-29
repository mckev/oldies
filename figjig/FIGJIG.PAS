(* SOLVER.PAS                         *)
(* Program Penyelesai Teka-teki Angka *)
(* Dibuat oleh KEVIN HARITMONDS       *)
(* Mahasiswa Tek. Material '97 ITB    *)
(* Agustus '98                        *)

{$S 65520}

uses crt;
const const_max_col = 42;       (* max cols of the problem *)
      const_max_row = 42;       (* max rows of the problem *)
      const_max_num = 250;      (* max number of helping numbers *)
      const_max_numlen = 13;    (* max length of helping numbers *)
      savetodisk = false;       (* output will be saved or not *)

var max_st     : byte;
    st         : array [1..const_max_row] of string[const_max_col];
    max_num    : byte;
    num        : array [1..const_max_num] of string[const_max_numlen];
    num_used   : array [1..const_max_num] of boolean;
    jlh_figjig : word;

    (* Variabel Temporary *)
    hx,hy,k    : word;
    hs         : string;
    hb,b,trace : boolean;

procedure read_data;
(* Procedure ini untuk mengambil data-data dari file DATA.FIG *)
var f:text;
begin
   assign (f,'data.fig');
   reset (f);
   max_st:=0;
   repeat
      inc (max_st);
      readln (f,st[max_st]);
   until st[max_st,1]='-';
   dec(max_st);
   max_num:=1;
   repeat
      num_used[max_num]:=false;
      readln (f,num[max_num]);
      if num[max_num]<>'' then inc(max_num);
   until eof(f);
   dec(max_num);
   close (f);
end;

procedure refresh_screen;
(* Procedure ini untuk meng-update tampilan layar *)
var i,j:word;
begin
   textbackground(0); textcolor(14);
   gotoxy (37,1); write ('SOLVER');
   textbackground(1); textcolor(15);
(*   for i:=1 to max_st do *)
   for i:=1 to 20 do
      for j:=1 to length (st[i]) do
         if st[i,j]<>' ' then
            begin
            gotoxy (j,i+2); write (st[i,j]);
   end;
   for i:=21 to max_st do
      for j:=1 to length (st[i]) do
         if st[i,j]<>' ' then
            begin
            gotoxy (j+40,i-20+2); write (st[i,j]);
   end;
end;

procedure write_data;
(* Procedure ini untuk men-save hasil ke file datasolv.1, datasolv.2, dst *)
var i:word;
    s:string;
    f:text;
begin
   str (jlh_figjig, s);
   assign (f, 'datasolv.' + s);
   rewrite (f);
   for i:=1 to max_st do
      writeln (f,st[i]);
   close (f);
end;

procedure get_info(x,y:word;var xh:word;var yh:word;var s:string;mendatar:boolean);
(* Procedure ini untuk mendapatkan informasi kolom dari koordinat (X,Y)
   secara horizontal ataupun vertikal (MENDATAR) dan hasil koordinat
   teratas untuk vertikal atau terkiri untuk horizontal diletakkan di (XH,YH)
   dan informasi string kolom di S *)
var bl:boolean;
begin
   s:='';xh:=x;yh:=y;
   if mendatar then
      begin
      bl:=false;
      while (xh>1) and not bl do
         begin
         dec(xh);
         if st[yh,xh]=' ' then bl:=true;
      end;
      if bl then inc(xh);
      x:=xh;
      while (x<=length(st[yh])) and (st[yh,x]<>' ') do
         begin
         s:=s+st[yh,x];
         inc(x);
      end;
   end else
      begin
      bl:=false;
      while (yh>1) and (xh<=length(st[yh])) and (not bl) do
         begin
         dec(yh);
         if st[yh,xh]=' ' then bl:=true;
      end;
      if bl or (xh>length(st[yh])) then inc(yh);
      y:=yh;
      while (y<=max_st) and (xh<=length(st[y])) and (st[y,xh]<>' ') do
         begin
         s:=s+st[y,xh];
         inc(y);
      end;
   end;
end;

function count_filled (const s:string): word;
var i:word;
    result:word;
begin
   result := 0;
   for i:=1 to length(s) do
      if ((ord(s[i]) > ord('0')) and (ord(s[i]) <= ord('9'))) then
         inc(result);
   count_filled := result;
end;

function scan (var x:word;var y:word;var bl:boolean):boolean;
(* Function ini untuk mendapatkan kolom yang belum diisi (yang masih
   mengandung kotak bertanda '*') dan hasilnya diletakkan di koordinat
   (X,Y) dan informasi horizontal ataupun vertikal di BL.
   Function ini bernilai TRUE jika ada kotak yang belum diisi dan bernilai
   FALSE jika seluruh kotak telah diisi *)
var i,j:word;
    s  :string;
    count:word;

    s_max: string;
    count_max:word;
    x_max, y_max: word;
    bl_max:boolean;
begin
   scan:=true;
   count := 0;
   s_max := ''; count_max := 0; x_max := 0; y_max := 0; bl_max := true;
   for i:=1 to max_st do
      for j:=1 to length(st[i]) do
         if st[i,j]='*' then
            begin
            bl:=true;
            get_info (j,i,x,y,s,bl);
            count := count_filled(s);
            if length(s)=1 then
               begin
               bl:=false;
               get_info(j,i,x,y,s,bl);
               count := count_filled(s);
            end;
            if ((length(s)>1) and (count>=count_max)) then
               begin
               if ( (count>count_max) or
                    ((count=count_max) and (length(s)>length(s_max))) ) then
                  begin
                  s_max := s;
                  count_max := count;
                  x_max := x;
                  y_max := y;
                  bl_max := bl;
               end;
            end;
   end;
   if length(s_max)>1 then
      begin
      s := s_max;
      count := count_max;
      x := x_max;
      y := y_max;
      bl := bl_max;
      exit;
   end;
   scan:=false;
end;

var saved_s: string;
function fill_column (x,y:byte;mendatar:boolean):boolean;
(* Function ini adalah fungsi utama dari program.
   Function ini bertugas untuk :
      - Mengisikan sebuah kolom yang kosong dengan seluruh kemungkinan
        yang ada.
      - Memeriksa kolom-kolom penuh yang berlawanan arah apakah memenuhi
        syarat atau tidak.
      - Mengisikan satu kolom yang berlawanan arah. Dan jika buntu maka
        akan mencari kolom yang mengandung kotak bertanda '*' melalui
        pemanggilan function SCAN.
      - Function ini akan menghasilkan nilai FALSE jika kolom yang diperiksa
        tidak dapat diisi dengan apapun juga, dan bernilai TRUE jika kolom
        yang diperiksa memenuhi syarat. *)
var saved   :string[const_max_numlen];
    i,j     :word;
label retrieve_column,not_used;
begin
   (* bilangan di saved dahulu *)
   get_info (x,y,hx,hy,saved_s,mendatar);
   saved:=saved_s; (* to minimize stack memory usage *)
   x:=hx;y:=hy;
   (* cek seluruh kemungkinan yang ada *)
   for i:=1 to max_num do
      begin
      b:=false;
      if (length(num[i])=length(saved)) and
         (
         ((pos('*',saved)<>0) and (not num_used[i])) or
         ((pos('*',saved)=0) and num_used[i] and (not trace)) or
         ((pos('*',saved)=0) and (not num_used[i]) and trace)
         ) then
         begin
         b:=true;
         for j:=1 to length(saved) do
            if (saved[j]<>'*') and (num[i,j]<>saved[j]) then b:=false;
      end;
      if b then
         begin
         (* jika kolom yang diperiksa adalah kolom penuh, berarti hanya
         memeriksa kolom penuh tsb. apakah memenuhi syarat atau tidak *)
         if pos('*',saved)=0 then
            begin
            fill_column:=true;
            if trace then num_used[i]:=true else num_used[i]:=false;
            exit;
         end;
         (* anggap bahwa kolom yang diisi adalah benar *)
         num_used[i]:=true;
         if mendatar then
            begin
            (* isi kolom mendatar *)
            for j:=1 to length(saved) do st[y,x+j-1]:=num[i,j];
            refresh_screen;
            (* cek kolom-kolom vertikal *)
            trace:=true;
            for j:=x to (x+length(saved)-1) do
               begin
               get_info(j,y,hx,hy,hs,not mendatar);
               if (saved[j-x+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                  if fill_column(hx,hy,not mendatar)=false then
                  begin
                  num_used[i]:=false;
                  trace:=false;
                  for k:=x to j-1 do
                     begin
                     get_info(k,y,hx,hy,hs,not mendatar);
                     if (saved[k-x+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                        b:=fill_column(hx,hy,not mendatar);
                  end;
                  goto retrieve_column;
               end;
            end;
            (* isi salah satu kolom vertikal *)
{            for j:=x to (x+length(saved)-1) do
               begin
               get_info(j,y,hx,hy,hs,not mendatar);
               if (length(hs)>1) and (pos('*',hs)<>0) then
                  if fill_column(hx,hy,not mendatar)=false then
                  goto not_used;
            end;}
         end else
            begin
            (* isi kolom vertikal *)
            for j:=1 to length(saved) do st[y+j-1,x]:=num[i,j];
            refresh_screen;
            (* cek kolom-kolom horizontal *)
            trace:=true;
            for j:=y to (y+length(saved)-1) do
               begin
               get_info(x,j,hx,hy,hs,not mendatar);
               if (saved[j-y+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                  if fill_column(hx,hy,not mendatar)=false then
                  begin
                  num_used[i]:=false;
                  trace:=false;
                  for k:=y to j-1 do
                     begin
                     get_info(x,k,hx,hy,hs,not mendatar);
                     if (saved[k-y+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                        b:=fill_column(hx,hy,not mendatar);
                  end;
                  goto retrieve_column;
               end;
            end;
            (* isi salah satu kolom horizontal *)
{             for j:=y to (y+length(saved)-1) do
               begin
               get_info(x,j,hx,hy,hs,not mendatar);
               if (length(hs)>1) and (pos('*',hs)<>0) then
                  if fill_column(hx,hy,not mendatar)=false then
                     goto not_used;
            end;}
         end;
         (* jika buntu, cari lagi di koordinat lain *)
         if scan (hx,hy,hb) then
            begin
            b:=fill_column(hx,hy,hb);
            end else
            begin
            refresh_screen;
            inc (jlh_figjig);
            if (savetodisk) then
               begin
               write_data;
               end else
               begin
               textbackground(0); textcolor(7);
               gotoxy (1,24); write ('KOMBINASI: ',jlh_figjig,'...');
               readkey;
               gotoxy (1,24); clreol;
            end;
         end;

         not_used:
         num_used[i]:=false;
         trace:=false;
         if mendatar then
            begin
            for k:=x to x+length(saved)-1 do
               begin
               get_info(k,y,hx,hy,hs,not mendatar);
               if (saved[k-x+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                  b:=fill_column(hx,hy,not mendatar);
            end;
            end else
            begin
            for k:=y to y+length(saved)-1 do
               begin
               get_info(x,k,hx,hy,hs,not mendatar);
               if (saved[k-y+1]='*') and (length(hs)>1) and (pos('*',hs)=0) then
                  b:=fill_column(hx,hy,not mendatar);
            end;
         end;

         retrieve_column:
         if mendatar then for j:=1 to length(saved) do st[y,x+j-1]:=saved[j]
            else for j:=1 to length(saved) do st[y+j-1,x]:=saved[j];
         refresh_screen;
      end;
   end;
   fill_column:=false;
end;

begin
   clrscr;
   read_data;
   refresh_screen;
   scan (hx,hy,hb);
   b:=fill_column (hx,hy,hb);
   textbackground(0); textcolor(7);
   gotoxy (1,22);
   writeln ('SELESAI...');
end.

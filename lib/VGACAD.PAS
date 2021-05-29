{-------------------------------------------------}
{ Program : VGACAD.PAS                            }
{ Coder   : Agustinus Nalwan                      }
{ Fungsi  : Unit Animasi Dan Game Profesional     }
{           Versi yang telah dimodifikasi         }
{           Versi 2.00                            }
{-------------------------------------------------}

{$G+,E+,N+}
Unit VGACAD;

INTERFACE

Uses Crt,Dos,VgaFont;

Const Screen      : Pointer = Ptr ($A000,0);

Type Palette_Cell = Record
       R , G , B : Byte;
     End;

     Palette_Type = Array[0..255] of Palette_Cell;
     Palette_Addr = ^Palette_Type;

     Scroll_Page  = Array[1..800] of Pointer;

     Parallax_Data = Record
       Page_X, Page_Y : Integer;
       Last_X, Last_Y : Integer;
       Length, Width  : Integer;
     End;

Var
     A,B           :  Integer;
     Reg           :  Registers;
     Total_Page    :  Byte;
     File_P        :  File;
     UserPalette   :  Palette_Type;
     DefaultPalette:  Palette_Type;
     File_Pal      :  File;
     User_Pal      :  Palette_Addr;
     Default_Pal   :  Palette_Addr;
     Active_Pal    :  Palette_Addr;
     Page_Scroll   :  Scroll_Page;
     Parallax_Dat  :  Parallax_Data;
     Page_Width    :  Integer;
     X,Y           :  Word;
     Px2,Py2       :  Word;
     Px3,Py3       :  Word;
     Already       :  Boolean;

{ Procedure Inisialisasi Graphic }

Procedure OpenVga256;
Procedure CloseVga256;

{ Procedure Manipulasi Layar }

Procedure FillWord      (Var PicBuff; Size:Word; Code:Byte);
Procedure MoveW         (Var Source; Var Dest; Size:Word );
Procedure Define_Page   (Var PicBuff : Pointer);
Procedure UnDefine_Page (Var PicBuff : Pointer);
Procedure Fill_Page     (Var PicBuff; Col : Byte);
Procedure MoveTo        (Var Source, Destination);

{ Procedure Konstruksi Bangun Geometri }

Procedure PutPixel      (Var PicBuff; X,Y : Integer; Color : Byte);
Function  GetPixel      (Var PicBuff; X,Y : Integer) : Byte;
Procedure Line          (Var PicBuff; X1,Y1,X2,Y2:integer; Col : Byte);
Procedure VLines (Var PicBuffer; Y1,Y2,X : Integer; Color : Byte);
Procedure HLines (Var PicBuffer; X1,X2,Y : Integer; Color : Byte);
Procedure FillLines(Var PicBuffer;XL,Length:Word;Color:Byte);
Procedure Rectangle (Var PicBuffer; X1,Y1,X2,Y2 : Integer; Color : Byte);
Procedure Block         (Var PicBuff; X1,Y1,X2,Y2 : Integer; Col : Byte);
Procedure Circle        (Var PicBuff; X,Y : Integer; R : Integer; Col : Byte);
Procedure Ellipse       (Var PicBuff; X,Y : Integer; Rx,Ry : Integer; Col : Byte);

{ Procedure Manipulasi Sprite }

Function  ImageSize     (X1,Y1,X2,Y2 : Integer) : Word;
Procedure GetImage      (Var PicBuff; X1,Y1,X2,Y2 : Integer; Var Buffer);
Procedure PutStr        (Var PicBuff;X,Y:Integer;Col1,Col2:Byte;Str:String);
Procedure Load_Sprite   (File_Name:String; Var Ptr:Pointer;Var Size:Word);
Procedure Save_Sprite   (File_Name:String; Ptr:Pointer;Size:Word);
Procedure Load_Picture  (File_Name:String; Var Buffer);
Procedure Save_Picture  (File_Name:String; Var Buffer);
Procedure PutOld        (Var PicBuff;X,Y : Integer; Var Buffer);
Procedure PutImage      (Var PicBuff;X1,Y1:Integer;Var Buffer);
Procedure Put1Col       (Var PicBuff;X1,Y1:Integer;Col:Byte;Var Buffer);
Procedure Put3D         (Var PicBuff;X,Y : Integer;XL,YL:Word; Var Buffer);
Procedure T_PutImage    (Var PicBuff;X1,Y1:Integer;Var Buffer;Var PalTable);
Procedure T_Put1Col     (Var PicBuff;X1,Y1:Integer;Col:Byte;Var Buffer;Var PalTable);
Procedure T_Put3D       (Var PicBuff;X,Y : Integer;XL,YL:Word; Var Buffer;Var PalTable);
Procedure WordBlockImage  (Var PicBuff;X,Y : Integer;Var Buffer);
Procedure ByteBlockImage  (Var PicBuff;X1,Y1:Integer;Var Buffer);
{ Procedure Transparansi }

Procedure Install_Transparent(PalTable:Pointer;Name:String);
Procedure Search_Transparent_Palette(Name:String);

{ Procedure Struktur Palette }

Procedure SetVisualPalette (No,R,G,B:Byte);
Procedure GetVisualPalette (No:Byte; Var R,G,B:Byte);
Procedure SetPalette       (Var Arr_Pal:Palette_Addr; No,Rr,Gg,Bb:Byte);
Procedure GetPalette       (Var Arr_Pal:Palette_Addr; No:Byte; Var Rr,Gg,Bb:Byte);
Procedure Load_Palette     (Pal_Buff:Pointer; File_Name:String);
Procedure Save_Palette     (Pal_Buff:Pointer; File_Name:String);
Procedure Refresh_Palette;
Procedure Active_Palette   (Ac_Pal:Palette_Addr);
Procedure Restore_Palette;
Procedure Install_Palette  (Name:String);

{ Procedure Manipulasi Palette }

Procedure Set_All_Palette  (Pal_Buff:Palette_Addr; R,G,B : Byte);
Procedure Active_To_Palette(Pal_Dest:Palette_Addr; Del:Byte);
Function  Metamorph_Palette(Pal_Buff, Pal_Dest : Palette_Addr; Rate:Byte) : Boolean;

{ Procedure Scroll Layar }

Procedure Load_Vert_Scroll (Name:String);
Procedure Free_Vert_Scroll;
Procedure Put_Vert_Scroll (Var PicBuff; Y:Integer);
Procedure Load_Horiz_Scroll (Name:String);
Procedure Free_Horiz_Scroll;
Procedure Put_Horiz_Scroll  (Var PicBuff;Y:Integer);
Procedure Load_Parallax_Scroll (Name:String);
Procedure Put_Parallax_Scroll(X,Y:Integer;Var PicBuff;Var Temp);

{ Procedure Kompresi Sprite }

Procedure Color_Compress   (Var Source;Var Destination;Var Size:Word);
Procedure Color_UnCompress (Var Source;Var Destination);
Procedure Zero_Compress    (Var Source;Var Destination;Var Size:Word);
Procedure Zero_UnCompress  (Var Source;Var Destination);
Procedure Rll_Compress     (Var Source;Var Destination;Var Size:Word);
Procedure RLL_UnCompress   (Var Source,Destination);

{ Procedure Pembantu }

Procedure GetAddr(Var PicBuff;Var Seg,Offs:Word);
Procedure Get_Dimension(Var Pic;Var X,Y:Word);

Implementation

Procedure Get_Dimension(Var Pic;Var X,Y:Word);
Var Length,Width:Word;
  Begin
    Asm
      Push ds
      Les di, Pic
      Mov Ax,[ES:DI]
      Mov Length,Ax
      Add di,2
      Mov Ax,[ES:DI]
      Mov Width,Ax
      Pop ds
    End;
    X:=Length;
    Y:=Width;
  End;

Procedure HLiness (Var PicBuffer; X1,X2,Y : Integer; Color : Byte);
{ Horizontal line }
Begin
  If X1<0 then X1:=0;
  If X2<0 then X2:=0;
  If X1>319 then X1:=319;
  IF X2>319 then X2:=319;
  If Y<0 then Y:=0;
  If Y>199 then Y:=199;
asm
  Les di,PicBuffer
  Mov dx,Y
  Mov ax,dx
  Shl dx,2
  Add dx,ax
  Shl dx,6
  Add dx,X1
  Add di,dx
  Mov cx,X2
  Sub cx,X1
  Inc cx
  Jcxz @2
  Cld
  @3:
  Mov al,[es:di]
  Xor al,255
  Mov [es:di],al
  inc di
  Loop @3
  @2:
end; { HLine }
End;

Procedure FillLines(Var PicBuffer;XL,Length:Word;Color:Byte);Assembler;
Asm
  Push ds
  Les di,PicBuffer
  Add di,XL
  Mov al,Color
  Mov ah,Color
  Mov cx,Length
  Shr cx,1
  Rep Stosw
  Jnc @no_add
  Stosb
 @no_add :
  Pop ds
End;

Procedure VLiness (Var PicBuffer; Y1,Y2,X : Integer; Color : Byte);
{ Vertical line }
Begin
  If Y1<0 then Y1:=0;
  If Y2<0 then Y2:=0;
  If Y1>199 then Y1:=199;
  If Y2>199 then Y2:=199;
  If X<0 then X:=0;
  If X>319 then X:=319;
asm
  Les di,PicBuffer
  Mov dx,Y1
  Mov ax,dx
  Shl dx,2
  Add dx,ax
  Shl dx,6
  Add dx,X
  Add di,dx
  Mov cx,Y2
  Sub cx,Y1
  Inc cx
  Jcxz @2
  Cld
  Mov al,Color
  @1:
    Mov al,[es:di]
    Xor al,255
    Mov [es:di],al
    Add di,320
    Loop @1
  @2:
end; { VLine }
End;

Procedure HLines (Var PicBuffer; X1,X2,Y : Integer; Color : Byte);
{ Horizontal line }
Begin
  If X1<0 then X1:=0;
  If X2<0 then X2:=0;
  If X1>319 then X1:=319;
  IF X2>319 then X2:=319;
  If Y<0 then Y:=0;
  If Y>199 then Y:=199;
asm
  Les di,PicBuffer
  Mov dx,Y
  Mov ax,dx
  Shl dx,2
  Add dx,ax
  Shl dx,6
  Add dx,X1
  Add di,dx
  Mov cx,X2
  Sub cx,X1
  Inc cx
  Jcxz @2
  Cld
  Mov al,Color
  Rep Stosb
  @2:
end; { HLine }
End;

Procedure VLines (Var PicBuffer; Y1,Y2,X : Integer; Color : Byte);

{ Vertical line }
Begin
  If Y1<0 then Y1:=0;
  If Y2<0 then Y2:=0;
  If Y1>199 then Y1:=199;
  If Y2>199 then Y2:=199;
  If X<0 then X:=0;
  If X>319 then X:=319;
asm
  Les di,PicBuffer
  Mov dx,Y1
  Mov ax,dx
  Shl dx,2
  Add dx,ax
  Shl dx,6
  Add dx,X
  Add di,dx
  Mov cx,Y2
  Sub cx,Y1
  Inc cx
  Jcxz @2
  Cld
  Mov al,Color
  @1:
    Stosb
    Add di,319
    Loop @1
  @2:
end; { VLine }
End;

Procedure Rectangle (Var PicBuffer; X1,Y1,X2,Y2 : Integer; Color : Byte);
{ Rectangle }

begin
  if Y2=Y1 then HLines(PicBuffer,X1,X2,Y1,Color) else
  If X2=X1 then VLines(PicBuffer,Y1,Y2,X1,Color) else
  Begin
  If X2 - X1 = 1 then
  begin
    VLines (PicBuffer,Y1,Y2,X1,Color); VLines (PicBuffer,Y1,Y2,X2,Color);
  end
  Else If Y2 - Y1 = 1 then
       begin
         HLines (PicBuffer,X1,X2,Y1,Color); HLines (PicBuffer,X1,X2,Y2,Color);
       end
       Else begin
              HLines (PicBuffer,X1,X2,Y1,Color);   VLines (PicBuffer,Y1+1,Y2,X2,Color);
              HLines (PicBuffer,X1,X2-1,Y2,Color); VLines (PicBuffer,Y1+1,Y2-1,X1,Color);
            end;
  End;
end; { Rect }

Function  ImageSize (X1,Y1,X2,Y2 : Integer) : Word;
  Begin
    ImageSize := (X2 - X1 + 1) * (Y2 - Y1 + 1) + 4;
  End;

Procedure GetImage (Var PicBuff; X1,Y1,X2,Y2 : Integer; Var Buffer); ASSEMBLER;
  Asm
    Push ds          { Push Stack                }
    Lds si,PicBuff   { Arahkan DS:SI ke PICBUFF  }
    Les di,Buffer    { Arahkan ES:DI ke BUFFER   }
    Mov dx,Y1        { Dx = Y awal               }
    Mov ax,dx        { Ax = Dx                   }
    Shl dx,2         { Dx = Dx * 4               }
    Add dx,ax        { Dx = Dx + Ax              }
    Shl dx,6         { Dx = Dx * 32              }
    Add dx,X1        { Dx = Dx + X awal          }
    Add si,dx        { Offset = Offset + Dx      }
    Mov bx,X2        { Bx = X akhir              }
    Sub bx,X1        { Bx = Bx - X awal          }
    Inc bx           { Bx = Bx + 1 = Panjang Gambar }
    Mov [es:di],bx   { Tulis Panjang Gambar         }
    Inc di           { Offset = Offset + 1          }
    Inc di           { Offset = Offset + 1          }
    Mov cx,Y2        { Cx = Y akhir              }
    Sub cx,Y1        { Cx = Cx - Y awal          }
    Inc cx           { Cx = Cx + 1 = Lebar Gambar   }
    Mov [es:di],cx   { Tulis Lebar Gambar           }
    Inc di           { Offset = Offset + 1          }
    Inc di           { Offset = Offset + 1          }
    Cld              { Counter Cx Mundur            }
    @1:
      Mov dx,cx      { Dx = Sisa lebar gambar       }
      Mov cx,bx      { Cx = Panjang gambar          }
      Mov ax,si      { Ax = Si                      }
      Rep Movsb      { Baca titik sejumlah Cx       }
      Mov si,ax      { Kembalikan Si ke Si awal     }
      Add si,320     { Si ke koordinat Y berikutnya }
      Mov cx,dx      { Cx = Dx                      }
      Loop @1        { Cx-1, Ulang hingga Cx = 0    }
    Pop ds           { Pop Stack                    }
  End;

Procedure OpenVga256;
  Begin
    Reg.Ax:=$13;
    Intr($10,Reg);
  End;

Procedure MoveW(Var Source; Var Dest; Size:Word); ASSEMBLER;
  Asm
    Push ds          { Push Stack               }
    Les di,Dest      { Arahkan ES:DI ke Dest    }
    Lds si,Source    { Arahkan DS:SI ke Source  }
    Mov Cx,Size      { Counter Cx sebesar Size  }
    SHR CX,1
    DB $66
    Rep MovsW        { Pindahkan DS:SI ke ES:DI }
    Pop ds           { Pop Stack                }
  End;

Procedure FillWord(Var PicBuff; Size:Word; Code:Byte); ASSEMBLER;
  Asm
    Push ds          { Push Stack               }
    Les di,PicBuff   { Arahkan ES:DI ke PicBuff }
    Mov CL,Code      { Al = Warna               }
    Mov CH,Code      { Ah = Warna               }
    MOV AX,CX
    DB $66
    DB $C1
    DB $E0
    DB $10
    MOV AX,CX
    Mov Cx,Size      { Counter sebesar Size     }
    SHR CX,1
    DB $66
    Rep StosW        { Isi ES:DI dengan Warna   }
    Pop ds           { Pop Stack                }
  End;

Procedure PutPixel (Var PicBuff; X,Y : Integer; Color : Byte);
  Begin
    If (X>=0) and (X<=319) and (Y>=0) and (Y<=199) then
    Begin
  Asm
    Push ds         { Push Stack                   }
    Les di,PicBuff  { Arahkan ES:DI ke PICBUFF     }
    Mov dx,Y        { Dx = Koordinat Y             }
    Mov ax,dx       { Ax = Dx                      }
    Shl dx,2        { Dx = Dx * 4                  }
    Add dx,ax       { Dx = Dx + Ax                 }
    Shl dx,6        { Dx = Dx * 32                 }
    Add dx,X        { Dx = Dx + Koordinat X        }
    Add di,dx       { Offset = Offset  + Dx        }
    Mov al,Color    { Al = Warna titik             }
    Stosb           { Alokasi memory layar         }
    Pop ds          { Pop Stack                    }
    End;
   End;
  End;

Procedure VLine(Var PicBuff; X,Y,L : Integer; Col: Byte);
Begin
  If Y<0 then Y:=0;
  If Y>199 then Y:=199;
  If X<0 then X:=0;
  If X>319 then X:=319;
  If Y+L>199 then L:=199-Y;

  Asm
    Push ds         { Push Stack                   }
    Les di,PicBuff  { Arahkan ES:DI ke PICBUFF     }
    Mov dx,Y        { Dx = Koordinat Y             }
    Mov ax,dx       { Ax = Dx                      }
    Shl dx,2        { Dx = Dx * 4                  }
    Add dx,ax       { Dx = Dx + Ax                 }
    Shl dx,6        { Dx = Dx * 32                 }
    Add dx,X        { Dx = Dx + Koordinat X        }
    Add di,dx       { Offset = Offset  + Dx        }
    mov cx,L
    mov al,col
    cld
    @1:
      Mov [es:di],al{ Al = Warna titik             }
      add di,320
    loop @1
    Pop ds          { Pop Stack                    }
  End;
End;

Function  GetPixel (Var PicBuff; X,Y : Integer) : Byte; ASSEMBLER;
  Asm
    Push ds          { Push Stack                  }
    Les di,PicBuff   { Arahkan ES:DI ke PICBUFF    }
    Mov dx,Y         { Dx = Koordinat Y            }
    Mov ax,dx        { Ax = Dx                     }
    Shl dx,2         { Dx = Dx * 4                 }
    Add dx,ax        { Dx = Dx + Ax                }
    Shl dx,6         { Dx = Dx * 32                }
    Add dx,X         { Dx = Dx + Koordinat X       }
    Add di,dx        { Offset = Offset  + Dx       }
    Mov al,[es:di]   { Pindahkan warna titik ke function }
    Pop ds           { Pop Stack                   }
  End;

Procedure Line(Var PicBuff; X1,Y1,X2,Y2:integer; Col : Byte);
Var Dx,Dy,Loop,Ctr              : Integer;
    XPos,YPos                   : Real;
    Rx,Ry                       : Real;
  Begin
    Dx:=X2-X1;
    Dy:=Y2-Y1;
    XPos:=X1;YPos:=Y1;
      If Abs(Dx)>Abs(Dy) then
        Begin
          Rx:=1;
          If Dx<>0 then
            Begin
              Ry:=Abs(Dy/Dx);
              Loop:=Abs(Dx);
            End Else
            Begin
              Rx:=0;
              Ry:=1;
              Loop:=Abs(Dy);
            End;
        End Else
        Begin
          Ry:=1;
          If Dy<>0 then
            Begin
              Rx:=Abs(Dx/Dy);
              Loop:=Abs(Dy);
            End Else
            Begin
              Ry:=0;
              Rx:=1;
              Loop:=Abs(Dx)
            End;
        End;
    If Dx<0 then Rx:=-Rx;
    If Dy<0 then Ry:=-Ry;
    If (Round(XPos)>=0) and (Round(XPos)<=319) and
    (Round(YPos)>=0) and (Round(YPos)<=199) then
      PutPixel(PicBuff,Round(XPos),Round(YPos),Col);
    For Ctr:=1 to Loop do
      Begin
        XPos:=Xpos+Rx;
        YPos:=YPos+Ry;
    If (Round(XPos)>=0) and (Round(XPos)<=319) and
    (Round(YPos)>=0) and (Round(YPos)<=199) then
      PutPixel(PicBuff,Round(XPos),Round(YPos),Col);
      End;
 End;

Procedure Block(Var PicBuff; X1,Y1,X2,Y2 : Integer; Col : Byte);
Begin
  If X1<0 then X1:=0;
  If X1>319 then X1:=319;
  If X2<0 then X2:=0;
  If X2>319 then X2:=319;
  If Y1<0 then Y1:=0;
  If Y1>199 then Y1:=199;
  If Y2<0 then Y2:=0;
  If Y2>199 then Y2:=199;
  Asm
    Push ds          { Push Stack               }
    Les di,PicBuff   { Arahkan DS:SI ke PICBUFF }
    Mov dx,Y1        { Dx = Y awal              }
    Mov ax,dx        { Ax = Dx                  }
    Shl dx,2         { Dx = Dx * 4              }
    Add dx,ax        { Dx = Dx + Ax             }
    Shl dx,6         { Dx = Dx * 32             }
    Add dx,X1        { Dx = Dx + X awal         }
    Add di,dx        { Offset = Offset + Dx     }
    Mov bx,X2        { Bx = X akhir             }
    Sub bx,X1        { Bx = Bx - X awal         }
    Inc bx           { Bx = Bx + 1 = Panjang Blok   }
    Mov cx,Y2        { Cx = Y akhir                 }
    Sub cx,Y1        { Cx = Cx - Y awal             }
    Inc cx           { Cx = Cx + 1 = Lebar Blok     }
    Mov Al,Col       { Al = Warna                   }
    Cld              { Counter Cx Mundur            }
    @1:
      Mov dx,cx      { Dx = Sisa lebar Blok         }
      Mov cx,bx      { Cx = Panjang Blok            }
      Mov si,di      { Ax = Si                      }
      Rep Stosb      { Baca titik sejumlah Cx       }
      Mov di,si      { Kembalikan Si ke Si awal     }
      Add di,320     { Si ke koordinat Y berikutnya }
      Mov cx,dx      { Cx = Dx                      }
      Loop @1        { Cx-1, Ulang hingga Cx = 0    }
    Pop ds           { Pop Stack                    }
  End;
End;

Procedure Circle (Var PicBuff; X,Y : Integer; R : Integer; Col : Byte);
Var Teta   : Integer;
  Begin
    For Teta:=0 to 1440 do
      PutPixel(PicBuff,X+Round(R*Cos(Teta*pi/720)),Y+Round(R*Sin(Teta*pi/720)),Col)
  End;

Procedure Ellipse (Var PicBuff; X,Y : Integer; Rx,Ry : Integer; Col : Byte);
Var Teta   : Integer;
  Begin
    For Teta:=0 to 1440 do
      PutPixel(PicBuff,X+Round(Rx*Cos(Teta*pi/720)),Y+Round(Ry*Sin(Teta*pi/720)),Col)
  End;

Procedure Load_Sprite(File_Name:String;Var Ptr:Pointer;Var Size:Word);
  Begin
    Assign(File_P,File_Name);
    Reset(File_P,1);
    GetMem(Ptr,FileSize(File_P));
    BlockRead(File_P,Ptr^,FileSize(File_P));
    Size:=FileSize(File_P);
    Close(File_P);
  End;

Procedure Save_Sprite(File_Name:String;Ptr:Pointer;Size:Word);
  Begin
    Assign(File_P,File_Name);
    Rewrite(File_P,1);
    BlockWrite(File_P,Ptr^,Size);
    Close(File_P);
  End;

Procedure Define_Page(Var PicBuff : Pointer);
  Begin
    GetMem(PicBuff,64000);
  End;

Procedure UnDefine_Page(Var PicBuff : Pointer);
  Begin
    FreeMem(PicBuff,64000);
  End;

Procedure Fill_Page (Var PicBuff; Col : Byte);
  Begin
    FillWord(PicBuff,32000,Col);
  End;

Procedure MoveTo (Var Source, Destination);
  Begin
    MoveW(Source,Destination,32000);
  End;

Procedure Load_Picture (File_Name:String;Var Buffer);
  Begin
    Assign(File_P,File_Name);
    Reset(File_P,1);
    BlockRead(File_P,Buffer,64000);
    Close(File_P);
  End;

Procedure Save_Picture (File_Name:String;Var Buffer);
  Begin
    Assign(File_P,File_Name);
    Rewrite(File_P,1);
    BlockWrite(File_P,Buffer,64000);
    Close(File_P);
  End;

Procedure SetVisualPalette (No,R,G,B:Byte);
  Begin
    Port[$3c8]:=No;      { Port nomor Palette }
    Port[$3c9]:=R;       { Isi Port Merah     }
    Port[$3c9]:=G;       { Isi Port Hijau     }
    Port[$3c9]:=B;       { Isi Port Biru      }
  End;

Procedure GetVisualPalette (No:Byte; Var R,G,B:Byte);
  Begin
    Port[$3c8]:=No;      { Port nomor Palette }
    R:=Port[$3c9];       { Baca Port Merah    }
    G:=Port[$3c9];       { Baca Port Hijau    }
    B:=Port[$3c9];       { Baca Port Biru     }
  End;

Procedure SetPalette    (Var Arr_Pal:Palette_Addr; No,Rr,Gg,Bb:Byte);
  Begin
    With Arr_Pal^[No] do
      Begin
        R:=Rr;
        G:=Gg;
        B:=Bb;
      End;
  End;

Procedure GetPalette    (Var Arr_Pal:Palette_Addr; No:Byte; Var Rr,Gg,Bb:Byte);
  Begin
    With Arr_Pal^[No] do
      Begin
        Rr:=R;
        Gg:=G;
        Bb:=B;
      End;
  End;

Procedure Load_Palette(Pal_Buff:Pointer; File_Name:String);
Var X        : Byte;
    R,G,B    : Char;
    RR,GG,BB : Byte;
  Begin
    Assign(File_Pal,File_Name);
    Reset(File_Pal,1);
    BlockRead(File_Pal,Pal_Buff^,768);
    Close(File_Pal);
  End;

Procedure Save_Palette (Pal_Buff:Pointer; File_Name:String);
Var X        : Byte;
    Fil      : Text;
  Begin
    Assign(File_Pal,File_Name);
    Rewrite(File_Pal,1);
    BlockWrite(File_Pal,Pal_Buff^,768);
    Close(File_Pal);
  End;

Procedure Refresh_Palette;
  Begin
    For A:=0 to 255 do
      With Active_Pal^[A] do
        Begin
          SetVisualPalette(A,R,G,B);
        End;
  End;

Procedure Active_Palette(Ac_Pal:Palette_Addr);
  Begin
    MoveW(Ac_Pal^,Active_Pal^,384);
    Refresh_Palette;
  End;

Procedure Restore_Palette;
  Begin
    MoveW(Default_Pal^,Active_Pal^,384);
  End;

Procedure Install_Palette(Name:String);
  Begin
    GetMem(Default_Pal,768);
    GetMem(User_Pal,768);
    GetMem(Active_Pal,768);
    Load_Palette(Default_Pal,Name);
    Active_Palette(Default_Pal);
  End;

Procedure Set_All_Palette   (Pal_Buff:Palette_Addr; R,G,B : Byte);
  Begin
    For A:=0 to 255 do
      SetPalette(Pal_Buff,A,R,G,B);
  End;

Procedure Active_To_Palette(Pal_Dest:Palette_Addr; Del:Byte);
Var Done     : Boolean;
    A        : Integer;
  Begin
    Repeat
      Done:=True;
      Delay(Del);
      For A:=0 to 255 do
        With Pal_Dest^[A] do
          Begin
            If Active_Pal^[A].R<R then Inc(Active_Pal^[A].R);
            If Active_Pal^[A].R>R then Dec(Active_Pal^[A].R);
            If Active_Pal^[A].G<G then Inc(Active_Pal^[A].G);
            If Active_Pal^[A].G>G then Dec(Active_Pal^[A].G);
            If Active_Pal^[A].B<B then Inc(Active_Pal^[A].B);
            If Active_Pal^[A].B>B then Dec(Active_Pal^[A].B);
            If Active_Pal^[A].R<>R then Done:=False;
            If Active_Pal^[A].G<>G then Done:=False;
            If Active_Pal^[A].B<>B then Done:=False;
          End;
      Refresh_Palette;
    Until Done;
  End;

Function Metamorph_Palette(Pal_Buff, Pal_Dest : Palette_Addr; Rate:Byte) : Boolean;
  Begin
    Metamorph_Palette:=True;
      For A:=0 to 255 do
        With Pal_Dest^[A] do
          Begin
            If Pal_Buff^[A].R<R then
              Begin
                If Pal_Buff^[A].R+Rate<R then Inc(Pal_Buff^[A].R,Rate)
                  Else Pal_Buff^[A].R:=R;
              End;
            If Pal_Buff^[A].R>R then
              Begin
                If Pal_Buff^[A].R-Rate>R then Dec(Pal_Buff^[A].R,Rate)
                  Else Pal_Buff^[A].R:=R;
              End;
            If Pal_Buff^[A].G<G then
              Begin
                If Pal_Buff^[A].G+Rate<G then Inc(Pal_Buff^[A].G,Rate)
                  Else Pal_Buff^[A].G:=G;
              End;
            If Pal_Buff^[A].G>G then
              Begin
                If Pal_Buff^[A].G-Rate>G then Dec(Pal_Buff^[A].G,Rate)
                  Else Pal_Buff^[A].G:=G;
              End;
            If Pal_Buff^[A].B<B then
              Begin
                If Pal_Buff^[A].B+Rate<B then Inc(Pal_Buff^[A].B,Rate)
                  Else Pal_Buff^[A].B:=B;
              End;
            If Pal_Buff^[A].B>B then
              Begin
                If Pal_Buff^[A].B-Rate>B then Dec(Pal_Buff^[A].B,Rate)
                  Else Pal_Buff^[A].B:=B;
              End;
            If Pal_Buff^[A].R<>R then Metamorph_Palette:=False;
            If Pal_Buff^[A].G<>G then Metamorph_Palette:=False;
            If Pal_Buff^[A].B<>B then Metamorph_Palette:=False;
          End;
  End;

Procedure Load_Vert_Scroll (Name:String);
Var Size : Longint;
    Ctr  : Longint;
  Begin
    Ctr:=1;
    For A:=1 to 800 do
      GetMem(Page_Scroll[A],320);
    Assign(File_P,Name);
    Reset(File_P,1);
    Size:=FileSize(File_P);
    Page_Width:=Size div 320;
    While Size>64000 do
      Begin
        BlockRead(File_P,Page_Scroll[Ctr]^,64000);
        Size:=Size-64000;
        Inc(Ctr,200);
      End;
    BlockRead(File_P,Page_Scroll[Ctr]^,Size);
    Close(File_P);
  End;

Procedure Free_Vert_Scroll;
Var Size : Word;
  Begin
    For A:=1 to 800 do
      FreeMem(Page_Scroll[A],320);
  End;

Procedure Put_Part (Var Page_Scroll; Var PicBuff; Y,Width : Integer); ASSEMBLER;
  Asm
    Push ds            { Push Stack                   }
    Les di,PicBuff     { Arahkan ES:DI ke PICBUFF     }
    Lds si,Page_Scroll { Arahkan DS:SI ke Page_Scroll }
    Mov dx,Y           { Dx = Y awal                  }
    Mov ax,dx          { Ax = Dx                      }
    Shl dx,2           { Dx = Dx * 4                  }
    Add dx,ax          { Dx = Dx + Ax                 }
    Shl dx,6           { Dx = Dx * 32                 }
    Add di,dx          { Offset = Offset + Dx         }

    Mov dx,Width       { Dx = Lebar sisa layar        }
    Mov ax,dx          { Ax = Dx                      }
    Shl dx,2
    Add dx,ax          { Dx = Dx + Ax                 }
    Shl dx,4           { Dx = Dx * 8                  }
    Mov Cx,Dx          { Counter Cx sejumlah Dx       }
    DB $66
    Rep MovsW          { Pindahkan DS:SI ke ES:DI     }
    Pop ds             { Pop Stack                    }
  End;

Procedure Put_Vert_Scroll (Var PicBuff; Y:Integer);
  Begin
    If (Y<=Page_Width) and (Y>=1) then
      Begin
        If Page_Width-Y>=200 then
          MoveW(Page_Scroll[Y]^,PicBuff,32000)
        Else Begin
          MoveW(Page_Scroll[Y]^,PicBuff,(Page_Width-Y+1)*160);
          If Page_Width-Y+1<>200 then
            Put_Part(Page_Scroll[1]^,PicBuff,Page_Width-Y+1,200-(Page_Width-Y+1));
        End;
      End;
  End;

Procedure Load_Horiz_Scroll (Name:String);
Var Size:Word;
    Fil :File;
  Begin
    Assign(Fil,Name);
    Reset(Fil,1);
    BlockRead(Fil,X,2);
    BlockRead(Fil,Y,2);
    GetMem(Page_Scroll[1],64000);
    BlockRead(Fil,Page_Scroll[1]^,64000);
    Px2:=0;Py2:=0;
    Px3:=0;Py3:=0;
    {$I-}
      BlockRead(Fil,X,2);
      BlockRead(Fil,Y,2);
    {$I+}
      If (IOResult=0) and (X>0) then
        Begin
          Px2:=X;Py2:=Y+1;
          Size:=(pY2)*(pX2);
          GetMem(Page_Scroll[2],Size);
          BlockRead(Fil,Page_Scroll[2]^,Size);
        End;
    Close(Fil);
  End;

Procedure Free_Horiz_Scroll;
Var Size : Word;
  Begin
    FreeMem(Page_Scroll[1],64000);
    Size:=(Py2)*(Px2);
    If Px2<>0 then
      FreeMem(Page_Scroll[2],Size);
  End;

Procedure Put_XPart(Var Picbuff,Proc;X,Start,CtrX,XGrid:Word); Assembler;
  Asm
    Push ds
    Les di,PicBuff
    Lds si,Proc
    Mov Cx,200
    @1:
      Push si
      Push di
      Push cx
      Add di,x
      Add si,Start
      Mov Cx,CtrX
      Rep MovsB
      Pop cx
      Pop di
      Pop si
      Add si,XGrid
      Add di,320
    Loop @1
    Pop ds
  End;

Procedure Put_Horiz_Scroll (Var PicBuff;Y:Integer);
Var S,L,T:Word;
  Begin
    If Y<320 then
      Put_XPart(PicBuff,Page_Scroll[1]^,0,Y,320-Y,320);
    If (Y<640) and (Y>0) and (Px2<>0) then
      Begin
        If Y>=320 then
          Begin
            S:=Y-320;
            L:=640-Y;
            T:=0;
          End Else
          Begin
            S:=0;
            L:=Y;
            T:=320-Y;
          End;
        Put_XPart(PicBuff,Page_Scroll[2]^,T,S,L,Px2);
      End;
  End;

Procedure Load_Parallax_Scroll (Name:String);
Var No_Pic:Integer;
    File_P:File;
    File_D:Text;
    Size  :Word;
    PCTR  :Integer;
  Begin
    Assign(File_P,Name+'.Scr');
    Reset(File_P,1);
    Assign(File_D,Name+'.Atr');
    Reset(File_D);
    With Parallax_Dat do
      Begin
        Readln(File_D,Length);
        Readln(File_D,Width);
        Readln(File_D,Page_X);
        Readln(File_D,Page_Y);
        Readln(File_D,Last_X);
        Readln(File_D,Last_Y);
      End;
    PCTR:=1;
    Repeat
    Readln(File_D,Size);
    GetMem(Page_Scroll[PCTR],Size);
    BlockRead(File_P,Page_Scroll[PCTR]^,Size);
    Inc(PCTR);
    Until Eof(File_D);
    Close(File_P);
    Close(File_D);
  End;

Procedure Put_Parallax_Scroll(X,Y:Integer;Var PicBuff;Var Temp);
Var Al_X,Al_Y : Integer;
    Xs,Ys     : Integer;
    Xr,Yr     : Integer;
    Pic_No    : Integer;
    Size      : Word;
  Begin
    Al_X:=(X Div 80)+1;
    Al_Y:=(Y Div 50)+1;
    Xs:=(-(X Mod 80));
    Ys:=(-(Y Mod 50));
    Xr:=Xs;Yr:=Ys;
    Repeat
      Repeat
        Pic_No:=((Al_Y-1)*Parallax_Dat.Page_X)+Al_X;
        Rll_UnCompress(Page_Scroll[Pic_No]^,Temp);
        If (Xr<0) or (Xr>239) or (Yr<0) or (Yr>150)
        then ByteBlockImage(PicBuff,xr,yr,Temp) Else
          WordBlockImage(PicBuff,xr,yr,Temp);
        Inc(Xr,80);
        Inc(Al_X);
      Until Xr>319;
      Xr:=Xs;
      Al_X:=(X Div 80)+1;
      Inc(Al_Y);
      Inc(Yr,50);
    Until Yr>199;
  End;


Procedure Install_Transparent(PalTable:Pointer;Name:String);
Var FileTable:File;
  Begin
    Assign(FileTable,Name);
    Reset(FileTable,1);
    BlockRead(FileTable,PalTable^,65280);
    Close(FileTable);
  End;

Procedure PutOld (Var PicBuff;X,Y : Integer; Var Buffer); ASSEMBLER;
  Asm
    Push ds           { Push Stack               }
    Les di,PicBuff    { Arahkan ES:DI ke PICBUFF }
    Lds si,Buffer     { Arahkan DS:SI ke BUFFER  }
    Mov bx,[ds:si]    { Baca Panjang             }
    Inc si            { Offset + 1               }
    Inc si            { Offset + 1               }
    Mov cx,[ds:si]    { Baca Lebar               }
    Inc si            { Offset + 1               }
    Inc si            { Offset + 1               }
    Mov dx,Y          { Masukkan Y ke Dx         }
    Mov ax,dx         { Masukkan Dx ke Ax        }
    Shl dx,2          { Dx = DX * 4              }
    Add dx,ax         { Dx = Dx + Ax             }
    Shl dx,6          { Dx = Dx * 32             }
    Add dx,X          { Dx = Dx + X              }
    Add di,dx         { Start Offset peletakkan titik }
    Cld               { Counter Cx Mundur             }
    @1:
      Mov dx,cx       { Dx = Sisa Lebar Gambar   }
      Mov cx,bx       { Cx = Sisa Panjang Gambar }
      Push di         { Push Stack               }
      @2:
        Lodsb         { Baca titik dari BUFFER   }
        Or al,al      { Apakah titik = 0         }
        Jz @3         { Kalau Y tidak perlu diletakkan }
        Stosb         { Letakkan titik           }
        Dec di        { Kurangi offset pembacaan titik } { karena di bawah akan ditambah lagi }
        @3:
          Inc di      { Tambah offset pembacaan titik                    }
        Loop @2       { CX-1, Ulang sampai sisa panjang gambar CX = 0    }
      Pop di          { Pop Stack                                        }
      Add di,320      { Register Di ke koordinat Y berikutnya            }
      Mov cx,dx       { Isi CX dengan sisa lebar   gambar                }
      Loop @1         { CX-1, Ulang hingga sisa lebar gambar  = 0        }
    Pop ds            { Pop Stack                }
  End;

Procedure PutImage(Var PicBuff;X1,Y1:Integer;Var Buffer);Assembler;
Var XWStart:Word;
    XRStart:Word;
    YWStart:Word;
    YRStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov YRead,Ax
    Mov YRStart,0
    Mov Ax,Y1
    Mov YWStart,Ax
    Add si,2
    Mov XRStart,0
    Mov Ax,X1
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XRStart,Ax
      Mov XWStart,0
      Sub XRead,Ax
    @X1_Not_Negative:
      Mov Ax,X1
      Add Ax,Length
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y1
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Mov YRStart,Ax
      Sub YRead,Ax
    @No_Top_Crop:
      Mov Ax,Y1
      Add Ax,Width
      Dec Ax
      Cmp Ax,199
    Jle @No_Bot_Crop
      Sub Ax,199
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Ax,YRStart
      Xor Ah,Ah
      Mul Length
      Add si,Ax
      Add si,XRStart

      Mov Cx,YRead
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Cx,XRead
      @Loop2:
         Lodsb
         or al,al
         Jz @No_Write
         Stosb
         dec di
       @No_Write:
         inc di
      Loop @Loop2
      Pop si
      Pop di
      Add si,Length
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;

Procedure ByteBlockImage(Var PicBuff;X1,Y1:Integer;Var Buffer);Assembler;
Var XWStart:Word;
    XRStart:Word;
    YWStart:Word;
    YRStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov YRead,Ax
    Mov YRStart,0
    Mov Ax,Y1
    Mov YWStart,Ax
    Add si,2
    Mov XRStart,0
    Mov Ax,X1
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XRStart,Ax
      Mov XWStart,0
      Sub XRead,Ax
    @X1_Not_Negative:
      Mov Ax,X1
      Add Ax,Length
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y1
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Mov YRStart,Ax
      Sub YRead,Ax
    @No_Top_Crop:
      Mov Ax,Y1
      Add Ax,Width
      Dec Ax
      Cmp Ax,199
    Jle @No_Bot_Crop
      Sub Ax,199
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Ax,YRStart
      Xor Ah,Ah
      Mul Length
      Add si,Ax
      Add si,XRStart

      Mov Cx,YRead
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Cx,XRead
      Rep Movsb
      Pop si
      Pop di
      Add si,Length
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;

Procedure Put1Col(Var PicBuff;X1,Y1:Integer;Col:Byte;Var Buffer);Assembler;
Var XWStart:Word;
    XRStart:Word;
    YWStart:Word;
    YRStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov YRead,Ax
    Mov YRStart,0
    Mov Ax,Y1
    Mov YWStart,Ax
    Add si,2
    Mov XRStart,0
    Mov Ax,X1
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XRStart,Ax
      Mov XWStart,0
      Sub XRead,Ax
    @X1_Not_Negative:
      Mov Ax,X1
      Add Ax,Length
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y1
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Mov YRStart,Ax
      Sub YRead,Ax
    @No_Top_Crop:
      Mov Ax,Y1
      Add Ax,Width
      Dec Ax
      Cmp Ax,199
    Jle @No_Bot_Crop
      Sub Ax,199
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Ax,YRStart
      Xor Ah,Ah
      Mul Length
      Add si,Ax
      Add si,XRStart

      Mov Cx,YRead
      Mov Bl,Col
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Cx,XRead
      @Loop2:
          Lodsb
          or al,al
          Jz @No_Write
          Mov [ES:DI],Bl
        @No_Write:
          inc di
      Loop @Loop2
      Pop si
      Pop di
      Add si,Length
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;

Procedure T_PutImage(Var PicBuff;X1,Y1:Integer;Var Buffer;Var PalTable);Assembler;
Var XWStart:Word;
    XRStart:Word;
    YWStart:Word;
    YRStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov YRead,Ax
    Mov YRStart,0
    Mov Ax,Y1
    Mov YWStart,Ax
    Add si,2
    Mov XRStart,0
    Mov Ax,X1
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XRStart,Ax
      Mov XWStart,0
      Sub XRead,Ax
    @X1_Not_Negative:
      Mov Ax,X1
      Add Ax,Length
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y1
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Mov YRStart,Ax
      Sub YRead,Ax
    @No_Top_Crop:
      Mov Ax,Y1
      Add Ax,Width
      Dec Ax
      Cmp Ax,199
    Jle @No_Bot_Crop
      Sub Ax,199
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Ax,YRStart
      Xor Ah,Ah
      Mul Length
      Add si,Ax
      Add si,XRStart

      Mov Cx,YRead
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Cx,XRead
      @Loop2:
          Lodsb
          or al,al
          Jz @No_Write

          Push bx
          Mov bl,[es:di]
          Xor bh,bh
          Xor ah,ah
          Dec al
          Shl ax,8
          Add ax,bx
          Push es
          Push di
          Les di,PalTable
          Add di,ax
          Mov al,[es:di]
          Pop di
          Pop es
          Pop bx

          Stosb
          dec di
        @No_Write:
          inc di
      Loop @Loop2
      Pop si
      Pop di
      Add si,Length
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;

Procedure T_Put1Col(Var PicBuff;X1,Y1:Integer;Col:Byte;Var Buffer;Var PalTable);Assembler;
Var XWStart:Word;
    XRStart:Word;
    YWStart:Word;
    YRStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov YRead,Ax
    Mov YRStart,0
    Mov Ax,Y1
    Mov YWStart,Ax
    Add si,2
    Mov XRStart,0
    Mov Ax,X1
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XRStart,Ax
      Mov XWStart,0
      Sub XRead,Ax
    @X1_Not_Negative:
      Mov Ax,X1
      Add Ax,Length
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y1
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Mov YRStart,Ax
      Sub YRead,Ax
    @No_Top_Crop:
      Mov Ax,Y1
      Add Ax,Width
      Dec Ax
      Cmp Ax,199
    Jle @No_Bot_Crop
      Sub Ax,199
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Ax,YRStart
      Xor Ah,Ah
      Mul Length
      Add si,Ax
      Add si,XRStart

      Mov Cx,YRead
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Cx,XRead
      @Loop2:
          Lodsb
          or al,al
          Jz @No_Write

          Push bx
          Mov bl,[es:di]
          Xor bh,bh
          Xor ah,ah
          Mov al,col
          Dec al
          Shl ax,8
          Add ax,bx
          Push es
          Push di
          Les di,PalTable
          Add di,ax
          Mov al,[es:di]
          Pop di
          Pop es
          Pop bx

          Stosb
          dec di
        @No_Write:
          inc di
      Loop @Loop2
      Pop si
      Pop di
      Add si,Length
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;

Procedure T_Put3D(Var PicBuff;X,Y : Integer;XL,YL:Word; Var Buffer;Var PalTable);
Var XWStart:Word;
    YWStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;

    XFixed :Word;
    YFixed :Word;
    XFStart:Word;
    YFStart:Word;
    RX     :Word;
    RY     :Word;
  Begin
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov Ah,Al
    Xor Al,Al
    Mov Bx,Ax
    Xor Dx,Dx
    Div XL
    Mov Rx,Ax
    Mov Ax,Bx
    Xor Dx,Dx
    Div Rx
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov Ah,Al
    Xor Al,Al
    Mov Bx,Ax
    Xor Dx,Dx
    Div YL
    Mov Ry,Ax
    Mov Ax,Bx
    Xor Dx,Dx
    Div Ry
    Mov YRead,Ax
    Mov XFixed,0
    Mov YFixed,0
    Mov XFStart,0
    Mov YFStart,0
    Mov Ax,Y
    Mov YWStart,Ax
    Add si,2
    Mov Ax,X
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XWStart,0
      Sub XRead,Ax
      Mul Rx
      Mov XFStart,Ax
    @X1_Not_Negative:
      Mov Ax,XWStart
      Add Ax,XRead
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Sub YRead,Ax
      Mul Ry
      Mov YFStart,Ax
    @No_Top_Crop:
      Mov Ax,YWStart
      Add Ax,YRead
      Cmp Ax,200
    Jle @No_Bot_Crop
      Sub Ax,200
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Cx,YRead
      Mov Ax,YFStart
      Mov YFixed,Ax
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Ax,YFixed
      Mov Al,Ah
      Xor Ah,Ah
      Mul Length
      Add si,Ax

      Mov Cx,XRead
      Mov Ax,XFStart
      Mov XFixed,Ax
      Mov Bx,Rx
      @Loop2:
         Mov Ax,XFixed
         Mov Al,Ah
         Xor Ah,Ah
         Push si
         Add si,Ax

         Lodsb
         Pop si
         Add XFixed,Bx
         or al,al
         Jz @No_Write
          { Transparent Algorithm }
          Push bx
          Mov bl,[es:di]
          Xor bh,bh
          Xor ah,ah
          Dec al
          Shl ax,8
          Add ax,bx
          Push es
          Push di
          Les di,PalTable
          Add di,ax
          Mov al,[es:di]
          Pop di
          Pop es
          Pop bx
          { ----------}
         Stosb
         dec di
       @No_Write:
         inc di
      Loop @Loop2
      Pop si
      Pop di
      Mov Bx,Ry
      Add YFixed,Bx
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;
  End;

Procedure Put3D(Var PicBuff;X,Y : Integer;XL,YL:Word; Var Buffer);
Var XWStart:Word;
    YWStart:Word;
    Length :Word;
    Width  :Word;
    XRead  :Word;  { CX }
    YRead  :Word;

    XFixed :Word;
    YFixed :Word;
    XFStart:Word;
    YFStart:Word;
    RX     :Word;
    RY     :Word;
  Begin
  Asm
    Push ds
    Lds si,Buffer
    Les di,PicBuff
    Mov Ax,[ds:si]
    Mov Length,Ax
    Mov Ah,Al
    Xor Al,Al
    Mov Bx,Ax
    Xor Dx,Dx
    Div XL
    Mov Rx,Ax
    Mov Ax,Bx
    Xor Dx,Dx
    Div Rx
    Mov XRead,Ax
    Add si,2
    Mov Ax,[ds:si]
    Mov Width,Ax
    Mov Ah,Al
    Xor Al,Al
    Mov Bx,Ax
    Xor Dx,Dx
    Div YL
    Mov Ry,Ax
    Mov Ax,Bx
    Xor Dx,Dx
    Div Ry
    Mov YRead,Ax
    Mov XFixed,0
    Mov YFixed,0
    Mov XFStart,0
    Mov YFStart,0
    Mov Ax,Y
    Mov YWStart,Ax
    Add si,2
    Mov Ax,X
    Mov XWStart,Ax
    Cmp Ax,0
    Jge @X1_Not_Negative
      Neg Ax
      Mov XWStart,0
      Sub XRead,Ax
      Mul Rx
      Mov XFStart,Ax
    @X1_Not_Negative:
      Mov Ax,XWStart
      Add Ax,XRead
      Dec Ax
      Cmp Ax,319
    Jle @X1_No_Right_Crop
      Sub Ax,319
      Sub XRead,Ax
    @X1_No_Right_Crop:
      Mov Ax,Y
      Cmp Ax,0
    Jge @No_Top_Crop
      Neg Ax
      Mov YWStart,0
      Sub YRead,Ax
      Mul Ry
      Mov YFStart,Ax
    @No_Top_Crop:
      Mov Ax,YWStart
      Add Ax,YRead
      Cmp Ax,200
    Jle @No_Bot_Crop
      Sub Ax,200
      Sub YRead,Ax
    @No_Bot_Crop:
      Add di,XWStart
      Mov Ax,YWStart
      Shl Ax,2
      Add Ax,YWStart
      Shl Ax,6
      Add di,Ax

      Mov Cx,YRead
      Mov Ax,YFStart
      Mov YFixed,Ax
    @Loop1:
      Push Cx
      Push di
      Push si
      Mov Ax,YFixed
      Mov Al,Ah
      Xor Ah,Ah
      Mul Length
      Add si,Ax

      Mov Cx,XRead
      Mov Ax,XFStart
      Mov XFixed,Ax
      Mov Bx,Rx
      @Loop2:
         Mov Ax,XFixed
         Mov Al,Ah
         Xor Ah,Ah
         Push si
         Add si,Ax

         Lodsb
         Pop si
         Add XFixed,Bx
         or al,al
         Jz @No_Write
         Stosb
         dec di
       @No_Write:
         inc di
      Loop @Loop2
      Pop si
      Pop di
      Mov Bx,Ry
      Add YFixed,Bx
      Add di,320
      Pop Cx
      Loop @Loop1
    Pop ds
  End;
  End;

Procedure WordBlockImage  (Var PicBuff;X,Y : Integer;Var Buffer);Assembler;
  Asm
    Push ds           { Push Stack               }
    Les di,PicBuff    { Arahkan ES:DI ke PICBUFF }
    Lds si,Buffer     { Arahkan DS:SI ke BUFFER  }
    Mov bx,[ds:si]    { Baca Panjang             }
    Inc si            { Offset + 1               }
    Inc si            { Offset + 1               }
    Mov cx,[ds:si]    { Baca Lebar               }
    Inc si            { Offset + 1               }
    Inc si            { Offset + 1               }
    Mov dx,Y          { Masukkan Y ke Dx         }
    Mov ax,dx         { Masukkan Dx ke Ax        }
    Shl dx,2          { Dx = DX * 4              }
    Add dx,ax         { Dx = Dx + Ax             }
    Shl dx,6          { Dx = Dx * 32             }
    Add dx,X          { Dx = Dx + X              }
    Add di,dx         { Start Offset peletakkan titik }
    Shr bx,2
    Cld               { Counter Cx Mundur             }
    @1:
      Mov dx,cx       { Dx = Sisa Lebar Gambar   }
      Mov cx,bx       { Cx = Sisa Panjang Gambar }
      Push di         { Push Stack               }
      DB $66
      Rep MovsW     { Baca titik dari BUFFER   }
      Pop di          { Pop Stack                                        }
      Add di,320      { Register Di ke koordinat Y berikutnya            }
      Mov cx,dx       { Isi CX dengan sisa lebar   gambar                }
      Loop @1         { CX-1, Ulang hingga sisa lebar gambar  = 0        }
    Pop ds            { Pop Stack                }
  End;

Procedure Search_Transparent_Palette(Name:String);
Var A,B,Col1,
    Col2          : Integer;
    Red1,Red2     : Integer;
    Green1,Green2 : Integer;
    Blue1,Blue2   : Integer;
    SRed,SGreen,
    SBlue         : Integer;

    DRed      : Integer;
    DGreen    : Integer;
    DBlue     : Integer;
    Red,Green,
    Blue      : Integer;
    DTotal    : Integer;
    DMin      : Integer;
    TransCol  : Byte;
    FileTable : File;
    Ch        : Char;
  Begin
    Assign(FileTable,Name);
    Rewrite(FileTable,1);
    For Col1:=1 to 255 do
      Begin
        Red1  :=Default_Pal^[Col1].R;
        Green1:=Default_Pal^[Col1].G;
        Blue1 :=Default_Pal^[Col1].B;
        For Col2:=0 to 255 do
          Begin
            Red2  :=Default_Pal^[Col2].R;
            Green2:=Default_Pal^[Col2].G;
            Blue2 :=Default_Pal^[Col2].B;

            SRed  :=(Red1+Red2)     div 2;
            SGreen:=(Green1+Green2) div 2;
            SBlue :=(Blue1+Blue2)   div 2;
            DMin:=1000;
            For A:=0 to 255 do
              Begin
                Red  :=Default_Pal^[A].R;
                Green:=Default_Pal^[A].G;
                Blue :=Default_Pal^[A].B;

                DRed   :=Abs(Red-SRed);
                DGreen :=Abs(Green-SGreen);
                DBlue  :=Abs(Blue-SBlue);
                DTotal:=DRed+DGreen+DBlue;
                If (DTotal<DMin) or (DTotal = 0) then
                  Begin
                    DMin:=DTotal;
                    TransCol:=A;
                  End;
              End;
            BlockWrite(FileTable,TransCol,1);
        End;
      End;
    Close(FileTable);
  End;

Procedure GetAddr(Var PicBuff;Var Seg,Offs:Word);
Var Sg,Off:Word;
  Begin
    Asm
      push ds
      les di,PicBuff
      mov Sg,es
      mov Off,di
      pop ds
    End;
    Seg:=Sg+Off div 16;
    Offs:=Off Mod 16;
  End;

Procedure Color_Compress(Var Source;Var Destination;Var Size:Word);
Var SegS,OffS   :Word;
    SegD,OffD   :Word;
    Length,Width:Word;
    Total       :Word;
    Finish      :Boolean;
    Value       :Byte;
    Long        :Byte;
  Begin
    GetAddr(Source,SegS,OffS);
    GetAddr(Destination,SegD,OffD);
    Move(Mem[SegS:OffS],Length,2);
    Move(Mem[SegS:OffS+2],Width,2);
    Total:=Width*Length+4;
    Finish:=False;

    Value:=Mem[SegS:OffS];
    Long:=0;
    Inc(OffD,2);
    Size:=0;
    Repeat
      If (Mem[SegS:OffS]=Value) and (Long<255) and (OffS<Total) then
        Begin
          Inc(Long);
          Inc(OffS);
        End Else
        Begin
          Mem[SegD:OffD]:=Value;
          Inc(OffD);
          Mem[SegD:OffD]:=Long;
          Inc(OffD);
          Inc(Size,2);
          Value:=Mem[SegS:OffS];
          Long:=0;
          If OffS>=Total then Finish:=True;
        End;
    Until Finish;
    Move(Size,Destination,2);
    Inc(Size,2);
  End;

Procedure Color_UnCompress(Var Source;Var Destination);Assembler;
  Asm
    Push ds
    Lds si,Source
    Les di,Destination
    LodsW
    Shr Ax,1
    Mov Cx,Ax
    @Loop1:
      Push Cx
      LodsW
      Xor Ch,Ch
      Mov Cl,Ah
      @Loop2:
        Stosb
      Loop @Loop2
      Pop Cx
    Loop @Loop1
    Pop ds
  End;

Procedure Zero_Compress(Var Source;Var Destination;Var Size:Word);
Var SegS,OffS   :Word;
    SegD,OffD   :Word;
    Length,Width:Word;
    Total       :Word;
    Finish      :Boolean;
    Value       :Byte;
    Long        :Byte;
    Packet      :Word;
    A,Ctr       :Word;
  Begin
    GetAddr(Source,SegS,OffS);
    GetAddr(Destination,SegD,OffD);
    Move(Mem[SegS:OffS],Length,2);
    Move(Mem[SegS:OffS+2],Width,2);
    Total:=Width*Length+4;
    Finish:=False;

    Value:=Mem[SegS:OffS];
    Long:=0;
    Inc(OffD,2);
    Size:=2;
    Packet:=0;
    Finish:=False;
    Ctr:=0;
    Repeat
      If Value=0 then
        Begin
          Long:=0;
          Repeat
            Inc(Long);
            Inc(OffS);
            Inc(Ctr);
          Until (Mem[SegS:OffS]<>0) or (Long>=255) or (Ctr>=Total);
          Mem[SegD:OffD]:=0;
          Mem[SegD:OffD+1]:=Long;
          Inc(OffD,2);
          Value:=Mem[SegS:OffS];
          Inc(Packet);
          Inc(Size,2);
        End else
        Begin
          Mem[SegD:OffD]:=Value;
          Inc(OffD);
          Inc(OffS);
          Value:=Mem[SegS:OffS];
          Inc(Packet);
          Inc(Ctr);
          Inc(Size);
        End;
      If Ctr>=Total then Finish:=True;
    Until Finish;
    GetAddr(Destination,SegD,OffD);
    Move(Packet,Mem[SegD:OffD],2);
  End;

Procedure Zero_UnCompress(Var Source;Var Destination);
  Begin
  Asm
    Push ds
    Lds si,Source
    Les di,Destination
    LodsW
    Mov Cx,Ax    { Get Packed }
    @Loop1:
      Push Cx
      Lodsb
      Mov Cx,1
      Or Al,Al
      Jnz @Loop2
      Mov bl,al
      Lodsb
      Mov cl,al
      Mov al,bl
      @Loop2:
        Stosb
      Loop @Loop2
      Pop Cx
    Loop @Loop1
    Pop ds
  End;
  End;

Procedure Rll_Compress(Var Source;Var Destination;Var Size:Word);
Var SegS,OffS:Word;
    SegD,OffD:Word;
    Finish:Boolean;
    SrcCtr:Byte;
    FByte :Byte;
    Ctr   :Word;
    OldOFF:Word;
    Length,Width:Word;
  Begin
    Ctr:=1;
    GetAddr(Source,SegS,OffS);
    GetAddr(Destination,SegD,OffD);
    Move(Mem[SegS:OffS],Length,2);
    Move(Mem[SegS:OffS+2],Width,2);
    Size:=Length*Width+4;
    OldOFF:=OffD;
    Finish:=False;
    FByte:=Mem[SegS:OffS];
    Repeat
      SrcCtr:=1;
      While (FByte=Mem[SegS:OffS+SrcCtr]) and (SrcCtr<255) and
      (Ctr<=Size) do
        Begin
          Inc(SrcCtr);
          Inc(Ctr);
        End;
      If SrcCtr>1 then
        Begin
          Mem[SegD:OffD]:=SrcCtr;
          Inc(OffD);
          Mem[SegD:OffD]:=FByte;
          Inc(OffD);
          Inc(OffS,SrcCtr);
          FByte:=Mem[SegS:OffS];
          Inc(Ctr);
        End Else
        Begin
          Mem[SegD:OffD]:=0;
          SrcCtr:=0;
          While (Mem[SegS:OffS+SrcCtr]<>Mem[SegS:OffS+SrcCtr+1]) and
          (SrcCtr<255) and (Ctr<=Size) do
            Begin
              Inc(Ctr);
              Mem[SegD:OffD+SrcCtr+2]:=Mem[SegS:OffS+SrcCtr];
              Inc(SrcCtr);
            End;
          Mem[SegD:OffD+1]:=SrcCtr;
          Inc(OffD,SrcCtr+2);
          Inc(OffS,SrcCtr);
          FByte:=Mem[SegS:OffS];
        End;
      If Ctr>Size then Finish:=True;
    Until Finish;
    Mem[SegD:OffD]:=0;
    Mem[SegD:OffD+1]:=0;
    Size:=OffD+2-OldOFF;
  End;

Procedure PutStr (Var PicBuff;X,Y:Integer;Col1,Col2:Byte;Str:String);
Var A,Start,Stop:Integer;
  Begin
    Start:=0;
    For A:=1 to Length(Str) do
      Begin
        If (A-1)*6+X<0 then Start:=A;
      End;
    If Start<>0 then
      For A:=1 to Start do
        Str[A]:=' ';

    Stop:=0;
    For A:=Length(Str) downto 1 do
      If ((A-1)*6)+X>313 then Stop:=A;
    If Stop<>0 then
      For A:=Length(Str) downto Stop do
        Str[A]:=' ';
    If (Y<192) and (Y>=0) then
      PutString(PicBuff,X,Y,Col1,Col2,Str);
  End;

Procedure RLL_UnCompress (Var Source,Destination); ASSEMBLER;

asm
  Mov dx,ds            { save ds }
  Les di,Destination
  Lds si,Source
  Xor bx,bx
  Cld

@1:
  Xor cx,cx
  Lodsb
  Or  al,al
  Jz  @2
  Mov cl,al
  Add bx,cx
  Lodsb
  Rep Stosb
  Loop @1

@2:
  Lodsb
  Or  al,al
  Jz  @3
  Mov cl,al
  Add bx,cx
  Rep Movsb
  Loop @1

@3:
  Mov ds,dx
end; { RLLxUnCompress }

Procedure CloseVga256;
  Begin
    TextMode(80);
  End;

Begin
  Randomize;
  Already:=False;
End.

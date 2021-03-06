UNIT DATA;
INTERFACE

VAR ANI,DJB,DGK,FONT,T,P    : POINTER;

PROCEDURE MOVEW (VAR SOURCE; VAR DEST; SIZE:WORD);
PROCEDURE FILLW (VAR DEST; SIZE:WORD);

IMPLEMENTATION

PROCEDURE TRIO; EXTERNAL;
{$L TRIO.OBJ}

PROCEDURE TRIO1; EXTERNAL;
{$L TRIO1.OBJ}

PROCEDURE TRIO2; EXTERNAL;
{$L TRIO2.OBJ}

PROCEDURE TRIO3; EXTERNAL;
{$L TRIO3.OBJ}

PROCEDURE TRIO4; EXTERNAL;
{$L TRIO4.OBJ}

PROCEDURE MOVEW (VAR SOURCE; VAR DEST; SIZE:WORD); ASSEMBLER;
ASM
   PUSH DS
   LES DI,DEST
   LDS SI,SOURCE
   MOV CX,SIZE
   REP MOVSW
   POP DS
END;

PROCEDURE FILLW (VAR DEST; SIZE:WORD); ASSEMBLER;
ASM
   PUSH DS
   LES DI,DEST
   MOV CX,SIZE
   XOR AX,AX
   REP STOSW
   POP DS
END;


BEGIN
   DJB  := ADDR (TRIO);
   DGK  := ADDR (TRIO1);
   ANI  := ADDR (TRIO2);
   FONT := ADDR (TRIO3);
   T    := ADDR (TRIO4);
   GETMEM (P,5966);
   MOVEW (T^,P^,2983);
END.

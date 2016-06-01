%{
/* Grammaire du langage TPC */
%}

%token EGAL PV VRG LPAR RPAR LCUR RCUR LSQB RSQB
%token IDENT
%token IF ELSE WHILE RETURN PRINT READ READCH
%token MAIN VOID
%token TYPE NUM CARACTERE
%token COMP ADDSUB DIVSTAR BOPE NEGATION

%union {
	char str[10];
	
}

%%
Prog         : DeclConsts DeclVars DeclFoncts;
DeclConsts   : DeclConsts CONST ListConst PV
             | ;
ListConst    : ListConst VRG IDENT EGAL Litteral
             | IDENT EGAL Litteral ;
Litteral     : NombreSigne
             | CARACTERE ;
NombreSigne  : NUM
             | ADDSUB NUM ;
DeclVars     : DeclVars TYPE Declarateurs PV
             | ;
Declarateurs : Declarateurs VRG Declarateur
             | Declarateur ;
Declarateur  : IDENT
             | IDENT LSQB NUM RSQB ;
DeclFoncts   : DeclFoncts DeclFonct
             | DeclFonct ;
DeclFonct    : EnTeteFonct Corps ;
EnTeteFonct  : TYPE IDENT LPAR Parametres RPAR
             | VOID IDENT LPAR Parametres RPAR ;
Parametres   : VOID
             | ListTypVar ;
ListTypVar   : ListTypVar VRG TYPE IDENT
             | TYPE IDENT ;
Corps        : LCUR DeclConsts DeclVars SuiteInstr RCUR ;
SuiteInstr   : SuiteInstr Instr
             | ;
Instr        : LValue EGAL Exp PV
             | IF LPAR Exp RPAR Instr
             | IF LPAR Exp RPAR Instr ELSE Instr
             | WHILE LPAR Exp RPAR Instr
             | RETURN Exp PV
             | RETURN PV
             | IDENT LPAR Arguments RPAR PV
             | READ LPAR IDENT RPAR PV
             | READCH LPAR IDENT RPAR PV
             | PRINT LPAR Exp RPAR PV
             | PV
             | Bloc ;
Bloc         : LCUR SuiteInstr RCUR ;
Arguments    : ListExp
             | ;
ListExp      : ListExp VRG Exp
             | Exp ;
Exp          : Exp ADDSUB Exp
             | Exp DIVSTAR Exp
             | Exp COMP Exp
             | ADDSUB Exp
             | Exp BOPE Exp
             | NEGATION Exp
             | LPAR Exp RPAR
             | LValue
             | NUM
             | CARACTERE
             | Exp IF LPAR Exp RPAR ELSE Exp
             | IDENT LPAR Arguments RPAR ;
LValue       : IDENT
             | IDENT LSQB Exp RSQB ;
%%

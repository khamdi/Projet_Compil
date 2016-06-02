%{
#include <stdlib.h>
#include <stdio.h>

int yyerror(char*);
int yylex();
FILE* yyin; 
int yylval; 
int jump_label=0;
void inst(const char *);
void instarg(const char *,int);
void comment(const char *);
%}

%token EGAL PV VRG LPAR RPAR LCUR RCUR LSQB RSQB
%token IDENT
%token IF ELSE WHILE RETURN PRINT READ READCH CONST
%token MAIN VOID
%token TYPE NUM CARACTERE
%token COMP ADDSUB DIVSTAR BOPE NEGATION

%union {
	char str[10];
	
}

%%
Prog         : DeclConsts DeclVars DeclFoncts;
DeclConsts   : DeclConsts CONST ListConst PV {/* Table des symboles nécessaire */}
             | ;
ListConst    : ListConst VRG IDENT EGAL Litteral
             | IDENT EGAL Litteral {$1 = $3;};
Litteral     : NombreSigne {$$ = $1;}
             | CARACTERE {$$ = $1;};
NombreSigne  : NUM {$$ = $1;}
             | ADDSUB NUM {$$ = ($1 == '+') ? $1: -$1;};
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
Corps        : LCUR DeclConsts DeclVars SuiteInstr RCUR {/* Corps de fonction, si la fonction est de type void, ne pas oublier return implicite à la fin */};
SuiteInstr   : SuiteInstr Instr
             | ;
Instr        : LValue EGAL Exp PV {$1 = $3;}
             | IF LPAR Exp RPAR Instr {/*TP If/Else*/}
             | IF LPAR Exp RPAR Instr ELSE Instr
             | WHILE LPAR Exp RPAR Instr {/*TP WHILE*/}
             | RETURN Exp PV {/* Empiler la valeur sur la pile */ inst("RETURN");}
             | RETURN PV {inst ("RETURN");}
             | IDENT LPAR Arguments RPAR PV {/* Fonctions */}
             | READ LPAR IDENT RPAR PV {/* Appel de Read sur Identifiant */}
             | READCH LPAR IDENT RPAR PV {/* Idem avec les caractères */}
             | PRINT LPAR Exp RPAR PV {/* Appel de print sur l'expression */}
             | PV
             | Bloc ;
Bloc         : LCUR SuiteInstr RCUR ;
Arguments    : ListExp {/* Count args */}
             | ;
ListExp      : ListExp VRG Exp
             | Exp ;
Exp          : Exp ADDSUB Exp {
				inst("POP");
				inst("SWAP");
				inst ("POP");
				if ($2 == '+')
					inst ("ADD");
				else
					inst ("SUB");
				inst ("PUSH"); /*$$ = ($2 == '+') ? $1 + $3 : $1 - $3;*/}
             | Exp DIVSTAR Exp
             | Exp COMP Exp 
             | ADDSUB Exp {if ($1 == '-') {inst ("POP"); inst ("SWAP"); inst ("PUSH"); instarg ("SET", 0); inst ("SUB"); inst ("SWAP"); inst ("POP"); inst ("SWAP"); inst ("PUSH");}}
             | Exp BOPE Exp {
					inst ("POP"); inst ("SWAP"); inst ("POP");
					switch (*$2.str) {
						case '>':	switch (*$2.str + 1) {
										case '=': inst ("GEQ"); break;
										default : inst ("GREATER"); break;
									}
						case '<':	switch (*$2.str + 1) {
										case '=': inst ("LEQ"); break;
										default : inst ("LESS"); break;
									}																		
						case '=': 	inst ("EQUAL"); break;
						case '!':	inst ("NOTEQ"); break;
						default :	error ("Not a binary operation."); break;
					}
					inst ("PUSH");
				}
             | NEGATION Exp {inst ("POP"); inst ("NEG"); inst ("PUSH"); $$ = ($2) ? 0 : 1;}
             | LPAR Exp RPAR {$$ = $2;}
             | LValue {$$ = $1;}
             | NUM {instarg ("SET", $1); inst ("PUSH"); $$ = $1;}
             | CARACTERE {$$ = $1;}
             | Exp IF LPAR Exp RPAR ELSE Exp {$$ = ($4) ? $1: $6;}
             | IDENT LPAR Arguments RPAR ; {/* Un appel de fonction */}
LValue       : IDENT {$$ = $1;}
             | IDENT LSQB Exp RSQB {/* Tableaux */};
%%

int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

void inst(const char *s){
  printf("%s\n",s);
}

void instarg(const char *s,int n){
  printf("%s\t%d\n",s,n);
}

void comment(const char *s){
  printf("#%s\n",s);
}


int main(int argc, char** argv) {
  if(argc==2){
    yyin = fopen(argv[1],"r");
  }
  else if(argc==1){
    yyin = stdin;
  }
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }
  yyparse();
  inst("HALT");
  return 0;
}

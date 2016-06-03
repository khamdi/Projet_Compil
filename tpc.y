%{
#include <stdlib.h>
#include <stdio.h>

int yyerror(char*);
int yylex();
FILE* yyin; 
/*int yylval;*/
int jump_label=0;
void inst(const char *);
void instarg(const char *,int);
void comment(const char *);
%}

%union {
	char id[64];
	char bop[3];
	char op;
	int val;
}

%token EGAL PV VRG LPAR RPAR LCUR RCUR LSQB RSQB
%token <id> IDENT
%token IF ELSE WHILE RETURN PRINT READ READCH CONST
%token MAIN VOID NEGATION
%token TYPE
%token <val> NUM CARACTERE
%token <op> ADDSUB DIVSTAR
%token <bop> COMP BOPE

%type <val> IFACTION ELSEACTION WHILELABEL WHILECOMP

%left COMP BOPE ADDSUB
%left unaryOp
%right EGAL

%%
Prog         : DeclConsts DeclVars DeclFoncts;
DeclConsts   : DeclConsts CONST ListConst PV {/* Table des symboles nécessaire */}
             | ;
ListConst    : ListConst VRG IDENT EGAL Litteral
             | IDENT EGAL Litteral {/*$1 = $3;*/};
Litteral     : NombreSigne {/*$$ = $1;*/}
             | CARACTERE {/*$$ = $1;*/};
NombreSigne  : NUM {/*$$ = $1;*/}
             | ADDSUB NUM {/*$$ = ($1 == '+') ? $1: -$1;*/};
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
Instr        : LValue EGAL Exp PV {/*$1 = $3;*/}
             | IF LPAR Exp IFACTION RPAR Instr {instarg ("LABEL", $4);}
             | IF LPAR Exp IFACTION RPAR Instr ELSE ELSEACTION {instarg ("LABEL", $4);} Instr {instarg ("LABEL", $8);}
             | WHILE WHILELABEL LPAR Exp RPAR WHILECOMP Instr {instarg ("JUMP", $2); instarg ("LABEL", $6);}
             | RETURN Exp PV {/* Empiler la valeur sur la pile */inst ("POP"); inst("RETURN");}
             | RETURN PV {inst ("RETURN");}
             | IDENT LPAR Arguments RPAR PV {/* Fonctions */}
             | READ LPAR IDENT RPAR PV {inst ("READ"); inst ("PUSH");/* Appel de Read sur Identifiant */}
             | READCH LPAR IDENT RPAR PV {inst ("READCH"); inst ("PUSH");/* Idem avec les caractères */}
             | PRINT LPAR Exp RPAR PV {inst ("POP"); inst ("WRITE"); inst ("PUSH");/* Appel de print sur l'expression */}
             | PV
             | Bloc ;
IFACTION	 : {instarg ("JUMPF", $$=jump_label++);};
ELSEACTION	 : {instarg ("JUMP", $$=jump_label++);};
WHILELABEL	 : {instarg ("LABEL", $$=jump_label++);};
WHILECOMP	 : {instarg ("JUMPF", $$=jump_label++);};
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
             | Exp DIVSTAR Exp {
				inst("POP");
				inst("SWAP");
				inst ("POP");
				switch ($2) {
					case '*': inst ("MUL"); break;
					case '/': inst ("DIV"); break;
					case '%': inst ("MOD"); break;
				}
				inst ("PUSH"); /*$$ = ($2 == '+') ? $1 + $3 : $1 - $3;*/}
             | Exp COMP Exp {
					inst ("POP");
					inst ("SWAP");
					inst ("POP");
					switch (*$2) {
						case '>':	switch (*($2 + 1)) {
										case '=': inst ("GEQ"); break;
										default : inst ("GREATER"); break;
									} break;
						case '<':	switch (*($2 + 1)) {
										case '=': inst ("LEQ"); break;
										default : inst ("LESS"); break;
									} break;													
						case '=': 	inst ("EQUAL"); break;
						case '!':	inst ("NOTEQ"); break;
						default :	yyerror ("Not a comparator."); break;
					}
					inst ("PUSH");
				}
			 | Exp BOPE Exp {
					inst ("POP"); inst ("SWAP"); inst ("POP");
					switch (*$2) {
						case '|':	instarg ("JUMPF", jump_label++);  break;
						case '&':	inst ("NEG"); instarg ("JUMPF", jump_label++); inst ("NEG"); break;
					}
					inst ("NEG"); inst ("NEG"); inst ("PUSH"); instarg ("JUMP", jump_label++); instarg ("LABEL", jump_label - 2); inst ("SWAP"); inst ("NEG"); inst ("NEG"); inst ("PUSH"); instarg ("LABEL", jump_label - 1);
				}
             | ADDSUB Exp %prec unaryOp {if ($1 == '-') {inst ("POP"); inst ("SWAP"); inst ("PUSH"); instarg ("SET", 0); inst ("SUB"); inst ("SWAP"); inst ("POP"); inst ("SWAP"); inst ("PUSH");}}
             | NEGATION Exp {inst ("POP"); inst ("NEG"); inst ("PUSH"); /*$$ = ($2) ? 0 : 1;*/}
             | LPAR Exp RPAR {/*$$ = $2;*/}
             | LValue {/*$$ = $1;*/}
             | NUM {instarg ("SET", $1); inst ("PUSH"); /*$$ = $1;*/}
             | CARACTERE {/*$$ = $1;*/}
             | Exp IF LPAR Exp RPAR ELSE Exp {/*$$ = ($4) ? $1: $6;*/}
             | IDENT LPAR Arguments RPAR {/* Un appel de fonction */}; 
LValue       : IDENT {/*$$ = $1;*/}
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

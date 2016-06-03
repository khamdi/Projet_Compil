%{
#include <stdlib.h>
#include <stdio.h>

#define IDENT_MAX 64

#define VOID 0
#define ENTIER 1
#define CHAR 2
#define CONST 3

int yyerror(char*);
int yylex();
FILE* yyin; 
/*int yylval;*/

int VARS_MAX = 1000
int FUN_MAX = 1000
int top_stack_position = 0;

int jump_label = 0;
int size_fun_sym = 0;
int nb_funs = 0;

fun_sym funs[FUN_MAX];

void inst(const char *);
void instarg(const char *,int);
void comment(const char *);

typedef struct {
      char name[IDENT_MAX];
      int type;
      int value
      int size;
      int position;
}var_sym;

typedef struct {
      char name[IDENT_MAX];
      int return_type;
      int nb_arg;
      int num_lab;
      int nb_vars;
      var_sym *fun_vars;
}fun_sym;


void add_var_fun (char * name_var, int type_var, int value_var, int position, int num_lab_fun);
int search_var_fun (char * name);
void add_fun (char * name, int return_type, int nb_arg);

%}

%union {
	char id[IDENT_MAX];
	char character[4];
	char bop[3];
	char op;
	int val;
}

%token EGAL PV VRG LPAR RPAR LCUR RCUR LSQB RSQB
%token <id> IDENT
%token IF ELSE WHILE RETURN PRINT READ READCH CONST
%token MAIN VOID NEGATION
%token TYPE
%token <val> NUM
%token <character> CARACTERE
%token <op> ADDSUB DIVSTAR
%token <bop> COMP BOPE

%type <id>  LValue
%type <val> IFACTION ELSEACTION WHILELABEL WHILECOMP
%type <val> ListTypVar Parametres

%left COMP BOPE ADDSUB
%left unaryOp
%right EGAL

%%
Prog         : DeclConsts DeclVars DeclFoncts;
DeclConsts   : DeclConsts CONST ListConst PV {/* Table des symboles nécessaire */}
             | ;
ListConst    : ListConst VRG IDENT EGAL Litteral 
                                                {
                                                      add_var_sym($3, CONST, $5, jump_label++);
                                                      instarg("ALLOC", 1);

                                                }
             | IDENT EGAL Litteral {add_var_sym($1, CONST, $3, jump_label++);}
Litteral     : NombreSigne {/*$$ = $1;*/}
             | CARACTERE {/*$$ = $1;*/};
NombreSigne  : NUM {/*$$ = $1;*/}
             | ADDSUB NUM {/*$$ = ($1 == '+') ? $1: -$1;*/};
DeclVars     : DeclVars TYPE Declarateurs PV{}
             | ;
Declarateurs : Declarateurs VRG Declarateur
             | Declarateur ;
Declarateur  : IDENT
             | IDENT LSQB NUM RSQB ;
DeclFoncts   : DeclFoncts DeclFonct
             | DeclFonct ;
DeclFonct    : EnTeteFonct Corps ;
EnTeteFonct  : TYPE IDENT LPAR Parametres RPAR
             | VOID IDENT LPAR Parametres RPAR {/* $4 contient le nombre de paramètres */};
Parametres   : VOID {$$ = 0;}
             | ListTypVar {$$ = $1;};
ListTypVar   : ListTypVar VRG TYPE IDENT {$$ = $1 + 1;}
             | TYPE IDENT {$$ = 1;};
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
Arguments    : ListExp {$$ = $1;/* Count args : $1 */}
             | {$$ = 0;};
ListExp      : ListExp VRG Exp {$$ = $1 + 1;}
             | Exp {$$ = 1};
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
             | NEGATION Exp {inst ("POP"); inst ("NEG"); inst ("PUSH");}
             | LPAR Exp RPAR {/*Rien à faire*/}
             | LValue {instarg ("SET", search_var_fun ($1)); inst ("LOADR"); inst ("PUSH");/*Table des symboles : LOADR*/}
             | NUM {instarg ("SET", $1); inst ("PUSH"); /*$$ = $1;*/}
             | CARACTERE {instarg ("SET", *($1 + 1)); inst ("PUSH");/*$$ = $1;*/}
             | Exp IF LPAR Exp RPAR ELSE Exp {inst ("POP"); inst ("SWAP"); inst ("POP"); inst ("NEG"); instarg ("JUMPF", jump_label++); inst ("NEG"); inst ("SWAP"); inst ("PUSH"); instarg ("JUMP", jump_label++); instarg ("LABEL", jump_label - 2); inst ("POP"); inst ("PUSH"); instarg ("LABEL", jump_label - 1);/*$$ = ($4) ? $1: $6;*/}
             | IDENT LPAR Arguments RPAR {/* Un appel de fonction */}; 
LValue       : IDENT {$$ = $1;/*Table des symboles*/}
             | IDENT LSQB Exp RSQB {$$ = $1;/* Tableaux : manipulation de l'indice */};
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

void add_fun (char * name, int return_type, int nb_arg){
      int i;

      for(i = 0; i < nb_funs; i++){
            if (!strcmp(funs[i].name, name)){
                  fprintf(stderr, "THE NAME %s IS ALREADY USED\n", name);
                  exit(EXIT_FAILURE);
            }
      }

      if (nb_funs == FUN_MAX){
            if (NULL == realloc(funs, FUN_MAX * 2)){
                  fprintf(stderr, "NO MORE SPACE LEFT\n");
                  exit(EXIT_FAILURE);
            }
            FUN_MAX *= 2;
      }

      strcpy(funs[nb_funs].name, name);
      funs[nb_funs].return_type = return_type;
      funs[nb_funs].num_lab = jump_label ++;
      funs[nb_funs].nb_arg = nb_arg;

      nb_funs ++;
}

void add_var_fun (char * name_var, int type_var, int value_var, int position, int num_lab_fun){
      int j, i;
      int nbs_var_fun;
      
      for (j = 0; j < size_fun_sym; j++) {
            if (funs[j].num_lab == num_lab_fun){
                  
                  nbs_var_fun = funs[j].nb_vars;

                  for (i = 0; i < nbs_var_fun; i++){
                        if (strcmp(name, vars[i].name)){
                              fprintf(stderr, "ERROR %s IS ALREADY USED\n", name);
                              exit(EXIT_FAILURE);
                        }
                  } 
                  if (nbs_var_fun == VARS_MAX){
                        if (NULL == realloc (vars, VARS_MAX * 2)){
                              fprintf(stderr, "NO MORE SPACE LEFT\n");
                              exit(EXIT_FAILURE);
                        }
                        VARS_MAX *= 2;
                  }
                  strcpy(funs[j].funs_vars[nbs_var_fun].name, name);
                  funs[j].funs_vars[nbs_var_fun].type = type;
                  funs[j].funs_vars[nbs_var_fun].value = value;
                  funs[j].funs_vars[nbs_var_fun].position = position;

                  funs[j].nb_vars ++;
            }
      }
}

int search_var_fun (char * name){
      int i, j;

      for (i = 0; i < nb_funs; i++){
            for (j = 0; j < funs[i].nb_vars; j++){
                  if (!strcmp(funs[i].var_sym[j].name,name)
                        return funs[i].var_sym[j].position;
            }
      }
      fprintf(stderr, "THE VARIABLE %s DOES NOT EXIST\n",name);
      exit(EXIT_FAILURE);
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

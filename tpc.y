%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define IDENT_MAX	64
#define VARS_MAX	64
#define FUN_MAX	64

#define __MAIN_LABEL__ 0

#define __VOID__ 0
#define __ENTIER__ 1
#define __CHAR__ 2
#define __CONST__ 3

typedef struct {
      char name[IDENT_MAX];
      int type;
      int size;
      int position;
}var_sym;

typedef struct {
      char name[IDENT_MAX];
      int return_type;
      int nb_arg;
	  int nb_vars_max;
      int num_lab;
      int nb_vars;
      var_sym *fun_vars;
}fun_sym;

int yyerror(char*);
int yylex();
FILE* yyin; 
/*int yylval;*/

int top_stack_position = 0;

int count = 0;
int jump_label = 1;
int current_label = 0;
int size_fun_sym = 0;
int nb_funs = 0;
int nb_funs_max = FUN_MAX;
fun_sym* funs = NULL;

void inst(const char *);
void instarg(const char *,int);
void comment(const char *);

void init ();
void before_exit ();

int add_var_fun (char * name_var, int type_var, int position, int num_lab_fun);
int search_var_fun_in_label (char* name, int label);
int search_var_fun (char * name);
void add_fun (char * name, int return_type);
void add_args (char* name, int type, int position, int num_lab_fun);
int convert_type (char * type_name);
void check_main ();
int find_fun(char * name);
int return_nb_args_fun (char * name);

%}

%union {
	char id[64];
	char character[4];
	char bop[3];
	char op;
	int val;
}

%union {
	int count;
}

%token EGAL PV VRG LPAR RPAR LCUR RCUR LSQB RSQB
%token <id> IDENT
%token IF ELSE WHILE RETURN PRINT READ READCH CONST
%token MAIN VOID NEGATION
%token <id> TYPE
%token <val> NUM
%token <character> CARACTERE
%token <op> ADDSUB DIVSTAR
%token <bop> COMP BOPE

%type <id>  LValue
%type <val> IFACTION ELSEACTION WHILELABEL WHILECOMP
%type <val> ListTypVar Parametres Arguments ListExp Litteral NombreSigne ListConst

%left COMP BOPE ADDSUB
%left unaryOp
%right EGAL

%%
Prog         : DeclConsts DeclVars DeclFoncts {check_main();};
DeclConsts   : DeclConsts CONST ListConst PV {/* Table des symboles nécessaire */}
             | ;
ListConst    : ListConst VRG IDENT EGAL Litteral {
				 $$ = $1 + 1;
//			     printf ("%s\n", $3);
                 add_var_fun($3, __CONST__, count, current_label); // $3: Identificateur , $$: Numéro de la constante dans l'ordre d'apparition du programme.
				 count++;
				 instarg ("SET", $5); 
                 inst ("PUSH"); 
               }
             | IDENT EGAL Litteral {add_var_fun($1, __CONST__, count, current_label); count++; instarg ("SET", $3); inst ("PUSH");};
Litteral     : NombreSigne {$$ = $1;}
             | CARACTERE {$$ = *($1 + 1);};
NombreSigne  : NUM {$$ = $1;}
             | ADDSUB NUM {$$ = ($1 == '+') ? $1: -$1;};
DeclVars     : DeclVars TYPE Declarateurs PV
             | ;
Declarateurs : Declarateurs VRG Declarateur
             | Declarateur;
Declarateur  : IDENT
             | IDENT LSQB NUM RSQB ;
DeclFoncts   : DeclFoncts DeclFonct
             | DeclFonct ;
DeclFonct    : EnTeteFonct {/* Si ($1: nom de la fonction) est "main", faire un saut/label pour commencer à exécuter main après avoir réservé de la place pour les constantes et globales */ } Corps {/*FAIRE LE CORPS*/} ;
EnTeteFonct  : TYPE IDENT LPAR {add_fun($2, convert_type($1)); instarg("LABEL", current_label); /*snprintf ($$, 64, "%s", $2);*/ count = 0;} Parametres {funs[nb_funs - 1].nb_arg = $4;} RPAR
             | VOID IDENT LPAR {add_fun($2, __VOID__); instarg("LABEL", current_label); /*snprintf ($$, 64, "%s", $2);*/ count = 0;} Parametres {funs[nb_funs - 1].nb_arg = $4;} RPAR;
Parametres   : VOID {$$ = 0;/* Rien à faire pour les arguments */}
             | ListTypVar {$$ = $1;};
ListTypVar   : ListTypVar VRG TYPE IDENT {$$ = $1 + 1; add_args ($4, convert_type($3), count, current_label); count++;}
             | TYPE IDENT {$$ = 1; add_args ($2, convert_type($1), count, current_label); count++;};
Corps        : LCUR DeclConsts DeclVars SuiteInstr RCUR {/* Corps de fonction, si la fonction est de type void, ne pas oublier return implicite à la fin */};
SuiteInstr   : SuiteInstr Instr
             | ;
Instr        : LValue EGAL Exp PV {/*$1 = $3;*/}
             | IF LPAR Exp IFACTION RPAR Instr {instarg ("LABEL", $4);}
             | IF LPAR Exp IFACTION RPAR Instr ELSE ELSEACTION {instarg ("LABEL", $4);} Instr {instarg ("LABEL", $8);}
             | WHILE WHILELABEL LPAR Exp RPAR WHILECOMP Instr {instarg ("JUMP", $2); instarg ("LABEL", $6);}
             | RETURN Exp PV {/* Empiler la valeur sur la pile */inst ("POP"); inst("RETURN");}
             | RETURN PV {inst ("RETURN");}
             | IDENT LPAR Arguments RPAR PV 
                                                {
                                                      if (return_nb_args_fun($1) == $3){
                                                            instarg("CALL", find_fun($1));
                                                      }
                                                      else{
															fprintf (stderr, "%d <> %d", return_nb_args_fun ($1), $3);
                                                            fprintf(stderr, "ARGUMENT PROBLEME FOR THE FUNCTION %s\n", $1 );
                                                            exit(EXIT_FAILURE);
                                                      }

                                                }
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
             | Exp {$$ = 1;};
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
             | LValue {
					int x;
					if (-1 == (x = search_var_fun_in_label ($1, current_label))) { /* Local function */
						if (-1 == (x = search_var_fun_in_label ($1, 1))) {
							fprintf (stderr, "VARIABLE %s DOES NOT EXIST", $1);
						}
						instarg ("SET", x);
						inst ("LOAD");
					}
					else {
						instarg ("SET", x);
						inst ("LOADR");
					}
					inst ("PUSH");
					/*Table des symboles : LOADR*/
				}
             | NUM {instarg ("SET", $1); inst ("PUSH"); /*$$ = $1;*/}
             | CARACTERE {instarg ("SET", *($1 + 1)); inst ("PUSH");/*$$ = $1;*/}
             | Exp IF LPAR Exp RPAR ELSE Exp {inst ("POP"); inst ("SWAP"); inst ("POP"); inst ("NEG"); instarg ("JUMPF", jump_label++); inst ("NEG"); inst ("SWAP"); inst ("PUSH"); instarg ("JUMP", jump_label++); instarg ("LABEL", jump_label - 2); inst ("POP"); inst ("PUSH"); instarg ("LABEL", jump_label - 1);/*$$ = ($4) ? $1: $6;*/}
             | IDENT LPAR Arguments RPAR  {
                                                if (return_nb_args_fun($1) == $3){
                                                            instarg("CALL", find_fun($1));
                                                }
                                                else{
                                                      fprintf(stderr, "ARGUMENT PROBLEME FOR THE FUNCTION %s\n", $1 );
                                                      exit(EXIT_FAILURE);
                                                }
                                          }; 
LValue       : IDENT {snprintf ($$, 64, "%s", $1); /*Table des symboles*/}
             | IDENT LSQB Exp RSQB {snprintf ($$, 64, "%s", $1); /* Tableaux : manipulation de l'indice */};
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

int convert_type (char * type_name){
      switch (*type_name){
            case 'e' : return __ENTIER__;
            case 'c' : return __CHAR__;
            default : fprintf(stderr, "THIS TYPE %s DOES NOT EXIST \n", type_name); exit(EXIT_FAILURE);
      }
}

void init () {
	if (!(funs = malloc (FUN_MAX * sizeof (fun_sym)))) {
		fprintf (stderr, "Failed allocation : init\n");
		exit (EXIT_FAILURE);
	}
	add_fun ("__INIT__", 0);
}

void before_exit () {
	int i;

	for (i = 0 ; i < nb_funs ; i++) {
		free (funs[i].fun_vars);
	}
	free (funs);
}

int find_fun(char * name){
      int i;

      for (i = 0; i < nb_funs; i++){
            if (!strcmp(funs[i].name, name))
                  return funs[i].num_lab;
      }
      fprintf(stderr, "THE FUNCTION %s DOES NOT EXIST\n", name);
      exit(EXIT_FAILURE);
}

int return_nb_args_fun (char * name){
      int i;

      for (i = 0; i < nb_funs; i++){
            if (!strcmp(funs[i].name, name))
                  return funs[i].nb_arg;
      }
      fprintf(stderr, "THE FUNCTION %s DOES NOT EXIST\n", name);
      exit(EXIT_FAILURE);
}

void add_fun (char * name, int return_type){
      int i;

      for(i = 0; i < nb_funs; i++){
            if (!strcmp(funs[i].name, name)){
                  fprintf(stderr, "THE NAME %s IS ALREADY USED\n", name);
                  exit(EXIT_FAILURE);
            }
      }

      if (nb_funs == FUN_MAX){
            if (NULL == realloc(funs, nb_funs_max * 2)){
                  fprintf(stderr, "NO MORE SPACE LEFT\n");
                  exit(EXIT_FAILURE);
            }
            nb_funs_max *= 2;
      }

      strcpy(funs[nb_funs].name, name);
      funs[nb_funs].return_type = return_type;

      if (!strcmp(name, "main")) {
		  current_label = __MAIN_LABEL__;
          funs[nb_funs].num_lab = __MAIN_LABEL__;
	  }
      else {
		  current_label = jump_label;
	      funs[nb_funs].num_lab = current_label;
		  jump_label++;
	  }
      funs[nb_funs].nb_arg = 0;
	  funs[nb_funs].nb_vars_max = VARS_MAX;
	  if (!(funs[nb_funs].fun_vars = malloc (VARS_MAX * sizeof (var_sym)))) {
	     fprintf (stderr, "Failed allocation : add_fun");
	     exit (EXIT_FAILURE);
	  }

      nb_funs ++;
}

int add_var_fun (char * name, int type_var, int position, int num_lab_fun){
      int j, i;
      int nbs_var_fun;
      
	fprintf (stderr, "Addvar %s in : %d\n", name, num_lab_fun);

      for (j = 0; j < nb_funs; j++) {
            if (funs[j].num_lab == num_lab_fun){
                  
                  nbs_var_fun = funs[j].nb_vars;

                  for (i = 0; i < nbs_var_fun; i++){
                        if (strcmp(name, funs[j].fun_vars[i].name)){
                              fprintf(stderr, "ERROR %s IS ALREADY USED\n", name);
                              exit(EXIT_FAILURE);
                        }
                  } 
                  if (nbs_var_fun == funs[j].nb_vars_max){
                        if (NULL == realloc (funs[j].fun_vars, funs[j].nb_vars_max * 2)){
                              fprintf(stderr, "NO MORE SPACE LEFT\n");
                              exit(EXIT_FAILURE);
                        }
                        funs[j].nb_vars_max *= 2;
                  }
                  strcpy(funs[j].fun_vars[nbs_var_fun].name, name);
                  funs[j].fun_vars[nbs_var_fun].type = type_var;
                  funs[j].fun_vars[nbs_var_fun].position = position;

                  funs[j].nb_vars ++;
				  return j;
            }
      }
	fprintf (stderr, "Fonction non trouvée.\n");
	return -1;
}

void add_args (char* name, int type, int position, int num_lab_fun) {
	int tmp = add_var_fun (name, type, position, num_lab_fun);
	funs[tmp].nb_arg++;
}

int search_var_fun_in_label (char* name, int label) {
	int i, j;

      for (i = 0; i < nb_funs; i++){
			if (label == funs[i].num_lab) {
	            for (j = 0; j < funs[i].nb_vars; j++){
	            	if (!strcmp(funs[i].fun_vars[j].name,name))
                    	return funs[i].fun_vars[j].position;
	            }
			}
      }
	return -1;
}

int search_var_fun (char * name){
      int i, j;

      for (i = 0; i < funs[jump_label].nb_vars; i++){
            if (!strcmp(funs[jump_label].fun_vars[i].name,name))
                  return funs[jump_label].fun_vars[i].position;
      }
      for (i = 0; i < funs[0].nb_vars; i++){
            if (!strcmp(funs[0].fun_vars[i].name,name))
                  return funs[0].fun_vars[i].position;
      }
      
      fprintf(stderr, "THE VARIABLE %s DOES NOT EXIST\n",name);
      exit(EXIT_FAILURE);
}

void check_main (){
      int i;

      for (i = 0; i < nb_funs; i++)
            if (!strcmp(funs[i].name, "main"))
                  return;
      
      fprintf(stderr, "NO MAIN FUNCTION\n");
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
  init ();
  yyparse();
  inst("HALT");
  before_exit ();
  return 0;
}

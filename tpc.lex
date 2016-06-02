%{
#include "tpc.h"
%}

%option noyywrap
%option noinput
%option nounput

id		[A-Za-z_][A-Za-z_0-9]*
num 	[0-9]+

%%

[ \t\n]+					;
if							{return IF;}
else						{return ELSE;}
while						{return WHILE;}
return						{return RETURN;}
print						{return PRINT;}
read						{return READ;}
readch						{return READCH;}
const						{return CONST;}

main						{return MAIN;}
void						{return VOID;}

"entier"|"caractere"		{return TYPE;}
{num}						{sscanf(yytext," %d",&(yylval.val)); return NUM;}
\'[A-Za-z0-9]\'				{return CARACTERE;}

{id}						{snprintf (yylval.id,64,"%s",yytext); return IDENT;}

"=="|"<="|">="|"!="|"<"|">" {snprintf (yylval.bop, 3, "%s", yytext); return COMP;}
=							{return EGAL;}
[+-]						{sscanf (yytext, " %c", &(yylval.op)); return ADDSUB;}
[*/%]						{sscanf (yytext, " %c", &(yylval.op)); return DIVSTAR;}
"&&"|"||"					{snprintf (yylval.bop, 3, "%s", yytext); return BOPE;}
!							{return NEGATION;}

\;							{return PV;}
\,							{return VRG;}
\(							{return LPAR;}
\)							{return RPAR;}
\{							{return LCUR;}
\}							{return RCUR;}
\[							{return LSQB;}
\]							{return RSQB;}
.							return yytext[0];
%%

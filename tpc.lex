
%option noyywrap
%option noinput
%option nounput

id		[A-Za-z_][A-Za-z_0-9]*
num [0-9]+

%%

if {return IF;}
else {return ELSE;}
while {return WHILE;}
return {return RETURN;}
print {return PRINT;}
read {return READ;}
readch {return READCH;}
const {return CONST;}

main {return MAIN;}
void {return VOID;}

"entier"|"caractere" {sscanf(yytext,"%s",yylval.str); return TYPE;}
{num} {sscanf(yytext,"%d",&yylval); return NUM;}
'[A-Za-z0-9]' {sscanf(yytext,"%d",yylval); return CARACTERE;}

{id} {sscanf(yytext,"%s",yylval.str); return IDENT;}

"=="|"<="|">="|"!="|"<"|">" {sscanf(yytext,"%s",yylval.str); return COMP;}
= {return EGAL;}
[+-] {sscanf(yytext,"%s",yylval.str); return ADDSUB;}
[*/%] {sscanf(yytext,"%s",yylval.str); return DIVSTAR;}
"&&"|"||" {sscanf(yytext,"%s",yylval.str); return BOPE;}
! {return NEGATION;}

; {return PV;}
, {return VRG;}
( {return LPAR;}
) {return RPAR;}
{ {return LCUR;}
} {return RCUR;}
[ {return LSQB;}
] {return RSQB;}

%%


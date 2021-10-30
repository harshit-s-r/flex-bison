%{
    #include<iostream>
	#include <string>
	#include "ss.tab.h"
	#include "sqlite3.h"            //using sqlite3 dbms
	int yyparse (void);
    extern void swapper(char*);     //swapper is a function in ss.y which, on correct parse, swaps the token <A..>
                                    //with its counterpart actual fieldname from another table
%}

%%

[ \t\n]+;                       //do nothing on spaces and new line
(<A[0-9]+>) { yylval.str_val =  yytext; return VARIABLE;}       //if we get variable of the form <A1>, save it as string
[0-9][0-9]*(.[0-9]+)? { yylval.double_val = atof ( yytext); return NUMBER;}     //same for number, but it is unneccessary
[+-/*] return OP;               //return OP for all mathematical operations
"(" return LPAREN;
")" return RPAREN;
. {std::cout<<"\nUnrecognised Character stream\n";exit(1);};

%%

int yywrap () {return 1;}   //yywrap 1 tells yy scanner or yyin to stop reading and waiting after input is finished
int callback(void *NotUsed, int argc, char **argv, char **azColName)    //callback returns the output of sql query and it is fed directly yyscanstring
{
	char *str2 = argv[1];
    std::cout<<"\nFORMULA SCANNED IS \n"<<str2<<"\n";
    YY_BUFFER_STATE buffer = yy_scan_string(str2);
    int check= yyparse();               //if yyparse returns 0, pass the string to swapper function in ss.y file
    if(!check)
    {
        swapper(str2);
    }
    yy_delete_buffer(buffer);
    std::cout <<"\n";
    return 0;
}
int main ()
{
std::cout<<"Hello!\n";
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    std::string sql;
    rc = sqlite3_open("mydb.db", &db);          //connection to db set, which is a file in same folder
    
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        return(1);
    }

char x;
std::cout<<"\nENTER A FORMULA ID (1-4): ";
std::cin>>x;
    sql = "SELECT * FROM 'FORMULAE' where id = ";
    sql.push_back(x);
    sql.push_back(';');
    rc = sqlite3_exec(db, sql.c_str(), callback, 0, &zErrMsg);
    sqlite3_close(db);
    return 0;
}

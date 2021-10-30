%{
#include<iostream>
#include <string>
#include "ss.tab.h"
#include "sqlite3.h"
extern int yylex ();
void yyerror ( std::string);
void swapper(char*);
void replace(char*);
std::string arr[10];        //the string array that holds the variable token's replacement in order to which they occur in formula
int count = 0;              //count keeps the count of number of variables passed
%}
%union {
char char_val;
double double_val;
char* str_val;
}
%token < char_val > OP LPAREN RPAREN
%token < str_val > VARIABLE
%token < double_val > NUMBER
%start root

        //cfg is ambiguous, so it is returning a sr confilict, I tried to remove it unsuccessfully.
%%
root:       top_level  {std::cout<<"\ncorrect expression\n";};
top_level:  expression
expression: expression OP expression
            | LPAREN expression RPAREN
            | VARIABLE    {
                            replace($1);    //as soon as a variable is encountered, it is passed to a replace function, which saves
                                            //the corresponding value of the variable picked up from table fields into arr
                                }
            |NUMBER;
%%
void yyerror ( std::string str )
{
    std::cout<<str;
}
int callback1(void *NotUsed, int argc, char **argv, char **azColName)
{
    arr[count] = std::string(argv[2]);         //save the corresponding values into arr and increase counter
    count++;
    return 0;
}
int callback2(void *NotUsed, int argc, char **argv, char **azColName)       //function for normal ouptput from sqlite
{
    std::cout<<"\n\t"<<argv[0];
    return 0;
}
void replace(char* x)           //replace function gets the values of tokens and calls the sql table fields
{
    std::string st(x);
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    std::string sql;
    rc = sqlite3_open("mydb.db", &db);
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        exit(0);
    }
    sql = "SELECT * FROM 'fields' where val = \"" + st + "\";";
    rc = sqlite3_exec(db, sql.c_str(), callback1, 0, &zErrMsg);
    sqlite3_close(db);
}
void swapper(char* formula)         //swapper gets the correct formulas and replaces the variable tokens in it
{
    int j=0;
    std::string finalstr = "SELECT ";
    std::cout<<"\n\nFORMULA PARSED CORRECTLY, THE FORMULA IS : ";
    std::cout<<formula<<"\n\n";
    for(int i=0;formula[i]!='\0';i++)       //loop reads the formula, as soon as a variable is found, the final string named finalstr
    {                                       //adds the fieldname stored in arr in order, else it saves whatever is in formula
        if(formula[i]=='<')
        {
            finalstr = finalstr + arr[j];
            j++;
            while(formula[i]!='>')
                i++;
        }
        else
            finalstr += formula[i];
    }
    std::cout<<"\nENTER A SALARY ID (1-3) : ";      //salary table has multiple values
    char sal;
    std::cin>>sal;
    finalstr += " FROM SALARY WHERE ID=";           //complete the query
    finalstr.push_back(sal);
    finalstr.push_back(';');
    std::cout<<"\n\nFORMULA IS REFACTORED, THE FINAL QUERY IS : ";     //call for the final output
    std::cout<<finalstr;
    std::cout<<"\n\n THE QUERY RESULT IS : \n";
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    rc = sqlite3_open("mydb.db", &db);
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        exit(0);
    }
    rc = sqlite3_exec(db, finalstr.c_str(), callback2, 0, &zErrMsg);
    sqlite3_close(db);
}
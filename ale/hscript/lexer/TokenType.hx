package ale.hscript.lexer;

enum TokenType
{
    TBool(value:Bool);
    TValue(value:Float);
    TString(value:String);
    TIdent(value:String);
    
    // Symbols

    TEqual;

    TColon;
    TSemiColon;

    // Keywords

    TFinal;
}
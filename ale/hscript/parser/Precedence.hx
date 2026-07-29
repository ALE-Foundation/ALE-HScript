package ale.hscript.parser;

enum abstract Precedence(Int) from Int to Int
{
    var NONE = 0;
    var ASSIGNMENT = 1;
    var TERNARY = 2;
    var OR = 3;
    var AND = 4;
    var BIT_OR = 5;
    var BIT_XOR = 6;
    var BIT_AND = 7;
    var EQUALITY = 8;
    var COMPARISON = 9;
    var SHIFT = 10;
    var TERM = 11;
    var FACTOR = 12;
    var UNARY = 13;
    var CALL = 14;
    var MEMBER = 15;
}
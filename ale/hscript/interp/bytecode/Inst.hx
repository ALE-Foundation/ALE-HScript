package ale.hscript.interp.bytecode;

enum abstract Inst(Int) from Int to Int
{
    var CONST;

    var SET_VAR;

    var GET_VAR;

    var CALL;
}
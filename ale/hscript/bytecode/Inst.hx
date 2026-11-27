package ale.hscript.bytecode;

enum abstract Inst(Int) from Int to Int
{
    var IConstant;

    var IVarDecl;
    var IFunctionDecl;

    var IVar;
    var ICall;
}
package ale.hscript.bytecode;

enum abstract Inst(Null<Int>) from Null<Int> to Null<Int>
{
    var IPush;
    var IJump;

    var IEnterScope;
    var IExitScope;

    var IVarDecl;
    var IFunctionDecl;

    var IAlias;

    var IVar;
    var IField;
    var IType;
    var IArrayAccess;

    var ICall;
    var INew;

    var IFunction;

    var IInterpolatedString;

    var IArray;
    var IMap;
    var IStructure;

    var IAssign;
    var IFieldAssign;
    var IArrayAssign;

    var IReturn;

    var ICast;

    var IPackage;
    var IImport;
    var IPackageImport;
    var IUsing;
}
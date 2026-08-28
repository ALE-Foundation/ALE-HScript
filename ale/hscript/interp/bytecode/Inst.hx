package ale.hscript.interp.bytecode;

enum abstract Inst(Null<Int>) from Null<Int> to Null<Int>
{
    var IVarDecl;
    var IFunctionDecl;

    var ITypedef;
    var IAlias;


    var IVar;
    var IField;
    var IType;

    var IArrayAccess;

    
    var ICall;
    var INew;


    var IFunction;
    var IBlock;

    
    var IInterpolatedString;


    var IArray;
    var IArrayComprehension;
    var IMap;
    var IStructure;

    
    var IAssign;

    
    var IBinOp;
    var IPrefix;
    var IPostfix;
    var ITernOp;


    var IIf;
    
    var IWhile;
    var IDoWhile;

    var IFor;

    var ISwitch;
    
    var ITry;


    var IReturn;
    var IThrow;

    var IContinue;
    var IBreak;


    var ICast;


    var IPackage;

    var IImport;
    var IPackageImport;

    var IUsing;


    var IMetadata;
    
    var IEof;


    var IPush;
}
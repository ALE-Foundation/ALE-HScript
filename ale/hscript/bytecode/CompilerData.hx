package ale.hscript.bytecode;

typedef CompilerData = {
    instructions:Array<Int>,
    constants:Array<Dynamic>,
    posInfos:Array<{line:Int, column:Int}>
};
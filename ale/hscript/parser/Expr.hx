package ale.hscript.parser;

import ale.hscript.utils.ScriptPos;

typedef Expr = {
    ?type:ExprType,
    pos:ScriptPos
}
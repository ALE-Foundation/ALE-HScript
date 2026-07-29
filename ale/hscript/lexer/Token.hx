package ale.hscript.lexer;

import ale.hscript.utils.ScriptPos;

typedef Token = {
    ?type:TokenType,
    pos:ScriptPos
}
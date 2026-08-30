package ale.hscript.bytecode;

import ale.hscript.interp.Scope;

typedef CallFrame = {
    ip:Int,
    scope:Scope
}
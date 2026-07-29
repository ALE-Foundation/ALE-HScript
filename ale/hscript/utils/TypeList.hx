package ale.hscript.utils;

import ale.hscript.macros.TypeListMacro;

@:build(ale.hscript.macros.TypeListMacro.build())
class TypeList
{
    public static var list(get, never):Map<String, Array<String>>;
    static function get_list():Map<String, Array<String>>
        return TypeListMacro.list;
}
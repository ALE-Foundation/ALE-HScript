package ale.hscript.interp;

interface IExtensible
{
    final _ALE_HScript_Scripted:ScriptedInstance;
    final _ALE_HScript_Fields:Array<String>;

    function _ALE_HSCRIPT_ResolveField(id:String):Dynamic;
    function _ALE_HSCRIPT_SetField(id:String, value:Dynamic):Dynamic;
}
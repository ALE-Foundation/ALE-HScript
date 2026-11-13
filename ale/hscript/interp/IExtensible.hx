package ale.hscript.interp;

interface IExtensible
{
    final _ALE_HSCRIPT_AccessorsBypass:Map<String, Bool>;
    final _ALE_HScript_Scripted:ScriptedInstance;
    final _ALE_HScript_Fields:Map<String, Bool>;

    function _ALE_HSCRIPT_ResolveField(id:String):Dynamic;
    function _ALE_HSCRIPT_SetField(id:String, value:Dynamic):Dynamic;
}
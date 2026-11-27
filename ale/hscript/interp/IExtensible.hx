package ale.hscript.interp;

#if (ALE_HS_CLASSES == 'true')
interface IExtensible
{
    final _ALE_HSCRIPT_AccessorsBypass:Map<String, Bool>;
    final _ALE_HScript_Fields:Map<String, Bool>;
    var _ALE_HScript_Scripted:ScriptedInstance;

    function _ALE_HSCRIPT_ResolveField(id:String):Dynamic;
    function _ALE_HSCRIPT_SetField(id:String, value:Dynamic):Dynamic;
}
#end
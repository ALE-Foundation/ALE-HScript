package ale.hscript.module;

#if (ALE_HS_MODULES == 'true')
typedef ModuleCache = {
    path:String,
    module:Array<ModuleType>,
    time:Float
}
#end
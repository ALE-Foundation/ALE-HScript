package;

class BaseBase
{
    public function osoFunc():String
    {
        trace('donde');

        return 'oso';
    }
}


class Base extends BaseBase
{
    public function new(arg:String = 'donde', ?tengo:Dynamic, ?hambre:Dynamic)
        trace(arg);
}

@:build(ale.hscript.macros.ExtensibleMacro.build())
class ExtensibleTest extends Base
{
    var oso:String = 'tu ta';
}
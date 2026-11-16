package;

class Module
{
    static var oso(default, set):String = 'oso';
    static function set_oso(val:String):String
    {
        trace('oso reassign');

        return oso = val;
    }

    static function traceOso()
        trace(oso);

    public function new()
        traceOso();
}
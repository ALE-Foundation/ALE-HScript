class Peru
{
    var oso(default, set):String = 'donde';
    function set_oso(val:String):String
        return oso = val;

    var arg0(default, set):Dynamic;
    function set_arg0(val:Dynamic):Dynamic
    {
        trace('arg0 assign');

        return arg0 = val;
    }

    public function new(arg0, arg1)
    {
        this.arg0 = arg0;

        method();
    }

    function method()
        trace('methodoso');
}

class Peruano extends Peru
{
    override function method()
    {
        trace('methodoso override');

        super.method();
    }

    override function set_oso(val:String):String
    {
        trace('succ override');

        return oso = val;
    }
}

class Ch3erea extends Peruano {}

final peru = new Ch3erea('oso', 'donde');
peru.oso = 67;

trace(peru.toString());
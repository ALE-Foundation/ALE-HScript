class Peru
{
    var oso(default, set):String = 'donde';
    function set_oso(val:String):String
        return oso = val;

    public function new(arg0, arg1)
    {
        trace(arg0, arg1);

        method();
    }
}

class Peruano extends Peru
{
    override function method()
        trace('donde');

    override function set_oso(val:String):String
    {
        trace('succ override');

        return oso = val;
    }
}

class Ch3erea extends Peruano {}

final peru = new Ch3erea('oso', 'donde');
peru.oso = 67;
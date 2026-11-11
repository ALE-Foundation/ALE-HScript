class Peru
{
    public var oso(get, never):String = 'donde';
    function get_oso():String
    {
        trace('donde');

        return oso;
    }

    public function new(arg0, arg1)
    {
        trace(arg0, arg1);
    }

    public function donde()
        return 67;
}

class Peruano extends Peru
{
    function get_oso():String
    {
        trace('tuta');

        return oso;
    }
}

final peru = new Peruano('oso', 'donde');

trace(peru.oso);
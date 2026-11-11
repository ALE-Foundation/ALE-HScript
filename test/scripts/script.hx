class Peru
{
    var oso:String = 'donde';

    public function new(arg0, arg1)
    {
        trace(arg0, arg1);

        method();
    }

    public function method()
        trace('oso');
}

class Peruano extends Peru
{
    override function method()
        trace('donde');
}

final peru = new Peruano('oso', 'donde');
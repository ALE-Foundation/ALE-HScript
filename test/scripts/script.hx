import Test;

class Oso extends Test
{
    public function new(arg)
    {
        trace(arg);

        super('osoooo');
    }

    override function method()
        trace('oso');
}

final osoInstance = new Oso('donde');
osoInstance.method();
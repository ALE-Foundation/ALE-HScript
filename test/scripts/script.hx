import Test;

class Oso extends Test
{
    public function new(arg)
    {
        trace(arg);

        super('osoooo');
        
        trace(oso);

        oso = 'tengo hambre oso';

        trace(oso);
    }

    override function method()
        trace('oso');
}

final osoInstance = new Oso('donde');
osoInstance.method();
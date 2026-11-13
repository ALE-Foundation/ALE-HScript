import Test;

class Oso extends Test
{
    override function method()
    {
        trace('pre');

        super.method();

        trace('post');
    }
}

final osoInstance = new Oso('donde');
osoInstance.method();
class Oso extends ExtensibleTest
{
    override function osoFunc():String
    {
        trace('donde');
    }
}

final oso = new Oso('tengo hambre');

trace(oso.oso);

oso.osoFunc();
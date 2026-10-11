class ExtensibleTest
{
    public function new() {}

    var oso:String = 'oso';
}

class Oso extends ExtensibleTest
{
    function osoFunc():String
    {
        trace('donde');
    }
}

final oso = new Oso('tengo hambre');

trace(oso.oso);

oso.osoFunc();
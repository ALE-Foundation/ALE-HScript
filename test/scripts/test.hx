import Main;

class Oso extends ExtensibleTest
{
    override function new(arg:String)
    {
        trace('en');

        super(arg, 'radio', 'hay');

        trace('un pollito');
    }

    override function osoFunc(arg:String):String
    {
        return 'ayayayay me pica el pene me pica el pene';
    }
}

final oso = new Oso();

trace(oso);
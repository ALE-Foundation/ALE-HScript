class Oso extends ExtensibleTest
{
    override function new(arg:String)
    {
        trace('en');

        super(arg, 'radio', 'hay');

        trace('un pollito');
    }
}

final oso = new Oso('la');
class Oso
{
    var oso:String = 'MASHA';

    function new(?arg:String)
        if (arg != null)
            oso = arg;
}

final instance0 = new Oso('oso');
final instance1 = new Oso('donde');

trace(instance0.oso);
trace(instance1.oso);

/*
class Masha extends Oso
{
    function new()
    {
        super('masha');
    }
}

final instance2 = new Masha('tu');
final instance3 = new Masha();
trace(instance2.oso);
trace(instance3.oso);
*/
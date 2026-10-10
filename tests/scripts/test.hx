
/*
interface IOso
{
    var tung:String;

    public function oso():Void;
}
*/

class Oso
{
    var tung:String = 'donde';

    public function new()
        trace('oso');

    public function oso()
        trace('donde');
}

class Donde extends Oso
{
    override function oso()
        trace('tu');
}

class Ta extends Donde
{
    public function new()
    {
        super();
    }
}

final oso = new Ta();

trace(oso.tung);

oso.oso();
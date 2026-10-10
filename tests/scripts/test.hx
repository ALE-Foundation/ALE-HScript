interface IBaseOso
{
    var tung:String;
}

interface IOso extends IBaseOso
{
    public function oso():Void;
}

class Oso
{
    var tung:String = '67';

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

class Ta extends Donde implements IOso
{
    public function new()
    {
        super();
    }
}

final oso = new Ta();

trace(oso.tung);

oso.oso();
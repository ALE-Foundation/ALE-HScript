class Oso
{
    var tung:String = 'donde';

    public function new()
        trace('oso');
}

class Donde extends Oso {}

class Ta extends Donde
{
    public function new()
        super();
}

final oso = new Ta();

trace(oso.tung);
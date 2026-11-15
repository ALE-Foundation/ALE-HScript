package pack;

class Oso
{
    function osoMethod()
    {
        trace(donde);
    }

    public function new()
    {
        osoMethod();

        trace('ese peluche puede hablar');
    }
}

class Donde extends Oso
{
    override function osoMethod()
    {
        return 'donde';
    }
}
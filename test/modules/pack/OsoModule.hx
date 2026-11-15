package pack;

class Oso
{
    public function new()
        trace('ese peluche puede hablar');
}

class Donde extends Oso
{
    public function osoMethod()
        return 'donde';
}
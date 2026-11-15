import pack.OsoModule;

class Masha
{
    public function new() 
    {
        trace('oso');
    }

    function superMethod()
        return 'donde';
}

class Matrioshka extends Masha
{
    public function new()
    {
        super();

        super.superMethod();
    }
}

final a = new Oso();

final b = new Donde();
trace(b.osoMethod());
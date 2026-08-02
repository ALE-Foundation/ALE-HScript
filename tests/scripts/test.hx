// Types

// - Basic Types

var oso:Date = Type.createInstance(StringBuf, []);
oso.add('oso');

// - - Bool

trace(true);
trace(false);

// - - Int

trace(1);
trace(0);
// trace(-1);
// trace(0xFF0000);

// - - Float

trace(1.0);
trace(0.0);
// trace(-1.0);
// trace(1e10);

// - Function Type

function coolPrint(i:Int, ?s:String = 'sahur'):String
{
    trace('Cool Print', i, s);

    return 'oso donde tu ta oso';
}

trace(coolPrint(1));

var funnyFunc = function(oso:Dynamic):String return oso();

trace(funnyFunc((?oso:String) -> 'tung'));

trace(funnyFunc(function():String return 'sahur'));

// Type System

// - Untyped

untyped final oso = 'oso';

trace(oso);

// Class Fields

// - Variable

var oso:String = 'tung';

{ var oso:String = 'sahur'; }

trace(oso);

// - Property

var oso(get, set):String = 'messi tomate una pepsi';

function get_oso():String
{
    trace('cool getter', oso);

    return oso;
}

function set_oso(value:String):String
{
    trace('cool setter', value);

    return oso = value;
}

oso = 'donde';

trace(oso);
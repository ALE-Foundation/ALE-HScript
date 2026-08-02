final CATEGORY_TRACE:String -> Void = (str:String) -> {
    trace('');
    trace(str);
    trace('');
};

CATEGORY_TRACE('Types');

CATEGORY_TRACE('- Basic Types');

var oso:Date = Type.createInstance(StringBuf, []);
oso.add('oso');

trace(oso);

CATEGORY_TRACE('- - Bool');

trace(true);
trace(false);

CATEGORY_TRACE('- - Int');

trace(1);
trace(0);
// trace(-1);
// trace(0xFF0000);

CATEGORY_TRACE('- - Float');

trace(1.0);
trace(0.0);
// trace(-1.0);
// trace(1e10);

CATEGORY_TRACE('- - Function Type');

function coolPrint(i:Int, ?s:String = 'sahur'):String
{
    trace('Cool Print', i, s);

    return 'oso donde tu ta oso';
}

trace(coolPrint(1));

var funnyFunc = function(oso:Dynamic):String return oso();

trace(funnyFunc((?oso:String) -> 'tung'));

trace(funnyFunc(function():String return 'sahur'));

CATEGORY_TRACE('Type System');

CATEGORY_TRACE('- Untyped');

untyped final oso = 'oso';

trace(oso);

CATEGORY_TRACE('Class Fields');

CATEGORY_TRACE('- Variable');

var oso:String = 'tung';

{ var oso:String = 'sahur'; }

trace(oso);

CATEGORY_TRACE('- Property');

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

CATEGORY_TRACE('- Method');

function dameElOso():String
    return 'oso';

trace(dameElOso());
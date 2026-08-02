final ____CT:String -> Void = (str:String) -> {
    trace('');
    trace(str);
    trace('');
};

____CT('Expressions');

____CT('- Blocks');

{
    var oso:String = 'oso';

    oso = 'donde';

    trace(oso.length);
}

try
{
    final oso:String = 'oso';

    oso = 'donde';
} catch(e:Dynamic) {
    trace(e);
}
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

____CT('- Literals');

____CT('- - Int');

trace(42);
trace(0xFF42);

____CT('- - Float');

trace(0.32);
trace(3.);
trace(1e5);
trace(2.1e5);
trace(6E10);
trace(1.5e-3);
trace(8e+7);

____CT('- - Bool');

trace(false);
trace(true);

____CT('- - EReg');

// trace(~/haxe/gi);

____CT('- - Null');

trace(null);

____CT('- - String');

trace("XXX");
trace('XXX');
trace("X".code);
trace('x'.code);

____CT('- - Array');

trace([1, 2, 3]);
trace([]);

____CT('- - Map');

trace([
    'a' => 1,
    'b' => 2
]);
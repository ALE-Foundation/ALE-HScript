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
trace([0, 1, 2][2]);

____CT('- - Map');

trace([
    'a' => 1,
    'b' => 2,
    'tung' => 3
]);

trace([
    'a' => 1,
    'b' => 2,
    'tung' => 'sahur'
]['tung']);

____CT('- - Anonymous Structure');

trace({
    foo: true,
    oso: 'donde tu ta oso',
    donde: {
        tu: 'ta'
    }
});

____CT('- - Operators');

____CT('- - - Unary');

trace(~10);
trace(!false);
trace(-20);

var oso:Int = 3;

trace(++oso);
trace(--oso);

trace(oso++);
trace(oso);

trace(oso--);
trace(oso);

____CT('- - - Binary');

trace(7 % 5);
trace(5 * 4);
trace(10 / 2);
trace(5 + 12);
trace(5 - 20);
trace('after all' + ' of the waster years');
trace(oso + ' tristes tigres');

trace(20 << 2);
trace(20 >> 2);
trace(10 >>> 2);
trace(12 & 10);
trace(12 | 10);
trace(12 ^ 10);

trace(true && false);
trace(false || true);

var osoVal:Float = 7;

trace(osoVal %= 5);
trace(osoVal *= 10);
trace(osoVal /= 5);
trace(osoVal += 6);
trace(osoVal -= 5);

var osoVal:Int = 10;

trace(osoVal <<= 2);
trace(osoVal >>= 2);
trace(osoVal >>>= 2);
trace(osoVal &= 2);
trace(osoVal |= 2);
trace(osoVal ^= 2);

trace(10 == 10);
trace(20 != 20);
trace(5 < 10);
trace(10 <= 10);
trace(5 > 10);
trace(5 >= 5);

trace(10...20);

trace((10 + 10) * 10);

____CT('- - - Ternary');

trace(true ? 10 : 20);
trace(false ? 10 : 20);

____CT('- new');

trace(new haxe.ds.StringMap<Dynamic>());

____CT('- for');

final map = [1 => 101, 'oso' => 102, 3 => 103];

for (key => value in map)
    trace(key, value);
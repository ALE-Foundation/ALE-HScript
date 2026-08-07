package;

import haxe.ds.*;

final ____CT:String -> Void = (str:String) -> {
    haxe.Log.trace('\n' + str + '\n', null);
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
trace(if (false) 10 else 20);

____CT('- Local Functions');

function oso(donde:String, ?tuta:Dynamic, ?oh:String = 'masha'):Null<Bool>
{
    trace(tuta ?? 'tuta');

    tuta ??= 'tuta';

    trace(donde, tuta, oh);

    return false;

    trace('tung tung tung');
}

oso('donde');
oso('donde', 'tuta dura sin ir al gym');

____CT('- new');

trace(new StringMap<Dynamic>());

____CT('- for');

for (i in 0...10)
    trace(i);

final map = [1 => 101, 'oso' => 102, 3 => 103];

for (key => value in map)
    trace(key, value);

____CT('- while');

var f:Float = 0;

while (f < 0.75)
    trace(f = Math.random());

____CT('- do while');

var i:Int = 0;

do {
    trace(++i);
} while (i < 3);

____CT('- if');

if (false)
    trace('false');
else if (true)
    trace('true');
else
    trace('tung');

____CT('- switch');

switch ('oso')
{
    case 'donde':
        trace('a');
    
    case 'tu':
        trace('b');

    case 'ta':
        trace('c');

    default:
        trace('d');
}

____CT('- throw');

try
{
    throw 'oso';
} catch(val:Dynamic) {
    trace(val);
}

____CT('- cast');

final oso:Dynamic = {
    donde: 'oso'
}

trace(cast oso.donde);

trace(cast('donde', String));

trace(('tu ta' : String));

____CT('Class Fields');

var oso(get, set):String = 'oso';

function get_oso():String
{
    trace(oso + ': sahur');

    return oso;
}

function set_oso(value:String):String
{
    trace('tung: ' + value);

    return oso = value;
}

oso = 'masha';

trace(oso);

____CT('Standard Library');

____CT('- String');

trace('messi');
trace('\ttomate');
trace('\nuna');
Sys.print("fanta\rpepsi\n");
trace("\"");
trace('\'');
trace('\\');
trace('\x41');
trace('\x61');
trace('\x7A');
trace('\u0041');
trace('\u00F1');
trace('\u03A9');
trace('\u{41}');
trace('\u{1F43B}');
trace('\u{10FFFF}');
trace('\101');
trace('\141');
trace('\040');
trace('Tung\nSahur');
trace('\toso\tdonde\ttuta');
trace('A\x42\u0043\u{44}\105');
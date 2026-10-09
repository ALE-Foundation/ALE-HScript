// EPackage

package haxe.io;

// EImport

import haxe.ds.StringMap as OsoMap;
import haxe.ds.IntMap;

// EPackageImport

import ale.hscript.*;

// EUsing

using StringTools;

// ETypedef

typedef Masha = {
    ?id:String,
    leche:Int
}

// EAlias

typedef Alias = Math;

trace(Alias.sin(10));

// EVarDecl

var oso:String = 'oso';

trace(oso);

// EFunctionDecl

function oso(a:String, b:String = 'oso', ?c:Int = 10)
    trace(a, b, c);

oso('a');
oso('a', 'b');
oso('a', null, 20);
oso('a', 'b', 20);

// EVar

var oso:String = 'masha';

trace(oso);

// EField

var oso:String = 'osooo';

trace(oso.length);

// EType

trace(haxe.ds.ObjectMap);

// EArrayAccess

trace('leche de oso'.split(' ')[2]);

// ECall

trace(Date.now());

// ENew

trace(new Date(2026, 11, 25, 0, 0, 0));

// EFunction

function oso(func:Void -> String)
{
    trace(func(), func, func());
}

oso(() -> 'donde');

// EBlock

var oso:Int = 10;

{
    trace(oso);

    var oso:Int = 25;

    trace(oso);
}

trace(oso);

// EString

trace('oso donde tu ta oso');

// EInterpolatedString

trace('en ${'la'} radio ${Math.sin(0.5)}');

// ENumber

trace(0xFF10);
trace(100.0);
trace(25.105);
trace(10e-5);
trace(10e5);

// EArray

trace([10, 20, 30, 40, 'ola']);

// EArrayComprehension

trace([for (i in 0...20) i]);

// EMap

trace([
    'el raton' => 'sni',
    'barbie' => 'oh',
    'el gorila' => 10,
    'el burro' => Date.now()
]);

// EStructure

trace({
    en: {
        hay: {
            un: {
                pollito: 'pio pio'
            }
        }
    },
    la: 'radio'
});

// ERegex

final mailReg:EReg = ~/^[\w.+-]+@[\w-]+\.[\w.-]+$/;

trace(mailReg.match('pollitoenlaradio@gmail.com'));
trace(mailReg.match('los@pollitos'));

trace("hola,123,mundo,456,Haxe,789".split(",").filter(s -> ~/^[0-9]+$/.match(s)));

// ETrue

trace(true);

// EFalse

trace(false);

// ENull

trace(null);

// EAssign

var oso:String = 'oso';

oso = 'donde';

trace(oso);


final masha:Array<String> = ['tengo', 'hambre', 'oso'];

masha[0] = 'quiero';
masha[1] = 'leche';

trace(masha);


final leche:Dynamic = {
    oh: {
        masha: {
            yo: 'te',
            puedo: 'da',
            leche: {}
        }
    }
};

leche.oh.masha.leche = 'tengo mucha leche para tí';

trace(leche);

// EBinOp

final oso:Int = 10;

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

trace(false || true);

function tung():Dynamic
{
    trace('masha');

    return 'oso';
}

trace(null ?? tung());
trace(10 ?? tung());

function tung():Bool
{
    trace('masha');

    return true;
}

trace(true || tung());
trace(false || tung());

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

// EPrefix

trace(~10);
trace(!false);
trace(-20);

var oso:Int = 3;

trace(++oso);
trace(--oso);

// EPostfix

trace(oso++);
trace(oso);

trace(oso--);
trace(oso);

// ETernOp

trace(20 >= 10 ? 10 : 20);
trace(if (false) 10 else 20);

// EIf

if ('oso' == 'oso')
    trace('oso');

if (10 + 10 >= 20)
    trace('donde');
else
    trace('tu ta');

// EWhile

var i:Int = 0;

while (i++ < 10)
    trace(i);

while (false)
    trace('oso');

// EDoWhile

do {
    trace(i);
} while (--i > 0);

do {
    trace('oso');
} while (false);

// EFor

for (i in 0...10)
    trace(i);

final arr = ['oso', 10, 20, 50];

for (i => val in arr)
    trace(i, val);

final map = [
    'en' => 10,
    'la' => 67,
    'radio' => [
        'hay un pollito' => 'pio pio'
    ]
];

for (key => val in map)
    trace(key, val);

// ESwitch

var oso:String = 'oso';

while (true)
{
    trace(oso);

    switch (oso)
    {
        case 'oso':
            oso = 'donde';

        case 'donde':
            oso = 'tu';

        case 'tu':
            oso = 'ta';

        case 'ta':
            break;
    }
}

// ETry

try
{
    final oso = 'oso';

    oso = 'donde';
} catch(e) {
    trace(e);
}

// EReturn

function oso(?arg:String):Void -> Void
{
    if (arg != null)
        throw 'MercadoLibre';

    return () -> trace('kumalala kumalala kumala sabesta');

    return () -> trace('oso');
}

oso()();

// EThrow

try
{
    oso('AY SI');
} catch(e) {
    trace(e);
}

// EContinue

var i:Int = 10;

while (i-- > 0)
{
    if (i == 6)
        continue;

    trace(i);
}

for (i in 0...10)
{
    if (i == 7)
        continue;

    trace(i);
}

do {
    if (i == 6)
        continue;

    trace(i);
} while(i++ < 10);

// EBreak

while (i-- > 10)
{
    trace(i);

    if (i == 6)
        break;
}

for (i in 0...67)
{
    trace(i);

    if (i == 6)
        break;
}

do {
    if (i == 6)
        break;

    trace(i);
} while(i++ < 10);

// ECast

final oso:String = cast 67;

trace(cast(67, Int));

// EMetadata

@:privateAccess trace('oso');
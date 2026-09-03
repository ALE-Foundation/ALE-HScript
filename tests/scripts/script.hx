
/*
// EPackage

package haxe.io;

// EImport

import haxe.ds.StringMap as OsoMap;
import haxe.ds.IntMap;

// EPackageImport

import ale.hscript.*;

// EUsing

using StringTools;

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


// ETypedef

typedef Masha = {
    ?id:String,
    leche:Int
}

// EAlias

typedef Alias = Math;

trace(Alias.sin(10));

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

// ECast

final oso:String = cast 67;

trace(cast(67, Int));

*/

// EBinOp

/*
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
*/

function oso()
{
    trace('donde');

    return true;
}

final oso = true && oso();

trace(oso);

// trace(false || true);

/*
function tung():Dynamic
{
    trace('osooo');

    return 'oso';
}

trace(null ?? tung());
trace(10 ?? tung());
*/
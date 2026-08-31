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
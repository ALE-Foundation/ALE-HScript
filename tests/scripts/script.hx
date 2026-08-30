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
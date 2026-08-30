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
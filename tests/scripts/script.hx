
function oso(txt:String)
{
    final val = new Oso('donde');

    return () -> {
        val.oso = txt;

        return val;
    };
}

trace(oso('donde')().oso);
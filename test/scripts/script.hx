class Oso extends Test
{
    override function set_oso(val:Dynamic):Dynamic
        return oso = val;

    override function get_oso():Dynamic
    {
        trace(oso);

        return oso;
    }
}

final oso = new Oso();
oso.oso = 67;

trace(oso.oso);
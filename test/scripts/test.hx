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

function tung()
{
    trace('sahur');

    return 67;
}

var osoVal:Null<Int> = null;

trace(osoVal ??= tung());

function tung()
    return 10;

trace(osoVal ??= tung());
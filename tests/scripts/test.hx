function myFunc(str:String = 'oso'):Dynamic
{
    trace(str);

    return str.length;
}

trace(myFunc('donde'));
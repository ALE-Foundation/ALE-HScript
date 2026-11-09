var i:Int = 0;

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
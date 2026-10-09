package ale.hscript.interp;

enum ControlSignal
{
    CBreak;
    CContinue;
    CReturn(value:Dynamic);
}
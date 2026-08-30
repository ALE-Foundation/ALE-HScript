package ale.hscript.serialization;

enum abstract ConstantType(Int) from Int to Int
{
    var CNull;
    var CBool;
    var CInt;
    var CFloat;
    var CString;
    var CProperty;
}
package ale.hscript.bytecode;

enum abstract Operator(Int) from Int to Int
{
    var OPlus;
    var OMinus;
    var OStar;
    var OSlash;
    var OPercent;

    var OEqual;
    var ODoubleEqual;
    var OExclamationEqual;

    var OGreater;
    var OLess;
    var OGreaterEqual;
    var OLessEqual;

    var OAmpersand;
    var ODoubleAmpersand;
    var OPipe;
    var ODoublePipe;
    var OCaret;
    var OTilde;
    var OExclamation;

    var ODoubleLess;
    var ODoubleGreater;
    var OTripleGreater;

    var OPlusEqual;
    var OMinusEqual;
    var OStarEqual;
    var OSlashEqual;
    var OPercentEqual;

    var OAmpersandEqual;
    var OPipeEqual;
    var OCaretEqual;

    var ODoubleLessEqual;
    var ODoubleGreaterEqual;
    var OTripleGreaterEqual;

    var ODoubleQuestionEqual;

    var ODoublePlus;
    var ODoubleMinus;
    var ODoubleQuestion;
    var OQuestionDot;

    var OArrow;
    var OFatArrow;

    var OQuestion;
    var OTripleDot;

    var OIs;
}
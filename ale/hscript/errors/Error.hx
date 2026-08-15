package ale.hscript.errors;

import ale.hscript.lexer.TokenType;

import haxe.Exception;

class Error extends Exception
{
    public final type:ErrorType;

    public final line:Int;
    public final column:Int;

    public function new(type:ErrorType, line:Int, column:Int)
    {
        super(format(type));

        this.type = type;

        this.line = line;
        this.column = column;
    }

    override function toString():String
        return '$line:$column: $message';

    static function format(type:ErrorType):String
        return switch (type)
        {
            case EInvalidCharacter(char):
                'Invalid character "${String.fromCharCode(char)}"';

            case EInvalidEscape(char):
                'Invalid escape: "\\${String.fromCharCode(char)}"';

            case EUnterminatedString:
                'Unterminated string';

            case EUnterminatedComment:
                'Unterminated comment';

            case EInvalidNumber:
                'Invalid number';

            case EExpected(want, got):
                'Expected ${formatToken(want)}, got ${formatToken(got)}';

            case EUnexpected(got):
                'Unexpected ${formatToken(got)}';

            case ETypeNotFound(module):
                'Type "$module" not found';

            case EInvalidArrayAccess(type):
                'Array access is not allowed on $type';

            case EInvalidAssignment:
                'Invalid assignment';

            case EInvalidCast:
                'Invalid cast';

            case EFinalAssign(id):
                'Cannot assign final variable "$id"';

            case ENeverWrite(id):
                'Variable "$id" cannot be accessed for writing';

            case ENeverRead(id):
                'Variable "$id" cannot be accessed for reading';

            case EUnknownVariable(id):
                'Unknown variable "$id"';

            case EInvalidOp(op):
                'Invalid operation "$op"';

            case EInvalidExpression(expr):
                'Invalid expression $expr';

            default:
                Std.string(type);
        }

    static function formatToken(type:TokenType):String
        return switch (type)
        {
            case TNumber(val):
                Std.string(val);

            case TString(str):
                str ?? 'STRING';

            case TIdent(id):
                id ?? 'IDENT';

            case TPlus:
                '+';

            case TMinus:
                '-';

            case TStar:
                '*';

            case TSlash:
                '/';

            case TPercent:
                '%';

            case TEqual:
                '=';

            case TDoubleEqual:
                '==';

            case TExclamationEqual:
                '!=';

            case TGreater:
                '>';

            case TLess:
                '<';

            case TGreaterEqual:
                '>=';

            case TLessEqual:
                '<=';

            case TAmpersand:
                '&';

            case TDoubleAmpersand:
                '&&';

            case TPipe:
                '|';

            case TDoublePipe:
                '||';

            case TCaret:
                '^';

            case TTilde:
                '~';

            case TExclamation:
                '!';

            case TDoubleLess:
                '<<';

            case TDoubleGreater:
                '>>';

            case TTripleGreater:
                '>>>';

            case TPlusEqual:
                '+=';

            case TMinusEqual:
                '-=';

            case TStarEqual:
                '*=';

            case TSlashEqual:
                '/=';

            case TPercentEqual:
                '%=';

            case TAmpersandEqual:
                '&=';

            case TPipeEqual:
                '|=';

            case TCaretEqual:
                '^=';

            case TDoubleLessEqual:
                '<<=';

            case TDoubleGreaterEqual:
                '>>=';

            case TTripleGreaterEqual:
                '>>>=';

            case TDoubleQuestionEqual:
                '??=';

            case TDoublePlus:
                '++';

            case TDoubleMinus:
                '--';

            case TDoubleQuestion:
                '??';

            case TQuestionDot:
                '?.';

            case TArrow:
                '->';

            case TFatArrow:
                '=>';

            case TLParen:
                '(';

            case TRParen:
                ')';

            case TLBrace:
                '{';

            case TRBrace:
                '}';

            case TLBracket:
                '[';

            case TRBracket:
                ']';

            case TDot:
                '.';

            case TComma:
                ',';

            case TColon:
                ':';

            case TSemicolon:
                ';';

            case TQuestion:
                '?';

            case TTripleDot:
                '...';

            case TAt:
                '@';

            case TDollar:
                '$';

            case TEof:
                '<EOF>';

            case TAbstract:
                'abstract';

            case TBreak:
                'break';

            case TCase:
                'case';

            case TCast:
                'cast';

            case TCatch:
                'catch';

            case TClass:
                'class';

            case TContinue:
                'continue';

            case TDo:
                'do';

            case TDynamic:
                'dynamic';

            case TElse:
                'else';

            case TEnum:
                'enum';

            case TExtends:
                'extends';

            case TExtern:
                'extern';

            case TFalse:
                'false';

            case TFinal:
                'final';

            case TFor:
                'for';

            case TFunction:
                'function';

            case TIf:
                'if';

            case TImplements:
                'implements';

            case TImport:
                'import';

            case TIn:
                'in';

            case TInline:
                'inline';

            case TInterface:
                'interface';

            case TMacro:
                'macro';

            case TNew:
                'new';

            case TNull:
                'null';

            case TOperator:
                'operator';

            case TOverload:
                'overload';

            case TOverride:
                'override';

            case TPackage:
                'package';

            case TPrivate:
                'private';

            case TPublic:
                'public';

            case TReturn:
                'return';

            case TStatic:
                'static';

            case TSwitch:
                'switch';

            case TThis:
                'this';

            case TThrow:
                'throw';

            case TTrue:
                'true';

            case TTry:
                'try';

            case TTypedef:
                'typedef';

            case TUntyped:
                'untyped';

            case TUsing:
                'using';

            case TVar:
                'var';

            case TWhile:
                'while';

            default:
                Std.string(type);
        }
}
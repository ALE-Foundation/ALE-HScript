package ale.hscript.utils;

import ale.hscript.serialization.Unserializer;

import ale.hscript.bytecode.Operator;

import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import ale.hscript.parser.ExprType;
import ale.hscript.parser.Expr;

import ale.hscript.Config;

@:publicFields
class Util
{
    static function resolveSourceData(script:String, ?name:String):SourceData
    {
        final basePath:String = Config.SCRIPT_PATH + script;

        final path:String = basePath + Config.EXTENSION;
        final compiledPath:String = basePath + Config.COMPILED_EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        final baseName:String = name ?? (isFile ? script : Config.SCRIPT_NAME);

        return {
            source: isFile ? Config.CONTENT_READER(path) : script,
            code: Config.FILE_CHECKER(compiledPath) ? new Unserializer(script).unserialize() : null,
            name: baseName + Config.EXTENSION,
            compiledPath: Config.SCRIPT_PATH + (isFile ? script : name ?? Config.SCRIPT_NAME) + Config.COMPILED_EXTENSION
        };
    }


    static final stringToTokenType:Map<String, TokenType> = [
        'abstract' => TAbstract,
        'as' => TAs,
        'break' => TBreak,
        'case' => TCase,
        'cast' => TCast,
        'catch' => TCatch,
        'class' => TClass,
        'continue' => TContinue,
        'do' => TDo,
        'dynamic' => TDynamic,
        'else' => TElse,
        'enum' => TEnum,
        'extends' => TExtends,
        'extern' => TExtern,
        'false' => TFalse,
        'final' => TFinal,
        'for' => TFor,
        'function' => TFunction,
        'if' => TIf,
        'implements' => TImplements,
        'import' => TImport,
        'in' => TIn,
        'is' => TIs,
        'inline' => TInline,
        'interface' => TInterface,
        'macro' => TMacro,
        'new' => TNew,
        'null' => TNull,
        'operator' => TOperator,
        'overload' => TOverload,
        'override' => TOverride,
        'package' => TPackage,
        'private' => TPrivate,
        'public' => TPublic,
        'return' => TReturn,
        'static' => TStatic,
        'switch' => TSwitch,
        'this' => TThis,
        'throw' => TThrow,
        'true' => TTrue,
        'try' => TTry,
        'typedef' => TTypedef,
        'untyped' => TUntyped,
        'using' => TUsing,
        'var' => TVar,
        'while' => TWhile
    ];

    static function tokensToTokenTypes(tokens:Array<Token>):Array<TokenType>
        return tokens.map(token -> token.type);
    
    static function tokenTypeToOperator(type:TokenType):Null<Operator>
        return switch (type)
        {
            case TPlus:
                OPlus;

            case TMinus:
                OMinus;

            case TStar:
                OStar;

            case TSlash:
                OSlash;

            case TPercent:
                OPercent;


            case TEqual:
                OEqual;

            case TDoubleEqual:
                ODoubleEqual;

            case TExclamationEqual:
                OExclamationEqual;


            case TGreater:
                OGreater;

            case TLess:
                OLess;

            case TGreaterEqual:
                OGreaterEqual;

            case TLessEqual:
                OLessEqual;


            case TAmpersand:
                OAmpersand;

            case TDoubleAmpersand:
                ODoubleAmpersand;

            case TPipe:
                OPipe;

            case TDoublePipe:
                ODoublePipe;

            case TCaret:
                OCaret;

            case TTilde:
                OTilde;

            case TExclamation:
                OExclamation;


            case TDoubleLess:
                ODoubleLess;

            case TDoubleGreater:
                ODoubleGreater;

            case TTripleGreater:
                OTripleGreater;


            case TPlusEqual:
                OPlusEqual;

            case TMinusEqual:
                OMinusEqual;

            case TStarEqual:
                OStarEqual;

            case TSlashEqual:
                OSlashEqual;

            case TPercentEqual:
                OPercentEqual;


            case TAmpersandEqual:
                OAmpersandEqual;

            case TPipeEqual:
                OPipeEqual;

            case TCaretEqual:
                OCaretEqual;


            case TDoubleLessEqual:
                ODoubleLessEqual;

            case TDoubleGreaterEqual:
                ODoubleGreaterEqual;

            case TTripleGreaterEqual:
                OTripleGreaterEqual;

            case TDoubleQuestionEqual:
                ODoubleQuestionEqual;


            case TDoublePlus:
                ODoublePlus;

            case TDoubleMinus:
                ODoubleMinus;

            case TDoubleQuestion:
                ODoubleQuestion;

            case TQuestionDot:
                OQuestionDot;


            case TArrow:
                OArrow;

            case TFatArrow:
                OFatArrow;


            case TQuestion:
                OQuestion;

            case TTripleDot:
                OTripleDot;


            case TIs:
                OIs;


            default:
                null;
        };


    static function exprsToExprTypes(exprs:Array<Expr>):Array<ExprType>
        return exprs.map(expr -> expr.type);
}
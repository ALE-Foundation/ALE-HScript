package ale.hscript.utils;

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
        'super' => TSuper,
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


    static function exprsToExprTypes(exprs:Array<Expr>):Array<ExprType>
        return exprs.map(expr -> expr.type);
}
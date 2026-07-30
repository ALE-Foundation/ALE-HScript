package ale.hscript.parser;

@:publicFields
class ExprUtil
{
    static function exprsToExprTypes(exprs:Array<Expr>):Array<ExprType>
        return exprs.map(expr -> expr.type);
}
package ale.hscript.interp;

class ConstructorData<T>
{
    final interp:Interp<T>;

    final pre:T;
    final superArgs:Array<T>;
    final post:T;

    final funcArgs:Array<ConstructorArgument<T>>;

    public function new(interp:Interp<T>, pre:T, superArgs:Array<T>, post:T, funcArgs:Array<ConstructorArgument<T>>)
    {
        this.interp = interp;

        this.pre = pre;
        this.superArgs = superArgs;
        this.post = post;

        this.funcArgs = funcArgs;
    }

    var oldScope:Scope<T>;
    
    public function initScope(newArgs:Array<Dynamic>)
    {
        oldScope = interp.scope;

        interp.scope = new Scope<T>(interp.scope);

        for (i => arg in funcArgs)
            interp.scope.define(arg.id, newArgs[i] ?? interp.eval(arg.value));
    }

    public function initPre()
        interp.eval(pre);

    public function getSuperArgs():Array<Dynamic>
        return [for (arg in superArgs) interp.eval(arg)];

    public function initPost()
        interp.eval(post);

    public function destroyScope()
        interp.scope = oldScope;
}
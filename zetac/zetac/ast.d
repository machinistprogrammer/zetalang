module zetac.ast;

public import zetac.lexer : TokenType;

interface ASTVisitor
{
    void visit(ASTDef that);
    void visit(ASTFunction that);
    void visit(ASTClass that);
    void visit(ASTInterface that);
    void visit(ASTIf that);
    void visit(ASTSwitch that);
    void visit(ASTCase that);
    void visit(ASTWhile that);
    void visit(ASTDo that);
    void visit(ASTFor that);
    void visit(ASTForeach that);
    void visit(ASTBreak that);
    void visit(ASTContinue that);
    void visit(ASTReturn that);
    void visit(ASTUnary that);
    void visit(ASTBinary that);
    void visit(ASTTinary that);
    void visit(ASTCall that);
    void visit(ASTIndex that);
    void visit(ASTAssign that);
    void visit(ASTNew that);
    void visit(ASTCast that);
    void visit(ASTStringLiteral that);
    void visit(ASTCharecterLiteral that);
    void visit(ASTFloatLiteral that);
    void visit(ASTIntegerLiteral that);
    void visit(ASTArrayLiteral that);
}

class ASTModule : ASTDecl
{
    ASTDecl[] block;

    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTImport : ASTDecl
{
    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTAlias : ASTDef
{
	ASTNode symbol;

	mixin ASTDeclCtor;
	mixin ASTAccepter;
}

class ASTDef : ASTDecl
{
    ASTNode exp;

    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTFunction : ASTDecl
{
    ASTDef[] parameters;
    ASTNode[] block;

    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTClass : ASTDecl
{
    ASTNode[] inherits;
    ASTDecl[] block;

    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTInterface : ASTDecl
{
    ASTNode[] inherits;
    ASTDecl[] block;

    mixin ASTDeclCtor;
    mixin ASTAccepter;
}

class ASTIf : ASTNode
{
    ASTNode testExp;
    ASTNode[] ifBlock, elseBlock;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTSwitch : ASTNode
{
    ASTNode testExp;
    ASTCase[] block;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTCase : ASTNode
{
    ASTNode testExp;
    ASTNode[] block;
    bool isElseCase;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTWhile : ASTNode
{
    ASTNode testExp;
    ASTNode[] block;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTDo : ASTNode
{
    ASTNode[] block;
    ASTNode testExp;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTFor : ASTNode
{
    ASTNode initExp, testExp, stepExp;
    ASTNode[] block;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTForeach : ASTNode
{
    ASTDef[] initDefs;
    ASTNode iterExp;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTBreak : ASTNode
{
    ASTNode next;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTContinue : ASTNode
{
    ASTNode next;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTReturn : ASTNode
{
    ASTNode exp;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTUnaryExp : ASTNode
{
    ASTNode exp;
    TokenType op;
    bool isPostfix;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTBinary : ASTNode
{
    ASTNode lhsExp, rhsExp;
    TokenType op;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTTinary : ASTNode
{
    ASTNode testExp, lhsExp, rhsExp;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTCall : ASTNode
{
    ASTNode lhsExp;
    ASTNode[] args;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTIndex : ASTNode
{
    ASTNode lhsExp;
    ASTNode[] args;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTAssign : ASTNode
{
    ASTNode lhsExp, rhsExp;
    TokenType op;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTNew : ASTNode
{
    ASTNode type;
    ASTNode[] args;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTCast : ASTNode
{
    ASTNode type;
    ASTNode exp;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTIdentifier : ASTNode
{
    string name;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTLookup : ASTNode
{
    ASTNode lhsExp;
    string name;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTStringLiteral : ASTNode
{
    string literal;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTCharecterLiteral : ASTNode
{
    dchar literal;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTFloatLiteral : ASTNode
{
    real literal;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTIntegerLiteral : ASTNode
{
    long literal;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

class ASTArrayLiteral : ASTNode
{
    ASTNode[] literal;

    mixin ASTNodeCtor;
    mixin ASTAccepter;
}

abstract class ASTNode
{
    SRCLocation loc;
    ASTNode parent;

    this(SRCLocation loc, ASTNode parent)
    {
        this.loc = loc;
        this.parent = parent;
    }

    abstract void accept(ASTVisitor visitor);
}

abstract class ASTDecl : ASTNode
{
    string name;
    string[] attribs;

    this(SRCLocation loc, ASTNode parent, string[] attrubs)
    {
        super(loc, parent);
        this.attribs = attribs;
    }
}

mixin template ASTAccepter()
{
    override accept(ASTVisitor visitor)
    {
        visitor.visit(this);
    }
}

mixin template ASTNodeCtor()
{
    this(SRCLocation loc, ASTNode parent)
    {
        super(loc, parent);
    }
}

mixin template ASTDeclCtor()
{
    this(SRCLocation loc, ASTNode parent, [] attribs)
    {
        super(loc, parent, attribs);
    }
}

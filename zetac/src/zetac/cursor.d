module zetac.cursor;

import zetac.ast;

class ASTCursor : ASTVisitor
{
    final void visit(ASTModule that)
    {
        if (this.enter(that))
            this.visit(cast(ASTNode[]) that.block);
        this.exit(that);
    }

    final void visit(ASTImport that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTDef that)
    {
        if (this.enter(that))
            if (that.exp !is null)
                that.exp.accept(this);
        this.exit(that);
    }

    final void visit(ASTFunction that)
    {
        if (this.enter(that))
        {
            this.visit(cast(ASTNode[]) that.parameters);
            this.visit(that.block);
        }
        this.exit(that);
    }

    final void visit(ASTClass that)
    {
        if (this.enter(that))
            this.visit(cast(ASTNode[]) that.block);
        this.exit(that);
    }

    final void visit(ASTInterface that)
    {
        if (this.enter(that))
            this.visit(cast(ASTNode[]) that.block);
        this.exit(that);
    }

    final void visit(ASTIf that)
    {
        if (this.enter(that))
        {
            this.visit(that.ifBlock);
            if (that.elseBlock !is null)
                this.visit(that.elseBlock);
        }
        this.exit(that);
    }

    final void visit(ASTSwitch that)
    {
        if (this.enter(that))
        {
            that.testExp.accept(this);
            this.visit(cast(ASTNode[]) that.block);
        }
        this.exit(that);
    }

    final void visit(ASTCase that)
    {
        if (this.enter(that))
        {
            that.testExp.accept(this);
            this.visit(that.block);
        }
        this.exit(that);
    }

    final void visit(ASTWhile that)
    {
        if (this.enter(that))
        {
            that.testExp.accept(this);
            this.visit(that.block);
        }
        this.exit(that);
    }

    final void visit(ASTDo that)
    {
        if (this.enter(that))
        {
            this.visit(that.block);
            that.testExp.accept(this);
        }
        this.exit(that);
    }

    final void visit(ASTFor that)
    {
        if (this.enter(that))
        {
            that.initExp.accept(this);
            that.testExp.accept(this);
            that.stepExp.accept(this);
            this.visit(that.block);
        }
        this.exit(that);
    }

    final void visit(ASTForeach that)
    {
        if (this.enter(that))
        {
            this.visit(cast(ASTNode[]) that.initDefs);
            that.iterExp.accept(this);
            this.visit(that.block);
        }
        this.exit(that);
    }

    final void visit(ASTBreak that)
    {
        if (this.enter(that))
            if (that.next !is null)
                that.next.accept(this);
        this.exit(that);
    }

    final void visit(ASTContinue that)
    {
        if (this.enter(that))
            if (that.next !is null)
                that.next.accept(this);
        this.exit(that);
    }

    final void visit(ASTReturn that)
    {
        if (this.enter(that))
            if (that.exp !is null)
                that.exp.accept(this);
        this.exit(that);
    }

    final void visit(ASTUnary that)
    {
        if (this.enter(that))
            that.exp.accept(this);
        this.exit(that);
    }

    final void visit(ASTBinary that)
    {
        if (this.enter(that))
        {
            that.lhsExp.accept(this);
            that.rhsExp.accept(this);
        }
        this.exit(that);
    }

    final void visit(ASTTinary that)
    {
        if (this.enter(that))
        {
            that.testExp.accept(this);
            that.lhsExp.accept(this);
            that.rhsExp.accept(this);
        }
        this.exit(that);
    }

    final void visit(ASTCall that)
    {
        if (this.enter(that))
        {
            that.lhsExp.accept(this);
            this.visit(that.args);
        }
        this.exit(that);
    }

    final void visit(ASTIndex that)
    {
        if (this.enter(that))
        {
            that.lhsExp.accept(this);
            this.visit(that.args);
        }
        this.exit(that);
    }

    final void visit(ASTAssign that)
    {
        if (this.enter(that))
        {
            that.lhsExp.accept(this);
            that.rhsExp.accept(this);
        }
        this.exit(that);
    }

    final void visit(ASTNew that)
    {
        if (this.enter(that))
        {
            this.visit(that.args);
        }
        this.exit(that);
    }

    final void visit(ASTIdentifier that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTLookup that)
    {
        if (this.enter(that))
            that.lhsExp.accept(this);
        this.exit(that);
    }

    final void visit(ASTStringLiteral that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTCharacterLiteral that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTFloatLiteral that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTIntegerLiteral that)
    {
        this.enter(that);
        this.exit(that);
    }

    final void visit(ASTArrayLiteral that)
    {
        if (this.enter(that))
            this.visit(that.literal);
        this.exit(that);
    }

    final void visit(ASTNode[] that)
    {
        if (this.enter(that))
            foreach (node; that)
                node.accept(this);
        this.exit(that);
    }

    bool enter(ASTModule that)
    {
        return true;
    }

    bool enter(ASTImport that)
    {
        return true;
    }

    bool enter(ASTDef that)
    {
        return true;
    }

    bool enter(ASTFunction that)
    {
        return true;
    }

    bool enter(ASTClass that)
    {
        return true;
    }

    bool enter(ASTInterface that)
    {
        return true;
    }

    bool enter(ASTIf that)
    {
        return true;
    }

    bool enter(ASTSwitch that)
    {
        return true;
    }

    bool enter(ASTCase that)
    {
        return true;
    }

    bool enter(ASTWhile that)
    {
        return true;
    }

    bool enter(ASTDo that)
    {
        return true;
    }

    bool enter(ASTFor that)
    {
        return true;
    }

    bool enter(ASTForeach that)
    {
        return true;
    }

    bool enter(ASTBreak that)
    {
        return true;
    }

    bool enter(ASTContinue that)
    {
        return true;
    }

    bool enter(ASTReturn that)
    {
        return true;
    }

    bool enter(ASTUnary that)
    {
        return true;
    }

    bool enter(ASTBinary that)
    {
        return true;
    }

    bool enter(ASTTinary that)
    {
        return true;
    }

    bool enter(ASTCall that)
    {
        return true;
    }

    bool enter(ASTIndex that)
    {
        return true;
    }

    bool enter(ASTAssign that)
    {
        return true;
    }

    bool enter(ASTNew that)
    {
        return true;
    }

    bool enter(ASTIdentifier that)
    {
        return true;
    }

    bool enter(ASTLookup that)
    {
        return true;
    }

    bool enter(ASTStringLiteral that)
    {
        return true;
    }

    bool enter(ASTCharacterLiteral that)
    {
        return true;
    }

    bool enter(ASTFloatLiteral that)
    {
        return true;
    }

    bool enter(ASTIntegerLiteral that)
    {
        return true;
    }

    bool enter(ASTArrayLiteral that)
    {
        return true;
    }

    bool enter(ASTNode[] that)
    {
        return true;
    }

    void exit(ASTModule that)
    {
    }

    void exit(ASTImport that)
    {
    }

    void exit(ASTDef that)
    {
    }

    void exit(ASTFunction that)
    {
    }

    void exit(ASTClass that)
    {
    }

    void exit(ASTInterface that)
    {
    }

    void exit(ASTIf that)
    {
    }

    void exit(ASTSwitch that)
    {
    }

    void exit(ASTCase that)
    {
    }

    void exit(ASTWhile that)
    {
    }

    void exit(ASTDo that)
    {
    }

    void exit(ASTFor that)
    {
    }

    void exit(ASTForeach that)
    {
    }

    void exit(ASTBreak that)
    {
    }

    void exit(ASTContinue that)
    {
    }

    void exit(ASTReturn that)
    {
    }

    void exit(ASTUnary that)
    {
    }

    void exit(ASTBinary that)
    {
    }

    void exit(ASTTinary that)
    {
    }

    void exit(ASTCall that)
    {
    }

    void exit(ASTIndex that)
    {
    }

    void exit(ASTAssign that)
    {
    }

    void exit(ASTNew that)
    {
    }

    void exit(ASTIdentifier that)
    {
    }

    void exit(ASTLookup that)
    {
    }

    void exit(ASTStringLiteral that)
    {
    }

    void exit(ASTCharacterLiteral that)
    {
    }

    void exit(ASTFloatLiteral that)
    {
    }

    void exit(ASTIntegerLiteral that)
    {
    }

    void exit(ASTArrayLiteral that)
    {
    }

    void exit(ASTNode[] that)
    {
    }
}

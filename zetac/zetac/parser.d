module zetac.parser;

import std.traits : ReturnType;
import std.array : join;

import zetac.lexer;
import zetac.ast;

alias TokenStream = DList!Token;

auto parseModule(TokenStream stream, string defaultName)
{
    auto astModule = new ASTModule(stream.front.type, null, null);
    auto parents = new Stack!ASTNode;

    parents.push(astModule);
    if (stream.test(TokenType.tk_module))
        astModule.name = parseQuantifiedName(stream);
    else
        astModule.name = defaultName;
    while (!stream.empty)
        astModule.block ~= parseDecl(stream, parents);
    parents.pop();
}

auto parseDecl(TokenStream stream, Stack!ASTNode parents, ASTAttribute[] attribs = null)
{
    switch (stream.front.type)
    {
    case TokenType.tk_def:
        return parseDef(stream, parents, attribs);
    case TokenType.tk_function:
        return parseFunction(stream, parents, attribs);
    case TokenType.tk_class:
        return parseClass(stream, parents, attribs);
    case TokenType.tk_interface:
        return parseInterface(stream, parents, attribs);
    case TokenType.tk_attribute:
        return parseDecl(stream, parents,
                parseAttributes(stream, parents) ~ attribs);
    default:
        throw new CompilerError(stream.front.loc, "Unrecognised declaration %s", stream.front.text);
    }
}

auto parseDef(TokenStream stream, Stack!ASTNode parents, string[] attribs = null)
{
    if (stream.front == TokenType.tk_attribute)
        attribs ~= parseAttributes(stream, parents);
    auto astDef = new ASTDef(stream.expect(TokenType.tk_def).loc, parents.peek(), attribs);
    stream.expect(TokenType.tk_colon);
    astDef.type = parseSymbolRef(stream, parents);
    astDef.name = stream.expect(TokenType.tk_identifier).text;
    if (stream.test(TokenType.tk_assign))
        astDef.exp = parseExpression(stream, parents);
    stream.expect(TokenType.tk_semicolon);
    return astDef;
}

auto parseFunction(TokenStream stream, Stack!ASTNode parents, string[] attribs = null)
{
    if (stream.front == TokenType.tk_attribute)
        attribs ~= parseAttributes(stream, parents);
    auto astFunction = new ASTFunction(stream.expect(TokenType.tk_function)
            .loc, parents.peek(), attribs);
    stream.expect(TokenType.tk_colon);
    astFunction.type = parseSymbolRef(stream, parents);
    astFunction.name = stream.expect(TokenType.tk_identifier).text;
    astFunction.parameters = parseParameterList!parseDef(stream, parents);
    astFunction.block = parseStatementBlock(stream, parents);
    return astFunction;
}

auto parseClass(TokenStream stream, Stack!ASTNode parents, string[] attribs = null)
{
    if (stream.front == TokenType.tk_attribute)
        attribs ~= parseAttributes(stream, parents);
    auto astClass = new ASTClass(stream.expect(TokenType.tk_class).loc, parents.peek(), attribs);
    astClass.name = stream.expect(TokenType.tk_identifier).text;
    if (stream.test(TokenType.tk_inherits))
        astClass.inherits = parseDelimitedList!parseSymbolRef(stream, parents, TokenType.tk_comma);
    astClass.block = parseDeclBlock(stream, parents);
    return astClass;
}

auto parseInterface(TokenStream stream, Stack!ASTNode parents, string[] attribs = null)
{
	if (stream.front == TokenType.tk_attribute)
        attribs ~= parseAttributes(stream, parents);
    auto astInterface = new ASTInterface(stream.expect(TokenType.tk_interface)
            .loc, parents.peek(), attribs);
    astInterface.name = stream.expect(TokenType.tk_identifier).text;
    if (stream.test(TokenType.tk_inherits))
        astInterface.inherits = parseDelimitedList!parseSymbolRef(stream,
                parents, TokenType.tk_comma);
    astInterface.block = parseDeclBlock(stream, parents);
    return astInterface;
}

auto parseAttributes(TokenStrean stream, Stack!ASTNode parents, string[] attribs = null)
{
	stream.expect(TokenType.tk_attribute);
	return parseDelimitedList!((a, b) => a.expect(TokenType.tk_identifer.text))(stream, 
		null, TokenType.tk_attribute);
}

auto parseQuantifiedName(TokenStream stream)
{
    return parseDelimitedList!((a, b) => a.expect(TokenType.tk_identifer.text))(stream,
            null, TokenType.tk_dot).joint('.');
}

auto parseDelimitedList(alias fun)(TokenSteam stream, Stack!ASTNode parents, TokenType delimiter)
{
    ReturnType!(fun)[] result;
    while (!stream.empty && stream.test(delimiter))
        result ~= func(stream, parents);
    return result;
}

Token expect(TokenStream stream, TokenType type)
{
    auto result = stream.front;
    if (result.type == type)
    {
        stream.removeFront();
        return result;
    }
    else
        throw new CompilerError(result.loc, "Expected %s got %s",
                tokenTypeToText(type), result.text);
}

Token test(TokenStream stream, TokenType)
{
    auto result = stream.front;
    if (result.type == type)
    {
        stream.removeFront();
        return result;
    }
    return null;
}

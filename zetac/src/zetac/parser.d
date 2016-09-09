module zetac.parser;

import std.traits : ReturnType;
import std.array : join;
import std.container.dlist : DList;
import std.conv : to;

import zetac.lexer : TokenType, Token, tokenTypeName;
import zetac.ast;
import zetac.common : Stack, CompilerError;

alias TokenStream = DList!Token;

ASTModule parseModule(TokenStream stream, Stack!ASTNode stack, string defaultName)
{
	auto astModule = new ASTModule(stream.front.loc, null, null);
	
	stack.push(astModule);
	if (stream.test(TokenType.tk_module))
	{
		astModule.name = parseQuantifiedName(stream);
		stream.expect(TokenType.tk_semicolon);
	}
	else
		astModule.name = defaultName;
	while (!stream.empty)
		astModule.block ~= parseDeclaration(stream, stack);
	stack.pop();
	return astModule;
}

ASTImport parseImport(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	auto result = new ASTImport(stream.expect(TokenType.tk_import).loc, stack.peek, attribs);
	result.name = parseQuantifiedName(stream);
	return result;
}

ASTDef parseDef(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	if (stream.front.type == TokenType.tk_attribute)
		attribs ~= parseAttributes(stream, stack);
	auto astDef = new ASTDef(stream.expect(TokenType.tk_def).loc, stack.peek(), attribs);
	stack.push(astDef);
	astDef.name = stream.expect(TokenType.tk_identifier).text;
	if (stream.test(TokenType.tk_assign))
		astDef.exp = parseExpression(stream, stack);
	stack.pop();
	return astDef;
}

ASTFunction parseFunction(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	if (stream.front.type == TokenType.tk_attribute)
		attribs ~= parseAttributes(stream, stack);
	auto astFunction = new ASTFunction(stream.expect(TokenType.tk_function)
		.loc, stack.peek(), attribs);
	stack.push(astFunction);
	astFunction.name = stream.expect(TokenType.tk_identifier).text;
	stream.expect(TokenType.tk_lparen);
	if (stream.front.type != TokenType.tk_rparen)
		astFunction.parameters = parseDelimitedList!parseDef(stream, stack, TokenType.tk_comma);
	stream.expect(TokenType.tk_lparen);
	astFunction.block = parseStatementBlock(stream, stack);
	stack.pop();
	return astFunction;
}

ASTClass parseClass(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	if (stream.front.type == TokenType.tk_attribute)
		attribs ~= parseAttributes(stream, stack);
	auto astClass = new ASTClass(stream.expect(TokenType.tk_class).loc, stack.peek(), attribs);
	stack.push(astClass);
	astClass.name = stream.expect(TokenType.tk_identifier).text;
	if (stream.test(TokenType.tk_inherits))
		astClass.inherits = parseDelimitedList!parseSymbolRef(stream, stack, TokenType.tk_comma);
	astClass.block = parseDeclarationBlock(stream, stack);
	stack.pop();
	return astClass;
}

ASTInterface parseInterface(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	if (stream.front.type == TokenType.tk_attribute)
		attribs ~= parseAttributes(stream, stack);
	auto astInterface = new ASTInterface(stream.expect(TokenType.tk_interface)
		.loc, stack.peek(), attribs);
	stack.push(astInterface);
	astInterface.name = stream.expect(TokenType.tk_identifier).text;
	if (stream.test(TokenType.tk_inherits))
		astInterface.inherits = parseDelimitedList!parseSymbolRef(stream,
			stack, TokenType.tk_comma);
	astInterface.block = parseDeclarationBlock(stream, stack);
	stack.pop();
	return astInterface;
}

ASTIf parseIf(TokenStream stream, Stack!ASTNode stack)
{
	auto astIf = new ASTIf(stream.expect(TokenType.tk_if).loc, stack.peek);
	stack.push(astIf);
	stream.expect(TokenType.tk_lparen);
	astIf.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	astIf.ifBlock = parseStatementBlock(stream, stack);
	if (stream.test(TokenType.tk_else))
		astIf.elseBlock = parseStatementBlock(stream, stack);
	stack.pop();
	return astIf;
}

ASTSwitch parseSwitch(TokenStream stream, Stack!ASTNode stack)
{
	auto astSwitch = new ASTSwitch(stream.expect(TokenType.tk_switch).loc, stack.peek);
	stack.push(astSwitch);
	stream.expect(TokenType.tk_lparen);
	astSwitch.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	stream.expect(TokenType.tk_lbrace);
	while (!stream.test(TokenType.tk_rbrace))
		astSwitch.block ~= parseCase(stream, stack);
	return astSwitch;
}

ASTCase parseCase(TokenStream stream, Stack!ASTNode stack)
{
	auto astCase = new ASTCase(stream.expect(TokenType.tk_case).loc, stack.peek);
	if (stream.test(TokenType.tk_else))
		astCase.isElseCase = true;
	else
		astCase.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_colon);
	while (stream.front.type != TokenType.tk_case && stream.front.type != TokenType.tk_rbrace)
		astCase.block ~= parseStatement(stream, stack);
	return astCase;
}

ASTWhile parseWhile(TokenStream stream, Stack!ASTNode stack)
{
	auto astWhile = new ASTWhile(stream.expect(TokenType.tk_while).loc, stack.peek);
	stack.push(astWhile);
	stream.expect(TokenType.tk_lparen);
	astWhile.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	astWhile.block = parseStatementBlock(stream, stack);
	stack.pop();
	return astWhile;
}

ASTDo parseDo(TokenStream stream, Stack!ASTNode stack)
{
	auto astDo = new ASTDo(stream.expect(TokenType.tk_do).loc, stack.peek);
	stack.push(astDo);
	astDo.block = parseStatementBlock(stream, stack);
	stream.expect(TokenType.tk_while);
	stream.expect(TokenType.tk_lparen);
	astDo.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	stack.pop();
	return astDo;
}

ASTFor parseFor(TokenStream stream, Stack!ASTNode stack)
{
	auto astFor = new ASTFor(stream.expect(TokenType.tk_for).loc, stack.peek);
	stack.push(astFor);
	stream.expect(TokenType.tk_lparen);
	astFor.initExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_semicolon);
	astFor.testExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_semicolon);
	astFor.stepExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	astFor.block = parseStatementBlock(stream, stack);
	stack.pop();
	return astFor;
}

ASTForeach parseForeach(TokenStream stream, Stack!ASTNode stack)
{
	auto astForeach = new ASTForeach(stream.expect(TokenType.tk_foreach).loc, stack.peek);
	stack.push(astForeach);
	stream.expect(TokenType.tk_lparen);
	astForeach.initDefs = parseDelimitedList!parseDef(stream, stack, TokenType.tk_comma);
	stream.expect(TokenType.tk_semicolon);
	astForeach.iterExp = parseExpression(stream, stack);
	stream.expect(TokenType.tk_rparen);
	astForeach.block = parseStatementBlock(stream, stack);
	stack.pop();
	return astForeach;
}

ASTBreak parseBreak(TokenStream stream, Stack!ASTNode stack)
{
	auto astBreak = new ASTBreak(stream.expect(TokenType.tk_break).loc, stack.peek);
	if (stream.front.type == TokenType.tk_break)
		astBreak.next = parseBreak(stream, stack);
	else if (stream.front.type == TokenType.tk_continue)
		astBreak.next = parseContinue(stream, stack);
	return astBreak;
}

ASTContinue parseContinue(TokenStream stream, Stack!ASTNode stack)
{
	auto astContinue = new ASTContinue(stream.expect(TokenType.tk_continue).loc, stack.peek);
	if (stream.front.type == TokenType.tk_break)
		astContinue.next = parseBreak(stream, stack);
	else if (stream.front.type == TokenType.tk_continue)
		astContinue.next = parseContinue(stream, stack);
	return astContinue;
}

ASTReturn parseReturn(TokenStream stream, Stack!ASTNode stack)
{
	auto astReturn = new ASTReturn(stream.expect(TokenType.tk_return).loc, stack.peek);
	astReturn.exp = parseExpression(stream, stack);
	return astReturn;
}

ASTDecl[] parseDeclarationBlock(TokenStream stream, Stack!ASTNode stack)
{
	ASTDecl[] result;
	if (stream.test(TokenType.tk_lbrace))
		while(!stream.test(TokenType.tk_rparen))
			result ~= parseDeclaration(stream, stack);
	else
	{
		do
			result ~= parseDeclaration(stream, stack);
		while(stream.test(TokenType.tk_colon));
	}
	return result;
}

ASTNode[] parseStatementBlock(TokenStream stream, Stack!ASTNode stack)
{
	ASTNode[] result;
	if (stream.test(TokenType.tk_lbrace))
		while(!stream.test(TokenType.tk_rparen))
			result ~= parseStatement(stream, stack);
	else
	{
		do
			result ~= parseStatement(stream, stack);
		while(stream.test(TokenType.tk_colon));
	}
	return result;
}

ASTDecl parseDeclaration(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	switch (stream.front.type)
	{
		case TokenType.tk_import:
			auto result = parseImport(stream, stack, attribs);
			stream.expect(TokenType.tk_semicolon);
			return result;
		case TokenType.tk_def:
			auto result = parseDef(stream, stack, attribs);
			stream.expect(TokenType.tk_semicolon);
			return result;
		case TokenType.tk_function:
			auto result = parseFunction(stream, stack, attribs);
			return result;
		case TokenType.tk_class:
			auto result = parseClass(stream, stack, attribs);
			return result;
		case TokenType.tk_interface:
			auto result = parseInterface(stream, stack, attribs);
			return result;
		case TokenType.tk_attribute:
			auto result = parseAttributes(stream, stack, attribs);
			return parseDeclaration(stream, stack, result);
		default:
			throw new CompilerError(stream.front.loc, "Unknown declaration %s", stream.front.text);
	}
}

ASTNode parseStatement(TokenStream stream, Stack!ASTNode stack)
{
	switch (stream.front.type)
	{
		case TokenType.tk_if:
			auto result = parseIf(stream, stack);
			return result;
		case TokenType.tk_switch:
			auto result = parseSwitch(stream, stack);
			return result;
		case TokenType.tk_while:
			auto result = parseWhile(stream, stack);
			return result;
		case TokenType.tk_do:
			auto result = parseDo(stream, stack);
			return result;
		case TokenType.tk_for:
			auto result = parseFor(stream, stack);
			return result;
		case TokenType.tk_foreach:
			auto result = parseForeach(stream, stack);
			return result;
		case TokenType.tk_break:
			auto result = parseBreak(stream, stack);
			stream.expect(TokenType.tk_semicolon);
			return result;
		case TokenType.tk_continue:
			auto result = parseContinue(stream, stack);
			return result;
		case TokenType.tk_return:
			auto result = parseReturn(stream, stack);
			return result;
		case TokenType.tk_import:
		case TokenType.tk_def:
		case TokenType.tk_function:
		case TokenType.tk_class:
		case TokenType.tk_interface:
		case TokenType.tk_attribute:
			auto result = parseDeclaration(stream, stack);
			return result;
		default:
			auto result = parseExpression(stream, stack);
			stream.expect(TokenType.tk_semicolon);
			return result;
	}
}

ASTNode parseExpression(TokenStream stream, Stack!ASTNode stack)
{
	switch (stream.front.type)
	{
		case TokenType.tk_add:
		case TokenType.tk_subtract:
		case TokenType.tk_inc:
		case TokenType.tk_dec:
		case TokenType.tk_not:
			auto result = new ASTUnary(stream.front.loc, stack.peek);
			result.op = stream.front.type;
			stream.removeFront();
			result.exp = parseExpression(stream, stack);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_lparen:
			stream.removeFront();
			auto result = parseExpression(stream, stack);
			stream.expect(TokenType.tk_rparen);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_new:
			auto result = new ASTNew(stream.front.loc, stack.peek);
			stream.removeFront();
			result.type = parseSymbolRef(stream, stack);
			stream.expect(TokenType.tk_lparen);
			if (stream.front.type != TokenType.tk_rparen)
				result.args = parseDelimitedList!parseExpression(stream, stack, TokenType.tk_comma);
			stream.expect(TokenType.tk_rparen);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_identifier:
			auto result = new ASTIdentifier(stream.front.loc, stack.peek);
			result.name = stream.front.text;
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_lbracket:
			auto result = new ASTArrayLiteral(stream.front.loc, stack.peek);
			stream.removeFront();
			if (stream.front.type != TokenType.tk_rbracket)
				result.literal = parseDelimitedList!parseExpression(stream, stack, TokenType.tk_comma);
			stream.expect(TokenType.tk_rbracket);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_string:
			auto result = new ASTStringLiteral(stream.front.loc, stack.peek);
			result.literal = stream.front.text;
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_char:
			auto result = new ASTCharacterLiteral(stream.front.loc, stack.peek);
			result.literal = stream.front.text[0];
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_integer:
			auto result = new ASTIntegerLiteral(stream.front.loc, stack.peek);
			result.literal = to!long(stream.front.text);
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_float:
			auto result = new ASTFloatLiteral(stream.front.loc, stack.peek);
			result.literal = to!real(stream.front.text);
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_hex:
			auto result = new ASTIntegerLiteral(stream.front.loc, stack.peek);
			result.literal = to!long(stream.front.text, stream.front.text.length);
			stream.removeFront();
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_attribute:
		case TokenType.tk_def:
			auto result = parseDef(stream, stack);
			return parseNextExpression(stream, stack, result);
		default:
			throw new CompilerError(stream.front.loc, "Unrecognised Expression '%s'", stream.front.text);
	}
}

ASTNode parseNextExpression(TokenStream stream, Stack!ASTNode stack, ASTNode exp)
{
	switch (stream.front.type)
	{
		case TokenType.tk_inc:
		case TokenType.tk_dec:
			auto result = new ASTUnary(stream.front.loc, stack.peek);
			result.isPostfix = true;
			result.op = stream.front.type;
			stream.removeFront();
			result.exp = exp;
			return parseNextExpression(stream, stack, exp);
		case TokenType.tk_add:
		case TokenType.tk_subtract:
		case TokenType.tk_multiply:
		case TokenType.tk_divide:
		case TokenType.tk_modulo:
		case TokenType.tk_concat:
		case TokenType.tk_and:
		case TokenType.tk_or:
		case TokenType.tk_xor:
		case TokenType.tk_equal:
		case TokenType.tk_not_equal:
		case TokenType.tk_greater:
		case TokenType.tk_less:
		case TokenType.tk_greater_equal:
		case TokenType.tk_less_equal:
			auto result = new ASTBinary(stream.front.loc, stack.peek);
			result.op = stream.front.type;
			stream.removeFront();
			result.lhsExp = exp;
			result.rhsExp = parseExpression(stream, stack);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_assign:
		case TokenType.tk_assign_add:
		case TokenType.tk_assign_subtract:
		case TokenType.tk_assign_multiply:
		case TokenType.tk_assign_divide:
		case TokenType.tk_assign_modulo:
		case TokenType.tk_assign_concat:
		case TokenType.tk_assign_and:
		case TokenType.tk_assign_or:
		case TokenType.tk_assign_xor:
			auto result = new ASTAssign(stream.front.loc, stack.peek);
			result.op = stream.front.type;
			stream.removeFront();
			result.lhsExp = exp;
			result.rhsExp = parseExpression(stream, stack);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_lparen:
			auto result = new ASTCall(stream.front.loc, stack.peek);
			stream.removeFront();
			result.lhsExp = exp;
			if (stream.front.type != TokenType.tk_rparen)
				result.args = parseDelimitedList!parseExpression(stream, stack, TokenType.tk_comma);
			stream.expect(TokenType.tk_rparen);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_lbracket:
			auto result = new ASTIndex(stream.front.loc, stack.peek);
			stream.removeFront();
			result.lhsExp = exp;
			if (stream.front.type != TokenType.tk_rbracket)
				result.args = parseDelimitedList!parseExpression(stream, stack, TokenType.tk_comma);
			stream.expect(TokenType.tk_rbracket);
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_dot:
			auto result = new ASTLookup(stream.front.loc, stack.peek);
			stream.removeFront();
			result.lhsExp = exp;
			result.name = stream.expect(TokenType.tk_identifier).text;
			return parseNextExpression(stream, stack, result);
		case TokenType.tk_tinary:
			auto result = new ASTTinary(stream.front.loc, stack.peek);
			stream.removeFront();
			result.testExp = exp;
			result.lhsExp = parseExpression(stream, stack);
			stream.expect(TokenType.tk_colon);
			result.rhsExp = parseExpression(stream, stack);
			return result;
		default:
			return exp;
	}
}

ASTNode parseSymbolRef(TokenStream stream, Stack!ASTNode stack)
{
	auto identifier = new ASTIdentifier(stream.front.loc, stack.peek);
	identifier.name = stream.expect(TokenType.tk_identifier).text;
	ASTNode result = identifier;
	while(stream.test(TokenType.tk_dot))
	{
		auto next = new ASTLookup(stream.front.loc, stack.peek);
		next.name = stream.expect(TokenType.tk_identifier).text;
		next.lhsExp = result;
		result = next;
	}
	return result;
}
string[] parseAttributes(TokenStream stream, Stack!ASTNode stack, string[] attribs = null)
{
	stream.expect(TokenType.tk_attribute);
	return attribs ~ parseDelimitedList!(string,(a,
			b) => a.expect(TokenType.tk_identifier).text)(stream, Stack!ASTNode(), TokenType.tk_attribute);
}

string parseQuantifiedName(TokenStream stream)
{
	return parseDelimitedList!(string,(a, b) => a.expect(TokenType.tk_identifier).text)(stream,
		Stack!ASTNode(), TokenType.tk_dot).join('.');
}

auto parseDelimitedList(T,alias fun)(TokenStream stream, Stack!ASTNode stack, TokenType delimiter)
{
	T[] result;
	while (!stream.empty && stream.test(delimiter))
		result ~= fun(stream, stack);
	return result;
}

template parseDelimitedList(alias fun)
{
	alias parseDelimitedList = .parseDelimitedList!(ReturnType!fun,fun);
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
			tokenTypeName(type), result.text);
}

Token test(TokenStream stream, TokenType type)
{
	auto result = stream.front;
	if (result.type == type)
	{
		stream.removeFront();
		return result;
	}
	return null;
}

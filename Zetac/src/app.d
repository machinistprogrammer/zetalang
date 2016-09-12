module app;

import std.stdio;
import std.file : readText;
import zetac.lexer;
import zetac.parser;
import zetac.ast;

void main()
{
	auto file = "../../tests/pass/test1.zet";
	auto src = readText(file);
	auto ts = lex(file, src);
	auto ast = parse(file, ts.list);
}
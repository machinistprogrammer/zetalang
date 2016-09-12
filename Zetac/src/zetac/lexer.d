module zetac.lexer;

public import std.container.dlist : DList;
import std.algorithm.sorting : sort;
import std.array : Appender;
import std.uni : isWhite, isAlpha, isNumber, toLower;
import std.conv : to;
import zetac.common : SRCLocation, CompilerError;
import zetac.utils : flip;

class Token
{
    TokenType type;
    string text;
    SRCLocation loc;

    this(TokenType type, string text, SRCLocation loc)
    {
        this.type = type;
        this.text = text;
        this.loc = loc;
    }
}

auto lex(string file, string src)
{
    struct Result
    {
        CompilerError error;
        DList!Token list;
    }

    Result result;
    try
    {
        For: for (size_t i; i < src.length; i++)
        {
            if (src[i] == '/' && i + 1 < src.length && src[i + 1].isComment())
				lexComment(file, src, i);
			if (src[i].isWhite())
				continue;

            foreach_reverse (key; sort!"a.length < b.length"(tokenMap.keys))
            {
                if (i + key.length > src.length)
                    continue;
                auto tok = src[i .. i + key.length];
                import std.stdio;

                if (key == tok && ((tok[$ - 1].isIdentifier()
                        && i + key.length < src.length) ? !src[i + key.length].isIdentifier() : true))
                {
                    result.list.insert(new Token(tokenMap[key], tok, new SRCLocation(file, src, i)));
                    i += key.length-1;
                    continue For;
                }
            }
            if (src[i].isIdentifier())
            {
                auto identifier = lexIdentifier(file, src, i);
				i--;
                result.list.insert(identifier);
            }
            else if (src[i].isNumber())
            {
                auto number = lexNumber(file, src, i);
				i--;
                result.list.insert(number);
            }
            else if (src[i].isString())
            {
                auto string_ = lexString(file, src, i);
				i--;
                result.list.insert(string_);
            }
            else
            {
                throw new CompilerError(new SRCLocation(file, src, i), "Invalid symbol '%s'", src[i]);
            }
        }
    }
    catch (CompilerError e)
    {
        result.error = e;
    }
    return result;
}

bool isComment(dchar c)
{
    return c == '/' || c == '*';
}

bool isIdentifier(dchar c)
{
    return c.isAlpha() || c == '_';
}

bool isString(dchar c)
{
    return c == '`' || c == '"' || c == '\'';
}

auto lexComment(string file, string src, ref size_t i)
{

    i += 1;
    if (src[i] == '/')
        while (i < src.length && src[i] != '\r' && src[i] != '\n')
            i += 1;
    else if (src[i] == '*')
	{
        while (src[i .. i + 2] != "*/")
        {
            i += 1;
			if (i + 1 >= src.length)
				throw new CompilerError(new SRCLocation(file, src, i), "Unterminated comment");
        }
		i += 2;
	}
}

auto lexIdentifier(string file, string src, ref size_t i)
{
    Token result;
    SRCLocation loc = new SRCLocation(file, src, i);
    Appender!string data;

    while (i < src.length && (src[i].isAlpha() || src[i].isNumber))
        data.put(src[i++]);

    result = new Token(TokenType.tk_identifier, data.data, loc);
    return result;
}

auto lexNumber(string file, string src, ref size_t i)
{
    Token result;
    SRCLocation loc = new SRCLocation(file, src, i);
    Appender!string data;

    if (i + 1 <= src.length && src[i .. i + 1].toLower() == "0x")
    {
        i += 2;
        while (i < src.length && (src[i].isNumber() || src[i].toLower() >= 'a'
                && src[i].toLower() <= 'z'))
        {
            data.put(src[i++]);
        }
        if (data.data.length % 2 != 0 || data.data.length > 16)
            throw new CompilerError(loc, "Invalid hexdecimal length");
        return new Token(TokenType.tk_hex, data.data, loc);
    }
    else
    {
        bool isFloat;

        while (i < src.length && (src[i].isNumber() || src[i] == '.'))
        {
            if (src[i] == '.')
            {
                if (isFloat)
                    break;
                isFloat = true;
            }
            data.put(src[i++]);
        }
        if (i < src.length && src[i] == 'f')
        {
            isFloat = true;
            i++;
        }
        return new Token(isFloat ? TokenType.tk_float : TokenType.tk_integer, data.data, loc);
    }
}

auto lexString(string file, string src, ref size_t i)
{
    SRCLocation loc = new SRCLocation(file, src, i);

    if (src[i] == '`')
    {
        i += 1;
        Appender!string data;
        while (i > src.length && src[i] != '`')
            data.put(src[i++]);
        if (i <= src.length || src[i] != '`')
            throw new CompilerError(loc, "Unterminated string constant");
        else
            return new Token(TokenType.tk_string, data.data, loc);
    }
    else if (src[i] == '"')
    {
        i += 1;
        Appender!string data;
        while (i > src.length && src[i] != '"')
        {
            auto c = lexChar!('"')(file, src, i);
            data.put(c);
        }
        if (i <= src.length || src[i] != '"')
            throw new CompilerError(loc, "Unterminated string constant");
        else
            return new Token(TokenType.tk_string, data.data, loc);
    }
    else if (src[i] == '\'')
    {
        i += 1;
        auto c = lexChar!('\'')(file, src, i);
        if (i <= src.length || src[i] != '"')
            throw new CompilerError(loc, "Unterminated string constant");
        else
            return new Token(TokenType.tk_string, to!string(c), loc);
    }
    else
        assert(0);
}

auto lexChar(dchar terminator)(string file, string src, ref size_t i)
{
    dchar c;

    c = src[i++];
    if (c == '\\')
    {
        c = src[i++];
        switch (c)
        {
        case 'r':
            c = '\r';
            break;
        case 'n':
            c = '\n';
            break;
        case 't':
            c = '\t';
            break;
        case terminator:
            c = terminator;
            break;
        case '0':
            c = '\0';
            break;
        default:
            throw new CompilerError(new SRCLocation(file, src, i),
                    "Invalid escape sequence \\%s", c);
        }
    }
    return c;
}

string tokenTypeName(TokenType type)
{
    static string[TokenType] flippedTokenMap;
    if (flippedTokenMap is null)
        flippedTokenMap = tokenMap.flip();
    if (type == TokenType.tk_identifier)
        return "<identifier>";
    else if (type == TokenType.tk_string)
        return "<string constant>";
    else if (type == TokenType.tk_char)
        return "<character constant>";
    else if (type == TokenType.tk_integer)
        return "<integer constant>";
    else if (type == TokenType.tk_float)
        return "<float constant>";
    else if (type == TokenType.tk_hex)
        return "<hexdecimal constant>";
    else
        return flippedTokenMap[type];
}

enum TokenType
{
    tk_identifier,
    tk_string,
    tk_char,
    tk_integer,
    tk_float,
    tk_hex,

    tk_inc,
    tk_dec,
    tk_not,

    tk_add,
    tk_subtract,
    tk_multiply,
    tk_divide,
    tk_modulo,

    tk_concat,
    tk_and,
    tk_or,
    tk_xor,

    tk_equal,
    tk_not_equal,
    tk_greater,
    tk_less,
    tk_greater_equal,
    tk_less_equal,

    tk_assign,
    tk_assign_add,
    tk_assign_subtract,
    tk_assign_multiply,
    tk_assign_divide,
    tk_assign_modulo,

    tk_assign_concat,
    tk_assign_and,
    tk_assign_or,
    tk_assign_xor,

    tk_tinary,
    tk_attribute,

    tk_import,
    tk_module,
    tk_def,
    tk_function,
    tk_class,
    tk_interface,
    tk_inherits,

    tk_break,
    tk_continue,
    tk_return,
    tk_if,
    tk_elseif,
    tk_else,
    tk_switch,
    tk_case,
    tk_while,
    tk_do,
    tk_for,
    tk_foreach,
    tk_new,

    tk_lparen,
    tk_rparen,
    tk_lbrace,
    tk_rbrace,
    tk_lbracket,
    tk_rbracket,

    tk_dot,
    tk_comma,
    tk_colon,
    tk_semicolon,
    tk_dollar
}

//dfmt off
enum TokenType[string] tokenMap = 
[
	"++":TokenType.tk_inc,
	"--":TokenType.tk_dec,
	"!":TokenType.tk_not,
	
	"+":TokenType.tk_add,
	"-":TokenType.tk_subtract,
	"*":TokenType.tk_multiply,
	"//":TokenType.tk_divide,
	"%":TokenType.tk_modulo,
	
	"~":TokenType.tk_concat,
	"&":TokenType.tk_and,
	"|":TokenType.tk_or,
	"^":TokenType.tk_xor,
	
	"==":TokenType.tk_equal,
	"!=":TokenType.tk_not_equal,
	">":TokenType.tk_greater,
	"<":TokenType.tk_less,
	">=":TokenType.tk_greater_equal,
	"<=":TokenType.tk_less_equal,
	
	"=":TokenType.tk_assign,
	"+=":TokenType.tk_assign_add,
	"-=":TokenType.tk_assign_subtract,
	"*=":TokenType.tk_assign_multiply,
	"//=":TokenType.tk_assign_divide,
	"%=":TokenType.tk_assign_modulo,
	
	"~=":TokenType.tk_assign_concat,
	"&=":TokenType.tk_assign_and,
	"|=":TokenType.tk_assign_or,
	"^=":TokenType.tk_assign_xor,
	
	"?":TokenType.tk_tinary,
	"@":TokenType.tk_attribute,
	
	"module":TokenType.tk_module,
	"import":TokenType.tk_import,
	"def":TokenType.tk_def,
	"function":TokenType.tk_function,
	"class":TokenType.tk_class,
	"interface":TokenType.tk_interface,
	"inherits":TokenType.tk_inherits,
	
	"break":TokenType.tk_break,
	"continue":TokenType.tk_continue,
	"return":TokenType.tk_return,
	"if":TokenType.tk_if,
	"else":TokenType.tk_else,
	"switch":TokenType.tk_switch,
	"case":TokenType.tk_case,
	"while":TokenType.tk_while,
	"do":TokenType.tk_do,
	"for":TokenType.tk_for,
	"foreach":TokenType.tk_foreach,
	"new":TokenType.tk_new,
	
	"(":TokenType.tk_lparen,
	")":TokenType.tk_rparen,
	"{":TokenType.tk_lbrace,
	"}":TokenType.tk_rbrace,
	"[":TokenType.tk_lbracket,
	"]":TokenType.tk_rbracket,
	
	".":TokenType.tk_dot,
	",":TokenType.tk_comma,
	":":TokenType.tk_colon,
	";":TokenType.tk_semicolon,
	"$":TokenType.tk_dollar
];
//dfmt on
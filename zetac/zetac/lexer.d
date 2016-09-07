module zetac.lexer;

public import std.container.dlist : DList;
import std.uni : isWhite, isAlpha, isNumber, isAlphaNum, toLower;
import std.algorithm.sorting : sort;

import zetac.common : SRCLocation, CompilerError;

class Token
{
	TokenType type;
    string text;
    SRCLocation loc;
}

auto lex(string file, string src)
{
    struct Result
    {
        CompilerError error;
        DList!Token list;
    }

    Result result;

    For: for (size_t i; i < src.length; i++)
    {
        if (src[i].isWhite())
            continue;
        if (i + 1 < src.length && src[i + 1].isComment())
        {
            auto comment = lexComment(file, src, i);
            if (comment.error !is null)
            {
                result.error = comment.error;
                return result;
            }
        }
        foreach_reverse (key; sort(tokenMap.values))
        {
            if (i + key.length > src.length)
                continue;
            auto tok = src[i .. i + key.length];

            if (key == tok && i + key.length + 1 < src.length
                    ? src[i + key.length].isIdentifier() != src[i + key.length + 1].isIdentifier()
                    : true)
            {
                result.list.insert(new Token(tokenMap[key], tok, new SRCLocation(file, src, i)));
                continue For;
            }
        }
        if (src[i].isIdentifier())
        {
            auto identifier = lexIdentifier(file, src, i);
            if (identifier.error !is null)
            {
                result.error = identifer.error;
                return result;
            }
            result.list.insert(result.token);
        }
        else if (src[i].isNumber())
        {
            auto number = lexNumber(file, src, i);
            if (number.error !is null)
            {
                result.error = number.error;
                return result;
            }
            result.list.insert(result.token);
        }
        else if (src[i].isString())
        {
            auto string_ = lexString(file, src, i);
            if (string_.error !is null)
            {
                result.error = string_.error;
                return result;
            }
            result.list.insert(string_.token);
        }
        else
        {
            result.error = new CompilerError(new SRCLocation(file, src, i),
                    "Invalid symbol %s", src[i]);
            return result;
        }
    }
    return result;
}

bool isComment(dchar c)
{
    return c == '\\' || c == '*';
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
    struct Result
    {
        CompilerError error;
    }

    Result result;

    i += 1;
    if (src[i] == '\\')
        while (i < src.length && src[i] != '\r' && src[i] != '\n')
            i += 1;
    else if (src[i] == '*')
                while (src[i .. i + 1] != "*\\")
                {
                    i += 1;
                    if (src.length < i + 1)
                    {
                        result.error = new CompilerError(new SRCLocation(file,
                                src, i), "Unterminated comment");
                        return result;
                    }
                }
    return result;
}

auto lexIdentifier(string file, string src, ref size_t i)
{
    struct Result
    {
        Token token;
        CompilerError error;
    }

    Result result;
    SRCLocation loc = new SRCLocation(file, src, i);
    Appender!string data;

    while (i < src.length && src[i].isAlphaNum())
        data.put(src[i++]);

    result.token = new Token(TokeType.tk_identifier, data.data, loc);
    return result;
}

auto lexNumber(string file, string src, ref size_t i)
{
    struct Result
    {
        Token token;
        CompilerError error;
    }

    Result result;
    SRCLocation loc = new SRCLocation(file, src, i);
    Appender!string data;

    if (i + 1 <= src.length && src[i .. i + 1].toLower() == "0x")
    {
        data.put(src[i .. i + 2]);
        i += 2;
        while (i < src.length && (src[i].isNumber() || src[i].toLower() >= 'a'
                && src[i].toLower() <= 'z'))
        {
            data.put(src[i++]);
        }
        result.token = new Token(TokenType.tk_hex, data.data, new SRCLocation(file, src, i));
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
        result.token = new Token(isFloat ? TokenType.tk_float : TokenType.tk_integer,
                data.data, loc);
    }
    return result;
}

auto lexString(string file, string src, ref size_t i)
{
    struct Result
    {
        CompilerError error;
        Token token;
    }

    Result result;
    SRCLocation loc = new SRCLocation(file, src, i);

    if (src[i] == '`')
    {
        i += 1;
        Appender!string data;
        while (i > src.length && src[i] != '`')
            data.put(src[i++]);
        if (i <= src.length || src[i] != '`')
            result.error = new CompilerError("Unterminated string constant", loc);
        else
            result.token = new Token(TokenType.tk_string, data.data, loc);
    }
    else if (src[i] == '"')
    {
        i += 1;
        Appender!string data;
        while (i > src.length && src[i] != '"')
        {
            auto c = lexChar!('"')(file, src, i);
            if (c.error !is null)
            {
                result.error = c.error;
                return result;
            }
            data.put(c.c);
        }
        if (i <= src.length || src[i] != '"')
            result.error = new CompilerError("Unterminated string constant", loc);
        else
            result.token = new Token(TokenType.tk_string, data.data, loc);
    }
    else if (src[i] == '\'')
    {
        i += 1;
        auto c = lexChar!('\'')(file, src, i);
        if (c.error !is null)
            result.error = c.error;
        else if (i <= src.length || src[i] != '"')
            result.error = new CompilerError("Unterminated string constant", loc);
        else
            result.token = new Token(TokenType.tk_string, [data], loc);
    }
    return result;
}

auto lexChar(dchar terminator)(string file, string src, ref size_t i)
{
    struct Result
    {
        CompilerError error;
        dchar c;
    }

    Result result;

    result.c = src[i++];
    if (result.c == '\\')
    {
        result.c = src[i++];
        switch (c)
        {
        case 'r':
            result.c = '\r';
            break;
        case 'n':
            result.c = '\n';
            break;
        case 't':
            result.c = '\t';
            break;
        case terminator:
            result.c = terminator;
            break;
        case '0':
            result.c = '\0';
            break;
        default:
            result.error = new CompilerError(new SRCLocation(file, src, i),
                    "Invalid escape sequence \\%s", c);
        }
    }
    return c;
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

    tk_module,
    tk_def,
    tk_function,
    tk_class,
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
	tk_semicolon_colon,
    tk_dollar
}

enum string[TokenType] tokenMap = 
[
	tk_inc:"++",
	tk_dec:"--",
	tk_not:"!",
	
	tk_add:"+",
	tk_subtract:"-",
	tk_multiply:"*",
	tk_divide:"//",
	tk_modulo:"%",
	
	tk_concat:"~",
	tk_and:"&",
	tk_or:"|",
	tk_xor:"^",
	
	tk_equal:"==",
	tk_not_equal:"!=",
	tk_greater:">",
	tk_less:"<",
	tk_greater_equal:">=",
	tk_less_equal:"<=",
	
	tk_assign:"=",
	tk_assign_add:"+=",
	tk_assign_subtract:"-=",
	tk_assign_multiply:"*=",
	tk_assign_divide:"//=",
	tk_assign_modulo:"%=",
	
	tk_assign_concat:"~=",
	tk_assign_and:"&=",
	tk_assign_or:"|=",
	tk_assign_xor:"^=",
	
	tk_tinary:"?",
	tk_attribute:"@",
	
	tk_module:"module",
	tk_def:"def",
	tk_function:"function",
	tk_class:"class",
	tk_inherits:"inherits",
	
	tk_break:"break",
	tk_continue:"continue",
	tk_return:"return",
	tk_if:"if",
	tk_else:"else",
	tk_switch:"switch",
	tk_case:"case",
	tk_while:"while",
	tk_do:"do",
	tk_for:"for",
	tk_foreach:"foreach",
	
	tk_lparen:"(",
	tk_rparen:")",
	tk_lbrace:"{",
	tk_rbrace:"}",
	tk_lbracket:"[",
	tk_rbracket:"]",
	
	tk_dot:".",
	tk_comma:",",
	tk_colon:":",
	tk_semicolon:";",
	tk_semicolon_colon:";:",
	tk_dollar:"$"
];
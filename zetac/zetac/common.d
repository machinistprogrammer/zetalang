module zetac.common;

import std.string : splitLines;
import std.format : format;

import zetac.utils : getStackTrace;

class SRCLocation
{
    string file;
    size_t line, colunm;

    this(string file, string src, size_t i)
    {
        this.file;
        auto lines = src[0 .. i].splitLines();
        this.line = lines.length;
        this.colunm = lines[$ - 1].length;
    }

    override string toString()
    {
        return format("%s(%s,%s)", file, line, colunm);
    }
}

class CompilerError
{
    SRCLocation loc;
    string message;
    Throwable.TraceInfo trace;

    this(Args...)(SRCLocation loc, Args args)
    {
        this.loc;
        message = format(args);
        trace = getStackTrace();
    }

    override string toString()
    {
        return format("Error %s at %s", message, loc);
    }
}

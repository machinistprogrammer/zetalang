module zetac.common;

import std.string : splitLines;
import std.format : format;
import std.container.slist : SList;

import zetac.utils : getStackTrace;

class SRCLocation
{
    string file;
    size_t line, colunm;

    this(string file, string src, size_t i)
    {
        this.file = file;
        auto lines = src[0 .. i].splitLines();
        this.line = lines.length;
		this.colunm = line <= 0 ? 0 : lines[$ - 1].length;
    }

    override string toString()
    {
        return format("%s(%s,%s)", file, line, colunm);
    }
}

class CompilerError : Exception
{
    SRCLocation loc;

    this(Args...)(SRCLocation loc, string fmt, Args args)
    {
		super(format(fmt,args));
		this.loc = loc;
		this.info = getStackTrace();
    }

    override string toString()
    {
        return format("Error %s at %s", msg, loc);
    }
}

struct Stack(T)
{
	private SList!T stack;
	
	public void push(T value)
	{
		stack.stableInsertFront(value);
	}
	
	public T peek()
	{
		assert(!stack.empty);
		return (stack.front());
	}
	
	public T pop()
	{
		assert(!stack.empty);
		T Temp = stack.front();
		stack.stableRemoveFront();
		return Temp;
	}
	
	@property const bool empty()
	{
		return stack.empty();
	}
	
	public void unwind()
	{
		while(!empty)
		{
			pop();
		}
	}
}
module zetac.utils;

import core.runtime;
import std.traits : KeyType, ValueType, isAssociativeArray;

Throwable.TraceInfo getStackTrace()
{
    Throwable.TraceInfo traceInfo;
    version (Posix)
    {
        auto f(uint i)
        {
            if (i > 4)
                return f(i + 1);
            else
                return defaultTraceHandler();
        }

        traceInfo = f(1);
    }
    else
    {
        traceInfo = defaultTraceHandler();
    }
    return traceInfo;
}

auto flip(T)(T aarray) if (isAssociativeArray!T)
{
	KeyType!T[ValueType!T] result;
	foreach(k, v; aarray)
		result[v] = k;
	return result;
}
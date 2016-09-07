module zetac.utils;

import core.runtime;

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

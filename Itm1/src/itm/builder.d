module itm.builder;

import std.experimental.allocator;
import itm.types;

enum allocationBlockSize = 1024;

class ItmBuilder
{
    IAllocator allocator;
    uint[string] unlinked;
    uint[string] linked;
    void[] program_;
    uint pos;

    this(size_t amount = allocationBlockSize, IAllocator allocator = theAllocator)
    {
        this.allocator = allocator;
        this.program_ = this.allocator.allocate(amount);
    }

    void add(Args...)(lazy Args args)
    {
        foreach (i, Arg; Args)
        {
            import std.traits;

            static if (isArray!Arg)
            {
                auto arg = args[i];
                if (ArrayElementType!Arg * arg.length > program_.length)
                    resize(ArrayElementType!Arg * arg.length + allocationBlockSize);
                program_[pos .. pos += ArrayElementType!Arg * arg.length] = (cast(void*) args.ptr)[0
                    .. ArrayElementType!Arg * arg.length];
            }
            else
            {
                auto arg = args[i];
                if (Arg.sizeof > program_.length)
                    resize(Arg.sizeof + allocationBlockSize);
                program_[pos .. pos += Arg.sizeof] = (cast(void*)&arg)[0 .. Arg.sizeof];
            }
        }
    }

    uint refLink(string name)
    {
        auto ptr = name in linked;
        if (ptr !is null)
            return *ptr;
        else
            unlinked[name] = pos;
        return 0u;
    }

    void makeLabelLink(string name)
    {
        linked[name] = pos;
    }

    void makeLink(string name, uint value)
    {
        linked[name] = value;
    }

    void link()
    {
        foreach (name, linkPos; unlinked)
        {
            auto link = linked[name];
            *cast(uint*)(program_.ptr + linkPos) = link;
        }
        unlinked = null;
    }

    @property void[] program()
    {
        return program_[0 .. pos];
    }

    void resize(size_t amount)
    {
        if (!allocator.expand(program_, amount))
            allocator.reallocate(program_, amount + program_.length);
    }
}

public template ArrayElementType(T)
{
    alias ArrayElementType = typeof(T.init[0]);
}

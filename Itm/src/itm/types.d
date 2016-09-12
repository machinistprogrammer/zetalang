module itm.types;

import itm.vm : ItmThread;

enum ItmOpcode : ubyte
{
    mset = 1,
    mpush,
    mpeek,
    mpop,

    add,
    sub,
    mul,
    div,
    mod,
    
    pos,
    neg,
    inc,
    dec,
	
    eq,
    gr,
    le,
    gre,
    lee,

    lnot,
    land,
    lor,
    lxor,

    bnot,
    band,
    bor,
    bxor,

    jmp,
    jmc,

    call,
    ret,
    conv
}

enum ItmAddress : ubyte
{
    VGA = 1,
    VGB,
    VGC,
    VGD,
    VSP,
    VBP,
    VIC,
    VFC,
    PGA,
    PGB,
    PGC,
    PGD,
    PSP,
    PBP,
    PIC,
}

enum ItmBuiltinTypes : ushort
{
    int8 = 1,
    int16,
    int32,
    int64,
    float32,
    float64,
}

enum uint foreignFunctionBitmask = int.max;
enum uint defaultStackSize = 1024 * 1024 * 1024 * 2;

struct ItmValue
{
    ushort type;
    union
    {
        ubyte b;
        ushort s;
        uint i;
        ulong l;
        float f;
        float d;
        void* ptr;
    }
}

class ItmTypeRegistry
{
    ItmType[ushort] registry;

    this()
    {
        import itm.builtins;

        registerBuiltinTypes(this);
    }

    ushort register(ItmType type)
    {
        for (ushort id; id < ushort.max; id++)
        {
            if ((id in registry) is null)
            {
                registry[id] = type;
                type.onRegister(this, id);
                return id;
            }
        }
        throw new ItmException("Failed to register type");
    }

    void register(ItmType type, ushort id)
    {
        if ((id in registry) !is null)
            throw new ItmException("Failed to register type");
        registry[id] = type;
        type.onRegister(this, id);
    }

    ItmType getType(ushort id)
    {
        auto type = id in registry;
        if (type is null)
            throw new ItmException("Unknown type");
        return *type;
    }
}

interface ItmType
{
    void onRegister(ItmTypeRegistry registry, ushort id);

    void op_add(ItmValue* dst, ItmValue* src);
    void op_sub(ItmValue* dst, ItmValue* src);
    void op_mul(ItmValue* dst, ItmValue* src);
    void op_div(ItmValue* dst, ItmValue* src);
    void op_mod(ItmValue* dst, ItmValue* src);
    
    
    void op_pos(ItmValue* dst);
    void op_neg(ItmValue* dst);
    void op_inc(ItmValue* dst);
    void op_dec(ItmValue* dst);

    void op_eq(ItmValue* dst, ItmValue* src);
    void op_gr(ItmValue* dst, ItmValue* src);
    void op_le(ItmValue* dst, ItmValue* src);
    void op_gre(ItmValue* dst, ItmValue* src);
    void op_lee(ItmValue* dst, ItmValue* src);

    void op_lnot(ItmValue* dst);
    void op_land(ItmValue* dst, ItmValue* src);
    void op_lor(ItmValue* dst, ItmValue* src);
    void op_lxor(ItmValue* dst, ItmValue* src);

    void op_bnot(ItmValue* dst);
    void op_band(ItmValue* dst, ItmValue* src);
    void op_bor(ItmValue* dst, ItmValue* src);
    void op_bxor(ItmValue* dst, ItmValue* src);

    void op_conv(ItmValue* dst, ushort type);
}

class ItmForeignFunctionRegistry
{
    ItmFunction[uint] registry;

    this()
    {
        import itm.builtins;

        registerBuiltinFunctions(this);
    }

    uint register(uint id, ItmFunction func)
    {
        for (; id < uint.max; id++)
        {
            if ((id in registry) is null)
            {
                registry[id] = func;
                return id;
            }
        }
        throw new ItmException("Failed to register function");
    }

    void register(ItmFunction func, uint id)
    {
        if ((id in registry) !is null)
            throw new ItmException("Failed to register function");
        registry[id] = func;
    }

    void callFunction(uint id, ItmThread callee)
    {
        auto ptr = id in registry;
        if (ptr !is null)
            (*ptr)(callee);
        else
            throw new ItmException("Function dosen't exist");
    }
}

alias ItmFunction = void delegate(ItmThread thread);

class ItmException : Exception
{
    @nogc @safe pure nothrow this(string msg, string file = __FILE__,
            size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

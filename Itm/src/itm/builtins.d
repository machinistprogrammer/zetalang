module itm.builtins;

import itm.types;

enum ItmValue itmTrueValue = {b:
    1, type : ItmBuiltinTypes.int8};
enum ItmValue itmFalseValue = {b:
    0, type : ItmBuiltinTypes.int8};

void registerBuiltinTypes(ItmTypeRegistry registry)
{
    registry.register(new ItmIntegerType!"b"(), ItmBuiltinTypes.int8);
    registry.register(new ItmIntegerType!"s"(), ItmBuiltinTypes.int16);
    registry.register(new ItmIntegerType!"i"(), ItmBuiltinTypes.int32);
    registry.register(new ItmIntegerType!"l"(), ItmBuiltinTypes.int64);
}

void registerBuiltinFunctions(ItmForeignFunctionRegistry registry)
{

}

class ItmIntegerType(string suffix) : ItmType
{
    import std.format;

    ItmTypeRegistry registry;
    ushort type;

    void onRegister(ItmTypeRegistry registry, ushort id)
    {
        this.registry = registry;
        this.type = id;
    }

    void op_add(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s += src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s += v.%s;", suffix, suffix));
        }
    }

    void op_sub(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s -= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s -= v.%s;", suffix, suffix));
        }
    }

    void op_mul(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s *= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s *= v.%s;", suffix, suffix));
        }
    }

    void op_div(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s /= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s /= v.%s;", suffix, suffix));
        }
    }

    void op_mod(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s %%= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s %%= v.%s;", suffix, suffix));
        }
    }

    void op_pos(ItmValue* dst)
    {
        mixin(format("dst.%s = +dst.%s;", suffix, suffix));
    }

    void op_neg(ItmValue* dst)
    {
        mixin(format("dst.%s = -dst.%s;", suffix, suffix));
    }

    void op_inc(ItmValue* dst)
    {
        mixin(format("dst.%s++;", suffix));
    }

    void op_dec(ItmValue* dst)
    {
        mixin(format("dst.%s--;", suffix));
    }

    void op_eq(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s == src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s == src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_gr(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s > src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s > src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        }
    }

    void op_le(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s < src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s < src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        }
    }

    void op_gre(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s >= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s >= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lee(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s <= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s <= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lnot(ItmValue* dst)
    {
        mixin(format("*dst = dst.%s ? itmFalseValue : itmTrueValue;", suffix));
    }

    void op_land(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s && src.%s) ? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s && src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lor(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s || src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s || src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lxor(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s ^^ src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s ^^ src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_bnot(ItmValue* dst)
    {
        mixin(format("dst.%s = ~dst.%s ;", suffix, suffix));
    }

    void op_band(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s &= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s &= v.%s;", suffix, suffix));
        }
    }

    void op_bor(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s |= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s |= v.%s;", suffix, suffix));
        }
    }

    void op_bxor(ItmValue* dst, ItmValue* src)
    {

        if (src.type == this.type)
            mixin(format("dst.%s ^= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s ^= v.%s;", suffix, suffix));
        }
    }

    void op_conv(ItmValue* dst, ushort type)
    {
        if (type <= ItmBuiltinTypes.int64)
            dst.type = type;
        else if (type == ItmBuiltinTypes.float32)
        {
            dst.type = type;
            mixin(format("dst.f = cast(float)dst.%s;", suffix));
        }
        else if (type == ItmBuiltinTypes.float64)
        {
            dst.type = type;
            mixin(format("dst.d = cast(double)dst.%s;", suffix));
        }
        else
            throw new ItmException("Illegal cast");
    }
}

class ItmFloatType(string prefix) : ItmType
{
    import std.format;

    ItmTypeRegistry registry;
    ushort type;

    void onRegister(ItmTypeRegistry registry, ushort id)
    {
        this.registry = registry;
        this.type = id;
    }

    void op_add(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s += src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s += v.%s;", suffix, suffix));
        }
    }

    void op_sub(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s -= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s -= v.%s;", suffix, suffix));
        }
    }

    void op_mul(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s *= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s *= v.%s;", suffix, suffix));
        }
    }

    void op_div(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s /= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s /= v.%s;", suffix, suffix));
        }
    }

    void op_mod(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("dst.%s %= src.%s;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("dst.%s %= v.%s;", suffix, suffix));
        }
    }

    void op_pos(ItmValue* dst)
    {
        mixin(format("dst.%s = +dst.%s;", suffix, suffix));
    }

    void op_neg(ItmValue* dst)
    {
        mixin(format("dst.%s = -dst.%s;", suffix, suffix));
    }

    void op_inc(ItmValue* dst)
    {
        mixin(format("dst.%s++", suffix));
    }

    void op_dec(ItmValue* dst)
    {
        mixin(format("dst.%s--", suffix));
    }

    void op_eq(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s == src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s == src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_gr(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s > src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s > src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        }
    }

    void op_le(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s < src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s < src.%s)? itmTrueValue : itmFalseValue;", suffix, suffix));
        }
    }

    void op_gre(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s >= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s >= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lee(ItmValue* dst, ItmValue* src)
    {
        if (src.type == this.type)
            mixin(format("*dst = (dst.%s <= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        else
        {
            ItmValue v = *src;
            registry.getType(src.type).op_conv(&v, this.type);
            mixin(format("*dst = (dst.%s <= src.%s)? itmTrueValue : itmFalseValue;",
                    suffix, suffix));
        }
    }

    void op_lnot(ItmValue* dst)
    {
    }

    void op_land(ItmValue* dst, ItmValue* src)
    {
    }

    void op_lor(ItmValue* dst, ItmValue* src)
    {
    }

    void op_lxor(ItmValue* dst, ItmValue* src)
    {
    }

    void op_bnot(ItmValue* dst)
    {
    }

    void op_band(ItmValue* dst, ItmValue* src)
    {
    }

    void op_bor(ItmValue* dst, ItmValue* src)
    {
    }

    void op_bxor(ItmValue* dst, ItmValue* src)
    {
    }

    void op_conv(ItmValue* dst, ushort type)
    {
        if (type == ItmBuiltinTypes.int8)
        {
            dst.type = type;
            mixin(format("dst.b = cast(ubyte)dst.%s", suffix));
        }
        else if (type == ItmBuiltinTypes.int16)
        {
            dst.type = type;
            mixin(format("dst.s = cast(ushort)dst.%s", suffix));
        }
        else if (type == ItmBuiltinTypes.int32)
        {
            dst.type = type;
            mixin(format("dst.i = cast(uint)dst.%s", suffix));
        }
        else if (type == ItmBuiltinTypes.int64)
        {
            dst.type = type;
            mixin(format("dst.f = cast(ulong)dst.%s", suffix));
        }
        else if (type == ItmBuiltinTypes.float32)
        {
            dst.type = type;
            mixin(format("dst.f = cast(float)dst.%s", suffix));
        }
        else if (type == ItmBuiltinTypes.float64)
        {
            dst.type = type;
            mixin(format("dst.d = cast(double)dst.%s", suffix));
        }
        else
            throw new ItmException("Illegal cast");
    }
}

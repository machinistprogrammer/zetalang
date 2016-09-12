module itm.vm;

import itm.types;

import std.exception;

alias ItmThread = ItmVirtualMachine.ItmThread;
class ItmVirtualMachine
{
    ItmTypeRegistry typeRegistry;
    ItmForeignFunctionRegistry functionRegistry;
    ubyte[] program;
    ItmThread[] threadPool;
    size_t currentTid;

    this(ubyte[] program, size_t startAddress = 0, size_t stackSize = defaultStackSize)
    {
        this.program = program;
        this.typeRegistry = new ItmTypeRegistry();
        this.functionRegistry = new ItmForeignFunctionRegistry();
        this.createThread(startAddress, stackSize);
    }

    void executeNextThreadInstruction()
    {
        if (currentTid > threadPool.length)
            currentTid = 0;
        threadPool[currentTid].executeNextInstruction();
        currentTid++;
    }

    ItmThread createThread(size_t startAddress, size_t stackSize = defaultStackSize)
    {
        auto result = new ItmThread(threadPool.length, startAddress, stackSize);
        threadPool ~= result;
        return result;
    }

    class ItmThread
    {
        size_t cp, tid;
        ItmValue a, b, c, d, sp, bp;
        ItmValue literal;
        ItmValue[] stack;

        this(size_t tid, size_t startAddress, size_t stackSize)
        {
            this.tid = tid;
            this.cp = startAddress;
            this.stack = new ItmValue[](stackSize);
        }

        T decode(T)()
        {
            T t = *cast(T*)(program.ptr + cp);
            cp += t.sizeof;
            return t;
        }

        ItmValue* decodeNextAddress()
        {
            switch (program[cp++]) with (ItmAddress)
            {
            case VGA:
                return &a;
            case VGB:
                return &b;
            case VGC:
                return &c;
            case VGD:
                return &d;
            case VSP:
                return &sp;
            case VBP:
                return &bp;
            case PGA:
                enforce!ItmException(a.type == ItmBuiltinTypes.int32, "A register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[a.i + offset];
            case PGB:
                enforce!ItmException(b.type == ItmBuiltinTypes.int32, "B register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[b.i + offset];
            case PGC:
                enforce!ItmException(c.type == ItmBuiltinTypes.int32, "C register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[c.i + offset];
            case PGD:
                enforce!ItmException(d.type == ItmBuiltinTypes.int32, "D register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[d.i + offset];
            case PSP:
                enforce!ItmException(sp.type == ItmBuiltinTypes.int32,
                        "Stack register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[sp.i + offset];
            case PBP:
                enforce!ItmException(bp.type == ItmBuiltinTypes.int32,
                        "Base register in wrong mode");
                ubyte offset = decode!byte();
                return &stack[bp.i + offset];
            case PIC:
                auto address = decode!uint();
                return &stack[address];
            default:
                throw new ItmException("Illegal address");
            }
        }

        ItmValue* decodeNextOperand()
        {
            if (program[cp] == ItmAddress.VIC)
            {
                cp++;
                literal.i = decode!uint();
                literal.type = ItmBuiltinTypes.int32;
                return &literal;
            }
            else if (program[cp] == ItmAddress.VFC)
            {
                cp++;
                literal.f = decode!float();
                literal.type = ItmBuiltinTypes.float32;
                return &literal;
            }
            else
                return decodeNextAddress();
        }

        void executeNextInstruction()
        {
            switch (program[cp++]) with (ItmOpcode)
            {
            case mset:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                *dst = *src;
                break;
            case mpush:
                auto src = decodeNextOperand();
                enforce!ItmException(sp.type == ItmBuiltinTypes.int32,
                        "Stack register in wrong mode");
                stack[sp.i++] = *src;
                break;
            case mpeek:
                auto dst = decodeNextAddress();
                enforce!ItmException(sp.type == ItmBuiltinTypes.int32,
                        "Stack register in wrong mode");
                *dst = stack[sp.i];
                break;
            case mpop:
                auto dst = decodeNextAddress();
                enforce!ItmException(sp.type == ItmBuiltinTypes.int32,
                        "Stack register in wrong mode");
                *dst = stack[sp.i];
                sp.i--;
                break;
            case add:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_add(dst, src);
                break;
            case sub:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_sub(dst, src);
                break;
            case mul:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_mul(dst, src);
                break;
            case div:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_div(dst, src);
                break;
            case mod:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_mod(dst, src);
                break;
            case pos:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_pos(dst);
                break;
            case neg:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_neg(dst);
                break;
            case inc:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_inc(dst);
                break;
            case dec:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_dec(dst);
                break;
            case eq:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_eq(dst, src);
                break;
            case gr:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_gr(dst, src);
                break;
            case le:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_le(dst, src);
                break;
            case gre:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_gre(dst, src);
                break;
            case lee:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_lee(dst, src);
                break;
            case lnot:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_lnot(dst);
                break;
            case land:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_land(dst, src);
                break;
            case lor:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_lor(dst, src);
                break;
            case lxor:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_lxor(dst, src);
                break;
            case bnot:
                auto dst = decodeNextAddress();
                typeRegistry.getType(dst.type).op_bnot(dst);
                break;
            case band:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_band(dst, src);
                break;
            case bor:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_bor(dst, src);
                break;
            case bxor:
                auto dst = decodeNextAddress();
                auto src = decodeNextOperand();
                typeRegistry.getType(dst.type).op_bxor(dst, src);
                break;
            case jmp:
                auto src = decodeNextOperand();
                cp = src.i;
                break;
            case jmc:
                auto src = decodeNextOperand();
                auto cond = decodeNextOperand();
                if (cond.b > 0)
                    cp = src.i;
                break;
            case call:
                auto src = decodeNextOperand();
                enforce!ItmException(sp.type == ItmBuiltinTypes.int32,
                        "Stack register in wrong mode");
                if ((src.i & foreignFunctionBitmask) == foreignFunctionBitmask)
                {
                    auto funcId = (~foreignFunctionBitmask) & src.i;
                    functionRegistry.callFunction(funcId, this);
                }
                stack[sp.i].i = cp;
                stack[sp.i++].type = ItmBuiltinTypes.int32;
                cp = src.i;
                break;
            case ret:
                auto src = stack[sp.i--];
                cp = src.i;
                break;
            case conv:
                auto dst = decodeNextOperand();
                auto type = decode!ushort();
                typeRegistry.getType(dst.type).op_conv(dst, type);
                break;
            default:
                throw new ItmException("Illegal instruction");
            }
        }
    }
}

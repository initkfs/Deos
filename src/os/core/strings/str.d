/**
 * Authors: initkfs
 */
module os.core.strings.str;

import os.core.errors;

immutable
{
    string strEmpty = "";
    string strFormatError = "_formaterror_";
    char strNullByte = '\0';
    size_t strBuffSize = 256;
}

import std.traits : isSomeChar;

bool isEqual(T)(const(T)[] s1, const(T)[] s2) if (isSomeChar!T)
{
    import MemCore = os.core.mem.mem_core;

    return MemCore.memeqs(s1, s2);
}

unittest
{
    assert(isEqual("", ""));
    assert(isEqual(" ", " "));
    assert(!isEqual("", " "));
    assert(!isEqual(" ", ""));
    assert(!isEqual(null, ""));
    assert(!isEqual("", null));
    assert(!(isEqual!char(null, null)));

    assert(isEqual("a", "a"));
    assert(isEqual("foo bar", "foo bar"));
    assert(!isEqual("a", "A"));

    assert(isEqual(cast(string)['a'], cast(string)['a']));
}

bool isEqual(T)(T s1, const(T)[] s2) if (isSomeChar!T)
{
    if (s2.length != 1)
    {
        return false;
    }

    return s1 == s2[0];
}

bool isEmpty(T)(const(T)[] str) if (isSomeChar!T)
{
    return str.length == 0;
}

unittest
{
    assert(isEmpty(""));
}

bool isEmptyz(T)(const T* str) if (isSomeChar!T)
{
    return strlenz(str) == 0;
}

unittest
{
    assert(isEmptyz("".ptr));
}

bool isBlank(T)(const(T)[] str) if (isSomeChar!T)
{
    import Ascii = os.core.strings.ascii;

    if (!str || str.length == 0)
    {
        return true;
    }

    foreach (ch; str)
    {
        if (!Ascii.isSpace(ch))
        {
            return false;
        }
    }

    return true;
}

unittest
{
    //assert(isBlank(null));
    assert(isBlank(""));
    assert(isBlank(" "));
    assert(isBlank(" \n \t  \t "));
    assert(!isBlank("  a  "));
}

size_t strlenz(T)(const T* str) if (isSomeChar!T)
{
    if (!str)
    {
        return 0;
    }

    //TODO add length limit
    size_t lengthIndex;
    while (str[lengthIndex] != strNullByte)
    {
        if (lengthIndex == size_t.max)
        {
            import os.core.errors;

            panic("Overflow string length");
        }

        lengthIndex++;
    }

    return lengthIndex;
}

unittest
{
    assert(strlenz!char(null) == 0);
    assert(strlenz("".ptr) == 0);
    assert(strlenz(" ".ptr) == 1);
    assert(strlenz("a".ptr) == 1);
    assert(strlenz("aaa".ptr) == 3);
    assert(strlenz("a b c".ptr) == 5);
}

C[] ttoa(T, C = char)(T targetValue, C[] buff, const size_t base = 10)
        if (__traits(isIntegral, T) && isSomeChar!C)
{
    if (buff.length < 2)
    {
        panic("Buffer size must be equal or greater than 2 to convert any number to string ");
    }

    if (base == 0)
    {
        panic("Number base must not be 0");
    }

    if (targetValue == 0)
    {
        buff[0] = '0';
        return buff[0 .. 1];
    }

    //TODO hex min value, etc
    if (targetValue == T.min)
    {
        enum minStr = T.min.stringof;
        if (minStr.length <= buff.length)
        {
            buff[] = minStr;
            return buff[0 .. minStr.length];
        }
        else
        {
            enum minDefault = "-0";
            buff[] = minDefault;
            return buff[0 .. minDefault.length];
        }
    }

    immutable C[16] alphabet = "0123456789ABCDEF";

    auto value = targetValue;
    immutable isNeg = value < 0;
    if (isNeg)
    {
        value = -value;
    }

    size_t index = buff.length - 1;
    while (value && index)
    {
        buff[index] = alphabet[value % base];
        value /= base;
        --index;
    }

    if (isNeg)
    {
        buff[index] = '-';
    }
    else
    {
        index++;
    }
    //TODO it would be useful to reset the buffer in case of insufficient capacity
    return buff[index .. $];
}

char[] atoa(int value, char[] buff, const size_t base = 10)
{
    return ttoa(value, buff, base);
}

//TODO compiler-rt
static if (size_t.sizeof >= long.sizeof)
{
    char[] ltoa(long value, char[] buff, const size_t base = 10)
    {
        return ttoa(value, buff, base);
    }
}

unittest
{
    import os.core.io.cstdio;

    char[64] buff = 0;

    //Decimal
    auto sd = atoa(0, buff);
    assert(isEqual(sd, "0"));
    assert(sd.length == 1);

    auto negZero = atoa(-0, buff);
    assert(isEqual(negZero, "0"));
    assert(negZero.length == 1);

    auto sd1 = atoa(1, buff);
    assert(isEqual(sd1, "1"));
    assert(sd1.length == 1);

    auto sdneg1 = atoa(-1, buff);
    assert(isEqual(sdneg1, "-1"));

    auto sd101 = atoa(101, buff);
    assert(isEqual(sd101, "101"));

    auto sd101neg = atoa(-101, buff);
    assert(isEqual(sd101neg, "-101"));

    auto sd100x = atoa(10_000_000, buff);
    assert(isEqual(sd100x, "10000000"));

    auto sd64x = atoa(648_356, buff);
    assert(isEqual(sd64x, "648356"));

    auto sdmax = atoa(int.max, buff);
    assert(isEqual(sdmax, "2147483647"));

    auto sdmin = atoa(int.min, buff);
    assert(isEqual(sdmin, "-2147483648"));

    //Negative tests
    char[2] minBuff = 0;
    auto minMin = atoa(int.min, minBuff);
    assert(isEqual(minMin, "-0"));

    auto numOverflow = atoa(1234, minBuff);
    assert(isEqual(numOverflow, "4"));

    auto numNegOverflow = atoa(-1234, minBuff);
    assert(isEqual(numNegOverflow, "-4"));

    //Bin
    enum binBase = 2;
    auto binZero = atoa(0, buff, binBase);
    assert(isEqual(binZero, "0"));

    auto binOne = atoa(1, buff, binBase);
    assert(isEqual(binOne, "1"));

    auto bin2 = atoa(2, buff, binBase);
    assert(isEqual(bin2, "10"));

    auto bin10 = atoa(10, buff, binBase);
    assert(isEqual(bin10, "1010"));

    auto bin10neg = atoa(-10, buff, binBase);
    assert(isEqual(bin10neg, "-1010"));

    auto bin64x = atoa(648356, buff, binBase);
    assert(isEqual(bin64x, "10011110010010100100"));

    //Hex
    enum hexBase = 16;
    auto hZero = atoa(0, buff, hexBase);
    assert(isEqual(hZero, "0"));

    auto hOne = atoa(1, buff, hexBase);
    assert(isEqual(hOne, "1"));

    auto hOneNeg = atoa(-1, buff, hexBase);
    assert(isEqual(hOneNeg, "-1"));

    auto h10 = atoa(10, buff, hexBase);
    assert(isEqual(h10, "A"));

    auto h4573 = atoa(4573, buff, hexBase);
    assert(isEqual(h4573, "11DD"));

    auto h0x7f = atoa(int.max, buff, hexBase);
    assert(isEqual(h0x7f, "7FFFFFFF"));

    auto h0x7fMin = atoa(int.min, buff, hexBase);
    //TODO correct hex min value
    assert(isEqual(h0x7fMin, "-2147483648"));

    //Long
    static if (size_t.sizeof >= long.sizeof)
    {
        auto lMax = ltoa(long.max, buff);
        assert(isEqual(lMax, "9223372036854775807"));

        auto lMin = ltoa(long.min, buff);
        //TODO cast
        assert(isEqual(lMin, "cast(long)-9223372036854775808"));
    }
}

B[] transform(T, B)(const(T)[] str, B[] buff, scope T delegate(T) onChar)
        if (isSomeChar!T && isSomeChar!B)
{
    if (!onChar)
    {
        panic("Transform delegate must not be null");
    }

    if (buff.length == 0)
    {
        panic("Buffer length must be greater than zero");
    }

    if (str.length == 0)
    {
        buff[0] = strNullByte;
        return buff[0 .. 1];
    }

    size_t buffLength;
    foreach (i, ch; str)
    {
        if (i >= buff.length)
        {
            panic("Buffer index is greater than receiver capacity");
        }

        buff[i] = onChar ? onChar(ch) : ch;

        buffLength++;
    }

    return buff[0 .. buffLength];
}

unittest
{
    char[64] buff = 0;
    assert(isEqual('\0', transform("", buff, (char ch) => ch)));
    assert(isEqual("HELLO", transform("hello", buff, (char ch) => cast(char)(ch - 32))));
}

B[] toLower(T, B)(const(T)[] str, B[] buff) if (isSomeChar!T && isSomeChar!B)
{
    return transform!(T, B)(str, buff, (T ch) {
        if (ch >= 'A' && ch <= 'Z')
        {
            return cast(char)(ch + 32);
        }
        return ch;
    });
}

unittest
{
    char[64] buff = 0;
    assert(isEqual("foobar", toLower("foobar", buff)));
    assert(isEqual("foobar", toLower("FooBar", buff)));
    assert(isEqual("foobar", toLower("FOOBAR", buff)));
}

B[] toUpper(T, B)(const(T)[] str, B[] buff) if (isSomeChar!T && isSomeChar!B)
{
    return transform!(T, B)(str, buff, (T ch) {
        if (ch >= 'a' && ch <= 'z')
        {
            return cast(char)(ch - 32);
        }
        return ch;
    });
}

unittest
{
    char[64] buff = 0;
    assert(isEqual("FOOBAR", toUpper("foobar", buff)));
    assert(isEqual("FOOBAR", toUpper("FooBar", buff)));
    assert(isEqual("FOOBAR", toUpper("FOOBAR", buff)));
}

T[] reverse(T, B)(const(T)[] str, B[] buff) if (isSomeChar!T && isSomeChar!B)
{
    if (buff.length == 0)
    {
        panic("Buffer length must not be 0");
    }

    if(str.length == 0){
        buff[0] = strNullByte;
        return buff[0..1];
    }

    size_t bufferLength;
    size_t strLength = str.length;
    foreach_reverse (i, ch; str)
    {
        if (i >= buff.length)
        {
            panic("Buffer overflow");
        }
        buff[strLength - i - 1] = ch;
        bufferLength++;
    }

    return buff[0 .. bufferLength];
}

unittest
{
    char[64] buff = 0;
    assert(isEqual('\0', reverse("", buff)));
    assert(isEqual("raboof", reverse("foobar", buff)));
}

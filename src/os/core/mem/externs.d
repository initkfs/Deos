/**
 * Authors: initkfs
 */
module os.core.mem.externs;

import MemCore = os.core.mem.mem_core;

extern (C) int memcmp(const void* dest, const void* src, size_t len)
{
    return MemCore.memcmp(dest, src, len);
}

extern (C) void* memcpy(void* dest, const void* src, size_t len)
{
    return MemCore.memcpy(dest, src, len);
}

extern (C) void* memset(void* dest, ubyte c, size_t len)
{
    return MemCore.memset(dest, c, len);
}

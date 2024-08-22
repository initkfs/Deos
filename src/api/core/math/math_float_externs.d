/**
 * Authors: initkfs
 */
module api.core.math.math_float_externs;

extern (C):

version (LDC)
{
    pragma(LDC_intrinsic, "llvm.sqrt.f#")
    T _sqrt(T)(T value);

    pragma(LDC_intrinsic, "llvm.sin.f#")
    T _sin(T)(T value);

    pragma(LDC_intrinsic, "llvm.cos.f#")
    T _cos(T)(T value);

    pragma(LDC_intrinsic, "llvm.fabs.f#")
    T _fabs(T)(T value);
}

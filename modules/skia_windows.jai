#import "Basic";
#import "Math";
#import "Windows";

libskia :: #library "skia";  // Jai appends .dll automatically

std :: struct {
    unique_ptr :: struct(T: Type, Deleter: Type=void) {
        ptr: *T;
    }
    array :: struct(T: Type, N: int) {
        data: [N] T;
    }
    false_type :: struct {}
    true_type :: struct {}
    integral_constant__RAW :: struct {}
    atomic :: struct(T: Type) { value: T; }
    byte :: u8;
    shared_ptr :: struct(T: Type) { ptr: *T; }
    optional :: struct(T: Type) { value: T; has_value: bool; }
    vector :: struct(T: Type) { ptr: *T; count: int; }
    tuple :: struct(T1: Type, T2: Type=void, T3: Type=void) {
        v1: T1;
        #if T2 != void { v2: T2; }
        #if T3 != void { v3: T3; }
    }
    String :: struct {}
    String_view :: struct {}
}

va_list :: *void;
FILE :: *void;  // Windows FILE handle
SK_FloatInfinity :: FLOAT32_INFINITY;

UnknownTemplateArgumentPlaceholder :: void;
PlaceholderForUnsupportedArgument :: void;
enable_if_t :: struct(T: Type) {};

// =============================================================================
// sk_sp<T> FFI Helpers
// =============================================================================
//
// WARNING: Functions that take sk_sp<T> by value have broken FFI semantics.
// The value gets corrupted when passed from Jai to C++ due to ABI differences
// in how single-pointer structs are passed (registers vs stack).
//
// Use the *_safe wrapper functions or manually set fPtr fields instead.
// =============================================================================

// Reference counting helpers for sk_sp (ref/unref are inlined in C++ headers)
libskia_ref_helper :: #library "skia_ref_helper";
sk_ref_cnt_ref :: (ptr: *void) -> void #foreign libskia_ref_helper;
sk_ref_cnt_unref :: (ptr: *void) -> void #foreign libskia_ref_helper;
sk_ref_cnt_get_count :: (ptr: *void) -> s32 #foreign libskia_ref_helper;

// Helper to increment reference count for any SkRefCnt-derived type
sk_sp_ref :: (sp: *$T/sk_sp) {
    if sp.fPtr {
        sk_ref_cnt_ref(sp.fPtr);
    }
}

// Helper to decrement reference count for any SkRefCnt-derived type
sk_sp_unref :: (sp: *$T/sk_sp) {
    if sp.fPtr {
        sk_ref_cnt_unref(sp.fPtr);
        sp.fPtr = null;
    }
}

// Helper to reset an sk_sp to a new pointer (handles refcounting)
sk_sp_reset :: (sp: *$T/sk_sp, new_ptr: *T.element_type) {
    old_ptr := sp.fPtr;
    sp.fPtr = new_ptr;
    if new_ptr {
        sk_ref_cnt_ref(new_ptr);
    }
    if old_ptr {
        sk_ref_cnt_unref(old_ptr);
    }
}

// =============================================================================
// SkFont Safe Wrappers (work around sk_sp by-value ABI issue)
// =============================================================================

SkFont_make :: (typeface: *SkTypeface, size: SkScalar) -> SkFont {
    font: SkFont;
    SkFont.Constructor(*font);
    SkFont.setSize(*font, size);
    SkFont_setTypeface_safe(*font, typeface);
    return font;
}

SkFont_make :: (typeface: *SkTypeface, size: SkScalar, scaleX: SkScalar, skewX: SkScalar) -> SkFont {
    font: SkFont;
    SkFont.Constructor(*font);
    SkFont.setSize(*font, size);
    SkFont.setScaleX(*font, scaleX);
    SkFont.setSkewX(*font, skewX);
    SkFont_setTypeface_safe(*font, typeface);
    return font;
}

SkFont_setTypeface_safe :: (font: *SkFont, typeface: *SkTypeface) {
    if typeface {
        sk_ref_cnt_ref(typeface);
    }
    if font.fTypeface.fPtr {
        sk_ref_cnt_unref(font.fTypeface.fPtr);
    }
    font.fTypeface.fPtr = typeface;
}

SkFont_destroy :: (font: *SkFont) {
    if font.fTypeface.fPtr {
        sk_ref_cnt_unref(font.fTypeface.fPtr);
        font.fTypeface.fPtr = null;
    }
}

// =============================================================================
// Custom Font Manager Creation (Windows mangled symbols)
// =============================================================================
// NOTE: These need Windows-specific mangled symbol names.
// They will be added once we verify the exact symbols exported from skia.dll


//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



SK_BUILD_FOR_WIN :: 1;
SK_CPU_X86 :: 1;

SK_CPU_SSE_LEVEL_SSE1 :: 10;
SK_CPU_SSE_LEVEL_SSE2 :: 20;
SK_CPU_SSE_LEVEL_SSE3 :: 30;
SK_CPU_SSE_LEVEL_SSSE3 :: 31;
SK_CPU_SSE_LEVEL_SSE41 :: 41;
SK_CPU_SSE_LEVEL_SSE42 :: 42;
SK_CPU_SSE_LEVEL_AVX :: 51;
SK_CPU_SSE_LEVEL_AVX2 :: 52;
SK_CPU_SSE_LEVEL_SKX :: 60;

SK_CPU_LSX_LEVEL_LSX :: 70;
SK_CPU_LSX_LEVEL_LASX :: 80;

SK_CPU_SSE_LEVEL :: SK_CPU_SSE_LEVEL_SSE2;

SKIA_IMPLEMENTATION :: 0;

SK_DUMP_LINE_FORMAT :: "%s(%d)";

SK_R32_SHIFT :: 16;

SK_B32_SHIFT :: 16-SK_R32_SHIFT;

SK_G32_SHIFT :: 8;
SK_A32_SHIFT :: 24;

SK_ALLOW_STATIC_GLOBAL_INITIALIZERS :: 0;

SK_GAMMA_EXPONENT :: 0.0;

SK_GAMMA_CONTRAST :: 0.5;

SK_HISTOGRAMS_ENABLED :: 0;

GR_CACHE_STATS :: 1;

GR_GPU_STATS :: 1;

SK_Scalar1 :: 1.0;
SK_ScalarHalf :: 0.5;
SK_ScalarSqrt2 :: SK_FloatSqrt2;
SK_ScalarPI :: SK_FloatPI;
SK_ScalarTanPIOver8 :: 0.414213562;
SK_ScalarRoot2Over2 :: 0.707106781;
SK_ScalarMax :: 3.402823466e+38;
SK_ScalarMin :: -SK_ScalarMax;

SK_ScalarNegativeInfinity :: SK_FloatNegativeInfinity;

SK_ScalarNearlyZero :: SK_Scalar1 / (1 << 12);

SK_ScalarSinCosNearlyZero :: SK_Scalar1 / (1 << 16);

SK_INIT_TO_AVOID_WARNING :: 0;

SK_Fixed1 :: 1 << 16;
SK_FixedHalf :: 1 << 15;
SK_FixedQuarter :: 1 << 14;
SK_FixedMax :: 0x7FFFFFFF;
SK_FixedMin :: -SK_FixedMax;
SK_FixedPI :: 0x3243F;
SK_FixedSqrt2 :: 92682;
SK_FixedTanPIOver8 :: 0x6A0A;
SK_FixedRoot2Over2 :: 0xB505;

SkFixed3232Max :: SK_MaxS64;
SkFixed3232Min :: -SkFixed3232Max;

SkDebugf :: (format: *u8, __args: ..Any) -> void #foreign libskia "?SkDebugf@@YAXQEBDZZ";

/** Called internally if we hit an unrecoverable error.
The platform implementation must not return, but should either throw
an exception or otherwise exit.
*/
sk_abort_no_print :: () -> void #foreign libskia "?sk_abort_no_print@@YAXXZ";

sk_print_index_out_of_bounds :: (i: u64, size: u64) -> void #foreign libskia "?sk_print_index_out_of_bounds@@YAX_K0@Z";

sk_print_length_too_big :: (i: u64, size: u64) -> void #foreign libskia "?sk_print_length_too_big@@YAX_K0@Z";

sk_collection_not_empty :: (empty: bool) -> void #foreign libskia "?sk_collection_not_empty@@YAX_N@Z";

sk_print_size_too_big :: (size: u64, maxSize: u64) -> void #foreign libskia "?sk_print_size_too_big@@YAX_K0@Z";

/** 32 bit integer to hold a unicode value
*/
SkUnichar :: s32;

/** 16 bit unsigned integer to hold a glyph index
*/
SkGlyphID :: u16;

/** The generation IDs in Skia reserve 0 has an invalid marker.
*/
SK_InvalidGenID: u32 : 0;

/** The unique IDs in Skia reserve 0 has an invalid marker.
*/
SK_InvalidUniqueID: u32 : 0;

SkPathFillType :: enum u8 {
    Winding        :: 0;

    EvenOdd        :: 1;

    InverseWinding :: 2;

    InverseEvenOdd :: 3;

    Default        :: 0;

    kWinding        :: Winding;

    kEvenOdd        :: EvenOdd;

    kInverseWinding :: InverseWinding;

    kInverseEvenOdd :: InverseEvenOdd;

    kDefault        :: Default;
}

// SkPathFillType_IsEvenOdd :: (ft: SkPathFillType) -> bool #foreign libskia "?SkPathFillType_IsEvenOdd@@YA_NW4SkPathFillType@@@Z";

// SkPathFillType_IsInverse :: (ft: SkPathFillType) -> bool #foreign libskia "?SkPathFillType_IsInverse@@YA_NW4SkPathFillType@@@Z";

// SkPathFillType_ToggleInverse :: (ft: SkPathFillType) -> SkPathFillType #foreign libskia "?SkPathFillType_ToggleInverse@@YA?AW4SkPathFillType@@W41@@Z";

// SkPathFillType_ConvertToNonInverse :: (ft: SkPathFillType) -> SkPathFillType #foreign libskia "?SkPathFillType_ConvertToNonInverse@@YA?AW4SkPathFillType@@W41@@Z";

SkPathDirection :: enum u8 {
    CW      :: 0;

    CCW     :: 1;

    Default :: 0;

    kCW      :: CW;

    kCCW     :: CCW;

    kDefault :: Default;
}

SkPathSegmentMask :: enum s32 {
    Line_SkPathSegmentMask  :: 1;
    Quad_SkPathSegmentMask  :: 2;
    Conic_SkPathSegmentMask :: 4;
    Cubic_SkPathSegmentMask :: 8;

    kLine_SkPathSegmentMask  :: Line_SkPathSegmentMask;
    kQuad_SkPathSegmentMask  :: Quad_SkPathSegmentMask;
    kConic_SkPathSegmentMask :: Conic_SkPathSegmentMask;
    kCubic_SkPathSegmentMask :: Cubic_SkPathSegmentMask;
}

SkPathVerb :: enum u8 {
    Move      :: 0;
    Line      :: 1;
    Quad      :: 2;
    Conic     :: 3;
    Cubic     :: 4;
    Close     :: 5;

    Last_Verb :: 5;

    kMove      :: Move;
    kLine      :: Line;
    kQuad      :: Quad;
    kConic     :: Conic;
    kCubic     :: Cubic;
    kClose     :: Close;

    kLast_Verb :: Last_Verb;
}

/** Fast type for unsigned 8 bits. Use for parameter passing and local
variables, not for storage
*/
U8CPU :: u32;

/** Fast type for unsigned 16 bits. Use for parameter passing and local
variables, not for storage
*/
U16CPU :: u32;

// Max Signed 16 bit value
SK_MaxS16: s16 : S16_MAX;
SK_MinS16: s16 : -SK_MaxS16;

SK_MaxS32: s32 : S32_MAX;
SK_MinS32: s32 : -SK_MaxS32;
SK_NaN32: s32 : S32_MIN;

SK_MaxS64: s64 : S64_MAX;
SK_MinS64: s64 : -SK_MaxS64;

// Handy util that can be passed two ints, and will automatically promote to
// 64bits before the multiply, so the caller doesn't have to remember to cast
// e.g. (int64_t)a * b;
// sk_64_mul :: (a: s64, b: s64) -> s64 #foreign libskia "?sk_64_mul@@YA_J_J0@Z";

// SkLeftShift :: (value: s32, shift: s32) -> s32 #foreign libskia "?SkLeftShift@@YAHHH@Z";

// SkLeftShift :: (value: s64, shift: s32) -> s64 #foreign libskia "?SkLeftShift@@YA_J_JH@Z";

/**
*  Return a*b/((1 << shift) - 1), rounding any fractional bits.
*  Only valid if a and b are unsigned and <= 32767 and shift is > 0 and <= 8
*/
// SkMul16ShiftRound :: (a: U16CPU, b: U16CPU, shift: s32) -> u32 #foreign libskia "?SkMul16ShiftRound@@YAIIIH@Z";

/**
*  Return a*b/255, rounding any fractional bits.
*  Only valid if a and b are unsigned and <= 32767.
*/
// SkMulDiv255Round :: (a: U16CPU, b: U16CPU) -> U8CPU #foreign libskia "?SkMulDiv255Round@@YAIII@Z";

SK_FloatSqrt2: float : 1.414214;
SK_FloatPI: float : 3.141593;
SK_DoublePI: float64 : 3.141593;

// sk_float_sgn :: (x: float) -> s32 #foreign libskia "?sk_float_sgn@@YAHM@Z";

// sk_float_degrees_to_radians :: (degrees: float) -> float #foreign libskia "?sk_float_degrees_to_radians@@YAMM@Z";

// sk_float_radians_to_degrees :: (radians: float) -> float #foreign libskia "?sk_float_radians_to_degrees@@YAMM@Z";

SK_MaxS32FitsInFloat: s32 : 2147483520;
SK_MinS32FitsInFloat: s32 : -SK_MaxS32FitsInFloat;

// 0x7fffff8000000000
SK_MaxS64FitsInFloat: s64 : SK_MaxS64 >> (63 - 24) << (63 - 24);
SK_MinS64FitsInFloat: s64 : -SK_MaxS64FitsInFloat;

/**
*  Return the closest int for the given float. Returns SK_MaxS32FitsInFloat for NaN.
*/
// sk_float_saturate2int :: (x: float) -> s32 #foreign libskia "?sk_float_saturate2int@@YAHM@Z";

/**
*  Return the closest int for the given double. Returns SK_MaxS32 for NaN.
*/
// sk_double_saturate2int :: (x: float64) -> s32 #foreign libskia "?sk_double_saturate2int@@YAHN@Z";

/**
*  Return the closest int64_t for the given float. Returns SK_MaxS64FitsInFloat for NaN.
*/
// sk_float_saturate2int64 :: (x: float) -> s64 #foreign libskia "?sk_float_saturate2int64@@YA_JM@Z";

// Cast double to float, ignoring any warning about too-large finite values being cast to float.
// Clang thinks this is undefined, but it's actually implementation defined to return either
// the largest float or infinity (one of the two bracketing representable floats).  Good enough!
// sk_double_to_float :: (x: float64) -> float #foreign libskia "?sk_double_to_float@@YAMN@Z";

SK_FloatNegativeInfinity: float : -SK_FloatInfinity;

// Calculate the midpoint between a and b. Similar to std::midpoint in c++20.
// sk_float_midpoint :: (a: float, b: float) -> float #foreign libskia "?sk_float_midpoint@@YAMMM@Z";

// sk_float_rsqrt_portable :: (x: float) -> float #foreign libskia "?sk_float_rsqrt_portable@@YAMM@Z";
// sk_float_rsqrt :: (x: float) -> float #foreign libskia "?sk_float_rsqrt@@YAMM@Z";

// sk_ieee_float_divide :: (numer: float, denom: float) -> float #foreign libskia "?sk_ieee_float_divide@@YAMMM@Z";

// sk_ieee_double_divide :: (numer: float64, denom: float64) -> float64 #foreign libskia "?sk_ieee_double_divide@@YANNN@Z";

// Returns true iff the provided number is within a small epsilon of 0.
// sk_double_nearly_zero :: (a: float64) -> bool #foreign libskia "?sk_double_nearly_zero@@YA_NN@Z";

// Compare two doubles and return true if they are within maxUlpsDiff of each other.
// * nan as a or b - returns false.
// * infinity, infinity or -infinity, -infinity - returns true.
// * infinity and any other number - returns false.
//
// ulp is an initialism for Units in the Last Place.
// sk_doubles_nearly_equal_ulps :: (a: float64, b: float64, maxUlpsDiff: u8 = 16) -> bool #foreign libskia "?sk_doubles_nearly_equal_ulps@@YA_NNNE@Z";

// Sk64_pin_to_s32 :: (x: s64) -> s32 #foreign libskia "?Sk64_pin_to_s32@@YAH_J@Z";

// Sk32_sat_add :: (a: s32, b: s32) -> s32 #foreign libskia "?Sk32_sat_add@@YAHHH@Z";

// Sk32_sat_sub :: (a: s32, b: s32) -> s32 #foreign libskia "?Sk32_sat_sub@@YAHHH@Z";

// To avoid UBSAN complaints about 2's compliment overflows
//
// Sk32_can_overflow_add :: (a: s32, b: s32) -> s32 #foreign libskia "?Sk32_can_overflow_add@@YAHHH@Z";

// Sk32_can_overflow_sub :: (a: s32, b: s32) -> s32 #foreign libskia "?Sk32_can_overflow_sub@@YAHHH@Z";

/**
* This is a 'safe' abs for 32-bit integers that asserts when undefined behavior would occur.
* SkTAbs (in SkTemplates.h) is a general purpose absolute-value function.
*/
// SkAbs32 :: (value: s32) -> s32 #foreign libskia "?SkAbs32@@YAHH@Z";

/** SkIVector provides an alternative name for SkIPoint. SkIVector and SkIPoint
can be used interchangeably for all purposes.
*/
SkIVector :: SkIPoint;

/** \struct SkIPoint
SkIPoint holds two 32-bit integer coordinates.
*/
SkIPoint :: struct {
    fX: s32; //!< x-axis value
    fY: s32; //!< y-axis value

    /** Sets fX to x, fY to y.
    
    @param x  integer x-axis value of constructed SkIPoint
    @param y  integer y-axis value of constructed SkIPoint
    @return   SkIPoint (x, y)
    */
//     Make :: (x: s32, y: s32) -> SkIPoint #foreign libskia "?Make@SkIPoint@@SA?AU1@HH@Z";

    /** Returns x-axis value of SkIPoint.
    
    @return  fX
    */
//     x :: (this: *SkIPoint) -> s32 #cpp_method #foreign libskia "?x@SkIPoint@@QEBAHXZ";

    /** Returns y-axis value of SkIPoint.
    
    @return  fY
    */
//     y :: (this: *SkIPoint) -> s32 #cpp_method #foreign libskia "?y@SkIPoint@@QEBAHXZ";

    /** Returns true if fX and fY are both zero.
    
    @return  true if fX is zero and fY is zero
    */
//     isZero :: (this: *SkIPoint) -> bool #cpp_method #foreign libskia "?isZero@SkIPoint@@QEBA_NXZ";

    /** Sets fX to x and fY to y.
    
    @param x  new value for fX
    @param y  new value for fY
    */
//     set :: (this: *SkIPoint, x: s32, y: s32) -> void #cpp_method #foreign libskia "?set@SkIPoint@@QEAAXHH@Z";

    /** Returns true if SkIPoint is equivalent to SkIPoint constructed from (x, y).
    
    @param x  value compared with fX
    @param y  value compared with fY
    @return   true if SkIPoint equals (x, y)
    */
//     equals :: (this: *SkIPoint, x: s32, y: s32) -> bool #cpp_method #foreign libskia "?equals@SkIPoint@@QEBA_NHH@Z";
}

/** Returns SkIPoint changing the signs of fX and fY.

@return  SkIPoint as (-fX, -fY)
*/
// operator_minus :: (this: *SkIPoint) -> SkIPoint #cpp_method #foreign libskia "??GSkIPoint@@QEBA?AU0@XZ";
operator_minus :: (this: SkIPoint) -> SkIPoint #no_context {
    return operator_minus(*this);
}

/** Offsets SkIPoint by ivector v. Sets SkIPoint to (fX + v.fX, fY + v.fY).

@param v  ivector to add
*/
// operator_plus_equals :: (this: *SkIPoint, v: *SkIVector) -> void #cpp_method #foreign libskia "??YSkIPoint@@QEAAXAEBU0@@Z";
operator_plus_equals :: (this: *SkIPoint, v: SkIVector) #no_context {
    operator_plus_equals(this, *v);
}

/** Subtracts ivector v from SkIPoint. Sets SkIPoint to: (fX - v.fX, fY - v.fY).

@param v  ivector to subtract
*/
// operator_minus_equals :: (this: *SkIPoint, v: *SkIVector) -> void #cpp_method #foreign libskia "??ZSkIPoint@@QEAAXAEBU0@@Z";
operator_minus_equals :: (this: *SkIPoint, v: SkIVector) #no_context {
    operator_minus_equals(this, *v);
}

/** SkVector provides an alternative name for SkPoint. SkVector and SkPoint can
be used interchangeably for all purposes.
*/
SkVector :: SkPoint;

/** \struct SkPoint
SkPoint holds two 32-bit floating point coordinates.
*/
SkPoint :: struct {
    fX: float; //!< x-axis value
    fY: float; //!< y-axis value

    /** Sets fX to x, fY to y. Used both to set SkPoint and vector.
    
    @param x  float x-axis value of constructed SkPoint or vector
    @param y  float y-axis value of constructed SkPoint or vector
    @return   SkPoint (x, y)
    */
    Make :: (x: float, y: float) -> SkPoint #foreign libskia "?Make@SkPoint@@SA?AU1@MM@Z";

    /** Returns x-axis value of SkPoint or vector.
    
    @return  fX
    */
    x :: (this: *SkPoint) -> float #cpp_method #foreign libskia "?x@SkPoint@@QEBAMXZ";

    /** Returns y-axis value of SkPoint or vector.
    
    @return  fY
    */
    y :: (this: *SkPoint) -> float #cpp_method #foreign libskia "?y@SkPoint@@QEBAMXZ";

    /** Returns true if fX and fY are both zero.
    
    @return  true if fX is zero and fY is zero
    */
    isZero :: (this: *SkPoint) -> bool #cpp_method #foreign libskia "?isZero@SkPoint@@QEBA_NXZ";

    /** Sets fX to x and fY to y.
    
    @param x  new value for fX
    @param y  new value for fY
    */
    set :: (this: *SkPoint, x: float, y: float) -> void #cpp_method #foreign libskia "?set@SkPoint@@QEAAXMM@Z";

    /** Sets fX to x and fY to y, promoting integers to float values.
    
    Assigning a large integer value directly to fX or fY may cause a compiler
    error, triggered by narrowing conversion of int to float. This safely
    casts x and y to avoid the error.
    
    @param x  new value for fX
    @param y  new value for fY
    */
    iset :: (this: *SkPoint, x: s32, y: s32) -> void #cpp_method #foreign libskia "?iset@SkPoint@@QEAAXHH@Z";

    /** Sets fX to p.fX and fY to p.fY, promoting integers to float values.
    
    Assigning an SkIPoint containing a large integer value directly to fX or fY may
    cause a compiler error, triggered by narrowing conversion of int to float.
    This safely casts p.fX and p.fY to avoid the error.
    
    @param p  SkIPoint members promoted to float
    */
    iset :: (this: *SkPoint, p: *SkIPoint) -> void #cpp_method #foreign libskia "?iset@SkPoint@@QEAAXAEBUSkIPoint@@@Z";
    iset :: (this: *SkPoint, p: SkIPoint) #no_context {
        iset(this, *p);
    }

    /** Sets fX to absolute value of pt.fX; and fY to absolute value of pt.fY.
    
    @param pt  members providing magnitude for fX and fY
    */
    setAbs :: (this: *SkPoint, pt: *SkPoint) -> void #cpp_method #foreign libskia "?setAbs@SkPoint@@QEAAXAEBU1@@Z";
    setAbs :: (this: *SkPoint, pt: SkPoint) #no_context {
        setAbs(this, *pt);
    }

    /** Adds offset to each SkPoint in points array with count entries.
    
    @param points  SkPoint array
    @param count   entries in array
    @param offset  vector added to points
    */
    Offset :: (points: *SkPoint, count: s32, offset: *SkVector) -> void #foreign libskia "?Offset@SkPoint@@SAXQEAU1@HAEBU1@@Z";
    Offset :: (points: *SkPoint, count: s32, offset: SkVector) #no_context {
        Offset(points, count, *offset);
    }

    /** Adds offset (dx, dy) to each SkPoint in points array of length count.
    
    @param points  SkPoint array
    @param count   entries in array
    @param dx      added to fX in points
    @param dy      added to fY in points
    */
    Offset :: (points: *SkPoint, count: s32, dx: float, dy: float) -> void #foreign libskia "?Offset@SkPoint@@SAXQEAU1@HMM@Z";

    /** Adds offset (dx, dy) to SkPoint.
    
    @param dx  added to fX
    @param dy  added to fY
    */
    offset :: (this: *SkPoint, dx: float, dy: float) -> void #cpp_method #foreign libskia "?offset@SkPoint@@QEAAXMM@Z";

    /** Returns the Euclidean distance from origin, computed as:
    
    sqrt(fX * fX + fY * fY)
    
    .
    
    @return  straight-line distance to origin
    */
    length :: (this: *SkPoint) -> float #cpp_method #foreign libskia "?length@SkPoint@@QEBAMXZ";

    /** Returns the Euclidean distance from origin, computed as:
    
    sqrt(fX * fX + fY * fY)
    
    .
    
    @return  straight-line distance to origin
    */
    distanceToOrigin :: (this: *SkPoint) -> float #cpp_method #foreign libskia "?distanceToOrigin@SkPoint@@QEBAMXZ";

    /** Scales (fX, fY) so that length() returns one, while preserving ratio of fX to fY,
    if possible. If prior length is nearly zero, sets vector to (0, 0) and returns
    false; otherwise returns true.
    
    @return  true if former length is not zero or nearly zero
    
    example: https://fiddle.skia.org/c/@Point_normalize_2
    */
    normalize :: (this: *SkPoint) -> bool #cpp_method #foreign libskia "?normalize@SkPoint@@QEAA_NXZ";

    /** Sets vector to (x, y) scaled so length() returns one, and so that
    (fX, fY) is proportional to (x, y).  If (x, y) length is nearly zero,
    sets vector to (0, 0) and returns false; otherwise returns true.
    
    @param x  proportional value for fX
    @param y  proportional value for fY
    @return   true if (x, y) length is not zero or nearly zero
    
    example: https://fiddle.skia.org/c/@Point_setNormalize
    */
    setNormalize :: (this: *SkPoint, x: float, y: float) -> bool #cpp_method #foreign libskia "?setNormalize@SkPoint@@QEAA_NMM@Z";

    /** Scales vector so that distanceToOrigin() returns length, if possible. If former
    length is nearly zero, sets vector to (0, 0) and return false; otherwise returns
    true.
    
    @param length  straight-line distance to origin
    @return        true if former length is not zero or nearly zero
    
    example: https://fiddle.skia.org/c/@Point_setLength
    */
    setLength :: (this: *SkPoint, length: float) -> bool #cpp_method #foreign libskia "?setLength@SkPoint@@QEAA_NM@Z";

    /** Sets vector to (x, y) scaled to length, if possible. If former
    length is nearly zero, sets vector to (0, 0) and return false; otherwise returns
    true.
    
    @param x       proportional value for fX
    @param y       proportional value for fY
    @param length  straight-line distance to origin
    @return        true if (x, y) length is not zero or nearly zero
    
    example: https://fiddle.skia.org/c/@Point_setLength_2
    */
    setLength :: (this: *SkPoint, x: float, y: float, length: float) -> bool #cpp_method #foreign libskia "?setLength@SkPoint@@QEAA_NMMM@Z";

    /** Sets dst to SkPoint times scale. dst may be SkPoint to modify SkPoint in place.
    
    @param scale  factor to multiply SkPoint by
    @param dst    storage for scaled SkPoint
    
    example: https://fiddle.skia.org/c/@Point_scale
    */
    scale :: (this: *SkPoint, scale: float, dst: *SkPoint) -> void #cpp_method #foreign libskia "?scale@SkPoint@@QEBAXMPEAU1@@Z";

    /** Scales SkPoint in place by scale.
    
    @param value  factor to multiply SkPoint by
    */
    scale :: (this: *SkPoint, value: float) -> void #cpp_method #foreign libskia "?scale@SkPoint@@QEAAXM@Z";

    /** Changes the sign of fX and fY.
    */
    negate :: (this: *SkPoint) -> void #cpp_method #foreign libskia "?negate@SkPoint@@QEAAXXZ";

    /** Returns true if both fX and fY are measurable values.
    
    @return  true for values other than infinities and NaN
    */
    isFinite :: (this: *SkPoint) -> bool #cpp_method #foreign libskia "?isFinite@SkPoint@@QEBA_NXZ";

    /** Returns true if SkPoint is equivalent to SkPoint constructed from (x, y).
    
    @param x  value compared with fX
    @param y  value compared with fY
    @return   true if SkPoint equals (x, y)
    */
    equals :: (this: *SkPoint, x: float, y: float) -> bool #cpp_method #foreign libskia "?equals@SkPoint@@QEBA_NMM@Z";

    /** Returns the Euclidean distance from origin, computed as:
    
    sqrt(x * x + y * y)
    
    .
    
    @param x  component of length
    @param y  component of length
    @return   straight-line distance to origin
    
    example: https://fiddle.skia.org/c/@Point_Length
    */
    Length :: (x: float, y: float) -> float #foreign libskia "?Length@SkPoint@@SAMMM@Z";

    /** Scales (vec->fX, vec->fY) so that length() returns one, while preserving ratio of vec->fX
    to vec->fY, if possible. If original length is nearly zero, sets vec to (0, 0) and returns
    zero; otherwise, returns length of vec before vec is scaled.
    
    Returned prior length may be INFINITY if it can not be represented by float.
    
    Note that normalize() is faster if prior length is not required.
    
    @param vec  normalized to unit length
    @return     original vec length
    
    example: https://fiddle.skia.org/c/@Point_Normalize
    */
    Normalize :: (vec: *SkVector) -> float #foreign libskia "?Normalize@SkPoint@@SAMPEAU1@@Z";

    /** Returns the Euclidean distance between a and b.
    
    @param a  line end point
    @param b  line end point
    @return   straight-line distance from a to b
    */
    Distance :: (a: *SkPoint, b: *SkPoint) -> float #foreign libskia "?Distance@SkPoint@@SAMAEBU1@0@Z";
    Distance :: (a: SkPoint, b: SkPoint) -> float #no_context {
        return Distance(*a, *b);
    }

    /** Returns the dot product of vector a and vector b.
    
    @param a  left side of dot product
    @param b  right side of dot product
    @return   product of input magnitudes and cosine of the angle between them
    */
    DotProduct :: (a: *SkVector, b: *SkVector) -> float #foreign libskia "?DotProduct@SkPoint@@SAMAEBU1@0@Z";
    DotProduct :: (a: SkVector, b: SkVector) -> float #no_context {
        return DotProduct(*a, *b);
    }

    /** Returns the cross product of vector a and vector b.
    
    a and b form three-dimensional vectors with z-axis value equal to zero. The
    cross product is a three-dimensional vector with x-axis and y-axis values equal
    to zero. The cross product z-axis component is returned.
    
    @param a  left side of cross product
    @param b  right side of cross product
    @return   area spanned by vectors signed by angle direction
    */
    CrossProduct :: (a: *SkVector, b: *SkVector) -> float #foreign libskia "?CrossProduct@SkPoint@@SAMAEBU1@0@Z";
    CrossProduct :: (a: SkVector, b: SkVector) -> float #no_context {
        return CrossProduct(*a, *b);
    }

    /** Returns the cross product of vector and vec.
    
    Vector and vec form three-dimensional vectors with z-axis value equal to zero.
    The cross product is a three-dimensional vector with x-axis and y-axis values
    equal to zero. The cross product z-axis component is returned.
    
    @param vec  right side of cross product
    @return     area spanned by vectors signed by angle direction
    */
    cross :: (this: *SkPoint, vec: *SkVector) -> float #cpp_method #foreign libskia "?cross@SkPoint@@QEBAMAEBU1@@Z";
    cross :: (this: *SkPoint, vec: SkVector) -> float #no_context {
        return cross(this, *vec);
    }

    /** Returns the dot product of vector and vector vec.
    
    @param vec  right side of dot product
    @return     product of input magnitudes and cosine of the angle between them
    */
    dot :: (this: *SkPoint, vec: *SkVector) -> float #cpp_method #foreign libskia "?dot@SkPoint@@QEBAMAEBU1@@Z";
    dot :: (this: *SkPoint, vec: SkVector) -> float #no_context {
        return dot(this, *vec);
    }
}

/** Returns SkPoint changing the signs of fX and fY.

@return  SkPoint as (-fX, -fY)
*/
operator_minus :: (this: *SkPoint) -> SkPoint #cpp_method #foreign libskia "??GSkPoint@@QEBA?AU0@XZ";
operator_minus :: (this: SkPoint) -> SkPoint #no_context {
    return operator_minus(*this);
}

/** Adds vector v to SkPoint. Sets SkPoint to: (fX + v.fX, fY + v.fY).

@param v  vector to add
*/
operator_plus_equals :: (this: *SkPoint, v: *SkVector) -> void #cpp_method #foreign libskia "??YSkPoint@@QEAAXAEBU0@@Z";
operator_plus_equals :: (this: *SkPoint, v: SkVector) #no_context {
    operator_plus_equals(this, *v);
}

/** Subtracts vector v from SkPoint. Sets SkPoint to: (fX - v.fX, fY - v.fY).

@param v  vector to subtract
*/
operator_minus_equals :: (this: *SkPoint, v: *SkVector) -> void #cpp_method #foreign libskia "??ZSkPoint@@QEAAXAEBU0@@Z";
operator_minus_equals :: (this: *SkPoint, v: SkVector) #no_context {
    operator_minus_equals(this, *v);
}

/** Returns SkPoint multiplied by scale.

@param scale  float to multiply by
@return       SkPoint as (fX * scale, fY * scale)
*/
operator_mul :: (this: *SkPoint, scale: float) -> SkPoint #cpp_method #foreign libskia "??DSkPoint@@QEBA?AU0@M@Z";
operator_mul :: (this: SkPoint, scale: float) -> SkPoint #no_context {
    return operator_mul(*this, scale);
}

/** Multiplies SkPoint by scale. Sets SkPoint to: (fX * scale, fY * scale).

@param scale  float to multiply by
@return       reference to SkPoint
*/
operator_mul_equals :: (this: *SkPoint, scale: float) -> *SkPoint #cpp_method #foreign libskia "??XSkPoint@@QEAAAEAU0@M@Z";

SkScalar :: float;

/** Returns the fractional part of the scalar. */
// SkScalarFraction :: (x: SkScalar) -> SkScalar #foreign libskia "?SkScalarFraction@@YAMM@Z";

// SkScalarSquare :: (x: SkScalar) -> SkScalar #foreign libskia "?SkScalarSquare@@YAMM@Z";

// SkScalarIsInt :: (x: SkScalar) -> bool #foreign libskia "?SkScalarIsInt@@YA_NM@Z";

/**
*  Returns -1 || 0 || 1 depending on the sign of value:
*  -1 if x < 0
*   0 if x == 0
*   1 if x > 0
*/
// SkScalarSignAsInt :: (x: SkScalar) -> s32 #foreign libskia "?SkScalarSignAsInt@@YAHM@Z";

// Scalar result version of above
// SkScalarSignAsScalar :: (x: SkScalar) -> SkScalar #foreign libskia "?SkScalarSignAsScalar@@YAMM@Z";

// SkScalarNearlyZero :: (x: SkScalar, tolerance: SkScalar = 0.000244) -> bool #foreign libskia "?SkScalarNearlyZero@@YA_NMM@Z";

// SkScalarNearlyEqual :: (x: SkScalar, y: SkScalar, tolerance: SkScalar = 0.000244) -> bool #foreign libskia "?SkScalarNearlyEqual@@YA_NMMM@Z";

// SkScalarSinSnapToZero :: (radians: SkScalar) -> float #foreign libskia "?SkScalarSinSnapToZero@@YAMM@Z";

// SkScalarCosSnapToZero :: (radians: SkScalar) -> float #foreign libskia "?SkScalarCosSnapToZero@@YAMM@Z";

/** Linearly interpolate between A and B, based on t.
If t is 0, return A
If t is 1, return B
else interpolate.
t must be [0..SK_Scalar1]
*/
// SkScalarInterp :: (A: SkScalar, B: SkScalar, t: SkScalar) -> SkScalar #foreign libskia "?SkScalarInterp@@YAMMMM@Z";

/*
*  Helper to compare an array of scalars.
*/
// SkScalarsEqual :: (a: *SkScalar, b: *SkScalar, n: s32) -> bool #foreign libskia "?SkScalarsEqual@@YA_NQEBM0H@Z";

/**
* std::underlying_type is only defined for enums. For integral types, we just want the type.
*/
sk_strip_enum :: struct(T: Type, Enable: Type) {
    using,except(T, Enable) sk_strip_enum__raw:     sk_strip_enum__RAW(T, Enable);
    #if size_of(sk_strip_enum__RAW(T, Enable)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// sk_strip_enum without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from sk_strip_enum
sk_strip_enum__RAW :: struct(T: Type, Enable: Type) {
    type :: T;
}

SkISize :: struct {
    fWidth:  s32;
    fHeight: s32;

//     Make :: (w: s32, h: s32) -> SkISize #foreign libskia "?Make@SkISize@@SA?AU1@HH@Z";

//     MakeEmpty :: () -> SkISize #foreign libskia "?MakeEmpty@SkISize@@SA?AU1@XZ";

//     set :: (this: *SkISize, w: s32, h: s32) -> void #cpp_method #foreign libskia "?set@SkISize@@QEAAXHH@Z";

    /** Returns true iff fWidth == 0 && fHeight == 0
    */
//     isZero :: (this: *SkISize) -> bool #cpp_method #foreign libskia "?isZero@SkISize@@QEBA_NXZ";

    /** Returns true if either width or height are <= 0 */
//     isEmpty :: (this: *SkISize) -> bool #cpp_method #foreign libskia "?isEmpty@SkISize@@QEBA_NXZ";

    /** Set the width and height to 0 */
//     setEmpty :: (this: *SkISize) -> void #cpp_method #foreign libskia "?setEmpty@SkISize@@QEAAXXZ";

//     width :: (this: *SkISize) -> s32 #cpp_method #foreign libskia "?width@SkISize@@QEBAHXZ";
//     height :: (this: *SkISize) -> s32 #cpp_method #foreign libskia "?height@SkISize@@QEBAHXZ";

//     area :: (this: *SkISize) -> s64 #cpp_method #foreign libskia "?area@SkISize@@QEBA_JXZ";

//     equals :: (this: *SkISize, w: s32, h: s32) -> bool #cpp_method #foreign libskia "?equals@SkISize@@QEBA_NHH@Z";
}

// operator_eq :: (a: *SkISize, b: *SkISize) -> bool #foreign libskia "??8@YA_NAEBUSkISize@@0@Z";
operator_eq :: (a: SkISize, b: SkISize) -> bool #no_context {
    return operator_eq(*a, *b);
}

// operator_neq :: (a: *SkISize, b: *SkISize) -> bool #foreign libskia "??9@YA_NAEBUSkISize@@0@Z";
operator_neq :: (a: SkISize, b: SkISize) -> bool #no_context {
    return operator_neq(*a, *b);
}

///////////////////////////////////////////////////////////////////////////////
SkSize :: struct {
    fWidth:  SkScalar;
    fHeight: SkScalar;

//     Make :: (w: SkScalar, h: SkScalar) -> SkSize #foreign libskia "?Make@SkSize@@SA?AU1@MM@Z";

//     Make :: (src: *SkISize) -> SkSize #foreign libskia "?Make@SkSize@@SA?AU1@AEBUSkISize@@@Z";
    Make :: (src: SkISize) -> SkSize #no_context {
        return Make(*src);
    }

//     MakeEmpty :: () -> SkSize #foreign libskia "?MakeEmpty@SkSize@@SA?AU1@XZ";

//     set :: (this: *SkSize, w: SkScalar, h: SkScalar) -> void #cpp_method #foreign libskia "?set@SkSize@@QEAAXMM@Z";

    /** Returns true iff fWidth == 0 && fHeight == 0
    */
//     isZero :: (this: *SkSize) -> bool #cpp_method #foreign libskia "?isZero@SkSize@@QEBA_NXZ";

    /** Returns true if either width or height are <= 0 */
//     isEmpty :: (this: *SkSize) -> bool #cpp_method #foreign libskia "?isEmpty@SkSize@@QEBA_NXZ";

    /** Set the width and height to 0 */
//     setEmpty :: (this: *SkSize) -> void #cpp_method #foreign libskia "?setEmpty@SkSize@@QEAAXXZ";

//     width :: (this: *SkSize) -> SkScalar #cpp_method #foreign libskia "?width@SkSize@@QEBAMXZ";
//     height :: (this: *SkSize) -> SkScalar #cpp_method #foreign libskia "?height@SkSize@@QEBAMXZ";

//     equals :: (this: *SkSize, w: SkScalar, h: SkScalar) -> bool #cpp_method #foreign libskia "?equals@SkSize@@QEBA_NMM@Z";

//     toRound :: (this: *SkSize) -> SkISize #cpp_method #foreign libskia "?toRound@SkSize@@QEBA?AUSkISize@@XZ";

//     toCeil :: (this: *SkSize) -> SkISize #cpp_method #foreign libskia "?toCeil@SkSize@@QEBA?AUSkISize@@XZ";

//     toFloor :: (this: *SkSize) -> SkISize #cpp_method #foreign libskia "?toFloor@SkSize@@QEBA?AUSkISize@@XZ";
}

// operator_eq :: (a: *SkSize, b: *SkSize) -> bool #foreign libskia "??8@YA_NAEBUSkSize@@0@Z";
operator_eq :: (a: SkSize, b: SkSize) -> bool #no_context {
    return operator_eq(*a, *b);
}

// operator_neq :: (a: *SkSize, b: *SkSize) -> bool #foreign libskia "??9@YA_NAEBUSkSize@@0@Z";
operator_neq :: (a: SkSize, b: SkSize) -> bool #no_context {
    return operator_neq(*a, *b);
}

/**
* SkSpan holds a reference to contiguous data of type T along with a count. SkSpan does not own
* the data itself but is merely a reference, therefore you must take care with the lifetime of
* the underlying data.
*
* SkSpan is a count and a pointer into existing array or data type that stores its data in
* contiguous memory like std::vector. Any container that works with std::size() and std::data()
* can be used.
*
* SkSpan makes a convenient parameter for a routine to accept array like things. This allows you to
* write the routine without overloads for all different container types.
*
* Example:
*     void routine(SkSpan<const int> a) { ... }
*
*     std::vector v = {1, 2, 3, 4, 5};
*
*     routine(a);
*
* A word of caution when working with initializer_list, initializer_lists have a lifetime that is
* limited to the current statement. The following is correct and safe:
*
* Example:
*     routine({1,2,3,4,5});
*
* The following is undefined, and will result in erratic execution:
*
* Bad Example:
*     initializer_list l = {1, 2, 3, 4, 5};   // The data behind l dies at the ;.
*     routine(l);
*/
SkSpan :: struct(T: Type) {
    fPtr:  *T;
    fSize: u64;
}

/** \struct SkIRect
SkIRect holds four 32-bit integer coordinates describing the upper and
lower bounds of a rectangle. SkIRect may be created from outer bounds or
from position, width, and height. SkIRect describes an area; if its right
is less than or equal to its left, or if its bottom is less than or equal to
its top, it is considered empty.
*/
SkIRect :: struct {
    fLeft:   s32 = 0; //!< smaller x-axis bounds
    fTop:    s32 = 0; //!< smaller y-axis bounds
    fRight:  s32 = 0; //!< larger x-axis bounds
    fBottom: s32 = 0; //!< larger y-axis bounds

    /** Returns constructed SkIRect set to (0, 0, 0, 0).
    Many other rectangles are empty; if left is equal to or greater than right,
    or if top is equal to or greater than bottom. Setting all members to zero
    is a convenience, but does not designate a special empty rectangle.
    
    @return  bounds (0, 0, 0, 0)
    */
    MakeEmpty :: () -> SkIRect #foreign libskia "?MakeEmpty@SkIRect@@SA?AU1@XZ";

    /** Returns constructed SkIRect set to (0, 0, w, h). Does not validate input; w or h
    may be negative.
    
    @param w  width of constructed SkIRect
    @param h  height of constructed SkIRect
    @return   bounds (0, 0, w, h)
    */
    MakeWH :: (w: s32, h: s32) -> SkIRect #foreign libskia "?MakeWH@SkIRect@@SA?AU1@HH@Z";

    /** Returns constructed SkIRect set to (0, 0, size.width(), size.height()).
    Does not validate input; size.width() or size.height() may be negative.
    
    @param size  values for SkIRect width and height
    @return      bounds (0, 0, size.width(), size.height())
    */
    MakeSize :: (size: *SkISize) -> SkIRect #foreign libskia "?MakeSize@SkIRect@@SA?AU1@AEBUSkISize@@@Z";
    MakeSize :: (size: SkISize) -> SkIRect #no_context {
        return MakeSize(*size);
    }

    /** Returns constructed SkIRect set to (pt.x(), pt.y(), pt.x() + size.width(),
    pt.y() + size.height()). Does not validate input; size.width() or size.height() may be
    negative.
    
    @param pt    values for SkIRect fLeft and fTop
    @param size  values for SkIRect width and height
    @return      bounds at pt with width and height of size
    */
    MakePtSize :: (pt: SkIPoint, size: SkISize) -> SkIRect #foreign libskia "?MakePtSize@SkIRect@@SA?AU1@USkIPoint@@USkISize@@@Z";

    /** Returns constructed SkIRect set to (l, t, r, b). Does not sort input; SkIRect may
    result in fLeft greater than fRight, or fTop greater than fBottom.
    
    @param l  integer stored in fLeft
    @param t  integer stored in fTop
    @param r  integer stored in fRight
    @param b  integer stored in fBottom
    @return   bounds (l, t, r, b)
    */
    MakeLTRB :: (l: s32, t: s32, r: s32, b: s32) -> SkIRect #foreign libskia "?MakeLTRB@SkIRect@@SA?AU1@HHHH@Z";

    /** Returns constructed SkIRect set to: (x, y, x + w, y + h).
    Does not validate input; w or h may be negative.
    
    @param x  stored in fLeft
    @param y  stored in fTop
    @param w  added to x and stored in fRight
    @param h  added to y and stored in fBottom
    @return   bounds at (x, y) with width w and height h
    */
    MakeXYWH :: (x: s32, y: s32, w: s32, h: s32) -> SkIRect #foreign libskia "?MakeXYWH@SkIRect@@SA?AU1@HHHH@Z";

    /** Returns left edge of SkIRect, if sorted.
    Call sort() to reverse fLeft and fRight if needed.
    
    @return  fLeft
    */
    left :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?left@SkIRect@@QEBAHXZ";

    /** Returns top edge of SkIRect, if sorted. Call isEmpty() to see if SkIRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fTop
    */
    top :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?top@SkIRect@@QEBAHXZ";

    /** Returns right edge of SkIRect, if sorted.
    Call sort() to reverse fLeft and fRight if needed.
    
    @return  fRight
    */
    right :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?right@SkIRect@@QEBAHXZ";

    /** Returns bottom edge of SkIRect, if sorted. Call isEmpty() to see if SkIRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fBottom
    */
    bottom :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?bottom@SkIRect@@QEBAHXZ";

    /** Returns left edge of SkIRect, if sorted. Call isEmpty() to see if SkIRect may be invalid,
    and sort() to reverse fLeft and fRight if needed.
    
    @return  fLeft
    */
    x :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?x@SkIRect@@QEBAHXZ";

    /** Returns top edge of SkIRect, if sorted. Call isEmpty() to see if SkIRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fTop
    */
    y :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?y@SkIRect@@QEBAHXZ";

    // Experimental
    topLeft :: (this: *SkIRect) -> SkIPoint #cpp_method #foreign libskia "?topLeft@SkIRect@@QEBA?AUSkIPoint@@XZ";

    /** Returns span on the x-axis. This does not check if SkIRect is sorted, or if
    result fits in 32-bit signed integer; result may be negative.
    
    @return  fRight minus fLeft
    */
    width :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?width@SkIRect@@QEBAHXZ";

    /** Returns span on the y-axis. This does not check if SkIRect is sorted, or if
    result fits in 32-bit signed integer; result may be negative.
    
    @return  fBottom minus fTop
    */
    height :: (this: *SkIRect) -> s32 #cpp_method #foreign libskia "?height@SkIRect@@QEBAHXZ";

    /** Returns spans on the x-axis and y-axis. This does not check if SkIRect is sorted,
    or if result fits in 32-bit signed integer; result may be negative.
    
    @return  SkISize (width, height)
    */
    size :: (this: *SkIRect) -> SkISize #cpp_method #foreign libskia "?size@SkIRect@@QEBA?AUSkISize@@XZ";

    /** Returns span on the x-axis. This does not check if SkIRect is sorted, so the
    result may be negative. This is safer than calling width() since width() might
    overflow in its calculation.
    
    @return  fRight minus fLeft cast to int64_t
    */
    width64 :: (this: *SkIRect) -> s64 #cpp_method #foreign libskia "?width64@SkIRect@@QEBA_JXZ";

    /** Returns span on the y-axis. This does not check if SkIRect is sorted, so the
    result may be negative. This is safer than calling height() since height() might
    overflow in its calculation.
    
    @return  fBottom minus fTop cast to int64_t
    */
    height64 :: (this: *SkIRect) -> s64 #cpp_method #foreign libskia "?height64@SkIRect@@QEBA_JXZ";

    /** Returns true if fLeft is equal to or greater than fRight, or if fTop is equal
    to or greater than fBottom. Call sort() to reverse rectangles with negative
    width64() or height64().
    
    @return  true if width64() or height64() are zero or negative
    */
    isEmpty64 :: (this: *SkIRect) -> bool #cpp_method #foreign libskia "?isEmpty64@SkIRect@@QEBA_NXZ";

    /** Returns true if width() or height() are zero or negative.
    
    @return  true if width() or height() are zero or negative
    */
    isEmpty :: (this: *SkIRect) -> bool #cpp_method #foreign libskia "?isEmpty@SkIRect@@QEBA_NXZ";

    /** Sets SkIRect to (0, 0, 0, 0).
    
    Many other rectangles are empty; if left is equal to or greater than right,
    or if top is equal to or greater than bottom. Setting all members to zero
    is a convenience, but does not designate a special empty rectangle.
    */
    setEmpty :: (this: *SkIRect) -> void #cpp_method #foreign libskia "?setEmpty@SkIRect@@QEAAXXZ";

    /** Sets SkIRect to (left, top, right, bottom).
    left and right are not sorted; left is not necessarily less than right.
    top and bottom are not sorted; top is not necessarily less than bottom.
    
    @param left    stored in fLeft
    @param top     stored in fTop
    @param right   stored in fRight
    @param bottom  stored in fBottom
    */
    setLTRB :: (this: *SkIRect, left: s32, top: s32, right: s32, bottom: s32) -> void #cpp_method #foreign libskia "?setLTRB@SkIRect@@QEAAXHHHH@Z";

    /** Sets SkIRect to: (x, y, x + width, y + height).
    Does not validate input; width or height may be negative.
    
    @param x       stored in fLeft
    @param y       stored in fTop
    @param width   added to x and stored in fRight
    @param height  added to y and stored in fBottom
    */
    setXYWH :: (this: *SkIRect, x: s32, y: s32, width: s32, height: s32) -> void #cpp_method #foreign libskia "?setXYWH@SkIRect@@QEAAXHHHH@Z";

    setWH :: (this: *SkIRect, width: s32, height: s32) -> void #cpp_method #foreign libskia "?setWH@SkIRect@@QEAAXHH@Z";

    setSize :: (this: *SkIRect, size: SkISize) -> void #cpp_method #foreign libskia "?setSize@SkIRect@@QEAAXUSkISize@@@Z";

    /** Returns SkIRect offset by (dx, dy).
    
    If dx is negative, SkIRect returned is moved to the left.
    If dx is positive, SkIRect returned is moved to the right.
    If dy is negative, SkIRect returned is moved upward.
    If dy is positive, SkIRect returned is moved downward.
    
    @param dx  offset added to fLeft and fRight
    @param dy  offset added to fTop and fBottom
    @return    SkIRect offset by dx and dy, with original width and height
    */
    makeOffset :: (this: *SkIRect, dx: s32, dy: s32) -> SkIRect #cpp_method #foreign libskia "?makeOffset@SkIRect@@QEBA?AU1@HH@Z";

    /** Returns SkIRect offset by (offset.x(), offset.y()).
    
    If offset.x() is negative, SkIRect returned is moved to the left.
    If offset.x() is positive, SkIRect returned is moved to the right.
    If offset.y() is negative, SkIRect returned is moved upward.
    If offset.y() is positive, SkIRect returned is moved downward.
    
    @param offset  translation vector
    @return    SkIRect translated by offset, with original width and height
    */
    makeOffset :: (this: *SkIRect, offset: SkIVector) -> SkIRect #cpp_method #foreign libskia "?makeOffset@SkIRect@@QEBA?AU1@USkIPoint@@@Z";

    /** Returns SkIRect, inset by (dx, dy).
    
    If dx is negative, SkIRect returned is wider.
    If dx is positive, SkIRect returned is narrower.
    If dy is negative, SkIRect returned is taller.
    If dy is positive, SkIRect returned is shorter.
    
    @param dx  offset added to fLeft and subtracted from fRight
    @param dy  offset added to fTop and subtracted from fBottom
    @return    SkIRect inset symmetrically left and right, top and bottom
    */
    makeInset :: (this: *SkIRect, dx: s32, dy: s32) -> SkIRect #cpp_method #foreign libskia "?makeInset@SkIRect@@QEBA?AU1@HH@Z";

    /** Returns SkIRect, outset by (dx, dy).
    
    If dx is negative, SkIRect returned is narrower.
    If dx is positive, SkIRect returned is wider.
    If dy is negative, SkIRect returned is shorter.
    If dy is positive, SkIRect returned is taller.
    
    @param dx  offset subtracted to fLeft and added from fRight
    @param dy  offset subtracted to fTop and added from fBottom
    @return    SkIRect outset symmetrically left and right, top and bottom
    */
    makeOutset :: (this: *SkIRect, dx: s32, dy: s32) -> SkIRect #cpp_method #foreign libskia "?makeOutset@SkIRect@@QEBA?AU1@HH@Z";

    /** Offsets SkIRect by adding dx to fLeft, fRight; and by adding dy to fTop, fBottom.
    
    If dx is negative, moves SkIRect returned to the left.
    If dx is positive, moves SkIRect returned to the right.
    If dy is negative, moves SkIRect returned upward.
    If dy is positive, moves SkIRect returned downward.
    
    @param dx  offset added to fLeft and fRight
    @param dy  offset added to fTop and fBottom
    */
    offset :: (this: *SkIRect, dx: s32, dy: s32) -> void #cpp_method #foreign libskia "?offset@SkIRect@@QEAAXHH@Z";

    /** Offsets SkIRect by adding delta.fX to fLeft, fRight; and by adding delta.fY to
    fTop, fBottom.
    
    If delta.fX is negative, moves SkIRect returned to the left.
    If delta.fX is positive, moves SkIRect returned to the right.
    If delta.fY is negative, moves SkIRect returned upward.
    If delta.fY is positive, moves SkIRect returned downward.
    
    @param delta  offset added to SkIRect
    */
    offset :: (this: *SkIRect, delta: *SkIPoint) -> void #cpp_method #foreign libskia "?offset@SkIRect@@QEAAXAEBUSkIPoint@@@Z";
    offset :: (this: *SkIRect, delta: SkIPoint) #no_context {
        offset(this, *delta);
    }

    /** Offsets SkIRect so that fLeft equals newX, and fTop equals newY. width and height
    are unchanged.
    
    @param newX  stored in fLeft, preserving width()
    @param newY  stored in fTop, preserving height()
    */
    offsetTo :: (this: *SkIRect, newX: s32, newY: s32) -> void #cpp_method #foreign libskia "?offsetTo@SkIRect@@QEAAXHH@Z";

    /** Insets SkIRect by (dx,dy).
    
    If dx is positive, makes SkIRect narrower.
    If dx is negative, makes SkIRect wider.
    If dy is positive, makes SkIRect shorter.
    If dy is negative, makes SkIRect taller.
    
    @param dx  offset added to fLeft and subtracted from fRight
    @param dy  offset added to fTop and subtracted from fBottom
    */
    inset :: (this: *SkIRect, dx: s32, dy: s32) -> void #cpp_method #foreign libskia "?inset@SkIRect@@QEAAXHH@Z";

    /** Outsets SkIRect by (dx, dy).
    
    If dx is positive, makes SkIRect wider.
    If dx is negative, makes SkIRect narrower.
    If dy is positive, makes SkIRect taller.
    If dy is negative, makes SkIRect shorter.
    
    @param dx  subtracted to fLeft and added from fRight
    @param dy  subtracted to fTop and added from fBottom
    */
    outset :: (this: *SkIRect, dx: s32, dy: s32) -> void #cpp_method #foreign libskia "?outset@SkIRect@@QEAAXHH@Z";

    /** Adjusts SkIRect by adding dL to fLeft, dT to fTop, dR to fRight, and dB to fBottom.
    
    If dL is positive, narrows SkIRect on the left. If negative, widens it on the left.
    If dT is positive, shrinks SkIRect on the top. If negative, lengthens it on the top.
    If dR is positive, narrows SkIRect on the right. If negative, widens it on the right.
    If dB is positive, shrinks SkIRect on the bottom. If negative, lengthens it on the bottom.
    
    The resulting SkIRect is not checked for validity. Thus, if the resulting SkIRect left is
    greater than right, the SkIRect will be considered empty. Call sort() after this call
    if that is not the desired behavior.
    
    @param dL  offset added to fLeft
    @param dT  offset added to fTop
    @param dR  offset added to fRight
    @param dB  offset added to fBottom
    */
    adjust :: (this: *SkIRect, dL: s32, dT: s32, dR: s32, dB: s32) -> void #cpp_method #foreign libskia "?adjust@SkIRect@@QEAAXHHHH@Z";

    /** Returns true if: fLeft <= x < fRight && fTop <= y < fBottom.
    Returns false if SkIRect is empty.
    
    Considers input to describe constructed SkIRect: (x, y, x + 1, y + 1) and
    returns true if constructed area is completely enclosed by SkIRect area.
    
    @param x  test SkIPoint x-coordinate
    @param y  test SkIPoint y-coordinate
    @return   true if (x, y) is inside SkIRect
    */
    contains :: (this: *SkIRect, x: s32, y: s32) -> bool #cpp_method #foreign libskia "?contains@SkIRect@@QEBA_NHH@Z";

    /** Returns true if SkIRect contains r.
    Returns false if SkIRect is empty or r is empty.
    
    SkIRect contains r when SkIRect area completely includes r area.
    
    @param r  SkIRect contained
    @return   true if all sides of SkIRect are outside r
    */
    contains :: (this: *SkIRect, r: *SkIRect) -> bool #cpp_method #foreign libskia "?contains@SkIRect@@QEBA_NAEBU1@@Z";
    contains :: (this: *SkIRect, r: SkIRect) -> bool #no_context {
        return contains(this, *r);
    }

    /** Returns true if SkIRect contains r.
    Returns false if SkIRect is empty or r is empty.
    
    SkIRect contains r when SkIRect area completely includes r area.
    
    @param r  SkRect contained
    @return   true if all sides of SkIRect are outside r
    */
    contains :: (this: *SkIRect, r: *SkRect) -> bool #cpp_method #foreign libskia "?contains@SkIRect@@QEBA_NAEBUSkRect@@@Z";
    contains :: (this: *SkIRect, r: SkRect) -> bool #no_context {
        return contains(this, *r);
    }

    /** Returns true if SkIRect contains construction.
    Asserts if SkIRect is empty or construction is empty, and if SK_DEBUG is defined.
    
    Return is undefined if SkIRect is empty or construction is empty.
    
    @param r  SkIRect contained
    @return   true if all sides of SkIRect are outside r
    */
    containsNoEmptyCheck :: (this: *SkIRect, r: *SkIRect) -> bool #cpp_method #foreign libskia "?containsNoEmptyCheck@SkIRect@@QEBA_NAEBU1@@Z";
    containsNoEmptyCheck :: (this: *SkIRect, r: SkIRect) -> bool #no_context {
        return containsNoEmptyCheck(this, *r);
    }

    /** Returns true if SkIRect intersects r, and sets SkIRect to intersection.
    Returns false if SkIRect does not intersect r, and leaves SkIRect unchanged.
    
    Returns false if either r or SkIRect is empty, leaving SkIRect unchanged.
    
    @param r  limit of result
    @return   true if r and SkIRect have area in common
    */
    intersect :: (this: *SkIRect, r: *SkIRect) -> bool #cpp_method #foreign libskia "?intersect@SkIRect@@QEAA_NAEBU1@@Z";
    intersect :: (this: *SkIRect, r: SkIRect) -> bool #no_context {
        return intersect(this, *r);
    }

    /** Returns true if a intersects b, and sets SkIRect to intersection.
    Returns false if a does not intersect b, and leaves SkIRect unchanged.
    
    Returns false if either a or b is empty, leaving SkIRect unchanged.
    
    @param a  SkIRect to intersect
    @param b  SkIRect to intersect
    @return   true if a and b have area in common
    */
    intersect :: (this: *SkIRect, a: *SkIRect, b: *SkIRect) -> bool #cpp_method #foreign libskia "?intersect@SkIRect@@QEAA_NAEBU1@0@Z";
    intersect :: (this: *SkIRect, a: SkIRect, b: SkIRect) -> bool #no_context {
        return intersect(this, *a, *b);
    }

    /** Returns true if a intersects b.
    Returns false if either a or b is empty, or do not intersect.
    
    @param a  SkIRect to intersect
    @param b  SkIRect to intersect
    @return   true if a and b have area in common
    */
    Intersects :: (a: *SkIRect, b: *SkIRect) -> bool #foreign libskia "?Intersects@SkIRect@@SA_NAEBU1@0@Z";
    Intersects :: (a: SkIRect, b: SkIRect) -> bool #no_context {
        return Intersects(*a, *b);
    }

    /** Sets SkIRect to the union of itself and r.
    
    Has no effect if r is empty. Otherwise, if SkIRect is empty, sets SkIRect to r.
    
    @param r  expansion SkIRect
    
    example: https://fiddle.skia.org/c/@IRect_join_2
    */
    join :: (this: *SkIRect, r: *SkIRect) -> void #cpp_method #foreign libskia "?join@SkIRect@@QEAAXAEBU1@@Z";
    join :: (this: *SkIRect, r: SkIRect) #no_context {
        join(this, *r);
    }

    /** Swaps fLeft and fRight if fLeft is greater than fRight; and swaps
    fTop and fBottom if fTop is greater than fBottom. Result may be empty,
    and width() and height() will be zero or positive.
    */
    sort :: (this: *SkIRect) -> void #cpp_method #foreign libskia "?sort@SkIRect@@QEAAXXZ";

    /** Returns SkIRect with fLeft and fRight swapped if fLeft is greater than fRight; and
    with fTop and fBottom swapped if fTop is greater than fBottom. Result may be empty;
    and width() and height() will be zero or positive.
    
    @return  sorted SkIRect
    */
    makeSorted :: (this: *SkIRect) -> SkIRect #cpp_method #foreign libskia "?makeSorted@SkIRect@@QEBA?AU1@XZ";

    /** Returns pointer to first int32 in SkIRect, to treat it as an array with four
    entries.
    
    @return  pointer to fLeft
    */
    asInt32s :: (this: *SkIRect) -> *s32 #cpp_method #foreign libskia "?asInt32s@SkIRect@@QEBAPEBHXZ";
}

/** \struct SkRect
SkRect holds four float coordinates describing the upper and
lower bounds of a rectangle. SkRect may be created from outer bounds or
from position, width, and height. SkRect describes an area; if its right
is less than or equal to its left, or if its bottom is less than or equal to
its top, it is considered empty.
*/
SkRect :: struct {
    fLeft:   float = 0; //!< smaller x-axis bounds
    fTop:    float = 0; //!< smaller y-axis bounds
    fRight:  float = 0; //!< larger x-axis bounds
    fBottom: float = 0; //!< larger y-axis bounds

    /** Returns constructed SkRect set to (0, 0, 0, 0).
    Many other rectangles are empty; if left is equal to or greater than right,
    or if top is equal to or greater than bottom. Setting all members to zero
    is a convenience, but does not designate a special empty rectangle.
    
    @return  bounds (0, 0, 0, 0)
    */
    MakeEmpty :: () -> SkRect #foreign libskia "?MakeEmpty@SkRect@@SA?AU1@XZ";

    /** Returns constructed SkRect set to float values (0, 0, w, h). Does not
    validate input; w or h may be negative.
    
    Passing integer values may generate a compiler warning since SkRect cannot
    represent 32-bit integers exactly. Use SkIRect for an exact integer rectangle.
    
    @param w  float width of constructed SkRect
    @param h  float height of constructed SkRect
    @return   bounds (0, 0, w, h)
    */
    MakeWH :: (w: float, h: float) -> SkRect #foreign libskia "?MakeWH@SkRect@@SA?AU1@MM@Z";

    /** Returns constructed SkRect set to integer values (0, 0, w, h). Does not validate
    input; w or h may be negative.
    
    Use to avoid a compiler warning that input may lose precision when stored.
    Use SkIRect for an exact integer rectangle.
    
    @param w  integer width of constructed SkRect
    @param h  integer height of constructed SkRect
    @return   bounds (0, 0, w, h)
    */
    MakeIWH :: (w: s32, h: s32) -> SkRect #foreign libskia "?MakeIWH@SkRect@@SA?AU1@HH@Z";

    /** Returns constructed SkRect set to (0, 0, size.width(), size.height()). Does not
    validate input; size.width() or size.height() may be negative.
    
    @param size  float values for SkRect width and height
    @return      bounds (0, 0, size.width(), size.height())
    */
    MakeSize :: (size: *SkSize) -> SkRect #foreign libskia "?MakeSize@SkRect@@SA?AU1@AEBUSkSize@@@Z";
    MakeSize :: (size: SkSize) -> SkRect #no_context {
        return MakeSize(*size);
    }

    /** Returns constructed SkRect set to (l, t, r, b). Does not sort input; SkRect may
    result in fLeft greater than fRight, or fTop greater than fBottom.
    
    @param l  float stored in fLeft
    @param t  float stored in fTop
    @param r  float stored in fRight
    @param b  float stored in fBottom
    @return   bounds (l, t, r, b)
    */
    MakeLTRB :: (l: float, t: float, r: float, b: float) -> SkRect #foreign libskia "?MakeLTRB@SkRect@@SA?AU1@MMMM@Z";

    /** Returns constructed SkRect set to (x, y, x + w, y + h).
    Does not validate input; w or h may be negative.
    
    @param x  stored in fLeft
    @param y  stored in fTop
    @param w  added to x and stored in fRight
    @param h  added to y and stored in fBottom
    @return   bounds at (x, y) with width w and height h
    */
    MakeXYWH :: (x: float, y: float, w: float, h: float) -> SkRect #foreign libskia "?MakeXYWH@SkRect@@SA?AU1@MMMM@Z";

    /** Returns constructed SkIRect set to (0, 0, size.width(), size.height()).
    Does not validate input; size.width() or size.height() may be negative.
    
    @param size  integer values for SkRect width and height
    @return      bounds (0, 0, size.width(), size.height())
    */
    Make :: (size: *SkISize) -> SkRect #foreign libskia "?Make@SkRect@@SA?AU1@AEBUSkISize@@@Z";
    Make :: (size: SkISize) -> SkRect #no_context {
        return Make(*size);
    }

    /** Returns constructed SkIRect set to irect, promoting integers to float.
    Does not validate input; fLeft may be greater than fRight, fTop may be greater
    than fBottom.
    
    @param irect  integer unsorted bounds
    @return       irect members converted to float
    */
    Make :: (irect: *SkIRect) -> SkRect #foreign libskia "?Make@SkRect@@SA?AU1@AEBUSkIRect@@@Z";
    Make :: (irect: SkIRect) -> SkRect #no_context {
        return Make(*irect);
    }

    /** Returns true if fLeft is equal to or greater than fRight, or if fTop is equal
    to or greater than fBottom. Call sort() to reverse rectangles with negative
    width() or height().
    
    @return  true if width() or height() are zero or negative
    */
    isEmpty :: (this: *SkRect) -> bool #cpp_method #foreign libskia "?isEmpty@SkRect@@QEBA_NXZ";

    /** Returns true if fLeft is equal to or less than fRight, or if fTop is equal
    to or less than fBottom. Call sort() to reverse rectangles with negative
    width() or height().
    
    @return  true if width() or height() are zero or positive
    */
    isSorted :: (this: *SkRect) -> bool #cpp_method #foreign libskia "?isSorted@SkRect@@QEBA_NXZ";

    /** Returns true if all values in the rectangle are finite.
    
    @return  true if no member is infinite or NaN
    */
    isFinite :: (this: *SkRect) -> bool #cpp_method #foreign libskia "?isFinite@SkRect@@QEBA_NXZ";

    /** Returns left edge of SkRect, if sorted. Call isSorted() to see if SkRect is valid.
    Call sort() to reverse fLeft and fRight if needed.
    
    @return  fLeft
    */
    x :: (this: *SkRect) -> float #cpp_method #foreign libskia "?x@SkRect@@QEBAMXZ";

    /** Returns top edge of SkRect, if sorted. Call isEmpty() to see if SkRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fTop
    */
    y :: (this: *SkRect) -> float #cpp_method #foreign libskia "?y@SkRect@@QEBAMXZ";

    /** Returns left edge of SkRect, if sorted. Call isSorted() to see if SkRect is valid.
    Call sort() to reverse fLeft and fRight if needed.
    
    @return  fLeft
    */
    left :: (this: *SkRect) -> float #cpp_method #foreign libskia "?left@SkRect@@QEBAMXZ";

    /** Returns top edge of SkRect, if sorted. Call isEmpty() to see if SkRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fTop
    */
    top :: (this: *SkRect) -> float #cpp_method #foreign libskia "?top@SkRect@@QEBAMXZ";

    /** Returns right edge of SkRect, if sorted. Call isSorted() to see if SkRect is valid.
    Call sort() to reverse fLeft and fRight if needed.
    
    @return  fRight
    */
    right :: (this: *SkRect) -> float #cpp_method #foreign libskia "?right@SkRect@@QEBAMXZ";

    /** Returns bottom edge of SkRect, if sorted. Call isEmpty() to see if SkRect may be invalid,
    and sort() to reverse fTop and fBottom if needed.
    
    @return  fBottom
    */
    bottom :: (this: *SkRect) -> float #cpp_method #foreign libskia "?bottom@SkRect@@QEBAMXZ";

    /** Returns span on the x-axis. This does not check if SkRect is sorted, or if
    result fits in 32-bit float; result may be negative or infinity.
    
    @return  fRight minus fLeft
    */
    width :: (this: *SkRect) -> float #cpp_method #foreign libskia "?width@SkRect@@QEBAMXZ";

    /** Returns span on the y-axis. This does not check if SkRect is sorted, or if
    result fits in 32-bit float; result may be negative or infinity.
    
    @return  fBottom minus fTop
    */
    height :: (this: *SkRect) -> float #cpp_method #foreign libskia "?height@SkRect@@QEBAMXZ";

    /** Returns average of left edge and right edge. Result does not change if SkRect
    is sorted. Result may overflow to infinity if SkRect is far from the origin.
    
    @return  midpoint on x-axis
    */
    centerX :: (this: *SkRect) -> float #cpp_method #foreign libskia "?centerX@SkRect@@QEBAMXZ";

    /** Returns average of top edge and bottom edge. Result does not change if SkRect
    is sorted.
    
    @return  midpoint on y-axis
    */
    centerY :: (this: *SkRect) -> float #cpp_method #foreign libskia "?centerY@SkRect@@QEBAMXZ";

    /** Returns the point this->centerX(), this->centerY().
    @return  rectangle center
    */
    center :: (this: *SkRect) -> SkPoint #cpp_method #foreign libskia "?center@SkRect@@QEBA?AUSkPoint@@XZ";

    TL :: (this: *SkRect) -> SkPoint #cpp_method #foreign libskia "?TL@SkRect@@QEBA?AUSkPoint@@XZ";
    TR :: (this: *SkRect) -> SkPoint #cpp_method #foreign libskia "?TR@SkRect@@QEBA?AUSkPoint@@XZ";
    BL :: (this: *SkRect) -> SkPoint #cpp_method #foreign libskia "?BL@SkRect@@QEBA?AUSkPoint@@XZ";
    BR :: (this: *SkRect) -> SkPoint #cpp_method #foreign libskia "?BR@SkRect@@QEBA?AUSkPoint@@XZ";

    /** Returns four points in quad that enclose SkRect,
    *  respect the specified path-direction.
    */
    toQuad :: (this: *SkRect, dir: SkPathDirection = .CW) -> std.array(SkPoint, 4) #cpp_method #foreign libskia "?toQuad@SkRect@@QEBA?AV?$array@USkPoint@@$03@std@@W4SkPathDirection@@@Z";

    // Same as toQuad(), but copies the 4 points into the specified storage
    // which must be at least a size of 4.
    copyToQuad :: (this: *SkRect, pts: SkSpan(SkPoint), dir: SkPathDirection = .CW) -> void #cpp_method #foreign libskia "?copyToQuad@SkRect@@QEBAXV?$SkSpan@USkPoint@@@@W4SkPathDirection@@@Z";

    // DEPRECATED: use std::array or copyToQuad versions
    toQuad :: (this: *SkRect, quad: *[4] SkPoint) -> void #cpp_method #foreign libskia "?toQuad@SkRect@@QEBAXQEAUSkPoint@@@Z";

    /** Sets SkRect to (0, 0, 0, 0).
    
    Many other rectangles are empty; if left is equal to or greater than right,
    or if top is equal to or greater than bottom. Setting all members to zero
    is a convenience, but does not designate a special empty rectangle.
    */
    setEmpty :: (this: *SkRect) -> void #cpp_method #foreign libskia "?setEmpty@SkRect@@QEAAXXZ";

    /** Sets SkRect to src, promoting src members from integer to float.
    Very large values in src may lose precision.
    
    @param src  integer SkRect
    */
    set :: (this: *SkRect, src: *SkIRect) -> void #cpp_method #foreign libskia "?set@SkRect@@QEAAXAEBUSkIRect@@@Z";
    set :: (this: *SkRect, src: SkIRect) #no_context {
        set(this, *src);
    }

    /** Sets SkRect to (left, top, right, bottom).
    left and right are not sorted; left is not necessarily less than right.
    top and bottom are not sorted; top is not necessarily less than bottom.
    
    @param left    stored in fLeft
    @param top     stored in fTop
    @param right   stored in fRight
    @param bottom  stored in fBottom
    */
    setLTRB :: (this: *SkRect, left: float, top: float, right: float, bottom: float) -> void #cpp_method #foreign libskia "?setLTRB@SkRect@@QEAAXMMMM@Z";

    /**
    * Compute the bounds of the span of points.
    * If the span is empty, returns the empty-rect {0, 0, 0, 0.
    * If the span contains non-finite values (inf or nan), returns {}
    */
    Bounds :: (pts: SkSpan(SkPoint)) -> std.optional(SkRect) #cpp_return_type_is_non_pod #foreign libskia "?Bounds@SkRect@@SA?AV?$optional@USkRect@@@std@@V?$SkSpan@$$CBUSkPoint@@@@@Z";

    BoundsOrEmpty :: (pts: SkSpan(SkPoint)) -> SkRect #foreign libskia "?BoundsOrEmpty@SkRect@@SA?AU1@V?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Sets to bounds of SkPoint array with count entries. If count is zero or smaller,
    or if SkPoint array contains an infinity or NaN, sets to (0, 0, 0, 0).
    
    Result is either empty or sorted: fLeft is less than or equal to fRight, and
    fTop is less than or equal to fBottom.
    
    @param pts    SkPoint span
    */
    setBounds :: (this: *SkRect, pts: SkSpan(SkPoint)) -> void #cpp_method #foreign libskia "?setBounds@SkRect@@QEAAXV?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Sets to bounds of the span of points, and return true (if all point values were finite).
    *
    * If the span is empty, set the rect to empty() and return true.
    * If any point contains an infinity or NaN, set the rect to empty and return false.
    *
    * @param pts    SkPoint span
    * example: https://fiddle.skia.org/c/@Rect_setBoundsCheck
    */
    setBoundsCheck :: (this: *SkRect, pts: SkSpan(SkPoint)) -> bool #cpp_method #foreign libskia "?setBoundsCheck@SkRect@@QEAA_NV?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Sets to bounds of the span of points.
    *
    * If the span is empty, set the rect to empty().
    * If any point contains an infinity or NaN, set the rect to NaN.
    *
    * @param pts    SkPoint span
    * example: https://fiddle.skia.org/c/@Rect_setBoundsNoCheck
    */
    setBoundsNoCheck :: (this: *SkRect, pts: SkSpan(SkPoint)) -> void #cpp_method #foreign libskia "?setBoundsNoCheck@SkRect@@QEAAXV?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Sets bounds to the smallest SkRect enclosing SkPoint p0 and p1. The result is
    sorted and may be empty. Does not check to see if values are finite.
    
    @param p0  corner to include
    @param p1  corner to include
    */
    set :: (this: *SkRect, p0: *SkPoint, p1: *SkPoint) -> void #cpp_method #foreign libskia "?set@SkRect@@QEAAXAEBUSkPoint@@0@Z";
    set :: (this: *SkRect, p0: SkPoint, p1: SkPoint) #no_context {
        set(this, *p0, *p1);
    }

    /** Sets SkRect to (x, y, x + width, y + height).
    Does not validate input; width or height may be negative.
    
    @param x       stored in fLeft
    @param y       stored in fTop
    @param width   added to x and stored in fRight
    @param height  added to y and stored in fBottom
    */
    setXYWH :: (this: *SkRect, x: float, y: float, width: float, height: float) -> void #cpp_method #foreign libskia "?setXYWH@SkRect@@QEAAXMMMM@Z";

    /** Sets SkRect to (0, 0, width, height). Does not validate input;
    width or height may be negative.
    
    @param width   stored in fRight
    @param height  stored in fBottom
    */
    setWH :: (this: *SkRect, width: float, height: float) -> void #cpp_method #foreign libskia "?setWH@SkRect@@QEAAXMM@Z";

    setIWH :: (this: *SkRect, width: s32, height: s32) -> void #cpp_method #foreign libskia "?setIWH@SkRect@@QEAAXHH@Z";

    /** Returns SkRect offset by (dx, dy).
    
    If dx is negative, SkRect returned is moved to the left.
    If dx is positive, SkRect returned is moved to the right.
    If dy is negative, SkRect returned is moved upward.
    If dy is positive, SkRect returned is moved downward.
    
    @param dx  added to fLeft and fRight
    @param dy  added to fTop and fBottom
    @return    SkRect offset on axes, with original width and height
    */
    makeOffset :: (this: *SkRect, dx: float, dy: float) -> SkRect #cpp_method #foreign libskia "?makeOffset@SkRect@@QEBA?AU1@MM@Z";

    /** Returns SkRect offset by v.
    
    @param v  added to rect
    @return    SkRect offset on axes, with original width and height
    */
    makeOffset :: (this: *SkRect, v: SkVector) -> SkRect #cpp_method #foreign libskia "?makeOffset@SkRect@@QEBA?AU1@USkPoint@@@Z";

    /** Returns SkRect, inset by (dx, dy).
    
    If dx is negative, SkRect returned is wider.
    If dx is positive, SkRect returned is narrower.
    If dy is negative, SkRect returned is taller.
    If dy is positive, SkRect returned is shorter.
    
    @param dx  added to fLeft and subtracted from fRight
    @param dy  added to fTop and subtracted from fBottom
    @return    SkRect inset symmetrically left and right, top and bottom
    */
    makeInset :: (this: *SkRect, dx: float, dy: float) -> SkRect #cpp_method #foreign libskia "?makeInset@SkRect@@QEBA?AU1@MM@Z";

    /** Returns SkRect, outset by (dx, dy).
    
    If dx is negative, SkRect returned is narrower.
    If dx is positive, SkRect returned is wider.
    If dy is negative, SkRect returned is shorter.
    If dy is positive, SkRect returned is taller.
    
    @param dx  subtracted to fLeft and added from fRight
    @param dy  subtracted to fTop and added from fBottom
    @return    SkRect outset symmetrically left and right, top and bottom
    */
    makeOutset :: (this: *SkRect, dx: float, dy: float) -> SkRect #cpp_method #foreign libskia "?makeOutset@SkRect@@QEBA?AU1@MM@Z";

    /** Offsets SkRect by adding dx to fLeft, fRight; and by adding dy to fTop, fBottom.
    
    If dx is negative, moves SkRect to the left.
    If dx is positive, moves SkRect to the right.
    If dy is negative, moves SkRect upward.
    If dy is positive, moves SkRect downward.
    
    @param dx  offset added to fLeft and fRight
    @param dy  offset added to fTop and fBottom
    */
    offset :: (this: *SkRect, dx: float, dy: float) -> void #cpp_method #foreign libskia "?offset@SkRect@@QEAAXMM@Z";

    /** Offsets SkRect by adding delta.fX to fLeft, fRight; and by adding delta.fY to
    fTop, fBottom.
    
    If delta.fX is negative, moves SkRect to the left.
    If delta.fX is positive, moves SkRect to the right.
    If delta.fY is negative, moves SkRect upward.
    If delta.fY is positive, moves SkRect downward.
    
    @param delta  added to SkRect
    */
    offset :: (this: *SkRect, delta: *SkPoint) -> void #cpp_method #foreign libskia "?offset@SkRect@@QEAAXAEBUSkPoint@@@Z";
    offset :: (this: *SkRect, delta: SkPoint) #no_context {
        offset(this, *delta);
    }

    /** Offsets SkRect so that fLeft equals newX, and fTop equals newY. width and height
    are unchanged.
    
    @param newX  stored in fLeft, preserving width()
    @param newY  stored in fTop, preserving height()
    */
    offsetTo :: (this: *SkRect, newX: float, newY: float) -> void #cpp_method #foreign libskia "?offsetTo@SkRect@@QEAAXMM@Z";

    /** Insets SkRect by (dx, dy).
    
    If dx is positive, makes SkRect narrower.
    If dx is negative, makes SkRect wider.
    If dy is positive, makes SkRect shorter.
    If dy is negative, makes SkRect taller.
    
    @param dx  added to fLeft and subtracted from fRight
    @param dy  added to fTop and subtracted from fBottom
    */
    inset :: (this: *SkRect, dx: float, dy: float) -> void #cpp_method #foreign libskia "?inset@SkRect@@QEAAXMM@Z";

    /** Outsets SkRect by (dx, dy).
    
    If dx is positive, makes SkRect wider.
    If dx is negative, makes SkRect narrower.
    If dy is positive, makes SkRect taller.
    If dy is negative, makes SkRect shorter.
    
    @param dx  subtracted to fLeft and added from fRight
    @param dy  subtracted to fTop and added from fBottom
    */
    outset :: (this: *SkRect, dx: float, dy: float) -> void #cpp_method #foreign libskia "?outset@SkRect@@QEAAXMM@Z";

    /** Returns true if SkRect intersects r, and sets SkRect to intersection.
    Returns false if SkRect does not intersect r, and leaves SkRect unchanged.
    
    Returns false if either r or SkRect is empty, leaving SkRect unchanged.
    
    @param r  limit of result
    @return   true if r and SkRect have area in common
    
    example: https://fiddle.skia.org/c/@Rect_intersect
    */
    intersect :: (this: *SkRect, r: *SkRect) -> bool #cpp_method #foreign libskia "?intersect@SkRect@@QEAA_NAEBU1@@Z";
    intersect :: (this: *SkRect, r: SkRect) -> bool #no_context {
        return intersect(this, *r);
    }

    /** Returns true if a intersects b, and sets SkRect to intersection.
    Returns false if a does not intersect b, and leaves SkRect unchanged.
    
    Returns false if either a or b is empty, leaving SkRect unchanged.
    
    @param a  SkRect to intersect
    @param b  SkRect to intersect
    @return   true if a and b have area in common
    */
    intersect :: (this: *SkRect, a: *SkRect, b: *SkRect) -> bool #cpp_method #foreign libskia "?intersect@SkRect@@QEAA_NAEBU1@0@Z";
    intersect :: (this: *SkRect, a: SkRect, b: SkRect) -> bool #no_context {
        return intersect(this, *a, *b);
    }

    Intersects :: (al: float, at: float, ar: float, ab: float, bl: float, bt: float, br: float, bb: float) -> bool #foreign libskia "?Intersects@SkRect@@CA_NMMMMMMMM@Z";

    /** Returns true if SkRect intersects r.
    Returns false if either r or SkRect is empty, or do not intersect.
    
    @param r  SkRect to intersect
    @return   true if r and SkRect have area in common
    */
    intersects :: (this: *SkRect, r: *SkRect) -> bool #cpp_method #foreign libskia "?intersects@SkRect@@QEBA_NAEBU1@@Z";
    intersects :: (this: *SkRect, r: SkRect) -> bool #no_context {
        return intersects(this, *r);
    }

    /** Returns true if a intersects b.
    Returns false if either a or b is empty, or do not intersect.
    
    @param a  SkRect to intersect
    @param b  SkRect to intersect
    @return   true if a and b have area in common
    */
    Intersects :: (a: *SkRect, b: *SkRect) -> bool #foreign libskia "?Intersects@SkRect@@SA_NAEBU1@0@Z";
    Intersects :: (a: SkRect, b: SkRect) -> bool #no_context {
        return Intersects(*a, *b);
    }

    /** Sets SkRect to the union of itself and r.
    
    Has no effect if r is empty. Otherwise, if SkRect is empty, sets
    SkRect to r.
    
    @param r  expansion SkRect
    
    example: https://fiddle.skia.org/c/@Rect_join_2
    */
    join :: (this: *SkRect, r: *SkRect) -> void #cpp_method #foreign libskia "?join@SkRect@@QEAAXAEBU1@@Z";
    join :: (this: *SkRect, r: SkRect) #no_context {
        join(this, *r);
    }

    /** Sets SkRect to the union of itself and r.
    
    Asserts if r is empty and SK_DEBUG is defined.
    If SkRect is empty, sets SkRect to r.
    
    May produce incorrect results if r is empty.
    
    @param r  expansion SkRect
    */
    joinNonEmptyArg :: (this: *SkRect, r: *SkRect) -> void #cpp_method #foreign libskia "?joinNonEmptyArg@SkRect@@QEAAXAEBU1@@Z";
    joinNonEmptyArg :: (this: *SkRect, r: SkRect) #no_context {
        joinNonEmptyArg(this, *r);
    }

    /** Sets SkRect to the union of itself and the construction.
    
    May produce incorrect results if SkRect or r is empty.
    
    @param r  expansion SkRect
    */
    joinPossiblyEmptyRect :: (this: *SkRect, r: *SkRect) -> void #cpp_method #foreign libskia "?joinPossiblyEmptyRect@SkRect@@QEAAXAEBU1@@Z";
    joinPossiblyEmptyRect :: (this: *SkRect, r: SkRect) #no_context {
        joinPossiblyEmptyRect(this, *r);
    }

    /** Returns true if: fLeft <= x < fRight && fTop <= y < fBottom.
    Returns false if SkRect is empty.
    
    @param x  test SkPoint x-coordinate
    @param y  test SkPoint y-coordinate
    @return   true if (x, y) is inside SkRect
    */
    contains :: (this: *SkRect, x: float, y: float) -> bool #cpp_method #foreign libskia "?contains@SkRect@@QEBA_NMM@Z";

    /** Returns true if SkRect contains r.
    Returns false if SkRect is empty or r is empty.
    
    SkRect contains r when SkRect area completely includes r area.
    
    @param r  SkRect contained
    @return   true if all sides of SkRect are outside r
    */
    contains :: (this: *SkRect, r: *SkRect) -> bool #cpp_method #foreign libskia "?contains@SkRect@@QEBA_NAEBU1@@Z";
    contains :: (this: *SkRect, r: SkRect) -> bool #no_context {
        return contains(this, *r);
    }

    /** Returns true if SkRect contains r.
    Returns false if SkRect is empty or r is empty.
    
    SkRect contains r when SkRect area completely includes r area.
    
    @param r  SkIRect contained
    @return   true if all sides of SkRect are outside r
    */
    contains :: (this: *SkRect, r: *SkIRect) -> bool #cpp_method #foreign libskia "?contains@SkRect@@QEBA_NAEBUSkIRect@@@Z";
    contains :: (this: *SkRect, r: SkIRect) -> bool #no_context {
        return contains(this, *r);
    }

    /** Sets SkIRect by adding 0.5 and discarding the fractional portion of SkRect
    members, using (sk_float_round2int(fLeft), sk_float_round2int(fTop),
    sk_float_round2int(fRight), sk_float_round2int(fBottom)).
    
    @param dst  storage for SkIRect
    */
    round :: (this: *SkRect, dst: *SkIRect) -> void #cpp_method #foreign libskia "?round@SkRect@@QEBAXPEAUSkIRect@@@Z";

    /** Sets SkIRect by discarding the fractional portion of fLeft and fTop; and rounding
    up fRight and fBottom, using
    (sk_float_floor2int(fLeft), sk_float_floor2int(fTop),
    sk_float_ceil2int(fRight), sk_float_ceil2int(fBottom)).
    
    @param dst  storage for SkIRect
    */
    roundOut :: (this: *SkRect, dst: *SkIRect) -> void #cpp_method #foreign libskia "?roundOut@SkRect@@QEBAXPEAUSkIRect@@@Z";

    /** Sets SkRect by discarding the fractional portion of fLeft and fTop; and rounding
    up fRight and fBottom, using
    (std::floor(fLeft), std::floor(fTop),
    std::ceil(fRight), std::ceil(fBottom)).
    
    @param dst  storage for SkRect
    */
    roundOut :: (this: *SkRect, dst: *SkRect) -> void #cpp_method #foreign libskia "?roundOut@SkRect@@QEBAXPEAU1@@Z";

    /** Sets SkRect by rounding up fLeft and fTop; and discarding the fractional portion
    of fRight and fBottom, using
    (sk_float_ceil2int(fLeft), sk_float_ceil2int(fTop),
    sk_float_floor2int(fRight), sk_float_floor2int(fBottom)).
    
    @param dst  storage for SkIRect
    */
    roundIn :: (this: *SkRect, dst: *SkIRect) -> void #cpp_method #foreign libskia "?roundIn@SkRect@@QEBAXPEAUSkIRect@@@Z";

    /** Returns SkIRect by adding 0.5 and discarding the fractional portion of SkRect
    members, using (sk_float_round2int(fLeft), sk_float_round2int(fTop),
    sk_float_round2int(fRight), sk_float_round2int(fBottom)).
    
    @return  rounded SkIRect
    */
    round :: (this: *SkRect) -> SkIRect #cpp_method #foreign libskia "?round@SkRect@@QEBA?AUSkIRect@@XZ";

    /** Sets SkIRect by discarding the fractional portion of fLeft and fTop; and rounding
    up fRight and fBottom, using
    (sk_float_floor2int(fLeft), sk_float_floor2int(fTop),
    sk_float_ceil2int(fRight), sk_float_ceil2int(fBottom)).
    
    @return  rounded SkIRect
    */
    roundOut :: (this: *SkRect) -> SkIRect #cpp_method #foreign libskia "?roundOut@SkRect@@QEBA?AUSkIRect@@XZ";

    /** Sets SkIRect by rounding up fLeft and fTop; and discarding the fractional portion
    of fRight and fBottom, using
    (sk_float_ceil2int(fLeft), sk_float_ceil2int(fTop),
    sk_float_floor2int(fRight), sk_float_floor2int(fBottom)).
    
    @return  rounded SkIRect
    */
    roundIn :: (this: *SkRect) -> SkIRect #cpp_method #foreign libskia "?roundIn@SkRect@@QEBA?AUSkIRect@@XZ";

    /** Swaps fLeft and fRight if fLeft is greater than fRight; and swaps
    fTop and fBottom if fTop is greater than fBottom. Result may be empty;
    and width() and height() will be zero or positive.
    */
    sort :: (this: *SkRect) -> void #cpp_method #foreign libskia "?sort@SkRect@@QEAAXXZ";

    /** Returns SkRect with fLeft and fRight swapped if fLeft is greater than fRight; and
    with fTop and fBottom swapped if fTop is greater than fBottom. Result may be empty;
    and width() and height() will be zero or positive.
    
    @return  sorted SkRect
    */
    makeSorted :: (this: *SkRect) -> SkRect #cpp_method #foreign libskia "?makeSorted@SkRect@@QEBA?AU1@XZ";

    /** Returns pointer to first float in SkRect, to treat it as an array with four
    entries.
    
    @return  pointer to fLeft
    */
    asScalars :: (this: *SkRect) -> *float #cpp_method #foreign libskia "?asScalars@SkRect@@QEBAPEBMXZ";

    /** Writes text representation of SkRect to standard output. Set asHex to true to
    generate exact binary representations of floating point numbers.
    
    @param asHex  true if SkScalar values are written as hexadecimal
    
    example: https://fiddle.skia.org/c/@Rect_dump
    */
    dump :: (this: *SkRect, asHex: bool) -> void #cpp_method #foreign libskia "?dump@SkRect@@QEBAX_N@Z";
    dumpToString :: (this: *SkRect, asHex: bool) -> SkString #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?dumpToString@SkRect@@QEBA?AVSkString@@_N@Z";

    /** Writes text representation of SkRect to standard output. The representation may be
    directly compiled as C++ code. Floating point values are written
    with limited precision; it may not be possible to reconstruct original SkRect
    from output.
    */
    dump :: (this: *SkRect) -> void #cpp_method #foreign libskia "?dump@SkRect@@QEBAXXZ";

    /** Writes text representation of SkRect to standard output. The representation may be
    directly compiled as C++ code. Floating point values are written
    in hexadecimal to preserve their exact bit pattern. The output reconstructs the
    original SkRect.
    
    Use instead of dump() when submitting
    */
    dumpHex :: (this: *SkRect) -> void #cpp_method #foreign libskia "?dumpHex@SkRect@@QEBAXXZ";
}

// Represents an arc along an oval boundary, or a closed wedge of the oval.
SkArc :: struct {
    Type :: enum u8 {
        Arc   :: 0;
        Wedge :: 1;

        kArc   :: Arc;
        kWedge :: Wedge;
    }

//     Constructor :: (this: *SkArc) -> void #cpp_method #foreign libskia "??0SkArc@@QEAA@XZ";
//     CopyConstructor :: (this: *SkArc, arc: *SkArc) -> void #cpp_method #foreign libskia "??0SkArc@@QEAA@AEBU0@@Z";
    CopyConstructor :: (this: *SkArc, arc: SkArc) #no_context {
        CopyConstructor(this, *arc);
    }

//     oval :: (this: *SkArc) -> *SkRect #cpp_method #foreign libskia "?oval@SkArc@@QEBAAEBUSkRect@@XZ";
//     startAngle :: (this: *SkArc) -> SkScalar #cpp_method #foreign libskia "?startAngle@SkArc@@QEBAMXZ";
//     sweepAngle :: (this: *SkArc) -> SkScalar #cpp_method #foreign libskia "?sweepAngle@SkArc@@QEBAMXZ";
//     isWedge :: (this: *SkArc) -> bool #cpp_method #foreign libskia "?isWedge@SkArc@@QEBA_NXZ";

    // Preferred factory that explicitly states which type of arc
//     Make :: (oval: *SkRect, startAngleDegrees: SkScalar, sweepAngleDegrees: SkScalar, type: Type) -> SkArc #cpp_return_type_is_non_pod #foreign libskia "?Make@SkArc@@SA?AU1@AEBUSkRect@@MMW4Type@1@@Z";
    Make :: (oval: SkRect, startAngleDegrees: SkScalar, sweepAngleDegrees: SkScalar, type: Type) -> SkArc #no_context {
        return Make(*oval, startAngleDegrees, sweepAngleDegrees, type);
    }

    // Deprecated factory to assist with legacy code based on `useCenter`
//     Make :: (oval: *SkRect, startAngleDegrees: SkScalar, sweepAngleDegrees: SkScalar, useCenter: bool) -> SkArc #cpp_return_type_is_non_pod #foreign libskia "?Make@SkArc@@SA?AU1@AEBUSkRect@@MM_N@Z";
    Make :: (oval: SkRect, startAngleDegrees: SkScalar, sweepAngleDegrees: SkScalar, useCenter: bool) -> SkArc #no_context {
        return Make(*oval, startAngleDegrees, sweepAngleDegrees, useCenter);
    }

    // Bounds of oval containing the arc.
    fOval:       SkRect;

    // Angle in degrees where the arc begins. Zero means horizontally to the right.
    fStartAngle: SkScalar = 0;

    // Sweep angle in degrees; positive is clockwise.
    fSweepAngle: SkScalar = 0;

    fType:       Type = .Arc;

//     Constructor :: (this: *SkArc, oval: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, type: Type) -> void #cpp_method #foreign libskia "??0SkArc@@AEAA@AEBUSkRect@@MMW4Type@0@@Z";
    Constructor :: (this: *SkArc, oval: SkRect, startAngle: SkScalar, sweepAngle: SkScalar, type: Type) #no_context {
        Constructor(this, *oval, startAngle, sweepAngle, type);
    }
}

// operator_assign :: (this: *SkArc, arc: *SkArc) -> *SkArc #cpp_method #foreign libskia "??4SkArc@@QEAAAEAU0@AEBU0@@Z";
operator_assign :: (this: *SkArc, arc: SkArc) -> *SkArc #no_context {
    return operator_assign(this, *arc);
}

/**
*  Blends are operators that take in two colors (source, destination) and return a new color.
*  Many of these operate the same on all 4 components: red, green, blue, alpha. For these,
*  we just document what happens to one component, rather than naming each one separately.
*
*  Different SkColorTypes have different representations for color components:
*      8-bit: 0..255
*      6-bit: 0..63
*      5-bit: 0..31
*      4-bit: 0..15
*     floats: 0...1
*
*  The documentation is expressed as if the component values are always 0..1 (floats).
*
*  For brevity, the documentation uses the following abbreviations
*  s  : source
*  d  : destination
*  sa : source alpha
*  da : destination alpha
*
*  Results are abbreviated
*  r  : if all 4 components are computed in the same manner
*  ra : result alpha component
*  rc : result "color": red, green, blue components
*/
SkBlendMode :: enum s32 {
    Clear             :: 0;
    Src               :: 1;
    Dst               :: 2;
    SrcOver           :: 3;
    DstOver           :: 4;
    SrcIn             :: 5;
    DstIn             :: 6;
    SrcOut            :: 7;
    DstOut            :: 8;
    SrcATop           :: 9;
    DstATop           :: 10;
    Xor               :: 11;
    Plus              :: 12;
    Modulate          :: 13;
    Screen            :: 14;

    Overlay           :: 15;
    Darken            :: 16;
    Lighten           :: 17;
    ColorDodge        :: 18;
    ColorBurn         :: 19;
    HardLight         :: 20;
    SoftLight         :: 21;
    Difference        :: 22;
    Exclusion         :: 23;
    Multiply          :: 24;

    Hue               :: 25;
    Saturation        :: 26;
    Color             :: 27;
    Luminosity        :: 28;

    LastCoeffMode     :: 14;
    LastSeparableMode :: 24;
    LastMode          :: 28;

    kClear             :: Clear;
    kSrc               :: Src;
    kDst               :: Dst;
    kSrcOver           :: SrcOver;
    kDstOver           :: DstOver;
    kSrcIn             :: SrcIn;
    kDstIn             :: DstIn;
    kSrcOut            :: SrcOut;
    kDstOut            :: DstOut;
    kSrcATop           :: SrcATop;
    kDstATop           :: DstATop;
    kXor               :: Xor;
    kPlus              :: Plus;
    kModulate          :: Modulate;
    kScreen            :: Screen;

    kOverlay           :: Overlay;
    kDarken            :: Darken;
    kLighten           :: Lighten;
    kColorDodge        :: ColorDodge;
    kColorBurn         :: ColorBurn;
    kHardLight         :: HardLight;
    kSoftLight         :: SoftLight;
    kDifference        :: Difference;
    kExclusion         :: Exclusion;
    kMultiply          :: Multiply;

    kHue               :: Hue;
    kSaturation        :: Saturation;
    kColor             :: Color;
    kLuminosity        :: Luminosity;

    kLastCoeffMode     :: LastCoeffMode;
    kLastSeparableMode :: LastSeparableMode;
    kLastMode          :: LastMode;
}

kSkBlendModeCount: s32 : cast(s32) (SkBlendMode.LastMode + 1);

/**
* For Porter-Duff SkBlendModes (those <= kLastCoeffMode), these coefficients describe the blend
* equation used. Coefficient-based blend modes specify an equation:
* ('dstCoeff' * dst + 'srcCoeff' * src), where the coefficient values are constants, functions of
* the src or dst alpha, or functions of the src or dst color.
*/
SkBlendModeCoeff :: enum s32 {
    Zero       :: 0;
    One        :: 1;
    SC         :: 2;
    ISC        :: 3;
    DC         :: 4;
    IDC        :: 5;
    SA         :: 6;
    ISA        :: 7;
    DA         :: 8;
    IDA        :: 9;

    CoeffCount :: 10;

    kZero       :: Zero;
    kOne        :: One;
    kSC         :: SC;
    kISC        :: ISC;
    kDC         :: DC;
    kIDC        :: IDC;
    kSA         :: SA;
    kISA        :: ISA;
    kDA         :: DA;
    kIDA        :: IDA;

    kCoeffCount :: CoeffCount;
}

/**
* Returns true if 'mode' is a coefficient-based blend mode (<= kLastCoeffMode). If true is
* returned, the mode's src and dst coefficient functions are set in 'src' and 'dst'.
*/
SkBlendMode_AsCoeff :: (mode: SkBlendMode, src: *SkBlendModeCoeff, dst: *SkBlendModeCoeff) -> bool #foreign libskia "?SkBlendMode_AsCoeff@@YA_NW4SkBlendMode@@PEAW4SkBlendModeCoeff@@1@Z";

/** Returns name of blendMode as null-terminated C string.

@return           C string
*/
SkBlendMode_Name :: (blendMode: SkBlendMode) -> *u8 #foreign libskia "?SkBlendMode_Name@@YAPEBDW4SkBlendMode@@@Z";

SkClipOp :: enum s32 {
    Difference    :: 0;
    Intersect     :: 1;
    Max_EnumValue :: 1;

    kDifference    :: Difference;
    kIntersect     :: Intersect;
    kMax_EnumValue :: Max_EnumValue;
}

/** \enum SkAlphaType
Describes how to interpret the alpha component of a pixel. A pixel may
be opaque, or alpha, describing multiple levels of transparency.

In simple blending, alpha weights the draw color and the destination
color to create a new color. If alpha describes a weight from zero to one:

new color = draw color * alpha + destination color * (1 - alpha)

In practice alpha is encoded in two or more bits, where 1.0 equals all bits set.

RGB may have alpha included in each component value; the stored
value is the original RGB multiplied by alpha. Premultiplied color
components improve performance.
*/
SkAlphaType :: enum s32 {
    Unknown_SkAlphaType  :: 0;
    Opaque_SkAlphaType   :: 1;
    Premul_SkAlphaType   :: 2;
    Unpremul_SkAlphaType :: 3;
    LastEnum_SkAlphaType :: 3;

    kUnknown_SkAlphaType  :: Unknown_SkAlphaType;
    kOpaque_SkAlphaType   :: Opaque_SkAlphaType;
    kPremul_SkAlphaType   :: Premul_SkAlphaType;
    kUnpremul_SkAlphaType :: Unpremul_SkAlphaType;
    kLastEnum_SkAlphaType :: LastEnum_SkAlphaType;
}

/** Returns true if SkAlphaType equals kOpaque_SkAlphaType.

kOpaque_SkAlphaType is a hint that the SkColorType is opaque, or that all
alpha values are set to their 1.0 equivalent. If SkAlphaType is
kOpaque_SkAlphaType, and SkColorType is not opaque, then the result of
drawing any pixel with a alpha value less than 1.0 is undefined.
*/
// SkAlphaTypeIsOpaque :: (at: SkAlphaType) -> bool #foreign libskia "?SkAlphaTypeIsOpaque@@YA_NW4SkAlphaType@@@Z";

/** 8-bit type for an alpha value. 255 is 100% opaque, zero is 100% transparent.
*/
SkAlpha :: u8;

/** 32-bit ARGB color value, unpremultiplied. Color components are always in
a known order. This is different from SkPMColor, which has its bytes in a configuration
dependent order, to match the format of kBGRA_8888_SkColorType bitmaps. SkColor
is the type used to specify colors in SkPaint and in gradients.

Color that is premultiplied has the same component values as color
that is unpremultiplied if alpha is 255, fully opaque, although may have the
component values in a different order.
*/
SkColor :: u32;

/** Returns color value from 8-bit component values. Asserts if SK_DEBUG is defined
if a, r, g, or b exceed 255. Since color is unpremultiplied, a may be smaller
than the largest of r, g, and b.

@param a  amount of alpha, from fully transparent (0) to fully opaque (255)
@param r  amount of red, from no red (0) to full red (255)
@param g  amount of green, from no green (0) to full green (255)
@param b  amount of blue, from no blue (0) to full blue (255)
@return   color and alpha, unpremultiplied
*/
// SkColorSetARGB :: (a: U8CPU, r: U8CPU, g: U8CPU, b: U8CPU) -> SkColor #foreign libskia "?SkColorSetARGB@@YAIIIII@Z";

/** Returns unpremultiplied color with red, blue, and green set from c; and alpha set
from a. Alpha component of c is ignored and is replaced by a in result.

@param c  packed RGB, eight bits per component
@param a  alpha: transparent at zero, fully opaque at 255
@return   color with transparency
*/
// SkColorSetA :: (c: SkColor, a: U8CPU) -> SkColor #foreign libskia "?SkColorSetA@@YAIII@Z";

/** Represents fully transparent SkAlpha value. SkAlpha ranges from zero,
fully transparent; to 255, fully opaque.
*/
SK_AlphaTRANSPARENT: SkAlpha : 0;

/** Represents fully opaque SkAlpha value. SkAlpha ranges from zero,
fully transparent; to 255, fully opaque.
*/
SK_AlphaOPAQUE: SkAlpha : 255;

/** Converts RGB to its HSV components.
hsv[0] contains hsv hue, a value from zero to less than 360.
hsv[1] contains hsv saturation, a value from zero to one.
hsv[2] contains hsv value, a value from zero to one.

@param red    red component value from zero to 255
@param green  green component value from zero to 255
@param blue   blue component value from zero to 255
@param hsv    three element array which holds the resulting HSV components
*/
SkRGBToHSV :: (red: U8CPU, green: U8CPU, blue: U8CPU, hsv: *[3] SkScalar) -> void #foreign libskia "?SkRGBToHSV@@YAXIIIQEAM@Z";

/** Converts ARGB to its HSV components. Alpha in ARGB is ignored.
hsv[0] contains hsv hue, and is assigned a value from zero to less than 360.
hsv[1] contains hsv saturation, a value from zero to one.
hsv[2] contains hsv value, a value from zero to one.

@param color  ARGB color to convert
@param hsv    three element array which holds the resulting HSV components
*/
// SkColorToHSV :: (color: SkColor, hsv: *[3] SkScalar) -> void #foreign libskia "?SkColorToHSV@@YAXIQEAM@Z";

/** Converts HSV components to an ARGB color. Alpha is passed through unchanged.
hsv[0] represents hsv hue, an angle from zero to less than 360.
hsv[1] represents hsv saturation, and varies from zero to one.
hsv[2] represents hsv value, and varies from zero to one.

Out of range hsv values are pinned.

@param alpha  alpha component of the returned ARGB color
@param hsv    three element array which holds the input HSV components
@return       ARGB equivalent to HSV
*/
SkHSVToColor :: (alpha: U8CPU, hsv: *[3] SkScalar) -> SkColor #foreign libskia "?SkHSVToColor@@YAIIQEBM@Z";

/** Converts HSV components to an ARGB color. Alpha is set to 255.
hsv[0] represents hsv hue, an angle from zero to less than 360.
hsv[1] represents hsv saturation, and varies from zero to one.
hsv[2] represents hsv value, and varies from zero to one.

Out of range hsv values are pinned.

@param hsv  three element array which holds the input HSV components
@return     RGB equivalent to HSV
*/
// SkHSVToColor :: (hsv: *[3] SkScalar) -> SkColor #foreign libskia "?SkHSVToColor@@YAIQEBM@Z";

/** 32-bit ARGB color value, premultiplied. The byte order for this value is
configuration dependent, matching the format of kBGRA_8888_SkColorType bitmaps.
This is different from SkColor, which is unpremultiplied, and is always in the
same byte order.
*/
SkPMColor :: u32;

/** Returns a SkPMColor value from unpremultiplied 8-bit component values.

@param a  amount of alpha, from fully transparent (0) to fully opaque (255)
@param r  amount of red, from no red (0) to full red (255)
@param g  amount of green, from no green (0) to full green (255)
@param b  amount of blue, from no blue (0) to full blue (255)
@return   premultiplied color
*/
SkPreMultiplyARGB :: (a: U8CPU, r: U8CPU, g: U8CPU, b: U8CPU) -> SkPMColor #foreign libskia "?SkPreMultiplyARGB@@YAIIIII@Z";

/** Returns pmcolor closest to color c. Multiplies c RGB components by the c alpha,
and arranges the bytes to match the format of kN32_SkColorType.

@param c  unpremultiplied ARGB color
@return   premultiplied color
*/
SkPreMultiplyColor :: (c: SkColor) -> SkPMColor #foreign libskia "?SkPreMultiplyColor@@YAII@Z";

/** \enum SkColorChannel
Describes different color channels one can manipulate
*/
SkColorChannel :: enum s32 {
    R        :: 0;
    G        :: 1;
    B        :: 2;
    A        :: 3;

    LastEnum :: 3;

    kR        :: R;
    kG        :: G;
    kB        :: B;
    kA        :: A;

    kLastEnum :: LastEnum;
}

/** Used to represent the channels available in a color type or texture format as a mask. */
SkColorChannelFlag :: enum u32 {
    Red_SkColorChannelFlag        :: 1;
    Green_SkColorChannelFlag      :: 2;
    Blue_SkColorChannelFlag       :: 4;
    Alpha_SkColorChannelFlag      :: 8;
    Gray_SkColorChannelFlag       :: 16;

    GrayAlpha_SkColorChannelFlags :: 24;
    RG_SkColorChannelFlags        :: 3;
    RGB_SkColorChannelFlags       :: 7;
    RGBA_SkColorChannelFlags      :: 15;

    kRed_SkColorChannelFlag        :: Red_SkColorChannelFlag;
    kGreen_SkColorChannelFlag      :: Green_SkColorChannelFlag;
    kBlue_SkColorChannelFlag       :: Blue_SkColorChannelFlag;
    kAlpha_SkColorChannelFlag      :: Alpha_SkColorChannelFlag;
    kGray_SkColorChannelFlag       :: Gray_SkColorChannelFlag;

    kGrayAlpha_SkColorChannelFlags :: GrayAlpha_SkColorChannelFlags;
    kRG_SkColorChannelFlags        :: RG_SkColorChannelFlags;
    kRGB_SkColorChannelFlags       :: RGB_SkColorChannelFlags;
    kRGBA_SkColorChannelFlags      :: RGBA_SkColorChannelFlags;
}

/** \struct SkRGBA4f
RGBA color value, holding four floating point components. Color components are always in
a known order. kAT determines if the SkRGBA4f's R, G, and B components are premultiplied
by alpha or not.

Skia's public API always uses unpremultiplied colors, which can be stored as
SkRGBA4f<kUnpremul_SkAlphaType>. For convenience, this type can also be referred to
as SkColor4f.
*/
SkRGBA4f :: struct(kAT: SkAlphaType) {
    fR: float; //!< red component
    fG: float; //!< green component
    fB: float; //!< blue component
    fA: float; //!< alpha component
}

/** \struct SkColor4f
RGBA color value, holding four floating point components. Color components are always in
a known order, and are unpremultiplied.

This is a specialization of SkRGBA4f. For details, @see SkRGBA4f.
*/
SkColor4f :: SkRGBA4f(.Unpremul_SkAlphaType);

FromColor :: (this: *void /* Unknown type */, unknown0: SkColor) -> SkColor4f #cpp_method #foreign libskia "?FromColor@?$SkRGBA4f@$02@@SA?AU1@I@Z";
toSkColor :: (this: *void /* Unknown type */) -> SkColor #cpp_method #foreign libskia "?toSkColor@?$SkRGBA4f@$02@@QEBAIXZ";
toBytes_RGBA :: (this: *void /* Unknown type */) -> u32 #cpp_method #foreign libskia "?toBytes_RGBA@?$SkRGBA4f@$02@@QEBAIXZ";
FromBytes_RGBA :: (this: *void /* Unknown type */, color: u32) -> SkColor4f #cpp_method #foreign libskia "?FromBytes_RGBA@?$SkRGBA4f@$02@@SA?AU1@I@Z";

SkTextEncoding :: enum s32 {
    UTF8    :: 0;
    UTF16   :: 1;
    UTF32   :: 2;
    GlyphID :: 3;

    kUTF8    :: UTF8;
    kUTF16   :: UTF16;
    kUTF32   :: UTF32;
    kGlyphID :: GlyphID;
}

SkFontHinting :: enum s32 {
    None   :: 0;
    Slight :: 1;
    Normal :: 2;
    Full   :: 3;

    kNone   :: None;
    kSlight :: Slight;
    kNormal :: Normal;
    kFull   :: Full;
}

/** \class SkRefCntBase

SkRefCntBase is the base class for objects that may be shared by multiple
objects. When an existing owner wants to share a reference, it calls ref().
When an owner wants to release its reference, it calls unref(). When the
shared object's reference count goes to zero as the result of an unref()
call, its (virtual) destructor is called. It is an error for the
destructor to be called explicitly (or via the object going out of scope on
the stack or calling delete) if getRefCnt() > 1.
*/
SkRefCntBase :: struct {
    vtable:                  *SkRefCntBase_VTable;
    using skrefcntbase__raw: SkRefCntBase__RAW;
}
// SkRefCntBase without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkRefCntBase
SkRefCntBase__RAW :: struct {
    /** Default construct, initializing the reference count to 1.
    */
    Constructor :: (this: *SkRefCntBase) -> void #cpp_method #foreign libskia "??0SkRefCntBase@@QEAA@XZ";

    /** May return true if the caller is the only owner.
    *  Ensures that all previous owner's actions are complete.
    */
    unique :: (this: *SkRefCntBase) -> bool #cpp_method #foreign libskia "?unique@SkRefCntBase@@QEBA_NXZ";

    /** Increment the reference count. Must be balanced by a call to unref().
    */
    ref :: (this: *SkRefCntBase) -> void #cpp_method #foreign libskia "?ref@SkRefCntBase@@QEBAXXZ";

    /** Decrement the reference count. If the reference count is 1 before the
    decrement, then delete the object. Note that if this is the case, then
    the object needs to have been allocated via new, and not on the stack.
    */
    unref :: (this: *SkRefCntBase) -> void #cpp_method #foreign libskia "?unref@SkRefCntBase@@QEBAXXZ";

    /** Return the reference count. Use only for debugging. */
//     getRefCnt :: (this: *SkRefCntBase) -> s32 #cpp_method #foreign libskia "?getRefCnt@SkRefCntBase@@AEBAHXZ";

    fRefCnt: std.atomic(s32);

//     CopyConstructor :: (this: *SkRefCntBase, unknown0: *SkRefCntBase) -> void #cpp_method #foreign libskia "??0SkRefCntBase@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkRefCntBase, unknown0: SkRefCntBase) #no_context {
        CopyConstructor(this, *unknown0);
    }

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Destruct, asserting that the reference count is 1.
    */
    virtual_Destructor :: (this: *SkRefCntBase, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkRefCntBase@@UEAA@XZ";

    /**
    *  Called when the ref count goes to 0.
    */
    virtual_internal_dispose :: (this: *SkRefCntBase) -> void #cpp_method #foreign libskia "?internal_dispose@SkRefCntBase@@EEBAXXZ";
}

// operator_assign :: (this: *SkRefCntBase, unknown0: *SkRefCntBase) -> *SkRefCntBase #cpp_method #foreign libskia "??4SkRefCntBase@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkRefCntBase, unknown0: SkRefCntBase) -> *SkRefCntBase #no_context {
    return operator_assign(this, *unknown0);
}
SkRefCntBase_VTable :: struct #type_info_none {
    Destructor:       #type (this: *SkRefCntBase, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    internal_dispose: #type (this: *SkRefCntBase) -> void #cpp_method;
}
SkRefCntBase_Destructor :: inline (this: *SkRefCntBase, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkRefCntBase_internal_dispose :: inline (this: *SkRefCntBase) { this.vtable.internal_dispose(this); }

get_vtable :: (obj: *SkRefCntBase) -> *SkRefCntBase_VTable { return obj.vtable; }


SkRefCnt :: struct {
    vtable:              *SkRefCntBase_VTable;
    using skrefcnt__raw: SkRefCnt__RAW;
    #place vtable; #as skrefcntbase: SkRefCntBase; // Support cast to SkRefCntBase
}
// SkRefCnt without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkRefCnt
SkRefCnt__RAW :: struct {
    using skrefcntbase__raw: SkRefCntBase__RAW;
}

// This is a variant of SkRefCnt that's Not Virtual, so weighs 4 bytes instead of 8 or 16.
// There's only benefit to using this if the deriving class does not otherwise need a vtable.
SkNVRefCnt :: struct(Derived: Type) {
    fRefCnt: std.atomic(s32);
}

/**
*  Shared pointer class to wrap classes that support a ref()/unref() interface.
*
*  This can be used for classes inheriting from SkRefCnt, but it also works for other
*  classes that match the interface, but have different internal choices: e.g. the hosted class
*  may have its ref/unref be thread-safe, but that is not assumed/imposed by sk_sp.
*
*  Declared with the trivial_abi attribute where supported so that sk_sp and types containing it
*  may be considered as trivially relocatable by the compiler so that destroying-move operations
*  i.e. move constructor followed by destructor can be optimized to memcpy.
*/
sk_sp :: struct(T: Type) {
    element_type :: T;

    sk_is_trivially_relocatable :: std.true_type;

    fPtr:                        *T;
}

SkReadBuffer :: struct {}
SkWriteBuffer :: struct {}
SkDeserialProcs :: struct {}
SkSerialProcs :: struct {}

/** \class SkFlattenable

SkFlattenable is the base class for objects that need to be flattened
into a data stream for either transport or as part of the key to the
font cache.
*/
SkFlattenable :: struct {
    vtable:                   *SkFlattenable_VTable;
    using skflattenable__raw: SkFlattenable__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkFlattenable without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFlattenable
SkFlattenable__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    Type :: enum s32 {
        ColorFilter_Type :: 0;
        Blender_Type     :: 1;
        Drawable_Type    :: 2;
        DrawLooper_Type  :: 3;
        ImageFilter_Type :: 4;
        MaskFilter_Type  :: 5;
        PathEffect_Type  :: 6;
        Shader_Type      :: 7;

        kSkColorFilter_Type :: ColorFilter_Type;
        kSkBlender_Type     :: Blender_Type;
        kSkDrawable_Type    :: Drawable_Type;
        kSkDrawLooper_Type  :: DrawLooper_Type;
        kSkImageFilter_Type :: ImageFilter_Type;
        kSkMaskFilter_Type  :: MaskFilter_Type;
        kSkPathEffect_Type  :: PathEffect_Type;
        kSkShader_Type      :: Shader_Type;
    }

    Factory :: #type (unknown0: *SkReadBuffer) -> sk_sp(SkFlattenable) #c_call #cpp_return_type_is_non_pod;

    Constructor :: (this: *SkFlattenable) -> void #cpp_method #foreign libskia "??0SkFlattenable@@QEAA@XZ";

    NameToFactory :: (name: *u8) -> SkFlattenable.Factory #foreign libskia "?NameToFactory@SkFlattenable@@SAP6A?AV?$sk_sp@VSkFlattenable@@@@AEAVSkReadBuffer@@@ZQEBD@Z";
    FactoryToName :: (unknown0: SkFlattenable.Factory) -> *u8 #foreign libskia "?FactoryToName@SkFlattenable@@SAPEBDP6A?AV?$sk_sp@VSkFlattenable@@@@AEAVSkReadBuffer@@@Z@Z";

    Register :: (name: *u8, unknown0: SkFlattenable.Factory) -> void #foreign libskia "?Register@SkFlattenable@@SAXQEBDP6A?AV?$sk_sp@VSkFlattenable@@@@AEAVSkReadBuffer@@@Z@Z";

    //
    // public ways to serialize / deserialize
    //
    serialize :: (this: *SkFlattenable, unknown0: *SkSerialProcs = null) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@SkFlattenable@@QEBA?AV?$sk_sp@VSkData@@@@PEBUSkSerialProcs@@@Z";
    serialize :: (this: *SkFlattenable, memory: *void, memory_size: u64, unknown0: *SkSerialProcs = null) -> u64 #cpp_method #foreign libskia "?serialize@SkFlattenable@@QEBA_KPEAX_KPEBUSkSerialProcs@@@Z";

    Deserialize :: (unknown0: SkFlattenable.Type, data: *void, length: u64, procs: *SkDeserialProcs = null) -> sk_sp(SkFlattenable) #cpp_return_type_is_non_pod #foreign libskia "?Deserialize@SkFlattenable@@SA?AV?$sk_sp@VSkFlattenable@@@@W4Type@1@PEBX_KPEBUSkDeserialProcs@@@Z";

    PrivateInitializer :: struct {
        using privateinitializer__raw: PrivateInitializer__RAW;
        __empty_struct_padding:        u8; // C++ makes empty structs have length 1
    }
        // PrivateInitializer without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from PrivateInitializer
    PrivateInitializer__RAW :: struct {
//         InitEffects :: () -> void #foreign libskia "?InitEffects@PrivateInitializer@SkFlattenable@@SAXXZ";
//         InitImageFilters :: () -> void #foreign libskia "?InitImageFilters@PrivateInitializer@SkFlattenable@@SAXXZ";
    }

    RegisterFlattenablesIfNeeded :: () -> void #foreign libskia "?RegisterFlattenablesIfNeeded@SkFlattenable@@CAXXZ";
    Finalize :: () -> void #foreign libskia "?Finalize@SkFlattenable@@CAXXZ";

    INHERITED :: SkRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Implement this to return a factory function pointer that can be called
    to recreate your class given a buffer (previously written to by your
    override of flatten().
    */
//     virtual_getFactory :: (this: *SkFlattenable) -> SkFlattenable.Factory #cpp_method #foreign libskia "?getFactory@SkFlattenable@@UEBAP6A?AV?$sk_sp@VSkFlattenable@@@@AEAVSkReadBuffer@@@ZXZ";

    /**
    *  Returns the name of the object's class.
    */
//     virtual_getTypeName :: (this: *SkFlattenable) -> *u8 #cpp_method #foreign libskia "?getTypeName@SkFlattenable@@UEBAPEBDXZ";

    /**
    *  Override this if your subclass needs to record data that it will need to recreate itself
    *  from its CreateProc (returned by getFactory()).
    *
    *  DEPRECATED public : will move to protected ... use serialize() instead
    */
    virtual_flatten :: (this: *SkFlattenable, unknown0: *SkWriteBuffer) -> void #cpp_method #foreign libskia "?flatten@SkFlattenable@@UEBAXAEAVSkWriteBuffer@@@Z";

//     virtual_getFlattenableType :: (this: *SkFlattenable) -> SkFlattenable.Type #cpp_method #foreign libskia "?getFlattenableType@SkFlattenable@@UEBA?AW4Type@1@XZ";
}
SkFlattenable_VTable :: struct #type_info_none {
    using vtable:       SkRefCntBase_VTable;

    getFactory:         #type (this: *SkFlattenable) -> SkFlattenable.Factory #cpp_method;

    getTypeName:        #type (this: *SkFlattenable) -> *u8 #cpp_method;

    flatten:            #type (this: *SkFlattenable, unknown0: *SkWriteBuffer) -> void #cpp_method;

    getFlattenableType: #type (this: *SkFlattenable) -> SkFlattenable.Type #cpp_method;
}
SkFlattenable_getFactory :: inline (this: *SkFlattenable) -> SkFlattenable.Factory { return this.vtable.getFactory(this); }

SkFlattenable_getTypeName :: inline (this: *SkFlattenable) -> *u8 { return this.vtable.getTypeName(this); }

SkFlattenable_flatten :: inline (this: *SkFlattenable, unknown0: *SkWriteBuffer) { this.vtable.flatten(this, unknown0); }

SkFlattenable_getFlattenableType :: inline (this: *SkFlattenable) -> SkFlattenable.Type { return this.vtable.getFlattenableType(this); }

get_vtable :: (obj: *SkFlattenable) -> *SkFlattenable_VTable { return obj.vtable; }


SkColorFilter :: struct {}

/**
*  Base class for image filters. If one is installed in the paint, then all drawing occurs as
*  usual, but it is as if the drawing happened into an offscreen (before the xfermode is applied).
*  This offscreen bitmap will then be handed to the imagefilter, who in turn creates a new bitmap
*  which is what will finally be drawn to the device (using the original xfermode).
*
*  The local space of image filters matches the local space of the drawn geometry. For instance if
*  there is rotation on the canvas, the blur will be computed along those rotated axes and not in
*  the device space. In order to achieve this result, the actual drawing of the geometry may happen
*  in an unrotated coordinate system so that the filtered image can be computed more easily, and
*  then it will be post transformed to match what would have been produced if the geometry were
*  drawn with the total canvas matrix to begin with.
*/
SkImageFilter :: struct {
    vtable:                   *SkImageFilter_VTable;
    using skimagefilter__raw: SkImageFilter__RAW;
    #place vtable; #as skflattenable: SkFlattenable; // Support cast to SkFlattenable
}
// SkImageFilter without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkImageFilter
SkImageFilter__RAW :: struct {
    using,except(INHERITED) skflattenable__raw: SkFlattenable__RAW;

    MapDirection :: enum s32 {
        Forward_MapDirection :: 0;
        Reverse_MapDirection :: 1;

        kForward_MapDirection :: Forward_MapDirection;
        kReverse_MapDirection :: Reverse_MapDirection;
    }

    /**
    * Map a device-space rect recursively forward or backward through the filter DAG.
    * kForward_MapDirection is used to determine which pixels of the destination canvas a source
    * image rect would touch after filtering. kReverse_MapDirection is used to determine which rect
    * of the source image would be required to fill the given rect (typically, clip bounds). Used
    * for clipping and temp-buffer allocations, so the result need not be exact, but should never
    * be smaller than the real answer. The default implementation recursively unions all input
    * bounds, or returns the source rect if no inputs.
    *
    * In kReverse mode, 'inputRect' is the device-space bounds of the input pixels. In kForward
    * mode it should always be null. If 'inputRect' is null in kReverse mode the resulting answer
    * may be incorrect.
    */
    filterBounds :: (this: *SkImageFilter, src: *SkIRect, ctm: *SkMatrix, unknown0: SkImageFilter.MapDirection, inputRect: *SkIRect = null) -> SkIRect #cpp_method #foreign libskia "?filterBounds@SkImageFilter@@QEBA?AUSkIRect@@AEBU2@AEBVSkMatrix@@W4MapDirection@1@PEBU2@@Z";
    filterBounds :: (this: *SkImageFilter, src: SkIRect, ctm: SkMatrix, unknown0: SkImageFilter.MapDirection, inputRect: *SkIRect = null) -> SkIRect #no_context {
        return filterBounds(this, *src, *ctm, unknown0, inputRect);
    }

    /**
    *  Returns whether this image filter is a color filter and puts the color filter into the
    *  "filterPtr" parameter if it can. Does nothing otherwise.
    *  If this returns false, then the filterPtr is unchanged.
    *  If this returns true, then if filterPtr is not null, it must be set to a ref'd colorfitler
    *  (i.e. it may not be set to NULL).
    */
    isColorFilterNode :: (this: *SkImageFilter, filterPtr: **SkColorFilter) -> bool #cpp_method #foreign libskia "?isColorFilterNode@SkImageFilter@@QEBA_NPEAPEAVSkColorFilter@@@Z";

    // DEPRECATED : use isColorFilterNode() instead
    asColorFilter :: (this: *SkImageFilter, filterPtr: **SkColorFilter) -> bool #cpp_method #foreign libskia "?asColorFilter@SkImageFilter@@QEBA_NPEAPEAVSkColorFilter@@@Z";

    /**
    *  Returns true (and optionally returns a ref'd filter) if this imagefilter can be completely
    *  replaced by the returned colorfilter. i.e. the two effects will affect drawing in the same
    *  way.
    */
    asAColorFilter :: (this: *SkImageFilter, filterPtr: **SkColorFilter) -> bool #cpp_method #foreign libskia "?asAColorFilter@SkImageFilter@@QEBA_NPEAPEAVSkColorFilter@@@Z";

    /**
    *  Returns the number of inputs this filter will accept (some inputs can be NULL).
    */
    countInputs :: (this: *SkImageFilter) -> s32 #cpp_method #foreign libskia "?countInputs@SkImageFilter@@QEBAHXZ";

    /**
    *  Returns the input filter at a given index, or NULL if no input is connected.  The indices
    *  used are filter-specific.
    */
    getInput :: (this: *SkImageFilter, i: s32) -> *SkImageFilter #cpp_method #foreign libskia "?getInput@SkImageFilter@@QEBAPEBV1@H@Z";

    // Can this filter DAG compute the resulting bounds of an object-space rectangle?
    canComputeFastBounds :: (this: *SkImageFilter) -> bool #cpp_method #foreign libskia "?canComputeFastBounds@SkImageFilter@@QEBA_NXZ";

    /**
    *  If this filter can be represented by another filter + a localMatrix, return that filter,
    *  else return null.
    */
    makeWithLocalMatrix :: (this: *SkImageFilter, matrix: *SkMatrix) -> sk_sp(SkImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeWithLocalMatrix@SkImageFilter@@QEBA?AV?$sk_sp@VSkImageFilter@@@@AEBVSkMatrix@@@Z";
    makeWithLocalMatrix :: (this: *SkImageFilter, matrix: SkMatrix) -> sk_sp(SkImageFilter) #no_context {
        return makeWithLocalMatrix(this, *matrix);
    }

    Deserialize :: (data: *void, size: u64, procs: *SkDeserialProcs = null) -> sk_sp(SkImageFilter) #cpp_return_type_is_non_pod #foreign libskia "?Deserialize@SkImageFilter@@SA?AV?$sk_sp@VSkImageFilter@@@@PEBX_KPEBUSkDeserialProcs@@@Z";

    refMe :: (this: *SkImageFilter) -> sk_sp(SkImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refMe@SkImageFilter@@IEBA?AV?$sk_sp@VSkImageFilter@@@@XZ";

    INHERITED :: SkFlattenable;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    // Default impl returns union of all input bounds.
    virtual_computeFastBounds :: (this: *SkImageFilter, bounds: *SkRect) -> SkRect #cpp_method #foreign libskia "?computeFastBounds@SkImageFilter@@UEBA?AUSkRect@@AEBU2@@Z";
}
SkImageFilter_VTable :: struct #type_info_none {
    using,except(vtable) vtable:            SkFlattenable_VTable;

    computeFastBounds: #type (this: *SkImageFilter, bounds: *SkRect) -> SkRect #cpp_method;
}
SkImageFilter_computeFastBounds :: inline (this: *SkImageFilter, bounds: *SkRect) -> SkRect { return this.vtable.computeFastBounds(this, bounds); }

get_vtable :: (obj: *SkImageFilter) -> *SkImageFilter_VTable { return obj.vtable; }


/** \enum SkColorType
Describes how pixel bits encode color. A pixel may be an alpha mask, a grayscale, RGB, or ARGB.

kN32_SkColorType selects the native 32-bit ARGB format for the current configuration. This can
lead to inconsistent results across platforms, so use with caution.

By default, Skia operates with the assumption of a little-Endian system. The names of each
SkColorType implicitly define the channel ordering and size in memory. Due to historical reasons
the names do not follow 100% identical convention, but are typically labeled from least
significant to most significant. To help clarify when the actual data layout differs from the
default convention, every SkColorType's comment includes a bit-labeled description of a pixel
in that color type on a LE system.

Unless specified otherwise, a channel's value is treated as an unsigned integer with a range of
of [0, 2^N-1] and this is mapped uniformly to a floating point value of [0.0, 1.0]. Some color
types instead store data directly in 32-bit floating point (assumed to be IEEE), or in 16-bit
"half" floating point values. A half float, or F16/float16, is interpreted as FP 1-5-10 or
Bits: [sign:15 exp:14..10 man:9..0]
*/
SkColorType :: enum s32 {
    Unknown_SkColorType            :: 0;

    Alpha_8_SkColorType            :: 1;

    RGB_565_SkColorType            :: 2;

    ARGB_4444_SkColorType          :: 3;

    RGBA_8888_SkColorType          :: 4;

    RGB_888x_SkColorType           :: 5;

    BGRA_8888_SkColorType          :: 6;

    RGBA_1010102_SkColorType       :: 7;

    BGRA_1010102_SkColorType       :: 8;

    RGB_101010x_SkColorType        :: 9;

    BGR_101010x_SkColorType        :: 10;

    BGR_101010x_XR_SkColorType     :: 11;

    BGRA_10101010_XR_SkColorType   :: 12;

    RGBA_10x6_SkColorType          :: 13;

    Gray_8_SkColorType             :: 14;

    RGBA_F16Norm_SkColorType       :: 15;

    RGBA_F16_SkColorType           :: 16;

    RGB_F16F16F16x_SkColorType     :: 17;

    RGBA_F32_SkColorType           :: 18;

    R8G8_unorm_SkColorType         :: 19;

    A16_float_SkColorType          :: 20;

    R16G16_float_SkColorType       :: 21;

    A16_unorm_SkColorType          :: 22;

    R16_unorm_SkColorType          :: 23;

    R16G16_unorm_SkColorType       :: 24;

    R16G16B16A16_unorm_SkColorType :: 25;

    SRGBA_8888_SkColorType         :: 26;

    R8_unorm_SkColorType           :: 27;

    LastEnum_SkColorType           :: 27;

    N32_SkColorType                :: 6;

    kUnknown_SkColorType            :: Unknown_SkColorType;

    kAlpha_8_SkColorType            :: Alpha_8_SkColorType;

    kRGB_565_SkColorType            :: RGB_565_SkColorType;

    kARGB_4444_SkColorType          :: ARGB_4444_SkColorType;

    kRGBA_8888_SkColorType          :: RGBA_8888_SkColorType;

    kRGB_888x_SkColorType           :: RGB_888x_SkColorType;

    kBGRA_8888_SkColorType          :: BGRA_8888_SkColorType;

    kRGBA_1010102_SkColorType       :: RGBA_1010102_SkColorType;

    kBGRA_1010102_SkColorType       :: BGRA_1010102_SkColorType;

    kRGB_101010x_SkColorType        :: RGB_101010x_SkColorType;

    kBGR_101010x_SkColorType        :: BGR_101010x_SkColorType;

    kBGR_101010x_XR_SkColorType     :: BGR_101010x_XR_SkColorType;

    kBGRA_10101010_XR_SkColorType   :: BGRA_10101010_XR_SkColorType;

    kRGBA_10x6_SkColorType          :: RGBA_10x6_SkColorType;

    kGray_8_SkColorType             :: Gray_8_SkColorType;

    kRGBA_F16Norm_SkColorType       :: RGBA_F16Norm_SkColorType;

    kRGBA_F16_SkColorType           :: RGBA_F16_SkColorType;

    kRGB_F16F16F16x_SkColorType     :: RGB_F16F16F16x_SkColorType;

    kRGBA_F32_SkColorType           :: RGBA_F32_SkColorType;

    kR8G8_unorm_SkColorType         :: R8G8_unorm_SkColorType;

    kA16_float_SkColorType          :: A16_float_SkColorType;

    kR16G16_float_SkColorType       :: R16G16_float_SkColorType;

    kA16_unorm_SkColorType          :: A16_unorm_SkColorType;

    kR16_unorm_SkColorType          :: R16_unorm_SkColorType;

    kR16G16_unorm_SkColorType       :: R16G16_unorm_SkColorType;

    kR16G16B16A16_unorm_SkColorType :: R16G16B16A16_unorm_SkColorType;

    kSRGBA_8888_SkColorType         :: SRGBA_8888_SkColorType;

    kR8_unorm_SkColorType           :: R8_unorm_SkColorType;

    kLastEnum_SkColorType           :: LastEnum_SkColorType;

    kN32_SkColorType                :: N32_SkColorType;
}

kSkColorTypeCnt: s32 : cast(s32) (SkColorType.LastEnum_SkColorType + 1);

/** Returns the number of bytes required to store a pixel, including unused padding.
Returns zero if ct is kUnknown_SkColorType or invalid.

@return    bytes per pixel
*/
SkColorTypeBytesPerPixel :: (ct: SkColorType) -> s32 #foreign libskia "?SkColorTypeBytesPerPixel@@YAHW4SkColorType@@@Z";

/** Returns true if SkColorType always decodes alpha to 1.0, making the pixel
fully opaque. If true, SkColorType does not reserve bits to encode alpha.

@return    true if alpha is always set to 1.0
*/
SkColorTypeIsAlwaysOpaque :: (ct: SkColorType) -> bool #foreign libskia "?SkColorTypeIsAlwaysOpaque@@YA_NW4SkColorType@@@Z";

/** Returns true if canonical can be set to a valid SkAlphaType for colorType. If
there is more than one valid canonical SkAlphaType, set to alphaType, if valid.
If true is returned and canonical is not nullptr, store valid SkAlphaType.

Returns false only if alphaType is kUnknown_SkAlphaType, color type is not
kUnknown_SkColorType, and SkColorType is not always opaque. If false is returned,
canonical is ignored.

@param canonical  storage for SkAlphaType
@return           true if valid SkAlphaType can be associated with colorType
*/
SkColorTypeValidateAlphaType :: (colorType: SkColorType, alphaType: SkAlphaType, canonical: *SkAlphaType = null) -> bool #foreign libskia "?SkColorTypeValidateAlphaType@@YA_NW4SkColorType@@W4SkAlphaType@@PEAW42@@Z";

/** \enum SkImageInfo::SkYUVColorSpace
Describes color range of YUV pixels. The color mapping from YUV to RGB varies
depending on the source. YUV pixels may be generated by JPEG images, standard
video streams, or high definition video streams. Each has its own mapping from
YUV to RGB.

JPEG YUV values encode the full range of 0 to 255 for all three components.
Video YUV values often range from 16 to 235 for Y and from 16 to 240 for U and V (limited).
Details of encoding and conversion to RGB are described in YCbCr color space.

The identity colorspace exists to provide a utility mapping from Y to R, U to G and V to B.
It can be used to visualize the YUV planes or to explicitly post process the YUV channels.
*/
SkYUVColorSpace :: enum s32 {
    JPEG_Full_SkYUVColorSpace            :: 0;
    Rec601_Limited_SkYUVColorSpace       :: 1;
    Rec709_Full_SkYUVColorSpace          :: 2;
    Rec709_Limited_SkYUVColorSpace       :: 3;
    BT2020_8bit_Full_SkYUVColorSpace     :: 4;
    BT2020_8bit_Limited_SkYUVColorSpace  :: 5;
    BT2020_10bit_Full_SkYUVColorSpace    :: 6;
    BT2020_10bit_Limited_SkYUVColorSpace :: 7;
    BT2020_12bit_Full_SkYUVColorSpace    :: 8;
    BT2020_12bit_Limited_SkYUVColorSpace :: 9;
    BT2020_16bit_Full_SkYUVColorSpace    :: 10;
    BT2020_16bit_Limited_SkYUVColorSpace :: 11;
    FCC_Full_SkYUVColorSpace             :: 12;
    FCC_Limited_SkYUVColorSpace          :: 13;
    SMPTE240_Full_SkYUVColorSpace        :: 14;
    SMPTE240_Limited_SkYUVColorSpace     :: 15;
    YDZDX_Full_SkYUVColorSpace           :: 16;
    YDZDX_Limited_SkYUVColorSpace        :: 17;
    GBR_Full_SkYUVColorSpace             :: 18;
    GBR_Limited_SkYUVColorSpace          :: 19;
    YCgCo_8bit_Full_SkYUVColorSpace      :: 20;
    YCgCo_8bit_Limited_SkYUVColorSpace   :: 21;
    YCgCo_10bit_Full_SkYUVColorSpace     :: 22;
    YCgCo_10bit_Limited_SkYUVColorSpace  :: 23;
    YCgCo_12bit_Full_SkYUVColorSpace     :: 24;
    YCgCo_12bit_Limited_SkYUVColorSpace  :: 25;
    YCgCo_16bit_Full_SkYUVColorSpace     :: 26;
    YCgCo_16bit_Limited_SkYUVColorSpace  :: 27;
    Identity_SkYUVColorSpace             :: 28;

    LastEnum_SkYUVColorSpace             :: 28;

    JPEG_SkYUVColorSpace                 :: 0;
    Rec601_SkYUVColorSpace               :: 1;
    Rec709_SkYUVColorSpace               :: 3;
    BT2020_SkYUVColorSpace               :: 5;

    kJPEG_Full_SkYUVColorSpace            :: JPEG_Full_SkYUVColorSpace;
    kRec601_Limited_SkYUVColorSpace       :: Rec601_Limited_SkYUVColorSpace;
    kRec709_Full_SkYUVColorSpace          :: Rec709_Full_SkYUVColorSpace;
    kRec709_Limited_SkYUVColorSpace       :: Rec709_Limited_SkYUVColorSpace;
    kBT2020_8bit_Full_SkYUVColorSpace     :: BT2020_8bit_Full_SkYUVColorSpace;
    kBT2020_8bit_Limited_SkYUVColorSpace  :: BT2020_8bit_Limited_SkYUVColorSpace;
    kBT2020_10bit_Full_SkYUVColorSpace    :: BT2020_10bit_Full_SkYUVColorSpace;
    kBT2020_10bit_Limited_SkYUVColorSpace :: BT2020_10bit_Limited_SkYUVColorSpace;
    kBT2020_12bit_Full_SkYUVColorSpace    :: BT2020_12bit_Full_SkYUVColorSpace;
    kBT2020_12bit_Limited_SkYUVColorSpace :: BT2020_12bit_Limited_SkYUVColorSpace;
    kBT2020_16bit_Full_SkYUVColorSpace    :: BT2020_16bit_Full_SkYUVColorSpace;
    kBT2020_16bit_Limited_SkYUVColorSpace :: BT2020_16bit_Limited_SkYUVColorSpace;
    kFCC_Full_SkYUVColorSpace             :: FCC_Full_SkYUVColorSpace;
    kFCC_Limited_SkYUVColorSpace          :: FCC_Limited_SkYUVColorSpace;
    kSMPTE240_Full_SkYUVColorSpace        :: SMPTE240_Full_SkYUVColorSpace;
    kSMPTE240_Limited_SkYUVColorSpace     :: SMPTE240_Limited_SkYUVColorSpace;
    kYDZDX_Full_SkYUVColorSpace           :: YDZDX_Full_SkYUVColorSpace;
    kYDZDX_Limited_SkYUVColorSpace        :: YDZDX_Limited_SkYUVColorSpace;
    kGBR_Full_SkYUVColorSpace             :: GBR_Full_SkYUVColorSpace;
    kGBR_Limited_SkYUVColorSpace          :: GBR_Limited_SkYUVColorSpace;
    kYCgCo_8bit_Full_SkYUVColorSpace      :: YCgCo_8bit_Full_SkYUVColorSpace;
    kYCgCo_8bit_Limited_SkYUVColorSpace   :: YCgCo_8bit_Limited_SkYUVColorSpace;
    kYCgCo_10bit_Full_SkYUVColorSpace     :: YCgCo_10bit_Full_SkYUVColorSpace;
    kYCgCo_10bit_Limited_SkYUVColorSpace  :: YCgCo_10bit_Limited_SkYUVColorSpace;
    kYCgCo_12bit_Full_SkYUVColorSpace     :: YCgCo_12bit_Full_SkYUVColorSpace;
    kYCgCo_12bit_Limited_SkYUVColorSpace  :: YCgCo_12bit_Limited_SkYUVColorSpace;
    kYCgCo_16bit_Full_SkYUVColorSpace     :: YCgCo_16bit_Full_SkYUVColorSpace;
    kYCgCo_16bit_Limited_SkYUVColorSpace  :: YCgCo_16bit_Limited_SkYUVColorSpace;
    kIdentity_SkYUVColorSpace             :: Identity_SkYUVColorSpace;

    kLastEnum_SkYUVColorSpace             :: LastEnum_SkYUVColorSpace;

    kJPEG_SkYUVColorSpace                 :: JPEG_SkYUVColorSpace;
    kRec601_SkYUVColorSpace               :: Rec601_SkYUVColorSpace;
    kRec709_SkYUVColorSpace               :: Rec709_SkYUVColorSpace;
    kBT2020_SkYUVColorSpace               :: BT2020_SkYUVColorSpace;
}

SkYUVColorSpaceIsLimitedRange :: (cs: SkYUVColorSpace) -> bool #foreign libskia "?SkYUVColorSpaceIsLimitedRange@@YA_NW4SkYUVColorSpace@@@Z";

/** \struct SkColorInfo
Describes pixel and encoding. SkImageInfo can be created from SkColorInfo by
providing dimensions.

It encodes how pixel bits describe alpha, transparency; color components red, blue,
and green; and SkColorSpace, the range and linearity of colors.
*/
SkColorInfo :: struct {
    /** Creates an SkColorInfo with kUnknown_SkColorType, kUnknown_SkAlphaType,
    and no SkColorSpace.
    
    @return  empty SkImageInfo
    */
    Constructor :: (this: *SkColorInfo) -> void #cpp_method #foreign libskia "??0SkColorInfo@@QEAA@XZ";
    Destructor :: (this: *SkColorInfo) -> void #cpp_method #foreign libskia "??1SkColorInfo@@QEAA@XZ";

    /** Creates SkColorInfo from SkColorType ct, SkAlphaType at, and optionally SkColorSpace cs.
    
    If SkColorSpace cs is nullptr and SkColorInfo is part of drawing source: SkColorSpace
    defaults to sRGB, mapping into SkSurface SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    @return        created SkColorInfo
    */
    Constructor :: (this: *SkColorInfo, ct: SkColorType, at: SkAlphaType, cs: sk_sp(SkColorSpace)) -> void #cpp_method #foreign libskia "??0SkColorInfo@@QEAA@W4SkColorType@@W4SkAlphaType@@V?$sk_sp@VSkColorSpace@@@@@Z";

    CopyConstructor :: (this: *SkColorInfo, unknown0: *SkColorInfo) -> void #cpp_method #foreign libskia "??0SkColorInfo@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkColorInfo, unknown0: SkColorInfo) #no_context {
        CopyConstructor(this, *unknown0);
    }

    colorSpace :: (this: *SkColorInfo) -> *SkColorSpace #cpp_method #foreign libskia "?colorSpace@SkColorInfo@@QEBAPEAVSkColorSpace@@XZ";
    refColorSpace :: (this: *SkColorInfo) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refColorSpace@SkColorInfo@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";
    colorType :: (this: *SkColorInfo) -> SkColorType #cpp_method #foreign libskia "?colorType@SkColorInfo@@QEBA?AW4SkColorType@@XZ";
    alphaType :: (this: *SkColorInfo) -> SkAlphaType #cpp_method #foreign libskia "?alphaType@SkColorInfo@@QEBA?AW4SkAlphaType@@XZ";

    isOpaque :: (this: *SkColorInfo) -> bool #cpp_method #foreign libskia "?isOpaque@SkColorInfo@@QEBA_NXZ";

    gammaCloseToSRGB :: (this: *SkColorInfo) -> bool #cpp_method #foreign libskia "?gammaCloseToSRGB@SkColorInfo@@QEBA_NXZ";

    /** Creates SkColorInfo with same SkColorType, SkColorSpace, with SkAlphaType set
    to newAlphaType.
    
    Created SkColorInfo contains newAlphaType even if it is incompatible with
    SkColorType, in which case SkAlphaType in SkColorInfo is ignored.
    */
    makeAlphaType :: (this: *SkColorInfo, newAlphaType: SkAlphaType) -> SkColorInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeAlphaType@SkColorInfo@@QEBA?AV1@W4SkAlphaType@@@Z";

    /** Creates new SkColorInfo with same SkAlphaType, SkColorSpace, with SkColorType
    set to newColorType.
    */
    makeColorType :: (this: *SkColorInfo, newColorType: SkColorType) -> SkColorInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorType@SkColorInfo@@QEBA?AV1@W4SkColorType@@@Z";

    /** Creates SkColorInfo with same SkAlphaType, SkColorType, with SkColorSpace
    set to cs. cs may be nullptr.
    */
    makeColorSpace :: (this: *SkColorInfo, cs: sk_sp(SkColorSpace)) -> SkColorInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorSpace@SkColorInfo@@QEBA?AV1@V?$sk_sp@VSkColorSpace@@@@@Z";

    /** Returns number of bytes per pixel required by SkColorType.
    Returns zero if colorType() is kUnknown_SkColorType.
    
    @return  bytes in pixel
    
    example: https://fiddle.skia.org/c/@ImageInfo_bytesPerPixel
    */
    bytesPerPixel :: (this: *SkColorInfo) -> s32 #cpp_method #foreign libskia "?bytesPerPixel@SkColorInfo@@QEBAHXZ";

    /** Returns bit shift converting row bytes to row pixels.
    Returns zero for kUnknown_SkColorType.
    
    @return  one of: 0, 1, 2, 3, 4; left shift to convert pixels to bytes
    
    example: https://fiddle.skia.org/c/@ImageInfo_shiftPerPixel
    */
    shiftPerPixel :: (this: *SkColorInfo) -> s32 #cpp_method #foreign libskia "?shiftPerPixel@SkColorInfo@@QEBAHXZ";

    fColorSpace: sk_sp(SkColorSpace);
    fColorType:  SkColorType = .Unknown_SkColorType;
    fAlphaType:  SkAlphaType = .Unknown_SkAlphaType;
}

operator_assign :: (this: *SkColorInfo, unknown0: *SkColorInfo) -> *SkColorInfo #cpp_method #foreign libskia "??4SkColorInfo@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkColorInfo, unknown0: SkColorInfo) -> *SkColorInfo #no_context {
    return operator_assign(this, *unknown0);
}

/** Does other represent the same color type, alpha type, and color space? */
operator_eq :: (this: *SkColorInfo, other: *SkColorInfo) -> bool #cpp_method #foreign libskia "??8SkColorInfo@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkColorInfo, other: SkColorInfo) -> bool #no_context {
    return operator_eq(*this, *other);
}

/** Does other represent a different color type, alpha type, or color space? */
operator_neq :: (this: *SkColorInfo, other: *SkColorInfo) -> bool #cpp_method #foreign libskia "??9SkColorInfo@@QEBA_NAEBV0@@Z";
operator_neq :: (this: SkColorInfo, other: SkColorInfo) -> bool #no_context {
    return operator_neq(*this, *other);
}

/** \struct SkImageInfo
Describes pixel dimensions and encoding. SkBitmap, SkImage, PixMap, and SkSurface
can be created from SkImageInfo. SkImageInfo can be retrieved from SkBitmap and
SkPixmap, but not from SkImage and SkSurface. For example, SkImage and SkSurface
implementations may defer pixel depth, so may not completely specify SkImageInfo.

SkImageInfo contains dimensions, the pixel integral width and height. It encodes
how pixel bits describe alpha, transparency; color components red, blue,
and green; and SkColorSpace, the range and linearity of colors.
*/
SkImageInfo :: struct {
    /** Creates an empty SkImageInfo with kUnknown_SkColorType, kUnknown_SkAlphaType,
    a width and height of zero, and no SkColorSpace.
    
    @return  empty SkImageInfo
    */
    Constructor :: (this: *SkImageInfo) -> void #cpp_method #foreign libskia "??0SkImageInfo@@QEAA@XZ";

    /** Creates SkImageInfo from integral dimensions width and height, SkColorType ct,
    SkAlphaType at, and optionally SkColorSpace cs.
    
    If SkColorSpace cs is nullptr and SkImageInfo is part of drawing source: SkColorSpace
    defaults to sRGB, mapping into SkSurface SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @param cs      range of colors; may be nullptr
    @return        created SkImageInfo
    */
    Make :: (width: s32, height: s32, ct: SkColorType, at: SkAlphaType) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?Make@SkImageInfo@@SA?AU1@HHW4SkColorType@@W4SkAlphaType@@@Z";
    Make :: (width: s32, height: s32, ct: SkColorType, at: SkAlphaType, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?Make@SkImageInfo@@SA?AU1@HHW4SkColorType@@W4SkAlphaType@@V?$sk_sp@VSkColorSpace@@@@@Z";

    Make :: (dimensions: SkISize, ct: SkColorType, at: SkAlphaType) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?Make@SkImageInfo@@SA?AU1@USkISize@@W4SkColorType@@W4SkAlphaType@@@Z";
    Make :: (dimensions: SkISize, ct: SkColorType, at: SkAlphaType, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?Make@SkImageInfo@@SA?AU1@USkISize@@W4SkColorType@@W4SkAlphaType@@V?$sk_sp@VSkColorSpace@@@@@Z";

    /** Creates SkImageInfo from integral dimensions and SkColorInfo colorInfo,
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param dimensions   pixel column and row count; must be zeros or greater
    @param SkColorInfo  the pixel encoding consisting of SkColorType, SkAlphaType, and
    SkColorSpace (which may be nullptr)
    @return        created SkImageInfo
    */
    Make :: (dimensions: SkISize, colorInfo: *SkColorInfo) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?Make@SkImageInfo@@SA?AU1@USkISize@@AEBVSkColorInfo@@@Z";
    Make :: (dimensions: SkISize, colorInfo: SkColorInfo) -> SkImageInfo #no_context {
        return Make(dimensions, *colorInfo);
    }

    /** Creates SkImageInfo from integral dimensions width and height, kN32_SkColorType,
    SkAlphaType at, and optionally SkColorSpace cs. kN32_SkColorType will equal either
    kBGRA_8888_SkColorType or kRGBA_8888_SkColorType, whichever is optimal.
    
    If SkColorSpace cs is nullptr and SkImageInfo is part of drawing source: SkColorSpace
    defaults to sRGB, mapping into SkSurface SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @param cs      range of colors; may be nullptr
    @return        created SkImageInfo
    */
    MakeN32 :: (width: s32, height: s32, at: SkAlphaType) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32@SkImageInfo@@SA?AU1@HHW4SkAlphaType@@@Z";
    MakeN32 :: (width: s32, height: s32, at: SkAlphaType, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32@SkImageInfo@@SA?AU1@HHW4SkAlphaType@@V?$sk_sp@VSkColorSpace@@@@@Z";

    /** Creates SkImageInfo from integral dimensions width and height, kN32_SkColorType,
    SkAlphaType at, with sRGB SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @return        created SkImageInfo
    
    example: https://fiddle.skia.org/c/@ImageInfo_MakeS32
    */
    MakeS32 :: (width: s32, height: s32, at: SkAlphaType) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeS32@SkImageInfo@@SA?AU1@HHW4SkAlphaType@@@Z";

    /** Creates SkImageInfo from integral dimensions width and height, kN32_SkColorType,
    kPremul_SkAlphaType, with optional SkColorSpace.
    
    If SkColorSpace cs is nullptr and SkImageInfo is part of drawing source: SkColorSpace
    defaults to sRGB, mapping into SkSurface SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @param cs      range of colors; may be nullptr
    @return        created SkImageInfo
    */
    MakeN32Premul :: (width: s32, height: s32) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32Premul@SkImageInfo@@SA?AU1@HH@Z";
    MakeN32Premul :: (width: s32, height: s32, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32Premul@SkImageInfo@@SA?AU1@HHV?$sk_sp@VSkColorSpace@@@@@Z";

    /** Creates SkImageInfo from integral dimensions width and height, kN32_SkColorType,
    kPremul_SkAlphaType, with SkColorSpace set to nullptr.
    
    If SkImageInfo is part of drawing source: SkColorSpace defaults to sRGB, mapping
    into SkSurface SkColorSpace.
    
    Parameters are not validated to see if their values are legal, or that the
    combination is supported.
    
    @param dimensions  width and height, each must be zero or greater
    @param cs          range of colors; may be nullptr
    @return            created SkImageInfo
    */
    MakeN32Premul :: (dimensions: SkISize) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32Premul@SkImageInfo@@SA?AU1@USkISize@@@Z";
    MakeN32Premul :: (dimensions: SkISize, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeN32Premul@SkImageInfo@@SA?AU1@USkISize@@V?$sk_sp@VSkColorSpace@@@@@Z";

    /** Creates SkImageInfo from integral dimensions width and height, kAlpha_8_SkColorType,
    kPremul_SkAlphaType, with SkColorSpace set to nullptr.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @return        created SkImageInfo
    */
    MakeA8 :: (width: s32, height: s32) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeA8@SkImageInfo@@SA?AU1@HH@Z";

    /** Creates SkImageInfo from integral dimensions, kAlpha_8_SkColorType,
    kPremul_SkAlphaType, with SkColorSpace set to nullptr.
    
    @param dimensions   pixel row and column count; must be zero or greater
    @return             created SkImageInfo
    */
    MakeA8 :: (dimensions: SkISize) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeA8@SkImageInfo@@SA?AU1@USkISize@@@Z";

    /** Creates SkImageInfo from integral dimensions width and height, kUnknown_SkColorType,
    kUnknown_SkAlphaType, with SkColorSpace set to nullptr.
    
    Returned SkImageInfo as part of source does not draw, and as part of destination
    can not be drawn to.
    
    @param width   pixel column count; must be zero or greater
    @param height  pixel row count; must be zero or greater
    @return        created SkImageInfo
    */
    MakeUnknown :: (width: s32, height: s32) -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeUnknown@SkImageInfo@@SA?AU1@HH@Z";

    /** Creates SkImageInfo from integral dimensions width and height set to zero,
    kUnknown_SkColorType, kUnknown_SkAlphaType, with SkColorSpace set to nullptr.
    
    Returned SkImageInfo as part of source does not draw, and as part of destination
    can not be drawn to.
    
    @return  created SkImageInfo
    */
    MakeUnknown :: () -> SkImageInfo #cpp_return_type_is_non_pod #foreign libskia "?MakeUnknown@SkImageInfo@@SA?AU1@XZ";

    /** Returns pixel count in each row.
    
    @return  pixel width
    */
    width :: (this: *SkImageInfo) -> s32 #cpp_method #foreign libskia "?width@SkImageInfo@@QEBAHXZ";

    /** Returns pixel row count.
    
    @return  pixel height
    */
    height :: (this: *SkImageInfo) -> s32 #cpp_method #foreign libskia "?height@SkImageInfo@@QEBAHXZ";

    colorType :: (this: *SkImageInfo) -> SkColorType #cpp_method #foreign libskia "?colorType@SkImageInfo@@QEBA?AW4SkColorType@@XZ";

    alphaType :: (this: *SkImageInfo) -> SkAlphaType #cpp_method #foreign libskia "?alphaType@SkImageInfo@@QEBA?AW4SkAlphaType@@XZ";

    /** Returns SkColorSpace, the range of colors. The reference count of
    SkColorSpace is unchanged. The returned SkColorSpace is immutable.
    
    @return  SkColorSpace, or nullptr
    */
    colorSpace :: (this: *SkImageInfo) -> *SkColorSpace #cpp_method #foreign libskia "?colorSpace@SkImageInfo@@QEBAPEAVSkColorSpace@@XZ";

    /** Returns smart pointer to SkColorSpace, the range of colors. The smart pointer
    tracks the number of objects sharing this SkColorSpace reference so the memory
    is released when the owners destruct.
    
    The returned SkColorSpace is immutable.
    
    @return  SkColorSpace wrapped in a smart pointer
    */
    refColorSpace :: (this: *SkImageInfo) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refColorSpace@SkImageInfo@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /** Returns if SkImageInfo describes an empty area of pixels by checking if either
    width or height is zero or smaller.
    
    @return  true if either dimension is zero or smaller
    */
    isEmpty :: (this: *SkImageInfo) -> bool #cpp_method #foreign libskia "?isEmpty@SkImageInfo@@QEBA_NXZ";

    /** Returns the dimensionless SkColorInfo that represents the same color type,
    alpha type, and color space as this SkImageInfo.
    */
    colorInfo :: (this: *SkImageInfo) -> *SkColorInfo #cpp_method #foreign libskia "?colorInfo@SkImageInfo@@QEBAAEBVSkColorInfo@@XZ";

    /** Returns true if SkAlphaType is set to hint that all pixels are opaque; their
    alpha value is implicitly or explicitly 1.0. If true, and all pixels are
    not opaque, Skia may draw incorrectly.
    
    Does not check if SkColorType allows alpha, or if any pixel value has
    transparency.
    
    @return  true if SkAlphaType is kOpaque_SkAlphaType
    */
    isOpaque :: (this: *SkImageInfo) -> bool #cpp_method #foreign libskia "?isOpaque@SkImageInfo@@QEBA_NXZ";

    /** Returns SkISize { width(), height() }.
    
    @return  integral size of width() and height()
    */
    dimensions :: (this: *SkImageInfo) -> SkISize #cpp_method #foreign libskia "?dimensions@SkImageInfo@@QEBA?AUSkISize@@XZ";

    /** Returns SkIRect { 0, 0, width(), height() }.
    
    @return  integral rectangle from origin to width() and height()
    */
    bounds :: (this: *SkImageInfo) -> SkIRect #cpp_method #foreign libskia "?bounds@SkImageInfo@@QEBA?AUSkIRect@@XZ";

    /** Returns true if associated SkColorSpace is not nullptr, and SkColorSpace gamma
    is approximately the same as sRGB.
    This includes the
    
    @return  true if SkColorSpace gamma is approximately the same as sRGB
    */
    gammaCloseToSRGB :: (this: *SkImageInfo) -> bool #cpp_method #foreign libskia "?gammaCloseToSRGB@SkImageInfo@@QEBA_NXZ";

    /** Creates SkImageInfo with the same SkColorType, SkColorSpace, and SkAlphaType,
    with dimensions set to width and height.
    
    @param newWidth   pixel column count; must be zero or greater
    @param newHeight  pixel row count; must be zero or greater
    @return           created SkImageInfo
    */
    makeWH :: (this: *SkImageInfo, newWidth: s32, newHeight: s32) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeWH@SkImageInfo@@QEBA?AU1@HH@Z";

    /** Creates SkImageInfo with the same SkColorType, SkColorSpace, and SkAlphaType,
    with dimensions set to newDimensions.
    
    @param newSize   pixel column and row count; must be zero or greater
    @return          created SkImageInfo
    */
    makeDimensions :: (this: *SkImageInfo, newSize: SkISize) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeDimensions@SkImageInfo@@QEBA?AU1@USkISize@@@Z";

    /** Creates SkImageInfo with same SkColorType, SkColorSpace, width, and height,
    with SkAlphaType set to newAlphaType.
    
    Created SkImageInfo contains newAlphaType even if it is incompatible with
    SkColorType, in which case SkAlphaType in SkImageInfo is ignored.
    
    @return              created SkImageInfo
    */
    makeAlphaType :: (this: *SkImageInfo, newAlphaType: SkAlphaType) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeAlphaType@SkImageInfo@@QEBA?AU1@W4SkAlphaType@@@Z";

    /** Creates SkImageInfo with same SkAlphaType, SkColorSpace, width, and height,
    with SkColorType set to newColorType.
    
    @return              created SkImageInfo
    */
    makeColorType :: (this: *SkImageInfo, newColorType: SkColorType) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorType@SkImageInfo@@QEBA?AU1@W4SkColorType@@@Z";

    /** Creates SkImageInfo with same SkAlphaType, SkColorType, width, and height,
    with SkColorSpace set to cs.
    
    @param cs  range of colors; may be nullptr
    @return    created SkImageInfo
    */
    makeColorSpace :: (this: *SkImageInfo, cs: sk_sp(SkColorSpace)) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorSpace@SkImageInfo@@QEBA?AU1@V?$sk_sp@VSkColorSpace@@@@@Z";

    /** Returns number of bytes per pixel required by SkColorType.
    Returns zero if colorType( is kUnknown_SkColorType.
    
    @return  bytes in pixel
    */
    bytesPerPixel :: (this: *SkImageInfo) -> s32 #cpp_method #foreign libskia "?bytesPerPixel@SkImageInfo@@QEBAHXZ";

    /** Returns bit shift converting row bytes to row pixels.
    Returns zero for kUnknown_SkColorType.
    
    @return  one of: 0, 1, 2, 3; left shift to convert pixels to bytes
    */
    shiftPerPixel :: (this: *SkImageInfo) -> s32 #cpp_method #foreign libskia "?shiftPerPixel@SkImageInfo@@QEBAHXZ";

    /** Returns minimum bytes per row, computed from pixel width() and SkColorType, which
    specifies bytesPerPixel(). SkBitmap maximum value for row bytes must fit
    in 31 bits.
    
    @return  width() times bytesPerPixel() as unsigned 64-bit integer
    */
    minRowBytes64 :: (this: *SkImageInfo) -> u64 #cpp_method #foreign libskia "?minRowBytes64@SkImageInfo@@QEBA_KXZ";

    /** Returns minimum bytes per row, computed from pixel width() and SkColorType, which
    specifies bytesPerPixel(). SkBitmap maximum value for row bytes must fit
    in 31 bits.
    
    @return  width() times bytesPerPixel() as size_t
    */
    minRowBytes :: (this: *SkImageInfo) -> u64 #cpp_method #foreign libskia "?minRowBytes@SkImageInfo@@QEBA_KXZ";

    /** Returns byte offset of pixel from pixel base address.
    
    Asserts in debug build if x or y is outside of bounds. Does not assert if
    rowBytes is smaller than minRowBytes(), even though result may be incorrect.
    
    @param x         column index, zero or greater, and less than width()
    @param y         row index, zero or greater, and less than height()
    @param rowBytes  size of pixel row or larger
    @return          offset within pixel array
    
    example: https://fiddle.skia.org/c/@ImageInfo_computeOffset
    */
    computeOffset :: (this: *SkImageInfo, x: s32, y: s32, rowBytes: u64) -> u64 #cpp_method #foreign libskia "?computeOffset@SkImageInfo@@QEBA_KHH_K@Z";

    /** Returns storage required by pixel array, given SkImageInfo dimensions, SkColorType,
    and rowBytes. rowBytes is assumed to be at least as large as minRowBytes().
    
    Returns zero if height is zero.
    Returns SIZE_MAX if answer exceeds the range of size_t.
    
    @param rowBytes  size of pixel row or larger
    @return          memory required by pixel buffer
    */
    computeByteSize :: (this: *SkImageInfo, rowBytes: u64) -> u64 #cpp_method #foreign libskia "?computeByteSize@SkImageInfo@@QEBA_K_K@Z";

    /** Returns storage required by pixel array, given SkImageInfo dimensions, and
    SkColorType. Uses minRowBytes() to compute bytes for pixel row.
    
    Returns zero if height is zero.
    Returns SIZE_MAX if answer exceeds the range of size_t.
    
    @return  least memory required by pixel buffer
    */
    computeMinByteSize :: (this: *SkImageInfo) -> u64 #cpp_method #foreign libskia "?computeMinByteSize@SkImageInfo@@QEBA_KXZ";

    /** Returns true if byteSize equals SIZE_MAX. computeByteSize() and
    computeMinByteSize() return SIZE_MAX if size_t can not hold buffer size.
    
    @param byteSize  result of computeByteSize() or computeMinByteSize()
    @return          true if computeByteSize() or computeMinByteSize() result exceeds size_t
    */
    ByteSizeOverflowed :: (byteSize: u64) -> bool #foreign libskia "?ByteSizeOverflowed@SkImageInfo@@SA_N_K@Z";

    /** Returns true if rowBytes is valid for this SkImageInfo.
    
    @param rowBytes  size of pixel row including padding
    @return          true if rowBytes is large enough to contain pixel row and is properly
    aligned
    */
    validRowBytes :: (this: *SkImageInfo, rowBytes: u64) -> bool #cpp_method #foreign libskia "?validRowBytes@SkImageInfo@@QEBA_N_K@Z";

    /** Creates an empty SkImageInfo with kUnknown_SkColorType, kUnknown_SkAlphaType,
    a width and height of zero, and no SkColorSpace.
    */
    reset :: (this: *SkImageInfo) -> void #cpp_method #foreign libskia "?reset@SkImageInfo@@QEAAXXZ";

    /** Asserts if internal values are illegal or inconsistent. Only available if
    SK_DEBUG is defined at compile time.
    */
//     validate :: (this: *SkImageInfo) -> void #cpp_method #foreign libskia "?validate@SkImageInfo@@QEBAXXZ";

    fColorInfo:  SkColorInfo;
    fDimensions: SkISize;

    Constructor :: (this: *SkImageInfo, dimensions: SkISize, colorInfo: *SkColorInfo) -> void #cpp_method #foreign libskia "??0SkImageInfo@@AEAA@USkISize@@AEBVSkColorInfo@@@Z";
    Constructor :: (this: *SkImageInfo, dimensions: SkISize, colorInfo: SkColorInfo) #no_context {
        Constructor(this, dimensions, *colorInfo);
    }
}

/** Compares SkImageInfo with other, and returns true if width, height, SkColorType,
SkAlphaType, and SkColorSpace are equivalent.

@param other  SkImageInfo to compare
@return       true if SkImageInfo equals other
*/
operator_eq :: (this: *SkImageInfo, other: *SkImageInfo) -> bool #cpp_method #foreign libskia "??8SkImageInfo@@QEBA_NAEBU0@@Z";
operator_eq :: (this: SkImageInfo, other: SkImageInfo) -> bool #no_context {
    return operator_eq(*this, *other);
}

/** Compares SkImageInfo with other, and returns true if width, height, SkColorType,
SkAlphaType, and SkColorSpace are not equivalent.

@param other  SkImageInfo to compare
@return       true if SkImageInfo is not equal to other
*/
operator_neq :: (this: *SkImageInfo, other: *SkImageInfo) -> bool #cpp_method #foreign libskia "??9SkImageInfo@@QEBA_NAEBU0@@Z";
operator_neq :: (this: SkImageInfo, other: SkImageInfo) -> bool #no_context {
    return operator_neq(*this, *other);
}

SkPoint3 :: struct {
    fX: SkScalar;
    fY: SkScalar;
    fZ: SkScalar;

    Make :: (x: SkScalar, y: SkScalar, z: SkScalar) -> SkPoint3 #foreign libskia "?Make@SkPoint3@@SA?AU1@MMM@Z";

    x :: (this: *SkPoint3) -> SkScalar #cpp_method #foreign libskia "?x@SkPoint3@@QEBAMXZ";
    y :: (this: *SkPoint3) -> SkScalar #cpp_method #foreign libskia "?y@SkPoint3@@QEBAMXZ";
    z :: (this: *SkPoint3) -> SkScalar #cpp_method #foreign libskia "?z@SkPoint3@@QEBAMXZ";

    set :: (this: *SkPoint3, x: SkScalar, y: SkScalar, z: SkScalar) -> void #cpp_method #foreign libskia "?set@SkPoint3@@QEAAXMMM@Z";

    /** Returns the Euclidian distance from (0,0,0) to (x,y,z)
    */
    Length :: (x: SkScalar, y: SkScalar, z: SkScalar) -> SkScalar #foreign libskia "?Length@SkPoint3@@SAMMMM@Z";

    /** Return the Euclidian distance from (0,0,0) to the point
    */
    length :: (this: *SkPoint3) -> SkScalar #cpp_method #foreign libskia "?length@SkPoint3@@QEBAMXZ";

    /** Set the point (vector) to be unit-length in the same direction as it
    already points.  If the point has a degenerate length (i.e., nearly 0)
    then set it to (0,0,0) and return false; otherwise return true.
    */
    normalize :: (this: *SkPoint3) -> bool #cpp_method #foreign libskia "?normalize@SkPoint3@@QEAA_NXZ";

    /** Return a new point whose X, Y and Z coordinates are scaled.
    */
    makeScale :: (this: *SkPoint3, scale: SkScalar) -> SkPoint3 #cpp_method #foreign libskia "?makeScale@SkPoint3@@QEBA?AU1@M@Z";

    /** Scale the point's coordinates by scale.
    */
    scale :: (this: *SkPoint3, value: SkScalar) -> void #cpp_method #foreign libskia "?scale@SkPoint3@@QEAAXM@Z";

    /** Returns true if fX, fY, and fZ are measurable values.
    
    @return  true for values other than infinities and NaN
    */
    isFinite :: (this: *SkPoint3) -> bool #cpp_method #foreign libskia "?isFinite@SkPoint3@@QEBA_NXZ";

    /** Returns the dot product of a and b, treating them as 3D vectors
    */
    DotProduct :: (a: *SkPoint3, b: *SkPoint3) -> SkScalar #foreign libskia "?DotProduct@SkPoint3@@SAMAEBU1@0@Z";
    DotProduct :: (a: SkPoint3, b: SkPoint3) -> SkScalar #no_context {
        return DotProduct(*a, *b);
    }

    dot :: (this: *SkPoint3, vec: *SkPoint3) -> SkScalar #cpp_method #foreign libskia "?dot@SkPoint3@@QEBAMAEBU1@@Z";
    dot :: (this: *SkPoint3, vec: SkPoint3) -> SkScalar #no_context {
        return dot(this, *vec);
    }

    /** Returns the cross product of a and b, treating them as 3D vectors
    */
    CrossProduct :: (a: *SkPoint3, b: *SkPoint3) -> SkPoint3 #foreign libskia "?CrossProduct@SkPoint3@@SA?AU1@AEBU1@0@Z";
    CrossProduct :: (a: SkPoint3, b: SkPoint3) -> SkPoint3 #no_context {
        return CrossProduct(*a, *b);
    }

    cross :: (this: *SkPoint3, vec: *SkPoint3) -> SkPoint3 #cpp_method #foreign libskia "?cross@SkPoint3@@QEBA?AU1@AEBU1@@Z";
    cross :: (this: *SkPoint3, vec: SkPoint3) -> SkPoint3 #no_context {
        return cross(this, *vec);
    }
}

/** Return a new point whose X, Y and Z coordinates are the negative of the
original point's
*/
operator_minus :: (this: *SkPoint3) -> SkPoint3 #cpp_method #foreign libskia "??GSkPoint3@@QEBA?AU0@XZ";
operator_minus :: (this: SkPoint3) -> SkPoint3 #no_context {
    return operator_minus(*this);
}

/** Add v's coordinates to the point's
*/
operator_plus_equals :: (this: *SkPoint3, v: *SkPoint3) -> void #cpp_method #foreign libskia "??YSkPoint3@@QEAAXAEBU0@@Z";
operator_plus_equals :: (this: *SkPoint3, v: SkPoint3) #no_context {
    operator_plus_equals(this, *v);
}

/** Subtract v's coordinates from the point's
*/
operator_minus_equals :: (this: *SkPoint3, v: *SkPoint3) -> void #cpp_method #foreign libskia "??ZSkPoint3@@QEAAXAEBU0@@Z";
operator_minus_equals :: (this: *SkPoint3, v: SkPoint3) #no_context {
    operator_minus_equals(this, *v);
}

SkVector3 :: SkPoint3;
SkColor3f :: SkPoint3;

/**
* Wraps a C++11 enum that we use as a bitfield, and enables a limited amount of
* masking with type safety. Instantiated with the ~ operator.
*/
SkTFlagsMask :: struct(TFlags: Type) {
    using,except(TFlags) sktflagsmask__raw:      SkTFlagsMask__RAW(TFlags);
    #if size_of(SkTFlagsMask__RAW(TFlags)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// SkTFlagsMask without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkTFlagsMask
SkTFlagsMask__RAW :: struct(TFlags: Type) {}

/** \class SkMatrix
SkMatrix holds a 3x3 matrix for transforming coordinates. This allows mapping
SkPoint and vectors with translation, scaling, skewing, rotation, and
perspective.

SkMatrix elements are in row major order.
SkMatrix constexpr default constructs to identity.

SkMatrix includes a hidden variable that classifies the type of matrix to
improve performance. SkMatrix is not thread safe unless getType() is called first.

example: https://fiddle.skia.org/c/@Matrix_063
*/
SkMatrix :: struct {
    /** Creates an identity SkMatrix:
    
    | 1 0 0 |
    | 0 1 0 |
    | 0 0 1 |
    */
    Constructor :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "??0SkMatrix@@QEAA@XZ";

    /** Sets SkMatrix to scale by (sx, sy). Returned matrix is:
    
    | sx  0  0 |
    |  0 sy  0 |
    |  0  0  1 |
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    @return    SkMatrix with scale
    */
    Scale :: (sx: SkScalar, sy: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Scale@SkMatrix@@SA?AV1@MM@Z";

    /** Sets SkMatrix to translate by (dx, dy). Returned matrix is:
    
    | 1 0 dx |
    | 0 1 dy |
    | 0 0  1 |
    
    @param dx  horizontal translation
    @param dy  vertical translation
    @return    SkMatrix with translation
    */
    Translate :: (dx: SkScalar, dy: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Translate@SkMatrix@@SA?AV1@MM@Z";

    Translate :: (t: SkVector) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Translate@SkMatrix@@SA?AV1@USkPoint@@@Z";
    Translate :: (t: SkIVector) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Translate@SkMatrix@@SA?AV1@USkIPoint@@@Z";

    ScaleTranslate :: (sx: float, sy: float, tx: float, ty: float) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?ScaleTranslate@SkMatrix@@SA?AV1@MMMM@Z";

    /** Sets SkMatrix to rotate by |deg| about a pivot point at (0, 0).
    
    @param deg  rotation angle in degrees (positive rotates clockwise)
    @return     SkMatrix with rotation
    */
    RotateDeg :: (deg: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?RotateDeg@SkMatrix@@SA?AV1@M@Z";

    RotateDeg :: (deg: SkScalar, pt: SkPoint) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?RotateDeg@SkMatrix@@SA?AV1@MUSkPoint@@@Z";

    RotateRad :: (rad: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?RotateRad@SkMatrix@@SA?AV1@M@Z";

    /** Sets SkMatrix to skew by (kx, ky) about pivot point (0, 0).
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    @return    SkMatrix with skew
    */
    Skew :: (kx: SkScalar, ky: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Skew@SkMatrix@@SA?AV1@MM@Z";

    /** \enum SkMatrix::ScaleToFit
    ScaleToFit describes how SkMatrix is constructed to map one SkRect to another.
    ScaleToFit may allow SkMatrix to have unequal horizontal and vertical scaling,
    or may restrict SkMatrix to square scaling. If restricted, ScaleToFit specifies
    how SkMatrix maps to the side or center of the destination SkRect.
    */
    ScaleToFit :: enum s32 {
        Fill_ScaleToFit   :: 0;
        Start_ScaleToFit  :: 1;
        Center_ScaleToFit :: 2;
        End_ScaleToFit    :: 3;

        kFill_ScaleToFit   :: Fill_ScaleToFit;
        kStart_ScaleToFit  :: Start_ScaleToFit;
        kCenter_ScaleToFit :: Center_ScaleToFit;
        kEnd_ScaleToFit    :: End_ScaleToFit;
    }

    /** Sets SkMatrix to:
    
    | scaleX  skewX transX |
    |  skewY scaleY transY |
    |  pers0  pers1  pers2 |
    
    @param scaleX  horizontal scale factor
    @param skewX   horizontal skew factor
    @param transX  horizontal translation
    @param skewY   vertical skew factor
    @param scaleY  vertical scale factor
    @param transY  vertical translation
    @param pers0   input x-axis perspective factor
    @param pers1   input y-axis perspective factor
    @param pers2   perspective scale factor
    @return        SkMatrix constructed from parameters
    */
    MakeAll :: (scaleX: SkScalar, skewX: SkScalar, transX: SkScalar, skewY: SkScalar, scaleY: SkScalar, transY: SkScalar, pers0: SkScalar, pers1: SkScalar, pers2: SkScalar) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?MakeAll@SkMatrix@@SA?AV1@MMMMMMMMM@Z";

    /** \enum SkMatrix::TypeMask
    Enum of bit fields for mask returned by getType().
    Used to identify the complexity of SkMatrix, to optimize performance.
    */
    TypeMask :: enum s32 {
        Identity_Mask    :: 0;
        Translate_Mask   :: 1;
        Scale_Mask       :: 2;
        Affine_Mask      :: 4;
        Perspective_Mask :: 8;

        kIdentity_Mask    :: Identity_Mask;
        kTranslate_Mask   :: Translate_Mask;
        kScale_Mask       :: Scale_Mask;
        kAffine_Mask      :: Affine_Mask;
        kPerspective_Mask :: Perspective_Mask;
    }

    /** Returns a bit field describing the transformations the matrix may
    perform. The bit field is computed conservatively, so it may include
    false positives. For example, when kPerspective_Mask is set, all
    other bits are set.
    
    @return  kIdentity_Mask, or combinations of: kTranslate_Mask, kScale_Mask,
    kAffine_Mask, kPerspective_Mask
    */
    getType :: (this: *SkMatrix) -> TypeMask #cpp_method #foreign libskia "?getType@SkMatrix@@QEBA?AW4TypeMask@1@XZ";

    /** Returns true if SkMatrix is identity.  Identity matrix is:
    
    | 1 0 0 |
    | 0 1 0 |
    | 0 0 1 |
    
    @return  true if SkMatrix has no effect
    */
    isIdentity :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?isIdentity@SkMatrix@@QEBA_NXZ";

    /** Returns true if SkMatrix at most scales and translates. SkMatrix may be identity,
    contain only scale elements, only translate elements, or both. SkMatrix form is:
    
    | scale-x    0    translate-x |
    |    0    scale-y translate-y |
    |    0       0         1      |
    
    @return  true if SkMatrix is identity; or scales, translates, or both
    */
    isScaleTranslate :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?isScaleTranslate@SkMatrix@@QEBA_NXZ";

    /** Returns true if SkMatrix is identity, or translates. SkMatrix form is:
    
    | 1 0 translate-x |
    | 0 1 translate-y |
    | 0 0      1      |
    
    @return  true if SkMatrix is identity, or translates
    */
    isTranslate :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?isTranslate@SkMatrix@@QEBA_NXZ";

    /** Returns true SkMatrix maps SkRect to another SkRect. If true, SkMatrix is identity,
    or scales, or rotates a multiple of 90 degrees, or mirrors on axes. In all
    cases, SkMatrix may also have translation. SkMatrix form is either:
    
    | scale-x    0    translate-x |
    |    0    scale-y translate-y |
    |    0       0         1      |
    
    or
    
    |    0     rotate-x translate-x |
    | rotate-y    0     translate-y |
    |    0        0          1      |
    
    for non-zero values of scale-x, scale-y, rotate-x, and rotate-y.
    
    Also called preservesAxisAlignment(); use the one that provides better inline
    documentation.
    
    @return  true if SkMatrix maps one SkRect into another
    */
    rectStaysRect :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?rectStaysRect@SkMatrix@@QEBA_NXZ";

    /** Returns true SkMatrix maps SkRect to another SkRect. If true, SkMatrix is identity,
    or scales, or rotates a multiple of 90 degrees, or mirrors on axes. In all
    cases, SkMatrix may also have translation. SkMatrix form is either:
    
    | scale-x    0    translate-x |
    |    0    scale-y translate-y |
    |    0       0         1      |
    
    or
    
    |    0     rotate-x translate-x |
    | rotate-y    0     translate-y |
    |    0        0          1      |
    
    for non-zero values of scale-x, scale-y, rotate-x, and rotate-y.
    
    Also called rectStaysRect(); use the one that provides better inline
    documentation.
    
    @return  true if SkMatrix maps one SkRect into another
    */
    preservesAxisAlignment :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?preservesAxisAlignment@SkMatrix@@QEBA_NXZ";

    /** Returns true if the matrix contains perspective elements. SkMatrix form is:
    
    |       --            --              --          |
    |       --            --              --          |
    | perspective-x  perspective-y  perspective-scale |
    
    where perspective-x or perspective-y is non-zero, or perspective-scale is
    not one. All other elements may have any value.
    
    @return  true if SkMatrix is in most general form
    */
    hasPerspective :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?hasPerspective@SkMatrix@@QEBA_NXZ";

    /** Returns true if SkMatrix contains only translation, rotation, reflection, and
    uniform scale.
    Returns false if SkMatrix contains different scales, skewing, perspective, or
    degenerate forms that collapse to a line or point.
    
    Describes that the SkMatrix makes rendering with and without the matrix are
    visually alike; a transformed circle remains a circle. Mathematically, this is
    referred to as similarity of a Euclidean space, or a similarity transformation.
    
    Preserves right angles, keeping the arms of the angle equal lengths.
    
    @param tol  to be deprecated
    @return     true if SkMatrix only rotates, uniformly scales, translates
    
    example: https://fiddle.skia.org/c/@Matrix_isSimilarity
    */
    isSimilarity :: (this: *SkMatrix, tol: SkScalar = 0.000244) -> bool #cpp_method #foreign libskia "?isSimilarity@SkMatrix@@QEBA_NM@Z";

    /** Returns true if SkMatrix contains only translation, rotation, reflection, and
    scale. Scale may differ along rotated axes.
    Returns false if SkMatrix skewing, perspective, or degenerate forms that collapse
    to a line or point.
    
    Preserves right angles, but not requiring that the arms of the angle
    retain equal lengths.
    
    @param tol  to be deprecated
    @return     true if SkMatrix only rotates, scales, translates
    
    example: https://fiddle.skia.org/c/@Matrix_preservesRightAngles
    */
    preservesRightAngles :: (this: *SkMatrix, tol: SkScalar = 0.000244) -> bool #cpp_method #foreign libskia "?preservesRightAngles@SkMatrix@@QEBA_NM@Z";

    kMScaleX:                   s32 : 0; //!< horizontal scale factor
    kMSkewX:                    s32 : 1; //!< horizontal skew factor
    kMTransX:                   s32 : 2; //!< horizontal translation
    kMSkewY:                    s32 : 3; //!< vertical skew factor
    kMScaleY:                   s32 : 4; //!< vertical scale factor
    kMTransY:                   s32 : 5; //!< vertical translation
    kMPersp0:                   s32 : 6; //!< input x perspective factor
    kMPersp1:                   s32 : 7; //!< input y perspective factor
    kMPersp2:                   s32 : 8; //!< perspective bias

    kAScaleX:                   s32 : 0; //!< horizontal scale factor
    kASkewY:                    s32 : 1; //!< vertical skew factor
    kASkewX:                    s32 : 2; //!< horizontal skew factor
    kAScaleY:                   s32 : 3; //!< vertical scale factor
    kATransX:                   s32 : 4; //!< horizontal translation
    kATransY:                   s32 : 5; //!< vertical translation

    /** Returns one matrix value. Asserts if index is out of range and SK_DEBUG is
    defined.
    
    @param index  one of: kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY,
    kMPersp0, kMPersp1, kMPersp2
    @return       value corresponding to index
    */
    get :: (this: *SkMatrix, index: s32) -> SkScalar #cpp_method #foreign libskia "?get@SkMatrix@@QEBAMH@Z";

    /** Returns one matrix value from a particular row/column. Asserts if index is out
    of range and SK_DEBUG is defined.
    
    @param r  matrix row to fetch
    @param c  matrix column to fetch
    @return   value at the given matrix position
    */
    rc :: (this: *SkMatrix, r: s32, c: s32) -> SkScalar #cpp_method #foreign libskia "?rc@SkMatrix@@QEBAMHH@Z";

    /** Returns scale factor multiplied by x-axis input, contributing to x-axis output.
    With mapPoints(), scales SkPoint along the x-axis.
    
    @return  horizontal scale factor
    */
    getScaleX :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getScaleX@SkMatrix@@QEBAMXZ";

    /** Returns scale factor multiplied by y-axis input, contributing to y-axis output.
    With mapPoints(), scales SkPoint along the y-axis.
    
    @return  vertical scale factor
    */
    getScaleY :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getScaleY@SkMatrix@@QEBAMXZ";

    /** Returns scale factor multiplied by x-axis input, contributing to y-axis output.
    With mapPoints(), skews SkPoint along the y-axis.
    Skewing both axes can rotate SkPoint.
    
    @return  vertical skew factor
    */
    getSkewY :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getSkewY@SkMatrix@@QEBAMXZ";

    /** Returns scale factor multiplied by y-axis input, contributing to x-axis output.
    With mapPoints(), skews SkPoint along the x-axis.
    Skewing both axes can rotate SkPoint.
    
    @return  horizontal scale factor
    */
    getSkewX :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getSkewX@SkMatrix@@QEBAMXZ";

    /** Returns translation contributing to x-axis output.
    With mapPoints(), moves SkPoint along the x-axis.
    
    @return  horizontal translation factor
    */
    getTranslateX :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getTranslateX@SkMatrix@@QEBAMXZ";

    /** Returns translation contributing to y-axis output.
    With mapPoints(), moves SkPoint along the y-axis.
    
    @return  vertical translation factor
    */
    getTranslateY :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getTranslateY@SkMatrix@@QEBAMXZ";

    /** Returns factor scaling input x-axis relative to input y-axis.
    
    @return  input x-axis perspective factor
    */
    getPerspX :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getPerspX@SkMatrix@@QEBAMXZ";

    /** Returns factor scaling input y-axis relative to input x-axis.
    
    @return  input y-axis perspective factor
    */
    getPerspY :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getPerspY@SkMatrix@@QEBAMXZ";

    /** Sets SkMatrix value. Asserts if index is out of range and SK_DEBUG is
    defined. Safer than operator_subscript; internal cache is always maintained.
    
    @param index  one of: kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY,
    kMPersp0, kMPersp1, kMPersp2
    @param value  scalar to store in SkMatrix
    */
    set :: (this: *SkMatrix, index: s32, value: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?set@SkMatrix@@QEAAAEAV1@HM@Z";

    /** Sets horizontal scale factor.
    
    @param v  horizontal scale factor to store
    */
    setScaleX :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setScaleX@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets vertical scale factor.
    
    @param v  vertical scale factor to store
    */
    setScaleY :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setScaleY@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets vertical skew factor.
    
    @param v  vertical skew factor to store
    */
    setSkewY :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSkewY@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets horizontal skew factor.
    
    @param v  horizontal skew factor to store
    */
    setSkewX :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSkewX@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets horizontal translation.
    
    @param v  horizontal translation to store
    */
    setTranslateX :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setTranslateX@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets vertical translation.
    
    @param v  vertical translation to store
    */
    setTranslateY :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setTranslateY@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets input x-axis perspective factor, which causes mapPoints() to vary input x-axis values
    inversely proportional to input y-axis values.
    
    @param v  perspective factor
    */
    setPerspX :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setPerspX@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets input y-axis perspective factor, which causes mapPoints() to vary input y-axis values
    inversely proportional to input x-axis values.
    
    @param v  perspective factor
    */
    setPerspY :: (this: *SkMatrix, v: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setPerspY@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets all values from parameters. Sets matrix to:
    
    | scaleX  skewX transX |
    |  skewY scaleY transY |
    | persp0 persp1 persp2 |
    
    @param scaleX  horizontal scale factor to store
    @param skewX   horizontal skew factor to store
    @param transX  horizontal translation to store
    @param skewY   vertical skew factor to store
    @param scaleY  vertical scale factor to store
    @param transY  vertical translation to store
    @param persp0  input x-axis values perspective factor to store
    @param persp1  input y-axis values perspective factor to store
    @param persp2  perspective scale factor to store
    */
    setAll :: (this: *SkMatrix, scaleX: SkScalar, skewX: SkScalar, transX: SkScalar, skewY: SkScalar, scaleY: SkScalar, transY: SkScalar, persp0: SkScalar, persp1: SkScalar, persp2: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setAll@SkMatrix@@QEAAAEAV1@MMMMMMMMM@Z";

    /** Copies nine scalar values contained by SkMatrix into buffer, in member value
    ascending order: kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY,
    kMPersp0, kMPersp1, kMPersp2.
    
    @param buffer  storage for nine scalar values
    */
    get9 :: (this: *SkMatrix, buffer: *[9] SkScalar) -> void #cpp_method #foreign libskia "?get9@SkMatrix@@QEBAXQEAM@Z";

    /** Sets SkMatrix to nine scalar values in buffer, in member value ascending order:
    kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY, kMPersp0, kMPersp1,
    kMPersp2.
    
    Sets matrix to:
    
    | buffer[0] buffer[1] buffer[2] |
    | buffer[3] buffer[4] buffer[5] |
    | buffer[6] buffer[7] buffer[8] |
    
    In the future, set9 followed by get9 may not return the same values. Since SkMatrix
    maps non-homogeneous coordinates, scaling all nine values produces an equivalent
    transformation, possibly improving precision.
    
    @param buffer  nine scalar values
    */
    set9 :: (this: *SkMatrix, buffer: *[9] SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?set9@SkMatrix@@QEAAAEAV1@QEBM@Z";

    /** Sets SkMatrix to identity; which has no effect on mapped SkPoint. Sets SkMatrix to:
    
    | 1 0 0 |
    | 0 1 0 |
    | 0 0 1 |
    
    Also called setIdentity(); use the one that provides better inline
    documentation.
    */
    reset :: (this: *SkMatrix) -> *SkMatrix #cpp_method #foreign libskia "?reset@SkMatrix@@QEAAAEAV1@XZ";

    /** Sets SkMatrix to identity; which has no effect on mapped SkPoint. Sets SkMatrix to:
    
    | 1 0 0 |
    | 0 1 0 |
    | 0 0 1 |
    
    Also called reset(); use the one that provides better inline
    documentation.
    */
    setIdentity :: (this: *SkMatrix) -> *SkMatrix #cpp_method #foreign libskia "?setIdentity@SkMatrix@@QEAAAEAV1@XZ";

    /** Sets SkMatrix to translate by (dx, dy).
    
    @param dx  horizontal translation
    @param dy  vertical translation
    */
    setTranslate :: (this: *SkMatrix, dx: SkScalar, dy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setTranslate@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to translate by (v.fX, v.fY).
    
    @param v  vector containing horizontal and vertical translation
    */
    setTranslate :: (this: *SkMatrix, v: *SkVector) -> *SkMatrix #cpp_method #foreign libskia "?setTranslate@SkMatrix@@QEAAAEAV1@AEBUSkPoint@@@Z";
    setTranslate :: (this: *SkMatrix, v: SkVector) -> *SkMatrix #no_context {
        return setTranslate(this, *v);
    }

    /** Sets SkMatrix to scale by sx and sy, about a pivot point at (px, py).
    The pivot point is unchanged when mapped with SkMatrix.
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    setScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setScale@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to scale by sx and sy about at pivot point at (0, 0).
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    */
    setScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setScale@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to rotate by degrees about a pivot point at (px, py).
    The pivot point is unchanged when mapped with SkMatrix.
    
    Positive degrees rotates clockwise.
    
    @param degrees  angle of axes relative to upright axes
    @param px       pivot on x-axis
    @param py       pivot on y-axis
    */
    setRotate :: (this: *SkMatrix, degrees: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setRotate@SkMatrix@@QEAAAEAV1@MMM@Z";

    /** Sets SkMatrix to rotate by degrees about a pivot point at (0, 0).
    Positive degrees rotates clockwise.
    
    @param degrees  angle of axes relative to upright axes
    */
    setRotate :: (this: *SkMatrix, degrees: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setRotate@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets SkMatrix to rotate by sinValue and cosValue, about a pivot point at (px, py).
    The pivot point is unchanged when mapped with SkMatrix.
    
    Vector (sinValue, cosValue) describes the angle of rotation relative to (0, 1).
    Vector length specifies scale.
    
    @param sinValue  rotation vector x-axis component
    @param cosValue  rotation vector y-axis component
    @param px        pivot on x-axis
    @param py        pivot on y-axis
    */
    setSinCos :: (this: *SkMatrix, sinValue: SkScalar, cosValue: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSinCos@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to rotate by sinValue and cosValue, about a pivot point at (0, 0).
    
    Vector (sinValue, cosValue) describes the angle of rotation relative to (0, 1).
    Vector length specifies scale.
    
    @param sinValue  rotation vector x-axis component
    @param cosValue  rotation vector y-axis component
    */
    setSinCos :: (this: *SkMatrix, sinValue: SkScalar, cosValue: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSinCos@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to rotate, scale, and translate using a compressed matrix form.
    
    Vector (rsxForm.fSSin, rsxForm.fSCos) describes the angle of rotation relative
    to (0, 1). Vector length specifies scale. Mapped point is rotated and scaled
    by vector, then translated by (rsxForm.fTx, rsxForm.fTy).
    
    @param rsxForm  compressed SkRSXform matrix
    @return         reference to SkMatrix
    
    example: https://fiddle.skia.org/c/@Matrix_setRSXform
    */
    setRSXform :: (this: *SkMatrix, rsxForm: *SkRSXform) -> *SkMatrix #cpp_method #foreign libskia "?setRSXform@SkMatrix@@QEAAAEAV1@AEBUSkRSXform@@@Z";
    setRSXform :: (this: *SkMatrix, rsxForm: SkRSXform) -> *SkMatrix #no_context {
        return setRSXform(this, *rsxForm);
    }

    /** Sets SkMatrix to skew by kx and ky, about a pivot point at (px, py).
    The pivot point is unchanged when mapped with SkMatrix.
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    setSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSkew@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to skew by kx and ky, about a pivot point at (0, 0).
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    */
    setSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setSkew@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix a multiplied by SkMatrix b. Either a or b may be this.
    
    Given:
    
    | A B C |      | J K L |
    a = | D E F |, b = | M N O |
    | G H I |      | P Q R |
    
    sets SkMatrix to:
    
    | A B C |   | J K L |   | AJ+BM+CP AK+BN+CQ AL+BO+CR |
    a * b = | D E F | * | M N O | = | DJ+EM+FP DK+EN+FQ DL+EO+FR |
    | G H I |   | P Q R |   | GJ+HM+IP GK+HN+IQ GL+HO+IR |
    
    @param a  SkMatrix on left side of multiply expression
    @param b  SkMatrix on right side of multiply expression
    */
    setConcat :: (this: *SkMatrix, a: *SkMatrix, b: *SkMatrix) -> *SkMatrix #cpp_method #foreign libskia "?setConcat@SkMatrix@@QEAAAEAV1@AEBV1@0@Z";
    setConcat :: (this: *SkMatrix, a: SkMatrix, b: SkMatrix) -> *SkMatrix #no_context {
        return setConcat(this, *a, *b);
    }

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from translation (dx, dy).
    This can be thought of as moving the point to be mapped before applying SkMatrix.
    
    Given:
    
    | A B C |               | 1 0 dx |
    Matrix = | D E F |,  T(dx, dy) = | 0 1 dy |
    | G H I |               | 0 0  1 |
    
    sets SkMatrix to:
    
    | A B C | | 1 0 dx |   | A B A*dx+B*dy+C |
    Matrix * T(dx, dy) = | D E F | | 0 1 dy | = | D E D*dx+E*dy+F |
    | G H I | | 0 0  1 |   | G H G*dx+H*dy+I |
    
    @param dx  x-axis translation before applying SkMatrix
    @param dy  y-axis translation before applying SkMatrix
    */
    preTranslate :: (this: *SkMatrix, dx: SkScalar, dy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preTranslate@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from scaling by (sx, sy)
    about pivot point (px, py).
    This can be thought of as scaling about a pivot point before applying SkMatrix.
    
    Given:
    
    | A B C |                       | sx  0 dx |
    Matrix = | D E F |,  S(sx, sy, px, py) = |  0 sy dy |
    | G H I |                       |  0  0  1 |
    
    where
    
    dx = px - sx * px
    dy = py - sy * py
    
    sets SkMatrix to:
    
    | A B C | | sx  0 dx |   | A*sx B*sy A*dx+B*dy+C |
    Matrix * S(sx, sy, px, py) = | D E F | |  0 sy dy | = | D*sx E*sy D*dx+E*dy+F |
    | G H I | |  0  0  1 |   | G*sx H*sy G*dx+H*dy+I |
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    preScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preScale@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from scaling by (sx, sy)
    about pivot point (0, 0).
    This can be thought of as scaling about the origin before applying SkMatrix.
    
    Given:
    
    | A B C |               | sx  0  0 |
    Matrix = | D E F |,  S(sx, sy) = |  0 sy  0 |
    | G H I |               |  0  0  1 |
    
    sets SkMatrix to:
    
    | A B C | | sx  0  0 |   | A*sx B*sy C |
    Matrix * S(sx, sy) = | D E F | |  0 sy  0 | = | D*sx E*sy F |
    | G H I | |  0  0  1 |   | G*sx H*sy I |
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    */
    preScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preScale@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from rotating by degrees
    about pivot point (px, py).
    This can be thought of as rotating about a pivot point before applying SkMatrix.
    
    Positive degrees rotates clockwise.
    
    Given:
    
    | A B C |                        | c -s dx |
    Matrix = | D E F |,  R(degrees, px, py) = | s  c dy |
    | G H I |                        | 0  0  1 |
    
    where
    
    c  = cos(degrees)
    s  = sin(degrees)
    dx =  s * py + (1 - c) * px
    dy = -s * px + (1 - c) * py
    
    sets SkMatrix to:
    
    | A B C | | c -s dx |   | Ac+Bs -As+Bc A*dx+B*dy+C |
    Matrix * R(degrees, px, py) = | D E F | | s  c dy | = | Dc+Es -Ds+Ec D*dx+E*dy+F |
    | G H I | | 0  0  1 |   | Gc+Hs -Gs+Hc G*dx+H*dy+I |
    
    @param degrees  angle of axes relative to upright axes
    @param px       pivot on x-axis
    @param py       pivot on y-axis
    */
    preRotate :: (this: *SkMatrix, degrees: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preRotate@SkMatrix@@QEAAAEAV1@MMM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from rotating by degrees
    about pivot point (0, 0).
    This can be thought of as rotating about the origin before applying SkMatrix.
    
    Positive degrees rotates clockwise.
    
    Given:
    
    | A B C |                        | c -s 0 |
    Matrix = | D E F |,  R(degrees, px, py) = | s  c 0 |
    | G H I |                        | 0  0 1 |
    
    where
    
    c  = cos(degrees)
    s  = sin(degrees)
    
    sets SkMatrix to:
    
    | A B C | | c -s 0 |   | Ac+Bs -As+Bc C |
    Matrix * R(degrees, px, py) = | D E F | | s  c 0 | = | Dc+Es -Ds+Ec F |
    | G H I | | 0  0 1 |   | Gc+Hs -Gs+Hc I |
    
    @param degrees  angle of axes relative to upright axes
    */
    preRotate :: (this: *SkMatrix, degrees: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preRotate@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from skewing by (kx, ky)
    about pivot point (px, py).
    This can be thought of as skewing about a pivot point before applying SkMatrix.
    
    Given:
    
    | A B C |                       |  1 kx dx |
    Matrix = | D E F |,  K(kx, ky, px, py) = | ky  1 dy |
    | G H I |                       |  0  0  1 |
    
    where
    
    dx = -kx * py
    dy = -ky * px
    
    sets SkMatrix to:
    
    | A B C | |  1 kx dx |   | A+B*ky A*kx+B A*dx+B*dy+C |
    Matrix * K(kx, ky, px, py) = | D E F | | ky  1 dy | = | D+E*ky D*kx+E D*dx+E*dy+F |
    | G H I | |  0  0  1 |   | G+H*ky G*kx+H G*dx+H*dy+I |
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    preSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preSkew@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix constructed from skewing by (kx, ky)
    about pivot point (0, 0).
    This can be thought of as skewing about the origin before applying SkMatrix.
    
    Given:
    
    | A B C |               |  1 kx 0 |
    Matrix = | D E F |,  K(kx, ky) = | ky  1 0 |
    | G H I |               |  0  0 1 |
    
    sets SkMatrix to:
    
    | A B C | |  1 kx 0 |   | A+B*ky A*kx+B C |
    Matrix * K(kx, ky) = | D E F | | ky  1 0 | = | D+E*ky D*kx+E F |
    | G H I | |  0  0 1 |   | G+H*ky G*kx+H I |
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    */
    preSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?preSkew@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix multiplied by SkMatrix other.
    This can be thought of mapping by other before applying SkMatrix.
    
    Given:
    
    | A B C |          | J K L |
    Matrix = | D E F |, other = | M N O |
    | G H I |          | P Q R |
    
    sets SkMatrix to:
    
    | A B C |   | J K L |   | AJ+BM+CP AK+BN+CQ AL+BO+CR |
    Matrix * other = | D E F | * | M N O | = | DJ+EM+FP DK+EN+FQ DL+EO+FR |
    | G H I |   | P Q R |   | GJ+HM+IP GK+HN+IQ GL+HO+IR |
    
    @param other  SkMatrix on right side of multiply expression
    */
    preConcat :: (this: *SkMatrix, other: *SkMatrix) -> *SkMatrix #cpp_method #foreign libskia "?preConcat@SkMatrix@@QEAAAEAV1@AEBV1@@Z";
    preConcat :: (this: *SkMatrix, other: SkMatrix) -> *SkMatrix #no_context {
        return preConcat(this, *other);
    }

    /** Sets SkMatrix to SkMatrix constructed from translation (dx, dy) multiplied by SkMatrix.
    This can be thought of as moving the point to be mapped after applying SkMatrix.
    
    Given:
    
    | J K L |               | 1 0 dx |
    Matrix = | M N O |,  T(dx, dy) = | 0 1 dy |
    | P Q R |               | 0 0  1 |
    
    sets SkMatrix to:
    
    | 1 0 dx | | J K L |   | J+dx*P K+dx*Q L+dx*R |
    T(dx, dy) * Matrix = | 0 1 dy | | M N O | = | M+dy*P N+dy*Q O+dy*R |
    | 0 0  1 | | P Q R |   |      P      Q      R |
    
    @param dx  x-axis translation after applying SkMatrix
    @param dy  y-axis translation after applying SkMatrix
    */
    postTranslate :: (this: *SkMatrix, dx: SkScalar, dy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postTranslate@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix constructed from scaling by (sx, sy) about pivot point
    (px, py), multiplied by SkMatrix.
    This can be thought of as scaling about a pivot point after applying SkMatrix.
    
    Given:
    
    | J K L |                       | sx  0 dx |
    Matrix = | M N O |,  S(sx, sy, px, py) = |  0 sy dy |
    | P Q R |                       |  0  0  1 |
    
    where
    
    dx = px - sx * px
    dy = py - sy * py
    
    sets SkMatrix to:
    
    | sx  0 dx | | J K L |   | sx*J+dx*P sx*K+dx*Q sx*L+dx+R |
    S(sx, sy, px, py) * Matrix = |  0 sy dy | | M N O | = | sy*M+dy*P sy*N+dy*Q sy*O+dy*R |
    |  0  0  1 | | P Q R |   |         P         Q         R |
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    postScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postScale@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to SkMatrix constructed from scaling by (sx, sy) about pivot point
    (0, 0), multiplied by SkMatrix.
    This can be thought of as scaling about the origin after applying SkMatrix.
    
    Given:
    
    | J K L |               | sx  0  0 |
    Matrix = | M N O |,  S(sx, sy) = |  0 sy  0 |
    | P Q R |               |  0  0  1 |
    
    sets SkMatrix to:
    
    | sx  0  0 | | J K L |   | sx*J sx*K sx*L |
    S(sx, sy) * Matrix = |  0 sy  0 | | M N O | = | sy*M sy*N sy*O |
    |  0  0  1 | | P Q R |   |    P    Q    R |
    
    @param sx  horizontal scale factor
    @param sy  vertical scale factor
    */
    postScale :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postScale@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix constructed from rotating by degrees about pivot point
    (px, py), multiplied by SkMatrix.
    This can be thought of as rotating about a pivot point after applying SkMatrix.
    
    Positive degrees rotates clockwise.
    
    Given:
    
    | J K L |                        | c -s dx |
    Matrix = | M N O |,  R(degrees, px, py) = | s  c dy |
    | P Q R |                        | 0  0  1 |
    
    where
    
    c  = cos(degrees)
    s  = sin(degrees)
    dx =  s * py + (1 - c) * px
    dy = -s * px + (1 - c) * py
    
    sets SkMatrix to:
    
    |c -s dx| |J K L|   |cJ-sM+dx*P cK-sN+dx*Q cL-sO+dx+R|
    R(degrees, px, py) * Matrix = |s  c dy| |M N O| = |sJ+cM+dy*P sK+cN+dy*Q sL+cO+dy*R|
    |0  0  1| |P Q R|   |         P          Q          R|
    
    @param degrees  angle of axes relative to upright axes
    @param px       pivot on x-axis
    @param py       pivot on y-axis
    */
    postRotate :: (this: *SkMatrix, degrees: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postRotate@SkMatrix@@QEAAAEAV1@MMM@Z";

    /** Sets SkMatrix to SkMatrix constructed from rotating by degrees about pivot point
    (0, 0), multiplied by SkMatrix.
    This can be thought of as rotating about the origin after applying SkMatrix.
    
    Positive degrees rotates clockwise.
    
    Given:
    
    | J K L |                        | c -s 0 |
    Matrix = | M N O |,  R(degrees, px, py) = | s  c 0 |
    | P Q R |                        | 0  0 1 |
    
    where
    
    c  = cos(degrees)
    s  = sin(degrees)
    
    sets SkMatrix to:
    
    | c -s dx | | J K L |   | cJ-sM cK-sN cL-sO |
    R(degrees, px, py) * Matrix = | s  c dy | | M N O | = | sJ+cM sK+cN sL+cO |
    | 0  0  1 | | P Q R |   |     P     Q     R |
    
    @param degrees  angle of axes relative to upright axes
    */
    postRotate :: (this: *SkMatrix, degrees: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postRotate@SkMatrix@@QEAAAEAV1@M@Z";

    /** Sets SkMatrix to SkMatrix constructed from skewing by (kx, ky) about pivot point
    (px, py), multiplied by SkMatrix.
    This can be thought of as skewing about a pivot point after applying SkMatrix.
    
    Given:
    
    | J K L |                       |  1 kx dx |
    Matrix = | M N O |,  K(kx, ky, px, py) = | ky  1 dy |
    | P Q R |                       |  0  0  1 |
    
    where
    
    dx = -kx * py
    dy = -ky * px
    
    sets SkMatrix to:
    
    | 1 kx dx| |J K L|   |J+kx*M+dx*P K+kx*N+dx*Q L+kx*O+dx+R|
    K(kx, ky, px, py) * Matrix = |ky  1 dy| |M N O| = |ky*J+M+dy*P ky*K+N+dy*Q ky*L+O+dy*R|
    | 0  0  1| |P Q R|   |          P           Q           R|
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    @param px  pivot on x-axis
    @param py  pivot on y-axis
    */
    postSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar, px: SkScalar, py: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postSkew@SkMatrix@@QEAAAEAV1@MMMM@Z";

    /** Sets SkMatrix to SkMatrix constructed from skewing by (kx, ky) about pivot point
    (0, 0), multiplied by SkMatrix.
    This can be thought of as skewing about the origin after applying SkMatrix.
    
    Given:
    
    | J K L |               |  1 kx 0 |
    Matrix = | M N O |,  K(kx, ky) = | ky  1 0 |
    | P Q R |               |  0  0 1 |
    
    sets SkMatrix to:
    
    |  1 kx 0 | | J K L |   | J+kx*M K+kx*N L+kx*O |
    K(kx, ky) * Matrix = | ky  1 0 | | M N O | = | ky*J+M ky*K+N ky*L+O |
    |  0  0 1 | | P Q R |   |      P      Q      R |
    
    @param kx  horizontal skew factor
    @param ky  vertical skew factor
    */
    postSkew :: (this: *SkMatrix, kx: SkScalar, ky: SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?postSkew@SkMatrix@@QEAAAEAV1@MM@Z";

    /** Sets SkMatrix to SkMatrix other multiplied by SkMatrix.
    This can be thought of mapping by other after applying SkMatrix.
    
    Given:
    
    | J K L |           | A B C |
    Matrix = | M N O |,  other = | D E F |
    | P Q R |           | G H I |
    
    sets SkMatrix to:
    
    | A B C |   | J K L |   | AJ+BM+CP AK+BN+CQ AL+BO+CR |
    other * Matrix = | D E F | * | M N O | = | DJ+EM+FP DK+EN+FQ DL+EO+FR |
    | G H I |   | P Q R |   | GJ+HM+IP GK+HN+IQ GL+HO+IR |
    
    @param other  SkMatrix on left side of multiply expression
    */
    postConcat :: (this: *SkMatrix, other: *SkMatrix) -> *SkMatrix #cpp_method #foreign libskia "?postConcat@SkMatrix@@QEAAAEAV1@AEBV1@@Z";
    postConcat :: (this: *SkMatrix, other: SkMatrix) -> *SkMatrix #no_context {
        return postConcat(this, *other);
    }

    /** If possible, return a matrix that will transform the src rect to the dst rect.
    *  If the src is empty, this will return {}.
    *  If the dst is empty, this will return the zero matrix (degenerate).
    */
    Rect2Rect :: (src: *SkRect, dst: *SkRect, unknown0: ScaleToFit = .Fill_ScaleToFit) -> std.optional(SkMatrix) #cpp_return_type_is_non_pod #foreign libskia "?Rect2Rect@SkMatrix@@SA?AV?$optional@VSkMatrix@@@std@@AEBUSkRect@@0W4ScaleToFit@1@@Z";
    Rect2Rect :: (src: SkRect, dst: SkRect, unknown0: ScaleToFit = .Fill_ScaleToFit) -> std.optional(SkMatrix) #no_context {
        return Rect2Rect(*src, *dst, unknown0);
    }

    RectToRectOrIdentity :: (src: *SkRect, dst: *SkRect, stf: ScaleToFit = .Fill_ScaleToFit) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?RectToRectOrIdentity@SkMatrix@@SA?AV1@AEBUSkRect@@0W4ScaleToFit@1@@Z";
    RectToRectOrIdentity :: (src: SkRect, dst: SkRect, stf: ScaleToFit = .Fill_ScaleToFit) -> SkMatrix #no_context {
        return RectToRectOrIdentity(*src, *dst, stf);
    }

    setRectToRect :: (this: *SkMatrix, src: *SkRect, dst: *SkRect, stf: ScaleToFit) -> bool #cpp_method #foreign libskia "?setRectToRect@SkMatrix@@QEAA_NAEBUSkRect@@0W4ScaleToFit@1@@Z";
    setRectToRect :: (this: *SkMatrix, src: SkRect, dst: SkRect, stf: ScaleToFit) -> bool #no_context {
        return setRectToRect(this, *src, *dst, stf);
    }

    MakeRectToRect :: (src: *SkRect, dst: *SkRect, stf: ScaleToFit) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?MakeRectToRect@SkMatrix@@SA?AV1@AEBUSkRect@@0W4ScaleToFit@1@@Z";
    MakeRectToRect :: (src: SkRect, dst: SkRect, stf: ScaleToFit) -> SkMatrix #no_context {
        return MakeRectToRect(*src, *dst, stf);
    }

    RectToRect :: (src: *SkRect, dst: *SkRect, mode: ScaleToFit = .Fill_ScaleToFit) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?RectToRect@SkMatrix@@SA?AV1@AEBUSkRect@@0W4ScaleToFit@1@@Z";
    RectToRect :: (src: SkRect, dst: SkRect, mode: ScaleToFit = .Fill_ScaleToFit) -> SkMatrix #no_context {
        return RectToRect(*src, *dst, mode);
    }

    /** Compute a matrix from two polygons, such that if the matrix was applied
    *  to the src polygon, it would produce the dst polygon.
    *
    *  If the size of the two spans are not equal, or if they are > 4, return {}.
    *  If the resulting matrix is non-invertible, return {}.
    *
    *  example: https://fiddle.skia.org/c/@Matrix_setPolyToPoly
    */
    PolyToPoly :: (src: SkSpan(SkPoint), dst: SkSpan(SkPoint)) -> std.optional(SkMatrix) #cpp_return_type_is_non_pod #foreign libskia "?PolyToPoly@SkMatrix@@SA?AV?$optional@VSkMatrix@@@std@@V?$SkSpan@$$CBUSkPoint@@@@0@Z";

    setPolyToPoly :: (this: *SkMatrix, src: SkSpan(SkPoint), dst: SkSpan(SkPoint)) -> bool #cpp_method #foreign libskia "?setPolyToPoly@SkMatrix@@QEAA_NV?$SkSpan@$$CBUSkPoint@@@@0@Z";

    /*
    * If this matrix is invertible, return its inverse, else return {}.
    */
    invert :: (this: *SkMatrix) -> std.optional(SkMatrix) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?invert@SkMatrix@@QEBA?AV?$optional@VSkMatrix@@@std@@XZ";

    // deprecated
    invert :: (this: *SkMatrix, inverse: *SkMatrix) -> bool #cpp_method #foreign libskia "?invert@SkMatrix@@QEBA_NPEAV1@@Z";

    /** Fills affine with identity values in column major order.
    Sets affine to:
    
    | 1 0 0 |
    | 0 1 0 |
    
    Affine 3 by 2 matrices in column major order are used by OpenGL and XPS.
    
    @param affine  storage for 3 by 2 affine matrix
    
    example: https://fiddle.skia.org/c/@Matrix_SetAffineIdentity
    */
    SetAffineIdentity :: (affine: *[6] SkScalar) -> void #foreign libskia "?SetAffineIdentity@SkMatrix@@SAXQEAM@Z";

    /** Fills affine in column major order. Sets affine to:
    
    | scale-x  skew-x translate-x |
    | skew-y  scale-y translate-y |
    
    If SkMatrix contains perspective, returns false and leaves affine unchanged.
    
    @param affine  storage for 3 by 2 affine matrix; may be nullptr
    @return        true if SkMatrix does not contain perspective
    */
    asAffine :: (this: *SkMatrix, affine: *[6] SkScalar) -> bool #cpp_method #foreign libskia "?asAffine@SkMatrix@@QEBA_NQEAM@Z";

    /** Sets SkMatrix to affine values, passed in column major order. Given affine,
    column, then row, as:
    
    | scale-x  skew-x translate-x |
    |  skew-y scale-y translate-y |
    
    SkMatrix is set, row, then column, to:
    
    | scale-x  skew-x translate-x |
    |  skew-y scale-y translate-y |
    |       0       0           1 |
    
    @param affine  3 by 2 affine matrix
    */
    setAffine :: (this: *SkMatrix, affine: *[6] SkScalar) -> *SkMatrix #cpp_method #foreign libskia "?setAffine@SkMatrix@@QEAAAEAV1@QEBM@Z";

    /**
    *  A matrix is categorized as 'perspective' if the bottom row is not [0, 0, 1].
    *  However, for most uses (e.g. mapPoints) a bottom row of [0, 0, X] behaves like a
    *  non-perspective matrix, though it will be categorized as perspective. Calling
    *  normalizePerspective() will change the matrix such that, if its bottom row was [0, 0, X],
    *  it will be changed to [0, 0, 1] by scaling the rest of the matrix by 1/X.
    *
    *  | A B C |    | A/X B/X C/X |
    *  | D E F | -> | D/X E/X F/X |   for X != 0
    *  | 0 0 X |    |  0   0   1  |
    */
    normalizePerspective :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "?normalizePerspective@SkMatrix@@QEAAXXZ";

    /** Maps src SkPoint array of length count to dst SkPoint array of equal or greater
    length. SkPoint are mapped by multiplying each SkPoint by SkMatrix. Given:
    
    | A B C |        | x |
    Matrix = | D E F |,  pt = | y |
    | G H I |        | 1 |
    
    where
    
    for (i = 0; i < count; ++i) {
    x = src[i].fX
    y = src[i].fY
    }
    
    each dst SkPoint is computed as:
    
    |A B C| |x|                               Ax+By+C   Dx+Ey+F
    Matrix * pt = |D E F| |y| = |Ax+By+C Dx+Ey+F Gx+Hy+I| = ------- , -------
    |G H I| |1|                               Gx+Hy+I   Gx+Hy+I
    
    src and dst may point to the same storage.
    
    @param dst    span where the transformed points are written
    @param src    spen where the points are read from
    
    Note: min(dst.size(), src.size()) is the number of points that will be written to dst.
    
    example: https://fiddle.skia.org/c/@Matrix_mapPoints
    */
    mapPoints :: (this: *SkMatrix, dst: SkSpan(SkPoint), src: SkSpan(SkPoint)) -> void #cpp_method #foreign libskia "?mapPoints@SkMatrix@@QEBAXV?$SkSpan@USkPoint@@@@V?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Maps pts SkPoint array of length count in place. SkPoint are mapped by multiplying
    each SkPoint by SkMatrix. Given:
    
    | A B C |        | x |
    Matrix = | D E F |,  pt = | y |
    | G H I |        | 1 |
    
    where
    
    for (i = 0; i < count; ++i) {
    x = pts[i].fX
    y = pts[i].fY
    }
    
    each resulting pts SkPoint is computed as:
    
    |A B C| |x|                               Ax+By+C   Dx+Ey+F
    Matrix * pt = |D E F| |y| = |Ax+By+C Dx+Ey+F Gx+Hy+I| = ------- , -------
    |G H I| |1|                               Gx+Hy+I   Gx+Hy+I
    
    @param pts    span of points to be transformed in-place
    */
    mapPoints :: (this: *SkMatrix, pts: SkSpan(SkPoint)) -> void #cpp_method #foreign libskia "?mapPoints@SkMatrix@@QEBAXV?$SkSpan@USkPoint@@@@@Z";

    /** Maps src SkPoint3 array of length count to dst SkPoint3 array, which must of length count or
    greater. SkPoint3 array is mapped by multiplying each SkPoint3 by SkMatrix. Given:
    
    | A B C |         | x |
    Matrix = | D E F |,  src = | y |
    | G H I |         | z |
    
    each resulting dst SkPoint is computed as:
    
    |A B C| |x|
    Matrix * src = |D E F| |y| = |Ax+By+Cz Dx+Ey+Fz Gx+Hy+Iz|
    |G H I| |z|
    
    @param dst    span where the transformed points are written
    @param src    spen where the points are read from
    
    Note: min(dst.size(), src.size()) is the number of points that will be written to dst.
    
    example: https://fiddle.skia.org/c/@Matrix_mapHomogeneousPoints
    */
    mapHomogeneousPoints :: (this: *SkMatrix, dst: SkSpan(SkPoint3), src: SkSpan(SkPoint3)) -> void #cpp_method #foreign libskia "?mapHomogeneousPoints@SkMatrix@@QEBAXV?$SkSpan@USkPoint3@@@@V?$SkSpan@$$CBUSkPoint3@@@@@Z";

    mapHomogeneousPoint :: (this: *SkMatrix, src: SkPoint3) -> SkPoint3 #cpp_method #foreign libskia "?mapHomogeneousPoint@SkMatrix@@QEBA?AUSkPoint3@@U2@@Z";

    /**
    *  Returns homogeneous points, starting with 2D src points (with implied w = 1).
    *
    *  Note: min(dst.size(), src.size()) is the number of points that will be written to dst.
    
    */
    mapPointsToHomogeneous :: (this: *SkMatrix, dst: SkSpan(SkPoint3), src: SkSpan(SkPoint)) -> void #cpp_method #foreign libskia "?mapPointsToHomogeneous@SkMatrix@@QEBAXV?$SkSpan@USkPoint3@@@@V?$SkSpan@$$CBUSkPoint@@@@@Z";

    mapPointToHomogeneous :: (this: *SkMatrix, src: SkPoint) -> SkPoint3 #cpp_method #foreign libskia "?mapPointToHomogeneous@SkMatrix@@QEBA?AUSkPoint3@@USkPoint@@@Z";

    /** Returns SkPoint pt multiplied by SkMatrix. Given:
    
    | A B C |        | x |
    Matrix = | D E F |,  pt = | y |
    | G H I |        | 1 |
    
    result is computed as:
    
    |A B C| |x|                               Ax+By+C   Dx+Ey+F
    Matrix * pt = |D E F| |y| = |Ax+By+C Dx+Ey+F Gx+Hy+I| = ------- , -------
    |G H I| |1|                               Gx+Hy+I   Gx+Hy+I
    
    @param p  SkPoint to map
    @return mapped SkPoint
    */
    mapPoint :: (this: *SkMatrix, p: SkPoint) -> SkPoint #cpp_method #foreign libskia "?mapPoint@SkMatrix@@QEBA?AUSkPoint@@U2@@Z";

    /*
    *  If the caller knows the matrix has no perspective, this will inline the
    *  math, making it more efficient than calling mapPoint().
    */
    mapPointAffine :: (this: *SkMatrix, p: SkPoint) -> SkPoint #cpp_method #foreign libskia "?mapPointAffine@SkMatrix@@QEBA?AUSkPoint@@U2@@Z";

    /** Returns (0, 0) multiplied by SkMatrix. Given:
    
    | A B C |        | 0 |
    Matrix = | D E F |,  pt = | 0 |
    | G H I |        | 1 |
    
    result is computed as:
    
    |A B C| |0|             C    F
    Matrix * pt = |D E F| |0| = |C F I| = -  , -
    |G H I| |1|             I    I
    
    @return   mapped (0, 0)
    */
    mapOrigin :: (this: *SkMatrix) -> SkPoint #cpp_method #foreign libskia "?mapOrigin@SkMatrix@@QEBA?AUSkPoint@@XZ";

    /** Maps src vector array of length count to vector SkPoint array of equal or greater
    length. Vectors are mapped by multiplying each vector by SkMatrix, treating
    SkMatrix translation as zero. Given:
    
    | A B 0 |         | x |
    Matrix = | D E 0 |,  src = | y |
    | G H I |         | 1 |
    
    where
    
    for (i = 0; i < count; ++i) {
    x = src[i].fX
    y = src[i].fY
    }
    
    each dst vector is computed as:
    
    |A B 0| |x|                            Ax+By     Dx+Ey
    Matrix * src = |D E 0| |y| = |Ax+By Dx+Ey Gx+Hy+I| = ------- , -------
    |G H I| |1|                           Gx+Hy+I   Gx+Hy+I
    
    src and dst may point to the same storage.
    
    @param dst    span where the transformed vectors are written
    @param src    spen where the vectors are read from
    
    Note: min(dst.size(), src.size()) is the number of points that will be written to dst.
    
    example: https://fiddle.skia.org/c/@Matrix_mapVectors
    */
    mapVectors :: (this: *SkMatrix, dst: SkSpan(SkVector), src: SkSpan(SkVector)) -> void #cpp_method #foreign libskia "?mapVectors@SkMatrix@@QEBAXV?$SkSpan@USkPoint@@@@V?$SkSpan@$$CBUSkPoint@@@@@Z";

    /** Maps vecs vector array of length count in place, multiplying each vector by
    SkMatrix, treating SkMatrix translation as zero. Given:
    
    | A B 0 |         | x |
    Matrix = | D E 0 |,  vec = | y |
    | G H I |         | 1 |
    
    where
    
    for (i = 0; i < count; ++i) {
    x = vecs[i].fX
    y = vecs[i].fY
    }
    
    each result vector is computed as:
    
    |A B 0| |x|                            Ax+By     Dx+Ey
    Matrix * vec = |D E 0| |y| = |Ax+By Dx+Ey Gx+Hy+I| = ------- , -------
    |G H I| |1|                           Gx+Hy+I   Gx+Hy+I
    
    @param vecs   vectors to transform, and storage for mapped vectors
    */
    mapVectors :: (this: *SkMatrix, vecs: SkSpan(SkVector)) -> void #cpp_method #foreign libskia "?mapVectors@SkMatrix@@QEBAXV?$SkSpan@USkPoint@@@@@Z";

    /** Returns vector (dx, dy) multiplied by SkMatrix, treating SkMatrix translation as zero.
    Given:
    
    | A B 0 |         | dx |
    Matrix = | D E 0 |,  vec = | dy |
    | G H I |         |  1 |
    
    each result vector is computed as:
    
    |A B 0| |dx|                                        A*dx+B*dy     D*dx+E*dy
    Matrix * vec = |D E 0| |dy| = |A*dx+B*dy D*dx+E*dy G*dx+H*dy+I| = ----------- , -----------
    |G H I| | 1|                                       G*dx+H*dy+I   G*dx+*dHy+I
    
    @param dx  x-axis value of vector to map
    @param dy  y-axis value of vector to map
    @return    mapped vector
    */
    mapVector :: (this: *SkMatrix, vec: SkVector) -> SkVector #cpp_method #foreign libskia "?mapVector@SkMatrix@@QEBA?AUSkPoint@@U2@@Z";

    mapVector :: (this: *SkMatrix, dx: SkScalar, dy: SkScalar) -> SkVector #cpp_method #foreign libskia "?mapVector@SkMatrix@@QEBA?AUSkPoint@@MM@Z";

    /** Sets dst to bounds of src corners mapped by SkMatrix.
    Returns true if mapped corners are dst corners.
    
    Returned value is the same as calling rectStaysRect().
    
    @param dst  storage for bounds of mapped SkPoint
    @param src  SkRect to map
    @param pc   whether to apply perspective clipping
    @return     true if dst is equivalent to mapped src
    
    example: https://fiddle.skia.org/c/@Matrix_mapRect
    */
    mapRect :: (this: *SkMatrix, dst: *SkRect, src: *SkRect) -> bool #cpp_method #foreign libskia "?mapRect@SkMatrix@@QEBA_NPEAUSkRect@@AEBU2@@Z";
    mapRect :: (this: *SkMatrix, dst: *SkRect, src: SkRect) -> bool #no_context {
        return mapRect(this, dst, *src);
    }

    /** Sets rect to bounds of rect corners mapped by SkMatrix.
    Returns true if mapped corners are computed rect corners.
    
    Returned value is the same as calling rectStaysRect().
    
    @param rect  rectangle to map, and storage for bounds of mapped corners
    @param pc    whether to apply perspective clipping
    @return      true if result is equivalent to mapped rect
    */
    mapRect :: (this: /*const*/ *SkMatrix, rect: *SkRect) -> bool #cpp_method #foreign libskia "?mapRect@SkMatrix@@QEBA_NPEAUSkRect@@@Z";

    /** Returns bounds of src corners mapped by SkMatrix.
    
    @param src  rectangle to map
    @return     mapped bounds
    */
    mapRect_1 :: (this: /*const*/ *SkMatrix, src: /*const reference*/ *SkRect) -> SkRect #cpp_method #foreign libskia "?mapRect@SkMatrix@@QEBA?AUSkRect@@AEBU2@@Z";
    mapRect_1 :: (this: *SkMatrix, src: SkRect) -> SkRect #no_context {
        return mapRect_1(this, *src);
    }

    /** Maps four corners of rect to dst. SkPoint are mapped by multiplying each
    rect corner by SkMatrix. rect corner is processed in this order:
    (rect.fLeft, rect.fTop), (rect.fRight, rect.fTop), (rect.fRight, rect.fBottom),
    (rect.fLeft, rect.fBottom).
    
    rect may be empty: rect.fLeft may be greater than or equal to rect.fRight;
    rect.fTop may be greater than or equal to rect.fBottom.
    
    Given:
    
    | A B C |        | x |
    Matrix = | D E F |,  pt = | y |
    | G H I |        | 1 |
    
    where pt is initialized from each of (rect.fLeft, rect.fTop),
    (rect.fRight, rect.fTop), (rect.fRight, rect.fBottom), (rect.fLeft, rect.fBottom),
    each dst SkPoint is computed as:
    
    |A B C| |x|                               Ax+By+C   Dx+Ey+F
    Matrix * pt = |D E F| |y| = |Ax+By+C Dx+Ey+F Gx+Hy+I| = ------- , -------
    |G H I| |1|                               Gx+Hy+I   Gx+Hy+I
    
    @param dst   storage for mapped corner SkPoint
    @param rect  SkRect to map
    
    Note: this does not perform perspective clipping (as that might result in more than
    4 points, so results are suspect if the matrix contains perspective.
    */
    mapRectToQuad :: (this: *SkMatrix, dst: *[4] SkPoint, rect: *SkRect) -> void #cpp_method #foreign libskia "?mapRectToQuad@SkMatrix@@QEBAXQEAUSkPoint@@AEBUSkRect@@@Z";
    mapRectToQuad :: (this: *SkMatrix, dst: *[4] SkPoint, rect: SkRect) #no_context {
        mapRectToQuad(this, dst, *rect);
    }

    /** Sets dst to bounds of src corners mapped by SkMatrix. If matrix contains
    elements other than scale or translate: asserts if SK_DEBUG is defined;
    otherwise, results are undefined.
    
    @param dst  storage for bounds of mapped SkPoint
    @param src  SkRect to map
    
    example: https://fiddle.skia.org/c/@Matrix_mapRectScaleTranslate
    */
    mapRectScaleTranslate :: (this: *SkMatrix, dst: *SkRect, src: *SkRect) -> void #cpp_method #foreign libskia "?mapRectScaleTranslate@SkMatrix@@QEBAXPEAUSkRect@@AEBU2@@Z";
    mapRectScaleTranslate :: (this: *SkMatrix, dst: *SkRect, src: SkRect) #no_context {
        mapRectScaleTranslate(this, dst, *src);
    }

    /** Returns geometric mean radius of ellipse formed by constructing circle of
    size radius, and mapping constructed circle with SkMatrix. The result squared is
    equal to the major axis length times the minor axis length.
    Result is not meaningful if SkMatrix contains perspective elements.
    
    @param radius  circle size to map
    @return        average mapped radius
    
    example: https://fiddle.skia.org/c/@Matrix_mapRadius
    */
    mapRadius :: (this: *SkMatrix, radius: SkScalar) -> SkScalar #cpp_method #foreign libskia "?mapRadius@SkMatrix@@QEBAMM@Z";

    /** Writes text representation of SkMatrix to standard output. Floating point values
    are written with limited precision; it may not be possible to reconstruct
    original SkMatrix from output.
    
    example: https://fiddle.skia.org/c/@Matrix_dump
    */
    dump :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "?dump@SkMatrix@@QEBAXXZ";

    /** Returns the minimum scaling factor of SkMatrix by decomposing the scaling and
    skewing elements.
    Returns -1 if scale factor overflows or SkMatrix contains perspective.
    
    @return  minimum scale factor
    
    example: https://fiddle.skia.org/c/@Matrix_getMinScale
    */
    getMinScale :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getMinScale@SkMatrix@@QEBAMXZ";

    /** Returns the maximum scaling factor of SkMatrix by decomposing the scaling and
    skewing elements.
    Returns -1 if scale factor overflows or SkMatrix contains perspective.
    
    @return  maximum scale factor
    
    example: https://fiddle.skia.org/c/@Matrix_getMaxScale
    */
    getMaxScale :: (this: *SkMatrix) -> SkScalar #cpp_method #foreign libskia "?getMaxScale@SkMatrix@@QEBAMXZ";

    /** Sets scaleFactors[0] to the minimum scaling factor, and scaleFactors[1] to the
    maximum scaling factor. Scaling factors are computed by decomposing
    the SkMatrix scaling and skewing elements.
    
    Returns true if scaleFactors are found; otherwise, returns false and sets
    scaleFactors to undefined values.
    
    @param scaleFactors  storage for minimum and maximum scale factors
    @return              true if scale factors were computed correctly
    */
    getMinMaxScales :: (this: *SkMatrix, scaleFactors: *[2] SkScalar) -> bool #cpp_method #foreign libskia "?getMinMaxScales@SkMatrix@@QEBA_NQEAM@Z";

    /** Decomposes SkMatrix into scale components and whatever remains. Returns false if
    SkMatrix could not be decomposed.
    
    Sets scale to portion of SkMatrix that scale axes. Sets remaining to SkMatrix
    with scaling factored out. remaining may be passed as nullptr
    to determine if SkMatrix can be decomposed without computing remainder.
    
    Returns true if scale components are found. scale and remaining are
    unchanged if SkMatrix contains perspective; scale factors are not finite, or
    are nearly zero.
    
    On success: Matrix = Remaining * scale.
    
    @param scale      axes scaling factors; may be nullptr
    @param remaining  SkMatrix without scaling; may be nullptr
    @return           true if scale can be computed
    
    example: https://fiddle.skia.org/c/@Matrix_decomposeScale
    */
    decomposeScale :: (this: *SkMatrix, scale: *SkSize, remaining: *SkMatrix = null) -> bool #cpp_method #foreign libskia "?decomposeScale@SkMatrix@@QEBA_NPEAUSkSize@@PEAV1@@Z";

    /** Returns reference to const identity SkMatrix. Returned SkMatrix is set to:
    
    | 1 0 0 |
    | 0 1 0 |
    | 0 0 1 |
    
    @return  const identity SkMatrix
    
    example: https://fiddle.skia.org/c/@Matrix_I
    */
    I :: () -> *SkMatrix #foreign libskia "?I@SkMatrix@@SAAEBV1@XZ";

    /** Returns reference to a const SkMatrix with invalid values. Returned SkMatrix is set
    to:
    
    | SK_ScalarMax SK_ScalarMax SK_ScalarMax |
    | SK_ScalarMax SK_ScalarMax SK_ScalarMax |
    | SK_ScalarMax SK_ScalarMax SK_ScalarMax |
    
    @return  const invalid SkMatrix
    
    example: https://fiddle.skia.org/c/@Matrix_InvalidMatrix
    */
    InvalidMatrix :: () -> *SkMatrix #foreign libskia "?InvalidMatrix@SkMatrix@@SAAEBV1@XZ";

    /** Returns SkMatrix a multiplied by SkMatrix b.
    
    Given:
    
    | A B C |      | J K L |
    a = | D E F |, b = | M N O |
    | G H I |      | P Q R |
    
    sets SkMatrix to:
    
    | A B C |   | J K L |   | AJ+BM+CP AK+BN+CQ AL+BO+CR |
    a * b = | D E F | * | M N O | = | DJ+EM+FP DK+EN+FQ DL+EO+FR |
    | G H I |   | P Q R |   | GJ+HM+IP GK+HN+IQ GL+HO+IR |
    
    @param a  SkMatrix on left side of multiply expression
    @param b  SkMatrix on right side of multiply expression
    @return   SkMatrix computed from a times b
    */
    Concat :: (a: *SkMatrix, b: *SkMatrix) -> SkMatrix #cpp_return_type_is_non_pod #foreign libskia "?Concat@SkMatrix@@SA?AV1@AEBV1@0@Z";
    Concat :: (a: SkMatrix, b: SkMatrix) -> SkMatrix #no_context {
        return Concat(*a, *b);
    }

    /** Sets internal cache to unknown state. Use to force update after repeated
    modifications to SkMatrix element reference returned by operator_subscript(int index).
    */
    dirtyMatrixTypeCache :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "?dirtyMatrixTypeCache@SkMatrix@@QEAAXXZ";

    /** Initializes SkMatrix with scale and translate elements.
    
    | sx  0 tx |
    |  0 sy ty |
    |  0  0  1 |
    
    @param sx  horizontal scale factor to store
    @param sy  vertical scale factor to store
    @param tx  horizontal translation to store
    @param ty  vertical translation to store
    */
    setScaleTranslate :: (this: *SkMatrix, sx: SkScalar, sy: SkScalar, tx: SkScalar, ty: SkScalar) -> void #cpp_method #foreign libskia "?setScaleTranslate@SkMatrix@@QEAAXMMMM@Z";

    /** Returns true if all elements of the matrix are finite. Returns false if any
    element is infinity, or NaN.
    
    @return  true if matrix has only finite elements
    */
    isFinite :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?isFinite@SkMatrix@@QEBA_NXZ";

    /** Set if the matrix will map a rectangle to another rectangle. This
    can be true if the matrix is scale-only, or rotates a multiple of
    90 degrees.
    
    This bit will be set on identity matrices
    */
    kRectStaysRect_Mask:        s32 : 16;

    /** Set if the perspective bit is valid even though the rest of
    the matrix is Unknown.
    */
    kOnlyPerspectiveValid_Mask: s32 : 64;

    kUnknown_Mask:              s32 : 128;

    kORableMasks:               s32 : 15; // Translate(1) | Scale(2) | Affine(4) | Perspective(8)

    kAllMasks:                  s32 : 31; // kORableMasks(15) | kRectStaysRect(16)

    fMat:                       [9] SkScalar;
    fTypeMask:                  s32;

    Constructor :: (this: *SkMatrix, sx: SkScalar, kx: SkScalar, tx: SkScalar, ky: SkScalar, sy: SkScalar, ty: SkScalar, p0: SkScalar, p1: SkScalar, p2: SkScalar, typeMask: s32) -> void #cpp_method #foreign libskia "??0SkMatrix@@AEAA@MMMMMMMMMH@Z";

    ComputeInv :: (dst: *[9] SkScalar, src: *[9] SkScalar, invDet: float64, isPersp: bool) -> void #foreign libskia "?ComputeInv@SkMatrix@@CAXQEAMQEBMN_N@Z";

    computeTypeMask :: (this: *SkMatrix) -> u8 #cpp_method #foreign libskia "?computeTypeMask@SkMatrix@@AEBAEXZ";
    computePerspectiveTypeMask :: (this: *SkMatrix) -> u8 #cpp_method #foreign libskia "?computePerspectiveTypeMask@SkMatrix@@AEBAEXZ";

    setTypeMask :: (this: *SkMatrix, mask: s32) -> void #cpp_method #foreign libskia "?setTypeMask@SkMatrix@@AEAAXH@Z";

    orTypeMask :: (this: *SkMatrix, mask: s32) -> void #cpp_method #foreign libskia "?orTypeMask@SkMatrix@@AEAAXH@Z";

    clearTypeMask :: (this: *SkMatrix, mask: s32) -> void #cpp_method #foreign libskia "?clearTypeMask@SkMatrix@@AEAAXH@Z";

    getPerspectiveTypeMaskOnly :: (this: *SkMatrix) -> TypeMask #cpp_method #foreign libskia "?getPerspectiveTypeMaskOnly@SkMatrix@@AEBA?AW4TypeMask@1@XZ";

    /** Returns true if we already know that the matrix is identity;
    false otherwise.
    */
    isTriviallyIdentity :: (this: *SkMatrix) -> bool #cpp_method #foreign libskia "?isTriviallyIdentity@SkMatrix@@AEBA_NXZ";

    updateTranslateMask :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "?updateTranslateMask@SkMatrix@@AEAAXXZ";

    /*
    *  If the caller knows the matrix perspective, this dos the extra work to
    *  correctly compute the mapping. mapPoint() calls this, but only after
    *  checking if the matrix includes perspective.
    */
    mapPointPerspective :: (this: *SkMatrix, pt: SkPoint) -> SkPoint #cpp_method #foreign libskia "?mapPointPerspective@SkMatrix@@AEBA?AUSkPoint@@U2@@Z";

    MapPtsProc :: #type (mat: *SkMatrix, dst: *SkPoint, src: *SkPoint, count: s32) -> void #c_call;

    GetMapPtsProc :: (mask: TypeMask) -> MapPtsProc #foreign libskia "?GetMapPtsProc@SkMatrix@@CAP6AXAEBV1@QEAUSkPoint@@QEBU2@H@ZW4TypeMask@1@@Z";

    getMapPtsProc :: (this: *SkMatrix) -> MapPtsProc #cpp_method #foreign libskia "?getMapPtsProc@SkMatrix@@AEBAP6AXAEBV1@QEAUSkPoint@@QEBU2@H@ZXZ";

    Poly2Proc :: (unknown0: *SkPoint, unknown1: *SkMatrix) -> bool #foreign libskia "?Poly2Proc@SkMatrix@@CA_NQEBUSkPoint@@PEAV1@@Z";
    Poly3Proc :: (unknown0: *SkPoint, unknown1: *SkMatrix) -> bool #foreign libskia "?Poly3Proc@SkMatrix@@CA_NQEBUSkPoint@@PEAV1@@Z";
    Poly4Proc :: (unknown0: *SkPoint, unknown1: *SkMatrix) -> bool #foreign libskia "?Poly4Proc@SkMatrix@@CA_NQEBUSkPoint@@PEAV1@@Z";

    Identity_pts :: (unknown0: *SkMatrix, unknown1: *SkPoint, unknown2: *SkPoint, unknown3: s32) -> void #foreign libskia "?Identity_pts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    Identity_pts :: (unknown0: SkMatrix, unknown1: *SkPoint, unknown2: *SkPoint, unknown3: s32) #no_context {
        Identity_pts(*unknown0, unknown1, unknown2, unknown3);
    }
    Trans_pts :: (unknown0: *SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) -> void #foreign libskia "?Trans_pts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    Trans_pts :: (unknown0: SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) #no_context {
        Trans_pts(*unknown0, dst, unknown1, unknown2);
    }
    Scale_pts :: (unknown0: *SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) -> void #foreign libskia "?Scale_pts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    Scale_pts :: (unknown0: SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) #no_context {
        Scale_pts(*unknown0, dst, unknown1, unknown2);
    }
//     ScaleTrans_pts :: (unknown0: *SkMatrix, dst: *SkPoint, unknown1: *SkPoint, count: s32) -> void #foreign libskia "?ScaleTrans_pts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    ScaleTrans_pts :: (unknown0: SkMatrix, dst: *SkPoint, unknown1: *SkPoint, count: s32) #no_context {
        ScaleTrans_pts(*unknown0, dst, unknown1, count);
    }

    Persp_pts :: (unknown0: *SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) -> void #foreign libskia "?Persp_pts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    Persp_pts :: (unknown0: SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) #no_context {
        Persp_pts(*unknown0, dst, unknown1, unknown2);
    }

    Affine_vpts :: (unknown0: *SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) -> void #foreign libskia "?Affine_vpts@SkMatrix@@CAXAEBV1@QEAUSkPoint@@QEBU2@H@Z";
    Affine_vpts :: (unknown0: SkMatrix, dst: *SkPoint, unknown1: *SkPoint, unknown2: s32) #no_context {
        Affine_vpts(*unknown0, dst, unknown1, unknown2);
    }

    // return the number of bytes written, whether or not buffer is null
    writeToMemory :: (this: *SkMatrix, buffer: *void) -> u64 #cpp_method #foreign libskia "?writeToMemory@SkMatrix@@AEBA_KPEAX@Z";

    /**
    * Reads data from the buffer parameter
    *
    * @param buffer Memory to read from
    * @param length Amount of memory available in the buffer
    * @return number of bytes read (must be a multiple of 4) or
    *         0 if there was not enough memory available
    */
    readFromMemory :: (this: *SkMatrix, buffer: *void, length: u64) -> u64 #cpp_method #foreign libskia "?readFromMemory@SkMatrix@@AEAA_KPEBX_K@Z";

    // legacy method -- still needed? why not just postScale(1/divx, ...)?
    postIDiv :: (this: *SkMatrix, divx: s32, divy: s32) -> bool #cpp_method #foreign libskia "?postIDiv@SkMatrix@@AEAA_NHH@Z";
    doNormalizePerspective :: (this: *SkMatrix) -> void #cpp_method #foreign libskia "?doNormalizePerspective@SkMatrix@@AEAAXXZ";
}

/** Returns one matrix value. Asserts if index is out of range and SK_DEBUG is
defined.

@param index  one of: kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY,
kMPersp0, kMPersp1, kMPersp2
@return       value corresponding to index
*/
operator_subscript :: (this: /*const*/ *SkMatrix, index: s32) -> SkScalar #cpp_method #foreign libskia "??ASkMatrix@@QEBAMH@Z";
operator_subscript :: (this: SkMatrix, index: s32) -> SkScalar #no_context {
    return operator_subscript(*this, index);
}

/** Returns writable SkMatrix value. Asserts if index is out of range and SK_DEBUG is
defined. Clears internal cache anticipating that caller will change SkMatrix value.

Next call to read SkMatrix state may recompute cache; subsequent writes to SkMatrix
value must be followed by dirtyMatrixTypeCache().

@param index  one of: kMScaleX, kMSkewX, kMTransX, kMSkewY, kMScaleY, kMTransY,
kMPersp0, kMPersp1, kMPersp2
@return       writable value corresponding to index
*/
operator_brackets_1 :: (this: *SkMatrix, index: s32) -> *SkScalar #cpp_method #foreign libskia "??ASkMatrix@@QEAAAEAMH@Z";
operator_brackets_1 :: (this: SkMatrix, index: s32) -> *SkScalar #no_context {
    return operator_brackets_1(*this, index);
}

SkV2 :: struct {
    x: float;
    y: float;

    Dot :: (a: SkV2, b: SkV2) -> SkScalar #foreign libskia "?Dot@SkV2@@SAMU1@0@Z";
    Cross :: (a: SkV2, b: SkV2) -> SkScalar #foreign libskia "?Cross@SkV2@@SAMU1@0@Z";
    Normalize :: (v: SkV2) -> SkV2 #foreign libskia "?Normalize@SkV2@@SA?AU1@U1@@Z";

    lengthSquared :: (this: *SkV2) -> SkScalar #cpp_method #foreign libskia "?lengthSquared@SkV2@@QEBAMXZ";
    length :: (this: *SkV2) -> SkScalar #cpp_method #foreign libskia "?length@SkV2@@QEBAMXZ";

    dot :: (this: *SkV2, v: SkV2) -> SkScalar #cpp_method #foreign libskia "?dot@SkV2@@QEBAMU1@@Z";
    cross :: (this: *SkV2, v: SkV2) -> SkScalar #cpp_method #foreign libskia "?cross@SkV2@@QEBAMU1@@Z";
    normalize :: (this: *SkV2) -> SkV2 #cpp_method #foreign libskia "?normalize@SkV2@@QEBA?AU1@XZ";

    ptr :: (this: /*const*/ *SkV2) -> *float #cpp_method #foreign libskia "?ptr@SkV2@@QEBAPEBMXZ";
    ptr_1 :: (this: *SkV2) -> *float #cpp_method #foreign libskia "?ptr@SkV2@@QEAAPEAMXZ";
}

operator_eq :: (this: *SkV2, v: SkV2) -> bool #cpp_method #foreign libskia "??8SkV2@@QEBA_NU0@@Z";
operator_eq :: (this: SkV2, v: SkV2) -> bool #no_context {
    return operator_eq(*this, v);
}
operator_neq :: (this: *SkV2, v: SkV2) -> bool #cpp_method #foreign libskia "??9SkV2@@QEBA_NU0@@Z";
operator_neq :: (this: SkV2, v: SkV2) -> bool #no_context {
    return operator_neq(*this, v);
}

operator_minus :: (this: *SkV2) -> SkV2 #cpp_method #foreign libskia "??GSkV2@@QEBA?AU0@XZ";
operator_minus :: (this: SkV2) -> SkV2 #no_context {
    return operator_minus(*this);
}
operator_plus :: (this: *SkV2, v: SkV2) -> SkV2 #cpp_method #foreign libskia "??HSkV2@@QEBA?AU0@U0@@Z";
operator_plus :: (this: SkV2, v: SkV2) -> SkV2 #no_context {
    return operator_plus(*this, v);
}
operator_minus :: (this: *SkV2, v: SkV2) -> SkV2 #cpp_method #foreign libskia "??GSkV2@@QEBA?AU0@U0@@Z";
operator_minus :: (this: SkV2, v: SkV2) -> SkV2 #no_context {
    return operator_minus(*this, v);
}

operator_mul :: (this: *SkV2, v: SkV2) -> SkV2 #cpp_method #foreign libskia "??DSkV2@@QEBA?AU0@U0@@Z";
operator_mul :: (this: SkV2, v: SkV2) -> SkV2 #no_context {
    return operator_mul(*this, v);
}

operator_plus_equals :: (this: *SkV2, v: SkV2) -> void #cpp_method #foreign libskia "??YSkV2@@QEAAXU0@@Z";
operator_minus_equals :: (this: *SkV2, v: SkV2) -> void #cpp_method #foreign libskia "??ZSkV2@@QEAAXU0@@Z";
operator_mul_equals :: (this: *SkV2, v: SkV2) -> void #cpp_method #foreign libskia "??XSkV2@@QEAAXU0@@Z";
operator_mul_equals :: (this: *SkV2, s: SkScalar) -> void #cpp_method #foreign libskia "??XSkV2@@QEAAXM@Z";
operator_div_equals :: (this: *SkV2, s: SkScalar) -> void #cpp_method #foreign libskia "??_0SkV2@@QEAAXM@Z";

SkV3 :: struct {
    x: float;
    y: float;
    z: float;

    Dot :: (a: *SkV3, b: *SkV3) -> SkScalar #foreign libskia "?Dot@SkV3@@SAMAEBU1@0@Z";
    Dot :: (a: SkV3, b: SkV3) -> SkScalar #no_context {
        return Dot(*a, *b);
    }
    Cross :: (a: *SkV3, b: *SkV3) -> SkV3 #foreign libskia "?Cross@SkV3@@SA?AU1@AEBU1@0@Z";
    Cross :: (a: SkV3, b: SkV3) -> SkV3 #no_context {
        return Cross(*a, *b);
    }

    Normalize :: (v: *SkV3) -> SkV3 #foreign libskia "?Normalize@SkV3@@SA?AU1@AEBU1@@Z";
    Normalize :: (v: SkV3) -> SkV3 #no_context {
        return Normalize(*v);
    }

    lengthSquared :: (this: *SkV3) -> SkScalar #cpp_method #foreign libskia "?lengthSquared@SkV3@@QEBAMXZ";
    length :: (this: *SkV3) -> SkScalar #cpp_method #foreign libskia "?length@SkV3@@QEBAMXZ";

    dot :: (this: *SkV3, v: *SkV3) -> SkScalar #cpp_method #foreign libskia "?dot@SkV3@@QEBAMAEBU1@@Z";
    dot :: (this: *SkV3, v: SkV3) -> SkScalar #no_context {
        return dot(this, *v);
    }
    cross :: (this: *SkV3, v: *SkV3) -> SkV3 #cpp_method #foreign libskia "?cross@SkV3@@QEBA?AU1@AEBU1@@Z";
    cross :: (this: *SkV3, v: SkV3) -> SkV3 #no_context {
        return cross(this, *v);
    }
    normalize :: (this: *SkV3) -> SkV3 #cpp_method #foreign libskia "?normalize@SkV3@@QEBA?AU1@XZ";

    ptr :: (this: /*const*/ *SkV3) -> *float #cpp_method #foreign libskia "?ptr@SkV3@@QEBAPEBMXZ";
    ptr_1 :: (this: *SkV3) -> *float #cpp_method #foreign libskia "?ptr@SkV3@@QEAAPEAMXZ";
}

operator_eq :: (this: *SkV3, v: *SkV3) -> bool #cpp_method #foreign libskia "??8SkV3@@QEBA_NAEBU0@@Z";
operator_eq :: (this: SkV3, v: SkV3) -> bool #no_context {
    return operator_eq(*this, *v);
}

operator_neq :: (this: *SkV3, v: *SkV3) -> bool #cpp_method #foreign libskia "??9SkV3@@QEBA_NAEBU0@@Z";
operator_neq :: (this: SkV3, v: SkV3) -> bool #no_context {
    return operator_neq(*this, *v);
}

operator_minus :: (this: *SkV3) -> SkV3 #cpp_method #foreign libskia "??GSkV3@@QEBA?AU0@XZ";
operator_minus :: (this: SkV3) -> SkV3 #no_context {
    return operator_minus(*this);
}
operator_plus :: (this: *SkV3, v: *SkV3) -> SkV3 #cpp_method #foreign libskia "??HSkV3@@QEBA?AU0@AEBU0@@Z";
operator_plus :: (this: SkV3, v: SkV3) -> SkV3 #no_context {
    return operator_plus(*this, *v);
}
operator_minus :: (this: *SkV3, v: *SkV3) -> SkV3 #cpp_method #foreign libskia "??GSkV3@@QEBA?AU0@AEBU0@@Z";
operator_minus :: (this: SkV3, v: SkV3) -> SkV3 #no_context {
    return operator_minus(*this, *v);
}

operator_mul :: (this: *SkV3, v: *SkV3) -> SkV3 #cpp_method #foreign libskia "??DSkV3@@QEBA?AU0@AEBU0@@Z";
operator_mul :: (this: SkV3, v: SkV3) -> SkV3 #no_context {
    return operator_mul(*this, *v);
}

operator_plus_equals :: (this: *SkV3, v: SkV3) -> void #cpp_method #foreign libskia "??YSkV3@@QEAAXU0@@Z";
operator_minus_equals :: (this: *SkV3, v: SkV3) -> void #cpp_method #foreign libskia "??ZSkV3@@QEAAXU0@@Z";
operator_mul_equals :: (this: *SkV3, v: SkV3) -> void #cpp_method #foreign libskia "??XSkV3@@QEAAXU0@@Z";
operator_mul_equals :: (this: *SkV3, s: SkScalar) -> void #cpp_method #foreign libskia "??XSkV3@@QEAAXM@Z";

SkV4 :: struct {
    x: float;
    y: float;
    z: float;
    w: float;

    Dot :: (a: *SkV4, b: *SkV4) -> SkScalar #foreign libskia "?Dot@SkV4@@SAMAEBU1@0@Z";
    Dot :: (a: SkV4, b: SkV4) -> SkScalar #no_context {
        return Dot(*a, *b);
    }

    Normalize :: (v: *SkV4) -> SkV4 #foreign libskia "?Normalize@SkV4@@SA?AU1@AEBU1@@Z";
    Normalize :: (v: SkV4) -> SkV4 #no_context {
        return Normalize(*v);
    }

    lengthSquared :: (this: *SkV4) -> SkScalar #cpp_method #foreign libskia "?lengthSquared@SkV4@@QEBAMXZ";
    length :: (this: *SkV4) -> SkScalar #cpp_method #foreign libskia "?length@SkV4@@QEBAMXZ";

    dot :: (this: *SkV4, v: *SkV4) -> SkScalar #cpp_method #foreign libskia "?dot@SkV4@@QEBAMAEBU1@@Z";
    dot :: (this: *SkV4, v: SkV4) -> SkScalar #no_context {
        return dot(this, *v);
    }
    normalize :: (this: *SkV4) -> SkV4 #cpp_method #foreign libskia "?normalize@SkV4@@QEBA?AU1@XZ";

    ptr :: (this: /*const*/ *SkV4) -> *float #cpp_method #foreign libskia "?ptr@SkV4@@QEBAPEBMXZ";
    ptr_1 :: (this: *SkV4) -> *float #cpp_method #foreign libskia "?ptr@SkV4@@QEAAPEAMXZ";
}

operator_eq :: (this: *SkV4, v: *SkV4) -> bool #cpp_method #foreign libskia "??8SkV4@@QEBA_NAEBU0@@Z";
operator_eq :: (this: SkV4, v: SkV4) -> bool #no_context {
    return operator_eq(*this, *v);
}

operator_neq :: (this: *SkV4, v: *SkV4) -> bool #cpp_method #foreign libskia "??9SkV4@@QEBA_NAEBU0@@Z";
operator_neq :: (this: SkV4, v: SkV4) -> bool #no_context {
    return operator_neq(*this, *v);
}

operator_minus :: (this: *SkV4) -> SkV4 #cpp_method #foreign libskia "??GSkV4@@QEBA?AU0@XZ";
operator_minus :: (this: SkV4) -> SkV4 #no_context {
    return operator_minus(*this);
}
operator_plus :: (this: *SkV4, v: *SkV4) -> SkV4 #cpp_method #foreign libskia "??HSkV4@@QEBA?AU0@AEBU0@@Z";
operator_plus :: (this: SkV4, v: SkV4) -> SkV4 #no_context {
    return operator_plus(*this, *v);
}
operator_minus :: (this: *SkV4, v: *SkV4) -> SkV4 #cpp_method #foreign libskia "??GSkV4@@QEBA?AU0@AEBU0@@Z";
operator_minus :: (this: SkV4, v: SkV4) -> SkV4 #no_context {
    return operator_minus(*this, *v);
}

operator_mul :: (this: *SkV4, v: *SkV4) -> SkV4 #cpp_method #foreign libskia "??DSkV4@@QEBA?AU0@AEBU0@@Z";
operator_mul :: (this: SkV4, v: SkV4) -> SkV4 #no_context {
    return operator_mul(*this, *v);
}

operator_subscript :: (this: /*const*/ *SkV4, i: s32) -> float #cpp_method #foreign libskia "??ASkV4@@QEBAMH@Z";
operator_subscript :: (this: SkV4, i: s32) -> float #no_context {
    return operator_subscript(*this, i);
}

operator_brackets_1 :: (this: *SkV4, i: s32) -> *float #cpp_method #foreign libskia "??ASkV4@@QEAAAEAMH@Z";
operator_brackets_1 :: (this: SkV4, i: s32) -> *float #no_context {
    return operator_brackets_1(*this, i);
}

/**
*  4x4 matrix used by SkCanvas and other parts of Skia.
*
*  Skia assumes a right-handed coordinate system:
*      +X goes to the right
*      +Y goes down
*      +Z goes into the screen (away from the viewer)
*/
SkM44 :: struct {
//     CopyConstructor :: (this: *SkM44, src: *SkM44) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkM44, src: SkM44) #no_context {
        CopyConstructor(this, *src);
    }

    Constructor :: (this: *SkM44) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@XZ";

    Constructor :: (this: *SkM44, a: *SkM44, b: *SkM44) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@AEBV0@0@Z";
    Constructor :: (this: *SkM44, a: SkM44, b: SkM44) #no_context {
        Constructor(this, *a, *b);
    }

    Uninitialized_Constructor :: enum s32 {
        kUninitialized_Constructor :: 0;
    }

    Constructor :: (this: *SkM44, unknown0: Uninitialized_Constructor) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@W4Uninitialized_Constructor@0@@Z";

    NaN_Constructor :: enum s32 {
        kNaN_Constructor :: 0;
    }

    Constructor :: (this: *SkM44, unknown0: NaN_Constructor) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@W4NaN_Constructor@0@@Z";

    /**
    *  The constructor parameters are in row-major order.
    */
    Constructor :: (this: *SkM44, m0: SkScalar, m4: SkScalar, m8: SkScalar, m12: SkScalar, m1: SkScalar, m5: SkScalar, m9: SkScalar, m13: SkScalar, m2: SkScalar, m6: SkScalar, m10: SkScalar, m14: SkScalar, m3: SkScalar, m7: SkScalar, m11: SkScalar, m15: SkScalar) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@MMMMMMMMMMMMMMMM@Z";

    Rows :: (r0: *SkV4, r1: *SkV4, r2: *SkV4, r3: *SkV4) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Rows@SkM44@@SA?AV1@AEBUSkV4@@000@Z";
    Rows :: (r0: SkV4, r1: SkV4, r2: SkV4, r3: SkV4) -> SkM44 #no_context {
        return Rows(*r0, *r1, *r2, *r3);
    }

    Cols :: (c0: *SkV4, c1: *SkV4, c2: *SkV4, c3: *SkV4) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Cols@SkM44@@SA?AV1@AEBUSkV4@@000@Z";
    Cols :: (c0: SkV4, c1: SkV4, c2: SkV4, c3: SkV4) -> SkM44 #no_context {
        return Cols(*c0, *c1, *c2, *c3);
    }

    RowMajor :: (r: *[16] SkScalar) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?RowMajor@SkM44@@SA?AV1@QEBM@Z";

    ColMajor :: (c: *[16] SkScalar) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?ColMajor@SkM44@@SA?AV1@QEBM@Z";

    Translate :: (x: SkScalar, y: SkScalar, z: SkScalar = 0) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Translate@SkM44@@SA?AV1@MMM@Z";

    Scale :: (x: SkScalar, y: SkScalar, z: SkScalar = 1) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Scale@SkM44@@SA?AV1@MMM@Z";

    Rotate :: (axis: SkV3, radians: SkScalar) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Rotate@SkM44@@SA?AV1@USkV3@@M@Z";

    // Scales and translates 'src' to fill 'dst' exactly.
    RectToRect :: (src: *SkRect, dst: *SkRect) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?RectToRect@SkM44@@SA?AV1@AEBUSkRect@@0@Z";
    RectToRect :: (src: SkRect, dst: SkRect) -> SkM44 #no_context {
        return RectToRect(*src, *dst);
    }

    LookAt :: (eye: *SkV3, center: *SkV3, up: *SkV3) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?LookAt@SkM44@@SA?AV1@AEBUSkV3@@00@Z";
    LookAt :: (eye: SkV3, center: SkV3, up: SkV3) -> SkM44 #no_context {
        return LookAt(*eye, *center, *up);
    }
    Perspective :: (near: float, far: float, angle: float) -> SkM44 #cpp_return_type_is_non_pod #foreign libskia "?Perspective@SkM44@@SA?AV1@MMM@Z";

    getColMajor :: (this: *SkM44, v: *SkScalar) -> void #cpp_method #foreign libskia "?getColMajor@SkM44@@QEBAXQEAM@Z";

    getRowMajor :: (this: *SkM44, v: *SkScalar) -> void #cpp_method #foreign libskia "?getRowMajor@SkM44@@QEBAXQEAM@Z";

    rc :: (this: *SkM44, r: s32, c: s32) -> SkScalar #cpp_method #foreign libskia "?rc@SkM44@@QEBAMHH@Z";

    setRC :: (this: *SkM44, r: s32, c: s32, value: SkScalar) -> void #cpp_method #foreign libskia "?setRC@SkM44@@QEAAXHHM@Z";

    row :: (this: *SkM44, i: s32) -> SkV4 #cpp_method #foreign libskia "?row@SkM44@@QEBA?AUSkV4@@H@Z";

    col :: (this: *SkM44, i: s32) -> SkV4 #cpp_method #foreign libskia "?col@SkM44@@QEBA?AUSkV4@@H@Z";

    setRow :: (this: *SkM44, i: s32, v: *SkV4) -> void #cpp_method #foreign libskia "?setRow@SkM44@@QEAAXHAEBUSkV4@@@Z";
    setRow :: (this: *SkM44, i: s32, v: SkV4) #no_context {
        setRow(this, i, *v);
    }

    setCol :: (this: *SkM44, i: s32, v: *SkV4) -> void #cpp_method #foreign libskia "?setCol@SkM44@@QEAAXHAEBUSkV4@@@Z";
    setCol :: (this: *SkM44, i: s32, v: SkV4) #no_context {
        setCol(this, i, *v);
    }

    setIdentity :: (this: *SkM44) -> *SkM44 #cpp_method #foreign libskia "?setIdentity@SkM44@@QEAAAEAV1@XZ";

    setTranslate :: (this: *SkM44, x: SkScalar, y: SkScalar, z: SkScalar = 0) -> *SkM44 #cpp_method #foreign libskia "?setTranslate@SkM44@@QEAAAEAV1@MMM@Z";

    setScale :: (this: *SkM44, x: SkScalar, y: SkScalar, z: SkScalar = 1) -> *SkM44 #cpp_method #foreign libskia "?setScale@SkM44@@QEAAAEAV1@MMM@Z";

    /**
    *  Set this matrix to rotate about the specified unit-length axis vector,
    *  by an angle specified by its sin() and cos().
    *
    *  This does not attempt to verify that axis.length() == 1 or that the sin,cos values
    *  are correct.
    */
    setRotateUnitSinCos :: (this: *SkM44, axis: SkV3, sinAngle: SkScalar, cosAngle: SkScalar) -> *SkM44 #cpp_method #foreign libskia "?setRotateUnitSinCos@SkM44@@QEAAAEAV1@USkV3@@MM@Z";

    /**
    *  Set this matrix to rotate about the specified unit-length axis vector,
    *  by an angle specified in radians.
    *
    *  This does not attempt to verify that axis.length() == 1.
    */
    setRotateUnit :: (this: *SkM44, axis: SkV3, radians: SkScalar) -> *SkM44 #cpp_method #foreign libskia "?setRotateUnit@SkM44@@QEAAAEAV1@USkV3@@M@Z";

    /**
    *  Set this matrix to rotate about the specified axis vector,
    *  by an angle specified in radians.
    *
    *  Note: axis is not assumed to be unit-length, so it will be normalized internally.
    *        If axis is already unit-length, call setRotateAboutUnitRadians() instead.
    */
    setRotate :: (this: *SkM44, axis: SkV3, radians: SkScalar) -> *SkM44 #cpp_method #foreign libskia "?setRotate@SkM44@@QEAAAEAV1@USkV3@@M@Z";

    setConcat :: (this: *SkM44, a: *SkM44, b: *SkM44) -> *SkM44 #cpp_method #foreign libskia "?setConcat@SkM44@@QEAAAEAV1@AEBV1@0@Z";
    setConcat :: (this: *SkM44, a: SkM44, b: SkM44) -> *SkM44 #no_context {
        return setConcat(this, *a, *b);
    }

    preConcat :: (this: *SkM44, m: *SkM44) -> *SkM44 #cpp_method #foreign libskia "?preConcat@SkM44@@QEAAAEAV1@AEBV1@@Z";
    preConcat :: (this: *SkM44, m: SkM44) -> *SkM44 #no_context {
        return preConcat(this, *m);
    }

    postConcat :: (this: *SkM44, m: *SkM44) -> *SkM44 #cpp_method #foreign libskia "?postConcat@SkM44@@QEAAAEAV1@AEBV1@@Z";
    postConcat :: (this: *SkM44, m: SkM44) -> *SkM44 #no_context {
        return postConcat(this, *m);
    }

    /**
    *  A matrix is categorized as 'perspective' if the bottom row is not [0, 0, 0, 1].
    *  For most uses, a bottom row of [0, 0, 0, X] behaves like a non-perspective matrix, though
    *  it will be categorized as perspective. Calling normalizePerspective() will change the
    *  matrix such that, if its bottom row was [0, 0, 0, X], it will be changed to [0, 0, 0, 1]
    *  by scaling the rest of the matrix by 1/X.
    *
    *  | A B C D |    | A/X B/X C/X D/X |
    *  | E F G H | -> | E/X F/X G/X H/X |   for X != 0
    *  | I J K L |    | I/X J/X K/X L/X |
    *  | 0 0 0 X |    |  0   0   0   1  |
    */
    normalizePerspective :: (this: *SkM44) -> void #cpp_method #foreign libskia "?normalizePerspective@SkM44@@QEAAXXZ";

    /** Returns true if all elements of the matrix are finite. Returns false if any
    element is infinity, or NaN.
    
    @return  true if matrix has only finite elements
    */
    isFinite :: (this: *SkM44) -> bool #cpp_method #foreign libskia "?isFinite@SkM44@@QEBA_NXZ";

    /** If this is invertible, return that in inverse and return true. If it is
    *  not invertible, return false and leave the inverse parameter unchanged.
    */
    invert :: (this: *SkM44, inverse: *SkM44) -> bool #cpp_method #foreign libskia "?invert@SkM44@@QEBA_NPEAV1@@Z";

    transpose :: (this: *SkM44) -> SkM44 #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?transpose@SkM44@@QEBA?AV1@XZ";

    dump :: (this: *SkM44) -> void #cpp_method #foreign libskia "?dump@SkM44@@QEBAXXZ";

    ////////////
    map :: (this: *SkM44, x: float, y: float, z: float, w: float) -> SkV4 #cpp_method #foreign libskia "?map@SkM44@@QEBA?AUSkV4@@MMMM@Z";

    /* When converting from SkM44 to SkMatrix, the third row and
    * column is dropped.  When converting from SkMatrix to SkM44
    * the third row and column remain as identity:
    * [ a b c ]      [ a b 0 c ]
    * [ d e f ]  ->  [ d e 0 f ]
    * [ g h i ]      [ 0 0 1 0 ]
    *                [ g h 0 i ]
    */
    asM33 :: (this: *SkM44) -> SkMatrix #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?asM33@SkM44@@QEBA?AVSkMatrix@@XZ";

    Constructor :: (this: *SkM44, src: *SkMatrix) -> void #cpp_method #foreign libskia "??0SkM44@@QEAA@AEBVSkMatrix@@@Z";
    Constructor :: (this: *SkM44, src: SkMatrix) #no_context {
        Constructor(this, *src);
    }

    preTranslate :: (this: *SkM44, x: SkScalar, y: SkScalar, z: SkScalar = 0) -> *SkM44 #cpp_method #foreign libskia "?preTranslate@SkM44@@QEAAAEAV1@MMM@Z";
    postTranslate :: (this: *SkM44, x: SkScalar, y: SkScalar, z: SkScalar = 0) -> *SkM44 #cpp_method #foreign libskia "?postTranslate@SkM44@@QEAAAEAV1@MMM@Z";

    preScale :: (this: *SkM44, x: SkScalar, y: SkScalar) -> *SkM44 #cpp_method #foreign libskia "?preScale@SkM44@@QEAAAEAV1@MM@Z";
    preScale :: (this: *SkM44, x: SkScalar, y: SkScalar, z: SkScalar) -> *SkM44 #cpp_method #foreign libskia "?preScale@SkM44@@QEAAAEAV1@MMM@Z";
    preConcat :: (this: *SkM44, unknown0: *SkMatrix) -> *SkM44 #cpp_method #foreign libskia "?preConcat@SkM44@@QEAAAEAV1@AEBVSkMatrix@@@Z";
    preConcat :: (this: *SkM44, unknown0: SkMatrix) -> *SkM44 #no_context {
        return preConcat(this, *unknown0);
    }

    /* Stored in column-major.
    *  Indices
    *  0  4  8  12        1 0 0 trans_x
    *  1  5  9  13  e.g.  0 1 0 trans_y
    *  2  6 10  14        0 0 1 trans_z
    *  3  7 11  15        0 0 0 1
    */
    fMat: [16] SkScalar;
}

operator_assign :: (this: *SkM44, src: *SkM44) -> *SkM44 #cpp_method #foreign libskia "??4SkM44@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkM44, src: SkM44) -> *SkM44 #no_context {
    return operator_assign(this, *src);
}

operator_eq :: (this: *SkM44, other: *SkM44) -> bool #cpp_method #foreign libskia "??8SkM44@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkM44, other: SkM44) -> bool #no_context {
    return operator_eq(*this, *other);
}
operator_neq :: (this: *SkM44, other: *SkM44) -> bool #cpp_method #foreign libskia "??9SkM44@@QEBA_NAEBV0@@Z";
operator_neq :: (this: SkM44, other: SkM44) -> bool #no_context {
    return operator_neq(*this, *other);
}

operator_mul :: (this: *SkM44, v: *SkV4) -> SkV4 #cpp_method #foreign libskia "??DSkM44@@QEBA?AUSkV4@@AEBU1@@Z";
operator_mul :: (this: SkM44, v: SkV4) -> SkV4 #no_context {
    return operator_mul(*this, *v);
}

operator_mul :: (this: *SkM44, v: SkV3) -> SkV3 #cpp_method #foreign libskia "??DSkM44@@QEBA?AUSkV3@@U1@@Z";
operator_mul :: (this: SkM44, v: SkV3) -> SkV3 #no_context {
    return operator_mul(*this, v);
}

// Trait for identifying types which are relocatable via memcpy, for container optimizations.
sk_has_trivially_relocatable_member :: struct(T: Type, _1: Type) {
    using,except(_1) sk_has_trivially_relocatable_member__raw: sk_has_trivially_relocatable_member__RAW(T, _1);
    #if size_of(sk_has_trivially_relocatable_member__RAW(T, _1)) == 0 {
        __empty_struct_padding:                   u8; // C++ makes empty structs have length 1
    }
    #place integral_constant__raw; #as false_type: std.false_type; // Support cast to false_type
}
// sk_has_trivially_relocatable_member without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from sk_has_trivially_relocatable_member
sk_has_trivially_relocatable_member__RAW :: struct(T: Type, _1: Type) {
    using integral_constant__raw: std.integral_constant__RAW;
}

// By default, all trivially copyable types are trivially relocatable.
sk_is_trivially_relocatable :: struct(T: Type) {
    using,except(T) sk_is_trivially_relocatable__raw: sk_is_trivially_relocatable__RAW(T);
    #if size_of(sk_is_trivially_relocatable__RAW(T)) == 0 {
        __empty_struct_padding:           u8; // C++ makes empty structs have length 1
    }
    #place disjunction__raw; #as disjunction: std.disjunction(std.is_trivially_copyable(T), sk_has_trivially_relocatable_member(T)); // Support cast to disjunction
}
// sk_is_trivially_relocatable without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from sk_is_trivially_relocatable
sk_is_trivially_relocatable__RAW :: struct(T: Type) {
    using disjunction__raw: std.disjunction__RAW(std.is_trivially_copyable(T), sk_has_trivially_relocatable_member(T));
}

SkBlender :: struct {}

SkMaskFilter :: struct {}
SkPathEffect :: struct {}
SkShader :: struct {}

/** \class SkPaint
SkPaint controls options applied when drawing. SkPaint collects all
options outside of the SkCanvas clip and SkCanvas matrix.

Various options apply to strokes and fills, and images.

SkPaint collects effects and filters that describe single-pass and multiple-pass
algorithms that alter the drawing geometry, color, and transparency. For instance,
SkPaint does not directly implement dashing or blur, but contains the objects that do so.
*/
SkPaint :: struct {
    /** Constructs SkPaint with default values.
    
    @return  default initialized SkPaint
    
    example: https://fiddle.skia.org/c/@Paint_empty_constructor
    */
    Constructor :: (this: *SkPaint) -> void #cpp_method #foreign libskia "??0SkPaint@@QEAA@XZ";

    /** Constructs SkPaint with default values and the given color.
    
    Sets alpha and RGB used when stroking and filling. The color is four floating
    point values, unpremultiplied. The color values are interpreted as being in
    the colorSpace. If colorSpace is nullptr, then color is assumed to be in the
    sRGB color space.
    
    @param color       unpremultiplied RGBA
    @param colorSpace  SkColorSpace describing the encoding of color
    @return            SkPaint with the given color
    */
    Constructor :: (this: *SkPaint, color: *SkColor4f, colorSpace: *SkColorSpace = null) -> void #cpp_method #foreign libskia "??0SkPaint@@QEAA@AEBU?$SkRGBA4f@$02@@PEAVSkColorSpace@@@Z";
    Constructor :: (this: *SkPaint, color: SkColor4f, colorSpace: *SkColorSpace = null) #no_context {
        Constructor(this, *color, colorSpace);
    }

    /** Makes a shallow copy of SkPaint. SkPathEffect, SkShader,
    SkMaskFilter, SkColorFilter, and SkImageFilter are shared
    between the original paint and the copy. Objects containing SkRefCnt increment
    their references by one.
    
    The referenced objects SkPathEffect, SkShader, SkMaskFilter, SkColorFilter,
    and SkImageFilter cannot be modified after they are created.
    This prevents objects with SkRefCnt from being modified once SkPaint refers to them.
    
    @param paint  original to copy
    @return       shallow copy of paint
    
    example: https://fiddle.skia.org/c/@Paint_copy_const_SkPaint
    */
    CopyConstructor :: (this: *SkPaint, paint: *SkPaint) -> void #cpp_method #foreign libskia "??0SkPaint@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkPaint, paint: SkPaint) #no_context {
        CopyConstructor(this, *paint);
    }

    /** Decreases SkPaint SkRefCnt of owned objects: SkPathEffect, SkShader,
    SkMaskFilter, SkColorFilter, and SkImageFilter. If the
    objects containing SkRefCnt go to zero, they are deleted.
    */
    Destructor :: (this: *SkPaint) -> void #cpp_method #foreign libskia "??1SkPaint@@QEAA@XZ";

    /** Sets all SkPaint contents to their initial values. This is equivalent to replacing
    SkPaint with the result of SkPaint().
    
    example: https://fiddle.skia.org/c/@Paint_reset
    */
    reset :: (this: *SkPaint) -> void #cpp_method #foreign libskia "?reset@SkPaint@@QEAAXXZ";

    /** Returns true if pixels on the active edges of SkPath may be drawn with partial transparency.
    @return  antialiasing state
    */
    isAntiAlias :: (this: *SkPaint) -> bool #cpp_method #foreign libskia "?isAntiAlias@SkPaint@@QEBA_NXZ";

    /** Requests, but does not require, that edge pixels draw opaque or with
    partial transparency.
    @param aa  setting for antialiasing
    */
    setAntiAlias :: (this: *SkPaint, aa: bool) -> void #cpp_method #foreign libskia "?setAntiAlias@SkPaint@@QEAAX_N@Z";

    /** Returns true if color error may be distributed to smooth color transition.
    @return  dithering state
    */
    isDither :: (this: *SkPaint) -> bool #cpp_method #foreign libskia "?isDither@SkPaint@@QEBA_NXZ";

    /** Requests, but does not require, to distribute color error.
    @param dither  setting for dithering
    */
    setDither :: (this: *SkPaint, dither: bool) -> void #cpp_method #foreign libskia "?setDither@SkPaint@@QEAAX_N@Z";

    /** \enum SkPaint::Style
    Set Style to fill, stroke, or both fill and stroke geometry.
    The stroke and fill
    share all paint attributes; for instance, they are drawn with the same color.
    
    Use kStrokeAndFill_Style to avoid hitting the same pixels twice with a stroke draw and
    a fill draw.
    */
    Style :: enum u8 {
        Fill_Style          :: 0;
        Stroke_Style        :: 1;
        StrokeAndFill_Style :: 2;

        kFill_Style          :: Fill_Style;
        kStroke_Style        :: Stroke_Style;
        kStrokeAndFill_Style :: StrokeAndFill_Style;
    }

    /** May be used to verify that SkPaint::Style is a legal value.
    */
    kStyleCount:                 s32 : cast(s32) (Style.StrokeAndFill_Style + 1);

    /** Returns whether the geometry is filled, stroked, or filled and stroked.
    */
    getStyle :: (this: *SkPaint) -> Style #cpp_method #foreign libskia "?getStyle@SkPaint@@QEBA?AW4Style@1@XZ";

    /** Sets whether the geometry is filled, stroked, or filled and stroked.
    Has no effect if style is not a legal SkPaint::Style value.
    
    example: https://fiddle.skia.org/c/@Paint_setStyle
    example: https://fiddle.skia.org/c/@Stroke_Width
    */
    setStyle :: (this: *SkPaint, style: Style) -> void #cpp_method #foreign libskia "?setStyle@SkPaint@@QEAAXW4Style@1@@Z";

    /**
    *  Set paint's style to kStroke if true, or kFill if false.
    */
    setStroke :: (this: *SkPaint, unknown0: bool) -> void #cpp_method #foreign libskia "?setStroke@SkPaint@@QEAAX_N@Z";

    /** Retrieves alpha and RGB, unpremultiplied, packed into 32 bits.
    Use helpers SkColorGetA(), SkColorGetR(), SkColorGetG(), and SkColorGetB() to extract
    a color component.
    
    @return  unpremultiplied ARGB
    */
    getColor :: (this: *SkPaint) -> SkColor #cpp_method #foreign libskia "?getColor@SkPaint@@QEBAIXZ";

    /** Retrieves alpha and RGB, unpremultiplied, as four floating point values. RGB are
    extended sRGB values (sRGB gamut, and encoded with the sRGB transfer function).
    
    @return  unpremultiplied RGBA
    */
    getColor4f :: (this: *SkPaint) -> SkColor4f #cpp_method #foreign libskia "?getColor4f@SkPaint@@QEBA?AU?$SkRGBA4f@$02@@XZ";

    /** Sets alpha and RGB used when stroking and filling. The color is a 32-bit value,
    unpremultiplied, packing 8-bit components for alpha, red, blue, and green.
    
    @param color  unpremultiplied ARGB
    
    example: https://fiddle.skia.org/c/@Paint_setColor
    */
    setColor :: (this: *SkPaint, color: SkColor) -> void #cpp_method #foreign libskia "?setColor@SkPaint@@QEAAXI@Z";

    /** Sets alpha and RGB used when stroking and filling. The color is four floating
    point values, unpremultiplied. The color values are interpreted as being in
    the colorSpace. If colorSpace is nullptr, then color is assumed to be in the
    sRGB color space.
    
    @param color       unpremultiplied RGBA
    @param colorSpace  SkColorSpace describing the encoding of color
    */
    setColor :: (this: *SkPaint, color: *SkColor4f, colorSpace: *SkColorSpace = null) -> void #cpp_method #foreign libskia "?setColor@SkPaint@@QEAAXAEBU?$SkRGBA4f@$02@@PEAVSkColorSpace@@@Z";
    setColor :: (this: *SkPaint, color: SkColor4f, colorSpace: *SkColorSpace = null) #no_context {
        setColor(this, *color, colorSpace);
    }

    setColor4f :: (this: *SkPaint, color: *SkColor4f, colorSpace: *SkColorSpace = null) -> void #cpp_method #foreign libskia "?setColor4f@SkPaint@@QEAAXAEBU?$SkRGBA4f@$02@@PEAVSkColorSpace@@@Z";
    setColor4f :: (this: *SkPaint, color: SkColor4f, colorSpace: *SkColorSpace = null) #no_context {
        setColor4f(this, *color, colorSpace);
    }

    /** Retrieves alpha from the color used when stroking and filling.
    
    @return  alpha ranging from zero, fully transparent, to one, fully opaque
    */
    getAlphaf :: (this: *SkPaint) -> float #cpp_method #foreign libskia "?getAlphaf@SkPaint@@QEBAMXZ";

    // Helper that scales the alpha by 255.
    getAlpha :: (this: *SkPaint) -> u8 #cpp_method #foreign libskia "?getAlpha@SkPaint@@QEBAEXZ";

    /** Replaces alpha, leaving RGB
    unchanged. An out of range value triggers an assert in the debug
    build. a is a value from 0.0 to 1.0.
    a set to zero makes color fully transparent; a set to 1.0 makes color
    fully opaque.
    
    @param a  alpha component of color
    */
    setAlphaf :: (this: *SkPaint, a: float) -> void #cpp_method #foreign libskia "?setAlphaf@SkPaint@@QEAAXM@Z";

    // Helper that accepts an int between 0 and 255, and divides it by 255.0
    setAlpha :: (this: *SkPaint, a: U8CPU) -> void #cpp_method #foreign libskia "?setAlpha@SkPaint@@QEAAXI@Z";

    /** Sets color used when drawing solid fills. The color components range from 0 to 255.
    The color is unpremultiplied; alpha sets the transparency independent of RGB.
    
    @param a  amount of alpha, from fully transparent (0) to fully opaque (255)
    @param r  amount of red, from no red (0) to full red (255)
    @param g  amount of green, from no green (0) to full green (255)
    @param b  amount of blue, from no blue (0) to full blue (255)
    
    example: https://fiddle.skia.org/c/@Paint_setARGB
    */
    setARGB :: (this: *SkPaint, a: U8CPU, r: U8CPU, g: U8CPU, b: U8CPU) -> void #cpp_method #foreign libskia "?setARGB@SkPaint@@QEAAXIIII@Z";

    /** Returns the thickness of the pen used by SkPaint to
    outline the shape.
    
    @return  zero for hairline, greater than zero for pen thickness
    */
    getStrokeWidth :: (this: *SkPaint) -> SkScalar #cpp_method #foreign libskia "?getStrokeWidth@SkPaint@@QEBAMXZ";

    /** Sets the thickness of the pen used by the paint to outline the shape.
    A stroke-width of zero is treated as "hairline" width. Hairlines are always exactly one
    pixel wide in device space (their thickness does not change as the canvas is scaled).
    Negative stroke-widths are invalid; setting a negative width will have no effect.
    
    @param width  zero thickness for hairline; greater than zero for pen thickness
    
    example: https://fiddle.skia.org/c/@Miter_Limit
    example: https://fiddle.skia.org/c/@Paint_setStrokeWidth
    */
    setStrokeWidth :: (this: *SkPaint, width: SkScalar) -> void #cpp_method #foreign libskia "?setStrokeWidth@SkPaint@@QEAAXM@Z";

    /** Returns the limit at which a sharp corner is drawn beveled.
    
    @return  zero and greater miter limit
    */
    getStrokeMiter :: (this: *SkPaint) -> SkScalar #cpp_method #foreign libskia "?getStrokeMiter@SkPaint@@QEBAMXZ";

    /** When stroking a small joinAngle with miter, the miterLength may be very long.
    When miterLength > maxMiterLength (or joinAngle < minJoinAngle) the join will become bevel.
    miterLimit = maxMiterLength / strokeWidth or miterLimit = 1 / sin(minJoinAngle / 2).
    
    This call has no effect if the miterLimit passed is less than zero.
    Values less than one will be treated as bevel.
    
    @param miterLimit  zero and greater miter limit
    
    example: https://fiddle.skia.org/c/@Paint_setStrokeMiter
    */
    setStrokeMiter :: (this: *SkPaint, miterLimit: SkScalar) -> void #cpp_method #foreign libskia "?setStrokeMiter@SkPaint@@QEAAXM@Z";

    /** \enum SkPaint::Cap
    Cap draws at the beginning and end of an open path contour.
    */
    Cap :: enum s32 {
        Butt_Cap    :: 0;
        Round_Cap   :: 1;
        Square_Cap  :: 2;
        Last_Cap    :: 2;
        Default_Cap :: 0;

        kButt_Cap    :: Butt_Cap;
        kRound_Cap   :: Round_Cap;
        kSquare_Cap  :: Square_Cap;
        kLast_Cap    :: Last_Cap;
        kDefault_Cap :: Default_Cap;
    }

    /** May be used to verify that SkPaint::Cap is a legal value.
    */
    kCapCount:                   s32 : cast(s32) (Cap.Last_Cap + 1);

    /** \enum SkPaint::Join
    Join specifies how corners are drawn when a shape is stroked. Join
    affects the four corners of a stroked rectangle, and the connected segments in a
    stroked path.
    
    Choose miter join to draw sharp corners. Choose round join to draw a circle with a
    radius equal to the stroke width on top of the corner. Choose bevel join to minimally
    connect the thick strokes.
    
    The fill path constructed to describe the stroked path respects the join setting but may
    not contain the actual join. For instance, a fill path constructed with round joins does
    not necessarily include circles at each connected segment.
    */
    Join :: enum u8 {
        Miter_Join   :: 0;
        Round_Join   :: 1;
        Bevel_Join   :: 2;
        Last_Join    :: 2;
        Default_Join :: 0;

        kMiter_Join   :: Miter_Join;
        kRound_Join   :: Round_Join;
        kBevel_Join   :: Bevel_Join;
        kLast_Join    :: Last_Join;
        kDefault_Join :: Default_Join;
    }

    /** May be used to verify that SkPaint::Join is a legal value.
    */
    kJoinCount:                  s32 : cast(s32) (Join.Last_Join + 1);

    /** Returns the geometry drawn at the beginning and end of strokes.
    */
    getStrokeCap :: (this: *SkPaint) -> Cap #cpp_method #foreign libskia "?getStrokeCap@SkPaint@@QEBA?AW4Cap@1@XZ";

    /** Sets the geometry drawn at the beginning and end of strokes.
    
    example: https://fiddle.skia.org/c/@Paint_setStrokeCap_a
    example: https://fiddle.skia.org/c/@Paint_setStrokeCap_b
    */
    setStrokeCap :: (this: *SkPaint, cap: Cap) -> void #cpp_method #foreign libskia "?setStrokeCap@SkPaint@@QEAAXW4Cap@1@@Z";

    /** Returns the geometry drawn at the corners of strokes.
    */
    getStrokeJoin :: (this: *SkPaint) -> Join #cpp_method #foreign libskia "?getStrokeJoin@SkPaint@@QEBA?AW4Join@1@XZ";

    /** Sets the geometry drawn at the corners of strokes.
    
    example: https://fiddle.skia.org/c/@Paint_setStrokeJoin
    */
    setStrokeJoin :: (this: *SkPaint, join: Join) -> void #cpp_method #foreign libskia "?setStrokeJoin@SkPaint@@QEAAXW4Join@1@@Z";

    /** Returns optional colors used when filling a path, such as a gradient.
    
    Does not alter SkShader SkRefCnt.
    
    @return  SkShader if previously set, nullptr otherwise
    */
    getShader :: (this: *SkPaint) -> *SkShader #cpp_method #foreign libskia "?getShader@SkPaint@@QEBAPEAVSkShader@@XZ";

    /** Returns optional colors used when filling a path, such as a gradient.
    
    Increases SkShader SkRefCnt by one.
    
    @return  SkShader if previously set, nullptr otherwise
    
    example: https://fiddle.skia.org/c/@Paint_refShader
    */
    refShader :: (this: *SkPaint) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refShader@SkPaint@@QEBA?AV?$sk_sp@VSkShader@@@@XZ";

    /** Sets optional colors used when filling a path, such as a gradient.
    
    Sets SkShader to shader, decreasing SkRefCnt of the previous SkShader.
    Increments shader SkRefCnt by one.
    
    @param shader  how geometry is filled with color; if nullptr, color is used instead
    
    example: https://fiddle.skia.org/c/@Color_Filter_Methods
    example: https://fiddle.skia.org/c/@Paint_setShader
    */
    setShader :: (this: *SkPaint, shader: sk_sp(SkShader)) -> void #cpp_method #foreign libskia "?setShader@SkPaint@@QEAAXV?$sk_sp@VSkShader@@@@@Z";

    /** Returns SkColorFilter if set, or nullptr.
    Does not alter SkColorFilter SkRefCnt.
    
    @return  SkColorFilter if previously set, nullptr otherwise
    */
    getColorFilter :: (this: *SkPaint) -> *SkColorFilter #cpp_method #foreign libskia "?getColorFilter@SkPaint@@QEBAPEAVSkColorFilter@@XZ";

    /** Returns SkColorFilter if set, or nullptr.
    Increases SkColorFilter SkRefCnt by one.
    
    @return  SkColorFilter if set, or nullptr
    
    example: https://fiddle.skia.org/c/@Paint_refColorFilter
    */
    refColorFilter :: (this: *SkPaint) -> sk_sp(SkColorFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refColorFilter@SkPaint@@QEBA?AV?$sk_sp@VSkColorFilter@@@@XZ";

    /** Sets SkColorFilter to filter, decreasing SkRefCnt of the previous
    SkColorFilter. Pass nullptr to clear SkColorFilter.
    
    Increments filter SkRefCnt by one.
    
    @param colorFilter  SkColorFilter to apply to subsequent draw
    
    example: https://fiddle.skia.org/c/@Blend_Mode_Methods
    example: https://fiddle.skia.org/c/@Paint_setColorFilter
    */
    setColorFilter :: (this: *SkPaint, colorFilter: sk_sp(SkColorFilter)) -> void #cpp_method #foreign libskia "?setColorFilter@SkPaint@@QEAAXV?$sk_sp@VSkColorFilter@@@@@Z";

    /** If the current blender can be represented as a SkBlendMode enum, this returns that
    *  enum in the optional's value(). If it cannot, then the returned optional does not
    *  contain a value.
    */
    asBlendMode :: (this: *SkPaint) -> std.optional(SkBlendMode) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?asBlendMode@SkPaint@@QEBA?AV?$optional@W4SkBlendMode@@@std@@XZ";

    /**
    *  Queries the blender, and if it can be represented as a SkBlendMode, return that mode,
    *  else return the defaultMode provided.
    */
    getBlendMode_or :: (this: *SkPaint, defaultMode: SkBlendMode) -> SkBlendMode #cpp_method #foreign libskia "?getBlendMode_or@SkPaint@@QEBA?AW4SkBlendMode@@W42@@Z";

    /** Returns true iff the current blender claims to be equivalent to SkBlendMode::kSrcOver.
    *
    *  Also returns true of the current blender is nullptr.
    */
    isSrcOver :: (this: *SkPaint) -> bool #cpp_method #foreign libskia "?isSrcOver@SkPaint@@QEBA_NXZ";

    /** Helper method for calling setBlender().
    *
    *  This sets a blender that implements the specified blendmode enum.
    */
    setBlendMode :: (this: *SkPaint, mode: SkBlendMode) -> void #cpp_method #foreign libskia "?setBlendMode@SkPaint@@QEAAXW4SkBlendMode@@@Z";

    /** Returns the user-supplied blend function, if one has been set.
    *  Does not alter SkBlender's SkRefCnt.
    *
    *  A nullptr blender signifies the default SrcOver behavior.
    *
    *  @return  the SkBlender assigned to this paint, otherwise nullptr
    */
    getBlender :: (this: *SkPaint) -> *SkBlender #cpp_method #foreign libskia "?getBlender@SkPaint@@QEBAPEAVSkBlender@@XZ";

    /** Returns the user-supplied blend function, if one has been set.
    *  Increments the SkBlender's SkRefCnt by one.
    *
    *  A nullptr blender signifies the default SrcOver behavior.
    *
    *  @return  the SkBlender assigned to this paint, otherwise nullptr
    */
    refBlender :: (this: *SkPaint) -> sk_sp(SkBlender) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refBlender@SkPaint@@QEBA?AV?$sk_sp@VSkBlender@@@@XZ";

    /** Sets the current blender, increasing its refcnt, and if a blender is already
    *  present, decreasing that object's refcnt.
    *
    *  A nullptr blender signifies the default SrcOver behavior.
    *
    *  For convenience, you can call setBlendMode() if the blend effect can be expressed
    *  as one of those values.
    */
    setBlender :: (this: *SkPaint, blender: sk_sp(SkBlender)) -> void #cpp_method #foreign libskia "?setBlender@SkPaint@@QEAAXV?$sk_sp@VSkBlender@@@@@Z";

    /** Returns SkPathEffect if set, or nullptr.
    Does not alter SkPathEffect SkRefCnt.
    
    @return  SkPathEffect if previously set, nullptr otherwise
    */
    getPathEffect :: (this: *SkPaint) -> *SkPathEffect #cpp_method #foreign libskia "?getPathEffect@SkPaint@@QEBAPEAVSkPathEffect@@XZ";

    /** Returns SkPathEffect if set, or nullptr.
    Increases SkPathEffect SkRefCnt by one.
    
    @return  SkPathEffect if previously set, nullptr otherwise
    
    example: https://fiddle.skia.org/c/@Paint_refPathEffect
    */
    refPathEffect :: (this: *SkPaint) -> sk_sp(SkPathEffect) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refPathEffect@SkPaint@@QEBA?AV?$sk_sp@VSkPathEffect@@@@XZ";

    /** Sets SkPathEffect to pathEffect, decreasing SkRefCnt of the previous
    SkPathEffect. Pass nullptr to leave the path geometry unaltered.
    
    Increments pathEffect SkRefCnt by one.
    
    @param pathEffect  replace SkPath with a modification when drawn
    
    example: https://fiddle.skia.org/c/@Mask_Filter_Methods
    example: https://fiddle.skia.org/c/@Paint_setPathEffect
    */
    setPathEffect :: (this: *SkPaint, pathEffect: sk_sp(SkPathEffect)) -> void #cpp_method #foreign libskia "?setPathEffect@SkPaint@@QEAAXV?$sk_sp@VSkPathEffect@@@@@Z";

    /** Returns SkMaskFilter if set, or nullptr.
    Does not alter SkMaskFilter SkRefCnt.
    
    @return  SkMaskFilter if previously set, nullptr otherwise
    */
    getMaskFilter :: (this: *SkPaint) -> *SkMaskFilter #cpp_method #foreign libskia "?getMaskFilter@SkPaint@@QEBAPEAVSkMaskFilter@@XZ";

    /** Returns SkMaskFilter if set, or nullptr.
    
    Increases SkMaskFilter SkRefCnt by one.
    
    @return  SkMaskFilter if previously set, nullptr otherwise
    
    example: https://fiddle.skia.org/c/@Paint_refMaskFilter
    */
    refMaskFilter :: (this: *SkPaint) -> sk_sp(SkMaskFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refMaskFilter@SkPaint@@QEBA?AV?$sk_sp@VSkMaskFilter@@@@XZ";

    /** Sets SkMaskFilter to maskFilter, decreasing SkRefCnt of the previous
    SkMaskFilter. Pass nullptr to clear SkMaskFilter and leave SkMaskFilter effect on
    mask alpha unaltered.
    
    Increments maskFilter SkRefCnt by one.
    
    @param maskFilter  modifies clipping mask generated from drawn geometry
    
    example: https://fiddle.skia.org/c/@Paint_setMaskFilter
    example: https://fiddle.skia.org/c/@Typeface_Methods
    */
    setMaskFilter :: (this: *SkPaint, maskFilter: sk_sp(SkMaskFilter)) -> void #cpp_method #foreign libskia "?setMaskFilter@SkPaint@@QEAAXV?$sk_sp@VSkMaskFilter@@@@@Z";

    /** Returns SkImageFilter if set, or nullptr.
    Does not alter SkImageFilter SkRefCnt.
    
    @return  SkImageFilter if previously set, nullptr otherwise
    */
    getImageFilter :: (this: *SkPaint) -> *SkImageFilter #cpp_method #foreign libskia "?getImageFilter@SkPaint@@QEBAPEAVSkImageFilter@@XZ";

    /** Returns SkImageFilter if set, or nullptr.
    Increases SkImageFilter SkRefCnt by one.
    
    @return  SkImageFilter if previously set, nullptr otherwise
    
    example: https://fiddle.skia.org/c/@Paint_refImageFilter
    */
    refImageFilter :: (this: *SkPaint) -> sk_sp(SkImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refImageFilter@SkPaint@@QEBA?AV?$sk_sp@VSkImageFilter@@@@XZ";

    /** Sets SkImageFilter to imageFilter, decreasing SkRefCnt of the previous
    SkImageFilter. Pass nullptr to clear SkImageFilter, and remove SkImageFilter effect
    on drawing.
    
    Increments imageFilter SkRefCnt by one.
    
    @param imageFilter  how SkImage is sampled when transformed
    
    example: https://fiddle.skia.org/c/@Paint_setImageFilter
    */
    setImageFilter :: (this: *SkPaint, imageFilter: sk_sp(SkImageFilter)) -> void #cpp_method #foreign libskia "?setImageFilter@SkPaint@@QEAAXV?$sk_sp@VSkImageFilter@@@@@Z";

    /** Returns true if SkPaint prevents all drawing;
    otherwise, the SkPaint may or may not allow drawing.
    
    Returns true if, for example, SkBlendMode combined with alpha computes a
    new alpha of zero.
    
    @return  true if SkPaint prevents all drawing
    
    example: https://fiddle.skia.org/c/@Paint_nothingToDraw
    */
    nothingToDraw :: (this: *SkPaint) -> bool #cpp_method #foreign libskia "?nothingToDraw@SkPaint@@QEBA_NXZ";

    /**     (to be made private)
    Returns true if SkPaint does not include elements requiring extensive computation
    to compute device bounds of drawn geometry. For instance, SkPaint with SkPathEffect
    always returns false.
    
    @return  true if SkPaint allows for fast computation of bounds
    */
    canComputeFastBounds :: (this: *SkPaint) -> bool #cpp_method #foreign libskia "?canComputeFastBounds@SkPaint@@QEBA_NXZ";

    /**     (to be made private)
    Only call this if canComputeFastBounds() returned true. This takes a
    raw rectangle (the raw bounds of a shape), and adjusts it for stylistic
    effects in the paint (e.g. stroking). If needed, it uses the storage
    parameter. It returns the adjusted bounds that can then be used
    for SkCanvas::quickReject tests.
    
    The returned SkRect will either be orig or storage, thus the caller
    should not rely on storage being set to the result, but should always
    use the returned value. It is legal for orig and storage to be the same
    SkRect.
    For example:
    if (!path.isInverseFillType() && paint.canComputeFastBounds()) {
    SkRect storage;
    if (canvas->quickReject(paint.computeFastBounds(path.getBounds(), &storage))) {
    return; // do not draw the path
    }
    }
    // draw the path
    
    @param orig     geometry modified by SkPaint when drawn
    @param storage  computed bounds of geometry; may not be nullptr
    @return         fast computed bounds
    */
    computeFastBounds :: (this: *SkPaint, orig: *SkRect, storage: *SkRect) -> *SkRect #cpp_method #foreign libskia "?computeFastBounds@SkPaint@@QEBAAEBUSkRect@@AEBU2@PEAU2@@Z";
    computeFastBounds :: (this: *SkPaint, orig: SkRect, storage: *SkRect) -> *SkRect #no_context {
        return computeFastBounds(this, *orig, storage);
    }

    /**     (to be made private)
    
    @param orig     geometry modified by SkPaint when drawn
    @param storage  computed bounds of geometry
    @return         fast computed bounds
    */
    computeFastStrokeBounds :: (this: *SkPaint, orig: *SkRect, storage: *SkRect) -> *SkRect #cpp_method #foreign libskia "?computeFastStrokeBounds@SkPaint@@QEBAAEBUSkRect@@AEBU2@PEAU2@@Z";
    computeFastStrokeBounds :: (this: *SkPaint, orig: SkRect, storage: *SkRect) -> *SkRect #no_context {
        return computeFastStrokeBounds(this, *orig, storage);
    }

    /**     (to be made private)
    Computes the bounds, overriding the SkPaint SkPaint::Style. This can be used to
    account for additional width required by stroking orig, without
    altering SkPaint::Style set to fill.
    
    @param orig     geometry modified by SkPaint when drawn
    @param storage  computed bounds of geometry
    @param style    overrides SkPaint::Style
    @return         fast computed bounds
    */
    doComputeFastBounds :: (this: *SkPaint, orig: *SkRect, storage: *SkRect, style: Style) -> *SkRect #cpp_method #foreign libskia "?doComputeFastBounds@SkPaint@@QEBAAEBUSkRect@@AEBU2@PEAU2@W4Style@1@@Z";
    doComputeFastBounds :: (this: *SkPaint, orig: SkRect, storage: *SkRect, style: Style) -> *SkRect #no_context {
        return doComputeFastBounds(this, *orig, storage, style);
    }

    sk_is_trivially_relocatable :: std.true_type;

    fPathEffect:                 sk_sp(SkPathEffect);
    fShader:                     sk_sp(SkShader);
    fMaskFilter:                 sk_sp(SkMaskFilter);
    fColorFilter:                sk_sp(SkColorFilter);
    fImageFilter:                sk_sp(SkImageFilter);
    fBlender:                    sk_sp(SkBlender);

    fColor4f:                    SkColor4f;
    fWidth:                      SkScalar;
    fMiterLimit:                 SkScalar;
    union {
        fBitfields:     struct {
            __bitfield: u32;
            /* 
                fAntiAlias: u32; /* 1 bits */
                fDither: u32; /* 1 bits */
                fCapType: u32; /* 2 bits */
                fJoinType: u32; /* 2 bits */
                fStyle: u32; /* 2 bits */
                fPadding: u32; /* 24 bits */ // 24 == 32 -1-1-2-2-2;
            */
        };

        fBitfieldsUInt: u32;
    }
}

/** Makes a shallow copy of SkPaint. SkPathEffect, SkShader,
SkMaskFilter, SkColorFilter, and SkImageFilter are shared
between the original paint and the copy. Objects containing SkRefCnt in the
prior destination are decreased by one, and the referenced objects are deleted if the
resulting count is zero. Objects containing SkRefCnt in the parameter paint
are increased by one. paint is unmodified.

@param paint  original to copy
@return       content of paint

example: https://fiddle.skia.org/c/@Paint_copy_operator
*/
operator_assign :: (this: *SkPaint, paint: *SkPaint) -> *SkPaint #cpp_method #foreign libskia "??4SkPaint@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkPaint, paint: SkPaint) -> *SkPaint #no_context {
    return operator_assign(this, *paint);
}

/**
*  A compressed form of a rotation+scale matrix.
*
*  [ fSCos     -fSSin    fTx ]
*  [ fSSin      fSCos    fTy ]
*  [     0          0      1 ]
*/
SkRSXform :: struct {
    Make :: (scos: SkScalar, ssin: SkScalar, tx: SkScalar, ty: SkScalar) -> SkRSXform #foreign libskia "?Make@SkRSXform@@SA?AU1@MMMM@Z";

    /*
    *  Initialize a new xform based on the scale, rotation (in radians), final tx,ty location
    *  and anchor-point ax,ay within the src quad.
    *
    *  Note: the anchor point is not normalized (e.g. 0...1) but is in pixels of the src image.
    */
    MakeFromRadians :: (scale: SkScalar, radians: SkScalar, tx: SkScalar, ty: SkScalar, ax: SkScalar, ay: SkScalar) -> SkRSXform #foreign libskia "?MakeFromRadians@SkRSXform@@SA?AU1@MMMMMM@Z";

    fSCos: SkScalar;
    fSSin: SkScalar;
    fTx:   SkScalar;
    fTy:   SkScalar;

    rectStaysRect :: (this: *SkRSXform) -> bool #cpp_method #foreign libskia "?rectStaysRect@SkRSXform@@QEBA_NXZ";

    setIdentity :: (this: *SkRSXform) -> void #cpp_method #foreign libskia "?setIdentity@SkRSXform@@QEAAXXZ";

    set :: (this: *SkRSXform, scos: SkScalar, ssin: SkScalar, tx: SkScalar, ty: SkScalar) -> void #cpp_method #foreign libskia "?set@SkRSXform@@QEAAXMMMM@Z";

    toQuad :: (this: *SkRSXform, width: SkScalar, height: SkScalar, quad: *[4] SkPoint) -> void #cpp_method #foreign libskia "?toQuad@SkRSXform@@QEBAXMMQEAUSkPoint@@@Z";
    toQuad :: (this: *SkRSXform, size: *SkSize, quad: *[4] SkPoint) -> void #cpp_method #foreign libskia "?toQuad@SkRSXform@@QEBAXAEBUSkSize@@QEAUSkPoint@@@Z";
    toQuad :: (this: *SkRSXform, size: SkSize, quad: *[4] SkPoint) #no_context {
        toQuad(this, *size, quad);
    }

    toTriStrip :: (this: *SkRSXform, width: SkScalar, height: SkScalar, strip: *[4] SkPoint) -> void #cpp_method #foreign libskia "?toTriStrip@SkRSXform@@QEBAXMMQEAUSkPoint@@@Z";
}

SkBitmap :: struct {}

/**
*  If a client wants to control the allocation of raster layers in a canvas, it should subclass
*  SkRasterHandleAllocator. This allocator performs two tasks:
*      1. controls how the memory for the pixels is allocated
*      2. associates a "handle" to a private object that can track the matrix/clip of the SkCanvas
*
*  This example allocates a canvas, and defers to the allocator to create the base layer.
*
*      std::unique_ptr<SkCanvas> canvas = SkRasterHandleAllocator::MakeCanvas(
*              SkImageInfo::Make(...),
*              std::make_unique<MySubclassRasterHandleAllocator>(...),
*              nullptr);
*
*  If you have already allocated the base layer (and its handle, release-proc etc.) then you
*  can pass those in using the last parameter to MakeCanvas().
*
*  Regardless of how the base layer is allocated, each time canvas->saveLayer() is called,
*  your allocator's allocHandle() will be called.
*/
SkRasterHandleAllocator :: struct {
    vtable: *SkRasterHandleAllocator_VTable;

    // The value that is returned to clients of the canvas that has this allocator installed.
    Handle :: *void;

    Rec :: struct {
        // When the allocation goes out of scope, this proc is called to free everything associated
        // with it: the pixels, the "handle", etc. This is passed the pixel address and fReleaseCtx.
        fReleaseProc: #type (pixels: *void, ctx: *void) -> void #c_call;
        fReleaseCtx:  *void; // context passed to fReleaseProc
        fPixels:      *void; // pixels for this allocation
        fRowBytes:    u64; // rowbytes for these pixels
        fHandle:      Handle; // public handle returned by SkCanvas::accessTopRasterHandle()
    }

    /**
    *  This creates a canvas which will use the allocator to manage pixel allocations, including
    *  all calls to saveLayer().
    *
    *  If rec is non-null, then it will be used as the base-layer of pixels/handle.
    *  If rec is null, then the allocator will be called for the base-layer as well.
    */
    MakeCanvas :: (unknown0: std.unique_ptr(SkRasterHandleAllocator), unknown1: *SkImageInfo, rec: *Rec = null, props: *SkSurfaceProps = null) -> std.unique_ptr(SkCanvas) #cpp_return_type_is_non_pod #foreign libskia "?MakeCanvas@SkRasterHandleAllocator@@SA?AV?$unique_ptr@VSkCanvas@@U?$default_delete@VSkCanvas@@@std@@@std@@V?$unique_ptr@VSkRasterHandleAllocator@@U?$default_delete@VSkRasterHandleAllocator@@@std@@@3@AEBUSkImageInfo@@PEBURec@1@PEBVSkSurfaceProps@@@Z";
    MakeCanvas :: (unknown0: std.unique_ptr(SkRasterHandleAllocator), unknown1: SkImageInfo, rec: *Rec = null, props: *SkSurfaceProps = null) -> std.unique_ptr(SkCanvas) #no_context {
        return MakeCanvas(unknown0, *unknown1, rec, props);
    }

    Constructor :: (this: *SkRasterHandleAllocator) -> void #cpp_method #foreign libskia "??0SkRasterHandleAllocator@@IEAA@XZ";
//     CopyConstructor :: (this: *SkRasterHandleAllocator, unknown0: *SkRasterHandleAllocator) -> void #cpp_method #foreign libskia "??0SkRasterHandleAllocator@@IEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkRasterHandleAllocator, unknown0: SkRasterHandleAllocator) #no_context {
        CopyConstructor(this, *unknown0);
    }

    allocBitmap :: (this: *SkRasterHandleAllocator, unknown0: *SkImageInfo, unknown1: *SkBitmap) -> Handle #cpp_method #foreign libskia "?allocBitmap@SkRasterHandleAllocator@@AEAAPEAXAEBUSkImageInfo@@PEAVSkBitmap@@@Z";
    allocBitmap :: (this: *SkRasterHandleAllocator, unknown0: SkImageInfo, unknown1: *SkBitmap) -> Handle #no_context {
        return allocBitmap(this, *unknown0, unknown1);
    }

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkRasterHandleAllocator, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkRasterHandleAllocator@@UEAA@XZ";

    /**
    *  Given a requested info, allocate the corresponding pixels/rowbytes, and whatever handle
    *  is desired to give clients access to those pixels. The rec also contains a proc and context
    *  which will be called when this allocation goes out of scope.
    *
    *  e.g.
    *      when canvas->saveLayer() is called, the allocator will be called to allocate the pixels
    *      for the layer. When canvas->restore() is called, the fReleaseProc will be called.
    */
//     virtual_allocHandle :: (this: *SkRasterHandleAllocator, unknown0: *SkImageInfo, unknown1: *Rec) -> bool #cpp_method #foreign libskia "?allocHandle@SkRasterHandleAllocator@@UEAA_NAEBUSkImageInfo@@PEAURec@1@@Z";

    /**
    *  Clients access the handle for a given layer by calling SkCanvas::accessTopRasterHandle().
    *  To allow the handle to reflect the current matrix/clip in the canvs, updateHandle() is
    *  is called. The subclass is responsible to update the handle as it sees fit.
    */
//     virtual_updateHandle :: (this: *SkRasterHandleAllocator, unknown0: Handle, unknown1: *SkMatrix, unknown2: *SkIRect) -> void #cpp_method #foreign libskia "?updateHandle@SkRasterHandleAllocator@@UEAAXPEAXAEBVSkMatrix@@AEBUSkIRect@@@Z";
}
SkRasterHandleAllocator_VTable :: struct #type_info_none {
    Destructor:   #type (this: *SkRasterHandleAllocator, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    allocHandle:  #type (this: *SkRasterHandleAllocator, unknown0: *SkImageInfo, unknown1: *SkRasterHandleAllocator.Rec) -> bool #cpp_method;

    updateHandle: #type (this: *SkRasterHandleAllocator, unknown0: SkRasterHandleAllocator.Handle, unknown1: *SkMatrix, unknown2: *SkIRect) -> void #cpp_method;
}
SkRasterHandleAllocator_Destructor :: inline (this: *SkRasterHandleAllocator, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkRasterHandleAllocator_allocHandle :: inline (this: *SkRasterHandleAllocator, unknown0: *SkImageInfo, unknown1: *SkRasterHandleAllocator.Rec) -> bool { return this.vtable.allocHandle(this, unknown0, unknown1); }

SkRasterHandleAllocator_updateHandle :: inline (this: *SkRasterHandleAllocator, unknown0: SkRasterHandleAllocator.Handle, unknown1: *SkMatrix, unknown2: *SkIRect) { this.vtable.updateHandle(this, unknown0, unknown1, unknown2); }

get_vtable :: (obj: *SkRasterHandleAllocator) -> *SkRasterHandleAllocator_VTable { return obj.vtable; }


// operator_assign :: (this: *SkRasterHandleAllocator, unknown0: *SkRasterHandleAllocator) -> *SkRasterHandleAllocator #cpp_method #foreign libskia "??4SkRasterHandleAllocator@@IEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkRasterHandleAllocator, unknown0: SkRasterHandleAllocator) -> *SkRasterHandleAllocator #no_context {
    return operator_assign(this, *unknown0);
}

SkFilterMode :: enum s32 {
    Nearest :: 0;
    Linear  :: 1;

    Last    :: 1;

    kNearest :: Nearest;
    kLinear  :: Linear;

    kLast    :: Last;
}

kSkFilterModeCount: s32 : cast(s32) (SkFilterMode.Last + 1);

SkMipmapMode :: enum s32 {
    None    :: 0;
    Nearest :: 1;
    Linear  :: 2;

    Last    :: 2;

    kNone    :: None;
    kNearest :: Nearest;
    kLinear  :: Linear;

    kLast    :: Last;
}

kSkMipmapModeCount: s32 : cast(s32) (SkMipmapMode.Last + 1);

/*
*  Specify B and C (each between 0...1) to create a shader that applies the corresponding
*  cubic reconstruction filter to the image.
*
*  Example values:
*      B = 1/3, C = 1/3        "Mitchell" filter
*      B = 0,   C = 1/2        "Catmull-Rom" filter
*
*  See "Reconstruction Filters in Computer Graphics"
*          Don P. Mitchell
*          Arun N. Netravali
*          1988
*  https://www.cs.utexas.edu/~fussell/courses/cs384g-fall2013/lectures/mitchell/Mitchell.pdf
*
*  Desmos worksheet https://www.desmos.com/calculator/aghdpicrvr
*  Nice overview https://entropymine.com/imageworsener/bicubic/
*/
SkCubicResampler :: struct {
    B: float;
    C: float;

    // Historic default for kHigh_SkFilterQuality
//     Mitchell :: () -> SkCubicResampler #foreign libskia "?Mitchell@SkCubicResampler@@SA?AU1@XZ";
//     CatmullRom :: () -> SkCubicResampler #foreign libskia "?CatmullRom@SkCubicResampler@@SA?AU1@XZ";
}

SkSamplingOptions :: struct {
    maxAniso: s32 : 0;
    useCubic  :: false;

    filter:   SkFilterMode : .Nearest;
    mipmap:   SkMipmapMode : .None;

    Constructor :: (this: *SkSamplingOptions) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@QEAA@XZ";
//     CopyConstructor :: (this: *SkSamplingOptions, unknown0: *SkSamplingOptions) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@QEAA@AEBU0@@Z";
    CopyConstructor :: (this: *SkSamplingOptions, unknown0: SkSamplingOptions) #no_context {
        CopyConstructor(this, *unknown0);
    }

    Constructor :: (this: *SkSamplingOptions, fm: SkFilterMode, mm: SkMipmapMode) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@QEAA@W4SkFilterMode@@W4SkMipmapMode@@@Z";

    // These are intentionally implicit because the single parameter clearly conveys what the
    // implicitly created SkSamplingOptions will be.
    Constructor :: (this: *SkSamplingOptions, fm: SkFilterMode) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@QEAA@W4SkFilterMode@@@Z";

    Constructor :: (this: *SkSamplingOptions, c: *SkCubicResampler) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@QEAA@AEBUSkCubicResampler@@@Z";
    Constructor :: (this: *SkSamplingOptions, c: SkCubicResampler) #no_context {
        Constructor(this, *c);
    }

    Aniso :: (maxAniso: s32) -> SkSamplingOptions #cpp_return_type_is_non_pod #foreign libskia "?Aniso@SkSamplingOptions@@SA?AU1@H@Z";

    isAniso :: (this: *SkSamplingOptions) -> bool #cpp_method #foreign libskia "?isAniso@SkSamplingOptions@@QEBA_NXZ";

    Constructor :: (this: *SkSamplingOptions, maxAniso: s32) -> void #cpp_method #foreign libskia "??0SkSamplingOptions@@AEAA@H@Z";
}

operator_assign :: (this: *SkSamplingOptions, that: *SkSamplingOptions) -> *SkSamplingOptions #cpp_method #foreign libskia "??4SkSamplingOptions@@QEAAAEAU0@AEBU0@@Z";
operator_assign :: (this: *SkSamplingOptions, that: SkSamplingOptions) -> *SkSamplingOptions #no_context {
    return operator_assign(this, *that);
}

operator_eq :: (this: *SkSamplingOptions, other: *SkSamplingOptions) -> bool #cpp_method #foreign libskia "??8SkSamplingOptions@@QEBA_NAEBU0@@Z";
operator_eq :: (this: SkSamplingOptions, other: SkSamplingOptions) -> bool #no_context {
    return operator_eq(*this, *other);
}

operator_neq :: (this: *SkSamplingOptions, other: *SkSamplingOptions) -> bool #cpp_method #foreign libskia "??9SkSamplingOptions@@QEBA_NAEBU0@@Z";
operator_neq :: (this: SkSamplingOptions, other: SkSamplingOptions) -> bool #no_context {
    return operator_neq(*this, *other);
}

/*  Some helper functions for C strings */
// SkStrStartsWith :: (_string: *u8, prefixStr: *u8) -> bool #foreign libskia "?SkStrStartsWith@@YA_NQEBD0@Z";

// SkStrStartsWith :: (_string: *u8, prefixChar: u8) -> bool #foreign libskia "?SkStrStartsWith@@YA_NQEBDD@Z";

// SkStrEndsWith :: (_string: *u8, suffixStr: *u8) -> bool #foreign libskia "?SkStrEndsWith@@YA_NQEBD0@Z";
// SkStrEndsWith :: (_string: *u8, suffixChar: u8) -> bool #foreign libskia "?SkStrEndsWith@@YA_NQEBDD@Z";

// SkStrStartsWithOneOf :: (_string: *u8, prefixes: *u8) -> s32 #foreign libskia "?SkStrStartsWithOneOf@@YAHQEBD0@Z";

// SkStrFind :: (_string: *u8, substring: *u8) -> s32 #foreign libskia "?SkStrFind@@YAHQEBD0@Z";

// SkStrFindLastOf :: (_string: *u8, subchar: u8) -> s32 #foreign libskia "?SkStrFindLastOf@@YAHQEBDD@Z";

// SkStrContains :: (_string: *u8, substring: *u8) -> bool #foreign libskia "?SkStrContains@@YA_NQEBD0@Z";

// SkStrContains :: (_string: *u8, subchar: u8) -> bool #foreign libskia "?SkStrContains@@YA_NQEBDD@Z";

/*
*  The SkStrAppend... methods will write into the provided buffer, assuming it is large enough.
*  Each method has an associated const (e.g. kSkStrAppendU32_MaxSize) which will be the largest
*  value needed for that method's buffer.
*
*  char storage[kSkStrAppendU32_MaxSize];
*  SkStrAppendU32(storage, value);
*
*  Note : none of the SkStrAppend... methods write a terminating 0 to their buffers. Instead,
*  the methods return the ptr to the end of the written part of the buffer. This can be used
*  to compute the length, and/or know where to write a 0 if that is desired.
*
*  char storage[kSkStrAppendU32_MaxSize + 1];
*  char* stop = SkStrAppendU32(storage, value);
*  size_t len = stop - storage;
*  *stop = 0;   // valid, since storage was 1 byte larger than the max.
*/
kSkStrAppendU32_MaxSize: s32 : 10;
// SkStrAppendU32 :: (buffer: *u8, unknown0: u32) -> *u8 #foreign libskia "?SkStrAppendU32@@YAPEADQEADI@Z";
kSkStrAppendU64_MaxSize: s32 : 20;
// SkStrAppendU64 :: (buffer: *u8, unknown0: u64, minDigits: s32) -> *u8 #foreign libskia "?SkStrAppendU64@@YAPEADQEAD_KH@Z";

kSkStrAppendS32_MaxSize: s32 : kSkStrAppendU32_MaxSize + 1;
// SkStrAppendS32 :: (buffer: *u8, unknown0: s32) -> *u8 #foreign libskia "?SkStrAppendS32@@YAPEADQEADH@Z";
kSkStrAppendS64_MaxSize: s32 : kSkStrAppendU64_MaxSize + 1;
// SkStrAppendS64 :: (buffer: *u8, unknown0: s64, minDigits: s32) -> *u8 #foreign libskia "?SkStrAppendS64@@YAPEADQEAD_JH@Z";

/**
*  Floats have at most 8 significant digits, so we limit our %g to that.
*  However, the total string could be 15 characters: -1.2345678e-005
*
*  In theory we should only expect up to 2 digits for the exponent, but on
*  some platforms we have seen 3 (as in the example above).
*/
kSkStrAppendScalar_MaxSize: s32 : 15;

/**
*  Write the scalar in decimal format into buffer, and return a pointer to
*  the next char after the last one written. Note: a terminating 0 is not
*  written into buffer, which must be at least kSkStrAppendScalar_MaxSize.
*  Thus if the caller wants to add a 0 at the end, buffer must be at least
*  kSkStrAppendScalar_MaxSize + 1 bytes large.
*/
// SkStrAppendScalar :: (buffer: *u8, unknown0: SkScalar) -> *u8 #foreign libskia "?SkStrAppendScalar@@YAPEADQEADM@Z";

/** \class SkString

Light weight class for managing strings. Uses reference
counting to make string assignments and copies very fast
with no extra RAM cost. Assumes UTF8 encoding.
*/
SkString :: struct {
    Constructor :: (this: *SkString) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@XZ";
    Constructor :: (this: *SkString, len: u64) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@_K@Z";
    Constructor :: (this: *SkString, text: *u8) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@QEBD@Z";
    Constructor :: (this: *SkString, text: *u8, len: u64) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@QEBD_K@Z";
    CopyConstructor :: (this: *SkString, unknown0: *SkString) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkString, unknown0: SkString) #no_context {
        CopyConstructor(this, *unknown0);
    }

    Constructor :: (this: *SkString, unknown0: *std.String) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@AEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@Z";
    Constructor :: (this: *SkString, unknown0: std.String) #no_context {
        Constructor(this, *unknown0);
    }
    Constructor :: (this: *SkString, unknown0: std.String_view) -> void #cpp_method #foreign libskia "??0SkString@@QEAA@V?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z";
    Destructor :: (this: *SkString) -> void #cpp_method #foreign libskia "??1SkString@@QEAA@XZ";

    isEmpty :: (this: *SkString) -> bool #cpp_method #foreign libskia "?isEmpty@SkString@@QEBA_NXZ";
    size :: (this: *SkString) -> u64 #cpp_method #foreign libskia "?size@SkString@@QEBA_KXZ";
    data :: (this: /*const*/ *SkString) -> *u8 #cpp_method #foreign libskia "?data@SkString@@QEBAPEBDXZ";
    c_str :: (this: *SkString) -> *u8 #cpp_method #foreign libskia "?c_str@SkString@@QEBAPEBDXZ";

    begin :: (this: /*const*/ *SkString) -> *u8 #cpp_method #foreign libskia "?begin@SkString@@QEBAPEBDXZ";
    end :: (this: /*const*/ *SkString) -> *u8 #cpp_method #foreign libskia "?end@SkString@@QEBAPEBDXZ";

    equals :: (this: *SkString, unknown0: *SkString) -> bool #cpp_method #foreign libskia "?equals@SkString@@QEBA_NAEBV1@@Z";
    equals :: (this: *SkString, unknown0: SkString) -> bool #no_context {
        return equals(this, *unknown0);
    }
    equals :: (this: *SkString, text: *u8) -> bool #cpp_method #foreign libskia "?equals@SkString@@QEBA_NQEBD@Z";
    equals :: (this: *SkString, text: *u8, len: u64) -> bool #cpp_method #foreign libskia "?equals@SkString@@QEBA_NQEBD_K@Z";

    startsWith :: (this: *SkString, prefixStr: *u8) -> bool #cpp_method #foreign libskia "?startsWith@SkString@@QEBA_NQEBD@Z";

    startsWith :: (this: *SkString, prefixChar: u8) -> bool #cpp_method #foreign libskia "?startsWith@SkString@@QEBA_ND@Z";

    endsWith :: (this: *SkString, suffixStr: *u8) -> bool #cpp_method #foreign libskia "?endsWith@SkString@@QEBA_NQEBD@Z";

    endsWith :: (this: *SkString, suffixChar: u8) -> bool #cpp_method #foreign libskia "?endsWith@SkString@@QEBA_ND@Z";

    contains :: (this: *SkString, substring: *u8) -> bool #cpp_method #foreign libskia "?contains@SkString@@QEBA_NQEBD@Z";

    contains :: (this: *SkString, subchar: u8) -> bool #cpp_method #foreign libskia "?contains@SkString@@QEBA_ND@Z";

    find :: (this: *SkString, substring: *u8) -> s32 #cpp_method #foreign libskia "?find@SkString@@QEBAHQEBD@Z";

    findLastOf :: (this: *SkString, subchar: u8) -> s32 #cpp_method #foreign libskia "?findLastOf@SkString@@QEBAHD@Z";

    data_1 :: (this: *SkString) -> *u8 #cpp_method #foreign libskia "?data@SkString@@QEAAPEADXZ";

    begin_1 :: (this: *SkString) -> *u8 #cpp_method #foreign libskia "?begin@SkString@@QEAAPEADXZ";
    end_1 :: (this: *SkString) -> *u8 #cpp_method #foreign libskia "?end@SkString@@QEAAPEADXZ";

    reset :: (this: *SkString) -> void #cpp_method #foreign libskia "?reset@SkString@@QEAAXXZ";

    /** String contents are preserved on resize. (For destructive resize, `set(nullptr, length)`.)
    * `resize` automatically reserves an extra byte at the end of the buffer for a null terminator.
    */
    resize :: (this: *SkString, len: u64) -> void #cpp_method #foreign libskia "?resize@SkString@@QEAAX_K@Z";
    set :: (this: *SkString, src: *SkString) -> void #cpp_method #foreign libskia "?set@SkString@@QEAAXAEBV1@@Z";
    set :: (this: *SkString, src: SkString) #no_context {
        set(this, *src);
    }
    set :: (this: *SkString, text: *u8) -> void #cpp_method #foreign libskia "?set@SkString@@QEAAXQEBD@Z";
    set :: (this: *SkString, text: *u8, len: u64) -> void #cpp_method #foreign libskia "?set@SkString@@QEAAXQEBD_K@Z";
    set :: (this: *SkString, str: std.String_view) -> void #cpp_method #foreign libskia "?set@SkString@@QEAAXV?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z";

    insert :: (this: *SkString, offset: u64, text: *u8) -> void #cpp_method #foreign libskia "?insert@SkString@@QEAAX_KQEBD@Z";
    insert :: (this: *SkString, offset: u64, text: *u8, len: u64) -> void #cpp_method #foreign libskia "?insert@SkString@@QEAAX_KQEBD0@Z";
    insert :: (this: *SkString, offset: u64, str: *SkString) -> void #cpp_method #foreign libskia "?insert@SkString@@QEAAX_KAEBV1@@Z";
    insert :: (this: *SkString, offset: u64, str: SkString) #no_context {
        insert(this, offset, *str);
    }
    insert :: (this: *SkString, offset: u64, str: std.String_view) -> void #cpp_method #foreign libskia "?insert@SkString@@QEAAX_KV?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z";
    insertUnichar :: (this: *SkString, offset: u64, unknown0: SkUnichar) -> void #cpp_method #foreign libskia "?insertUnichar@SkString@@QEAAX_KH@Z";
    insertS32 :: (this: *SkString, offset: u64, value: s32) -> void #cpp_method #foreign libskia "?insertS32@SkString@@QEAAX_KH@Z";
    insertS64 :: (this: *SkString, offset: u64, value: s64, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?insertS64@SkString@@QEAAX_K_JH@Z";
    insertU32 :: (this: *SkString, offset: u64, value: u32) -> void #cpp_method #foreign libskia "?insertU32@SkString@@QEAAX_KI@Z";
    insertU64 :: (this: *SkString, offset: u64, value: u64, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?insertU64@SkString@@QEAAX_K0H@Z";
    insertHex :: (this: *SkString, offset: u64, value: u32, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?insertHex@SkString@@QEAAX_KIH@Z";
    insertScalar :: (this: *SkString, offset: u64, unknown0: SkScalar) -> void #cpp_method #foreign libskia "?insertScalar@SkString@@QEAAX_KM@Z";

    append :: (this: *SkString, text: *u8) -> void #cpp_method #foreign libskia "?append@SkString@@QEAAXQEBD@Z";
    append :: (this: *SkString, text: *u8, len: u64) -> void #cpp_method #foreign libskia "?append@SkString@@QEAAXQEBD_K@Z";
    append :: (this: *SkString, str: *SkString) -> void #cpp_method #foreign libskia "?append@SkString@@QEAAXAEBV1@@Z";
    append :: (this: *SkString, str: SkString) #no_context {
        append(this, *str);
    }
    append :: (this: *SkString, str: std.String_view) -> void #cpp_method #foreign libskia "?append@SkString@@QEAAXV?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z";
    appendUnichar :: (this: *SkString, uni: SkUnichar) -> void #cpp_method #foreign libskia "?appendUnichar@SkString@@QEAAXH@Z";
    appendS32 :: (this: *SkString, value: s32) -> void #cpp_method #foreign libskia "?appendS32@SkString@@QEAAXH@Z";
    appendS64 :: (this: *SkString, value: s64, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?appendS64@SkString@@QEAAX_JH@Z";
    appendU32 :: (this: *SkString, value: u32) -> void #cpp_method #foreign libskia "?appendU32@SkString@@QEAAXI@Z";
    appendU64 :: (this: *SkString, value: u64, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?appendU64@SkString@@QEAAX_KH@Z";
    appendHex :: (this: *SkString, value: u32, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?appendHex@SkString@@QEAAXIH@Z";
    appendScalar :: (this: *SkString, value: SkScalar) -> void #cpp_method #foreign libskia "?appendScalar@SkString@@QEAAXM@Z";

    prepend :: (this: *SkString, text: *u8) -> void #cpp_method #foreign libskia "?prepend@SkString@@QEAAXQEBD@Z";
    prepend :: (this: *SkString, text: *u8, len: u64) -> void #cpp_method #foreign libskia "?prepend@SkString@@QEAAXQEBD_K@Z";
    prepend :: (this: *SkString, str: *SkString) -> void #cpp_method #foreign libskia "?prepend@SkString@@QEAAXAEBV1@@Z";
    prepend :: (this: *SkString, str: SkString) #no_context {
        prepend(this, *str);
    }
    prepend :: (this: *SkString, str: std.String_view) -> void #cpp_method #foreign libskia "?prepend@SkString@@QEAAXV?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z";
    prependUnichar :: (this: *SkString, uni: SkUnichar) -> void #cpp_method #foreign libskia "?prependUnichar@SkString@@QEAAXH@Z";
    prependS32 :: (this: *SkString, value: s32) -> void #cpp_method #foreign libskia "?prependS32@SkString@@QEAAXH@Z";
    prependS64 :: (this: *SkString, value: s32, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?prependS64@SkString@@QEAAXHH@Z";
    prependHex :: (this: *SkString, value: u32, minDigits: s32 = 0) -> void #cpp_method #foreign libskia "?prependHex@SkString@@QEAAXIH@Z";
    prependScalar :: (this: *SkString, value: SkScalar) -> void #cpp_method #foreign libskia "?prependScalar@SkString@@QEAAXM@Z";

    printf :: (this: *SkString, format: *u8, __args: ..Any) -> void #cpp_method #foreign libskia "?printf@SkString@@QEAAXQEBDZZ";
    printVAList :: (this: *SkString, format: *u8, unknown0: va_list) -> void #cpp_method #foreign libskia "?printVAList@SkString@@QEAAXQEBDPEAD@Z";
    appendf :: (this: *SkString, format: *u8, __args: ..Any) -> void #cpp_method #foreign libskia "?appendf@SkString@@QEAAXQEBDZZ";
    appendVAList :: (this: *SkString, format: *u8, unknown0: va_list) -> void #cpp_method #foreign libskia "?appendVAList@SkString@@QEAAXQEBDPEAD@Z";
    prependf :: (this: *SkString, format: *u8, __args: ..Any) -> void #cpp_method #foreign libskia "?prependf@SkString@@QEAAXQEBDZZ";
    prependVAList :: (this: *SkString, format: *u8, unknown0: va_list) -> void #cpp_method #foreign libskia "?prependVAList@SkString@@QEAAXQEBDPEAD@Z";

    _remove :: (this: *SkString, offset: u64, length: u64) -> void #cpp_method #foreign libskia "?remove@SkString@@QEAAX_K0@Z";

    /**
    *  Swap contents between this and other. This function is guaranteed
    *  to never fail or throw.
    */
    swap :: (this: *SkString, other: *SkString) -> void #cpp_method #foreign libskia "?swap@SkString@@QEAAXAEAV1@@Z";

    sk_is_trivially_relocatable :: std.true_type;

    Rec :: struct {
//         Constructor :: (this: *Rec, len: u32, refCnt: s32) -> void #cpp_method #foreign libskia "??0Rec@SkString@@QEAA@IH@Z";
//         Make :: (text: *u8, len: u64) -> sk_sp(Rec) #cpp_return_type_is_non_pod #foreign libskia "?Make@Rec@SkString@@SA?AV?$sk_sp@URec@SkString@@@@QEBD_K@Z";
//         data :: (this: *Rec) -> *u8 #cpp_method #foreign libskia "?data@Rec@SkString@@QEAAPEADXZ";
//         data_1 :: (this: /*const*/ *Rec) -> *u8 #cpp_method #foreign libskia "?data@Rec@SkString@@QEBAPEBDXZ";
//         ref :: (this: *Rec) -> void #cpp_method #foreign libskia "?ref@Rec@SkString@@QEBAXXZ";
//         unref :: (this: *Rec) -> void #cpp_method #foreign libskia "?unref@Rec@SkString@@QEBAXXZ";
//         unique :: (this: *Rec) -> bool #cpp_method #foreign libskia "?unique@Rec@SkString@@QEBA_NXZ";

//         getRefCnt :: (this: *Rec) -> s32 #cpp_method #foreign libskia "?getRefCnt@Rec@SkString@@QEBAHXZ";

        fLength:          u32; // logically size_t, but we want it to stay 32 bits

        fRefCnt:          std.atomic(s32);
        fBeginningOfData: [1] u8;
    }

    // Ensure the unsized delete is called.
//     operatordelete :: (this: *SkString.Rec, p: *void) -> void #cpp_method #foreign libskia "??3Rec@SkString@@CAXPEAX@Z";
    operatordelete :: (this: SkString.Rec, p: *void) #no_context {
        operatordelete(*this, p);
    }

    fRec:                        sk_sp(Rec);

    validate :: (this: *SkString) -> *SkString #cpp_method #foreign libskia "?validate@SkString@@AEAAAEAV1@XZ";
    validate_1 :: (this: /*const*/ *SkString) -> *SkString #cpp_method #foreign libskia "?validate@SkString@@AEBAAEBV1@XZ";
}

operator_subscript :: (this: /*const*/ *SkString, n: u64) -> u8 #cpp_method #foreign libskia "??ASkString@@QEBAD_K@Z";
operator_subscript :: (this: SkString, n: u64) -> u8 #no_context {
    return operator_subscript(*this, n);
}

// these methods edit the string
operator_assign :: (this: *SkString, unknown0: *SkString) -> *SkString #cpp_method #foreign libskia "??4SkString@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkString, unknown0: SkString) -> *SkString #no_context {
    return operator_assign(this, *unknown0);
}

operator_assign :: (this: *SkString, text: *u8) -> *SkString #cpp_method #foreign libskia "??4SkString@@QEAAAEAV0@QEBD@Z";

operator_brackets_1 :: (this: *SkString, n: u64) -> *u8 #cpp_method #foreign libskia "??ASkString@@QEAAAEAD_K@Z";
operator_brackets_1 :: (this: SkString, n: u64) -> *u8 #no_context {
    return operator_brackets_1(*this, n);
}

operator_plus_equals :: (this: *SkString, s: *SkString) -> *SkString #cpp_method #foreign libskia "??YSkString@@QEAAAEAV0@AEBV0@@Z";
operator_plus_equals :: (this: *SkString, s: SkString) -> *SkString #no_context {
    return operator_plus_equals(this, *s);
}
operator_plus_equals :: (this: *SkString, text: *u8) -> *SkString #cpp_method #foreign libskia "??YSkString@@QEAAAEAV0@QEBD@Z";
operator_plus_equals :: (this: *SkString, c: u8) -> *SkString #cpp_method #foreign libskia "??YSkString@@QEAAAEAV0@D@Z";

/// Creates a new string and writes into it using a printf()-style format.
SkStringPrintf_CFormat :: (format: *u8, __args: ..Any) -> SkString #cpp_return_type_is_non_pod #foreign libskia "?SkStringPrintf@@YA?AVSkString@@PEBDZZ";
SkStringPrintf :: (format: string, __args: ..Any) -> SkString {
    push_allocator(temp);
    formatted_text_builder: String_Builder;
    print_to_builder(*formatted_text_builder, format, ..__args);
    append(*formatted_text_builder, "\0");
    formatted_text := builder_to_string(*formatted_text_builder);
    return SkStringPrintf_CFormat("%s", formatted_text.data);
} @PrintLike

/// This makes it easier to write a caller as a VAR_ARGS function where the format string is
/// optional.
// SkStringPrintf :: () -> SkString #cpp_return_type_is_non_pod #foreign libskia "?SkStringPrintf@@YA?AVSkString@@XZ";

// swap :: (a: *SkString, b: *SkString) -> void #foreign libskia "?swap@@YAXAEAVSkString@@0@Z";

/**
*  Description of how the LCD strips are arranged for each pixel. If this is unknown, or the
*  pixels are meant to be "portable" and/or transformed before showing (e.g. rotated, scaled)
*  then use kUnknown_SkPixelGeometry.
*/
SkPixelGeometry :: enum s32 {
    Unknown_SkPixelGeometry :: 0;
    RGB_H_SkPixelGeometry   :: 1;
    BGR_H_SkPixelGeometry   :: 2;
    RGB_V_SkPixelGeometry   :: 3;
    BGR_V_SkPixelGeometry   :: 4;

    kUnknown_SkPixelGeometry :: Unknown_SkPixelGeometry;
    kRGB_H_SkPixelGeometry   :: RGB_H_SkPixelGeometry;
    kBGR_H_SkPixelGeometry   :: BGR_H_SkPixelGeometry;
    kRGB_V_SkPixelGeometry   :: RGB_V_SkPixelGeometry;
    kBGR_V_SkPixelGeometry   :: BGR_V_SkPixelGeometry;
}

// Returns true iff geo is a known geometry and is RGB.
// SkPixelGeometryIsRGB :: (geo: SkPixelGeometry) -> bool #foreign libskia "?SkPixelGeometryIsRGB@@YA_NW4SkPixelGeometry@@@Z";

// Returns true iff geo is a known geometry and is BGR.
// SkPixelGeometryIsBGR :: (geo: SkPixelGeometry) -> bool #foreign libskia "?SkPixelGeometryIsBGR@@YA_NW4SkPixelGeometry@@@Z";

// Returns true iff geo is a known geometry and is horizontal.
// SkPixelGeometryIsH :: (geo: SkPixelGeometry) -> bool #foreign libskia "?SkPixelGeometryIsH@@YA_NW4SkPixelGeometry@@@Z";

// Returns true iff geo is a known geometry and is vertical.
// SkPixelGeometryIsV :: (geo: SkPixelGeometry) -> bool #foreign libskia "?SkPixelGeometryIsV@@YA_NW4SkPixelGeometry@@@Z";

/**
*  Describes properties and constraints of a given SkSurface. The rendering engine can parse these
*  during drawing, and can sometimes optimize its performance (e.g. disabling an expensive
*  feature).
*/
SkSurfaceProps :: struct {
    Flags :: enum s32 {
        Default_Flag                   :: 0;
        UseDeviceIndependentFonts_Flag :: 1;

        DynamicMSAA_Flag               :: 2;

        AlwaysDither_Flag              :: 4;

        kDefault_Flag                   :: Default_Flag;
        kUseDeviceIndependentFonts_Flag :: UseDeviceIndependentFonts_Flag;

        kDynamicMSAA_Flag               :: DynamicMSAA_Flag;

        kAlwaysDither_Flag              :: AlwaysDither_Flag;
    }

    /** No flags, unknown pixel geometry, platform-default contrast/gamma. */
    Constructor :: (this: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkSurfaceProps@@QEAA@XZ";

    /** TODO(kschmi): Remove this constructor and replace with the one below. **/
    Constructor :: (this: *SkSurfaceProps, flags: u32, unknown0: SkPixelGeometry) -> void #cpp_method #foreign libskia "??0SkSurfaceProps@@QEAA@IW4SkPixelGeometry@@@Z";

    /** Specified pixel geometry, text contrast, and gamma **/
    Constructor :: (this: *SkSurfaceProps, flags: u32, unknown0: SkPixelGeometry, textContrast: SkScalar, textGamma: SkScalar) -> void #cpp_method #foreign libskia "??0SkSurfaceProps@@QEAA@IW4SkPixelGeometry@@MM@Z";

//     CopyConstructor :: (this: *SkSurfaceProps, unknown0: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkSurfaceProps@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkSurfaceProps, unknown0: SkSurfaceProps) #no_context {
        CopyConstructor(this, *unknown0);
    }

    cloneWithPixelGeometry :: (this: *SkSurfaceProps, newPixelGeometry: SkPixelGeometry) -> SkSurfaceProps #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?cloneWithPixelGeometry@SkSurfaceProps@@QEBA?AV1@W4SkPixelGeometry@@@Z";

    kMaxContrastInclusive: SkScalar : 1;
    kMinContrastInclusive: SkScalar : 0;
    kMaxGammaExclusive:    SkScalar : 4;
    kMinGammaInclusive:    SkScalar : 0;

    flags :: (this: *SkSurfaceProps) -> u32 #cpp_method #foreign libskia "?flags@SkSurfaceProps@@QEBAIXZ";
    pixelGeometry :: (this: *SkSurfaceProps) -> SkPixelGeometry #cpp_method #foreign libskia "?pixelGeometry@SkSurfaceProps@@QEBA?AW4SkPixelGeometry@@XZ";
    textContrast :: (this: *SkSurfaceProps) -> SkScalar #cpp_method #foreign libskia "?textContrast@SkSurfaceProps@@QEBAMXZ";
    textGamma :: (this: *SkSurfaceProps) -> SkScalar #cpp_method #foreign libskia "?textGamma@SkSurfaceProps@@QEBAMXZ";

    isUseDeviceIndependentFonts :: (this: *SkSurfaceProps) -> bool #cpp_method #foreign libskia "?isUseDeviceIndependentFonts@SkSurfaceProps@@QEBA_NXZ";

    isAlwaysDither :: (this: *SkSurfaceProps) -> bool #cpp_method #foreign libskia "?isAlwaysDither@SkSurfaceProps@@QEBA_NXZ";

    fFlags:                u32;
    fPixelGeometry:        SkPixelGeometry;

    // This gamma value is specifically about blending of mask coverage.
    // The surface also has a color space, but that applies to the colors.
    fTextContrast:         SkScalar;
    fTextGamma:            SkScalar;
}

operator_assign :: (this: *SkSurfaceProps, unknown0: *SkSurfaceProps) -> *SkSurfaceProps #cpp_method #foreign libskia "??4SkSurfaceProps@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkSurfaceProps, unknown0: SkSurfaceProps) -> *SkSurfaceProps #no_context {
    return operator_assign(this, *unknown0);
}

operator_eq :: (this: *SkSurfaceProps, that: *SkSurfaceProps) -> bool #cpp_method #foreign libskia "??8SkSurfaceProps@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkSurfaceProps, that: SkSurfaceProps) -> bool #no_context {
    return operator_eq(*this, *that);
}

operator_neq :: (this: *SkSurfaceProps, that: *SkSurfaceProps) -> bool #cpp_method #foreign libskia "??9SkSurfaceProps@@QEBA_NAEBV0@@Z";
operator_neq :: (this: SkSurfaceProps, that: SkSurfaceProps) -> bool #no_context {
    return operator_neq(*this, *that);
}

SkTileMode :: enum s32 {
    Clamp        :: 0;

    Repeat       :: 1;

    Mirror       :: 2;

    Decal        :: 3;

    LastTileMode :: 3;

    kClamp        :: Clamp;

    kRepeat       :: Repeat;

    kMirror       :: Mirror;

    kDecal        :: Decal;

    kLastTileMode :: LastTileMode;
}

kSkTileModeCount: s32 : cast(s32) (SkTileMode.LastTileMode + 1);

/*
* The deque class works by blindly creating memory space of a specified element
* size. It manages the memory as a doubly linked list of blocks each of which
* can contain multiple elements. Pushes and pops add/remove blocks from the
* beginning/end of the list as necessary while each block tracks the used
* portion of its memory.
* One behavior to be aware of is that the pops do not immediately remove an
* empty block from the beginning/end of the list (Presumably so push/pop pairs
* on the block boundaries don't cause thrashing). This can result in the first/
* last element not residing in the first/last block.
*/
SkDeque :: struct {
    /**
    * elemSize specifies the size of each individual element in the deque
    * allocCount specifies how many elements are to be allocated as a block
    */
    Constructor :: (this: *SkDeque, elemSize: u64, allocCount: s32 = 1) -> void #cpp_method #foreign libskia "??0SkDeque@@QEAA@_KH@Z";
    Constructor :: (this: *SkDeque, elemSize: u64, storage: *void, storageSize: u64, allocCount: s32 = 1) -> void #cpp_method #foreign libskia "??0SkDeque@@QEAA@_KPEAX0H@Z";
    Destructor :: (this: *SkDeque) -> void #cpp_method #foreign libskia "??1SkDeque@@QEAA@XZ";

    empty :: (this: *SkDeque) -> bool #cpp_method #foreign libskia "?empty@SkDeque@@QEBA_NXZ";
    count :: (this: *SkDeque) -> s32 #cpp_method #foreign libskia "?count@SkDeque@@QEBAHXZ";
    elemSize :: (this: *SkDeque) -> u64 #cpp_method #foreign libskia "?elemSize@SkDeque@@QEBA_KXZ";

    front :: (this: /*const*/ *SkDeque) -> *void #cpp_method #foreign libskia "?front@SkDeque@@QEBAPEBXXZ";
    back :: (this: /*const*/ *SkDeque) -> *void #cpp_method #foreign libskia "?back@SkDeque@@QEBAPEBXXZ";

    front_1 :: (this: *SkDeque) -> *void #cpp_method #foreign libskia "?front@SkDeque@@QEAAPEAXXZ";
    back_1 :: (this: *SkDeque) -> *void #cpp_method #foreign libskia "?back@SkDeque@@QEAAPEAXXZ";

    /**
    * push_front and push_back return a pointer to the memory space
    * for the new element
    */
    push_front :: (this: *SkDeque) -> *void #cpp_method #foreign libskia "?push_front@SkDeque@@QEAAPEAXXZ";
    push_back :: (this: *SkDeque) -> *void #cpp_method #foreign libskia "?push_back@SkDeque@@QEAAPEAXXZ";

    pop_front :: (this: *SkDeque) -> void #cpp_method #foreign libskia "?pop_front@SkDeque@@QEAAXXZ";
    pop_back :: (this: *SkDeque) -> void #cpp_method #foreign libskia "?pop_back@SkDeque@@QEAAXXZ";

    Block :: struct {}

    Iter :: struct {
        IterStart :: enum s32 {
            Front_IterStart :: 0;
            Back_IterStart  :: 1;

            kFront_IterStart :: Front_IterStart;
            kBack_IterStart  :: Back_IterStart;
        }

        /**
        * Creates an uninitialized iterator. Must be reset()
        */
//         Constructor :: (this: *Iter) -> void #cpp_method #foreign libskia "??0Iter@SkDeque@@QEAA@XZ";

//         Constructor :: (this: *Iter, d: *SkDeque, startLoc: IterStart) -> void #cpp_method #foreign libskia "??0Iter@SkDeque@@QEAA@AEBV1@W4IterStart@01@@Z";
        Constructor :: (this: *Iter, d: SkDeque, startLoc: IterStart) #no_context {
            Constructor(this, *d, startLoc);
        }
//         next :: (this: *Iter) -> *void #cpp_method #foreign libskia "?next@Iter@SkDeque@@QEAAPEAXXZ";
//         prev :: (this: *Iter) -> *void #cpp_method #foreign libskia "?prev@Iter@SkDeque@@QEAAPEAXXZ";

//         reset :: (this: *Iter, d: *SkDeque, startLoc: IterStart) -> void #cpp_method #foreign libskia "?reset@Iter@SkDeque@@QEAAXAEBV2@W4IterStart@12@@Z";
        reset :: (this: *Iter, d: SkDeque, startLoc: IterStart) #no_context {
            reset(this, *d, startLoc);
        }

        fCurBlock: *Block;
        fPos:      *u8;
        fElemSize: u64;
    }

    // Inherit privately from Iter to prevent access to reverse iteration
    F2BIter :: struct {
        #as using iter: Iter;

//         Constructor :: (this: *F2BIter) -> void #cpp_method #foreign libskia "??0F2BIter@SkDeque@@QEAA@XZ";

        /**
        * Wrap Iter's 2 parameter ctor to force initialization to the
        * beginning of the deque
        */
//         Constructor :: (this: *F2BIter, d: *SkDeque) -> void #cpp_method #foreign libskia "??0F2BIter@SkDeque@@QEAA@AEBV1@@Z";
        Constructor :: (this: *F2BIter, d: SkDeque) #no_context {
            Constructor(this, *d);
        }

        /**
        * Wrap Iter::reset to force initialization to the beginning of the
        * deque
        */
//         reset :: (this: *F2BIter, d: *SkDeque) -> void #cpp_method #foreign libskia "?reset@F2BIter@SkDeque@@QEAAXAEBV2@@Z";
        reset :: (this: *F2BIter, d: SkDeque) #no_context {
            reset(this, *d);
        }

        INHERITED :: Iter;
    }

    fFront:          *void;
    fBack:           *void;

    fFrontBlock:     *Block;
    fBackBlock:      *Block;
    fElemSize:       u64;
    fInitialStorage: *void;
    fCount:          s32; // number of elements in the deque
    fAllocCount:     s32; // number of elements to allocate per block

    allocateBlock :: (this: *SkDeque, allocCount: s32) -> *Block #cpp_method #foreign libskia "?allocateBlock@SkDeque@@AEAAPEAUBlock@1@H@Z";
    freeBlock :: (this: *SkDeque, block: *Block) -> void #cpp_method #foreign libskia "?freeBlock@SkDeque@@AEAAXPEAUBlock@1@@Z";

    /**
    * This returns the number of chunk blocks allocated by the deque. It
    * can be used to gauge the effectiveness of the selected allocCount.
    */
    numBlocksAllocated :: (this: *SkDeque) -> s32 #cpp_method #foreign libskia "?numBlocksAllocated@SkDeque@@AEBAHXZ";

//     CopyConstructor :: (this: *SkDeque, unknown0: *SkDeque) -> void #cpp_method #foreign libskia "??0SkDeque@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkDeque, unknown0: SkDeque) #no_context {
        CopyConstructor(this, *unknown0);
    }
}
// operator_assign :: (this: *SkDeque, unknown0: *SkDeque) -> *SkDeque #cpp_method #foreign libskia "??4SkDeque@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkDeque, unknown0: SkDeque) -> *SkDeque #no_context {
    return operator_assign(this, *unknown0);
}

// Code that implements bespoke allocation arenas can poison the entire arena on creation, then
// unpoison chunks of arena memory as they are parceled out. Consider leaving gaps between blocks
// to detect buffer overrun.
// sk_asan_poison_memory_region :: (addr: *void, size: u64) -> void #foreign libskia "?sk_asan_poison_memory_region@@YAXPEDX_K@Z";

// sk_asan_unpoison_memory_region :: (addr: *void, size: u64) -> void #foreign libskia "?sk_asan_unpoison_memory_region@@YAXPEDX_K@Z";

// sk_asan_address_is_poisoned :: (addr: *void) -> s32 #foreign libskia "?sk_asan_address_is_poisoned@@YAHPEDX@Z";

SkAlignedSTStorage :: struct(N: s32, T: Type) {
    using,except(N, T) skalignedststorage__raw: SkAlignedSTStorage__RAW(N, T);
    #if size_of(SkAlignedSTStorage__RAW(N, T)) == 0 {
        __empty_struct_padding:  u8; // C++ makes empty structs have length 1
    }
}
// SkAlignedSTStorage without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkAlignedSTStorage
SkAlignedSTStorage__RAW :: struct(N: s32, T: Type) {}

SkContainerAllocator :: struct {
    Constructor :: (this: *SkContainerAllocator, sizeOfT: u64, maxCapacity: s32) -> void #cpp_method #foreign libskia "??0SkContainerAllocator@@QEAA@_KH@Z";

    // allocate will abort on failure. Given a capacity of 0, it will return the empty span.
    // The bytes allocated are freed using sk_free().
    allocate :: (this: *SkContainerAllocator, capacity: s32, growthFactor: float64 = 1.0) -> SkSpan(std.byte) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?allocate@SkContainerAllocator@@QEAA?AV?$SkSpan@W4byte@std@@@@HN@Z";

    // All capacity counts will be rounded up to kCapacityMultiple. This matches ASAN's shadow
    // granularity, as well as our typical struct alignment on a 64-bit machine.
    kCapacityMultiple: s64 : 8;

    // Rounds up capacity to next multiple of kCapacityMultiple and pin to fMaxCapacity.
    roundUpCapacity :: (this: *SkContainerAllocator, capacity: s64) -> u64 #cpp_method #foreign libskia "?roundUpCapacity@SkContainerAllocator@@AEBA_K_J@Z";

    // Grows the capacity by growthFactor being sure to stay with in kMinBytes and fMaxCapacity.
    growthFactorCapacity :: (this: *SkContainerAllocator, capacity: s32, growthFactor: float64) -> u64 #cpp_method #foreign libskia "?growthFactorCapacity@SkContainerAllocator@@AEBA_KHN@Z";
}

// sk_allocate_canfail returns the empty span on failure. Parameter size must be > 0.
// sk_allocate_canfail :: (size: u64) -> SkSpan(std.byte) #cpp_return_type_is_non_pod #foreign libskia "?sk_allocate_canfail@@YA?AV?$SkSpan@W4byte@std@@@@_K@Z";

// Returns the empty span if size is 0. sk_allocate_throw aborts on failure.
// sk_allocate_throw :: (size: u64) -> SkSpan(std.byte) #cpp_return_type_is_non_pod #foreign libskia "?sk_allocate_throw@@YA?AV?$SkSpan@W4byte@std@@@@_K@Z";

sk_report_container_overflow_and_die :: () -> void #foreign libskia "?sk_report_container_overflow_and_die@@YAXXZ";

/** Free memory returned by sk_malloc(). It is safe to pass null. */
sk_free :: (unknown0: *void) -> void #foreign libskia "?sk_free@@YAXPEAX@Z";

/**
*  Called internally if we run out of memory. The platform implementation must
*  not return, but should either throw an exception or otherwise exit.
*/
sk_out_of_memory :: () -> void #foreign libskia "?sk_out_of_memory@@YAXXZ";

SK_MALLOC :: enum s32 {
    ZERO_INITIALIZE :: 1;

    THROW           :: 2;

    SK_MALLOC_ZERO_INITIALIZE :: ZERO_INITIALIZE;

    SK_MALLOC_THROW           :: THROW;
}

/**
*  Return a block of memory (at least 4-byte aligned) of at least the specified size.
*  If the requested memory cannot be returned, either return nullptr or throw/exit, depending
*  on the SK_MALLOC_THROW bit. If the allocation succeeds, the memory will be zero-initialized
*  if the SK_MALLOC_ZERO_INITIALIZE bit was set.
*
*  To free the memory, call sk_free()
*/
sk_malloc_flags :: (size: u64, flags: u32) -> *void #foreign libskia "?sk_malloc_flags@@YAPEAX_KI@Z";

/** Same as standard realloc(), but this one never returns null on failure. It will throw
*  if it fails.
*  If size is 0, it will call sk_free on buffer and return null. (This behavior is implementation-
*  defined for normal realloc. We follow what glibc does.)
*/
sk_realloc_throw :: (buffer: *void, size: u64) -> *void #foreign libskia "?sk_realloc_throw@@YAPEAXPEAX_K@Z";

/**
*  Return the size of the block of memory allocated in reality for a given pointer. The pointer
*  passed must have been allocated using the sk_malloc_* or sk_realloc_* functions. The "size"
*  parameter indicates the size originally requested when the memory block was allocated, and
*  the value returned by this function must be bigger or equal to it.
*/
sk_malloc_size :: (addr: *void, size: u64) -> u64 #foreign libskia "?sk_malloc_size@@YA_KPEAX_K@Z";

// sk_malloc_throw :: (size: u64) -> *void #foreign libskia "?sk_malloc_throw@@YAPEAX_K@Z";

// sk_calloc_throw :: (size: u64) -> *void #foreign libskia "?sk_calloc_throw@@YAPEAX_K@Z";

// sk_calloc_canfail :: (size: u64) -> *void #foreign libskia "?sk_calloc_canfail@@YAPEAX_K@Z";

// Performs a safe multiply count * elemSize, checking for overflow
sk_calloc_throw :: (count: u64, elemSize: u64) -> *void #foreign libskia "?sk_calloc_throw@@YAPEAX_K0@Z";
sk_malloc_throw :: (count: u64, elemSize: u64) -> *void #foreign libskia "?sk_malloc_throw@@YAPEAX_K0@Z";
sk_realloc_throw :: (buffer: *void, count: u64, elemSize: u64) -> *void #foreign libskia "?sk_realloc_throw@@YAPEAXPEAX_K1@Z";

/**
*  These variants return nullptr on failure
*/
// sk_malloc_canfail :: (size: u64) -> *void #foreign libskia "?sk_malloc_canfail@@YAPEAX_K@Z";

sk_malloc_canfail :: (count: u64, elemSize: u64) -> *void #foreign libskia "?sk_malloc_canfail@@YAPEAX_K0@Z";

// bzero is safer than memset, but we can't rely on it, so... sk_bzero()
// sk_bzero :: (buffer: *void, size: u64) -> void #foreign libskia "?sk_bzero@@YAXPEAX_K@Z";

/**
*  sk_careful_memcpy() is just like memcpy(), but guards against undefined behavior.
*
* It is undefined behavior to call memcpy() with null dst or src, even if len is 0.
* If an optimizer is "smart" enough, it can exploit this to do unexpected things.
*     memcpy(dst, src, 0);
*     if (src) {
*         printf("%x\n", *src);
*     }
* In this code the compiler can assume src is not null and omit the if (src) {...} check,
* unconditionally running the printf, crashing the program if src really is null.
* Of the compilers we pay attention to only GCC performs this optimization in practice.
*/
// sk_careful_memcpy :: (dst: *void, src: *void, len: u64) -> *void #foreign libskia "?sk_careful_memcpy@@YAPEAXPEAXPEBX_K@Z";

// sk_careful_memmove :: (dst: *void, src: *void, len: u64) -> *void #foreign libskia "?sk_careful_memmove@@YAPEAXPEAXPEBX_K@Z";

// sk_careful_memcmp :: (a: *void, b: *void, len: u64) -> s32 #foreign libskia "?sk_careful_memcmp@@YAHPEBX0_K@Z";

skia_private :: struct {
    /** TArray<T> implements a typical, mostly std::vector-like array.
    Each T will be default-initialized on allocation, and ~T will be called on destruction.
    
    MEM_MOVE controls the behavior when a T needs to be moved (e.g. when the array is resized)
    - true: T will be bit-copied via memcpy.
    - false: T will be moved via move-constructors.
    */
    TArray :: struct(T: Type, MEM_MOVE: bool) {
        value_type :: T;

        // Growth factors for checkRealloc.
        kExactFit:          float64 : 1.0;
        kGrowing:           float64 : 1.5;

        kMinHeapAllocCount: s32 : 8;

        fData:              *T;
        fSize:              s32;
        __bitfield:         u32;
        /* 
            fOwnMemory: u32; /* 1 bits */
            fCapacity: u32; /* 31 bits */;
        */
    }

    // Subclass of TArray that contains a pre-allocated memory block for the array.
    STArray :: struct(Nreq: s32, T: Type, MEM_MOVE: bool) {
        using,except(T) skalignedststorage__raw: SkAlignedSTStorage__RAW(Nreq, T);
        #as using,except(T, MEM_MOVE) tarray:              TArray(T, MEM_MOVE);

        Storage :: SkAlignedSTStorage(Nreq, T);
        #place skalignedststorage__raw; #as skalignedststorage: SkAlignedSTStorage(Nreq, T); // Support cast to SkAlignedSTStorage
    }

    /** Allocate an array of T elements on the heap. Once this goes out of scope, the
    *  elements will be cleaned up "auto"matically.
    */
    AutoTArray :: struct(T: Type) {
        fSize: u64 = 0;
    }

    /** Like AutoTArray with storage for some number of elements "nested within". The requested number
    *  of elements to fit in the storage is specified by kCountRequested. kCount is the actual number
    *  of elements that will fit in the storage. If the runtime number of elements exceeds the space of
    *  the storage, the elements will live on the heap.
    */
    AutoSTArray :: struct(kCountRequested: s32, T: Type) {
        kMinCount: s32 : kCountRequested;

        fArray:    *T;

        fCount:    s32;
    }

    /** Manages an array of T elements, freeing the array in the destructor.
    *  Does NOT call any constructors/destructors on T (T must be POD).
    */
    AutoTMalloc :: struct(T: Type, _1: Type = enable_if_t(PlaceholderForUnsupportedArgument)) {
        fPtr: std.unique_ptr(T, SkOverloadedFunctionObject(#type (unknown0: *void) -> void #c_call, UnknownTemplateArgumentPlaceholder));
    }

    AutoSTMalloc :: struct(kCountRequested: u64, T: Type, _1: Type = enable_if_t(PlaceholderForUnsupportedArgument)) {
        fPtr: *T;
        union {
            fTStorage: [1] T; // do NOT want to invoke T::T()
        }
    }

    UniqueVoidPtr :: std.unique_ptr(void, SkOverloadedFunctionObject(#type (unknown0: *void) -> void #c_call, UnknownTemplateArgumentPlaceholder));
}

sktext :: struct {
    GlyphRunBuilder :: struct {}
    GlyphRunList :: struct {}

    gpu :: struct {
        Slug :: struct {}
    }
}

AutoLayerForImageFilter :: struct {}
GrRecordingContext :: struct {}

SkBlurMaskFilterImpl :: struct {}

SkDevice :: struct {}
SkDrawable :: struct {}

SkMesh :: struct {}
SkPaintFilterCanvas :: struct {}

SkPicture :: struct {}

SkRRect :: struct {}
SkRegion :: struct {}
SkRecorder :: struct {}

SkSpecialImage :: struct {}

SkSurface_Base :: struct {}

SkVertices :: struct {}
SkDrawShadowRec :: struct {}

SkEnumBitMask :: struct(E: Type) {
    using,except(E) skenumbitmask__raw:     SkEnumBitMask__RAW(E);
    #if size_of(SkEnumBitMask__RAW(E)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// SkEnumBitMask without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkEnumBitMask
SkEnumBitMask__RAW :: struct(E: Type) {}

skgpu :: struct {
    graphite :: struct {
        Recorder :: struct {}
    }
}

SkRecords :: struct {
    Draw :: struct {}
}
skiatest :: struct {
    TestCanvas :: struct(Key: Type) {
        using,except(Key) testcanvas__raw:        TestCanvas__RAW(Key);
        #if size_of(TestCanvas__RAW(Key)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // TestCanvas without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from TestCanvas
    TestCanvas__RAW :: struct(Key: Type) {}
}

/** \class SkCanvas
SkCanvas provides an interface for drawing, and how the drawing is clipped and transformed.
SkCanvas contains a stack of SkMatrix and clip values.

SkCanvas and SkPaint together provide the state to draw into SkSurface or SkDevice.
Each SkCanvas draw call transforms the geometry of the object by the concatenation of all
SkMatrix values in the stack. The transformed geometry is clipped by the intersection
of all of clip values in the stack. The SkCanvas draw calls use SkPaint to supply drawing
state such as color, SkTypeface, text size, stroke width, SkShader and so on.

To draw to a pixel-based destination, create raster surface or GPU surface.
Request SkCanvas from SkSurface to obtain the interface to draw.
SkCanvas generated by raster surface draws to memory visible to the CPU.
SkCanvas generated by GPU surface uses Vulkan or OpenGL to draw to the GPU.

To draw to a document, obtain SkCanvas from SVG canvas, document PDF, or SkPictureRecorder.
SkDocument based SkCanvas and other SkCanvas subclasses reference SkDevice describing the
destination.

SkCanvas can be constructed to draw to SkBitmap without first creating raster surface.
This approach may be deprecated in the future.
*/
SkCanvas :: struct {
    vtable:              *SkCanvas_VTable;
    using skcanvas__raw: SkCanvas__RAW;
}
// SkCanvas without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkCanvas
SkCanvas__RAW :: struct {
    /** Allocates raster SkCanvas that will draw directly into pixels.
    
    SkCanvas is returned if all parameters are valid.
    Valid parameters include:
    info dimensions are zero or positive;
    info contains SkColorType and SkAlphaType supported by raster surface;
    pixels is not nullptr;
    rowBytes is zero or large enough to contain info width pixels of SkColorType.
    
    Pass zero for rowBytes to compute rowBytes from info width and size of pixel.
    If rowBytes is greater than zero, it must be equal to or greater than
    info width times bytes required for SkColorType.
    
    Pixel buffer size should be info height times computed rowBytes.
    Pixels are not initialized.
    To access pixels after drawing, call flush() or peekPixels().
    
    @param info      width, height, SkColorType, SkAlphaType, SkColorSpace, of raster surface;
    width, or height, or both, may be zero
    @param pixels    pointer to destination pixels buffer
    @param rowBytes  interval from one SkSurface row to the next, or zero
    @param props     LCD striping orientation and setting for device independent fonts;
    may be nullptr
    @return          SkCanvas if all parameters are valid; otherwise, nullptr
    */
    MakeRasterDirect :: (info: *SkImageInfo, pixels: *void, rowBytes: u64, props: *SkSurfaceProps = null) -> std.unique_ptr(SkCanvas) #cpp_return_type_is_non_pod #foreign libskia "?MakeRasterDirect@SkCanvas@@SA?AV?$unique_ptr@VSkCanvas@@U?$default_delete@VSkCanvas@@@std@@@std@@AEBUSkImageInfo@@PEAX_KPEBVSkSurfaceProps@@@Z";
    MakeRasterDirect :: (info: SkImageInfo, pixels: *void, rowBytes: u64, props: *SkSurfaceProps = null) -> std.unique_ptr(SkCanvas) #no_context {
        return MakeRasterDirect(*info, pixels, rowBytes, props);
    }

    /** Allocates raster SkCanvas specified by inline image specification. Subsequent SkCanvas
    calls draw into pixels.
    SkColorType is set to kN32_SkColorType.
    SkAlphaType is set to kPremul_SkAlphaType.
    To access pixels after drawing, call flush() or peekPixels().
    
    SkCanvas is returned if all parameters are valid.
    Valid parameters include:
    width and height are zero or positive;
    pixels is not nullptr;
    rowBytes is zero or large enough to contain width pixels of kN32_SkColorType.
    
    Pass zero for rowBytes to compute rowBytes from width and size of pixel.
    If rowBytes is greater than zero, it must be equal to or greater than
    width times bytes required for SkColorType.
    
    Pixel buffer size should be height times rowBytes.
    
    @param width     pixel column count on raster surface created; must be zero or greater
    @param height    pixel row count on raster surface created; must be zero or greater
    @param pixels    pointer to destination pixels buffer; buffer size should be height
    times rowBytes
    @param rowBytes  interval from one SkSurface row to the next, or zero
    @return          SkCanvas if all parameters are valid; otherwise, nullptr
    */
    MakeRasterDirectN32 :: (width: s32, height: s32, pixels: *SkPMColor, rowBytes: u64) -> std.unique_ptr(SkCanvas) #cpp_return_type_is_non_pod #foreign libskia "?MakeRasterDirectN32@SkCanvas@@SA?AV?$unique_ptr@VSkCanvas@@U?$default_delete@VSkCanvas@@@std@@@std@@HHPEAI_K@Z";

    /** Creates an empty SkCanvas with no backing device or pixels, with
    a width and height of zero.
    
    @return  empty SkCanvas
    
    example: https://fiddle.skia.org/c/@Canvas_empty_constructor
    */
    Constructor :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "??0SkCanvas@@QEAA@XZ";

    /** Creates SkCanvas of the specified dimensions without a SkSurface.
    Used by subclasses with custom implementations for draw member functions.
    
    If props equals nullptr, SkSurfaceProps are created with
    SkSurfaceProps::InitType settings, which choose the pixel striping
    direction and order. Since a platform may dynamically change its direction when
    the device is rotated, and since a platform may have multiple monitors with
    different characteristics, it is best not to rely on this legacy behavior.
    
    @param width   zero or greater
    @param height  zero or greater
    @param props   LCD striping orientation and setting for device independent fonts;
    may be nullptr
    @return        SkCanvas placeholder with dimensions
    
    example: https://fiddle.skia.org/c/@Canvas_int_int_const_SkSurfaceProps_star
    */
    Constructor :: (this: *SkCanvas, width: s32, height: s32, props: *SkSurfaceProps = null) -> void #cpp_method #foreign libskia "??0SkCanvas@@QEAA@HHPEBVSkSurfaceProps@@@Z";

    /** Private. For internal use only.
    */
    Constructor :: (this: *SkCanvas, device: sk_sp(SkDevice)) -> void #cpp_method #foreign libskia "??0SkCanvas@@QEAA@V?$sk_sp@VSkDevice@@@@@Z";

    /** Constructs a canvas that draws into bitmap.
    Sets kUnknown_SkPixelGeometry in constructed SkSurface.
    
    SkBitmap is copied so that subsequently editing bitmap will not affect
    constructed SkCanvas.
    
    May be deprecated in the future.
    
    @param bitmap  width, height, SkColorType, SkAlphaType, and pixel
    storage of raster surface
    @return        SkCanvas that can be used to draw into bitmap
    
    example: https://fiddle.skia.org/c/@Canvas_copy_const_SkBitmap
    */
    Constructor :: (this: *SkCanvas, bitmap: *SkBitmap) -> void #cpp_method #foreign libskia "??0SkCanvas@@QEAA@AEBVSkBitmap@@@Z";
    Constructor :: (this: *SkCanvas, bitmap: SkBitmap) #no_context {
        Constructor(this, *bitmap);
    }

    /** Constructs a canvas that draws into bitmap.
    Use props to match the device characteristics, like LCD striping.
    
    bitmap is copied so that subsequently editing bitmap will not affect
    constructed SkCanvas.
    
    @param bitmap  width, height, SkColorType, SkAlphaType,
    and pixel storage of raster surface
    @param props   order and orientation of RGB striping; and whether to use
    device independent fonts
    @return        SkCanvas that can be used to draw into bitmap
    
    example: https://fiddle.skia.org/c/@Canvas_const_SkBitmap_const_SkSurfaceProps
    */
    Constructor :: (this: *SkCanvas, bitmap: *SkBitmap, props: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkCanvas@@QEAA@AEBVSkBitmap@@AEBVSkSurfaceProps@@@Z";
    Constructor :: (this: *SkCanvas, bitmap: SkBitmap, props: SkSurfaceProps) #no_context {
        Constructor(this, *bitmap, *props);
    }

    /** Returns SkImageInfo for SkCanvas. If SkCanvas is not associated with raster surface or
    GPU surface, returned SkColorType is set to kUnknown_SkColorType.
    
    @return  dimensions and SkColorType of SkCanvas
    
    example: https://fiddle.skia.org/c/@Canvas_imageInfo
    */
    imageInfo :: (this: *SkCanvas) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?imageInfo@SkCanvas@@QEBA?AUSkImageInfo@@XZ";

    /** Copies SkSurfaceProps, if SkCanvas is associated with raster surface or
    GPU surface, and returns true. Otherwise, returns false and leave props unchanged.
    
    @param props  storage for writable SkSurfaceProps
    @return       true if SkSurfaceProps was copied
    
    DEPRECATED: Replace usage with getBaseProps() or getTopProps()
    
    example: https://fiddle.skia.org/c/@Canvas_getProps
    */
    getProps :: (this: *SkCanvas, props: *SkSurfaceProps) -> bool #cpp_method #foreign libskia "?getProps@SkCanvas@@QEBA_NPEAVSkSurfaceProps@@@Z";

    /** Returns the SkSurfaceProps associated with the canvas (i.e., at the base of the layer
    stack).
    
    @return  base SkSurfaceProps
    */
    getBaseProps :: (this: *SkCanvas) -> SkSurfaceProps #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getBaseProps@SkCanvas@@QEBA?AVSkSurfaceProps@@XZ";

    /** Returns the SkSurfaceProps associated with the canvas that are currently active (i.e., at
    the top of the layer stack). This can differ from getBaseProps depending on the flags
    passed to saveLayer (see SaveLayerFlagsSet).
    
    @return  SkSurfaceProps active in the current/top layer
    */
    getTopProps :: (this: *SkCanvas) -> SkSurfaceProps #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getTopProps@SkCanvas@@QEBA?AVSkSurfaceProps@@XZ";

    /** Creates SkSurface matching info and props, and associates it with SkCanvas.
    Returns nullptr if no match found.
    
    If props is nullptr, matches SkSurfaceProps in SkCanvas. If props is nullptr and SkCanvas
    does not have SkSurfaceProps, creates SkSurface with default SkSurfaceProps.
    
    @param info   width, height, SkColorType, SkAlphaType, and SkColorSpace
    @param props  SkSurfaceProps to match; may be nullptr to match SkCanvas
    @return       SkSurface matching info and props, or nullptr if no match is available
    
    example: https://fiddle.skia.org/c/@Canvas_makeSurface
    */
    makeSurface :: (this: *SkCanvas, info: *SkImageInfo, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeSurface@SkCanvas@@QEAA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@PEBVSkSurfaceProps@@@Z";
    makeSurface :: (this: *SkCanvas, info: SkImageInfo, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #no_context {
        return makeSurface(this, *info, props);
    }

    /** Sometimes a canvas is owned by a surface. If it is, getSurface() will return a bare
    *  pointer to that surface, else this will return nullptr.
    */
    getSurface :: (this: *SkCanvas) -> *SkSurface #cpp_method #foreign libskia "?getSurface@SkCanvas@@QEBAPEAVSkSurface@@XZ";

    /** Returns the pixel base address, SkImageInfo, rowBytes, and origin if the pixels
    can be read directly. The returned address is only valid
    while SkCanvas is in scope and unchanged. Any SkCanvas call or SkSurface call
    may invalidate the returned address and other returned values.
    
    If pixels are inaccessible, info, rowBytes, and origin are unchanged.
    
    @param info      storage for writable pixels' SkImageInfo; may be nullptr
    @param rowBytes  storage for writable pixels' row bytes; may be nullptr
    @param origin    storage for SkCanvas top layer origin, its top-left corner;
    may be nullptr
    @return          address of pixels, or nullptr if inaccessible
    
    example: https://fiddle.skia.org/c/@Canvas_accessTopLayerPixels_a
    example: https://fiddle.skia.org/c/@Canvas_accessTopLayerPixels_b
    */
    accessTopLayerPixels :: (this: *SkCanvas, info: *SkImageInfo, rowBytes: *u64, origin: *SkIPoint = null) -> *void #cpp_method #foreign libskia "?accessTopLayerPixels@SkCanvas@@QEAAPEAXPEAUSkImageInfo@@PEA_KPEAUSkIPoint@@@Z";

    /** Returns custom context that tracks the SkMatrix and clip.
    
    Use SkRasterHandleAllocator to blend Skia drawing with custom drawing, typically performed
    by the host platform user interface. The custom context returned is generated by
    SkRasterHandleAllocator::MakeCanvas, which creates a custom canvas with raster storage for
    the drawing destination.
    
    @return  context of custom allocation
    
    example: https://fiddle.skia.org/c/@Canvas_accessTopRasterHandle
    */
    accessTopRasterHandle :: (this: *SkCanvas) -> SkRasterHandleAllocator.Handle #cpp_method #foreign libskia "?accessTopRasterHandle@SkCanvas@@QEBAPEAXXZ";

    /** Returns true if SkCanvas has direct access to its pixels.
    
    Pixels are readable when SkDevice is raster. Pixels are not readable when SkCanvas
    is returned from GPU surface, returned by SkDocument::beginPage, returned by
    SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility class
    like DebugCanvas.
    
    pixmap is valid only while SkCanvas is in scope and unchanged. Any
    SkCanvas or SkSurface call may invalidate the pixmap values.
    
    @param pixmap  storage for pixel state if pixels are readable; otherwise, ignored
    @return        true if SkCanvas has direct access to pixels
    
    example: https://fiddle.skia.org/c/@Canvas_peekPixels
    */
    peekPixels :: (this: *SkCanvas, pixmap: *SkPixmap) -> bool #cpp_method #foreign libskia "?peekPixels@SkCanvas@@QEAA_NPEAVSkPixmap@@@Z";

    /** Copies SkRect of pixels from SkCanvas into dstPixels. SkMatrix and clip are
    ignored.
    
    Source SkRect corners are (srcX, srcY) and (imageInfo().width(), imageInfo().height()).
    Destination SkRect corners are (0, 0) and (dstInfo.width(), dstInfo.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to dstInfo.colorType() and dstInfo.alphaType() if required.
    
    Pixels are readable when SkDevice is raster, or backed by a GPU.
    Pixels are not readable when SkCanvas is returned by SkDocument::beginPage,
    returned by SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility
    class like DebugCanvas.
    
    The destination pixel storage must be allocated by the caller.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. dstPixels contents outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down destination.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkCanvas pixels could not be converted to dstInfo.colorType() or dstInfo.alphaType().
    - SkCanvas pixels are not readable; for instance, SkCanvas is document-based.
    - dstRowBytes is too small to contain one row of pixels.
    
    @param dstInfo      width, height, SkColorType, and SkAlphaType of dstPixels
    @param dstPixels    storage for pixels; dstInfo.height() times dstRowBytes, or larger
    @param dstRowBytes  size of one destination row; dstInfo.width() times pixel size, or larger
    @param srcX         offset into readable pixels on x-axis; may be negative
    @param srcY         offset into readable pixels on y-axis; may be negative
    @return             true if pixels were copied
    */
    readPixels :: (this: *SkCanvas, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkCanvas@@QEAA_NAEBUSkImageInfo@@PEAX_KHH@Z";
    readPixels :: (this: *SkCanvas, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dstInfo, dstPixels, dstRowBytes, srcX, srcY);
    }

    /** Copies SkRect of pixels from SkCanvas into pixmap. SkMatrix and clip are
    ignored.
    
    Source SkRect corners are (srcX, srcY) and (imageInfo().width(), imageInfo().height()).
    Destination SkRect corners are (0, 0) and (pixmap.width(), pixmap.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to pixmap.colorType() and pixmap.alphaType() if required.
    
    Pixels are readable when SkDevice is raster, or backed by a GPU.
    Pixels are not readable when SkCanvas is returned by SkDocument::beginPage,
    returned by SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility
    class like DebugCanvas.
    
    Caller must allocate pixel storage in pixmap if needed.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination SkRect
    are copied. pixmap pixels contents outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down pixmap.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkCanvas pixels could not be converted to pixmap.colorType() or pixmap.alphaType().
    - SkCanvas pixels are not readable; for instance, SkCanvas is document-based.
    - SkPixmap pixels could not be allocated.
    - pixmap.rowBytes() is too small to contain one row of pixels.
    
    @param pixmap  storage for pixels copied from SkCanvas
    @param srcX    offset into readable pixels on x-axis; may be negative
    @param srcY    offset into readable pixels on y-axis; may be negative
    @return        true if pixels were copied
    
    example: https://fiddle.skia.org/c/@Canvas_readPixels_2
    */
    readPixels :: (this: *SkCanvas, pixmap: *SkPixmap, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkCanvas@@QEAA_NAEBVSkPixmap@@HH@Z";
    readPixels :: (this: *SkCanvas, pixmap: SkPixmap, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *pixmap, srcX, srcY);
    }

    /** Copies SkRect of pixels from SkCanvas into bitmap. SkMatrix and clip are
    ignored.
    
    Source SkRect corners are (srcX, srcY) and (imageInfo().width(), imageInfo().height()).
    Destination SkRect corners are (0, 0) and (bitmap.width(), bitmap.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to bitmap.colorType() and bitmap.alphaType() if required.
    
    Pixels are readable when SkDevice is raster, or backed by a GPU.
    Pixels are not readable when SkCanvas is returned by SkDocument::beginPage,
    returned by SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility
    class like DebugCanvas.
    
    Caller must allocate pixel storage in bitmap if needed.
    
    SkBitmap values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. SkBitmap pixels outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down bitmap.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkCanvas pixels could not be converted to bitmap.colorType() or bitmap.alphaType().
    - SkCanvas pixels are not readable; for instance, SkCanvas is document-based.
    - bitmap pixels could not be allocated.
    - bitmap.rowBytes() is too small to contain one row of pixels.
    
    @param bitmap  storage for pixels copied from SkCanvas
    @param srcX    offset into readable pixels on x-axis; may be negative
    @param srcY    offset into readable pixels on y-axis; may be negative
    @return        true if pixels were copied
    
    example: https://fiddle.skia.org/c/@Canvas_readPixels_3
    */
    readPixels :: (this: *SkCanvas, bitmap: *SkBitmap, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkCanvas@@QEAA_NAEBVSkBitmap@@HH@Z";
    readPixels :: (this: *SkCanvas, bitmap: SkBitmap, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *bitmap, srcX, srcY);
    }

    /** Copies SkRect from pixels to SkCanvas. SkMatrix and clip are ignored.
    Source SkRect corners are (0, 0) and (info.width(), info.height()).
    Destination SkRect corners are (x, y) and
    (imageInfo().width(), imageInfo().height()).
    
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to imageInfo().colorType() and imageInfo().alphaType() if required.
    
    Pixels are writable when SkDevice is raster, or backed by a GPU.
    Pixels are not writable when SkCanvas is returned by SkDocument::beginPage,
    returned by SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility
    class like DebugCanvas.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. SkCanvas pixels outside SkRect intersection are unchanged.
    
    Pass negative values for x or y to offset pixels to the left or
    above SkCanvas pixels.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - pixels could not be converted to SkCanvas imageInfo().colorType() or
    imageInfo().alphaType().
    - SkCanvas pixels are not writable; for instance, SkCanvas is document-based.
    - rowBytes is too small to contain one row of pixels.
    
    @param info      width, height, SkColorType, and SkAlphaType of pixels
    @param pixels    pixels to copy, of size info.height() times rowBytes, or larger
    @param rowBytes  size of one row of pixels; info.width() times pixel size, or larger
    @param x         offset into SkCanvas writable pixels on x-axis; may be negative
    @param y         offset into SkCanvas writable pixels on y-axis; may be negative
    @return          true if pixels were written to SkCanvas
    
    example: https://fiddle.skia.org/c/@Canvas_writePixels
    */
    writePixels :: (this: *SkCanvas, info: *SkImageInfo, pixels: *void, rowBytes: u64, x: s32, y: s32) -> bool #cpp_method #foreign libskia "?writePixels@SkCanvas@@QEAA_NAEBUSkImageInfo@@PEBX_KHH@Z";
    writePixels :: (this: *SkCanvas, info: SkImageInfo, pixels: *void, rowBytes: u64, x: s32, y: s32) -> bool #no_context {
        return writePixels(this, *info, pixels, rowBytes, x, y);
    }

    /** Copies SkRect from pixels to SkCanvas. SkMatrix and clip are ignored.
    Source SkRect corners are (0, 0) and (bitmap.width(), bitmap.height()).
    
    Destination SkRect corners are (x, y) and
    (imageInfo().width(), imageInfo().height()).
    
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to imageInfo().colorType() and imageInfo().alphaType() if required.
    
    Pixels are writable when SkDevice is raster, or backed by a GPU.
    Pixels are not writable when SkCanvas is returned by SkDocument::beginPage,
    returned by SkPictureRecorder::beginRecording, or SkCanvas is the base of a utility
    class like DebugCanvas.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. SkCanvas pixels outside SkRect intersection are unchanged.
    
    Pass negative values for x or y to offset pixels to the left or
    above SkCanvas pixels.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - bitmap does not have allocated pixels.
    - bitmap pixels could not be converted to SkCanvas imageInfo().colorType() or
    imageInfo().alphaType().
    - SkCanvas pixels are not writable; for instance, SkCanvas is document based.
    - bitmap pixels are inaccessible; for instance, bitmap wraps a texture.
    
    @param bitmap  contains pixels copied to SkCanvas
    @param x       offset into SkCanvas writable pixels on x-axis; may be negative
    @param y       offset into SkCanvas writable pixels on y-axis; may be negative
    @return        true if pixels were written to SkCanvas
    
    example: https://fiddle.skia.org/c/@Canvas_writePixels_2
    example: https://fiddle.skia.org/c/@State_Stack_a
    example: https://fiddle.skia.org/c/@State_Stack_b
    */
    writePixels :: (this: *SkCanvas, bitmap: *SkBitmap, x: s32, y: s32) -> bool #cpp_method #foreign libskia "?writePixels@SkCanvas@@QEAA_NAEBVSkBitmap@@HH@Z";
    writePixels :: (this: *SkCanvas, bitmap: SkBitmap, x: s32, y: s32) -> bool #no_context {
        return writePixels(this, *bitmap, x, y);
    }

    /** Saves SkMatrix and clip.
    Calling restore() discards changes to SkMatrix and clip,
    restoring the SkMatrix and clip to their state when save() was called.
    
    SkMatrix may be changed by translate(), scale(), rotate(), skew(), concat(), setMatrix(),
    and resetMatrix(). Clip may be changed by clipRect(), clipRRect(), clipPath(), clipRegion().
    
    Saved SkCanvas state is put on a stack; multiple calls to save() should be balance
    by an equal number of calls to restore().
    
    Call restoreToCount() with result to restore this and subsequent saves.
    
    @return  depth of saved stack
    
    example: https://fiddle.skia.org/c/@Canvas_save
    */
    save :: (this: *SkCanvas) -> s32 #cpp_method #foreign libskia "?save@SkCanvas@@QEAAHXZ";

    /** Saves SkMatrix and clip, and allocates a SkSurface for subsequent drawing.
    Calling restore() discards changes to SkMatrix and clip, and draws the SkSurface.
    
    SkMatrix may be changed by translate(), scale(), rotate(), skew(), concat(),
    setMatrix(), and resetMatrix(). Clip may be changed by clipRect(), clipRRect(),
    clipPath(), clipRegion().
    
    SkRect bounds suggests but does not define the SkSurface size. To clip drawing to
    a specific rectangle, use clipRect().
    
    Optional SkPaint paint applies alpha, SkColorFilter, SkImageFilter, and
    SkBlendMode when restore() is called.
    
    Call restoreToCount() with returned value to restore this and subsequent saves.
    
    @param bounds  hint to limit the size of the layer; may be nullptr
    @param paint   graphics state for layer; may be nullptr
    @return        depth of saved stack
    
    example: https://fiddle.skia.org/c/@Canvas_saveLayer
    example: https://fiddle.skia.org/c/@Canvas_saveLayer_4
    */
    saveLayer :: (this: *SkCanvas, bounds: /*const*/ *SkRect, paint: /*const*/ *SkPaint) -> s32 #cpp_method #foreign libskia "?saveLayer@SkCanvas@@QEAAHPEBUSkRect@@PEBVSkPaint@@@Z";

    /** Saves SkMatrix and clip, and allocates a SkSurface for subsequent drawing.
    Calling restore() discards changes to SkMatrix and clip, and draws the SkSurface.
    
    SkMatrix may be changed by translate(), scale(), rotate(), skew(), concat(),
    setMatrix(), and resetMatrix(). Clip may be changed by clipRect(), clipRRect(),
    clipPath(), clipRegion().
    
    SkRect bounds suggests but does not define the layer size. To clip drawing to
    a specific rectangle, use clipRect().
    
    Optional SkPaint paint applies alpha, SkColorFilter, SkImageFilter, and
    SkBlendMode when restore() is called.
    
    Call restoreToCount() with returned value to restore this and subsequent saves.
    
    @param bounds  hint to limit the size of layer; may be nullptr
    @param paint   graphics state for layer; may be nullptr
    @return        depth of saved stack
    */
    saveLayer_1 :: (this: *SkCanvas, bounds: /*const reference*/ *SkRect, paint: /*const*/ *SkPaint) -> s32 #cpp_method #foreign libskia "?saveLayer@SkCanvas@@QEAAHAEBUSkRect@@PEBVSkPaint@@@Z";
    saveLayer_1 :: (this: *SkCanvas, bounds: SkRect, paint: *SkPaint) -> s32 #no_context {
        return saveLayer_1(this, *bounds, paint);
    }

    /** Saves SkMatrix and clip, and allocates SkSurface for subsequent drawing.
    
    Calling restore() discards changes to SkMatrix and clip,
    and blends layer with alpha opacity onto prior layer.
    
    SkMatrix may be changed by translate(), scale(), rotate(), skew(), concat(),
    setMatrix(), and resetMatrix(). Clip may be changed by clipRect(), clipRRect(),
    clipPath(), clipRegion().
    
    SkRect bounds suggests but does not define layer size. To clip drawing to
    a specific rectangle, use clipRect().
    
    alpha of zero is fully transparent, 1.0f is fully opaque.
    
    Call restoreToCount() with returned value to restore this and subsequent saves.
    
    @param bounds  hint to limit the size of layer; may be nullptr
    @param alpha   opacity of layer
    @return        depth of saved stack
    
    example: https://fiddle.skia.org/c/@Canvas_saveLayerAlpha
    */
    saveLayerAlphaf :: (this: *SkCanvas, bounds: *SkRect, alpha: float) -> s32 #cpp_method #foreign libskia "?saveLayerAlphaf@SkCanvas@@QEAAHPEBUSkRect@@M@Z";

    // Helper that accepts an int between 0 and 255, and divides it by 255.0
    saveLayerAlpha :: (this: *SkCanvas, bounds: *SkRect, alpha: U8CPU) -> s32 #cpp_method #foreign libskia "?saveLayerAlpha@SkCanvas@@QEAAHPEBUSkRect@@I@Z";

    /** \enum SkCanvas::SaveLayerFlagsSet
    SaveLayerFlags provides options that may be used in any combination in SaveLayerRec,
    defining how layer allocated by saveLayer() operates. It may be set to zero,
    kPreserveLCDText_SaveLayerFlag, kInitWithPrevious_SaveLayerFlag, or both flags.
    */
    SaveLayerFlagsSet :: enum s32 {
        PreserveLCDText_SaveLayerFlag  :: 2;
        InitWithPrevious_SaveLayerFlag :: 4;

        F16ColorType                   :: 16;

        kPreserveLCDText_SaveLayerFlag  :: PreserveLCDText_SaveLayerFlag;
        kInitWithPrevious_SaveLayerFlag :: InitWithPrevious_SaveLayerFlag;

        kF16ColorType                   :: F16ColorType;
    }

    SaveLayerFlags :: u32;
    FilterSpan :: SkSpan(sk_sp(SkImageFilter));
    kMaxFiltersPerLayer:       s32 : 16;

    /** \struct SkCanvas::SaveLayerRec
    SaveLayerRec contains the state used to create the layer.
    */
    SaveLayerRec :: struct {
        /** Sets fBounds, fPaint, and fBackdrop to nullptr. Clears fSaveLayerFlags.
        
        @return  empty SaveLayerRec
        */
//         Constructor :: (this: *SaveLayerRec) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@QEAA@XZ";

        /** Sets fBounds, fPaint, and fSaveLayerFlags; sets fBackdrop to nullptr.
        
        @param bounds          layer dimensions; may be nullptr
        @param paint           applied to layer when overlaying prior layer; may be nullptr
        @param saveLayerFlags  SaveLayerRec options to modify layer
        @return                SaveLayerRec with empty fBackdrop
        */
//         Constructor :: (this: *SaveLayerRec, bounds: *SkRect, paint: *SkPaint, saveLayerFlags: SaveLayerFlags = 0) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@QEAA@PEBUSkRect@@PEBVSkPaint@@I@Z";

        /** Sets fBounds, fPaint, fBackdrop, and fSaveLayerFlags.
        
        @param bounds          layer dimensions; may be nullptr
        @param paint           applied to layer when overlaying prior layer;
        may be nullptr
        @param backdrop        If not null, this causes the current layer to be filtered by
        backdrop, and then drawn into the new layer
        (respecting the current clip).
        If null, the new layer is initialized with transparent-black.
        @param saveLayerFlags  SaveLayerRec options to modify layer
        @return                SaveLayerRec fully specified
        */
//         Constructor :: (this: *SaveLayerRec, bounds: *SkRect, paint: *SkPaint, backdrop: *SkImageFilter, saveLayerFlags: SaveLayerFlags) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@QEAA@PEBUSkRect@@PEBVSkPaint@@PEBVSkImageFilter@@I@Z";

        /** Sets fBounds, fBackdrop, fColorSpace, and fSaveLayerFlags.
        
        @param bounds          layer dimensions; may be nullptr
        @param paint           applied to layer when overlaying prior layer;
        may be nullptr
        @param backdrop        If not null, this causes the current layer to be filtered by
        backdrop, and then drawn into the new layer
        (respecting the current clip).
        If null, the new layer is initialized with transparent-black.
        @param colorSpace      If not null, when the layer is restored, a color space
        conversion will be applied from this color space to the
        parent's color space. The restore paint and backdrop filters will
        be applied in this color space.
        If null, the new layer will inherit the color space from its
        parent.
        @param saveLayerFlags  SaveLayerRec options to modify layer
        @return                SaveLayerRec fully specified
        */
//         Constructor :: (this: *SaveLayerRec, bounds: *SkRect, paint: *SkPaint, backdrop: *SkImageFilter, colorSpace: *SkColorSpace, saveLayerFlags: SaveLayerFlags) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@QEAA@PEBUSkRect@@PEBVSkPaint@@PEBVSkImageFilter@@PEBVSkColorSpace@@I@Z";

        /** Sets fBounds, fBackdrop, fBackdropTileMode, fColorSpace, and fSaveLayerFlags.
        
        @param bounds           layer dimensions; may be nullptr
        @param paint            applied to layer when overlaying prior layer;
        may be nullptr
        @param backdrop         If not null, this causes the current layer to be filtered by
        backdrop, and then drawn into the new layer
        (respecting the current clip).
        If null, the new layer is initialized with transparent-black.
        @param backdropTileMode If the 'backdrop' is not null, or 'saveLayerFlags' has
        kInitWithPrevious set, this tile mode is used when the new layer
        would read outside the backdrop image's available content.
        @param colorSpace       If not null, when the layer is restored, a color space
        conversion will be applied from this color space to the parent's
        color space. The restore paint and backdrop filters will be
        applied in this color space.
        If null, the new layer will inherit the color space from its
        parent.
        @param saveLayerFlags   SaveLayerRec options to modify layer
        @return                 SaveLayerRec fully specified
        */
//         Constructor :: (this: *SaveLayerRec, bounds: *SkRect, paint: *SkPaint, backdrop: *SkImageFilter, backdropTileMode: SkTileMode, colorSpace: *SkColorSpace, saveLayerFlags: SaveLayerFlags) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@QEAA@PEBUSkRect@@PEBVSkPaint@@PEBVSkImageFilter@@W4SkTileMode@@PEBVSkColorSpace@@I@Z";

        /** hints at layer size limit */
        fBounds:                    *SkRect = null;

        /** modifies overlay */
        fPaint:                     *SkPaint = null;

        fFilters:                   FilterSpan;

        /**
        *  If not null, this triggers the same initialization behavior as setting
        *  kInitWithPrevious_SaveLayerFlag on fSaveLayerFlags: the current layer is copied into
        *  the new layer, rather than initializing the new layer with transparent-black.
        *  This is then filtered by fBackdrop (respecting the current clip).
        */
        fBackdrop:                  *SkImageFilter = null;

        /**
        * If the layer is initialized with prior content (and/or with a backdrop filter) and this
        * would require sampling outside of the available backdrop, this is the tilemode applied
        * to the boundary of the prior layer's image.
        */
        fBackdropTileMode:          SkTileMode = .Clamp;

        /**
        * If not null, this triggers a color space conversion when the layer is restored. It
        * will be as if the layer's contents are drawn in this color space. Filters from
        * fBackdrop and fPaint will be applied in this color space.
        */
        fColorSpace:                *SkColorSpace = null;

        /** preserves LCD text, creates with prior layer contents */
        fSaveLayerFlags:            SaveLayerFlags = 0;

//         Constructor :: (this: *SaveLayerRec, bounds: *SkRect, paint: *SkPaint, backdrop: *SkImageFilter, colorSpace: *SkColorSpace, backdropScale: SkScalar, backdropTileMode: SkTileMode, saveLayerFlags: SaveLayerFlags, filters: FilterSpan) -> void #cpp_method #foreign libskia "??0SaveLayerRec@SkCanvas@@AEAA@PEBUSkRect@@PEBVSkPaint@@PEBVSkImageFilter@@PEBVSkColorSpace@@MW4SkTileMode@@IV?$SkSpan@V?$sk_sp@VSkImageFilter@@@@@@@Z";

        // Relative scale factor that the image content used to initialize the layer when the
        // kInitFromPrevious flag or a backdrop filter is used.
        fExperimentalBackdropScale: SkScalar = 1.0;
    }

    /** Saves SkMatrix and clip, and allocates SkSurface for subsequent drawing.
    
    Calling restore() discards changes to SkMatrix and clip,
    and blends SkSurface with alpha opacity onto the prior layer.
    
    SkMatrix may be changed by translate(), scale(), rotate(), skew(), concat(),
    setMatrix(), and resetMatrix(). Clip may be changed by clipRect(), clipRRect(),
    clipPath(), clipRegion().
    
    SaveLayerRec contains the state used to create the layer.
    
    Call restoreToCount() with returned value to restore this and subsequent saves.
    
    @param layerRec  layer state
    @return          depth of save state stack before this call was made.
    
    example: https://fiddle.skia.org/c/@Canvas_saveLayer_3
    */
    saveLayer :: (this: *SkCanvas, layerRec: *SkCanvas.SaveLayerRec) -> s32 #cpp_method #foreign libskia "?saveLayer@SkCanvas@@QEAAHAEBUSaveLayerRec@1@@Z";
    saveLayer :: (this: *SkCanvas, layerRec: SkCanvas.SaveLayerRec) -> s32 #no_context {
        return saveLayer(this, *layerRec);
    }

    /** Removes changes to SkMatrix and clip since SkCanvas state was
    last saved. The state is removed from the stack.
    
    Does nothing if the stack is empty.
    
    example: https://fiddle.skia.org/c/@AutoCanvasRestore_restore
    
    example: https://fiddle.skia.org/c/@Canvas_restore
    */
    restore :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?restore@SkCanvas@@QEAAXXZ";

    /** Returns the number of saved states, each containing: SkMatrix and clip.
    Equals the number of save() calls less the number of restore() calls plus one.
    The save count of a new canvas is one.
    
    @return  depth of save state stack
    
    example: https://fiddle.skia.org/c/@Canvas_getSaveCount
    */
    getSaveCount :: (this: *SkCanvas) -> s32 #cpp_method #foreign libskia "?getSaveCount@SkCanvas@@QEBAHXZ";

    /** Restores state to SkMatrix and clip values when save(), saveLayer(),
    saveLayerPreserveLCDTextRequests(), or saveLayerAlpha() returned saveCount.
    
    Does nothing if saveCount is greater than state stack count.
    Restores state to initial values if saveCount is less than or equal to one.
    
    @param saveCount  depth of state stack to restore
    
    example: https://fiddle.skia.org/c/@Canvas_restoreToCount
    */
    restoreToCount :: (this: *SkCanvas, saveCount: s32) -> void #cpp_method #foreign libskia "?restoreToCount@SkCanvas@@QEAAXH@Z";

    /** Translates SkMatrix by dx along the x-axis and dy along the y-axis.
    
    Mathematically, replaces SkMatrix with a translation matrix
    premultiplied with SkMatrix.
    
    This has the effect of moving the drawing by (dx, dy) before transforming
    the result with SkMatrix.
    
    @param dx  distance to translate on x-axis
    @param dy  distance to translate on y-axis
    
    example: https://fiddle.skia.org/c/@Canvas_translate
    */
    translate :: (this: *SkCanvas, dx: SkScalar, dy: SkScalar) -> void #cpp_method #foreign libskia "?translate@SkCanvas@@QEAAXMM@Z";

    /** Scales SkMatrix by sx on the x-axis and sy on the y-axis.
    
    Mathematically, replaces SkMatrix with a scale matrix
    premultiplied with SkMatrix.
    
    This has the effect of scaling the drawing by (sx, sy) before transforming
    the result with SkMatrix.
    
    @param sx  amount to scale on x-axis
    @param sy  amount to scale on y-axis
    
    example: https://fiddle.skia.org/c/@Canvas_scale
    */
    scale :: (this: *SkCanvas, sx: SkScalar, sy: SkScalar) -> void #cpp_method #foreign libskia "?scale@SkCanvas@@QEAAXMM@Z";

    /** Rotates SkMatrix by degrees. Positive degrees rotates clockwise.
    
    Mathematically, replaces SkMatrix with a rotation matrix
    premultiplied with SkMatrix.
    
    This has the effect of rotating the drawing by degrees before transforming
    the result with SkMatrix.
    
    @param degrees  amount to rotate, in degrees
    
    example: https://fiddle.skia.org/c/@Canvas_rotate
    */
    rotate :: (this: *SkCanvas, degrees: SkScalar) -> void #cpp_method #foreign libskia "?rotate@SkCanvas@@QEAAXM@Z";

    /** Rotates SkMatrix by degrees about a point at (px, py). Positive degrees rotates
    clockwise.
    
    Mathematically, constructs a rotation matrix; premultiplies the rotation matrix by
    a translation matrix; then replaces SkMatrix with the resulting matrix
    premultiplied with SkMatrix.
    
    This has the effect of rotating the drawing about a given point before
    transforming the result with SkMatrix.
    
    @param degrees  amount to rotate, in degrees
    @param px       x-axis value of the point to rotate about
    @param py       y-axis value of the point to rotate about
    
    example: https://fiddle.skia.org/c/@Canvas_rotate_2
    */
    rotate :: (this: *SkCanvas, degrees: SkScalar, px: SkScalar, py: SkScalar) -> void #cpp_method #foreign libskia "?rotate@SkCanvas@@QEAAXMMM@Z";

    /** Skews SkMatrix by sx on the x-axis and sy on the y-axis. A positive value of sx
    skews the drawing right as y-axis values increase; a positive value of sy skews
    the drawing down as x-axis values increase.
    
    Mathematically, replaces SkMatrix with a skew matrix premultiplied with SkMatrix.
    
    This has the effect of skewing the drawing by (sx, sy) before transforming
    the result with SkMatrix.
    
    @param sx  amount to skew on x-axis
    @param sy  amount to skew on y-axis
    
    example: https://fiddle.skia.org/c/@Canvas_skew
    */
    skew :: (this: *SkCanvas, sx: SkScalar, sy: SkScalar) -> void #cpp_method #foreign libskia "?skew@SkCanvas@@QEAAXMM@Z";

    /** Replaces SkMatrix with matrix premultiplied with existing SkMatrix.
    
    This has the effect of transforming the drawn geometry by matrix, before
    transforming the result with existing SkMatrix.
    
    @param matrix  matrix to premultiply with existing SkMatrix
    
    example: https://fiddle.skia.org/c/@Canvas_concat
    */
    concat :: (this: *SkCanvas, matrix: *SkMatrix) -> void #cpp_method #foreign libskia "?concat@SkCanvas@@QEAAXAEBVSkMatrix@@@Z";
    concat :: (this: *SkCanvas, matrix: SkMatrix) #no_context {
        concat(this, *matrix);
    }
    concat :: (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method #foreign libskia "?concat@SkCanvas@@QEAAXAEBVSkM44@@@Z";
    concat :: (this: *SkCanvas, unknown0: SkM44) #no_context {
        concat(this, *unknown0);
    }

    /** Replaces SkMatrix with matrix.
    Unlike concat(), any prior matrix state is overwritten.
    
    @param matrix  matrix to copy, replacing existing SkMatrix
    
    example: https://fiddle.skia.org/c/@Canvas_setMatrix
    */
    setMatrix :: (this: *SkCanvas, matrix: *SkM44) -> void #cpp_method #foreign libskia "?setMatrix@SkCanvas@@QEAAXAEBVSkM44@@@Z";
    setMatrix :: (this: *SkCanvas, matrix: SkM44) #no_context {
        setMatrix(this, *matrix);
    }

    // DEPRECATED -- use SkM44 version
    setMatrix :: (this: *SkCanvas, matrix: *SkMatrix) -> void #cpp_method #foreign libskia "?setMatrix@SkCanvas@@QEAAXAEBVSkMatrix@@@Z";
    setMatrix :: (this: *SkCanvas, matrix: SkMatrix) #no_context {
        setMatrix(this, *matrix);
    }

    /** Sets SkMatrix to the identity matrix.
    Any prior matrix state is overwritten.
    
    example: https://fiddle.skia.org/c/@Canvas_resetMatrix
    */
    resetMatrix :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?resetMatrix@SkCanvas@@QEAAXXZ";

    /** Replaces clip with the intersection or difference of clip and rect,
    with an aliased or anti-aliased clip edge. rect is transformed by SkMatrix
    before it is combined with clip.
    
    @param rect         SkRect to combine with clip
    @param op           SkClipOp to apply to clip
    @param doAntiAlias  true if clip is to be anti-aliased
    
    example: https://fiddle.skia.org/c/@Canvas_clipRect
    */
    clipRect :: (this: *SkCanvas, rect: *SkRect, op: SkClipOp, doAntiAlias: bool) -> void #cpp_method #foreign libskia "?clipRect@SkCanvas@@QEAAXAEBUSkRect@@W4SkClipOp@@_N@Z";
    clipRect :: (this: *SkCanvas, rect: SkRect, op: SkClipOp, doAntiAlias: bool) #no_context {
        clipRect(this, *rect, op, doAntiAlias);
    }

    /** Replaces clip with the intersection or difference of clip and rect.
    Resulting clip is aliased; pixels are fully contained by the clip.
    rect is transformed by SkMatrix before it is combined with clip.
    
    @param rect  SkRect to combine with clip
    @param op    SkClipOp to apply to clip
    */
    clipRect :: (this: *SkCanvas, rect: *SkRect, op: SkClipOp) -> void #cpp_method #foreign libskia "?clipRect@SkCanvas@@QEAAXAEBUSkRect@@W4SkClipOp@@@Z";
    clipRect :: (this: *SkCanvas, rect: SkRect, op: SkClipOp) #no_context {
        clipRect(this, *rect, op);
    }

    /** Replaces clip with the intersection of clip and rect.
    Resulting clip is aliased; pixels are fully contained by the clip.
    rect is transformed by SkMatrix
    before it is combined with clip.
    
    @param rect         SkRect to combine with clip
    @param doAntiAlias  true if clip is to be anti-aliased
    */
    clipRect :: (this: *SkCanvas, rect: *SkRect, doAntiAlias := false) -> void #cpp_method #foreign libskia "?clipRect@SkCanvas@@QEAAXAEBUSkRect@@_N@Z";
    clipRect :: (this: *SkCanvas, rect: SkRect, doAntiAlias := false) #no_context {
        clipRect(this, *rect, doAntiAlias);
    }

    clipIRect :: (this: *SkCanvas, irect: *SkIRect, op: SkClipOp = .Intersect) -> void #cpp_method #foreign libskia "?clipIRect@SkCanvas@@QEAAXAEBUSkIRect@@W4SkClipOp@@@Z";
    clipIRect :: (this: *SkCanvas, irect: SkIRect, op: SkClipOp = .Intersect) #no_context {
        clipIRect(this, *irect, op);
    }

    /** Sets the maximum clip rectangle, which can be set by clipRect(), clipRRect() and
    clipPath() and intersect the current clip with the specified rect.
    The maximum clip affects only future clipping operations; it is not retroactive.
    The clip restriction is not recorded in pictures.
    
    Pass an empty rect to disable maximum clip.
    This private API is for use by Android framework only.
    
    DEPRECATED: Replace usage with SkAndroidFrameworkUtils::replaceClip()
    
    @param rect  maximum allowed clip in device coordinates
    */
    androidFramework_setDeviceClipRestriction :: (this: *SkCanvas, rect: *SkIRect) -> void #cpp_method #foreign libskia "?androidFramework_setDeviceClipRestriction@SkCanvas@@QEAAXAEBUSkIRect@@@Z";
    androidFramework_setDeviceClipRestriction :: (this: *SkCanvas, rect: SkIRect) #no_context {
        androidFramework_setDeviceClipRestriction(this, *rect);
    }

    /** Replaces clip with the intersection or difference of clip and rrect,
    with an aliased or anti-aliased clip edge.
    rrect is transformed by SkMatrix
    before it is combined with clip.
    
    @param rrect        SkRRect to combine with clip
    @param op           SkClipOp to apply to clip
    @param doAntiAlias  true if clip is to be anti-aliased
    
    example: https://fiddle.skia.org/c/@Canvas_clipRRect
    */
    clipRRect :: (this: *SkCanvas, rrect: *SkRRect, op: SkClipOp, doAntiAlias: bool) -> void #cpp_method #foreign libskia "?clipRRect@SkCanvas@@QEAAXAEBVSkRRect@@W4SkClipOp@@_N@Z";
    clipRRect :: (this: *SkCanvas, rrect: SkRRect, op: SkClipOp, doAntiAlias: bool) #no_context {
        clipRRect(this, *rrect, op, doAntiAlias);
    }

    /** Replaces clip with the intersection or difference of clip and rrect.
    Resulting clip is aliased; pixels are fully contained by the clip.
    rrect is transformed by SkMatrix before it is combined with clip.
    
    @param rrect  SkRRect to combine with clip
    @param op     SkClipOp to apply to clip
    */
    clipRRect :: (this: *SkCanvas, rrect: *SkRRect, op: SkClipOp) -> void #cpp_method #foreign libskia "?clipRRect@SkCanvas@@QEAAXAEBVSkRRect@@W4SkClipOp@@@Z";
    clipRRect :: (this: *SkCanvas, rrect: SkRRect, op: SkClipOp) #no_context {
        clipRRect(this, *rrect, op);
    }

    /** Replaces clip with the intersection of clip and rrect,
    with an aliased or anti-aliased clip edge.
    rrect is transformed by SkMatrix before it is combined with clip.
    
    @param rrect        SkRRect to combine with clip
    @param doAntiAlias  true if clip is to be anti-aliased
    */
    clipRRect :: (this: *SkCanvas, rrect: *SkRRect, doAntiAlias := false) -> void #cpp_method #foreign libskia "?clipRRect@SkCanvas@@QEAAXAEBVSkRRect@@_N@Z";
    clipRRect :: (this: *SkCanvas, rrect: SkRRect, doAntiAlias := false) #no_context {
        clipRRect(this, *rrect, doAntiAlias);
    }

    /** Replaces clip with the intersection or difference of clip and path,
    with an aliased or anti-aliased clip edge. SkPath::FillType determines if path
    describes the area inside or outside its contours; and if path contour overlaps
    itself or another path contour, whether the overlaps form part of the area.
    path is transformed by SkMatrix before it is combined with clip.
    
    @param path         SkPath to combine with clip
    @param op           SkClipOp to apply to clip
    @param doAntiAlias  true if clip is to be anti-aliased
    
    example: https://fiddle.skia.org/c/@Canvas_clipPath
    */
    clipPath :: (this: *SkCanvas, path: *SkPath, op: SkClipOp, doAntiAlias: bool) -> void #cpp_method #foreign libskia "?clipPath@SkCanvas@@QEAAXAEBVSkPath@@W4SkClipOp@@_N@Z";
    clipPath :: (this: *SkCanvas, path: SkPath, op: SkClipOp, doAntiAlias: bool) #no_context {
        clipPath(this, *path, op, doAntiAlias);
    }

    /** Replaces clip with the intersection or difference of clip and path.
    Resulting clip is aliased; pixels are fully contained by the clip.
    SkPath::FillType determines if path
    describes the area inside or outside its contours; and if path contour overlaps
    itself or another path contour, whether the overlaps form part of the area.
    path is transformed by SkMatrix
    before it is combined with clip.
    
    @param path  SkPath to combine with clip
    @param op    SkClipOp to apply to clip
    */
    clipPath :: (this: *SkCanvas, path: *SkPath, op: SkClipOp) -> void #cpp_method #foreign libskia "?clipPath@SkCanvas@@QEAAXAEBVSkPath@@W4SkClipOp@@@Z";
    clipPath :: (this: *SkCanvas, path: SkPath, op: SkClipOp) #no_context {
        clipPath(this, *path, op);
    }

    /** Replaces clip with the intersection of clip and path.
    Resulting clip is aliased; pixels are fully contained by the clip.
    SkPath::FillType determines if path
    describes the area inside or outside its contours; and if path contour overlaps
    itself or another path contour, whether the overlaps form part of the area.
    path is transformed by SkMatrix before it is combined with clip.
    
    @param path         SkPath to combine with clip
    @param doAntiAlias  true if clip is to be anti-aliased
    */
    clipPath :: (this: *SkCanvas, path: *SkPath, doAntiAlias := false) -> void #cpp_method #foreign libskia "?clipPath@SkCanvas@@QEAAXAEBVSkPath@@_N@Z";
    clipPath :: (this: *SkCanvas, path: SkPath, doAntiAlias := false) #no_context {
        clipPath(this, *path, doAntiAlias);
    }

    clipShader :: (this: *SkCanvas, unknown0: sk_sp(SkShader), unknown1: SkClipOp = .Intersect) -> void #cpp_method #foreign libskia "?clipShader@SkCanvas@@QEAAXV?$sk_sp@VSkShader@@@@W4SkClipOp@@@Z";

    /** Replaces clip with the intersection or difference of clip and SkRegion deviceRgn.
    Resulting clip is aliased; pixels are fully contained by the clip.
    deviceRgn is unaffected by SkMatrix.
    
    @param deviceRgn  SkRegion to combine with clip
    @param op         SkClipOp to apply to clip
    
    example: https://fiddle.skia.org/c/@Canvas_clipRegion
    */
    clipRegion :: (this: *SkCanvas, deviceRgn: *SkRegion, op: SkClipOp = .Intersect) -> void #cpp_method #foreign libskia "?clipRegion@SkCanvas@@QEAAXAEBVSkRegion@@W4SkClipOp@@@Z";
    clipRegion :: (this: *SkCanvas, deviceRgn: SkRegion, op: SkClipOp = .Intersect) #no_context {
        clipRegion(this, *deviceRgn, op);
    }

    /** Returns true if SkRect rect, transformed by SkMatrix, can be quickly determined to be
    outside of clip. May return false even though rect is outside of clip.
    
    Use to check if an area to be drawn is clipped out, to skip subsequent draw calls.
    
    @param rect  SkRect to compare with clip
    @return      true if rect, transformed by SkMatrix, does not intersect clip
    
    example: https://fiddle.skia.org/c/@Canvas_quickReject
    */
    quickReject :: (this: *SkCanvas, rect: *SkRect) -> bool #cpp_method #foreign libskia "?quickReject@SkCanvas@@QEBA_NAEBUSkRect@@@Z";
    quickReject :: (this: *SkCanvas, rect: SkRect) -> bool #no_context {
        return quickReject(this, *rect);
    }

    /** Returns true if path, transformed by SkMatrix, can be quickly determined to be
    outside of clip. May return false even though path is outside of clip.
    
    Use to check if an area to be drawn is clipped out, to skip subsequent draw calls.
    
    @param path  SkPath to compare with clip
    @return      true if path, transformed by SkMatrix, does not intersect clip
    
    example: https://fiddle.skia.org/c/@Canvas_quickReject_2
    */
    quickReject :: (this: *SkCanvas, path: *SkPath) -> bool #cpp_method #foreign libskia "?quickReject@SkCanvas@@QEBA_NAEBVSkPath@@@Z";
    quickReject :: (this: *SkCanvas, path: SkPath) -> bool #no_context {
        return quickReject(this, *path);
    }

    /** Returns bounds of clip, transformed by inverse of SkMatrix. If clip is empty,
    return SkRect::MakeEmpty, where all SkRect sides equal zero.
    
    SkRect returned is outset by one to account for partial pixel coverage if clip
    is anti-aliased.
    
    @return  bounds of clip in local coordinates
    
    example: https://fiddle.skia.org/c/@Canvas_getLocalClipBounds
    */
    getLocalClipBounds :: (this: *SkCanvas) -> SkRect #cpp_method #foreign libskia "?getLocalClipBounds@SkCanvas@@QEBA?AUSkRect@@XZ";

    /** Returns bounds of clip, transformed by inverse of SkMatrix. If clip is empty,
    return false, and set bounds to SkRect::MakeEmpty, where all SkRect sides equal zero.
    
    bounds is outset by one to account for partial pixel coverage if clip
    is anti-aliased.
    
    @param bounds  SkRect of clip in local coordinates
    @return        true if clip bounds is not empty
    */
    getLocalClipBounds :: (this: *SkCanvas, bounds: *SkRect) -> bool #cpp_method #foreign libskia "?getLocalClipBounds@SkCanvas@@QEBA_NPEAUSkRect@@@Z";

    /** Returns SkIRect bounds of clip, unaffected by SkMatrix. If clip is empty,
    return SkRect::MakeEmpty, where all SkRect sides equal zero.
    
    Unlike getLocalClipBounds(), returned SkIRect is not outset.
    
    @return  bounds of clip in base device coordinates
    
    example: https://fiddle.skia.org/c/@Canvas_getDeviceClipBounds
    */
    getDeviceClipBounds :: (this: *SkCanvas) -> SkIRect #cpp_method #foreign libskia "?getDeviceClipBounds@SkCanvas@@QEBA?AUSkIRect@@XZ";

    /** Returns SkIRect bounds of clip, unaffected by SkMatrix. If clip is empty,
    return false, and set bounds to SkRect::MakeEmpty, where all SkRect sides equal zero.
    
    Unlike getLocalClipBounds(), bounds is not outset.
    
    @param bounds  SkRect of clip in device coordinates
    @return        true if clip bounds is not empty
    */
    getDeviceClipBounds :: (this: *SkCanvas, bounds: *SkIRect) -> bool #cpp_method #foreign libskia "?getDeviceClipBounds@SkCanvas@@QEBA_NPEAUSkIRect@@@Z";

    /** Fills clip with color color.
    mode determines how ARGB is combined with destination.
    
    @param color  unpremultiplied ARGB
    @param mode   SkBlendMode used to combine source color and destination
    
    example: https://fiddle.skia.org/c/@Canvas_drawColor
    */
    drawColor :: (this: *SkCanvas, color: SkColor, mode: SkBlendMode = .SrcOver) -> void #cpp_method #foreign libskia "?drawColor@SkCanvas@@QEAAXIW4SkBlendMode@@@Z";

    /** Fills clip with color color.
    mode determines how ARGB is combined with destination.
    
    @param color  SkColor4f representing unpremultiplied color.
    @param mode   SkBlendMode used to combine source color and destination
    */
    drawColor :: (this: *SkCanvas, color: *SkColor4f, mode: SkBlendMode = .SrcOver) -> void #cpp_method #foreign libskia "?drawColor@SkCanvas@@QEAAXAEBU?$SkRGBA4f@$02@@W4SkBlendMode@@@Z";
    drawColor :: (this: *SkCanvas, color: SkColor4f, mode: SkBlendMode = .SrcOver) #no_context {
        drawColor(this, *color, mode);
    }

    /** Fills clip with color color using SkBlendMode::kSrc.
    This has the effect of replacing all pixels contained by clip with color.
    
    @param color  unpremultiplied ARGB
    */
    clear :: (this: *SkCanvas, color: SkColor) -> void #cpp_method #foreign libskia "?clear@SkCanvas@@QEAAXI@Z";

    /** Fills clip with color color using SkBlendMode::kSrc.
    This has the effect of replacing all pixels contained by clip with color.
    
    @param color  SkColor4f representing unpremultiplied color.
    */
    clear :: (this: *SkCanvas, color: *SkColor4f) -> void #cpp_method #foreign libskia "?clear@SkCanvas@@QEAAXAEBU?$SkRGBA4f@$02@@@Z";
    clear :: (this: *SkCanvas, color: SkColor4f) #no_context {
        clear(this, *color);
    }

    /** Makes SkCanvas contents undefined. Subsequent calls that read SkCanvas pixels,
    such as drawing with SkBlendMode, return undefined results. discard() does
    not change clip or SkMatrix.
    
    discard() may do nothing, depending on the implementation of SkSurface or SkDevice
    that created SkCanvas.
    
    discard() allows optimized performance on subsequent draws by removing
    cached data associated with SkSurface or SkDevice.
    It is not necessary to call discard() once done with SkCanvas;
    any cached data is deleted when owning SkSurface or SkDevice is deleted.
    */
    discard :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?discard@SkCanvas@@QEAAXXZ";

    /** Fills clip with SkPaint paint. SkPaint components, SkShader,
    SkColorFilter, SkImageFilter, and SkBlendMode affect drawing;
    SkMaskFilter and SkPathEffect in paint are ignored.
    
    @param paint  graphics state used to fill SkCanvas
    
    example: https://fiddle.skia.org/c/@Canvas_drawPaint
    */
    drawPaint :: (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPaint@SkCanvas@@QEAAXAEBVSkPaint@@@Z";
    drawPaint :: (this: *SkCanvas, paint: SkPaint) #no_context {
        drawPaint(this, *paint);
    }

    /** \enum SkCanvas::PointMode
    Selects if an array of points are drawn as discrete points, as lines, or as
    an open polygon.
    */
    PointMode :: enum s32 {
        Points_PointMode  :: 0;
        Lines_PointMode   :: 1;
        Polygon_PointMode :: 2;

        kPoints_PointMode  :: Points_PointMode;
        kLines_PointMode   :: Lines_PointMode;
        kPolygon_PointMode :: Polygon_PointMode;
    }

    /** Draws pts using clip, SkMatrix and SkPaint paint.
    count is the number of points; if count is less than one, has no effect.
    mode may be one of: kPoints_PointMode, kLines_PointMode, or kPolygon_PointMode.
    
    If mode is kPoints_PointMode, the shape of point drawn depends on paint
    SkPaint::Cap. If paint is set to SkPaint::kRound_Cap, each point draws a
    circle of diameter SkPaint stroke width. If paint is set to SkPaint::kSquare_Cap
    or SkPaint::kButt_Cap, each point draws a square of width and height
    SkPaint stroke width.
    
    If mode is kLines_PointMode, each pair of points draws a line segment.
    One line is drawn for every two points; each point is used once. If count is odd,
    the final point is ignored.
    
    If mode is kPolygon_PointMode, each adjacent pair of points draws a line segment.
    count minus one lines are drawn; the first and last point are used once.
    
    Each line segment respects paint SkPaint::Cap and SkPaint stroke width.
    SkPaint::Style is ignored, as if were set to SkPaint::kStroke_Style.
    
    Always draws each element one at a time; is not affected by
    SkPaint::Join, and unlike drawPath(), does not create a mask from all points
    and lines before drawing.
    
    @param mode   whether pts draws points or lines
    @param count  number of points in the array
    @param pts    array of points to draw
    @param paint  stroke, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawPoints
    */
    drawPoints :: (this: *SkCanvas, mode: SkCanvas.PointMode, unknown0: SkSpan(SkPoint), paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPoints@SkCanvas@@QEAAXW4PointMode@1@V?$SkSpan@$$CBUSkPoint@@@@AEBVSkPaint@@@Z";
    drawPoints :: (this: *SkCanvas, mode: SkCanvas.PointMode, unknown0: SkSpan(SkPoint), paint: SkPaint) #no_context {
        drawPoints(this, mode, unknown0, *paint);
    }

    /** Draws point at (x, y) using clip, SkMatrix and SkPaint paint.
    
    The shape of point drawn depends on paint SkPaint::Cap.
    If paint is set to SkPaint::kRound_Cap, draw a circle of diameter
    SkPaint stroke width. If paint is set to SkPaint::kSquare_Cap or SkPaint::kButt_Cap,
    draw a square of width and height SkPaint stroke width.
    SkPaint::Style is ignored, as if were set to SkPaint::kStroke_Style.
    
    @param x      left edge of circle or square
    @param y      top edge of circle or square
    @param paint  stroke, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawPoint
    */
    drawPoint :: (this: *SkCanvas, x: SkScalar, y: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPoint@SkCanvas@@QEAAXMMAEBVSkPaint@@@Z";
    drawPoint :: (this: *SkCanvas, x: SkScalar, y: SkScalar, paint: SkPaint) #no_context {
        drawPoint(this, x, y, *paint);
    }

    /** Draws point p using clip, SkMatrix and SkPaint paint.
    
    The shape of point drawn depends on paint SkPaint::Cap.
    If paint is set to SkPaint::kRound_Cap, draw a circle of diameter
    SkPaint stroke width. If paint is set to SkPaint::kSquare_Cap or SkPaint::kButt_Cap,
    draw a square of width and height SkPaint stroke width.
    SkPaint::Style is ignored, as if were set to SkPaint::kStroke_Style.
    
    @param p      top-left edge of circle or square
    @param paint  stroke, blend, color, and so on, used to draw
    */
    drawPoint :: (this: *SkCanvas, p: SkPoint, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPoint@SkCanvas@@QEAAXUSkPoint@@AEBVSkPaint@@@Z";
    drawPoint :: (this: *SkCanvas, p: SkPoint, paint: SkPaint) #no_context {
        drawPoint(this, p, *paint);
    }

    /** Draws line segment from (x0, y0) to (x1, y1) using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint stroke width describes the line thickness;
    SkPaint::Cap draws the end rounded or square;
    SkPaint::Style is ignored, as if were set to SkPaint::kStroke_Style.
    
    @param x0     start of line segment on x-axis
    @param y0     start of line segment on y-axis
    @param x1     end of line segment on x-axis
    @param y1     end of line segment on y-axis
    @param paint  stroke, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawLine
    */
    drawLine :: (this: *SkCanvas, x0: SkScalar, y0: SkScalar, x1: SkScalar, y1: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawLine@SkCanvas@@QEAAXMMMMAEBVSkPaint@@@Z";
    drawLine :: (this: *SkCanvas, x0: SkScalar, y0: SkScalar, x1: SkScalar, y1: SkScalar, paint: SkPaint) #no_context {
        drawLine(this, x0, y0, x1, y1, *paint);
    }

    /** Draws line segment from p0 to p1 using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint stroke width describes the line thickness;
    SkPaint::Cap draws the end rounded or square;
    SkPaint::Style is ignored, as if were set to SkPaint::kStroke_Style.
    
    @param p0     start of line segment
    @param p1     end of line segment
    @param paint  stroke, blend, color, and so on, used to draw
    */
    drawLine :: (this: *SkCanvas, p0: SkPoint, p1: SkPoint, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawLine@SkCanvas@@QEAAXUSkPoint@@0AEBVSkPaint@@@Z";
    drawLine :: (this: *SkCanvas, p0: SkPoint, p1: SkPoint, paint: SkPaint) #no_context {
        drawLine(this, p0, p1, *paint);
    }

    /** Draws SkRect rect using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint::Style determines if rectangle is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness, and
    SkPaint::Join draws the corners rounded or square.
    
    @param rect   rectangle to draw
    @param paint  stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawRect
    */
    drawRect :: (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawRect@SkCanvas@@QEAAXAEBUSkRect@@AEBVSkPaint@@@Z";
    drawRect :: (this: *SkCanvas, rect: SkRect, paint: SkPaint) #no_context {
        drawRect(this, *rect, *paint);
    }

    /** Draws SkIRect rect using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint::Style determines if rectangle is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness, and
    SkPaint::Join draws the corners rounded or square.
    
    @param rect   rectangle to draw
    @param paint  stroke or fill, blend, color, and so on, used to draw
    */
    drawIRect :: (this: *SkCanvas, rect: *SkIRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawIRect@SkCanvas@@QEAAXAEBUSkIRect@@AEBVSkPaint@@@Z";
    drawIRect :: (this: *SkCanvas, rect: SkIRect, paint: SkPaint) #no_context {
        drawIRect(this, *rect, *paint);
    }

    /** Draws SkRegion region using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint::Style determines if rectangle is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness, and
    SkPaint::Join draws the corners rounded or square.
    
    @param region  region to draw
    @param paint   SkPaint stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawRegion
    */
    drawRegion :: (this: *SkCanvas, region: *SkRegion, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawRegion@SkCanvas@@QEAAXAEBVSkRegion@@AEBVSkPaint@@@Z";
    drawRegion :: (this: *SkCanvas, region: SkRegion, paint: SkPaint) #no_context {
        drawRegion(this, *region, *paint);
    }

    /** Draws oval oval using clip, SkMatrix, and SkPaint.
    In paint: SkPaint::Style determines if oval is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    
    @param oval   SkRect bounds of oval
    @param paint  SkPaint stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawOval
    */
    drawOval :: (this: *SkCanvas, oval: *SkRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawOval@SkCanvas@@QEAAXAEBUSkRect@@AEBVSkPaint@@@Z";
    drawOval :: (this: *SkCanvas, oval: SkRect, paint: SkPaint) #no_context {
        drawOval(this, *oval, *paint);
    }

    /** Draws SkRRect rrect using clip, SkMatrix, and SkPaint paint.
    In paint: SkPaint::Style determines if rrect is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    
    rrect may represent a rectangle, circle, oval, uniformly rounded rectangle, or
    may have any combination of positive non-square radii for the four corners.
    
    @param rrect  SkRRect with up to eight corner radii to draw
    @param paint  SkPaint stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawRRect
    */
    drawRRect :: (this: *SkCanvas, rrect: *SkRRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawRRect@SkCanvas@@QEAAXAEBVSkRRect@@AEBVSkPaint@@@Z";
    drawRRect :: (this: *SkCanvas, rrect: SkRRect, paint: SkPaint) #no_context {
        drawRRect(this, *rrect, *paint);
    }

    /** Draws SkRRect outer and inner
    using clip, SkMatrix, and SkPaint paint.
    outer must contain inner or the drawing is undefined.
    In paint: SkPaint::Style determines if SkRRect is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    If stroked and SkRRect corner has zero length radii, SkPaint::Join can
    draw corners rounded or square.
    
    GPU-backed platforms optimize drawing when both outer and inner are
    concave and outer contains inner. These platforms may not be able to draw
    SkPath built with identical data as fast.
    
    @param outer  SkRRect outer bounds to draw
    @param inner  SkRRect inner bounds to draw
    @param paint  SkPaint stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawDRRect_a
    example: https://fiddle.skia.org/c/@Canvas_drawDRRect_b
    */
    drawDRRect :: (this: *SkCanvas, outer: *SkRRect, inner: *SkRRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawDRRect@SkCanvas@@QEAAXAEBVSkRRect@@0AEBVSkPaint@@@Z";
    drawDRRect :: (this: *SkCanvas, outer: SkRRect, inner: SkRRect, paint: SkPaint) #no_context {
        drawDRRect(this, *outer, *inner, *paint);
    }

    /** Draws circle at (cx, cy) with radius using clip, SkMatrix, and SkPaint paint.
    If radius is zero or less, nothing is drawn.
    In paint: SkPaint::Style determines if circle is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    
    @param cx      circle center on the x-axis
    @param cy      circle center on the y-axis
    @param radius  half the diameter of circle
    @param paint   SkPaint stroke or fill, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawCircle
    */
    drawCircle :: (this: *SkCanvas, cx: SkScalar, cy: SkScalar, radius: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawCircle@SkCanvas@@QEAAXMMMAEBVSkPaint@@@Z";
    drawCircle :: (this: *SkCanvas, cx: SkScalar, cy: SkScalar, radius: SkScalar, paint: SkPaint) #no_context {
        drawCircle(this, cx, cy, radius, *paint);
    }

    /** Draws circle at center with radius using clip, SkMatrix, and SkPaint paint.
    If radius is zero or less, nothing is drawn.
    In paint: SkPaint::Style determines if circle is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    
    @param center  circle center
    @param radius  half the diameter of circle
    @param paint   SkPaint stroke or fill, blend, color, and so on, used to draw
    */
    drawCircle :: (this: *SkCanvas, center: SkPoint, radius: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawCircle@SkCanvas@@QEAAXUSkPoint@@MAEBVSkPaint@@@Z";
    drawCircle :: (this: *SkCanvas, center: SkPoint, radius: SkScalar, paint: SkPaint) #no_context {
        drawCircle(this, center, radius, *paint);
    }

    /** Draws arc using clip, SkMatrix, and SkPaint paint.
    
    Arc is part of oval bounded by oval, sweeping from startAngle to startAngle plus
    sweepAngle. startAngle and sweepAngle are in degrees.
    
    startAngle of zero places start point at the right middle edge of oval.
    A positive sweepAngle places arc end point clockwise from start point;
    a negative sweepAngle places arc end point counterclockwise from start point.
    sweepAngle may exceed 360 degrees, a full circle.
    If useCenter is true, draw a wedge that includes lines from oval
    center to arc end points. If useCenter is false, draw arc between end points.
    
    If SkRect oval is empty or sweepAngle is zero, nothing is drawn.
    
    @param oval        SkRect bounds of oval containing arc to draw
    @param startAngle  angle in degrees where arc begins
    @param sweepAngle  sweep angle in degrees; positive is clockwise
    @param useCenter   if true, include the center of the oval
    @param paint       SkPaint stroke or fill, blend, color, and so on, used to draw
    */
    drawArc :: (this: *SkCanvas, oval: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, useCenter: bool, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawArc@SkCanvas@@QEAAXAEBUSkRect@@MM_NAEBVSkPaint@@@Z";
    drawArc :: (this: *SkCanvas, oval: SkRect, startAngle: SkScalar, sweepAngle: SkScalar, useCenter: bool, paint: SkPaint) #no_context {
        drawArc(this, *oval, startAngle, sweepAngle, useCenter, *paint);
    }

    /** Draws arc using clip, SkMatrix, and SkPaint paint.
    
    Arc is part of oval bounded by oval, sweeping from startAngle to startAngle plus
    sweepAngle. startAngle and sweepAngle are in degrees.
    
    startAngle of zero places start point at the right middle edge of oval.
    A positive sweepAngle places arc end point clockwise from start point;
    a negative sweepAngle places arc end point counterclockwise from start point.
    sweepAngle may exceed 360 degrees, a full circle.
    If useCenter is true, draw a wedge that includes lines from oval
    center to arc end points. If useCenter is false, draw arc between end points.
    
    If SkRect oval is empty or sweepAngle is zero, nothing is drawn.
    
    @param arc    SkArc specifying oval, startAngle, sweepAngle, and arc-vs-wedge
    @param paint  SkPaint stroke or fill, blend, color, and so on, used to draw
    */
    drawArc :: (this: *SkCanvas, arc: *SkArc, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawArc@SkCanvas@@QEAAXAEBUSkArc@@AEBVSkPaint@@@Z";
    drawArc :: (this: *SkCanvas, arc: SkArc, paint: SkPaint) #no_context {
        drawArc(this, *arc, *paint);
    }

    /** Draws SkRRect bounded by SkRect rect, with corner radii (rx, ry) using clip,
    SkMatrix, and SkPaint paint.
    
    In paint: SkPaint::Style determines if SkRRect is stroked or filled;
    if stroked, SkPaint stroke width describes the line thickness.
    If rx or ry are less than zero, they are treated as if they are zero.
    If rx plus ry exceeds rect width or rect height, radii are scaled down to fit.
    If rx and ry are zero, SkRRect is drawn as SkRect and if stroked is affected by
    SkPaint::Join.
    
    @param rect   SkRect bounds of SkRRect to draw
    @param rx     axis length on x-axis of oval describing rounded corners
    @param ry     axis length on y-axis of oval describing rounded corners
    @param paint  stroke, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawRoundRect
    */
    drawRoundRect :: (this: *SkCanvas, rect: *SkRect, rx: SkScalar, ry: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawRoundRect@SkCanvas@@QEAAXAEBUSkRect@@MMAEBVSkPaint@@@Z";
    drawRoundRect :: (this: *SkCanvas, rect: SkRect, rx: SkScalar, ry: SkScalar, paint: SkPaint) #no_context {
        drawRoundRect(this, *rect, rx, ry, *paint);
    }

    /** Draws SkPath path using clip, SkMatrix, and SkPaint paint.
    SkPath contains an array of path contour, each of which may be open or closed.
    
    In paint: SkPaint::Style determines if SkRRect is stroked or filled:
    if filled, SkPath::FillType determines whether path contour describes inside or
    outside of fill; if stroked, SkPaint stroke width describes the line thickness,
    SkPaint::Cap describes line ends, and SkPaint::Join describes how
    corners are drawn.
    
    @param path   SkPath to draw
    @param paint  stroke, blend, color, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawPath
    */
    drawPath :: (this: *SkCanvas, path: *SkPath, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPath@SkCanvas@@QEAAXAEBVSkPath@@AEBVSkPaint@@@Z";
    drawPath :: (this: *SkCanvas, path: SkPath, paint: SkPaint) #no_context {
        drawPath(this, *path, *paint);
    }

    drawImage :: (this: *SkCanvas, image: *SkImage, left: SkScalar, top: SkScalar) -> void #cpp_method #foreign libskia "?drawImage@SkCanvas@@QEAAXPEBVSkImage@@MM@Z";

    drawImage :: (this: *SkCanvas, image: *sk_sp(SkImage), left: SkScalar, top: SkScalar) -> void #cpp_method #foreign libskia "?drawImage@SkCanvas@@QEAAXAEBV?$sk_sp@VSkImage@@@@MM@Z";
    drawImage :: (this: *SkCanvas, image: sk_sp(SkImage), left: SkScalar, top: SkScalar) #no_context {
        drawImage(this, *image, left, top);
    }

    /** \enum SkCanvas::SrcRectConstraint
    SrcRectConstraint controls the behavior at the edge of source SkRect,
    provided to drawImageRect() when there is any filtering. If kStrict is set,
    then extra code is used to ensure it never samples outside of the src-rect.
    kStrict_SrcRectConstraint disables the use of mipmaps and anisotropic filtering.
    */
    SrcRectConstraint :: enum s32 {
        Strict_SrcRectConstraint :: 0;
        Fast_SrcRectConstraint   :: 1;

        kStrict_SrcRectConstraint :: Strict_SrcRectConstraint;
        kFast_SrcRectConstraint   :: Fast_SrcRectConstraint;
    }

    drawImage :: (this: *SkCanvas, unknown0: *SkImage, x: SkScalar, y: SkScalar, unknown1: *SkSamplingOptions, unknown2: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImage@SkCanvas@@QEAAXPEBVSkImage@@MMAEBUSkSamplingOptions@@PEBVSkPaint@@@Z";
    drawImage :: (this: *SkCanvas, unknown0: *SkImage, x: SkScalar, y: SkScalar, unknown1: SkSamplingOptions, unknown2: *SkPaint = null) #no_context {
        drawImage(this, unknown0, x, y, *unknown1, unknown2);
    }

    drawImage :: (this: *SkCanvas, image: *sk_sp(SkImage), x: SkScalar, y: SkScalar, sampling: *SkSamplingOptions, paint: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImage@SkCanvas@@QEAAXAEBV?$sk_sp@VSkImage@@@@MMAEBUSkSamplingOptions@@PEBVSkPaint@@@Z";
    drawImage :: (this: *SkCanvas, image: sk_sp(SkImage), x: SkScalar, y: SkScalar, sampling: SkSamplingOptions, paint: *SkPaint = null) #no_context {
        drawImage(this, *image, x, y, *sampling, paint);
    }

    drawImageRect :: (this: *SkCanvas, unknown0: *SkImage, src: *SkRect, dst: *SkRect, unknown1: *SkSamplingOptions, unknown2: *SkPaint, unknown3: SkCanvas.SrcRectConstraint) -> void #cpp_method #foreign libskia "?drawImageRect@SkCanvas@@QEAAXPEBVSkImage@@AEBUSkRect@@1AEBUSkSamplingOptions@@PEBVSkPaint@@W4SrcRectConstraint@1@@Z";
    drawImageRect :: (this: *SkCanvas, unknown0: *SkImage, src: SkRect, dst: SkRect, unknown1: SkSamplingOptions, unknown2: *SkPaint, unknown3: SkCanvas.SrcRectConstraint) #no_context {
        drawImageRect(this, unknown0, *src, *dst, *unknown1, unknown2, unknown3);
    }

    drawImageRect :: (this: *SkCanvas, unknown0: *SkImage, dst: *SkRect, unknown1: *SkSamplingOptions, unknown2: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImageRect@SkCanvas@@QEAAXPEBVSkImage@@AEBUSkRect@@AEBUSkSamplingOptions@@PEBVSkPaint@@@Z";
    drawImageRect :: (this: *SkCanvas, unknown0: *SkImage, dst: SkRect, unknown1: SkSamplingOptions, unknown2: *SkPaint = null) #no_context {
        drawImageRect(this, unknown0, *dst, *unknown1, unknown2);
    }

    drawImageRect :: (this: *SkCanvas, image: *sk_sp(SkImage), src: *SkRect, dst: *SkRect, sampling: *SkSamplingOptions, paint: *SkPaint, constraint: SkCanvas.SrcRectConstraint) -> void #cpp_method #foreign libskia "?drawImageRect@SkCanvas@@QEAAXAEBV?$sk_sp@VSkImage@@@@AEBUSkRect@@1AEBUSkSamplingOptions@@PEBVSkPaint@@W4SrcRectConstraint@1@@Z";
    drawImageRect :: (this: *SkCanvas, image: sk_sp(SkImage), src: SkRect, dst: SkRect, sampling: SkSamplingOptions, paint: *SkPaint, constraint: SkCanvas.SrcRectConstraint) #no_context {
        drawImageRect(this, *image, *src, *dst, *sampling, paint, constraint);
    }

    drawImageRect :: (this: *SkCanvas, image: *sk_sp(SkImage), dst: *SkRect, sampling: *SkSamplingOptions, paint: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImageRect@SkCanvas@@QEAAXAEBV?$sk_sp@VSkImage@@@@AEBUSkRect@@AEBUSkSamplingOptions@@PEBVSkPaint@@@Z";
    drawImageRect :: (this: *SkCanvas, image: sk_sp(SkImage), dst: SkRect, sampling: SkSamplingOptions, paint: *SkPaint = null) #no_context {
        drawImageRect(this, *image, *dst, *sampling, paint);
    }

    /** Draws SkImage image stretched proportionally to fit into SkRect dst.
    SkIRect center divides the image into nine sections: four sides, four corners, and
    the center. Corners are unmodified or scaled down proportionately if their sides
    are larger than dst; center and four sides are scaled to fit remaining space, if any.
    
    Additionally transform draw using clip, SkMatrix, and optional SkPaint paint.
    
    If SkPaint paint is supplied, apply SkColorFilter, alpha, SkImageFilter, and
    SkBlendMode. If image is kAlpha_8_SkColorType, apply SkShader.
    If paint contains SkMaskFilter, generate mask from image bounds.
    Any SkMaskFilter on paint is ignored as is paint anti-aliasing state.
    
    If generated mask extends beyond image bounds, replicate image edge colors, just
    as SkShader made from SkImage::makeShader with SkShader::kClamp_TileMode set
    replicates the image edge color when it samples outside of its bounds.
    
    @param image   SkImage containing pixels, dimensions, and format
    @param center  SkIRect edge of image corners and sides
    @param dst     destination SkRect of image to draw to
    @param filter  what technique to use when sampling the image
    @param paint   SkPaint containing SkBlendMode, SkColorFilter, SkImageFilter,
    and so on; or nullptr
    */
    drawImageNine :: (this: *SkCanvas, image: *SkImage, center: *SkIRect, dst: *SkRect, filter: SkFilterMode, paint: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImageNine@SkCanvas@@QEAAXPEBVSkImage@@AEBUSkIRect@@AEBUSkRect@@W4SkFilterMode@@PEBVSkPaint@@@Z";
    drawImageNine :: (this: *SkCanvas, image: *SkImage, center: SkIRect, dst: SkRect, filter: SkFilterMode, paint: *SkPaint = null) #no_context {
        drawImageNine(this, image, *center, *dst, filter, paint);
    }

    /** \struct SkCanvas::Lattice
    SkCanvas::Lattice divides SkBitmap or SkImage into a rectangular grid.
    Grid entries on even columns and even rows are fixed; these entries are
    always drawn at their original size if the destination is large enough.
    If the destination side is too small to hold the fixed entries, all fixed
    entries are proportionately scaled down to fit.
    The grid entries not on even columns and rows are scaled to fit the
    remaining space, if any.
    */
    Lattice :: struct {
        /** \enum SkCanvas::Lattice::RectType
        Optional setting per rectangular grid entry to make it transparent,
        or to fill the grid entry with a color.
        */
        RectType :: enum u8 {
            Default     :: 0;
            Transparent :: 1;
            FixedColor  :: 2;

            kDefault     :: Default;
            kTransparent :: Transparent;
            kFixedColor  :: FixedColor;
        }

        fXDivs:     *s32; //!< x-axis values dividing bitmap
        fYDivs:     *s32; //!< y-axis values dividing bitmap
        fRectTypes: *RectType; //!< array of fill types
        fXCount:    s32; //!< number of x-coordinates
        fYCount:    s32; //!< number of y-coordinates
        fBounds:    *SkIRect; //!< source bounds to draw from
        fColors:    *SkColor; //!< array of colors
    }

    /** Draws SkImage image stretched proportionally to fit into SkRect dst.
    
    SkCanvas::Lattice lattice divides image into a rectangular grid.
    Each intersection of an even-numbered row and column is fixed;
    fixed lattice elements never scale larger than their initial
    size and shrink proportionately when all fixed elements exceed the bitmap
    dimension. All other grid elements scale to fill the available space, if any.
    
    Additionally transform draw using clip, SkMatrix, and optional SkPaint paint.
    
    If SkPaint paint is supplied, apply SkColorFilter, alpha, SkImageFilter, and
    SkBlendMode. If image is kAlpha_8_SkColorType, apply SkShader.
    If paint contains SkMaskFilter, generate mask from image bounds.
    Any SkMaskFilter on paint is ignored as is paint anti-aliasing state.
    
    If generated mask extends beyond bitmap bounds, replicate bitmap edge colors,
    just as SkShader made from SkShader::MakeBitmapShader with
    SkShader::kClamp_TileMode set replicates the bitmap edge color when it samples
    outside of its bounds.
    
    @param image    SkImage containing pixels, dimensions, and format
    @param lattice  division of bitmap into fixed and variable rectangles
    @param dst      destination SkRect of image to draw to
    @param filter   what technique to use when sampling the image
    @param paint    SkPaint containing SkBlendMode, SkColorFilter, SkImageFilter,
    and so on; or nullptr
    */
    drawImageLattice :: (this: *SkCanvas, image: *SkImage, lattice: *SkCanvas.Lattice, dst: *SkRect, filter: SkFilterMode, paint: *SkPaint = null) -> void #cpp_method #foreign libskia "?drawImageLattice@SkCanvas@@QEAAXPEBVSkImage@@AEBULattice@1@AEBUSkRect@@W4SkFilterMode@@PEBVSkPaint@@@Z";
    drawImageLattice :: (this: *SkCanvas, image: *SkImage, lattice: SkCanvas.Lattice, dst: SkRect, filter: SkFilterMode, paint: *SkPaint = null) #no_context {
        drawImageLattice(this, image, *lattice, *dst, filter, paint);
    }

    drawImageLattice :: (this: *SkCanvas, image: *SkImage, lattice: *SkCanvas.Lattice, dst: *SkRect) -> void #cpp_method #foreign libskia "?drawImageLattice@SkCanvas@@QEAAXPEBVSkImage@@AEBULattice@1@AEBUSkRect@@@Z";
    drawImageLattice :: (this: *SkCanvas, image: *SkImage, lattice: SkCanvas.Lattice, dst: SkRect) #no_context {
        drawImageLattice(this, image, *lattice, *dst);
    }

    /**
    * Experimental. Controls anti-aliasing of each edge of images in an image-set.
    */
    QuadAAFlags :: enum u32 {
        Left_QuadAAFlag   :: 1;
        Top_QuadAAFlag    :: 2;
        Right_QuadAAFlag  :: 4;
        Bottom_QuadAAFlag :: 8;

        None_QuadAAFlags  :: 0;
        All_QuadAAFlags   :: 15;

        kLeft_QuadAAFlag   :: Left_QuadAAFlag;
        kTop_QuadAAFlag    :: Top_QuadAAFlag;
        kRight_QuadAAFlag  :: Right_QuadAAFlag;
        kBottom_QuadAAFlag :: Bottom_QuadAAFlag;

        kNone_QuadAAFlags  :: None_QuadAAFlags;
        kAll_QuadAAFlags   :: All_QuadAAFlags;
    }

    /** This is used by the experimental API below. */
    ImageSetEntry :: struct {
        Constructor :: (this: *ImageSetEntry, image: sk_sp(SkImage), srcRect: *SkRect, dstRect: *SkRect, matrixIndex: s32, alpha: float, aaFlags: u32, hasClip: bool) -> void #cpp_method #foreign libskia "??0ImageSetEntry@SkCanvas@@QEAA@V?$sk_sp@$$CBVSkImage@@@@AEBUSkRect@@1HMI_N@Z";
        Constructor :: (this: *ImageSetEntry, image: sk_sp(SkImage), srcRect: SkRect, dstRect: SkRect, matrixIndex: s32, alpha: float, aaFlags: u32, hasClip: bool) #no_context {
            Constructor(this, image, *srcRect, *dstRect, matrixIndex, alpha, aaFlags, hasClip);
        }

        Constructor :: (this: *ImageSetEntry, image: sk_sp(SkImage), srcRect: *SkRect, dstRect: *SkRect, alpha: float, aaFlags: u32) -> void #cpp_method #foreign libskia "??0ImageSetEntry@SkCanvas@@QEAA@V?$sk_sp@$$CBVSkImage@@@@AEBUSkRect@@1MI@Z";
        Constructor :: (this: *ImageSetEntry, image: sk_sp(SkImage), srcRect: SkRect, dstRect: SkRect, alpha: float, aaFlags: u32) #no_context {
            Constructor(this, image, *srcRect, *dstRect, alpha, aaFlags);
        }

        Constructor :: (this: *ImageSetEntry) -> void #cpp_method #foreign libskia "??0ImageSetEntry@SkCanvas@@QEAA@XZ";
        Destructor :: (this: *ImageSetEntry) -> void #cpp_method #foreign libskia "??1ImageSetEntry@SkCanvas@@QEAA@XZ";
        CopyConstructor :: (this: *ImageSetEntry, unknown0: *ImageSetEntry) -> void #cpp_method #foreign libskia "??0ImageSetEntry@SkCanvas@@QEAA@AEBU01@@Z";
        CopyConstructor :: (this: *ImageSetEntry, unknown0: ImageSetEntry) #no_context {
            CopyConstructor(this, *unknown0);
        }

        fImage:       sk_sp(SkImage);
        fSrcRect:     SkRect;
        fDstRect:     SkRect;
        fMatrixIndex: s32 = -1; // Index into the preViewMatrices arg, or < 0
        fAlpha:       float = 1.0;
        fAAFlags:     u32 = xx QuadAAFlags.None_QuadAAFlags; // QuadAAFlags
        fHasClip      := false; // True to use next 4 points in dstClip arg as quad
    }

    operator_assign :: (this: *SkCanvas.ImageSetEntry, unknown0: *SkCanvas.ImageSetEntry) -> *SkCanvas.ImageSetEntry #cpp_method #foreign libskia "??4ImageSetEntry@SkCanvas@@QEAAAEAU01@AEBU01@@Z";
    operator_assign :: (this: *SkCanvas.ImageSetEntry, unknown0: SkCanvas.ImageSetEntry) -> *SkCanvas.ImageSetEntry #no_context {
        return operator_assign(this, *unknown0);
    }

    /**
    * This is an experimental API for the SkiaRenderer Chromium project, and its API will surely
    * evolve if it is not removed outright.
    *
    * This behaves very similarly to drawRect() combined with a clipPath() formed by clip
    * quadrilateral. 'rect' and 'clip' are in the same coordinate space. If 'clip' is null, then it
    * is as if the rectangle was not clipped (or, alternatively, clipped to itself). If not null,
    * then it must provide 4 points.
    *
    * In addition to combining the draw and clipping into one operation, this function adds the
    * additional capability of controlling each of the rectangle's edges anti-aliasing
    * independently.  The edges of the clip will respect the per-edge AA flags. It is required that
    * 'clip' be contained inside 'rect'. In terms of mapping to edge labels, the 'clip' points
    * should be ordered top-left, top-right, bottom-right, bottom-left so that the edge between [0]
    * and [1] is "top", [1] and [2] is "right", [2] and [3] is "bottom", and [3] and [0] is "left".
    * This ordering matches SkRect::toQuad().
    *
    * This API only draws solid color, filled rectangles so it does not accept a full SkPaint.
    */
    experimental_DrawEdgeAAQuad :: (this: *SkCanvas, rect: *SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: *SkColor4f, mode: SkBlendMode) -> void #cpp_method #foreign libskia "?experimental_DrawEdgeAAQuad@SkCanvas@@QEAAXAEBUSkRect@@QEBUSkPoint@@W4QuadAAFlags@1@AEBU?$SkRGBA4f@$02@@W4SkBlendMode@@@Z";
    experimental_DrawEdgeAAQuad :: (this: *SkCanvas, rect: SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: SkColor4f, mode: SkBlendMode) #no_context {
        experimental_DrawEdgeAAQuad(this, *rect, clip, aaFlags, *color, mode);
    }

    experimental_DrawEdgeAAQuad :: (this: *SkCanvas, rect: *SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: SkColor, mode: SkBlendMode) -> void #cpp_method #foreign libskia "?experimental_DrawEdgeAAQuad@SkCanvas@@QEAAXAEBUSkRect@@QEBUSkPoint@@W4QuadAAFlags@1@IW4SkBlendMode@@@Z";
    experimental_DrawEdgeAAQuad :: (this: *SkCanvas, rect: SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: SkColor, mode: SkBlendMode) #no_context {
        experimental_DrawEdgeAAQuad(this, *rect, clip, aaFlags, color, mode);
    }

    /**
    * This is an bulk variant of experimental_DrawEdgeAAQuad() that renders 'cnt' textured quads.
    * For each entry, 'fDstRect' is rendered with its clip (determined by entry's 'fHasClip' and
    * the current index in 'dstClip'). The entry's fImage is applied to the destination rectangle
    * by sampling from 'fSrcRect' sub-image.  The corners of 'fSrcRect' map to the corners of
    * 'fDstRect', just like in drawImageRect(), and they will be properly interpolated when
    * applying a clip.
    *
    * Like experimental_DrawEdgeAAQuad(), each entry can specify edge AA flags that apply to both
    * the destination rect and its clip.
    *
    * If provided, the 'dstClips' array must have length equal 4 * the number of entries with
    * fHasClip true. If 'dstClips' is null, every entry must have 'fHasClip' set to false. The
    * destination clip coordinates will be read consecutively with the image set entries, advancing
    * by 4 points every time an entry with fHasClip is passed.
    *
    * This entry point supports per-entry manipulations to the canvas's current matrix. If an
    * entry provides 'fMatrixIndex' >= 0, it will be drawn as if the canvas's CTM was
    * canvas->getTotalMatrix() * preViewMatrices[fMatrixIndex]. If 'fMatrixIndex' is less than 0,
    * the pre-view matrix transform is implicitly the identity, so it will be drawn using just the
    * current canvas matrix. The pre-view matrix modifies the canvas's view matrix, it does not
    * affect the local coordinates of each entry.
    *
    * An optional paint may be provided, which supports the same subset of features usable with
    * drawImageRect (i.e. assumed to be filled and no path effects). When a paint is provided, the
    * image set is drawn as if each image used the applied paint independently, so each is affected
    * by the image, color, and/or mask filter.
    */
    experimental_DrawEdgeAAImageSet :: (this: *SkCanvas, imageSet: *SkCanvas.ImageSetEntry, cnt: s32, dstClips: *SkPoint, preViewMatrices: *SkMatrix, unknown0: *SkSamplingOptions, paint: *SkPaint = null, constraint: SkCanvas.SrcRectConstraint = .Strict_SrcRectConstraint) -> void #cpp_method #foreign libskia "?experimental_DrawEdgeAAImageSet@SkCanvas@@QEAAXQEBUImageSetEntry@1@HQEBUSkPoint@@QEBVSkMatrix@@AEBUSkSamplingOptions@@PEBVSkPaint@@W4SrcRectConstraint@1@@Z";
    experimental_DrawEdgeAAImageSet :: (this: *SkCanvas, imageSet: *SkCanvas.ImageSetEntry, cnt: s32, dstClips: *SkPoint, preViewMatrices: *SkMatrix, unknown0: SkSamplingOptions, paint: *SkPaint = null, constraint: SkCanvas.SrcRectConstraint = .Strict_SrcRectConstraint) #no_context {
        experimental_DrawEdgeAAImageSet(this, imageSet, cnt, dstClips, preViewMatrices, *unknown0, paint, constraint);
    }

    /** Draws text, with origin at (x, y), using clip, SkMatrix, SkFont font,
    and SkPaint paint.
    
    When encoding is SkTextEncoding::kUTF8, SkTextEncoding::kUTF16, or
    SkTextEncoding::kUTF32, this function uses the default
    character-to-glyph mapping from the SkTypeface in font.  It does not
    perform typeface fallback for characters not found in the SkTypeface.
    It does not perform kerning or other complex shaping; glyphs are
    positioned based on their default advances.
    
    Text meaning depends on SkTextEncoding.
    
    Text size is affected by SkMatrix and SkFont text size. Default text
    size is 12 point.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param text        character code points or glyphs drawn
    @param byteLength  byte length of text array
    @param encoding    text encoding used in the text array
    @param x           start of text on x-axis
    @param y           start of text on y-axis
    @param font        typeface, text size and so, used to describe the text
    @param paint       blend, color, and so on, used to draw
    */
    drawSimpleText :: (this: *SkCanvas, text: *void, byteLength: u64, encoding: SkTextEncoding, x: SkScalar, y: SkScalar, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawSimpleText@SkCanvas@@QEAAXPEBX_KW4SkTextEncoding@@MMAEBVSkFont@@AEBVSkPaint@@@Z";
    drawSimpleText :: (this: *SkCanvas, text: *void, byteLength: u64, encoding: SkTextEncoding, x: SkScalar, y: SkScalar, font: SkFont, paint: SkPaint) #no_context {
        drawSimpleText(this, text, byteLength, encoding, x, y, *font, *paint);
    }

    /** Draws null terminated string, with origin at (x, y), using clip, SkMatrix,
    SkFont font, and SkPaint paint.
    
    This function uses the default character-to-glyph mapping from the
    SkTypeface in font.  It does not perform typeface fallback for
    characters not found in the SkTypeface.  It does not perform kerning;
    glyphs are positioned based on their default advances.
    
    String str is encoded as UTF-8.
    
    Text size is affected by SkMatrix and font text size. Default text
    size is 12 point.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param str     character code points drawn,
    ending with a char value of zero
    @param x       start of string on x-axis
    @param y       start of string on y-axis
    @param font    typeface, text size and so, used to describe the text
    @param paint   blend, color, and so on, used to draw
    */
    drawString :: (this: *SkCanvas, str: *u8, x: SkScalar, y: SkScalar, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawString@SkCanvas@@QEAAXQEBDMMAEBVSkFont@@AEBVSkPaint@@@Z";
    drawString :: (this: *SkCanvas, str: *u8, x: SkScalar, y: SkScalar, font: SkFont, paint: SkPaint) #no_context {
        drawString(this, str, x, y, *font, *paint);
    }

    /** Draws SkString, with origin at (x, y), using clip, SkMatrix, SkFont font,
    and SkPaint paint.
    
    This function uses the default character-to-glyph mapping from the
    SkTypeface in font.  It does not perform typeface fallback for
    characters not found in the SkTypeface.  It does not perform kerning;
    glyphs are positioned based on their default advances.
    
    SkString str is encoded as UTF-8.
    
    Text size is affected by SkMatrix and SkFont text size. Default text
    size is 12 point.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param str     character code points drawn,
    ending with a char value of zero
    @param x       start of string on x-axis
    @param y       start of string on y-axis
    @param font    typeface, text size and so, used to describe the text
    @param paint   blend, color, and so on, used to draw
    */
    drawString :: (this: *SkCanvas, str: *SkString, x: SkScalar, y: SkScalar, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawString@SkCanvas@@QEAAXAEBVSkString@@MMAEBVSkFont@@AEBVSkPaint@@@Z";
    drawString :: (this: *SkCanvas, str: SkString, x: SkScalar, y: SkScalar, font: SkFont, paint: SkPaint) #no_context {
        drawString(this, *str, x, y, *font, *paint);
    }

    /** Draws count glyphs, at positions relative to origin styled with font and paint with
    supporting utf8 and cluster information.
    
    This function draw glyphs at the given positions relative to the given origin.
    It does not perform typeface fallback for glyphs not found in the SkTypeface in font.
    
    The drawing obeys the current transform matrix and clipping.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param glyphs          the span of glyphIDs to draw
    @param positions       where to draw each glyph relative to origin
    @param clusters        cluster information
    @param utf8text        utf8text supporting information for the glyphs
    @param origin          the origin of all the positions
    @param font            typeface, text size and so, used to describe the text
    @param paint           blend, color, and so on, used to draw
    */
    drawGlyphs :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), positions: SkSpan(SkPoint), clusters: SkSpan(u32), utf8text: SkSpan(u8), origin: SkPoint, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawGlyphs@SkCanvas@@QEAAXV?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkPoint@@@@V?$SkSpan@$$CBI@@V?$SkSpan@$$CBD@@USkPoint@@AEBVSkFont@@AEBVSkPaint@@@Z";
    drawGlyphs :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), positions: SkSpan(SkPoint), clusters: SkSpan(u32), utf8text: SkSpan(u8), origin: SkPoint, font: SkFont, paint: SkPaint) #no_context {
        drawGlyphs(this, glyphs, positions, clusters, utf8text, origin, *font, *paint);
    }

    /** Draws count glyphs, at positions relative to origin styled with font and paint.
    
    This function draw glyphs at the given positions relative to the given origin.
    It does not perform typeface fallback for glyphs not found in the SkTypeface in font.
    
    The drawing obeys the current transform matrix and clipping.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param count       number of glyphs to draw
    @param glyphs      the array of glyphIDs to draw
    @param positions   where to draw each glyph relative to origin
    @param origin      the origin of all the positions
    @param font        typeface, text size and so, used to describe the text
    @param paint       blend, color, and so on, used to draw
    */
    drawGlyphs :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), positions: SkSpan(SkPoint), origin: SkPoint, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawGlyphs@SkCanvas@@QEAAXV?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkPoint@@@@USkPoint@@AEBVSkFont@@AEBVSkPaint@@@Z";
    drawGlyphs :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), positions: SkSpan(SkPoint), origin: SkPoint, font: SkFont, paint: SkPaint) #no_context {
        drawGlyphs(this, glyphs, positions, origin, *font, *paint);
    }

    /** Draws count glyphs, at positions relative to origin styled with font and paint.
    
    This function draw glyphs using the given scaling and rotations. They are positioned
    relative to the given origin. It does not perform typeface fallback for glyphs not found
    in the SkTypeface in font.
    
    The drawing obeys the current transform matrix and clipping.
    
    All elements of paint: SkPathEffect, SkMaskFilter, SkShader,
    SkColorFilter, and SkImageFilter; apply to text. By
    default, draws filled black glyphs.
    
    @param count    number of glyphs to draw
    @param glyphs   the array of glyphIDs to draw
    @param xforms   where to draw and orient each glyph
    @param origin   the origin of all the positions
    @param font     typeface, text size and so, used to describe the text
    @param paint    blend, color, and so on, used to draw
    */
    drawGlyphsRSXform :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), xforms: SkSpan(SkRSXform), origin: SkPoint, font: *SkFont, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawGlyphsRSXform@SkCanvas@@QEAAXV?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkRSXform@@@@USkPoint@@AEBVSkFont@@AEBVSkPaint@@@Z";
    drawGlyphsRSXform :: (this: *SkCanvas, glyphs: SkSpan(SkGlyphID), xforms: SkSpan(SkRSXform), origin: SkPoint, font: SkFont, paint: SkPaint) #no_context {
        drawGlyphsRSXform(this, glyphs, xforms, origin, *font, *paint);
    }

    /** Draws SkTextBlob blob at (x, y), using clip, SkMatrix, and SkPaint paint.
    
    blob contains glyphs, their positions, and paint attributes specific to text:
    SkTypeface, SkPaint text size, SkPaint text scale x,
    SkPaint text skew x, SkPaint::Align, SkPaint::Hinting, anti-alias, SkPaint fake bold,
    SkPaint font embedded bitmaps, SkPaint full hinting spacing, LCD text, SkPaint linear text,
    and SkPaint subpixel text.
    
    SkTextEncoding must be set to SkTextEncoding::kGlyphID.
    
    Elements of paint: anti-alias, SkBlendMode, color including alpha,
    SkColorFilter, SkPaint dither, SkMaskFilter, SkPathEffect, SkShader, and
    SkPaint::Style; apply to blob. If SkPaint contains SkPaint::kStroke_Style:
    SkPaint miter limit, SkPaint::Cap, SkPaint::Join, and SkPaint stroke width;
    apply to SkPath created from blob.
    
    @param blob   glyphs, positions, and their paints' text size, typeface, and so on
    @param x      horizontal offset applied to blob
    @param y      vertical offset applied to blob
    @param paint  blend, color, stroking, and so on, used to draw
    
    example: https://fiddle.skia.org/c/@Canvas_drawTextBlob
    */
    drawTextBlob :: (this: *SkCanvas, blob: *SkTextBlob, x: SkScalar, y: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawTextBlob@SkCanvas@@QEAAXPEBVSkTextBlob@@MMAEBVSkPaint@@@Z";
    drawTextBlob :: (this: *SkCanvas, blob: *SkTextBlob, x: SkScalar, y: SkScalar, paint: SkPaint) #no_context {
        drawTextBlob(this, blob, x, y, *paint);
    }

    /** Draws SkTextBlob blob at (x, y), using clip, SkMatrix, and SkPaint paint.
    
    blob contains glyphs, their positions, and paint attributes specific to text:
    SkTypeface, SkPaint text size, SkPaint text scale x,
    SkPaint text skew x, SkPaint::Align, SkPaint::Hinting, anti-alias, SkPaint fake bold,
    SkPaint font embedded bitmaps, SkPaint full hinting spacing, LCD text, SkPaint linear text,
    and SkPaint subpixel text.
    
    SkTextEncoding must be set to SkTextEncoding::kGlyphID.
    
    Elements of paint: SkPathEffect, SkMaskFilter, SkShader, SkColorFilter,
    and SkImageFilter; apply to blob.
    
    @param blob   glyphs, positions, and their paints' text size, typeface, and so on
    @param x      horizontal offset applied to blob
    @param y      vertical offset applied to blob
    @param paint  blend, color, stroking, and so on, used to draw
    */
    drawTextBlob :: (this: *SkCanvas, blob: *sk_sp(SkTextBlob), x: SkScalar, y: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawTextBlob@SkCanvas@@QEAAXAEBV?$sk_sp@VSkTextBlob@@@@MMAEBVSkPaint@@@Z";
    drawTextBlob :: (this: *SkCanvas, blob: sk_sp(SkTextBlob), x: SkScalar, y: SkScalar, paint: SkPaint) #no_context {
        drawTextBlob(this, *blob, x, y, *paint);
    }

    /** Draws SkPicture picture, using clip and SkMatrix.
    Clip and SkMatrix are unchanged by picture contents, as if
    save() was called before and restore() was called after drawPicture().
    
    SkPicture records a series of draw commands for later playback.
    
    @param picture  recorded drawing commands to play
    */
    drawPicture :: (this: *SkCanvas, picture: *SkPicture) -> void #cpp_method #foreign libskia "?drawPicture@SkCanvas@@QEAAXPEBVSkPicture@@@Z";

    /** Draws SkPicture picture, using clip and SkMatrix.
    Clip and SkMatrix are unchanged by picture contents, as if
    save() was called before and restore() was called after drawPicture().
    
    SkPicture records a series of draw commands for later playback.
    
    @param picture  recorded drawing commands to play
    */
    drawPicture :: (this: *SkCanvas, picture: *sk_sp(SkPicture)) -> void #cpp_method #foreign libskia "?drawPicture@SkCanvas@@QEAAXAEBV?$sk_sp@VSkPicture@@@@@Z";
    drawPicture :: (this: *SkCanvas, picture: sk_sp(SkPicture)) #no_context {
        drawPicture(this, *picture);
    }

    /** Draws SkPicture picture, using clip and SkMatrix; transforming picture with
    SkMatrix matrix, if provided; and use SkPaint paint alpha, SkColorFilter,
    SkImageFilter, and SkBlendMode, if provided.
    
    If paint is non-null, then the picture is always drawn into a temporary layer before
    actually landing on the canvas. Note that drawing into a layer can also change its
    appearance if there are any non-associative blendModes inside any of the pictures elements.
    
    @param picture  recorded drawing commands to play
    @param matrix   SkMatrix to rotate, scale, translate, and so on; may be nullptr
    @param paint    SkPaint to apply transparency, filtering, and so on; may be nullptr
    
    example: https://fiddle.skia.org/c/@Canvas_drawPicture_3
    */
    drawPicture :: (this: *SkCanvas, picture: *SkPicture, matrix: *SkMatrix, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPicture@SkCanvas@@QEAAXPEBVSkPicture@@PEBVSkMatrix@@PEBVSkPaint@@@Z";

    /** Draws SkPicture picture, using clip and SkMatrix; transforming picture with
    SkMatrix matrix, if provided; and use SkPaint paint alpha, SkColorFilter,
    SkImageFilter, and SkBlendMode, if provided.
    
    If paint is non-null, then the picture is always drawn into a temporary layer before
    actually landing on the canvas. Note that drawing into a layer can also change its
    appearance if there are any non-associative blendModes inside any of the pictures elements.
    
    @param picture  recorded drawing commands to play
    @param matrix   SkMatrix to rotate, scale, translate, and so on; may be nullptr
    @param paint    SkPaint to apply transparency, filtering, and so on; may be nullptr
    */
    drawPicture :: (this: *SkCanvas, picture: *sk_sp(SkPicture), matrix: *SkMatrix, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPicture@SkCanvas@@QEAAXAEBV?$sk_sp@VSkPicture@@@@PEBVSkMatrix@@PEBVSkPaint@@@Z";
    drawPicture :: (this: *SkCanvas, picture: sk_sp(SkPicture), matrix: *SkMatrix, paint: *SkPaint) #no_context {
        drawPicture(this, *picture, matrix, paint);
    }

    /** Draws SkVertices vertices, a triangle mesh, using clip and SkMatrix.
    If paint contains an SkShader and vertices does not contain texCoords, the shader
    is mapped using the vertices' positions.
    
    SkBlendMode is ignored if SkVertices does not have colors. Otherwise, it combines
    - the SkShader if SkPaint contains SkShader
    - or the opaque SkPaint color if SkPaint does not contain SkShader
    as the src of the blend and the interpolated vertex colors as the dst.
    
    SkMaskFilter, SkPathEffect, and antialiasing on SkPaint are ignored.
    
    @param vertices  triangle mesh to draw
    @param mode      combines vertices' colors with SkShader if present or SkPaint opaque color
    if not. Ignored if the vertices do not contain color.
    @param paint     specifies the SkShader, used as SkVertices texture, and SkColorFilter.
    
    example: https://fiddle.skia.org/c/@Canvas_drawVertices
    */
    drawVertices :: (this: *SkCanvas, vertices: *SkVertices, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawVertices@SkCanvas@@QEAAXPEBVSkVertices@@W4SkBlendMode@@AEBVSkPaint@@@Z";
    drawVertices :: (this: *SkCanvas, vertices: *SkVertices, mode: SkBlendMode, paint: SkPaint) #no_context {
        drawVertices(this, vertices, mode, *paint);
    }

    /** Draws SkVertices vertices, a triangle mesh, using clip and SkMatrix.
    If paint contains an SkShader and vertices does not contain texCoords, the shader
    is mapped using the vertices' positions.
    
    SkBlendMode is ignored if SkVertices does not have colors. Otherwise, it combines
    - the SkShader if SkPaint contains SkShader
    - or the opaque SkPaint color if SkPaint does not contain SkShader
    as the src of the blend and the interpolated vertex colors as the dst.
    
    SkMaskFilter, SkPathEffect, and antialiasing on SkPaint are ignored.
    
    @param vertices  triangle mesh to draw
    @param mode      combines vertices' colors with SkShader if present or SkPaint opaque color
    if not. Ignored if the vertices do not contain color.
    @param paint     specifies the SkShader, used as SkVertices texture, may be nullptr
    
    example: https://fiddle.skia.org/c/@Canvas_drawVertices_2
    */
    drawVertices :: (this: *SkCanvas, vertices: *sk_sp(SkVertices), mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawVertices@SkCanvas@@QEAAXAEBV?$sk_sp@VSkVertices@@@@W4SkBlendMode@@AEBVSkPaint@@@Z";
    drawVertices :: (this: *SkCanvas, vertices: sk_sp(SkVertices), mode: SkBlendMode, paint: SkPaint) #no_context {
        drawVertices(this, *vertices, mode, *paint);
    }

    /**
    Experimental, under active development, and subject to change without notice.
    
    Draws a mesh using a user-defined specification (see SkMeshSpecification). Requires
    a GPU backend or SkSL to be compiled in.
    
    SkBlender is ignored if SkMesh's specification does not output fragment shader color.
    Otherwise, it combines
    - the SkShader if SkPaint contains SkShader
    - or the opaque SkPaint color if SkPaint does not contain SkShader
    as the src of the blend and the mesh's fragment color as the dst.
    
    SkMaskFilter, SkPathEffect, and antialiasing on SkPaint are ignored.
    
    @param mesh      the mesh vertices and compatible specification.
    @param blender   combines vertices colors with SkShader if present or SkPaint opaque color
    if not. Ignored if the custom mesh does not output color. Defaults to
    SkBlendMode::kModulate if nullptr.
    @param paint     specifies the SkShader, used as SkVertices texture, may be nullptr
    */
    drawMesh :: (this: *SkCanvas, mesh: *SkMesh, blender: sk_sp(SkBlender), paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawMesh@SkCanvas@@QEAAXAEBVSkMesh@@V?$sk_sp@VSkBlender@@@@AEBVSkPaint@@@Z";
    drawMesh :: (this: *SkCanvas, mesh: SkMesh, blender: sk_sp(SkBlender), paint: SkPaint) #no_context {
        drawMesh(this, *mesh, blender, *paint);
    }

    /** Draws a Coons patch: the interpolation of four cubics with shared corners,
    associating a color, and optionally a texture SkPoint, with each corner.
    
    SkPoint array cubics specifies four SkPath cubic starting at the top-left corner,
    in clockwise order, sharing every fourth point. The last SkPath cubic ends at the
    first point.
    
    Color array color associates colors with corners in top-left, top-right,
    bottom-right, bottom-left order.
    
    If paint contains SkShader, SkPoint array texCoords maps SkShader as texture to
    corners in top-left, top-right, bottom-right, bottom-left order. If texCoords is
    nullptr, SkShader is mapped using positions (derived from cubics).
    
    SkBlendMode is ignored if colors is null. Otherwise, it combines
    - the SkShader if SkPaint contains SkShader
    - or the opaque SkPaint color if SkPaint does not contain SkShader
    as the src of the blend and the interpolated patch colors as the dst.
    
    SkMaskFilter, SkPathEffect, and antialiasing on SkPaint are ignored.
    
    @param cubics     SkPath cubic array, sharing common points
    @param colors     color array, one for each corner
    @param texCoords  SkPoint array of texture coordinates, mapping SkShader to corners;
    may be nullptr
    @param mode       combines patch's colors with SkShader if present or SkPaint opaque color
    if not. Ignored if colors is null.
    @param paint      SkShader, SkColorFilter, SkBlendMode, used to draw
    */
    drawPatch :: (this: *SkCanvas, cubics: *[12] SkPoint, colors: *[4] SkColor, texCoords: *[4] SkPoint, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawPatch@SkCanvas@@QEAAXQEBUSkPoint@@QEBI0W4SkBlendMode@@AEBVSkPaint@@@Z";
    drawPatch :: (this: *SkCanvas, cubics: *[12] SkPoint, colors: *[4] SkColor, texCoords: *[4] SkPoint, mode: SkBlendMode, paint: SkPaint) #no_context {
        drawPatch(this, cubics, colors, texCoords, mode, *paint);
    }

    /** Draws a set of sprites from atlas, using clip, SkMatrix, and optional SkPaint paint.
    paint uses anti-alias, alpha, SkColorFilter, SkImageFilter, and SkBlendMode
    to draw, if present. For each entry in the array, SkRect tex locates sprite in
    atlas, and SkRSXform xform transforms it into destination space.
    
    SkMaskFilter and SkPathEffect on paint are ignored.
    
    For non-empty spans, the number of draws will be the min of
    xform.size(), tex.size(), and (if not empty) colors.size().
    
    Optional colors are applied for each sprite using SkBlendMode mode, treating
    sprite as source and colors as destination.
    Optional cullRect is a conservative bounds of all transformed sprites.
    If cullRect is outside of clip, canvas can skip drawing.
    
    If atlas is nullptr, this draws nothing.
    
    @param atlas     SkImage containing sprites
    @param xform     SkRSXform mappings for sprites in atlas
    @param tex       SkRect locations of sprites in atlas
    @param colors    one per sprite, blended with sprite using SkBlendMode; may be nullptr
    @param mode      SkBlendMode combining colors and sprites
    @param sampling  SkSamplingOptions used when sampling from the atlas image
    @param cullRect  bounds of transformed sprites for efficient clipping; may be nullptr
    @param paint     SkColorFilter, SkImageFilter, SkBlendMode, and so on; may be nullptr
    */
    drawAtlas :: (this: *SkCanvas, atlas: *SkImage, xform: SkSpan(SkRSXform), tex: SkSpan(SkRect), colors: SkSpan(SkColor), mode: SkBlendMode, sampling: *SkSamplingOptions, cullRect: *SkRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawAtlas@SkCanvas@@QEAAXPEBVSkImage@@V?$SkSpan@$$CBUSkRSXform@@@@V?$SkSpan@$$CBUSkRect@@@@V?$SkSpan@$$CBI@@W4SkBlendMode@@AEBUSkSamplingOptions@@PEBUSkRect@@PEBVSkPaint@@@Z";
    drawAtlas :: (this: *SkCanvas, atlas: *SkImage, xform: SkSpan(SkRSXform), tex: SkSpan(SkRect), colors: SkSpan(SkColor), mode: SkBlendMode, sampling: SkSamplingOptions, cullRect: *SkRect, paint: *SkPaint) #no_context {
        drawAtlas(this, atlas, xform, tex, colors, mode, *sampling, cullRect, paint);
    }

    /** Draws SkDrawable drawable using clip and SkMatrix, concatenated with
    optional matrix.
    
    If SkCanvas has an asynchronous implementation, as is the case
    when it is recording into SkPicture, then drawable will be referenced,
    so that SkDrawable::draw() can be called when the operation is finalized. To force
    immediate drawing, call SkDrawable::draw() instead.
    
    @param drawable  custom struct encapsulating drawing commands
    @param matrix    transformation applied to drawing; may be nullptr
    
    example: https://fiddle.skia.org/c/@Canvas_drawDrawable
    */
    drawDrawable :: (this: *SkCanvas, drawable: *SkDrawable, matrix: *SkMatrix = null) -> void #cpp_method #foreign libskia "?drawDrawable@SkCanvas@@QEAAXPEAVSkDrawable@@PEBVSkMatrix@@@Z";

    /** Draws SkDrawable drawable using clip and SkMatrix, offset by (x, y).
    
    If SkCanvas has an asynchronous implementation, as is the case
    when it is recording into SkPicture, then drawable will be referenced,
    so that SkDrawable::draw() can be called when the operation is finalized. To force
    immediate drawing, call SkDrawable::draw() instead.
    
    @param drawable  custom struct encapsulating drawing commands
    @param x         offset into SkCanvas writable pixels on x-axis
    @param y         offset into SkCanvas writable pixels on y-axis
    
    example: https://fiddle.skia.org/c/@Canvas_drawDrawable_2
    */
    drawDrawable :: (this: *SkCanvas, drawable: *SkDrawable, x: SkScalar, y: SkScalar) -> void #cpp_method #foreign libskia "?drawDrawable@SkCanvas@@QEAAXPEAVSkDrawable@@MM@Z";

    /** Associates SkRect on SkCanvas with an annotation; a key-value pair, where the key is
    a null-terminated UTF-8 string, and optional value is stored as SkData.
    
    Only some canvas implementations, such as recording to SkPicture, or drawing to
    document PDF, use annotations.
    
    @param rect   SkRect extent of canvas to annotate
    @param key    string used for lookup
    @param value  data holding value stored in annotation
    
    example: https://fiddle.skia.org/c/@Canvas_drawAnnotation_2
    */
    drawAnnotation :: (this: *SkCanvas, rect: *SkRect, key: *u8, value: *SkData) -> void #cpp_method #foreign libskia "?drawAnnotation@SkCanvas@@QEAAXAEBUSkRect@@QEBDPEAVSkData@@@Z";
    drawAnnotation :: (this: *SkCanvas, rect: SkRect, key: *u8, value: *SkData) #no_context {
        drawAnnotation(this, *rect, key, value);
    }

    /** Associates SkRect on SkCanvas when an annotation; a key-value pair, where the key is
    a null-terminated UTF-8 string, and optional value is stored as SkData.
    
    Only some canvas implementations, such as recording to SkPicture, or drawing to
    document PDF, use annotations.
    
    @param rect   SkRect extent of canvas to annotate
    @param key    string used for lookup
    @param value  data holding value stored in annotation
    */
    drawAnnotation :: (this: *SkCanvas, rect: *SkRect, key: *u8, value: *sk_sp(SkData)) -> void #cpp_method #foreign libskia "?drawAnnotation@SkCanvas@@QEAAXAEBUSkRect@@QEBDAEBV?$sk_sp@VSkData@@@@@Z";
    drawAnnotation :: (this: *SkCanvas, rect: SkRect, key: *u8, value: sk_sp(SkData)) #no_context {
        drawAnnotation(this, *rect, key, *value);
    }

    /** Returns the current transform from local coordinates to the 'device', which for most
    *  purposes means pixels.
    *
    *  @return transformation from local coordinates to device / pixels.
    */
    getLocalToDevice :: (this: *SkCanvas) -> SkM44 #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getLocalToDevice@SkCanvas@@QEBA?AVSkM44@@XZ";

    /**
    *  Throws away the 3rd row and column in the matrix, so be warned.
    */
    getLocalToDeviceAs3x3 :: (this: *SkCanvas) -> SkMatrix #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getLocalToDeviceAs3x3@SkCanvas@@QEBA?AVSkMatrix@@XZ";

    /** DEPRECATED
    *  Legacy version of getLocalToDevice(), which strips away any Z information, and
    *  just returns a 3x3 version.
    *
    *  @return 3x3 version of getLocalToDevice()
    *
    *  example: https://fiddle.skia.org/c/@Canvas_getTotalMatrix
    *  example: https://fiddle.skia.org/c/@Clip
    */
    getTotalMatrix :: (this: *SkCanvas) -> SkMatrix #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getTotalMatrix@SkCanvas@@QEBA?AVSkMatrix@@XZ";

    /**
    *  Returns the global clip as a region. If the clip contains AA, then only the bounds
    *  of the clip may be returned.
    */
    temporary_internal_getRgnClip :: (this: *SkCanvas, region: *SkRegion) -> void #cpp_method #foreign libskia "?temporary_internal_getRgnClip@SkCanvas@@QEAAXPEAVSkRegion@@@Z";

    private_draw_shadow_rec :: (this: *SkCanvas, unknown0: *SkPath, unknown1: *SkDrawShadowRec) -> void #cpp_method #foreign libskia "?private_draw_shadow_rec@SkCanvas@@QEAAXAEBVSkPath@@AEBUSkDrawShadowRec@@@Z";
    private_draw_shadow_rec :: (this: *SkCanvas, unknown0: SkPath, unknown1: SkDrawShadowRec) #no_context {
        private_draw_shadow_rec(this, *unknown0, *unknown1);
    }

    // Subclass save/restore notifiers.
    // Overriders should call the corresponding INHERITED method up the inheritance chain.
    // getSaveLayerStrategy()'s return value may suppress full layer allocation.
    SaveLayerStrategy :: enum s32 {
        FullLayer_SaveLayerStrategy :: 0;
        NoLayer_SaveLayerStrategy   :: 1;

        kFullLayer_SaveLayerStrategy :: FullLayer_SaveLayerStrategy;
        kNoLayer_SaveLayerStrategy   :: NoLayer_SaveLayerStrategy;
    }

    ClipEdgeStyle :: enum s32 {
        Hard_ClipEdgeStyle :: 0;
        Soft_ClipEdgeStyle :: 1;

        kHard_ClipEdgeStyle :: Hard_ClipEdgeStyle;
        kSoft_ClipEdgeStyle :: Soft_ClipEdgeStyle;
    }

    PredrawFlags :: enum u32 {
        None                    :: 0;
        OpaqueShaderOverride    :: 1;
        NonOpaqueShaderOverride :: 2;
        CheckForOverwrite       :: 4;
        SkipMaskFilterAutoLayer :: 8;

        kNone                    :: None;
        kOpaqueShaderOverride    :: OpaqueShaderOverride;
        kNonOpaqueShaderOverride :: NonOpaqueShaderOverride;
        kCheckForOverwrite       :: CheckForOverwrite;
        kSkipMaskFilterAutoLayer :: SkipMaskFilterAutoLayer;
    }

    // notify our surface (if we have one) that we are about to draw, so it
    // can perform copy-on-write or invalidate any cached images
    // returns false if the copy failed
    predrawNotify :: (this: *SkCanvas, willOverwritesEntireSurface := false) -> bool #cpp_method #foreign libskia "?predrawNotify@SkCanvas@@AEAA_N_N@Z";
    predrawNotify :: (this: *SkCanvas, unknown0: *SkRect, unknown1: *SkPaint, unknown2: SkEnumBitMask(SkCanvas.PredrawFlags)) -> bool #cpp_method #foreign libskia "?predrawNotify@SkCanvas@@AEAA_NPEBUSkRect@@PEBVSkPaint@@V?$SkEnumBitMask@W4PredrawFlags@SkCanvas@@@@@Z";

    // call the appropriate predrawNotify and create a layer if needed.
    aboutToDraw :: (this: *SkCanvas, paint: *SkPaint, rawBounds: *SkRect, flags: SkEnumBitMask(SkCanvas.PredrawFlags)) -> std.optional(AutoLayerForImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?aboutToDraw@SkCanvas@@AEAA?AV?$optional@VAutoLayerForImageFilter@@@std@@AEBVSkPaint@@PEBUSkRect@@V?$SkEnumBitMask@W4PredrawFlags@SkCanvas@@@@@Z";
    aboutToDraw :: (this: *SkCanvas, paint: SkPaint, rawBounds: *SkRect, flags: SkEnumBitMask(SkCanvas.PredrawFlags)) -> std.optional(AutoLayerForImageFilter) #no_context {
        return aboutToDraw(this, *paint, rawBounds, flags);
    }

    aboutToDraw :: (this: *SkCanvas, paint: *SkPaint, rawBounds: *SkRect = null) -> std.optional(AutoLayerForImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?aboutToDraw@SkCanvas@@AEAA?AV?$optional@VAutoLayerForImageFilter@@@std@@AEBVSkPaint@@PEBUSkRect@@@Z";
    aboutToDraw :: (this: *SkCanvas, paint: SkPaint, rawBounds: *SkRect = null) -> std.optional(AutoLayerForImageFilter) #no_context {
        return aboutToDraw(this, *paint, rawBounds);
    }

    // The bottom-most device in the stack, only changed by init(). Image properties and the final
    // canvas pixels are determined by this device.
    rootDevice :: (this: *SkCanvas) -> *SkDevice #cpp_method #foreign libskia "?rootDevice@SkCanvas@@AEBAPEAVSkDevice@@XZ";

    // The top-most device in the stack, will change within saveLayer()'s. All drawing and clipping
    // operations should route to this device.
    topDevice :: (this: *SkCanvas) -> *SkDevice #cpp_method #foreign libskia "?topDevice@SkCanvas@@AEBAPEAVSkDevice@@XZ";

    // Canvases maintain a sparse stack of layers, where the top-most layer receives the drawing,
    // clip, and matrix commands. There is a layer per call to saveLayer() using the
    // kFullLayer_SaveLayerStrategy.
    Layer :: struct {
        fDevice:          sk_sp(SkDevice);
        fImageFilters:    skia_private.STArray(1, sk_sp(SkImageFilter), true);
        fPaint:           SkPaint;
        fIsCoverage:      bool;
        fDiscard:         bool;

        // If true, the layer image is sized to include a 1px buffer that remains transparent
        // to allow for faster linear filtering under complex transforms.
        fIncludesPadding: bool;

//         Constructor :: (this: *Layer, device: sk_sp(SkDevice), imageFilters: FilterSpan, paint: *SkPaint, isCoverage: bool, includesPadding: bool) -> void #cpp_method #foreign libskia "??0Layer@SkCanvas@@QEAA@V?$sk_sp@VSkDevice@@@@V?$SkSpan@V?$sk_sp@VSkImageFilter@@@@@@AEBVSkPaint@@_N3@Z";
        Constructor :: (this: *Layer, device: sk_sp(SkDevice), imageFilters: FilterSpan, paint: SkPaint, isCoverage: bool, includesPadding: bool) #no_context {
            Constructor(this, device, imageFilters, *paint, isCoverage, includesPadding);
        }
    }

    // Encapsulate state needed to restore from saveBehind()
    BackImage :: struct {
        // Out of line to avoid including SkSpecialImage.h
//         Constructor :: (this: *BackImage, unknown0: sk_sp(SkSpecialImage), unknown1: SkIPoint) -> void #cpp_method #foreign libskia "??0BackImage@SkCanvas@@QEAA@V?$sk_sp@VSkSpecialImage@@@@USkIPoint@@@Z";
//         CopyConstructor :: (this: *BackImage, unknown0: *BackImage) -> void #cpp_method #foreign libskia "??0BackImage@SkCanvas@@QEAA@AEBU01@@Z";
        CopyConstructor :: (this: *BackImage, unknown0: BackImage) #no_context {
            CopyConstructor(this, *unknown0);
        }

//         Destructor :: (this: *BackImage) -> void #cpp_method #foreign libskia "??1BackImage@SkCanvas@@QEAA@XZ";

        fImage: sk_sp(SkSpecialImage);
        fLoc:   SkIPoint;
    }

//     operator_assign :: (this: *SkCanvas.BackImage, unknown0: *SkCanvas.BackImage) -> *SkCanvas.BackImage #cpp_method #foreign libskia "??4BackImage@SkCanvas@@QEAAAEAU01@AEBU01@@Z";
    operator_assign :: (this: *SkCanvas.BackImage, unknown0: SkCanvas.BackImage) -> *SkCanvas.BackImage #no_context {
        return operator_assign(this, *unknown0);
    }

    MCRec :: struct {
        // If not null, this MCRec corresponds with the saveLayer() record that made the layer.
        // The base "layer" is not stored here, since it is stored inline in SkCanvas and has no
        // restoration behavior.
        fLayer:             std.unique_ptr(Layer);

        // This points to the device of the top-most layer (which may be lower in the stack), or
        // to the canvas's fRootDevice. The MCRec does not own the device.
        fDevice:            *SkDevice;

        fBackImage:         std.unique_ptr(BackImage);
        fMatrix:            SkM44;
        fDeferredSaveCount: s32 = 0;

//         Constructor :: (this: *MCRec, device: *SkDevice) -> void #cpp_method #foreign libskia "??0MCRec@SkCanvas@@QEAA@PEAVSkDevice@@@Z";
//         Constructor :: (this: *MCRec, prev: *MCRec) -> void #cpp_method #foreign libskia "??0MCRec@SkCanvas@@QEAA@PEBV01@@Z";
//         Destructor :: (this: *MCRec) -> void #cpp_method #foreign libskia "??1MCRec@SkCanvas@@QEAA@XZ";

//         newLayer :: (this: *MCRec, layerDevice: sk_sp(SkDevice), filters: FilterSpan, restorePaint: *SkPaint, layerIsCoverage: bool, includesPadding: bool) -> void #cpp_method #foreign libskia "?newLayer@MCRec@SkCanvas@@QEAAXV?$sk_sp@VSkDevice@@@@V?$SkSpan@V?$sk_sp@VSkImageFilter@@@@@@AEBVSkPaint@@_N3@Z";
        newLayer :: (this: *MCRec, layerDevice: sk_sp(SkDevice), filters: FilterSpan, restorePaint: SkPaint, layerIsCoverage: bool, includesPadding: bool) #no_context {
            newLayer(this, layerDevice, filters, *restorePaint, layerIsCoverage, includesPadding);
        }

//         reset :: (this: *MCRec, device: *SkDevice) -> void #cpp_method #foreign libskia "?reset@MCRec@SkCanvas@@QEAAXPEAVSkDevice@@@Z";
    }

    kMCRecCount:               s32 : 32; // common depth for save/restores

    // This stack allocation of memory will be used to house the first kMCRecCount
    // layers without need to call malloc.
    fMCRecStorage:             [3072] std.byte;

    fMCStack:                  SkDeque; // uses the stack memory
    fMCRec:                    *SkCanvas.MCRec; // points to top of stack for convenience

    // Installed via init()
    fRootDevice:               sk_sp(SkDevice);

    fSaveCount:                s32; // value returned by getSaveCount()

    fAllocator:                std.unique_ptr(SkRasterHandleAllocator);

    fSurfaceBase:              *SkSurface_Base;
    getSurfaceBase :: (this: *SkCanvas) -> *SkSurface_Base #cpp_method #foreign libskia "?getSurfaceBase@SkCanvas@@AEBAPEAVSkSurface_Base@@XZ";
    setSurfaceBase :: (this: *SkCanvas, sb: *SkSurface_Base) -> void #cpp_method #foreign libskia "?setSurfaceBase@SkCanvas@@AEAAXPEAVSkSurface_Base@@@Z";

    fClipRestrictionRect:      SkIRect;
    fClipRestrictionSaveCount: s32 = -1;

    doSave :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?doSave@SkCanvas@@AEAAXXZ";
    checkForDeferredSave :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?checkForDeferredSave@SkCanvas@@AEAAXXZ";
    internalSetMatrix :: (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method #foreign libskia "?internalSetMatrix@SkCanvas@@AEAAXAEBVSkM44@@@Z";
    internalSetMatrix :: (this: *SkCanvas, unknown0: SkM44) #no_context {
        internalSetMatrix(this, *unknown0);
    }

    // For use by SkNoDrawCanvas (via SkCanvasVirtualEnforcer, which can't be a friend)
    Constructor :: (this: *SkCanvas, bounds: *SkIRect) -> void #cpp_method #foreign libskia "??0SkCanvas@@IEAA@AEBUSkIRect@@@Z";
    Constructor :: (this: *SkCanvas, bounds: SkIRect) #no_context {
        Constructor(this, *bounds);
    }

    Constructor :: (this: *SkCanvas, unknown0: *SkBitmap, unknown1: std.unique_ptr(SkRasterHandleAllocator), unknown2: SkRasterHandleAllocator.Handle, props: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkCanvas@@AEAA@AEBVSkBitmap@@V?$unique_ptr@VSkRasterHandleAllocator@@U?$default_delete@VSkRasterHandleAllocator@@@std@@@std@@PEAXPEBVSkSurfaceProps@@@Z";
    Constructor :: (this: *SkCanvas, unknown0: SkBitmap, unknown1: std.unique_ptr(SkRasterHandleAllocator), unknown2: SkRasterHandleAllocator.Handle, props: *SkSurfaceProps) #no_context {
        Constructor(this, *unknown0, unknown1, unknown2, props);
    }

//     CopyConstructor :: (this: *SkCanvas, unknown0: *SkCanvas) -> void #cpp_method #foreign libskia "??0SkCanvas@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkCanvas, unknown0: SkCanvas) #no_context {
        CopyConstructor(this, *unknown0);
    }

    /**
    * Convert a SkTextBlob to a sktext::gpu::Slug using the current canvas state.
    */
    convertBlobToSlug :: (this: *SkCanvas, blob: *SkTextBlob, origin: SkPoint, paint: *SkPaint) -> sk_sp(sktext.gpu.Slug) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?convertBlobToSlug@SkCanvas@@AEAA?AV?$sk_sp@VSlug@gpu@sktext@@@@AEBVSkTextBlob@@USkPoint@@AEBVSkPaint@@@Z";
    convertBlobToSlug :: (this: *SkCanvas, blob: SkTextBlob, origin: SkPoint, paint: SkPaint) -> sk_sp(sktext.gpu.Slug) #no_context {
        return convertBlobToSlug(this, *blob, origin, *paint);
    }

    /**
    * Draw an sktext::gpu::Slug given the current canvas state.
    */
    drawSlug :: (this: *SkCanvas, slug: *sktext.gpu.Slug, paint: *SkPaint) -> void #cpp_method #foreign libskia "?drawSlug@SkCanvas@@AEAAXPEBVSlug@gpu@sktext@@AEBVSkPaint@@@Z";
    drawSlug :: (this: *SkCanvas, slug: *sktext.gpu.Slug, paint: SkPaint) #no_context {
        drawSlug(this, slug, *paint);
    }

    /** Experimental
    *  Saves the specified subset of the current pixels in the current layer,
    *  and then clears those pixels to transparent black.
    *  Restores the pixels on restore() by drawing them in SkBlendMode::kDstOver.
    *
    *  @param subset   conservative bounds of the area to be saved / restored.
    *  @return depth of save state stack before this call was made.
    */
    only_axis_aligned_saveBehind :: (this: *SkCanvas, subset: *SkRect) -> s32 #cpp_method #foreign libskia "?only_axis_aligned_saveBehind@SkCanvas@@AEAAHPEBUSkRect@@@Z";

    /**
    *  Like drawPaint, but magically clipped to the most recent saveBehind buffer rectangle.
    *  If there is no active saveBehind, then this draws nothing.
    */
    drawClippedToSaveBehind :: (this: *SkCanvas, unknown0: *SkPaint) -> void #cpp_method #foreign libskia "?drawClippedToSaveBehind@SkCanvas@@AEAAXAEBVSkPaint@@@Z";
    drawClippedToSaveBehind :: (this: *SkCanvas, unknown0: SkPaint) #no_context {
        drawClippedToSaveBehind(this, *unknown0);
    }

    resetForNextPicture :: (this: *SkCanvas, bounds: *SkIRect) -> void #cpp_method #foreign libskia "?resetForNextPicture@SkCanvas@@AEAAXAEBUSkIRect@@@Z";
    resetForNextPicture :: (this: *SkCanvas, bounds: SkIRect) #no_context {
        resetForNextPicture(this, *bounds);
    }

    init :: (this: *SkCanvas, unknown0: sk_sp(SkDevice)) -> void #cpp_method #foreign libskia "?init@SkCanvas@@AEAAXV?$sk_sp@VSkDevice@@@@@Z";

    // All base onDrawX() functions should call this and skip drawing if it returns true.
    // If 'matrix' is non-null, it maps the paint's fast bounds before checking for quick rejection
    internalQuickReject :: (this: *SkCanvas, bounds: *SkRect, paint: *SkPaint, matrix: *SkMatrix = null) -> bool #cpp_method #foreign libskia "?internalQuickReject@SkCanvas@@AEAA_NAEBUSkRect@@AEBVSkPaint@@PEBVSkMatrix@@@Z";
    internalQuickReject :: (this: *SkCanvas, bounds: SkRect, paint: SkPaint, matrix: *SkMatrix = null) -> bool #no_context {
        return internalQuickReject(this, *bounds, *paint, matrix);
    }

    internalDrawPaint :: (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method #foreign libskia "?internalDrawPaint@SkCanvas@@AEAAXAEBVSkPaint@@@Z";
    internalDrawPaint :: (this: *SkCanvas, paint: SkPaint) #no_context {
        internalDrawPaint(this, *paint);
    }
    internalSaveLayer :: (this: *SkCanvas, unknown0: *SkCanvas.SaveLayerRec, unknown1: SkCanvas.SaveLayerStrategy, coverageOnly := false) -> void #cpp_method #foreign libskia "?internalSaveLayer@SkCanvas@@AEAAXAEBUSaveLayerRec@1@W4SaveLayerStrategy@1@_N@Z";
    internalSaveLayer :: (this: *SkCanvas, unknown0: SkCanvas.SaveLayerRec, unknown1: SkCanvas.SaveLayerStrategy, coverageOnly := false) #no_context {
        internalSaveLayer(this, *unknown0, unknown1, coverageOnly);
    }
    internalSaveBehind :: (this: *SkCanvas, unknown0: *SkRect) -> void #cpp_method #foreign libskia "?internalSaveBehind@SkCanvas@@AEAAXPEBUSkRect@@@Z";

    internalConcat44 :: (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method #foreign libskia "?internalConcat44@SkCanvas@@AEAAXAEBVSkM44@@@Z";
    internalConcat44 :: (this: *SkCanvas, unknown0: SkM44) #no_context {
        internalConcat44(this, *unknown0);
    }

    // shared by save() and saveLayer()
    internalSave :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?internalSave@SkCanvas@@AEAAXXZ";
    internalRestore :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?internalRestore@SkCanvas@@AEAAXXZ";

    DeviceCompatibleWithFilter :: enum s32 {
        Unknown        :: 0;

        Yes            :: 1;

        YesWithPadding :: 2;

        kUnknown        :: Unknown;

        kYes            :: Yes;

        kYesWithPadding :: YesWithPadding;
    }

    /**
    * Filters the contents of 'src' and draws the result into 'dst'. The filter is evaluated
    * relative to the current canvas matrix, and src is drawn to dst using their relative transform
    * 'paint' is applied after the filter and must not have a mask or image filter of its own.
    * A null 'filter' behaves as if the identity filter were used.
    *
    * 'scaleFactor' is an extra uniform scale transform applied to downscale the 'src' image
    * before any filtering, or as part of the copy, and is then drawn with 1/scaleFactor to 'dst'.
    * Must be 1.0 if 'compat' is kYes (i.e. any scale factor has already been baked into the
    * relative transforms between the devices).
    *
    * 'srcTileMode' is the tile mode to apply to the boundary of the 'src' image when insufficient
    * content is available. It defaults to kDecal for the regular saveLayer() case.
    */
    internalDrawDeviceWithFilter :: (this: *SkCanvas, src: *SkDevice, dst: *SkDevice, filters: SkCanvas.FilterSpan, paint: *SkPaint, compat: SkCanvas.DeviceCompatibleWithFilter, filterColorInfo: *SkColorInfo, scaleFactor: SkScalar = 1.0, srcTileMode: SkTileMode = .Decal, srcIsCoverageLayer := false) -> void #cpp_method #foreign libskia "?internalDrawDeviceWithFilter@SkCanvas@@AEAAXPEAVSkDevice@@0V?$SkSpan@V?$sk_sp@VSkImageFilter@@@@@@AEBVSkPaint@@W4DeviceCompatibleWithFilter@1@AEBVSkColorInfo@@MW4SkTileMode@@_N@Z";
    internalDrawDeviceWithFilter :: (this: *SkCanvas, src: *SkDevice, dst: *SkDevice, filters: SkCanvas.FilterSpan, paint: SkPaint, compat: SkCanvas.DeviceCompatibleWithFilter, filterColorInfo: SkColorInfo, scaleFactor: SkScalar = 1.0, srcTileMode: SkTileMode = .Decal, srcIsCoverageLayer := false) #no_context {
        internalDrawDeviceWithFilter(this, src, dst, filters, *paint, compat, *filterColorInfo, scaleFactor, srcTileMode, srcIsCoverageLayer);
    }

    /*
    *  Returns true if drawing the specified rect (or all if it is null) with the specified
    *  paint (or default if null) would overwrite the entire root device of the canvas
    *  (i.e. the canvas' surface if it had one).
    */
    wouldOverwriteEntireSurface :: (this: *SkCanvas, unknown0: *SkRect, unknown1: *SkPaint, unknown2: SkEnumBitMask(SkCanvas.PredrawFlags)) -> bool #cpp_method #foreign libskia "?wouldOverwriteEntireSurface@SkCanvas@@AEBA_NPEBUSkRect@@PEBVSkPaint@@V?$SkEnumBitMask@W4PredrawFlags@SkCanvas@@@@@Z";

    /**
    *  Returns true if the clip (for any active layer) contains antialiasing.
    *  If the clip is empty, this will return false.
    */
    androidFramework_isClipAA :: (this: *SkCanvas) -> bool #cpp_method #foreign libskia "?androidFramework_isClipAA@SkCanvas@@AEBA_NXZ";

    /**
    * Reset the clip to be wide-open (modulo any separately specified device clip restriction).
    * This operate within the save/restore clip stack so it can be undone by restoring to an
    * earlier save point.
    */
    internal_private_resetClip :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?internal_private_resetClip@SkCanvas@@AEAAXXZ";

    // Keep track of the device clip bounds in the canvas' global space to reject draws before
    // invoking the top-level device.
    fQuickRejectBounds:        SkRect;

    // Compute the clip's bounds based on all clipped SkDevice's reported device bounds transformed
    // into the canvas' global space.
    computeDeviceClipBounds :: (this: *SkCanvas, outsetForAA := true) -> SkRect #cpp_method #foreign libskia "?computeDeviceClipBounds@SkCanvas@@AEBA?AUSkRect@@_N@Z";

    // Returns the paint's mask filter if it can be used to draw an rrect with an analytic blur, and
    // returns null otherwise.
    canAttemptBlurredRRectDraw :: (this: *SkCanvas, unknown0: *SkPaint) -> *SkBlurMaskFilterImpl #cpp_method #foreign libskia "?canAttemptBlurredRRectDraw@SkCanvas@@AEBAPEBVSkBlurMaskFilterImpl@@AEBVSkPaint@@@Z";
    canAttemptBlurredRRectDraw :: (this: *SkCanvas, unknown0: SkPaint) -> *SkBlurMaskFilterImpl #no_context {
        return canAttemptBlurredRRectDraw(this, *unknown0);
    }

    // Attempt to draw a rrect with an analytic blur. If the draw succeeds or predrawNotify fails,
    // nullopt is returned indicating that nothing further should be drawn.
    attemptBlurredRRectDraw :: (this: *SkCanvas, unknown0: *SkRRect, unknown1: *SkBlurMaskFilterImpl, unknown2: *SkPaint, unknown3: SkEnumBitMask(SkCanvas.PredrawFlags)) -> std.optional(AutoLayerForImageFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?attemptBlurredRRectDraw@SkCanvas@@AEAA?AV?$optional@VAutoLayerForImageFilter@@@std@@AEBVSkRRect@@PEBVSkBlurMaskFilterImpl@@AEBVSkPaint@@V?$SkEnumBitMask@W4PredrawFlags@SkCanvas@@@@@Z";
    attemptBlurredRRectDraw :: (this: *SkCanvas, unknown0: SkRRect, unknown1: *SkBlurMaskFilterImpl, unknown2: SkPaint, unknown3: SkEnumBitMask(SkCanvas.PredrawFlags)) -> std.optional(AutoLayerForImageFilter) #no_context {
        return attemptBlurredRRectDraw(this, *unknown0, unknown1, *unknown2, unknown3);
    }

    AutoUpdateQRBounds :: struct {}
    validateClip :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?validateClip@SkCanvas@@AEBAXXZ";

    fScratchGlyphRunBuilder:   std.unique_ptr(sktext.GlyphRunBuilder);

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Draws saved layers, if any.
    Frees up resources used by SkCanvas.
    
    example: https://fiddle.skia.org/c/@Canvas_destructor
    */
    virtual_Destructor :: (this: *SkCanvas, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkCanvas@@UEAA@XZ";

    /** Gets the size of the base or root layer in global canvas coordinates. The
    origin of the base layer is always (0,0). The area available for drawing may be
    smaller (due to clipping or saveLayer).
    
    @return  integral width and height of base layer
    
    example: https://fiddle.skia.org/c/@Canvas_getBaseLayerSize
    */
    virtual_getBaseLayerSize :: (this: *SkCanvas) -> SkISize #cpp_method #foreign libskia "?getBaseLayerSize@SkCanvas@@UEBA?AUSkISize@@XZ";

    /** Returns Ganesh context of the GPU surface associated with SkCanvas.
    
    @return  GPU context, if available; nullptr otherwise
    
    example: https://fiddle.skia.org/c/@Canvas_recordingContext
    */
    virtual_recordingContext :: (this: *SkCanvas) -> *GrRecordingContext #cpp_method #foreign libskia "?recordingContext@SkCanvas@@UEBAPEAVGrRecordingContext@@XZ";

    /** Returns Recorder for the GPU surface associated with SkCanvas.
    
    @return  Recorder, if available; nullptr otherwise
    */
    virtual_recorder :: (this: *SkCanvas) -> *skgpu.graphite.Recorder #cpp_method #foreign libskia "?recorder@SkCanvas@@UEBAPEAVRecorder@graphite@skgpu@@XZ";

    /** Returns Recorder for the surface associated with SkCanvas.
    
    @return  Recorder, should be non-null
    */
    virtual_baseRecorder :: (this: *SkCanvas) -> *SkRecorder #cpp_method #foreign libskia "?baseRecorder@SkCanvas@@UEBAPEAVSkRecorder@@XZ";

    /** Returns true if clip is empty; that is, nothing will draw.
    
    May do work when called; it should not be called
    more often than needed. However, once called, subsequent calls perform no
    work until clip changes.
    
    @return  true if clip is empty
    
    example: https://fiddle.skia.org/c/@Canvas_isClipEmpty
    */
    virtual_isClipEmpty :: (this: *SkCanvas) -> bool #cpp_method #foreign libskia "?isClipEmpty@SkCanvas@@UEBA_NXZ";

    /** Returns true if clip is SkRect and not empty.
    Returns false if the clip is empty, or if it is not SkRect.
    
    @return  true if clip is SkRect and not empty
    
    example: https://fiddle.skia.org/c/@Canvas_isClipRect
    */
    virtual_isClipRect :: (this: *SkCanvas) -> bool #cpp_method #foreign libskia "?isClipRect@SkCanvas@@UEBA_NXZ";

    // default impl defers to getDevice()->newSurface(info)
    virtual_onNewSurface :: (this: *SkCanvas, info: *SkImageInfo, props: *SkSurfaceProps) -> sk_sp(SkSurface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onNewSurface@SkCanvas@@MEAA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@AEBVSkSurfaceProps@@@Z";

    // default impl defers to its device
    virtual_onPeekPixels :: (this: *SkCanvas, pixmap: *SkPixmap) -> bool #cpp_method #foreign libskia "?onPeekPixels@SkCanvas@@MEAA_NPEAVSkPixmap@@@Z";
    virtual_onAccessTopLayerPixels :: (this: *SkCanvas, pixmap: *SkPixmap) -> bool #cpp_method #foreign libskia "?onAccessTopLayerPixels@SkCanvas@@MEAA_NPEAVSkPixmap@@@Z";
    virtual_onImageInfo :: (this: *SkCanvas) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onImageInfo@SkCanvas@@MEBA?AUSkImageInfo@@XZ";
    virtual_onGetProps :: (this: *SkCanvas, props: *SkSurfaceProps, top: bool) -> bool #cpp_method #foreign libskia "?onGetProps@SkCanvas@@MEBA_NPEAVSkSurfaceProps@@_N@Z";

    virtual_willSave :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?willSave@SkCanvas@@MEAAXXZ";

    // Overriders should call the corresponding INHERITED method up the inheritance chain.
    virtual_getSaveLayerStrategy :: (this: *SkCanvas, unknown0: *SkCanvas.SaveLayerRec) -> SkCanvas.SaveLayerStrategy #cpp_method #foreign libskia "?getSaveLayerStrategy@SkCanvas@@MEAA?AW4SaveLayerStrategy@1@AEBUSaveLayerRec@1@@Z";

    // returns true if we should actually perform the saveBehind, or false if we should just save.
    virtual_onDoSaveBehind :: (this: *SkCanvas, unknown0: *SkRect) -> bool #cpp_method #foreign libskia "?onDoSaveBehind@SkCanvas@@MEAA_NPEBUSkRect@@@Z";
    virtual_willRestore :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?willRestore@SkCanvas@@MEAAXXZ";
    virtual_didRestore :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?didRestore@SkCanvas@@MEAAXXZ";

    virtual_didConcat44 :: (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method #foreign libskia "?didConcat44@SkCanvas@@MEAAXAEBVSkM44@@@Z";
    virtual_didSetM44 :: (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method #foreign libskia "?didSetM44@SkCanvas@@MEAAXAEBVSkM44@@@Z";
    virtual_didTranslate :: (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) -> void #cpp_method #foreign libskia "?didTranslate@SkCanvas@@MEAAXMM@Z";
    virtual_didScale :: (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) -> void #cpp_method #foreign libskia "?didScale@SkCanvas@@MEAAXMM@Z";

    // NOTE: If you are adding a new onDraw virtual to SkCanvas, PLEASE add an override to
    // SkCanvasVirtualEnforcer (in SkCanvasVirtualEnforcer.h). This ensures that subclasses using
    // that mechanism  will be required to implement the new function.
    virtual_onDrawPaint :: (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawPaint@SkCanvas@@MEAAXAEBVSkPaint@@@Z";
    virtual_onDrawBehind :: (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawBehind@SkCanvas@@MEAAXAEBVSkPaint@@@Z";
    virtual_onDrawRect :: (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawRect@SkCanvas@@MEAAXAEBUSkRect@@AEBVSkPaint@@@Z";
    virtual_onDrawRRect :: (this: *SkCanvas, rrect: *SkRRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawRRect@SkCanvas@@MEAAXAEBVSkRRect@@AEBVSkPaint@@@Z";
    virtual_onDrawDRRect :: (this: *SkCanvas, outer: *SkRRect, inner: *SkRRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawDRRect@SkCanvas@@MEAAXAEBVSkRRect@@0AEBVSkPaint@@@Z";
    virtual_onDrawOval :: (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawOval@SkCanvas@@MEAAXAEBUSkRect@@AEBVSkPaint@@@Z";
    virtual_onDrawArc :: (this: *SkCanvas, rect: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, useCenter: bool, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawArc@SkCanvas@@MEAAXAEBUSkRect@@MM_NAEBVSkPaint@@@Z";

    virtual_onDrawPath :: (this: *SkCanvas, path: *SkPath, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawPath@SkCanvas@@MEAAXAEBVSkPath@@AEBVSkPaint@@@Z";
    virtual_onDrawRegion :: (this: *SkCanvas, region: *SkRegion, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawRegion@SkCanvas@@MEAAXAEBVSkRegion@@AEBVSkPaint@@@Z";

    virtual_onDrawTextBlob :: (this: *SkCanvas, blob: *SkTextBlob, x: SkScalar, y: SkScalar, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawTextBlob@SkCanvas@@MEAAXPEBVSkTextBlob@@MMAEBVSkPaint@@@Z";

    virtual_onDrawGlyphRunList :: (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawGlyphRunList@SkCanvas@@MEAAXAEBVGlyphRunList@sktext@@AEBVSkPaint@@@Z";

    virtual_onDrawPatch :: (this: *SkCanvas, cubics: *[12] SkPoint, colors: *[4] SkColor, texCoords: *[4] SkPoint, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawPatch@SkCanvas@@MEAAXQEBUSkPoint@@QEBI0W4SkBlendMode@@AEBVSkPaint@@@Z";

    virtual_onDrawPoints :: (this: *SkCanvas, mode: SkCanvas.PointMode, count: u64, pts: *SkPoint, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawPoints@SkCanvas@@MEAAXW4PointMode@1@_KQEBUSkPoint@@AEBVSkPaint@@@Z";

    virtual_onDrawImage2 :: (this: *SkCanvas, unknown0: *SkImage, dx: SkScalar, dy: SkScalar, unknown1: *SkSamplingOptions, unknown2: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawImage2@SkCanvas@@MEAAXPEBVSkImage@@MMAEBUSkSamplingOptions@@PEBVSkPaint@@@Z";

    virtual_onDrawImageRect2 :: (this: *SkCanvas, unknown0: *SkImage, src: *SkRect, dst: *SkRect, unknown1: *SkSamplingOptions, unknown2: *SkPaint, unknown3: SkCanvas.SrcRectConstraint) -> void #cpp_method #foreign libskia "?onDrawImageRect2@SkCanvas@@MEAAXPEBVSkImage@@AEBUSkRect@@1AEBUSkSamplingOptions@@PEBVSkPaint@@W4SrcRectConstraint@1@@Z";

    virtual_onDrawImageLattice2 :: (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkCanvas.Lattice, dst: *SkRect, unknown2: SkFilterMode, unknown3: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawImageLattice2@SkCanvas@@MEAAXPEBVSkImage@@AEBULattice@1@AEBUSkRect@@W4SkFilterMode@@PEBVSkPaint@@@Z";

    virtual_onDrawAtlas2 :: (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkRSXform, src: *SkRect, unknown2: *SkColor, count: s32, unknown3: SkBlendMode, unknown4: *SkSamplingOptions, cull: *SkRect, unknown5: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawAtlas2@SkCanvas@@MEAAXPEBVSkImage@@QEBUSkRSXform@@QEBUSkRect@@QEBIHW4SkBlendMode@@AEBUSkSamplingOptions@@PEBU4@PEBVSkPaint@@@Z";

    virtual_onDrawEdgeAAImageSet2 :: (this: *SkCanvas, imageSet: *SkCanvas.ImageSetEntry, count: s32, dstClips: *SkPoint, preViewMatrices: *SkMatrix, unknown0: *SkSamplingOptions, unknown1: *SkPaint, unknown2: SkCanvas.SrcRectConstraint) -> void #cpp_method #foreign libskia "?onDrawEdgeAAImageSet2@SkCanvas@@MEAAXQEBUImageSetEntry@1@HQEBUSkPoint@@QEBVSkMatrix@@AEBUSkSamplingOptions@@PEBVSkPaint@@W4SrcRectConstraint@1@@Z";

    virtual_onDrawVerticesObject :: (this: *SkCanvas, vertices: *SkVertices, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawVerticesObject@SkCanvas@@MEAAXPEBVSkVertices@@W4SkBlendMode@@AEBVSkPaint@@@Z";

    virtual_onDrawMesh :: (this: *SkCanvas, unknown0: *SkMesh, unknown1: sk_sp(SkBlender), unknown2: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawMesh@SkCanvas@@MEAAXAEBVSkMesh@@V?$sk_sp@VSkBlender@@@@AEBVSkPaint@@@Z";
    virtual_onDrawAnnotation :: (this: *SkCanvas, rect: *SkRect, key: *u8, value: *SkData) -> void #cpp_method #foreign libskia "?onDrawAnnotation@SkCanvas@@MEAAXAEBUSkRect@@QEBDPEAVSkData@@@Z";
    virtual_onDrawShadowRec :: (this: *SkCanvas, unknown0: *SkPath, unknown1: *SkDrawShadowRec) -> void #cpp_method #foreign libskia "?onDrawShadowRec@SkCanvas@@MEAAXAEBVSkPath@@AEBUSkDrawShadowRec@@@Z";

    virtual_onDrawDrawable :: (this: *SkCanvas, drawable: *SkDrawable, matrix: *SkMatrix) -> void #cpp_method #foreign libskia "?onDrawDrawable@SkCanvas@@MEAAXPEAVSkDrawable@@PEBVSkMatrix@@@Z";
    virtual_onDrawPicture :: (this: *SkCanvas, picture: *SkPicture, matrix: *SkMatrix, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawPicture@SkCanvas@@MEAAXPEBVSkPicture@@PEBVSkMatrix@@PEBVSkPaint@@@Z";

    virtual_onDrawEdgeAAQuad :: (this: *SkCanvas, rect: *SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: *SkColor4f, mode: SkBlendMode) -> void #cpp_method #foreign libskia "?onDrawEdgeAAQuad@SkCanvas@@MEAAXAEBUSkRect@@QEBUSkPoint@@W4QuadAAFlags@1@AEBU?$SkRGBA4f@$02@@W4SkBlendMode@@@Z";

    virtual_onClipRect :: (this: *SkCanvas, rect: *SkRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method #foreign libskia "?onClipRect@SkCanvas@@MEAAXAEBUSkRect@@W4SkClipOp@@W4ClipEdgeStyle@1@@Z";
    virtual_onClipRRect :: (this: *SkCanvas, rrect: *SkRRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method #foreign libskia "?onClipRRect@SkCanvas@@MEAAXAEBVSkRRect@@W4SkClipOp@@W4ClipEdgeStyle@1@@Z";
    virtual_onClipPath :: (this: *SkCanvas, path: *SkPath, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method #foreign libskia "?onClipPath@SkCanvas@@MEAAXAEBVSkPath@@W4SkClipOp@@W4ClipEdgeStyle@1@@Z";
    virtual_onClipShader :: (this: *SkCanvas, unknown0: sk_sp(SkShader), unknown1: SkClipOp) -> void #cpp_method #foreign libskia "?onClipShader@SkCanvas@@MEAAXV?$sk_sp@VSkShader@@@@W4SkClipOp@@@Z";
    virtual_onClipRegion :: (this: *SkCanvas, deviceRgn: *SkRegion, op: SkClipOp) -> void #cpp_method #foreign libskia "?onClipRegion@SkCanvas@@MEAAXAEBVSkRegion@@W4SkClipOp@@@Z";
    virtual_onResetClip :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?onResetClip@SkCanvas@@MEAAXXZ";

    virtual_onDiscard :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?onDiscard@SkCanvas@@MEAAXXZ";

    /**
    */
    virtual_onConvertGlyphRunListToSlug :: (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) -> sk_sp(sktext.gpu.Slug) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onConvertGlyphRunListToSlug@SkCanvas@@MEAA?AV?$sk_sp@VSlug@gpu@sktext@@@@AEBVGlyphRunList@sktext@@AEBVSkPaint@@@Z";

    /**
    */
    virtual_onDrawSlug :: (this: *SkCanvas, slug: *sktext.gpu.Slug, paint: *SkPaint) -> void #cpp_method #foreign libskia "?onDrawSlug@SkCanvas@@MEAAXPEBVSlug@gpu@sktext@@AEBVSkPaint@@@Z";

    virtual_onSurfaceDelete :: (this: *SkCanvas) -> void #cpp_method #foreign libskia "?onSurfaceDelete@SkCanvas@@EEAAXXZ";

    virtual_internal_private_asPaintFilterCanvas :: (this: *SkCanvas) -> *SkPaintFilterCanvas #cpp_method #foreign libskia "?internal_private_asPaintFilterCanvas@SkCanvas@@EEBAPEAVSkPaintFilterCanvas@@XZ";
}

// operator_assign :: (this: *SkCanvas, unknown0: *SkCanvas) -> *SkCanvas #cpp_method #foreign libskia "??4SkCanvas@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkCanvas, unknown0: SkCanvas) -> *SkCanvas #no_context {
    return operator_assign(this, *unknown0);
}
SkCanvas_VTable :: struct #type_info_none {
    Destructor:                           #type (this: *SkCanvas, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    getBaseLayerSize:                     #type (this: *SkCanvas) -> SkISize #cpp_method;

    recordingContext:                     #type (this: *SkCanvas) -> *GrRecordingContext #cpp_method;

    recorder:                             #type (this: *SkCanvas) -> *skgpu.graphite.Recorder #cpp_method;

    baseRecorder:                         #type (this: *SkCanvas) -> *SkRecorder #cpp_method;

    isClipEmpty:                          #type (this: *SkCanvas) -> bool #cpp_method;

    isClipRect:                           #type (this: *SkCanvas) -> bool #cpp_method;

    onNewSurface:                         #type (this: *SkCanvas, info: *SkImageInfo, props: *SkSurfaceProps) -> sk_sp(SkSurface) #cpp_method #cpp_return_type_is_non_pod;

    onPeekPixels:                         #type (this: *SkCanvas, pixmap: *SkPixmap) -> bool #cpp_method;
    onAccessTopLayerPixels:               #type (this: *SkCanvas, pixmap: *SkPixmap) -> bool #cpp_method;
    onImageInfo:                          #type (this: *SkCanvas) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod;
    onGetProps:                           #type (this: *SkCanvas, props: *SkSurfaceProps, top: bool) -> bool #cpp_method;

    willSave:                             #type (this: *SkCanvas) -> void #cpp_method;

    getSaveLayerStrategy:                 #type (this: *SkCanvas, unknown0: *SkCanvas.SaveLayerRec) -> SkCanvas.SaveLayerStrategy #cpp_method;

    onDoSaveBehind:                       #type (this: *SkCanvas, unknown0: *SkRect) -> bool #cpp_method;
    willRestore:                          #type (this: *SkCanvas) -> void #cpp_method;
    didRestore:                           #type (this: *SkCanvas) -> void #cpp_method;

    didConcat44:                          #type (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method;
    didSetM44:                            #type (this: *SkCanvas, unknown0: *SkM44) -> void #cpp_method;
    didTranslate:                         #type (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) -> void #cpp_method;
    didScale:                             #type (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) -> void #cpp_method;

    onDrawPaint:                          #type (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method;
    onDrawBehind:                         #type (this: *SkCanvas, paint: *SkPaint) -> void #cpp_method;
    onDrawRect:                           #type (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) -> void #cpp_method;
    onDrawRRect:                          #type (this: *SkCanvas, rrect: *SkRRect, paint: *SkPaint) -> void #cpp_method;
    onDrawDRRect:                         #type (this: *SkCanvas, outer: *SkRRect, inner: *SkRRect, paint: *SkPaint) -> void #cpp_method;
    onDrawOval:                           #type (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) -> void #cpp_method;
    onDrawArc:                            #type (this: *SkCanvas, rect: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, useCenter: bool, paint: *SkPaint) -> void #cpp_method;

    onDrawPath:                           #type (this: *SkCanvas, path: *SkPath, paint: *SkPaint) -> void #cpp_method;
    onDrawRegion:                         #type (this: *SkCanvas, region: *SkRegion, paint: *SkPaint) -> void #cpp_method;

    onDrawTextBlob:                       #type (this: *SkCanvas, blob: *SkTextBlob, x: SkScalar, y: SkScalar, paint: *SkPaint) -> void #cpp_method;

    onDrawGlyphRunList:                   #type (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) -> void #cpp_method;

    onDrawPatch:                          #type (this: *SkCanvas, cubics: *[12] SkPoint, colors: *[4] SkColor, texCoords: *[4] SkPoint, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method;

    onDrawPoints:                         #type (this: *SkCanvas, mode: SkCanvas.PointMode, count: u64, pts: *SkPoint, paint: *SkPaint) -> void #cpp_method;

    onDrawImage2:                         #type (this: *SkCanvas, unknown0: *SkImage, dx: SkScalar, dy: SkScalar, unknown1: *SkSamplingOptions, unknown2: *SkPaint) -> void #cpp_method;

    onDrawImageRect2:                     #type (this: *SkCanvas, unknown0: *SkImage, src: *SkRect, dst: *SkRect, unknown1: *SkSamplingOptions, unknown2: *SkPaint, unknown3: SkCanvas.SrcRectConstraint) -> void #cpp_method;

    onDrawImageLattice2:                  #type (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkCanvas.Lattice, dst: *SkRect, unknown2: SkFilterMode, unknown3: *SkPaint) -> void #cpp_method;

    onDrawAtlas2:                         #type (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkRSXform, src: *SkRect, unknown2: *SkColor, count: s32, unknown3: SkBlendMode, unknown4: *SkSamplingOptions, cull: *SkRect, unknown5: *SkPaint) -> void #cpp_method;

    onDrawEdgeAAImageSet2:                #type (this: *SkCanvas, imageSet: *SkCanvas.ImageSetEntry, count: s32, dstClips: *SkPoint, preViewMatrices: *SkMatrix, unknown0: *SkSamplingOptions, unknown1: *SkPaint, unknown2: SkCanvas.SrcRectConstraint) -> void #cpp_method;

    onDrawVerticesObject:                 #type (this: *SkCanvas, vertices: *SkVertices, mode: SkBlendMode, paint: *SkPaint) -> void #cpp_method;

    onDrawMesh:                           #type (this: *SkCanvas, unknown0: *SkMesh, unknown1: sk_sp(SkBlender), unknown2: *SkPaint) -> void #cpp_method;
    onDrawAnnotation:                     #type (this: *SkCanvas, rect: *SkRect, key: *u8, value: *SkData) -> void #cpp_method;
    onDrawShadowRec:                      #type (this: *SkCanvas, unknown0: *SkPath, unknown1: *SkDrawShadowRec) -> void #cpp_method;

    onDrawDrawable:                       #type (this: *SkCanvas, drawable: *SkDrawable, matrix: *SkMatrix) -> void #cpp_method;
    onDrawPicture:                        #type (this: *SkCanvas, picture: *SkPicture, matrix: *SkMatrix, paint: *SkPaint) -> void #cpp_method;

    onDrawEdgeAAQuad:                     #type (this: *SkCanvas, rect: *SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: *SkColor4f, mode: SkBlendMode) -> void #cpp_method;

    onClipRect:                           #type (this: *SkCanvas, rect: *SkRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method;
    onClipRRect:                          #type (this: *SkCanvas, rrect: *SkRRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method;
    onClipPath:                           #type (this: *SkCanvas, path: *SkPath, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) -> void #cpp_method;
    onClipShader:                         #type (this: *SkCanvas, unknown0: sk_sp(SkShader), unknown1: SkClipOp) -> void #cpp_method;
    onClipRegion:                         #type (this: *SkCanvas, deviceRgn: *SkRegion, op: SkClipOp) -> void #cpp_method;
    onResetClip:                          #type (this: *SkCanvas) -> void #cpp_method;

    onDiscard:                            #type (this: *SkCanvas) -> void #cpp_method;

    onConvertGlyphRunListToSlug:          #type (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) -> sk_sp(sktext.gpu.Slug) #cpp_method #cpp_return_type_is_non_pod;

    onDrawSlug:                           #type (this: *SkCanvas, slug: *sktext.gpu.Slug, paint: *SkPaint) -> void #cpp_method;

    onSurfaceDelete:                      #type (this: *SkCanvas) -> void #cpp_method;

    internal_private_asPaintFilterCanvas: #type (this: *SkCanvas) -> *SkPaintFilterCanvas #cpp_method;
}
SkCanvas_Destructor :: inline (this: *SkCanvas, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkCanvas_getBaseLayerSize :: inline (this: *SkCanvas) -> SkISize { return this.vtable.getBaseLayerSize(this); }

SkCanvas_recordingContext :: inline (this: *SkCanvas) -> *GrRecordingContext { return this.vtable.recordingContext(this); }

SkCanvas_recorder :: inline (this: *SkCanvas) -> *skgpu.graphite.Recorder { return this.vtable.recorder(this); }

SkCanvas_baseRecorder :: inline (this: *SkCanvas) -> *SkRecorder { return this.vtable.baseRecorder(this); }

SkCanvas_isClipEmpty :: inline (this: *SkCanvas) -> bool { return this.vtable.isClipEmpty(this); }

SkCanvas_isClipRect :: inline (this: *SkCanvas) -> bool { return this.vtable.isClipRect(this); }

SkCanvas_onNewSurface :: inline (this: *SkCanvas, info: *SkImageInfo, props: *SkSurfaceProps) -> sk_sp(SkSurface) { return this.vtable.onNewSurface(this, info, props); }

SkCanvas_onPeekPixels :: inline (this: *SkCanvas, pixmap: *SkPixmap) -> bool { return this.vtable.onPeekPixels(this, pixmap); }
SkCanvas_onAccessTopLayerPixels :: inline (this: *SkCanvas, pixmap: *SkPixmap) -> bool { return this.vtable.onAccessTopLayerPixels(this, pixmap); }
SkCanvas_onImageInfo :: inline (this: *SkCanvas) -> SkImageInfo { return this.vtable.onImageInfo(this); }
SkCanvas_onGetProps :: inline (this: *SkCanvas, props: *SkSurfaceProps, top: bool) -> bool { return this.vtable.onGetProps(this, props, top); }

SkCanvas_willSave :: inline (this: *SkCanvas) { this.vtable.willSave(this); }

SkCanvas_getSaveLayerStrategy :: inline (this: *SkCanvas, unknown0: *SkCanvas.SaveLayerRec) -> SkCanvas.SaveLayerStrategy { return this.vtable.getSaveLayerStrategy(this, unknown0); }

SkCanvas_onDoSaveBehind :: inline (this: *SkCanvas, unknown0: *SkRect) -> bool { return this.vtable.onDoSaveBehind(this, unknown0); }
SkCanvas_willRestore :: inline (this: *SkCanvas) { this.vtable.willRestore(this); }
SkCanvas_didRestore :: inline (this: *SkCanvas) { this.vtable.didRestore(this); }

SkCanvas_didConcat44 :: inline (this: *SkCanvas, unknown0: *SkM44) { this.vtable.didConcat44(this, unknown0); }
SkCanvas_didSetM44 :: inline (this: *SkCanvas, unknown0: *SkM44) { this.vtable.didSetM44(this, unknown0); }
SkCanvas_didTranslate :: inline (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) { this.vtable.didTranslate(this, unknown0, unknown1); }
SkCanvas_didScale :: inline (this: *SkCanvas, unknown0: SkScalar, unknown1: SkScalar) { this.vtable.didScale(this, unknown0, unknown1); }

SkCanvas_onDrawPaint :: inline (this: *SkCanvas, paint: *SkPaint) { this.vtable.onDrawPaint(this, paint); }
SkCanvas_onDrawBehind :: inline (this: *SkCanvas, paint: *SkPaint) { this.vtable.onDrawBehind(this, paint); }
SkCanvas_onDrawRect :: inline (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) { this.vtable.onDrawRect(this, rect, paint); }
SkCanvas_onDrawRRect :: inline (this: *SkCanvas, rrect: *SkRRect, paint: *SkPaint) { this.vtable.onDrawRRect(this, rrect, paint); }
SkCanvas_onDrawDRRect :: inline (this: *SkCanvas, outer: *SkRRect, inner: *SkRRect, paint: *SkPaint) { this.vtable.onDrawDRRect(this, outer, inner, paint); }
SkCanvas_onDrawOval :: inline (this: *SkCanvas, rect: *SkRect, paint: *SkPaint) { this.vtable.onDrawOval(this, rect, paint); }
SkCanvas_onDrawArc :: inline (this: *SkCanvas, rect: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, useCenter: bool, paint: *SkPaint) { this.vtable.onDrawArc(this, rect, startAngle, sweepAngle, useCenter, paint); }

SkCanvas_onDrawPath :: inline (this: *SkCanvas, path: *SkPath, paint: *SkPaint) { this.vtable.onDrawPath(this, path, paint); }
SkCanvas_onDrawRegion :: inline (this: *SkCanvas, region: *SkRegion, paint: *SkPaint) { this.vtable.onDrawRegion(this, region, paint); }

SkCanvas_onDrawTextBlob :: inline (this: *SkCanvas, blob: *SkTextBlob, x: SkScalar, y: SkScalar, paint: *SkPaint) { this.vtable.onDrawTextBlob(this, blob, x, y, paint); }

SkCanvas_onDrawGlyphRunList :: inline (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) { this.vtable.onDrawGlyphRunList(this, glyphRunList, paint); }

SkCanvas_onDrawPatch :: inline (this: *SkCanvas, cubics: *[12] SkPoint, colors: *[4] SkColor, texCoords: *[4] SkPoint, mode: SkBlendMode, paint: *SkPaint) { this.vtable.onDrawPatch(this, cubics, colors, texCoords, mode, paint); }

SkCanvas_onDrawPoints :: inline (this: *SkCanvas, mode: SkCanvas.PointMode, count: u64, pts: *SkPoint, paint: *SkPaint) { this.vtable.onDrawPoints(this, mode, count, pts, paint); }

SkCanvas_onDrawImage2 :: inline (this: *SkCanvas, unknown0: *SkImage, dx: SkScalar, dy: SkScalar, unknown1: *SkSamplingOptions, unknown2: *SkPaint) { this.vtable.onDrawImage2(this, unknown0, dx, dy, unknown1, unknown2); }

SkCanvas_onDrawImageRect2 :: inline (this: *SkCanvas, unknown0: *SkImage, src: *SkRect, dst: *SkRect, unknown1: *SkSamplingOptions, unknown2: *SkPaint, unknown3: SkCanvas.SrcRectConstraint) { this.vtable.onDrawImageRect2(this, unknown0, src, dst, unknown1, unknown2, unknown3); }

SkCanvas_onDrawImageLattice2 :: inline (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkCanvas.Lattice, dst: *SkRect, unknown2: SkFilterMode, unknown3: *SkPaint) { this.vtable.onDrawImageLattice2(this, unknown0, unknown1, dst, unknown2, unknown3); }

SkCanvas_onDrawAtlas2 :: inline (this: *SkCanvas, unknown0: *SkImage, unknown1: *SkRSXform, src: *SkRect, unknown2: *SkColor, count: s32, unknown3: SkBlendMode, unknown4: *SkSamplingOptions, cull: *SkRect, unknown5: *SkPaint) { this.vtable.onDrawAtlas2(this, unknown0, unknown1, src, unknown2, count, unknown3, unknown4, cull, unknown5); }

SkCanvas_onDrawEdgeAAImageSet2 :: inline (this: *SkCanvas, imageSet: *SkCanvas.ImageSetEntry, count: s32, dstClips: *SkPoint, preViewMatrices: *SkMatrix, unknown0: *SkSamplingOptions, unknown1: *SkPaint, unknown2: SkCanvas.SrcRectConstraint) { this.vtable.onDrawEdgeAAImageSet2(this, imageSet, count, dstClips, preViewMatrices, unknown0, unknown1, unknown2); }

SkCanvas_onDrawVerticesObject :: inline (this: *SkCanvas, vertices: *SkVertices, mode: SkBlendMode, paint: *SkPaint) { this.vtable.onDrawVerticesObject(this, vertices, mode, paint); }

SkCanvas_onDrawMesh :: inline (this: *SkCanvas, unknown0: *SkMesh, unknown1: sk_sp(SkBlender), unknown2: *SkPaint) { this.vtable.onDrawMesh(this, unknown0, unknown1, unknown2); }
SkCanvas_onDrawAnnotation :: inline (this: *SkCanvas, rect: *SkRect, key: *u8, value: *SkData) { this.vtable.onDrawAnnotation(this, rect, key, value); }
SkCanvas_onDrawShadowRec :: inline (this: *SkCanvas, unknown0: *SkPath, unknown1: *SkDrawShadowRec) { this.vtable.onDrawShadowRec(this, unknown0, unknown1); }

SkCanvas_onDrawDrawable :: inline (this: *SkCanvas, drawable: *SkDrawable, matrix: *SkMatrix) { this.vtable.onDrawDrawable(this, drawable, matrix); }
SkCanvas_onDrawPicture :: inline (this: *SkCanvas, picture: *SkPicture, matrix: *SkMatrix, paint: *SkPaint) { this.vtable.onDrawPicture(this, picture, matrix, paint); }

SkCanvas_onDrawEdgeAAQuad :: inline (this: *SkCanvas, rect: *SkRect, clip: *[4] SkPoint, aaFlags: SkCanvas.QuadAAFlags, color: *SkColor4f, mode: SkBlendMode) { this.vtable.onDrawEdgeAAQuad(this, rect, clip, aaFlags, color, mode); }

SkCanvas_onClipRect :: inline (this: *SkCanvas, rect: *SkRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) { this.vtable.onClipRect(this, rect, op, edgeStyle); }
SkCanvas_onClipRRect :: inline (this: *SkCanvas, rrect: *SkRRect, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) { this.vtable.onClipRRect(this, rrect, op, edgeStyle); }
SkCanvas_onClipPath :: inline (this: *SkCanvas, path: *SkPath, op: SkClipOp, edgeStyle: SkCanvas.ClipEdgeStyle) { this.vtable.onClipPath(this, path, op, edgeStyle); }
SkCanvas_onClipShader :: inline (this: *SkCanvas, unknown0: sk_sp(SkShader), unknown1: SkClipOp) { this.vtable.onClipShader(this, unknown0, unknown1); }
SkCanvas_onClipRegion :: inline (this: *SkCanvas, deviceRgn: *SkRegion, op: SkClipOp) { this.vtable.onClipRegion(this, deviceRgn, op); }
SkCanvas_onResetClip :: inline (this: *SkCanvas) { this.vtable.onResetClip(this); }

SkCanvas_onDiscard :: inline (this: *SkCanvas) { this.vtable.onDiscard(this); }

SkCanvas_onConvertGlyphRunListToSlug :: inline (this: *SkCanvas, glyphRunList: *sktext.GlyphRunList, paint: *SkPaint) -> sk_sp(sktext.gpu.Slug) { return this.vtable.onConvertGlyphRunListToSlug(this, glyphRunList, paint); }

SkCanvas_onDrawSlug :: inline (this: *SkCanvas, slug: *sktext.gpu.Slug, paint: *SkPaint) { this.vtable.onDrawSlug(this, slug, paint); }

SkCanvas_onSurfaceDelete :: inline (this: *SkCanvas) { this.vtable.onSurfaceDelete(this); }

SkCanvas_internal_private_asPaintFilterCanvas :: inline (this: *SkCanvas) -> *SkPaintFilterCanvas { return this.vtable.internal_private_asPaintFilterCanvas(this); }

get_vtable :: (obj: *SkCanvas) -> *SkCanvas_VTable { return obj.vtable; }


/** \class SkAutoCanvasRestore
Stack helper class calls SkCanvas::restoreToCount when SkAutoCanvasRestore
goes out of scope. Use this to guarantee that the canvas is restored to a known
state.
*/
SkAutoCanvasRestore :: struct {
    /** Preserves SkCanvas::save() count. Optionally saves SkCanvas clip and SkCanvas matrix.
    
    @param canvas  SkCanvas to guard
    @param doSave  call SkCanvas::save()
    @return        utility to restore SkCanvas state on destructor
    */
//     Constructor :: (this: *SkAutoCanvasRestore, canvas: *SkCanvas, doSave: bool) -> void #cpp_method #foreign libskia "??0SkAutoCanvasRestore@@QEAA@PEAVSkCanvas@@_N@Z";

    /** Restores SkCanvas to saved state. Destructor is called when container goes out of
    scope.
    */
//     Destructor :: (this: *SkAutoCanvasRestore) -> void #cpp_method #foreign libskia "??1SkAutoCanvasRestore@@QEAA@XZ";

    /** Restores SkCanvas to saved state immediately. Subsequent calls and
    ~SkAutoCanvasRestore() have no effect.
    */
//     restore :: (this: *SkAutoCanvasRestore) -> void #cpp_method #foreign libskia "?restore@SkAutoCanvasRestore@@QEAAXXZ";

    fCanvas:    *SkCanvas;
    fSaveCount: s32;

//     CopyConstructor :: (this: *SkAutoCanvasRestore, unknown0: *SkAutoCanvasRestore) -> void #cpp_method #foreign libskia "??0SkAutoCanvasRestore@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkAutoCanvasRestore, unknown0: SkAutoCanvasRestore) #no_context {
        CopyConstructor(this, *unknown0);
    }
}

// operator_assign :: (this: *SkAutoCanvasRestore, unknown0: *SkAutoCanvasRestore) -> *SkAutoCanvasRestore #cpp_method #foreign libskia "??4SkAutoCanvasRestore@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkAutoCanvasRestore, unknown0: SkAutoCanvasRestore) -> *SkAutoCanvasRestore #no_context {
    return operator_assign(this, *unknown0);
}

SkPathIter :: struct {
    Rec :: struct {
        fPoints:      SkSpan(SkPoint);
        fConicWeight: float;
        fVerb:        SkPathVerb;

//         conicWeight :: (this: *Rec) -> float #cpp_method #foreign libskia "?conicWeight@Rec@SkPathIter@@QEBAMXZ";
    }

    Constructor :: (this: *SkPathIter, pts: SkSpan(SkPoint), vbs: SkSpan(SkPathVerb), cns: SkSpan(float)) -> void #cpp_method #foreign libskia "??0SkPathIter@@QEAA@V?$SkSpan@$$CBUSkPoint@@@@V?$SkSpan@$$CBW4SkPathVerb@@@@V?$SkSpan@$$CBM@@@Z";

    /*  Holds the current verb, and its associated points
    *  move:  pts[0]
    *  line:  pts[0..1]
    *  quad:  pts[0..2]
    *  conic: pts[0..2] fConicWeight
    *  cubic: pts[0..3]
    *  close: pts[0..1] ... as if close were a line from pts[0] to pts[1]
    */
    next :: (this: *SkPathIter) -> std.optional(Rec) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?next@SkPathIter@@QEAA?AV?$optional@URec@SkPathIter@@@std@@XZ";

    peekNextVerb :: (this: *SkPathIter) -> std.optional(SkPathVerb) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?peekNextVerb@SkPathIter@@QEBA?AV?$optional@W4SkPathVerb@@@std@@XZ";

    pIndex:             u64;
    vIndex:             u64;
    cIndex:             u64;
    fPoints:            SkSpan(SkPoint);
    fVerbs:             SkSpan(SkPathVerb);
    fConics:            SkSpan(float);
    fClosePointStorage: std.array(SkPoint, 2);
}

SkPathContourIter :: struct {
    Rec :: struct {
        fPoints: SkSpan(SkPoint);
        fVerbs:  SkSpan(SkPathVerb);
        fConics: SkSpan(float);
    }

//     Constructor :: (this: *SkPathContourIter, pts: SkSpan(SkPoint), vbs: SkSpan(SkPathVerb), cns: SkSpan(float)) -> void #cpp_method #foreign libskia "??0SkPathContourIter@@QEAA@V?$SkSpan@$$CBUSkPoint@@@@V?$SkSpan@$$CBW4SkPathVerb@@@@V?$SkSpan@$$CBM@@@Z";

//     next :: (this: *SkPathContourIter) -> std.optional(Rec) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?next@SkPathContourIter@@QEAA?AV?$optional@URec@SkPathContourIter@@@std@@XZ";

    fPoints: SkSpan(SkPoint);
    fVerbs:  SkSpan(SkPathVerb);
    fConics: SkSpan(float);
}

SkPathConvexity :: enum s32 {
}
SkResolveConvexity :: enum s32 {
}
SkPathRaw :: struct {}
SkPathVerbAnalysis :: struct {}
SkPathOvalInfo :: struct {}
SkPathRRectInfo :: struct {}

SkPathRef :: struct {}

/** \class SkPath
SkPath contain geometry. SkPath may be empty, or contain one or more verbs that
outline a figure. SkPath always starts with a move verb to a Cartesian coordinate,
and may be followed by additional verbs that add lines or curves.
Adding a close verb makes the geometry into a continuous loop, a closed contour.
SkPath may contain any number of contours, each beginning with a move verb.

SkPath contours may contain only a move verb, or may also contain lines,
quadratic beziers, conics, and cubic beziers. SkPath contours may be open or
closed.

When used to draw a filled area, SkPath describes whether the fill is inside or
outside the geometry. SkPath also describes the winding rule used to fill
overlapping contours.

Internally, SkPath lazily computes metrics likes bounds and convexity. Call
SkPath::updateBoundsCache to make SkPath thread safe.
*/
SkPath :: struct {
    /**
    *  Create a new path with the specified spans.
    *
    *  The points and weights arrays are read in order, based on the sequence of verbs.
    *
    *  Move    1 point
    *  Line    1 point
    *  Quad    2 points
    *  Conic   2 points and 1 weight
    *  Cubic   3 points
    *  Close   0 points
    *
    *  If an illegal sequence of verbs is encountered, or the specified number of points
    *  or weights is not sufficient given the verbs, an empty Path is returned.
    *
    *  A legal sequence of verbs consists of any number of Contours. A contour always begins
    *  with a Move verb, followed by 0 or more segments: Line, Quad, Conic, Cubic, followed
    *  by an optional Close.
    */
    Raw :: (pts: SkSpan(SkPoint), verbs: SkSpan(SkPathVerb), conics: SkSpan(SkScalar), unknown0: SkPathFillType, isVolatile := false) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Raw@SkPath@@SA?AV1@V?$SkSpan@$$CBUSkPoint@@@@V?$SkSpan@$$CBW4SkPathVerb@@@@V?$SkSpan@$$CBM@@W4SkPathFillType@@_N@Z";

    Rect :: (unknown0: *SkRect, unknown1: SkPathFillType, unknown2: SkPathDirection = .Default, startIndex: u32 = 0) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Rect@SkPath@@SA?AV1@AEBUSkRect@@W4SkPathFillType@@W4SkPathDirection@@I@Z";
    Rect :: (unknown0: SkRect, unknown1: SkPathFillType, unknown2: SkPathDirection = .Default, startIndex: u32 = 0) -> SkPath #no_context {
        return Rect(*unknown0, unknown1, unknown2, startIndex);
    }

    Rect :: (r: *SkRect, direction: SkPathDirection = .Default, startIndex: u32 = 0) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Rect@SkPath@@SA?AV1@AEBUSkRect@@W4SkPathDirection@@I@Z";
    Rect :: (r: SkRect, direction: SkPathDirection = .Default, startIndex: u32 = 0) -> SkPath #no_context {
        return Rect(*r, direction, startIndex);
    }

    Oval :: (unknown0: *SkRect, unknown1: SkPathDirection = .Default) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Oval@SkPath@@SA?AV1@AEBUSkRect@@W4SkPathDirection@@@Z";
    Oval :: (unknown0: SkRect, unknown1: SkPathDirection = .Default) -> SkPath #no_context {
        return Oval(*unknown0, unknown1);
    }
    Oval :: (unknown0: *SkRect, unknown1: SkPathDirection, startIndex: u32) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Oval@SkPath@@SA?AV1@AEBUSkRect@@W4SkPathDirection@@I@Z";
    Oval :: (unknown0: SkRect, unknown1: SkPathDirection, startIndex: u32) -> SkPath #no_context {
        return Oval(*unknown0, unknown1, startIndex);
    }
    Circle :: (center_x: SkScalar, center_y: SkScalar, radius: SkScalar, dir: SkPathDirection = .CW) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Circle@SkPath@@SA?AV1@MMMW4SkPathDirection@@@Z";

    RRect :: (unknown0: *SkRRect, dir: SkPathDirection = .Default) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?RRect@SkPath@@SA?AV1@AEBVSkRRect@@W4SkPathDirection@@@Z";
    RRect :: (unknown0: SkRRect, dir: SkPathDirection = .Default) -> SkPath #no_context {
        return RRect(*unknown0, dir);
    }
    RRect :: (unknown0: *SkRRect, unknown1: SkPathDirection, startIndex: u32) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?RRect@SkPath@@SA?AV1@AEBVSkRRect@@W4SkPathDirection@@I@Z";
    RRect :: (unknown0: SkRRect, unknown1: SkPathDirection, startIndex: u32) -> SkPath #no_context {
        return RRect(*unknown0, unknown1, startIndex);
    }
    RRect :: (bounds: *SkRect, rx: SkScalar, ry: SkScalar, dir: SkPathDirection = .Default) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?RRect@SkPath@@SA?AV1@AEBUSkRect@@MMW4SkPathDirection@@@Z";
    RRect :: (bounds: SkRect, rx: SkScalar, ry: SkScalar, dir: SkPathDirection = .Default) -> SkPath #no_context {
        return RRect(*bounds, rx, ry, dir);
    }

    Polygon :: (pts: SkSpan(SkPoint), isClosed: bool, fillType: SkPathFillType = .Default, isVolatile := false) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Polygon@SkPath@@SA?AV1@V?$SkSpan@$$CBUSkPoint@@@@_NW4SkPathFillType@@1@Z";

    Line :: (a: SkPoint, b: SkPoint) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Line@SkPath@@SA?AV1@USkPoint@@0@Z";

    // Deprecated: use Raw()
    Make :: (pts: SkSpan(SkPoint), verbs: SkSpan(u8), conics: SkSpan(SkScalar), fillType: SkPathFillType, isVolatile := false) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?Make@SkPath@@SA?AV1@V?$SkSpan@$$CBUSkPoint@@@@V?$SkSpan@$$CBE@@V?$SkSpan@$$CBM@@W4SkPathFillType@@_N@Z";

    /** Constructs an empty SkPath: no verbs, no points, no conic weights.
    
    @return  empty SkPath
    
    example: https://fiddle.skia.org/c/@Path_empty_constructor
    */
    Constructor :: (this: *SkPath, unknown0: SkPathFillType) -> void #cpp_method #foreign libskia "??0SkPath@@QEAA@W4SkPathFillType@@@Z";

    Constructor :: (this: *SkPath) -> void #cpp_method #foreign libskia "??0SkPath@@QEAA@XZ";

    /** Constructs a copy of an existing path.
    Copy constructor makes two paths identical by value. Internally, path and
    the returned result share pointer values. The underlying verb array, SkPoint array
    and weights are copied when modified.
    
    Creating a SkPath copy is very efficient and never allocates memory.
    SkPath are always copied by value from the interface; the underlying shared
    pointers are not exposed.
    
    @param path  SkPath to copy by value
    @return      copy of SkPath
    
    example: https://fiddle.skia.org/c/@Path_copy_const_SkPath
    */
    CopyConstructor :: (this: *SkPath, path: *SkPath) -> void #cpp_method #foreign libskia "??0SkPath@@QEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkPath, path: SkPath) #no_context {
        CopyConstructor(this, *path);
    }

    /** Releases ownership of any shared data and deletes data if SkPath is sole owner.
    
    example: https://fiddle.skia.org/c/@Path_destructor
    */
    Destructor :: (this: *SkPath) -> void #cpp_method #foreign libskia "??1SkPath@@QEAA@XZ";

    /** Returns a copy of this path in the current state. */
    snapshot :: (this: *SkPath) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?snapshot@SkPath@@QEBA?AV1@XZ";

    /** Returns true if SkPath contain equal verbs and equal weights.
    If SkPath contain one or more conics, the weights must match.
    
    conicTo() may add different verbs depending on conic weight, so it is not
    trivial to interpolate a pair of SkPath containing conics with different
    conic weight values.
    
    @param compare  SkPath to compare
    @return         true if SkPath verb array and weights are equivalent
    
    example: https://fiddle.skia.org/c/@Path_isInterpolatable
    */
    isInterpolatable :: (this: *SkPath, compare: *SkPath) -> bool #cpp_method #foreign libskia "?isInterpolatable@SkPath@@QEBA_NAEBV1@@Z";
    isInterpolatable :: (this: *SkPath, compare: SkPath) -> bool #no_context {
        return isInterpolatable(this, *compare);
    }

    /** Interpolates between SkPath with SkPoint array of equal size.
    Copy verb array and weights to out, and set out SkPoint array to a weighted
    average of this SkPoint array and ending SkPoint array, using the formula:
    (Path Point * weight) + ending Point * (1 - weight).
    
    weight is most useful when between zero (ending SkPoint array) and
    one (this Point_Array); will work with values outside of this
    range.
    
    interpolate() returns an empty SkPath if SkPoint array is not the same size
    as ending SkPoint array. Call isInterpolatable() to check SkPath compatibility
    prior to calling makeInterpolate().
    
    @param ending  SkPoint array averaged with this SkPoint array
    @param weight  contribution of this SkPoint array, and
    one minus contribution of ending SkPoint array
    @return        SkPath replaced by interpolated averages
    
    example: https://fiddle.skia.org/c/@Path_interpolate
    */
    makeInterpolate :: (this: *SkPath, ending: *SkPath, weight: SkScalar) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeInterpolate@SkPath@@QEBA?AV1@AEBV1@M@Z";
    makeInterpolate :: (this: *SkPath, ending: SkPath, weight: SkScalar) -> SkPath #no_context {
        return makeInterpolate(this, *ending, weight);
    }

    /** Interpolates between SkPath with SkPoint array of equal size.
    Copy verb array and weights to out, and set out SkPoint array to a weighted
    average of this SkPoint array and ending SkPoint array, using the formula:
    (Path Point * weight) + ending Point * (1 - weight).
    
    weight is most useful when between zero (ending SkPoint array) and
    one (this Point_Array); will work with values outside of this
    range.
    
    interpolate() returns false and leaves out unchanged if SkPoint array is not
    the same size as ending SkPoint array. Call isInterpolatable() to check SkPath
    compatibility prior to calling interpolate().
    
    @param ending  SkPoint array averaged with this SkPoint array
    @param weight  contribution of this SkPoint array, and
    one minus contribution of ending SkPoint array
    @param out     SkPath replaced by interpolated averages
    @return        true if SkPath contain same number of SkPoint
    
    example: https://fiddle.skia.org/c/@Path_interpolate
    */
    interpolate :: (this: *SkPath, ending: *SkPath, weight: SkScalar, out: *SkPath) -> bool #cpp_method #foreign libskia "?interpolate@SkPath@@QEBA_NAEBV1@MPEAV1@@Z";
    interpolate :: (this: *SkPath, ending: SkPath, weight: SkScalar, out: *SkPath) -> bool #no_context {
        return interpolate(this, *ending, weight, out);
    }

    /** Returns SkPathFillType, the rule used to fill SkPath.
    
    @return  current SkPathFillType setting
    */
    getFillType :: (this: *SkPath) -> SkPathFillType #cpp_method #foreign libskia "?getFillType@SkPath@@QEBA?AW4SkPathFillType@@XZ";

    /** Creates an SkPath with the same properties and data, and with SkPathFillType
    set to newFillType.
    */
    makeFillType :: (this: *SkPath, newFillType: SkPathFillType) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeFillType@SkPath@@QEBA?AV1@W4SkPathFillType@@@Z";

    /** Returns if SkPathFillType describes area outside SkPath geometry. The inverse fill area
    extends indefinitely.
    
    @return  true if FillType is kInverseWinding or kInverseEvenOdd
    */
    isInverseFillType :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isInverseFillType@SkPath@@QEBA_NXZ";

    /** Creates an SkPath with the same properties and data, and with SkPathFillType
    replaced with its inverse.  The inverse of SkPathFillType describes the area unmodified
    by the original FillType.
    */
    makeToggleInverseFillType :: (this: *SkPath) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeToggleInverseFillType@SkPath@@QEBA?AV1@XZ";

    /** Returns true if the path is convex. If necessary, it will first compute the convexity.
    */
    isConvex :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isConvex@SkPath@@QEBA_NXZ";

    /** Returns true if this path is recognized as an oval or circle.
    
    bounds receives bounds of oval.
    
    bounds is unmodified if oval is not found.
    
    @param bounds  storage for bounding SkRect of oval; may be nullptr
    @return        true if SkPath is recognized as an oval or circle
    
    example: https://fiddle.skia.org/c/@Path_isOval
    */
    isOval :: (this: *SkPath, bounds: *SkRect) -> bool #cpp_method #foreign libskia "?isOval@SkPath@@QEBA_NPEAUSkRect@@@Z";

    /** Returns true if path is representable as SkRRect.
    Returns false if path is representable as oval, circle, or SkRect.
    
    rrect receives bounds of SkRRect.
    
    rrect is unmodified if SkRRect is not found.
    
    @param rrect  storage for bounding SkRect of SkRRect; may be nullptr
    @return       true if SkPath contains only SkRRect
    
    example: https://fiddle.skia.org/c/@Path_isRRect
    */
    isRRect :: (this: *SkPath, rrect: *SkRRect) -> bool #cpp_method #foreign libskia "?isRRect@SkPath@@QEBA_NPEAVSkRRect@@@Z";

    /** Returns if SkPath is empty.
    Empty SkPath may have FillType but has no SkPoint, SkPath::Verb, or conic weight.
    SkPath() constructs empty SkPath; reset() and rewind() make SkPath empty.
    
    @return  true if the path contains no SkPath::Verb array
    */
    isEmpty :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isEmpty@SkPath@@QEBA_NXZ";

    /** Returns if contour is closed.
    Contour is closed if SkPath SkPath::Verb array was last modified by close(). When stroked,
    closed contour draws SkPaint::Join instead of SkPaint::Cap at first and last SkPoint.
    
    @return  true if the last contour ends with a kClose_Verb
    
    example: https://fiddle.skia.org/c/@Path_isLastContourClosed
    */
    isLastContourClosed :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isLastContourClosed@SkPath@@QEBA_NXZ";

    /** Returns true for finite SkPoint array values between negative SK_ScalarMax and
    positive SK_ScalarMax. Returns false for any SkPoint array value of
    SK_ScalarInfinity, SK_ScalarNegativeInfinity, or SK_ScalarNaN.
    
    @return  true if all SkPoint values are finite
    */
    isFinite :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isFinite@SkPath@@QEBA_NXZ";

    /** Returns true if the path is volatile; it will not be altered or discarded
    by the caller after it is drawn. SkPath by default have volatile set false, allowing
    SkSurface to attach a cache of data which speeds repeated drawing. If true, SkSurface
    may not speed repeated drawing.
    
    @return  true if caller will alter SkPath after drawing
    */
    isVolatile :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isVolatile@SkPath@@QEBA_NXZ";

    /** Return a copy of SkPath with isVolatile indicating whether it will be altered
    or discarded by the caller after it is drawn. SkPath by default have volatile
    set false, allowing Skia to attach a cache of data which speeds repeated drawing.
    
    Mark temporary paths, discarded or modified after use, as volatile
    to inform Skia that the path need not be cached.
    
    Mark animating SkPath volatile to improve performance.
    Mark unchanging SkPath non-volatile to improve repeated rendering.
    
    raster surface SkPath draws are affected by volatile for some shadows.
    GPU surface SkPath draws are affected by volatile for some shadows and concave geometries.
    
    @param isVolatile  true if caller will alter SkPath after drawing
    @return            SkPath
    */
    makeIsVolatile :: (this: *SkPath, isVolatile: bool) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeIsVolatile@SkPath@@QEBA?AV1@_N@Z";

    /** Tests if line between SkPoint pair is degenerate.
    Line with no length or that moves a very short distance is degenerate; it is
    treated as a point.
    
    exact changes the equality test. If true, returns true only if p1 equals p2.
    If false, returns true if p1 equals or nearly equals p2.
    
    @param p1     line start point
    @param p2     line end point
    @param exact  if false, allow nearly equals
    @return       true if line is degenerate; its length is effectively zero
    
    example: https://fiddle.skia.org/c/@Path_IsLineDegenerate
    */
    IsLineDegenerate :: (p1: *SkPoint, p2: *SkPoint, exact: bool) -> bool #foreign libskia "?IsLineDegenerate@SkPath@@SA_NAEBUSkPoint@@0_N@Z";
    IsLineDegenerate :: (p1: SkPoint, p2: SkPoint, exact: bool) -> bool #no_context {
        return IsLineDegenerate(*p1, *p2, exact);
    }

    /** Tests if quad is degenerate.
    Quad with no length or that moves a very short distance is degenerate; it is
    treated as a point.
    
    @param p1     quad start point
    @param p2     quad control point
    @param p3     quad end point
    @param exact  if true, returns true only if p1, p2, and p3 are equal;
    if false, returns true if p1, p2, and p3 are equal or nearly equal
    @return       true if quad is degenerate; its length is effectively zero
    */
    IsQuadDegenerate :: (p1: *SkPoint, p2: *SkPoint, p3: *SkPoint, exact: bool) -> bool #foreign libskia "?IsQuadDegenerate@SkPath@@SA_NAEBUSkPoint@@00_N@Z";
    IsQuadDegenerate :: (p1: SkPoint, p2: SkPoint, p3: SkPoint, exact: bool) -> bool #no_context {
        return IsQuadDegenerate(*p1, *p2, *p3, exact);
    }

    /** Tests if cubic is degenerate.
    Cubic with no length or that moves a very short distance is degenerate; it is
    treated as a point.
    
    @param p1     cubic start point
    @param p2     cubic control point 1
    @param p3     cubic control point 2
    @param p4     cubic end point
    @param exact  if true, returns true only if p1, p2, p3, and p4 are equal;
    if false, returns true if p1, p2, p3, and p4 are equal or nearly equal
    @return       true if cubic is degenerate; its length is effectively zero
    */
    IsCubicDegenerate :: (p1: *SkPoint, p2: *SkPoint, p3: *SkPoint, p4: *SkPoint, exact: bool) -> bool #foreign libskia "?IsCubicDegenerate@SkPath@@SA_NAEBUSkPoint@@000_N@Z";
    IsCubicDegenerate :: (p1: SkPoint, p2: SkPoint, p3: SkPoint, p4: SkPoint, exact: bool) -> bool #no_context {
        return IsCubicDegenerate(*p1, *p2, *p3, *p4, exact);
    }

    /** Returns true if SkPath contains only one line;
    SkPath::Verb array has two entries: kMove_Verb, kLine_Verb.
    If SkPath contains one line and line is not nullptr, line is set to
    line start point and line end point.
    Returns false if SkPath is not one line; line is unaltered.
    
    @param line  storage for line. May be nullptr
    @return      true if SkPath contains exactly one line
    
    example: https://fiddle.skia.org/c/@Path_isLine
    */
    isLine :: (this: *SkPath, line: *[2] SkPoint) -> bool #cpp_method #foreign libskia "?isLine@SkPath@@QEBA_NQEAUSkPoint@@@Z";

    /*
    *  Return a read-only view into the path's points.
    */
    points :: (this: *SkPath) -> SkSpan(SkPoint) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?points@SkPath@@QEBA?AV?$SkSpan@$$CBUSkPoint@@@@XZ";

    /*
    *  Return a read-only view into the path's verbs.
    */
    verbs :: (this: *SkPath) -> SkSpan(SkPathVerb) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?verbs@SkPath@@QEBA?AV?$SkSpan@$$CBW4SkPathVerb@@@@XZ";

    /*
    *  Return a read-only view into the path's conic-weights.
    */
    conicWeights :: (this: *SkPath) -> SkSpan(float) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?conicWeights@SkPath@@QEBA?AV?$SkSpan@$$CBM@@XZ";

    countPoints :: (this: *SkPath) -> s32 #cpp_method #foreign libskia "?countPoints@SkPath@@QEBAHXZ";
    countVerbs :: (this: *SkPath) -> s32 #cpp_method #foreign libskia "?countVerbs@SkPath@@QEBAHXZ";

    /** Return the last point, or {}
    
    @return The last if the path contains one or more SkPoint, else returns {}
    
    example: https://fiddle.skia.org/c/@Path_getLastPt
    */
    getLastPt :: (this: *SkPath) -> std.optional(SkPoint) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getLastPt@SkPath@@QEBA?AV?$optional@USkPoint@@@std@@XZ";

    /** Returns SkPoint at index in SkPoint array. Valid range for index is
    0 to countPoints() - 1.
    Returns (0, 0) if index is out of range.
    DEPRECATED
    @param index  SkPoint array element selector
    @return       SkPoint array value or (0, 0)
    */
    getPoint :: (this: *SkPath, index: s32) -> SkPoint #cpp_method #foreign libskia "?getPoint@SkPath@@QEBA?AUSkPoint@@H@Z";

    /** Returns number of points in SkPath.
    Copies N points from the path into the span, where N = min(#points, span capacity)
    DEPRECATED
    @param points  span to receive the points. may be empty
    @return the number of points in the path
    */
    getPoints :: (this: *SkPath, points: SkSpan(SkPoint)) -> u64 #cpp_method #foreign libskia "?getPoints@SkPath@@QEBA_KV?$SkSpan@USkPoint@@@@@Z";

    /** Returns number of points in SkPath.
    Copies N points from the path into the span, where N = min(#points, span capacity)
    DEPRECATED
    @param verbs span to store the verbs. may be empty.
    @return the number of verbs in the path
    
    example: https://fiddle.skia.org/c/@Path_getVerbs
    */
    getVerbs :: (this: *SkPath, verbs: SkSpan(u8)) -> u64 #cpp_method #foreign libskia "?getVerbs@SkPath@@QEBA_KV?$SkSpan@E@@@Z";

    // DEPRECATED
    getLastPt :: (this: *SkPath, lastPt: *SkPoint) -> bool #cpp_method #foreign libskia "?getLastPt@SkPath@@QEBA_NPEAUSkPoint@@@Z";

    /** Returns the approximate byte size of the SkPath in memory.
    
    @return  approximate size
    */
    approximateBytesUsed :: (this: *SkPath) -> u64 #cpp_method #foreign libskia "?approximateBytesUsed@SkPath@@QEBA_KXZ";

    /** Returns minimum and maximum axes values of SkPoint array.
    Returns (0, 0, 0, 0) if SkPath contains no points. Returned bounds width and height may
    be larger or smaller than area affected when SkPath is drawn.
    
    SkRect returned includes all SkPoint added to SkPath, including SkPoint associated with
    kMove_Verb that define empty contours.
    
    @return  bounds of all SkPoint in SkPoint array
    */
    getBounds :: (this: *SkPath) -> *SkRect #cpp_method #foreign libskia "?getBounds@SkPath@@QEBAAEBUSkRect@@XZ";

    /** Updates internal bounds so that subsequent calls to getBounds() are instantaneous.
    Unaltered copies of SkPath may also access cached bounds through getBounds().
    
    For now, identical to calling getBounds() and ignoring the returned value.
    
    Call to prepare SkPath subsequently drawn from multiple threads,
    to avoid a race condition where each draw separately computes the bounds.
    */
    updateBoundsCache :: (this: *SkPath) -> void #cpp_method #foreign libskia "?updateBoundsCache@SkPath@@QEBAXXZ";

    /** Returns minimum and maximum axes values of the lines and curves in SkPath.
    Returns (0, 0, 0, 0) if SkPath contains no points.
    Returned bounds width and height may be larger or smaller than area affected
    when SkPath is drawn.
    
    Includes SkPoint associated with kMove_Verb that define empty
    contours.
    
    Behaves identically to getBounds() when SkPath contains
    only lines. If SkPath contains curves, computed bounds includes
    the maximum extent of the quad, conic, or cubic; is slower than getBounds();
    and unlike getBounds(), does not cache the result.
    
    @return  tight bounds of curves in SkPath
    
    example: https://fiddle.skia.org/c/@Path_computeTightBounds
    */
    computeTightBounds :: (this: *SkPath) -> SkRect #cpp_method #foreign libskia "?computeTightBounds@SkPath@@QEBA?AUSkRect@@XZ";

    /** Returns true if rect is contained by SkPath.
    May return false when rect is contained by SkPath.
    
    For now, only returns true if SkPath has one contour and is convex.
    rect may share points and edges with SkPath and be contained.
    Returns true if rect is empty, that is, it has zero width or height; and
    the SkPoint or line described by rect is contained by SkPath.
    
    @param rect  SkRect, line, or SkPoint checked for containment
    @return      true if rect is contained
    
    example: https://fiddle.skia.org/c/@Path_conservativelyContainsRect
    */
    conservativelyContainsRect :: (this: *SkPath, rect: *SkRect) -> bool #cpp_method #foreign libskia "?conservativelyContainsRect@SkPath@@QEBA_NAEBUSkRect@@@Z";
    conservativelyContainsRect :: (this: *SkPath, rect: SkRect) -> bool #no_context {
        return conservativelyContainsRect(this, *rect);
    }

    /** \enum SkPath::ArcSize
    Four oval parts with radii (rx, ry) start at last SkPath SkPoint and ends at (x, y).
    ArcSize and Direction select one of the four oval parts.
    */
    ArcSize :: enum s32 {
        Small_ArcSize :: 0;
        Large_ArcSize :: 1;

        kSmall_ArcSize :: Small_ArcSize;
        kLarge_ArcSize :: Large_ArcSize;
    }

    /** Approximates conic with quad array. Conic is constructed from start SkPoint p0,
    control SkPoint p1, end SkPoint p2, and weight w.
    Quad array is stored in pts; this storage is supplied by caller.
    Maximum quad count is 2 to the pow2.
    Every third point in array shares last SkPoint of previous quad and first SkPoint of
    next quad. Maximum pts storage size is given by:
    (1 + 2 * (1 << pow2)) * sizeof(SkPoint).
    
    Returns quad count used the approximation, which may be smaller
    than the number requested.
    
    conic weight determines the amount of influence conic control point has on the curve.
    w less than one represents an elliptical section. w greater than one represents
    a hyperbolic section. w equal to one represents a parabolic section.
    
    Two quad curves are sufficient to approximate an elliptical conic with a sweep
    of up to 90 degrees; in this case, set pow2 to one.
    
    @param p0    conic start SkPoint
    @param p1    conic control SkPoint
    @param p2    conic end SkPoint
    @param w     conic weight
    @param pts   storage for quad array
    @param pow2  quad count, as power of two, normally 0 to 5 (1 to 32 quad curves)
    @return      number of quad curves written to pts
    */
    ConvertConicToQuads :: (p0: *SkPoint, p1: *SkPoint, p2: *SkPoint, w: SkScalar, pts: *SkPoint, pow2: s32) -> s32 #foreign libskia "?ConvertConicToQuads@SkPath@@SAHAEBUSkPoint@@00MQEAU2@H@Z";
    ConvertConicToQuads :: (p0: SkPoint, p1: SkPoint, p2: SkPoint, w: SkScalar, pts: *SkPoint, pow2: s32) -> s32 #no_context {
        return ConvertConicToQuads(*p0, *p1, *p2, w, pts, pow2);
    }

    /** Returns true if SkPath is equivalent to SkRect when filled.
    If false: rect, isClosed, and direction are unchanged.
    If true: rect, isClosed, and direction are written to if not nullptr.
    
    rect may be smaller than the SkPath bounds. SkPath bounds may include kMove_Verb points
    that do not alter the area drawn by the returned rect.
    
    @param rect       storage for bounds of SkRect; may be nullptr
    @param isClosed   storage set to true if SkPath is closed; may be nullptr
    @param direction  storage set to SkRect direction; may be nullptr
    @return           true if SkPath contains SkRect
    
    example: https://fiddle.skia.org/c/@Path_isRect
    */
    isRect :: (this: *SkPath, rect: *SkRect, isClosed: *bool = null, direction: *SkPathDirection = null) -> bool #cpp_method #foreign libskia "?isRect@SkPath@@QEBA_NPEAUSkRect@@PEA_NPEAW4SkPathDirection@@@Z";

    /** \enum SkPath::AddPathMode
    AddPathMode chooses how addPath() appends. Adding one SkPath to another can extend
    the last contour or start a new contour.
    */
    AddPathMode :: enum s32 {
        Append_AddPathMode :: 0;

        Extend_AddPathMode :: 1;

        kAppend_AddPathMode :: Append_AddPathMode;

        kExtend_AddPathMode :: Extend_AddPathMode;
    }

    /** Return a copy of SkPath with verb array, SkPoint array, and weight transformed
    by matrix. makeTransform may change verbs and increase their number.
    
    If the resulting path has any non-finite values, returns {}.
    
    @param matrix  SkMatrix to apply to SkPath
    @return        SkPath if finite, or {}
    */
    tryMakeTransform :: (this: *SkPath, matrix: *SkMatrix) -> std.optional(SkPath) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?tryMakeTransform@SkPath@@QEBA?AV?$optional@VSkPath@@@std@@AEBVSkMatrix@@@Z";
    tryMakeTransform :: (this: *SkPath, matrix: SkMatrix) -> std.optional(SkPath) #no_context {
        return tryMakeTransform(this, *matrix);
    }

    tryMakeOffset :: (this: *SkPath, dx: float, dy: float) -> std.optional(SkPath) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?tryMakeOffset@SkPath@@QEBA?AV?$optional@VSkPath@@@std@@MM@Z";

    tryMakeScale :: (this: *SkPath, sx: float, sy: float) -> std.optional(SkPath) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?tryMakeScale@SkPath@@QEBA?AV?$optional@VSkPath@@@std@@MM@Z";

    /** Return a copy of SkPath with verb array, SkPoint array, and weight transformed
    by matrix. makeTransform may change verbs and increase their number.
    
    If the resulting path has any non-finite values, this will still return a path
    but that path will return true for isFinite().
    
    The newer pattern is to call tryMakeTransform(matrix) which will only return a
    path if the result is finite.
    
    @param matrix  SkMatrix to apply to SkPath
    @return        SkPath
    */
    makeTransform :: (this: *SkPath, matrix: *SkMatrix) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeTransform@SkPath@@QEBA?AV1@AEBVSkMatrix@@@Z";
    makeTransform :: (this: *SkPath, matrix: SkMatrix) -> SkPath #no_context {
        return makeTransform(this, *matrix);
    }

    /** Returns SkPath with SkPoint array offset by (dx, dy).
    
    @param dx  offset added to SkPoint array x-axis coordinates
    @param dy  offset added to SkPoint array y-axis coordinates
    */
    makeOffset :: (this: *SkPath, dx: SkScalar, dy: SkScalar) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeOffset@SkPath@@QEBA?AV1@MM@Z";

    makeScale :: (this: *SkPath, sx: SkScalar, sy: SkScalar) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeScale@SkPath@@QEBA?AV1@MM@Z";

    /** \enum SkPath::SegmentMask
    SegmentMask constants correspond to each drawing Verb type in SkPath; for
    instance, if SkPath only contains lines, only the kLine_SegmentMask bit is set.
    */
    SegmentMask :: enum s32 {
        Line_SegmentMask  :: 1;
        Quad_SegmentMask  :: 2;
        Conic_SegmentMask :: 4;
        Cubic_SegmentMask :: 8;

        kLine_SegmentMask  :: Line_SegmentMask;
        kQuad_SegmentMask  :: Quad_SegmentMask;
        kConic_SegmentMask :: Conic_SegmentMask;
        kCubic_SegmentMask :: Cubic_SegmentMask;
    }

    /** Returns a mask, where each set bit corresponds to a SegmentMask constant
    if SkPath contains one or more verbs of that type.
    Returns zero if SkPath contains no lines, or curves: quads, conics, or cubics.
    
    getSegmentMasks() returns a cached result; it is very fast.
    
    @return  SegmentMask bits or zero
    */
    getSegmentMasks :: (this: *SkPath) -> u32 #cpp_method #foreign libskia "?getSegmentMasks@SkPath@@QEBAIXZ";

    /** \enum SkPath::Verb
    Verb instructs SkPath how to interpret one or more SkPoint and optional conic weight;
    manage contour, and terminate SkPath.
    */
    Verb :: enum s32 {
        Move_Verb  :: 0;
        Line_Verb  :: 1;
        Quad_Verb  :: 2;
        Conic_Verb :: 3;
        Cubic_Verb :: 4;
        Close_Verb :: 5;
        Done_Verb  :: 6;

        kMove_Verb  :: Move_Verb;
        kLine_Verb  :: Line_Verb;
        kQuad_Verb  :: Quad_Verb;
        kConic_Verb :: Conic_Verb;
        kCubic_Verb :: Cubic_Verb;
        kClose_Verb :: Close_Verb;
        kDone_Verb  :: Done_Verb;
    }

    /** Specifies whether SkPath is volatile; whether it will be altered or discarded
    by the caller after it is drawn. SkPath by default have volatile set false, allowing
    Skia to attach a cache of data which speeds repeated drawing.
    
    Mark temporary paths, discarded or modified after use, as volatile
    to inform Skia that the path need not be cached.
    
    Mark animating SkPath volatile to improve performance.
    Mark unchanging SkPath non-volatile to improve repeated rendering.
    
    raster surface SkPath draws are affected by volatile for some shadows.
    GPU surface SkPath draws are affected by volatile for some shadows and concave geometries.
    
    @param isVolatile  true if caller will alter SkPath after drawing
    @return            reference to SkPath
    */
    setIsVolatile :: (this: *SkPath, isVolatile: bool) -> *SkPath #cpp_method #foreign libskia "?setIsVolatile@SkPath@@QEAAAEAV1@_N@Z";

    /** Exchanges the verb array, SkPoint array, weights, and SkPath::FillType with other.
    Cached state is also exchanged. swap() internally exchanges pointers, so
    it is lightweight and does not allocate memory.
    
    swap() usage has largely been replaced by operator=(const SkPath& path).
    SkPath do not copy their content on assignment until they are written to,
    making assignment as efficient as swap().
    
    @param other  SkPath exchanged by value
    
    example: https://fiddle.skia.org/c/@Path_swap
    */
    swap :: (this: *SkPath, other: *SkPath) -> void #cpp_method #foreign libskia "?swap@SkPath@@QEAAXAEAV1@@Z";

    /** Sets SkPathFillType, the rule used to fill SkPath. While there is no
    check that ft is legal, values outside of SkPathFillType are not supported.
    */
    setFillType :: (this: *SkPath, ft: SkPathFillType) -> void #cpp_method #foreign libskia "?setFillType@SkPath@@QEAAXW4SkPathFillType@@@Z";

    /** Replaces SkPathFillType with its inverse. The inverse of SkPathFillType describes the area
    unmodified by the original SkPathFillType.
    */
    toggleInverseFillType :: (this: *SkPath) -> void #cpp_method #foreign libskia "?toggleInverseFillType@SkPath@@QEAAXXZ";

    /** Sets SkPath to its initial state.
    Removes verb array, SkPoint array, and weights, and sets FillType to kWinding.
    Internal storage associated with SkPath is released.
    
    @return  reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_reset
    */
    reset :: (this: *SkPath) -> *SkPath #cpp_method #foreign libskia "?reset@SkPath@@QEAAAEAV1@XZ";

    /** Returns a copy of this path in the current state, and resets the path to empty. */
//     detach :: (this: *SkPath) -> SkPath #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?detach@SkPath@@QEAA?AV1@XZ";

    /** Sets SkPath to its initial state, preserving internal storage.
    Removes verb array, SkPoint array, and weights, and sets FillType to kWinding.
    Internal storage associated with SkPath is retained.
    
    Use rewind() instead of reset() if SkPath storage will be reused and performance
    is critical.
    
    @return  reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_rewind
    */
//     rewind :: (this: *SkPath) -> *SkPath #cpp_method #foreign libskia "?rewind@SkPath@@QEAAAEAV1@XZ";

    /** Grows SkPath verb array, SkPoint array, and conics to contain additional space.
    May improve performance and use less memory by
    reducing the number and size of allocations when creating SkPath.
    
    @param extraPtCount  number of additional SkPoint to allocate
    @param extraVerbCount  number of additional verbs
    @param extraConicCount  number of additional conics
    
    example: https://fiddle.skia.org/c/@Path_incReserve
    */
//     incReserve :: (this: *SkPath, extraPtCount: s32, extraVerbCount: s32 = 0, extraConicCount: s32 = 0) -> void #cpp_method #foreign libskia "?incReserve@SkPath@@QEAAXHHH@Z";

    /** Specifies the beginning of contour. If the previous verb was a "move" verb,
    *  then this just replaces the point value of that move, otherwise it appends a new
    *  "move" verb to the path using the point.
    *
    *  Thus, each contour can only have 1 move verb in it (the last one specified).
    */
//     moveTo :: (this: *SkPath, p: SkPoint) -> *SkPath #cpp_method #foreign libskia "?moveTo@SkPath@@QEAAAEAV1@USkPoint@@@Z";

//     moveTo :: (this: *SkPath, x: SkScalar, y: SkScalar) -> *SkPath #cpp_method #foreign libskia "?moveTo@SkPath@@QEAAAEAV1@MM@Z";

    /** Adds beginning of contour relative to last point.
    If SkPath is empty, starts contour at (dx, dy).
    Otherwise, start contour at last point offset by (dx, dy).
    Function name stands for "relative move to".
    
    @param dx  offset from last point to contour start on x-axis
    @param dy  offset from last point to contour start on y-axis
    @return    reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_rMoveTo
    */
//     rMoveTo :: (this: *SkPath, dx: SkScalar, dy: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rMoveTo@SkPath@@QEAAAEAV1@MM@Z";

    /** Adds line from last point to (x, y). If SkPath is empty, or last SkPath::Verb is
    kClose_Verb, last point is set to (0, 0) before adding line.
    
    lineTo() appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed.
    lineTo() then appends kLine_Verb to verb array and (x, y) to SkPoint array.
    
    @param x  end of added line on x-axis
    @param y  end of added line on y-axis
    @return   reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_lineTo
    */
//     lineTo :: (this: *SkPath, x: SkScalar, y: SkScalar) -> *SkPath #cpp_method #foreign libskia "?lineTo@SkPath@@QEAAAEAV1@MM@Z";

    /** Adds line from last point to SkPoint p. If SkPath is empty, or last SkPath::Verb is
    kClose_Verb, last point is set to (0, 0) before adding line.
    
    lineTo() first appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed.
    lineTo() then appends kLine_Verb to verb array and SkPoint p to SkPoint array.
    
    @param p  end SkPoint of added line
    @return   reference to SkPath
    */
//     lineTo :: (this: *SkPath, p: *SkPoint) -> *SkPath #cpp_method #foreign libskia "?lineTo@SkPath@@QEAAAEAV1@AEBUSkPoint@@@Z";
    lineTo :: (this: *SkPath, p: SkPoint) -> *SkPath #no_context {
        return lineTo(this, *p);
    }

    /** Adds line from last point to vector (dx, dy). If SkPath is empty, or last SkPath::Verb is
    kClose_Verb, last point is set to (0, 0) before adding line.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed;
    then appends kLine_Verb to verb array and line end to SkPoint array.
    Line end is last point plus vector (dx, dy).
    Function name stands for "relative line to".
    
    @param dx  offset from last point to line end on x-axis
    @param dy  offset from last point to line end on y-axis
    @return    reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_rLineTo
    example: https://fiddle.skia.org/c/@Quad_a
    example: https://fiddle.skia.org/c/@Quad_b
    */
//     rLineTo :: (this: *SkPath, dx: SkScalar, dy: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rLineTo@SkPath@@QEAAAEAV1@MM@Z";

    /** Adds quad from last point towards (x1, y1), to (x2, y2).
    If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to (0, 0)
    before adding quad.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed;
    then appends kQuad_Verb to verb array; and (x1, y1), (x2, y2)
    to SkPoint array.
    
    @param x1  control SkPoint of quad on x-axis
    @param y1  control SkPoint of quad on y-axis
    @param x2  end SkPoint of quad on x-axis
    @param y2  end SkPoint of quad on y-axis
    @return    reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_quadTo
    */
//     quadTo :: (this: *SkPath, x1: SkScalar, y1: SkScalar, x2: SkScalar, y2: SkScalar) -> *SkPath #cpp_method #foreign libskia "?quadTo@SkPath@@QEAAAEAV1@MMMM@Z";

    /** Adds quad from last point towards SkPoint p1, to SkPoint p2.
    If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to (0, 0)
    before adding quad.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed;
    then appends kQuad_Verb to verb array; and SkPoint p1, p2
    to SkPoint array.
    
    @param p1  control SkPoint of added quad
    @param p2  end SkPoint of added quad
    @return    reference to SkPath
    */
//     quadTo :: (this: *SkPath, p1: *SkPoint, p2: *SkPoint) -> *SkPath #cpp_method #foreign libskia "?quadTo@SkPath@@QEAAAEAV1@AEBUSkPoint@@0@Z";
    quadTo :: (this: *SkPath, p1: SkPoint, p2: SkPoint) -> *SkPath #no_context {
        return quadTo(this, *p1, *p2);
    }

    /** Adds quad from last point towards vector (dx1, dy1), to vector (dx2, dy2).
    If SkPath is empty, or last SkPath::Verb
    is kClose_Verb, last point is set to (0, 0) before adding quad.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array,
    if needed; then appends kQuad_Verb to verb array; and appends quad
    control and quad end to SkPoint array.
    Quad control is last point plus vector (dx1, dy1).
    Quad end is last point plus vector (dx2, dy2).
    Function name stands for "relative quad to".
    
    @param dx1  offset from last point to quad control on x-axis
    @param dy1  offset from last point to quad control on y-axis
    @param dx2  offset from last point to quad end on x-axis
    @param dy2  offset from last point to quad end on y-axis
    @return     reference to SkPath
    
    example: https://fiddle.skia.org/c/@Conic_Weight_a
    example: https://fiddle.skia.org/c/@Conic_Weight_b
    example: https://fiddle.skia.org/c/@Conic_Weight_c
    example: https://fiddle.skia.org/c/@Path_rQuadTo
    */
//     rQuadTo :: (this: *SkPath, dx1: SkScalar, dy1: SkScalar, dx2: SkScalar, dy2: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rQuadTo@SkPath@@QEAAAEAV1@MMMM@Z";

    /** Adds conic from last point towards (x1, y1), to (x2, y2), weighted by w.
    If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to (0, 0)
    before adding conic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed.
    
    If w is finite and not one, appends kConic_Verb to verb array;
    and (x1, y1), (x2, y2) to SkPoint array; and w to conic weights.
    
    If w is one, appends kQuad_Verb to verb array, and
    (x1, y1), (x2, y2) to SkPoint array.
    
    If w is not finite, appends kLine_Verb twice to verb array, and
    (x1, y1), (x2, y2) to SkPoint array.
    
    @param x1  control SkPoint of conic on x-axis
    @param y1  control SkPoint of conic on y-axis
    @param x2  end SkPoint of conic on x-axis
    @param y2  end SkPoint of conic on y-axis
    @param w   weight of added conic
    @return    reference to SkPath
    */
//     conicTo :: (this: *SkPath, x1: SkScalar, y1: SkScalar, x2: SkScalar, y2: SkScalar, w: SkScalar) -> *SkPath #cpp_method #foreign libskia "?conicTo@SkPath@@QEAAAEAV1@MMMMM@Z";

    /** Adds conic from last point towards SkPoint p1, to SkPoint p2, weighted by w.
    If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to (0, 0)
    before adding conic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed.
    
    If w is finite and not one, appends kConic_Verb to verb array;
    and SkPoint p1, p2 to SkPoint array; and w to conic weights.
    
    If w is one, appends kQuad_Verb to verb array, and SkPoint p1, p2
    to SkPoint array.
    
    If w is not finite, appends kLine_Verb twice to verb array, and
    SkPoint p1, p2 to SkPoint array.
    
    @param p1  control SkPoint of added conic
    @param p2  end SkPoint of added conic
    @param w   weight of added conic
    @return    reference to SkPath
    */
//     conicTo :: (this: *SkPath, p1: *SkPoint, p2: *SkPoint, w: SkScalar) -> *SkPath #cpp_method #foreign libskia "?conicTo@SkPath@@QEAAAEAV1@AEBUSkPoint@@0M@Z";
    conicTo :: (this: *SkPath, p1: SkPoint, p2: SkPoint, w: SkScalar) -> *SkPath #no_context {
        return conicTo(this, *p1, *p2, w);
    }

    /** Adds conic from last point towards vector (dx1, dy1), to vector (dx2, dy2),
    weighted by w. If SkPath is empty, or last SkPath::Verb
    is kClose_Verb, last point is set to (0, 0) before adding conic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array,
    if needed.
    
    If w is finite and not one, next appends kConic_Verb to verb array,
    and w is recorded as conic weight; otherwise, if w is one, appends
    kQuad_Verb to verb array; or if w is not finite, appends kLine_Verb
    twice to verb array.
    
    In all cases appends SkPoint control and end to SkPoint array.
    control is last point plus vector (dx1, dy1).
    end is last point plus vector (dx2, dy2).
    
    Function name stands for "relative conic to".
    
    @param dx1  offset from last point to conic control on x-axis
    @param dy1  offset from last point to conic control on y-axis
    @param dx2  offset from last point to conic end on x-axis
    @param dy2  offset from last point to conic end on y-axis
    @param w    weight of added conic
    @return     reference to SkPath
    */
//     rConicTo :: (this: *SkPath, dx1: SkScalar, dy1: SkScalar, dx2: SkScalar, dy2: SkScalar, w: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rConicTo@SkPath@@QEAAAEAV1@MMMMM@Z";

    /** Adds cubic from last point towards (x1, y1), then towards (x2, y2), ending at
    (x3, y3). If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to
    (0, 0) before adding cubic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed;
    then appends kCubic_Verb to verb array; and (x1, y1), (x2, y2), (x3, y3)
    to SkPoint array.
    
    @param x1  first control SkPoint of cubic on x-axis
    @param y1  first control SkPoint of cubic on y-axis
    @param x2  second control SkPoint of cubic on x-axis
    @param y2  second control SkPoint of cubic on y-axis
    @param x3  end SkPoint of cubic on x-axis
    @param y3  end SkPoint of cubic on y-axis
    @return    reference to SkPath
    */
//     cubicTo :: (this: *SkPath, x1: SkScalar, y1: SkScalar, x2: SkScalar, y2: SkScalar, x3: SkScalar, y3: SkScalar) -> *SkPath #cpp_method #foreign libskia "?cubicTo@SkPath@@QEAAAEAV1@MMMMMM@Z";

    /** Adds cubic from last point towards SkPoint p1, then towards SkPoint p2, ending at
    SkPoint p3. If SkPath is empty, or last SkPath::Verb is kClose_Verb, last point is set to
    (0, 0) before adding cubic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array, if needed;
    then appends kCubic_Verb to verb array; and SkPoint p1, p2, p3
    to SkPoint array.
    
    @param p1  first control SkPoint of cubic
    @param p2  second control SkPoint of cubic
    @param p3  end SkPoint of cubic
    @return    reference to SkPath
    */
//     cubicTo :: (this: *SkPath, p1: *SkPoint, p2: *SkPoint, p3: *SkPoint) -> *SkPath #cpp_method #foreign libskia "?cubicTo@SkPath@@QEAAAEAV1@AEBUSkPoint@@00@Z";
    cubicTo :: (this: *SkPath, p1: SkPoint, p2: SkPoint, p3: SkPoint) -> *SkPath #no_context {
        return cubicTo(this, *p1, *p2, *p3);
    }

    /** Adds cubic from last point towards vector (dx1, dy1), then towards
    vector (dx2, dy2), to vector (dx3, dy3).
    If SkPath is empty, or last SkPath::Verb
    is kClose_Verb, last point is set to (0, 0) before adding cubic.
    
    Appends kMove_Verb to verb array and (0, 0) to SkPoint array,
    if needed; then appends kCubic_Verb to verb array; and appends cubic
    control and cubic end to SkPoint array.
    Cubic control is last point plus vector (dx1, dy1).
    Cubic end is last point plus vector (dx2, dy2).
    Function name stands for "relative cubic to".
    
    @param dx1  offset from last point to first cubic control on x-axis
    @param dy1  offset from last point to first cubic control on y-axis
    @param dx2  offset from last point to second cubic control on x-axis
    @param dy2  offset from last point to second cubic control on y-axis
    @param dx3  offset from last point to cubic end on x-axis
    @param dy3  offset from last point to cubic end on y-axis
    @return    reference to SkPath
    */
//     rCubicTo :: (this: *SkPath, dx1: SkScalar, dy1: SkScalar, dx2: SkScalar, dy2: SkScalar, dx3: SkScalar, dy3: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rCubicTo@SkPath@@QEAAAEAV1@MMMMMM@Z";

    /** Appends arc to SkPath. Arc added is part of ellipse
    bounded by oval, from startAngle through sweepAngle. Both startAngle and
    sweepAngle are measured in degrees, where zero degrees is aligned with the
    positive x-axis, and positive sweeps extends arc clockwise.
    
    arcTo() adds line connecting SkPath last SkPoint to initial arc SkPoint if forceMoveTo
    is false and SkPath is not empty. Otherwise, added contour begins with first point
    of arc. Angles greater than -360 and less than 360 are treated modulo 360.
    
    @param oval         bounds of ellipse containing arc
    @param startAngle   starting angle of arc in degrees
    @param sweepAngle   sweep, in degrees. Positive is clockwise; treated modulo 360
    @param forceMoveTo  true to start a new contour with arc
    @return             reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_arcTo
    */
//     arcTo :: (this: *SkPath, oval: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar, forceMoveTo: bool) -> *SkPath #cpp_method #foreign libskia "?arcTo@SkPath@@QEAAAEAV1@AEBUSkRect@@MM_N@Z";
    arcTo :: (this: *SkPath, oval: SkRect, startAngle: SkScalar, sweepAngle: SkScalar, forceMoveTo: bool) -> *SkPath #no_context {
        return arcTo(this, *oval, startAngle, sweepAngle, forceMoveTo);
    }

    /** Appends arc to SkPath, after appending line if needed. Arc is implemented by conic
    weighted to describe part of circle. Arc is contained by tangent from
    last SkPath point to (x1, y1), and tangent from (x1, y1) to (x2, y2). Arc
    is part of circle sized to radius, positioned so it touches both tangent lines.
    
    If last Path Point does not start Arc, arcTo appends connecting Line to Path.
    The length of Vector from (x1, y1) to (x2, y2) does not affect Arc.
    
    Arc sweep is always less than 180 degrees. If radius is zero, or if
    tangents are nearly parallel, arcTo appends Line from last Path Point to (x1, y1).
    
    arcTo appends at most one Line and one conic.
    arcTo implements the functionality of PostScript arct and HTML Canvas arcTo.
    
    @param x1      x-axis value common to pair of tangents
    @param y1      y-axis value common to pair of tangents
    @param x2      x-axis value end of second tangent
    @param y2      y-axis value end of second tangent
    @param radius  distance from arc to circle center
    @return        reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_arcTo_2_a
    example: https://fiddle.skia.org/c/@Path_arcTo_2_b
    example: https://fiddle.skia.org/c/@Path_arcTo_2_c
    */
//     arcTo :: (this: *SkPath, x1: SkScalar, y1: SkScalar, x2: SkScalar, y2: SkScalar, radius: SkScalar) -> *SkPath #cpp_method #foreign libskia "?arcTo@SkPath@@QEAAAEAV1@MMMMM@Z";

    /** Appends arc to SkPath, after appending line if needed. Arc is implemented by conic
    weighted to describe part of circle. Arc is contained by tangent from
    last SkPath point to p1, and tangent from p1 to p2. Arc
    is part of circle sized to radius, positioned so it touches both tangent lines.
    
    If last SkPath SkPoint does not start arc, arcTo() appends connecting line to SkPath.
    The length of vector from p1 to p2 does not affect arc.
    
    Arc sweep is always less than 180 degrees. If radius is zero, or if
    tangents are nearly parallel, arcTo() appends line from last SkPath SkPoint to p1.
    
    arcTo() appends at most one line and one conic.
    arcTo() implements the functionality of PostScript arct and HTML Canvas arcTo.
    
    @param p1      SkPoint common to pair of tangents
    @param p2      end of second tangent
    @param radius  distance from arc to circle center
    @return        reference to SkPath
    */
//     arcTo :: (this: *SkPath, p1: SkPoint, p2: SkPoint, radius: SkScalar) -> *SkPath #cpp_method #foreign libskia "?arcTo@SkPath@@QEAAAEAV1@USkPoint@@0M@Z";

    /** Appends arc to SkPath. Arc is implemented by one or more conics weighted to
    describe part of oval with radii (rx, ry) rotated by xAxisRotate degrees. Arc
    curves from last SkPath SkPoint to (x, y), choosing one of four possible routes:
    clockwise or counterclockwise, and smaller or larger.
    
    Arc sweep is always less than 360 degrees. arcTo() appends line to (x, y) if
    either radii are zero, or if last SkPath SkPoint equals (x, y). arcTo() scales radii
    (rx, ry) to fit last SkPath SkPoint and (x, y) if both are greater than zero but
    too small.
    
    arcTo() appends up to four conic curves.
    arcTo() implements the functionality of SVG arc, although SVG sweep-flag value
    is opposite the integer value of sweep; SVG sweep-flag uses 1 for clockwise,
    while kCW_Direction cast to int is zero.
    
    @param rx           radius on x-axis before x-axis rotation
    @param ry           radius on y-axis before x-axis rotation
    @param xAxisRotate  x-axis rotation in degrees; positive values are clockwise
    @param largeArc     chooses smaller or larger arc
    @param sweep        chooses clockwise or counterclockwise arc
    @param x            end of arc
    @param y            end of arc
    @return             reference to SkPath
    */
//     arcTo :: (this: *SkPath, rx: SkScalar, ry: SkScalar, xAxisRotate: SkScalar, largeArc: ArcSize, sweep: SkPathDirection, x: SkScalar, y: SkScalar) -> *SkPath #cpp_method #foreign libskia "?arcTo@SkPath@@QEAAAEAV1@MMMW4ArcSize@1@W4SkPathDirection@@MM@Z";

    /** Appends arc to SkPath. Arc is implemented by one or more conic weighted to describe
    part of oval with radii (r.fX, r.fY) rotated by xAxisRotate degrees. Arc curves
    from last SkPath SkPoint to (xy.fX, xy.fY), choosing one of four possible routes:
    clockwise or counterclockwise,
    and smaller or larger.
    
    Arc sweep is always less than 360 degrees. arcTo() appends line to xy if either
    radii are zero, or if last SkPath SkPoint equals (xy.fX, xy.fY). arcTo() scales radii r to
    fit last SkPath SkPoint and xy if both are greater than zero but too small to describe
    an arc.
    
    arcTo() appends up to four conic curves.
    arcTo() implements the functionality of SVG arc, although SVG sweep-flag value is
    opposite the integer value of sweep; SVG sweep-flag uses 1 for clockwise, while
    kCW_Direction cast to int is zero.
    
    @param r            radii on axes before x-axis rotation
    @param xAxisRotate  x-axis rotation in degrees; positive values are clockwise
    @param largeArc     chooses smaller or larger arc
    @param sweep        chooses clockwise or counterclockwise arc
    @param xy           end of arc
    @return             reference to SkPath
    */
//     arcTo :: (this: *SkPath, r: SkPoint, xAxisRotate: SkScalar, largeArc: ArcSize, sweep: SkPathDirection, xy: SkPoint) -> *SkPath #cpp_method #foreign libskia "?arcTo@SkPath@@QEAAAEAV1@USkPoint@@MW4ArcSize@1@W4SkPathDirection@@U2@@Z";

    /** Appends arc to SkPath, relative to last SkPath SkPoint. Arc is implemented by one or
    more conic, weighted to describe part of oval with radii (rx, ry) rotated by
    xAxisRotate degrees. Arc curves from last SkPath SkPoint to relative end SkPoint:
    (dx, dy), choosing one of four possible routes: clockwise or
    counterclockwise, and smaller or larger. If SkPath is empty, the start arc SkPoint
    is (0, 0).
    
    Arc sweep is always less than 360 degrees. arcTo() appends line to end SkPoint
    if either radii are zero, or if last SkPath SkPoint equals end SkPoint.
    arcTo() scales radii (rx, ry) to fit last SkPath SkPoint and end SkPoint if both are
    greater than zero but too small to describe an arc.
    
    arcTo() appends up to four conic curves.
    arcTo() implements the functionality of svg arc, although SVG "sweep-flag" value is
    opposite the integer value of sweep; SVG "sweep-flag" uses 1 for clockwise, while
    kCW_Direction cast to int is zero.
    
    @param rx           radius before x-axis rotation
    @param ry           radius before x-axis rotation
    @param xAxisRotate  x-axis rotation in degrees; positive values are clockwise
    @param largeArc     chooses smaller or larger arc
    @param sweep        chooses clockwise or counterclockwise arc
    @param dx           x-axis offset end of arc from last SkPath SkPoint
    @param dy           y-axis offset end of arc from last SkPath SkPoint
    @return             reference to SkPath
    */
//     rArcTo :: (this: *SkPath, rx: SkScalar, ry: SkScalar, xAxisRotate: SkScalar, largeArc: ArcSize, sweep: SkPathDirection, dx: SkScalar, dy: SkScalar) -> *SkPath #cpp_method #foreign libskia "?rArcTo@SkPath@@QEAAAEAV1@MMMW4ArcSize@1@W4SkPathDirection@@MM@Z";

    /** Appends kClose_Verb to SkPath. A closed contour connects the first and last SkPoint
    with line, forming a continuous loop. Open and closed contour draw the same
    with SkPaint::kFill_Style. With SkPaint::kStroke_Style, open contour draws
    SkPaint::Cap at contour start and end; closed contour draws
    SkPaint::Join at contour start and end.
    
    close() has no effect if SkPath is empty or last SkPath SkPath::Verb is kClose_Verb.
    
    @return  reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_close
    */
//     close :: (this: *SkPath) -> *SkPath #cpp_method #foreign libskia "?close@SkPath@@QEAAAEAV1@XZ";

    /** Adds a new contour to the path, defined by the rect, and wound in the
    specified direction. The verbs added to the path will be:
    
    kMove, kLine, kLine, kLine, kClose
    
    start specifies which corner to begin the contour:
    0: upper-left  corner
    1: upper-right corner
    2: lower-right corner
    3: lower-left  corner
    
    This start point also acts as the implied beginning of the subsequent,
    contour, if it does not have an explicit moveTo(). e.g.
    
    path.addRect(...)
    // if we don't say moveTo() here, we will use the rect's start point
    path.lineTo(...)
    
    @param rect   SkRect to add as a closed contour
    @param dir    SkPath::Direction to orient the new contour
    @param start  initial corner of SkRect to add
    @return       reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addRect_2
    */
//     addRect :: (this: *SkPath, rect: *SkRect, dir: SkPathDirection, start: u32) -> *SkPath #cpp_method #foreign libskia "?addRect@SkPath@@QEAAAEAV1@AEBUSkRect@@W4SkPathDirection@@I@Z";
    addRect :: (this: *SkPath, rect: SkRect, dir: SkPathDirection, start: u32) -> *SkPath #no_context {
        return addRect(this, *rect, dir, start);
    }

//     addRect :: (this: *SkPath, rect: *SkRect, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addRect@SkPath@@QEAAAEAV1@AEBUSkRect@@W4SkPathDirection@@@Z";
    addRect :: (this: *SkPath, rect: SkRect, dir: SkPathDirection = .CW) -> *SkPath #no_context {
        return addRect(this, *rect, dir);
    }

//     addRect :: (this: *SkPath, left: SkScalar, top: SkScalar, right: SkScalar, bottom: SkScalar, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addRect@SkPath@@QEAAAEAV1@MMMMW4SkPathDirection@@@Z";

    /** Adds oval to path, appending kMove_Verb, four kConic_Verb, and kClose_Verb.
    Oval is upright ellipse bounded by SkRect oval with radii equal to half oval width
    and half oval height. Oval begins at (oval.fRight, oval.centerY()) and continues
    clockwise if dir is kCW_Direction, counterclockwise if dir is kCCW_Direction.
    
    @param oval  bounds of ellipse added
    @param dir   SkPath::Direction to wind ellipse
    @return      reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addOval
    */
//     addOval :: (this: *SkPath, oval: *SkRect, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addOval@SkPath@@QEAAAEAV1@AEBUSkRect@@W4SkPathDirection@@@Z";
    addOval :: (this: *SkPath, oval: SkRect, dir: SkPathDirection = .CW) -> *SkPath #no_context {
        return addOval(this, *oval, dir);
    }

    /** Adds oval to SkPath, appending kMove_Verb, four kConic_Verb, and kClose_Verb.
    Oval is upright ellipse bounded by SkRect oval with radii equal to half oval width
    and half oval height. Oval begins at start and continues
    clockwise if dir is kCW_Direction, counterclockwise if dir is kCCW_Direction.
    
    @param oval   bounds of ellipse added
    @param dir    SkPath::Direction to wind ellipse
    @param start  index of initial point of ellipse
    @return       reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addOval_2
    */
//     addOval :: (this: *SkPath, oval: *SkRect, dir: SkPathDirection, start: u32) -> *SkPath #cpp_method #foreign libskia "?addOval@SkPath@@QEAAAEAV1@AEBUSkRect@@W4SkPathDirection@@I@Z";
    addOval :: (this: *SkPath, oval: SkRect, dir: SkPathDirection, start: u32) -> *SkPath #no_context {
        return addOval(this, *oval, dir, start);
    }

    /** Adds circle centered at (x, y) of size radius to SkPath, appending kMove_Verb,
    four kConic_Verb, and kClose_Verb. Circle begins at: (x + radius, y), continuing
    clockwise if dir is kCW_Direction, and counterclockwise if dir is kCCW_Direction.
    
    Has no effect if radius is zero or negative.
    
    @param x       center of circle
    @param y       center of circle
    @param radius  distance from center to edge
    @param dir     SkPath::Direction to wind circle
    @return        reference to SkPath
    */
//     addCircle :: (this: *SkPath, x: SkScalar, y: SkScalar, radius: SkScalar, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addCircle@SkPath@@QEAAAEAV1@MMMW4SkPathDirection@@@Z";

    /** Appends arc to SkPath, as the start of new contour. Arc added is part of ellipse
    bounded by oval, from startAngle through sweepAngle. Both startAngle and
    sweepAngle are measured in degrees, where zero degrees is aligned with the
    positive x-axis, and positive sweeps extends arc clockwise.
    
    If sweepAngle <= -360, or sweepAngle >= 360; and startAngle modulo 90 is nearly
    zero, append oval instead of arc. Otherwise, sweepAngle values are treated
    modulo 360, and arc may or may not draw depending on numeric rounding.
    
    @param oval        bounds of ellipse containing arc
    @param startAngle  starting angle of arc in degrees
    @param sweepAngle  sweep, in degrees. Positive is clockwise; treated modulo 360
    @return            reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addArc
    */
//     addArc :: (this: *SkPath, oval: *SkRect, startAngle: SkScalar, sweepAngle: SkScalar) -> *SkPath #cpp_method #foreign libskia "?addArc@SkPath@@QEAAAEAV1@AEBUSkRect@@MM@Z";
    addArc :: (this: *SkPath, oval: SkRect, startAngle: SkScalar, sweepAngle: SkScalar) -> *SkPath #no_context {
        return addArc(this, *oval, startAngle, sweepAngle);
    }

    /** Appends SkRRect to SkPath, creating a new closed contour. SkRRect has bounds
    equal to rect; each corner is 90 degrees of an ellipse with radii (rx, ry). If
    dir is kCW_Direction, SkRRect starts at top-left of the lower-left corner and
    winds clockwise. If dir is kCCW_Direction, SkRRect starts at the bottom-left
    of the upper-left corner and winds counterclockwise.
    
    If either rx or ry is too large, rx and ry are scaled uniformly until the
    corners fit. If rx or ry is less than or equal to zero, addRoundRect() appends
    SkRect rect to SkPath.
    
    After appending, SkPath may be empty, or may contain: SkRect, oval, or SkRRect.
    
    @param rect  bounds of SkRRect
    @param rx    x-axis radius of rounded corners on the SkRRect
    @param ry    y-axis radius of rounded corners on the SkRRect
    @param dir   SkPath::Direction to wind SkRRect
    @return      reference to SkPath
    */
//     addRoundRect :: (this: *SkPath, rect: *SkRect, rx: SkScalar, ry: SkScalar, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addRoundRect@SkPath@@QEAAAEAV1@AEBUSkRect@@MMW4SkPathDirection@@@Z";
    addRoundRect :: (this: *SkPath, rect: SkRect, rx: SkScalar, ry: SkScalar, dir: SkPathDirection = .CW) -> *SkPath #no_context {
        return addRoundRect(this, *rect, rx, ry, dir);
    }

    /** Appends SkRRect to SkPath, creating a new closed contour. SkRRect has bounds
    equal to rect; each corner is 90 degrees of an ellipse with radii from the
    array.
    
    @param rect   bounds of SkRRect
    @param radii  array of 8 SkScalar values, a radius pair for each corner
    @param dir    SkPath::Direction to wind SkRRect
    @return       reference to SkPath
    */
//     addRoundRect :: (this: *SkPath, rect: *SkRect, radii: SkSpan(SkScalar), dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addRoundRect@SkPath@@QEAAAEAV1@AEBUSkRect@@V?$SkSpan@$$CBM@@W4SkPathDirection@@@Z";
    addRoundRect :: (this: *SkPath, rect: SkRect, radii: SkSpan(SkScalar), dir: SkPathDirection = .CW) -> *SkPath #no_context {
        return addRoundRect(this, *rect, radii, dir);
    }

    /** Adds rrect to SkPath, creating a new closed contour. If
    dir is kCW_Direction, rrect starts at top-left of the lower-left corner and
    winds clockwise. If dir is kCCW_Direction, rrect starts at the bottom-left
    of the upper-left corner and winds counterclockwise.
    
    After appending, SkPath may be empty, or may contain: SkRect, oval, or SkRRect.
    
    @param rrect  bounds and radii of rounded rectangle
    @param dir    SkPath::Direction to wind SkRRect
    @return       reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addRRect
    */
//     addRRect :: (this: *SkPath, rrect: *SkRRect, dir: SkPathDirection = .CW) -> *SkPath #cpp_method #foreign libskia "?addRRect@SkPath@@QEAAAEAV1@AEBVSkRRect@@W4SkPathDirection@@@Z";
    addRRect :: (this: *SkPath, rrect: SkRRect, dir: SkPathDirection = .CW) -> *SkPath #no_context {
        return addRRect(this, *rrect, dir);
    }

    /** Adds rrect to SkPath, creating a new closed contour. If dir is kCW_Direction, rrect
    winds clockwise; if dir is kCCW_Direction, rrect winds counterclockwise.
    start determines the first point of rrect to add.
    
    @param rrect  bounds and radii of rounded rectangle
    @param dir    SkPath::Direction to wind SkRRect
    @param start  index of initial point of SkRRect
    @return       reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addRRect_2
    */
//     addRRect :: (this: *SkPath, rrect: *SkRRect, dir: SkPathDirection, start: u32) -> *SkPath #cpp_method #foreign libskia "?addRRect@SkPath@@QEAAAEAV1@AEBVSkRRect@@W4SkPathDirection@@I@Z";
    addRRect :: (this: *SkPath, rrect: SkRRect, dir: SkPathDirection, start: u32) -> *SkPath #no_context {
        return addRRect(this, *rrect, dir, start);
    }

    /** Adds contour created from line array, adding (count - 1) line segments.
    Contour added starts at pts[0], then adds a line for every additional SkPoint
    in pts array. If close is true, appends kClose_Verb to SkPath, connecting
    pts[count - 1] and pts[0].
    
    If count is zero, append kMove_Verb to path.
    Has no effect if count is less than one.
    
    @param pts    array of line sharing end and start SkPoint
    @param count  length of SkPoint array
    @param close  true to add line connecting contour end and start
    @return       reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_addPoly
    */
//     addPoly :: (this: *SkPath, pts: SkSpan(SkPoint), close: bool) -> *SkPath #cpp_method #foreign libskia "?addPoly@SkPath@@QEAAAEAV1@V?$SkSpan@$$CBUSkPoint@@@@_N@Z";

    /** Appends src to SkPath, offset by (dx, dy).
    
    If mode is kAppend_AddPathMode, src verb array, SkPoint array, and conic weights are
    added unaltered. If mode is kExtend_AddPathMode, add line before appending
    verbs, SkPoint, and conic weights.
    
    @param src   SkPath verbs, SkPoint, and conic weights to add
    @param dx    offset added to src SkPoint array x-axis coordinates
    @param dy    offset added to src SkPoint array y-axis coordinates
    @param mode  kAppend_AddPathMode or kExtend_AddPathMode
    @return      reference to SkPath
    */
//     addPath :: (this: *SkPath, src: *SkPath, dx: SkScalar, dy: SkScalar, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #cpp_method #foreign libskia "?addPath@SkPath@@QEAAAEAV1@AEBV1@MMW4AddPathMode@1@@Z";
    addPath :: (this: *SkPath, src: SkPath, dx: SkScalar, dy: SkScalar, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #no_context {
        return addPath(this, *src, dx, dy, mode);
    }

    /** Appends src to SkPath.
    
    If mode is kAppend_AddPathMode, src verb array, SkPoint array, and conic weights are
    added unaltered. If mode is kExtend_AddPathMode, add line before appending
    verbs, SkPoint, and conic weights.
    
    @param src   SkPath verbs, SkPoint, and conic weights to add
    @param mode  kAppend_AddPathMode or kExtend_AddPathMode
    @return      reference to SkPath
    */
//     addPath :: (this: *SkPath, src: *SkPath, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #cpp_method #foreign libskia "?addPath@SkPath@@QEAAAEAV1@AEBV1@W4AddPathMode@1@@Z";
    addPath :: (this: *SkPath, src: SkPath, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #no_context {
        return addPath(this, *src, mode);
    }

    /** Appends src to SkPath, transformed by matrix. Transformed curves may have different
    verbs, SkPoint, and conic weights.
    
    If mode is kAppend_AddPathMode, src verb array, SkPoint array, and conic weights are
    added unaltered. If mode is kExtend_AddPathMode, add line before appending
    verbs, SkPoint, and conic weights.
    
    @param src     SkPath verbs, SkPoint, and conic weights to add
    @param matrix  transform applied to src
    @param mode    kAppend_AddPathMode or kExtend_AddPathMode
    @return        reference to SkPath
    */
//     addPath :: (this: *SkPath, src: *SkPath, matrix: *SkMatrix, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #cpp_method #foreign libskia "?addPath@SkPath@@QEAAAEAV1@AEBV1@AEBVSkMatrix@@W4AddPathMode@1@@Z";
    addPath :: (this: *SkPath, src: SkPath, matrix: SkMatrix, mode: AddPathMode = .Append_AddPathMode) -> *SkPath #no_context {
        return addPath(this, *src, *matrix, mode);
    }

    /** Appends src to SkPath, from back to front.
    Reversed src always appends a new contour to SkPath.
    
    @param src  SkPath verbs, SkPoint, and conic weights to add
    @return     reference to SkPath
    
    example: https://fiddle.skia.org/c/@Path_reverseAddPath
    */
//     reverseAddPath :: (this: *SkPath, src: *SkPath) -> *SkPath #cpp_method #foreign libskia "?reverseAddPath@SkPath@@QEAAAEAV1@AEBV1@@Z";
    reverseAddPath :: (this: *SkPath, src: SkPath) -> *SkPath #no_context {
        return reverseAddPath(this, *src);
    }

    /** Sets last point to (x, y). If SkPoint array is empty, append kMove_Verb to
    verb array and append (x, y) to SkPoint array.
    
    @param x  set x-axis value of last point
    @param y  set y-axis value of last point
    
    example: https://fiddle.skia.org/c/@Path_setLastPt
    */
//     setLastPt :: (this: *SkPath, x: SkScalar, y: SkScalar) -> void #cpp_method #foreign libskia "?setLastPt@SkPath@@QEAAXMM@Z";

    /** Sets the last point on the path. If SkPoint array is empty, append kMove_Verb to
    verb array and append p to SkPoint array.
    
    @param p  set value of last point
    */
//     setLastPt :: (this: *SkPath, p: *SkPoint) -> void #cpp_method #foreign libskia "?setLastPt@SkPath@@QEAAXAEBUSkPoint@@@Z";
    setLastPt :: (this: *SkPath, p: SkPoint) #no_context {
        setLastPt(this, *p);
    }

    /** Offsets SkPoint array by (dx, dy). Offset SkPath replaces dst.
    If dst is nullptr, SkPath is replaced by offset data.
    
    @param dx   offset added to SkPoint array x-axis coordinates
    @param dy   offset added to SkPoint array y-axis coordinates
    @param dst  overwritten, translated copy of SkPath; may be nullptr
    
    example: https://fiddle.skia.org/c/@Path_offset
    */
//     offset :: (this: *SkPath, dx: SkScalar, dy: SkScalar, dst: *SkPath) -> void #cpp_method #foreign libskia "?offset@SkPath@@QEBAXMMPEAV1@@Z";

    /** Offsets SkPoint array by (dx, dy). SkPath is replaced by offset data.
    
    @param dx  offset added to SkPoint array x-axis coordinates
    @param dy  offset added to SkPoint array y-axis coordinates
    */
//     offset :: (this: *SkPath, dx: SkScalar, dy: SkScalar) -> *SkPath #cpp_method #foreign libskia "?offset@SkPath@@QEAAAEAV1@MM@Z";

    /** Transforms verb array, SkPoint array, and weight by matrix.
    transform may change verbs and increase their number.
    Transformed SkPath replaces dst; if dst is nullptr, original data
    is replaced.
    
    @param matrix  SkMatrix to apply to SkPath
    @param dst     overwritten, transformed copy of SkPath; may be nullptr
    @param pc      whether to apply perspective clipping
    
    example: https://fiddle.skia.org/c/@Path_transform
    */
//     transform :: (this: *SkPath, matrix: *SkMatrix, dst: *SkPath) -> void #cpp_method #foreign libskia "?transform@SkPath@@QEBAXAEBVSkMatrix@@PEAV1@@Z";
    transform :: (this: *SkPath, matrix: SkMatrix, dst: *SkPath) #no_context {
        transform(this, *matrix, dst);
    }

    /** Transforms verb array, SkPoint array, and weight by matrix.
    transform may change verbs and increase their number.
    SkPath is replaced by transformed data.
    
    @param matrix  SkMatrix to apply to SkPath
    @param pc      whether to apply perspective clipping
    */
//     transform :: (this: *SkPath, matrix: *SkMatrix) -> *SkPath #cpp_method #foreign libskia "?transform@SkPath@@QEAAAEAV1@AEBVSkMatrix@@@Z";
    transform :: (this: *SkPath, matrix: SkMatrix) -> *SkPath #no_context {
        return transform(this, *matrix);
    }

    iter :: (this: *SkPath) -> SkPathIter #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?iter@SkPath@@QEBA?AVSkPathIter@@XZ";

    IterRec :: struct {
        fVerb:        SkPathVerb;
        fPoints:      SkSpan(SkPoint);
        fConicWeight: float;

//         conicWeight :: (this: *IterRec) -> float #cpp_method #foreign libskia "?conicWeight@IterRec@SkPath@@QEBAMXZ";
    }

    /** \class SkPath::Iter
    Iterates through verb array, and associated SkPoint array and conic weight.
    Provides options to treat open contours as closed, and to ignore
    degenerate data.
    */
    Iter :: struct {
        /** Initializes SkPath::Iter with an empty SkPath. next() on SkPath::Iter returns
        kDone_Verb.
        Call setPath to initialize SkPath::Iter at a later time.
        
        @return  SkPath::Iter of empty SkPath
        
        example: https://fiddle.skia.org/c/@Path_Iter_Iter
        */
        Constructor :: (this: *Iter) -> void #cpp_method #foreign libskia "??0Iter@SkPath@@QEAA@XZ";

        /** Sets SkPath::Iter to return elements of verb array, SkPoint array, and conic weight in
        path. If forceClose is true, SkPath::Iter will add kLine_Verb and kClose_Verb after each
        open contour. path is not altered.
        
        @param path        SkPath to iterate
        @param forceClose  true if open contours generate kClose_Verb
        @return            SkPath::Iter of path
        
        example: https://fiddle.skia.org/c/@Path_Iter_const_SkPath
        */
        Constructor :: (this: *Iter, path: *SkPath, forceClose: bool) -> void #cpp_method #foreign libskia "??0Iter@SkPath@@QEAA@AEBV1@_N@Z";
        Constructor :: (this: *Iter, path: SkPath, forceClose: bool) #no_context {
            Constructor(this, *path, forceClose);
        }

        /** Sets SkPath::Iter to return elements of verb array, SkPoint array, and conic weight in
        path. If forceClose is true, SkPath::Iter will add kLine_Verb and kClose_Verb after each
        open contour. path is not altered.
        
        @param path        SkPath to iterate
        @param forceClose  true if open contours generate kClose_Verb
        
        example: https://fiddle.skia.org/c/@Path_Iter_setPath
        */
        setPath :: (this: *Iter, path: *SkPath, forceClose: bool) -> void #cpp_method #foreign libskia "?setPath@Iter@SkPath@@QEAAXAEBV2@_N@Z";
        setPath :: (this: *Iter, path: SkPath, forceClose: bool) #no_context {
            setPath(this, *path, forceClose);
        }

        /** Returns next SkPath::Verb in verb array, and advances SkPath::Iter.
        When verb array is exhausted, returns kDone_Verb.
        
        Zero to four SkPoint are stored in pts, depending on the returned SkPath::Verb.
        
        @param pts  storage for SkPoint data describing returned SkPath::Verb
        @return     next SkPath::Verb from verb array
        
        example: https://fiddle.skia.org/c/@Path_RawIter_next
        */
        next :: (this: *Iter, pts: *[4] SkPoint) -> Verb #cpp_method #foreign libskia "?next@Iter@SkPath@@QEAA?AW4Verb@2@QEAUSkPoint@@@Z";

        next :: (this: *Iter) -> std.optional(IterRec) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?next@Iter@SkPath@@QEAA?AV?$optional@UIterRec@SkPath@@@std@@XZ";

        /** Returns conic weight if next() returned kConic_Verb.
        
        If next() has not been called, or next() did not return kConic_Verb,
        result is undefined.
        
        @return  conic weight for conic SkPoint returned by next()
        */
        conicWeight :: (this: *Iter) -> SkScalar #cpp_method #foreign libskia "?conicWeight@Iter@SkPath@@QEBAMXZ";

        /** Returns true if last kLine_Verb returned by next() was generated
        by kClose_Verb. When true, the end point returned by next() is
        also the start point of contour.
        
        If next() has not been called, or next() did not return kLine_Verb,
        result is undefined.
        
        @return  true if last kLine_Verb was generated by kClose_Verb
        */
        isCloseLine :: (this: *Iter) -> bool #cpp_method #foreign libskia "?isCloseLine@Iter@SkPath@@QEBA_NXZ";

        /** Returns true if subsequent calls to next() return kClose_Verb before returning
        kMove_Verb. if true, contour SkPath::Iter is processing may end with kClose_Verb, or
        SkPath::Iter may have been initialized with force close set to true.
        
        @return  true if contour is closed
        
        example: https://fiddle.skia.org/c/@Path_Iter_isClosedContour
        */
        isClosedContour :: (this: *Iter) -> bool #cpp_method #foreign libskia "?isClosedContour@Iter@SkPath@@QEBA_NXZ";

        fPts:          *SkPoint;
        fVerbs:        *SkPathVerb;
        fVerbStop:     *SkPathVerb;
        fConicWeights: *SkScalar;
        fMoveTo:       SkPoint;
        fLastPt:       SkPoint;
        fStorage:      std.array(SkPoint, 4);
        fForceClose:   bool;
        fNeedClose:    bool;
        fCloseLine:    bool;

        autoClose :: (this: *Iter, pts: *[2] SkPoint) -> SkPathVerb #cpp_method #foreign libskia "?autoClose@Iter@SkPath@@AEAA?AW4SkPathVerb@@QEAUSkPoint@@@Z";
    }

    getOvalInfo :: (this: *SkPath) -> std.optional(SkPathOvalInfo) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getOvalInfo@SkPath@@AEBA?AV?$optional@USkPathOvalInfo@@@std@@XZ";
    getRRectInfo :: (this: *SkPath) -> std.optional(SkPathRRectInfo) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getRRectInfo@SkPath@@AEBA?AV?$optional@USkPathRRectInfo@@@std@@XZ";
    raw :: (this: *SkPath, unknown0: SkResolveConvexity) -> std.optional(SkPathRaw) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?raw@SkPath@@AEBA?AV?$optional@USkPathRaw@@@std@@W4SkResolveConvexity@@@Z";

    /** \class SkPath::RangeIter
    Iterates through a raw range of path verbs, points, and conics. All values are returned
    unaltered.
    
    NOTE: This class will be moved into SkPathPriv once RangeIter is removed.
    */
    RangeIter :: struct {
//         Constructor :: (this: *RangeIter) -> void #cpp_method #foreign libskia "??0RangeIter@SkPath@@QEAA@XZ";
//         Constructor :: (this: *RangeIter, verbs: *SkPathVerb, points: *SkPoint, weights: *SkScalar) -> void #cpp_method #foreign libskia "??0RangeIter@SkPath@@QEAA@PEBW4SkPathVerb@@PEBUSkPoint@@PEBM@Z";

//         peekVerb :: (this: *RangeIter) -> SkPathVerb #cpp_method #foreign libskia "?peekVerb@RangeIter@SkPath@@QEBA?AW4SkPathVerb@@XZ";

//         pts_advance_after_verb :: (verb: SkPathVerb) -> s32 #foreign libskia "?pts_advance_after_verb@RangeIter@SkPath@@CAHW4SkPathVerb@@@Z";

//         pts_backset_for_verb :: (verb: SkPathVerb) -> s32 #foreign libskia "?pts_backset_for_verb@RangeIter@SkPath@@CAHW4SkPathVerb@@@Z";

        fVerb:          *SkPathVerb = null;
        fPoints:        *SkPoint = null;
        fWeights:       *SkScalar = null;
        fInitialPoints: *SkPoint = null;
    }

//     operator_neq :: (this: *SkPath.RangeIter, that: *SkPath.RangeIter) -> bool #cpp_method #foreign libskia "??9RangeIter@SkPath@@QEBA_NAEBV01@@Z";
    operator_neq :: (this: SkPath.RangeIter, that: SkPath.RangeIter) -> bool #no_context {
        return operator_neq(*this, *that);
    }

//     operator_eq :: (this: *SkPath.RangeIter, that: *SkPath.RangeIter) -> bool #cpp_method #foreign libskia "??8RangeIter@SkPath@@QEBA_NAEBV01@@Z";
    operator_eq :: (this: SkPath.RangeIter, that: SkPath.RangeIter) -> bool #no_context {
        return operator_eq(*this, *that);
    }

//     operator_plus_plus :: (this: *SkPath.RangeIter) -> *SkPath.RangeIter #cpp_method #foreign libskia "??ERangeIter@SkPath@@QEAAAEAV01@XZ";
    operator_plus_plus :: (this: SkPath.RangeIter) -> *SkPath.RangeIter #no_context {
        return operator_plus_plus(*this);
    }

//     operator_plus_plus :: (this: *SkPath.RangeIter, unknown0: s32) -> SkPath.RangeIter #cpp_method #cpp_return_type_is_non_pod #foreign libskia "??ERangeIter@SkPath@@QEAA?AV01@H@Z";
    operator_plus_plus :: (this: SkPath.RangeIter, unknown0: s32) -> SkPath.RangeIter #no_context {
        return operator_plus_plus(*this, unknown0);
    }

    /** \class SkPath::RawIter
    Use Iter instead. This class will soon be removed and RangeIter will be made private.
    */
    RawIter :: struct {
        /** Initializes RawIter with an empty SkPath. next() on RawIter returns kDone_Verb.
        Call setPath to initialize SkPath::Iter at a later time.
        
        @return  RawIter of empty SkPath
        */
        Constructor :: (this: *RawIter) -> void #cpp_method #foreign libskia "??0RawIter@SkPath@@QEAA@XZ";

        /** Sets RawIter to return elements of verb array, SkPoint array, and conic weight in path.
        
        @param path  SkPath to iterate
        @return      RawIter of path
        */
        Constructor :: (this: *RawIter, path: *SkPath) -> void #cpp_method #foreign libskia "??0RawIter@SkPath@@QEAA@AEBV1@@Z";
        Constructor :: (this: *RawIter, path: SkPath) #no_context {
            Constructor(this, *path);
        }

        /** Sets SkPath::Iter to return elements of verb array, SkPoint array, and conic weight in
        path.
        
        @param path  SkPath to iterate
        */
        setPath :: (this: *RawIter, unknown0: *SkPath) -> void #cpp_method #foreign libskia "?setPath@RawIter@SkPath@@QEAAXAEBV2@@Z";
        setPath :: (this: *RawIter, unknown0: SkPath) #no_context {
            setPath(this, *unknown0);
        }

        /** Returns next SkPath::Verb in verb array, and advances RawIter.
        When verb array is exhausted, returns kDone_Verb.
        Zero to four SkPoint are stored in pts, depending on the returned SkPath::Verb.
        
        @param pts  storage for SkPoint data describing returned SkPath::Verb
        @return     next SkPath::Verb from verb array
        */
        next :: (this: *RawIter, unknown0: *[4] SkPoint) -> Verb #cpp_method #foreign libskia "?next@RawIter@SkPath@@QEAA?AW4Verb@2@QEAUSkPoint@@@Z";

        next :: (this: *RawIter) -> std.optional(IterRec) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?next@RawIter@SkPath@@QEAA?AV?$optional@UIterRec@SkPath@@@std@@XZ";

        /** Returns next SkPath::Verb, but does not advance RawIter.
        
        @return  next SkPath::Verb from verb array
        */
        peek :: (this: *RawIter) -> Verb #cpp_method #foreign libskia "?peek@RawIter@SkPath@@QEBA?AW4Verb@2@XZ";

        /** Returns conic weight if next() returned kConic_Verb.
        
        If next() has not been called, or next() did not return kConic_Verb,
        result is undefined.
        
        @return  conic weight for conic SkPoint returned by next()
        */
        conicWeight :: (this: *RawIter) -> SkScalar #cpp_method #foreign libskia "?conicWeight@RawIter@SkPath@@QEBAMXZ";

        fIter:        RangeIter;
        fEnd:         RangeIter;
        fConicWeight: SkScalar = 0;
    }

    /** Returns true if the point is contained by SkPath, taking into
    account FillType.
    
    @param point the point to test
    @return true if SkPoint is in SkPath
    */
    contains :: (this: *SkPath, point: SkPoint) -> bool #cpp_method #foreign libskia "?contains@SkPath@@QEBA_NUSkPoint@@@Z";

    // deprecated
    contains :: (this: *SkPath, x: SkScalar, y: SkScalar) -> bool #cpp_method #foreign libskia "?contains@SkPath@@QEBA_NMM@Z";

    /** Writes text representation of SkPath to stream. If stream is nullptr, writes to
    standard output. Set dumpAsHex true to generate exact binary representations
    of floating point numbers used in SkPoint array and conic weights.
    
    @param stream      writable SkWStream receiving SkPath text representation; may be nullptr
    @param dumpAsHex   true if SkScalar values are written as hexadecimal
    
    example: https://fiddle.skia.org/c/@Path_dump
    */
    dump :: (this: *SkPath, stream: *SkWStream, dumpAsHex: bool) -> void #cpp_method #foreign libskia "?dump@SkPath@@QEBAXPEAVSkWStream@@_N@Z";

    dump :: (this: *SkPath) -> void #cpp_method #foreign libskia "?dump@SkPath@@QEBAXXZ";
    dumpHex :: (this: *SkPath) -> void #cpp_method #foreign libskia "?dumpHex@SkPath@@QEBAXXZ";

    /** Writes SkPath to buffer, returning the number of bytes written.
    Pass nullptr to obtain the storage size.
    
    Writes SkPath::FillType, verb array, SkPoint array, conic weight, and
    additionally writes computed information like SkPath::Convexity and bounds.
    
    Use only be used in concert with readFromMemory();
    the format used for SkPath in memory is not guaranteed.
    
    @param buffer  storage for SkPath; may be nullptr
    @return        size of storage required for SkPath; always a multiple of 4
    
    example: https://fiddle.skia.org/c/@Path_writeToMemory
    */
    writeToMemory :: (this: *SkPath, buffer: *void) -> u64 #cpp_method #foreign libskia "?writeToMemory@SkPath@@QEBA_KPEAX@Z";

    /** Writes SkPath to buffer, returning the buffer written to, wrapped in SkData.
    
    serialize() writes SkPath::FillType, verb array, SkPoint array, conic weight, and
    additionally writes computed information like SkPath::Convexity and bounds.
    
    serialize() should only be used in concert with readFromMemory().
    The format used for SkPath in memory is not guaranteed.
    
    @return  SkPath data wrapped in SkData buffer
    
    example: https://fiddle.skia.org/c/@Path_serialize
    */
    serialize :: (this: *SkPath) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@SkPath@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

    /** Returns a SkPath from buffer of size length. If the buffer data is inconsistent, or the
    length is too small, returns a nullopt.
    
    Reads SkPath::FillType, verb array, SkPoint array, conic weight, and
    additionally reads computed information like SkPath::Convexity and bounds.
    
    Used only in concert with writeToMemory();
    the format used for SkPath in memory is not guaranteed.
    
    @param buffer    storage for SkPath
    @param length    buffer size in bytes; must be multiple of 4
    @param bytesRead if not null, the number of bytes read from buffer will be written here
    @return          the path read, or nullopt on failure
    
    example: https://fiddle.skia.org/c/@Path_readFromMemory
    */
    ReadFromMemory :: (buffer: *void, length: u64, bytesRead: *u64 = null) -> std.optional(SkPath) #cpp_return_type_is_non_pod #foreign libskia "?ReadFromMemory@SkPath@@SA?AV?$optional@VSkPath@@@std@@PEBX_KPEA_K@Z";

//     readFromMemory :: (this: *SkPath, buffer: *void, length: u64) -> u64 #cpp_method #foreign libskia "?readFromMemory@SkPath@@QEAA_KPEBX_K@Z";

    /** (See skbug.com/40032862)
    Returns a non-zero, globally unique value. A different value is returned
    if verb array, SkPoint array, or conic weight changes.
    
    Setting SkPath::FillType does not change generation identifier.
    
    Each time the path is modified, a different generation identifier will be returned.
    SkPath::FillType does affect generation identifier on Android framework.
    
    @return  non-zero, globally unique value
    
    example: https://fiddle.skia.org/c/@Path_getGenerationID
    */
    getGenerationID :: (this: *SkPath) -> u32 #cpp_method #foreign libskia "?getGenerationID@SkPath@@QEBAIXZ";

    /** Returns if SkPath data is consistent. Corrupt SkPath data is detected if
    internal values are out of range or internal storage does not match
    array dimensions.
    
    @return  true if SkPath data is consistent
    */
    isValid :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isValid@SkPath@@QEBA_NXZ";

    sk_is_trivially_relocatable :: std.true_type;

//     Constructor :: (this: *SkPath, unknown0: sk_sp(SkPathRef), unknown1: SkPathFillType, isVolatile: bool, unknown2: SkPathConvexity) -> void #cpp_method #foreign libskia "??0SkPath@@AEAA@V?$sk_sp@VSkPathRef@@@@W4SkPathFillType@@_NW4SkPathConvexity@@@Z";

    fPathRef:                    sk_sp(SkPathRef);
    fLastMoveToIndex:            s32;
    fConvexity:                  std.atomic(u8); // SkPathConvexity
    fFillType:                   SkPathFillType;
    fIsVolatile:                 bool;

    /** Resets all fields other than fPathRef to their initial 'empty' values.
    *  Assumes the caller has already emptied fPathRef.
    */
//     resetFields :: (this: *SkPath) -> void #cpp_method #foreign libskia "?resetFields@SkPath@@AEAAXXZ";

    /** Sets all fields other than fPathRef to the values in 'that'.
    *  Assumes the caller has already set fPathRef.
    *  Doesn't change fGenerationID or fSourcePath on Android.
    */
//     copyFields :: (this: *SkPath, that: *SkPath) -> void #cpp_method #foreign libskia "?copyFields@SkPath@@AEAAXAEBV1@@Z";
    copyFields :: (this: *SkPath, that: SkPath) #no_context {
        copyFields(this, *that);
    }

    // Creates a new Path after the supplied arguments have been validated by
    // SkPathPriv::AnalyzeVerbs().
//     MakeInternal :: (unknown0: *SkPathVerbAnalysis, unknown1: *SkPoint, unknown2: SkSpan(SkPathVerb), conics: *float, unknown3: SkPathFillType, isVolatile: bool) -> SkPath #cpp_return_type_is_non_pod #foreign libskia "?MakeInternal@SkPath@@CA?AV1@AEBUSkPathVerbAnalysis@@QEBUSkPoint@@V?$SkSpan@$$CBW4SkPathVerb@@@@QEBMW4SkPathFillType@@_N@Z";
    MakeInternal :: (unknown0: SkPathVerbAnalysis, unknown1: *SkPoint, unknown2: SkSpan(SkPathVerb), conics: *float, unknown3: SkPathFillType, isVolatile: bool) -> SkPath #no_context {
        return MakeInternal(*unknown0, unknown1, unknown2, conics, unknown3, isVolatile);
    }

    writeToMemoryAsRRect :: (this: *SkPath, buffer: *void) -> u64 #cpp_method #foreign libskia "?writeToMemoryAsRRect@SkPath@@AEBA_KPEAX@Z";
    readAsRRect :: (this: *SkPath, unknown0: *void, unknown1: u64) -> u64 #cpp_method #foreign libskia "?readAsRRect@SkPath@@AEAA_KPEBX_K@Z";

    /*  Append, in reverse order, the first contour of path, ignoring path's
    last point. If no moveTo() call has been made for this contour, the
    first point is automatically set to (0,0).
    */
//     reversePathTo :: (this: *SkPath, unknown0: *SkPath) -> *SkPath #cpp_method #foreign libskia "?reversePathTo@SkPath@@AEAAAEAV1@AEBV1@@Z";
    reversePathTo :: (this: *SkPath, unknown0: SkPath) -> *SkPath #no_context {
        return reversePathTo(this, *unknown0);
    }

    // called before we add points for lineTo, quadTo, cubicTo, checking to see
    // if we need to inject a leading moveTo first
    //
    //  SkPath path; path.lineTo(...);   <--- need a leading moveTo(0, 0)
    // SkPath path; ... path.close(); path.lineTo(...) <-- need a moveTo(previous moveTo)
    //
//     injectMoveToIfNeeded :: (this: *SkPath) -> void #cpp_method #foreign libskia "?injectMoveToIfNeeded@SkPath@@AEAAXXZ";

    hasOnlyMoveTos :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?hasOnlyMoveTos@SkPath@@AEBA_NXZ";

    computeConvexity :: (this: *SkPath) -> SkPathConvexity #cpp_method #foreign libskia "?computeConvexity@SkPath@@AEBA?AW4SkPathConvexity@@XZ";

//     isValidImpl :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?isValidImpl@SkPath@@AEBA_NXZ";

//     validate :: (this: *SkPath) -> void #cpp_method #foreign libskia "?validate@SkPath@@AEBAXXZ";
//     validateRef :: (this: *SkPath) -> void #cpp_method #foreign libskia "?validateRef@SkPath@@AEBAXXZ";

    // called by stroker to see if all points (in the last contour) are equal and worthy of a cap
    isZeroLengthSincePoint :: (this: *SkPath, startPtIndex: s32) -> bool #cpp_method #foreign libskia "?isZeroLengthSincePoint@SkPath@@AEBA_NH@Z";

    /** Returns if the path can return a bound at no cost (true) or will have to
    perform some computation (false).
    */
    hasComputedBounds :: (this: *SkPath) -> bool #cpp_method #foreign libskia "?hasComputedBounds@SkPath@@AEBA_NXZ";

    // 'rect' needs to be sorted
//     setBounds :: (this: *SkPath, rect: *SkRect) -> void #cpp_method #foreign libskia "?setBounds@SkPath@@AEAAXAEBUSkRect@@@Z";
    setBounds :: (this: *SkPath, rect: SkRect) #no_context {
        setBounds(this, *rect);
    }

//     setPt :: (this: *SkPath, index: s32, x: SkScalar, y: SkScalar) -> void #cpp_method #foreign libskia "?setPt@SkPath@@AEAAXHMM@Z";

//     dirtyAfterEdit :: (this: *SkPath) -> *SkPath #cpp_method #foreign libskia "?dirtyAfterEdit@SkPath@@AEAAAEAV1@XZ";

//     addRaw :: (this: *SkPath, unknown0: *SkPathRaw) -> void #cpp_method #foreign libskia "?addRaw@SkPath@@AEAAXAEBUSkPathRaw@@@Z";
    addRaw :: (this: *SkPath, unknown0: SkPathRaw) #no_context {
        addRaw(this, *unknown0);
    }

    /** Returns the comvexity type, computing if needed. Never returns kUnknown.
    @return  path's convexity type (convex or concave)
    */
    getConvexity :: (this: *SkPath) -> SkPathConvexity #cpp_method #foreign libskia "?getConvexity@SkPath@@AEBA?AW4SkPathConvexity@@XZ";

    getConvexityOrUnknown :: (this: *SkPath) -> SkPathConvexity #cpp_method #foreign libskia "?getConvexityOrUnknown@SkPath@@AEBA?AW4SkPathConvexity@@XZ";

    /** Stores a convexity type for this path. This is what will be returned if
    *  getConvexityOrUnknown() is called. If you pass kUnknown, then if getContexityType()
    *  is called, the real convexity will be computed.
    */
    setConvexity :: (this: *SkPath, unknown0: SkPathConvexity) -> void #cpp_method #foreign libskia "?setConvexity@SkPath@@AEBAXW4SkPathConvexity@@@Z";
}

/** Constructs a copy of an existing path.
SkPath assignment makes two paths identical by value. Internally, assignment
shares pointer values. The underlying verb array, SkPoint array and weights
are copied when modified.

Copying SkPath by assignment is very efficient and never allocates memory.
SkPath are always copied by value from the interface; the underlying shared
pointers are not exposed.

@param path  verb array, SkPoint array, weights, and SkPath::FillType to copy
@return      SkPath copied by value

example: https://fiddle.skia.org/c/@Path_copy_operator
*/
operator_assign :: (this: *SkPath, path: *SkPath) -> *SkPath #cpp_method #foreign libskia "??4SkPath@@QEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkPath, path: SkPath) -> *SkPath #no_context {
    return operator_assign(this, *path);
}

SkFourByteTag :: u32;

// SkSetFourByteTag :: (a: u8, b: u8, c: u8, d: u8) -> SkFourByteTag #foreign libskia "?SkSetFourByteTag@@YAIDDDD@Z";

/** Represents a set of actual arguments for a font. */
SkFontArguments :: struct {
    VariationPosition :: struct {
        Coordinate :: struct {
            axis:  SkFourByteTag;
            value: float;
        }

        coordinates:     *Coordinate;
        coordinateCount: s32;
    }

    /** Specify a palette to use and overrides for palette entries.
    *
    *  `overrides` is a list of pairs of palette entry index and color.
    *  The overriden palette entries will use the associated color.
    *  Override pairs with palette entry indices out of range will not be applied.
    *  Later override entries override earlier ones.
    */
    Palette :: struct {
        Override :: struct {
            index: u16;
            color: SkColor;
        }

        index:         s32;
        overrides:     *Override;
        overrideCount: s32;
    }

//     Constructor :: (this: *SkFontArguments) -> void #cpp_method #foreign libskia "??0SkFontArguments@@QEAA@XZ";

    /** Specify the index of the desired font.
    *
    *  Font formats like ttc, dfont, cff, cid, pfr, t42, t1, and fon may actually be indexed
    *  collections of fonts.
    */
//     setCollectionIndex :: (this: *SkFontArguments, collectionIndex: s32) -> *SkFontArguments #cpp_method #foreign libskia "?setCollectionIndex@SkFontArguments@@QEAAAEAU1@H@Z";

    /** Specify a position in the variation design space.
    *
    *  Any axis not specified will use the default value.
    *  Any specified axis not actually present in the font will be ignored.
    *
    *  @param position not copied. The value must remain valid for life of SkFontArguments.
    */
//     setVariationDesignPosition :: (this: *SkFontArguments, position: VariationPosition) -> *SkFontArguments #cpp_method #foreign libskia "?setVariationDesignPosition@SkFontArguments@@QEAAAEAU1@UVariationPosition@1@@Z";

//     getCollectionIndex :: (this: *SkFontArguments) -> s32 #cpp_method #foreign libskia "?getCollectionIndex@SkFontArguments@@QEBAHXZ";

//     getVariationDesignPosition :: (this: *SkFontArguments) -> VariationPosition #cpp_method #foreign libskia "?getVariationDesignPosition@SkFontArguments@@QEBA?AUVariationPosition@1@XZ";

//     setPalette :: (this: *SkFontArguments, palette: Palette) -> *SkFontArguments #cpp_method #foreign libskia "?setPalette@SkFontArguments@@QEAAAEAU1@UPalette@1@@Z";

//     getPalette :: (this: *SkFontArguments) -> Palette #cpp_method #foreign libskia "?getPalette@SkFontArguments@@QEBA?AUPalette@1@XZ";

    fCollectionIndex:         s32;
    fVariationDesignPosition: VariationPosition;
    fPalette:                 Palette;
}

SkFontParameters :: struct {
    using skfontparameters__raw: SkFontParameters__RAW;
    __empty_struct_padding:      u8; // C++ makes empty structs have length 1
}
// SkFontParameters without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFontParameters
SkFontParameters__RAW :: struct {
    Variation :: struct {
        using variation__raw:   Variation__RAW;
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
        // Variation without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from Variation
    Variation__RAW :: struct {
        // Parameters in a variation font axis.
        Axis :: struct {
//             Constructor :: (this: *Axis) -> void #cpp_method #foreign libskia "??0Axis@Variation@SkFontParameters@@QEAA@XZ";
//             Constructor :: (this: *Axis, tag: SkFourByteTag, min: float, def: float, max: float, hidden: bool) -> void #cpp_method #foreign libskia "??0Axis@Variation@SkFontParameters@@QEAA@IMMM_N@Z";

            // Four character identifier of the font axis (weight, width, slant, italic...).
            tag:    SkFourByteTag;

            // Minimum value supported by this axis.
            min:    float;

            // Default value set by this axis.
            def:    float;

            // Maximum value supported by this axis. The maximum can equal the minimum.
            max:    float;

            // Return whether this axis is recommended to be remain hidden in user interfaces.
//             isHidden :: (this: *Axis) -> bool #cpp_method #foreign libskia "?isHidden@Axis@Variation@SkFontParameters@@QEBA_NXZ";

            // Set this axis to be remain hidden in user interfaces.
//             setHidden :: (this: *Axis, hidden: bool) -> void #cpp_method #foreign libskia "?setHidden@Axis@Variation@SkFontParameters@@QEAAX_N@Z";

            HIDDEN: u16 : 1;

            // Attributes for a font axis.
            flags:  u16;
        }
    }
}

SkFontStyle :: struct {
    Weight :: enum s32 {
        Invisible_Weight  :: 0;
        Thin_Weight       :: 100;
        ExtraLight_Weight :: 200;
        Light_Weight      :: 300;
        Normal_Weight     :: 400;
        Medium_Weight     :: 500;
        SemiBold_Weight   :: 600;
        Bold_Weight       :: 700;
        ExtraBold_Weight  :: 800;
        Black_Weight      :: 900;
        ExtraBlack_Weight :: 1000;

        kInvisible_Weight  :: Invisible_Weight;
        kThin_Weight       :: Thin_Weight;
        kExtraLight_Weight :: ExtraLight_Weight;
        kLight_Weight      :: Light_Weight;
        kNormal_Weight     :: Normal_Weight;
        kMedium_Weight     :: Medium_Weight;
        kSemiBold_Weight   :: SemiBold_Weight;
        kBold_Weight       :: Bold_Weight;
        kExtraBold_Weight  :: ExtraBold_Weight;
        kBlack_Weight      :: Black_Weight;
        kExtraBlack_Weight :: ExtraBlack_Weight;
    }

    Width :: enum s32 {
        UltraCondensed_Width :: 1;
        ExtraCondensed_Width :: 2;
        Condensed_Width      :: 3;
        SemiCondensed_Width  :: 4;
        Normal_Width         :: 5;
        SemiExpanded_Width   :: 6;
        Expanded_Width       :: 7;
        ExtraExpanded_Width  :: 8;
        UltraExpanded_Width  :: 9;

        kUltraCondensed_Width :: UltraCondensed_Width;
        kExtraCondensed_Width :: ExtraCondensed_Width;
        kCondensed_Width      :: Condensed_Width;
        kSemiCondensed_Width  :: SemiCondensed_Width;
        kNormal_Width         :: Normal_Width;
        kSemiExpanded_Width   :: SemiExpanded_Width;
        kExpanded_Width       :: Expanded_Width;
        kExtraExpanded_Width  :: ExtraExpanded_Width;
        kUltraExpanded_Width  :: UltraExpanded_Width;
    }

    Slant :: enum u8 {
        Upright_Slant :: 0;
        Italic_Slant  :: 1;
        Oblique_Slant :: 2;

        kUpright_Slant :: Upright_Slant;
        kItalic_Slant  :: Italic_Slant;
        kOblique_Slant :: Oblique_Slant;
    }

    Constructor :: (this: *SkFontStyle, weight: s32, width: s32, slant: Slant) -> void #cpp_method #foreign libskia "??0SkFontStyle@@QEAA@HHW4Slant@0@@Z";

    Constructor :: (this: *SkFontStyle) -> void #cpp_method #foreign libskia "??0SkFontStyle@@QEAA@XZ";

    weight :: (this: *SkFontStyle) -> s32 #cpp_method #foreign libskia "?weight@SkFontStyle@@QEBAHXZ";
    width :: (this: *SkFontStyle) -> s32 #cpp_method #foreign libskia "?width@SkFontStyle@@QEBAHXZ";
    slant :: (this: *SkFontStyle) -> Slant #cpp_method #foreign libskia "?slant@SkFontStyle@@QEBA?AW4Slant@1@XZ";

    Normal :: () -> SkFontStyle #cpp_return_type_is_non_pod #foreign libskia "?Normal@SkFontStyle@@SA?AV1@XZ";

    Bold :: () -> SkFontStyle #cpp_return_type_is_non_pod #foreign libskia "?Bold@SkFontStyle@@SA?AV1@XZ";

    Italic :: () -> SkFontStyle #cpp_return_type_is_non_pod #foreign libskia "?Italic@SkFontStyle@@SA?AV1@XZ";

    BoldItalic :: () -> SkFontStyle #cpp_return_type_is_non_pod #foreign libskia "?BoldItalic@SkFontStyle@@SA?AV1@XZ";

    fValue: s32;
}

operator_eq :: (this: *SkFontStyle, rhs: *SkFontStyle) -> bool #cpp_method #foreign libskia "??8SkFontStyle@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkFontStyle, rhs: SkFontStyle) -> bool #no_context {
    return operator_eq(*this, *rhs);
}

/** \class SkWeakRefCnt

SkWeakRefCnt is the base class for objects that may be shared by multiple
objects. When an existing strong owner wants to share a reference, it calls
ref(). When a strong owner wants to release its reference, it calls
unref(). When the shared object's strong reference count goes to zero as
the result of an unref() call, its (virtual) weak_dispose method is called.
It is an error for the destructor to be called explicitly (or via the
object going out of scope on the stack or calling delete) if
getRefCnt() > 1.

In addition to strong ownership, an owner may instead obtain a weak
reference by calling weak_ref(). A call to weak_ref() must be balanced by a
call to weak_unref(). To obtain a strong reference from a weak reference,
call try_ref(). If try_ref() returns true, the owner's pointer is now also
a strong reference on which unref() must be called. Note that this does not
affect the original weak reference, weak_unref() must still be called. When
the weak reference count goes to zero, the object is deleted. While the
weak reference count is positive and the strong reference count is zero the
object still exists, but will be in the disposed state. It is up to the
object to define what this means.

Note that a strong reference implicitly implies a weak reference. As a
result, it is allowable for the owner of a strong ref to call try_ref().
This will have the same effect as calling ref(), but may be more expensive.

Example:

SkWeakRefCnt myRef = strongRef.weak_ref();
... // strongRef.unref() may or may not be called
if (myRef.try_ref()) {
... // use myRef
myRef.unref();
} else {
// myRef is in the disposed state
}
myRef.weak_unref();
*/
SkWeakRefCnt :: struct {
    vtable:                  *SkWeakRefCnt_VTable;
    using skweakrefcnt__raw: SkWeakRefCnt__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkWeakRefCnt without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkWeakRefCnt
SkWeakRefCnt__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    /** Default construct, initializing the reference counts to 1.
    The strong references collectively hold one weak reference. When the
    strong reference count goes to zero, the collectively held weak
    reference is released.
    */
    Constructor :: (this: *SkWeakRefCnt) -> void #cpp_method #foreign libskia "??0SkWeakRefCnt@@QEAA@XZ";

    /** Return the weak reference count. */
//     getWeakCnt :: (this: *SkWeakRefCnt) -> s32 #cpp_method #foreign libskia "?getWeakCnt@SkWeakRefCnt@@QEBAHXZ";

    /** If fRefCnt is 0, returns 0.
    *  Otherwise increments fRefCnt, acquires, and returns the old value.
    */
    atomic_conditional_acquire_strong_ref :: (this: *SkWeakRefCnt) -> s32 #cpp_method #foreign libskia "?atomic_conditional_acquire_strong_ref@SkWeakRefCnt@@AEBAHXZ";

    /** Creates a strong reference from a weak reference, if possible. The
    caller must already be an owner. If try_ref() returns true the owner
    is in posession of an additional strong reference. Both the original
    reference and new reference must be properly unreferenced. If try_ref()
    returns false, no strong reference could be created and the owner's
    reference is in the same state as before the call.
    */
    try_ref :: (this: *SkWeakRefCnt) -> bool #cpp_method #foreign libskia "?try_ref@SkWeakRefCnt@@QEBA_NXZ";

    /** Increment the weak reference count. Must be balanced by a call to
    weak_unref().
    */
    weak_ref :: (this: *SkWeakRefCnt) -> void #cpp_method #foreign libskia "?weak_ref@SkWeakRefCnt@@QEBAXXZ";

    /** Decrement the weak reference count. If the weak reference count is 1
    before the decrement, then call delete on the object. Note that if this
    is the case, then the object needs to have been allocated via new, and
    not on the stack.
    */
    weak_unref :: (this: *SkWeakRefCnt) -> void #cpp_method #foreign libskia "?weak_unref@SkWeakRefCnt@@QEBAXXZ";

    /** Returns true if there are no strong references to the object. When this
    is the case all future calls to try_ref() will return false.
    */
    weak_expired :: (this: *SkWeakRefCnt) -> bool #cpp_method #foreign libskia "?weak_expired@SkWeakRefCnt@@QEBA_NXZ";

    /* Invariant: fWeakCnt = #weak + (fRefCnt > 0 ? 1 : 0) */
    fWeakCnt:            std.atomic(s32);

    INHERITED :: SkRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Destruct, asserting that the weak reference count is 1.
    */
    virtual_Destructor :: (this: *SkWeakRefCnt, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkWeakRefCnt@@UEAA@XZ";

    /** Called when the strong reference count goes to zero. This allows the
    object to free any resources it may be holding. Weak references may
    still exist and their level of allowed access to the object is defined
    by the object's class.
    */
    virtual_weak_dispose :: (this: *SkWeakRefCnt) -> void #cpp_method #foreign libskia "?weak_dispose@SkWeakRefCnt@@MEBAXXZ";

    /** Called when the strong reference count goes to zero. Calls weak_dispose
    on the object and releases the implicit weak reference held
    collectively by the strong references.
    */
    virtual_internal_dispose :: (this: *SkWeakRefCnt) -> void #cpp_method #foreign libskia "?internal_dispose@SkWeakRefCnt@@EEBAXXZ";
}
SkWeakRefCnt_VTable :: struct #type_info_none {
    using vtable: SkRefCntBase_VTable;

    weak_dispose: #type (this: *SkWeakRefCnt) -> void #cpp_method;
}
SkWeakRefCnt_weak_dispose :: inline (this: *SkWeakRefCnt) { this.vtable.weak_dispose(this); }

get_vtable :: (obj: *SkWeakRefCnt) -> *SkWeakRefCnt_VTable { return obj.vtable; }


// SkOnce provides call-once guarantees for Skia, much like std::once_flag/std::call_once().
//
// There should be no particularly error-prone gotcha use cases when using SkOnce.
// It works correctly as a class member, a local, a global, a function-scoped static, whatever.
SkOnce :: struct {
//     Constructor :: (this: *SkOnce) -> void #cpp_method #foreign libskia "??0SkOnce@@QEAA@XZ";

    State :: enum u8 {
        NotStarted :: 0;
        Claimed    :: 1;
        Done       :: 2;
    }
    fState: std.atomic(u8) = .{cast(u8)State.NotStarted};
}

SkDescriptor :: struct {}

SkFontDescriptor :: struct {}
SkScalerContext :: struct {}

SkAdvancedTypefaceMetrics :: struct {}
SkScalerContextEffects :: struct {}
SkScalerContextRec :: struct {}

SkTypefaceID :: u32;

/** Machine endian. */
SkFontTableTag :: u32;

/** \class SkTypeface

The SkTypeface class specifies the typeface and intrinsic style of a font.
This is used in the paint, along with optionally algorithmic settings like
textSize, textSkewX, textScaleX, kFakeBoldText_Mask, to specify
how text appears when drawn (and measured).

Typeface objects are immutable, and so they can be shared between threads.
*/
SkTypeface :: struct {
    vtable:                *SkTypeface_VTable;
    using sktypeface__raw: SkTypeface__RAW;
    #place vtable; #as skweakrefcnt: SkWeakRefCnt; // Support cast to SkWeakRefCnt
}
// SkTypeface without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkTypeface
SkTypeface__RAW :: struct {
    using,except(INHERITED) skweakrefcnt__raw: SkWeakRefCnt__RAW;

    /** Returns the typeface's intrinsic style attributes. */
    fontStyle :: (this: *SkTypeface) -> SkFontStyle #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fontStyle@SkTypeface@@QEBA?AVSkFontStyle@@XZ";

    /** Returns true if style() has the kBold bit set. */
    isBold :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?isBold@SkTypeface@@QEBA_NXZ";

    /** Returns true if style() has the kItalic bit set. */
    isItalic :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?isItalic@SkTypeface@@QEBA_NXZ";

    /** Returns true if the typeface claims to be fixed-pitch.
    *  This is a style bit, advance widths may vary even if this returns true.
    */
    isFixedPitch :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?isFixedPitch@SkTypeface@@QEBA_NXZ";

    /** Copy into 'coordinates' (allocated by the caller) the design variation coordinates.
    *
    *  @param coordinates the span into which to write the design variation coordinates.
    *
    *  @return The number of axes, or -1 if there is an error.
    *  If 'coordinates.size() >= numAxes' then 'coordinates' will be
    *  filled with the variation coordinates describing the position of this typeface in design
    *  variation space. It is possible the number of axes can be retrieved but actual position
    *  cannot.
    */
    getVariationDesignPosition :: (this: *SkTypeface, coordinates: SkSpan(SkFontArguments.VariationPosition.Coordinate)) -> s32 #cpp_method #foreign libskia "?getVariationDesignPosition@SkTypeface@@QEBAHV?$SkSpan@UCoordinate@VariationPosition@SkFontArguments@@@@@Z";

    /** Copy into 'parameters' (allocated by the caller) the design variation parameters.
    *
    *  @param parameters the span into which to write the design variation parameters.
    *
    *  @return The number of axes, or -1 if there is an error.
    *  If 'parameters.size() >= numAxes' then 'parameters' will be
    *  filled with the variation parameters describing the position of this typeface in design
    *  variation space. It is possible the number of axes can be retrieved but actual parameters
    *  cannot.
    */
    getVariationDesignParameters :: (this: *SkTypeface, parameters: SkSpan(SkFontParameters.Variation.Axis)) -> s32 #cpp_method #foreign libskia "?getVariationDesignParameters@SkTypeface@@QEBAHV?$SkSpan@UAxis@Variation@SkFontParameters@@@@@Z";

    /** Return a 32bit value for this typeface, unique for the underlying font
    data. Will never return 0.
    */
    uniqueID :: (this: *SkTypeface) -> SkTypefaceID #cpp_method #foreign libskia "?uniqueID@SkTypeface@@QEBAIXZ";

    /** Returns true if the two typefaces reference the same underlying font,
    handling either being null (treating null as not equal to any font).
    */
    Equal :: (facea: *SkTypeface, faceb: *SkTypeface) -> bool #foreign libskia "?Equal@SkTypeface@@SA_NPEBV1@0@Z";

    /** Returns a non-null typeface which contains no glyphs. */
    MakeEmpty :: () -> sk_sp(SkTypeface) #cpp_return_type_is_non_pod #foreign libskia "?MakeEmpty@SkTypeface@@SA?AV?$sk_sp@VSkTypeface@@@@XZ";

    /** Return a new typeface based on this typeface but parameterized as specified in the
    SkFontArguments. If the SkFontArguments does not supply an argument for a parameter
    in the font then the value from this typeface will be used as the value for that
    argument. If the cloned typeface would be exaclty the same as this typeface then
    this typeface may be ref'ed and returned. May return nullptr on failure.
    */
    makeClone :: (this: *SkTypeface, unknown0: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeClone@SkTypeface@@QEBA?AV?$sk_sp@VSkTypeface@@@@AEBUSkFontArguments@@@Z";
    makeClone :: (this: *SkTypeface, unknown0: SkFontArguments) -> sk_sp(SkTypeface) #no_context {
        return makeClone(this, *unknown0);
    }

    /**
    *  A typeface can serialize just a descriptor (names, etc.), or it can also include the
    *  actual font data (which can be large). This enum controls how serialize() decides what
    *  to serialize.
    */
    SerializeBehavior :: enum s32 {
        DoIncludeData      :: 0;
        DontIncludeData    :: 1;
        IncludeDataIfLocal :: 2;

        kDoIncludeData      :: DoIncludeData;
        kDontIncludeData    :: DontIncludeData;
        kIncludeDataIfLocal :: IncludeDataIfLocal;
    }

    /** Write a unique signature to a stream, sufficient to reconstruct a
    typeface referencing the same font when Deserialize is called.
    */
    serialize :: (this: *SkTypeface, unknown0: *SkWStream, unknown1: SkTypeface.SerializeBehavior = .IncludeDataIfLocal) -> void #cpp_method #foreign libskia "?serialize@SkTypeface@@QEBAXPEAVSkWStream@@W4SerializeBehavior@1@@Z";

    /**
    *  Same as serialize(SkWStream*, ...) but returns the serialized data in SkData, instead of
    *  writing it to a stream.
    */
    serialize :: (this: *SkTypeface, unknown0: SkTypeface.SerializeBehavior = .IncludeDataIfLocal) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@SkTypeface@@QEBA?AV?$sk_sp@VSkData@@@@W4SerializeBehavior@1@@Z";

    /** Given the data previously written by serialize(), return a new instance
    of a typeface referring to the same font. If that font is not available,
    return nullptr.
    Goes through all registered typeface factories and lastResortMgr (if non-null).
    Does not affect ownership of SkStream.
    */
    MakeDeserialize :: (unknown0: *SkStream, lastResortMgr: sk_sp(SkFontMgr)) -> sk_sp(SkTypeface) #cpp_return_type_is_non_pod #foreign libskia "?MakeDeserialize@SkTypeface@@SA?AV?$sk_sp@VSkTypeface@@@@PEAVSkStream@@V?$sk_sp@VSkFontMgr@@@@@Z";

    /**
    *  Given an array of UTF32 character codes, return their corresponding glyph IDs.
    *
    *  @param unis span of UTF32 chars
    *  @param glyphs returns the corresponding glyph IDs for each character.
    */
    unicharsToGlyphs :: (this: *SkTypeface, unis: SkSpan(SkUnichar), glyphs: SkSpan(SkGlyphID)) -> void #cpp_method #foreign libskia "?unicharsToGlyphs@SkTypeface@@QEBAXV?$SkSpan@$$CBH@@V?$SkSpan@G@@@Z";

    textToGlyphs :: (this: *SkTypeface, text: *void, byteLength: u64, encoding: SkTextEncoding, glyphs: SkSpan(SkGlyphID)) -> u64 #cpp_method #foreign libskia "?textToGlyphs@SkTypeface@@QEBA_KPEBX_KW4SkTextEncoding@@V?$SkSpan@G@@@Z";

    /**
    *  Return the glyphID that corresponds to the specified unicode code-point
    *  (in UTF32 encoding). If the unichar is not supported, returns 0.
    *
    *  This is a short-cut for calling unicharsToGlyphs().
    */
    unicharToGlyph :: (this: *SkTypeface, unichar: SkUnichar) -> SkGlyphID #cpp_method #foreign libskia "?unicharToGlyph@SkTypeface@@QEBAGH@Z";

    /**
    *  Return the number of glyphs in the typeface.
    */
    countGlyphs :: (this: *SkTypeface) -> s32 #cpp_method #foreign libskia "?countGlyphs@SkTypeface@@QEBAHXZ";

    /** Return the number of tables in the font. */
    countTables :: (this: *SkTypeface) -> s32 #cpp_method #foreign libskia "?countTables@SkTypeface@@QEBAHXZ";

    /** Copy into tags[] (allocated by the caller) the list of table tags in
    *  the font, and return the number. This will be the same as CountTables()
    *  or 0 if an error occured. If tags is empty, this only returns the count
    *  (the same as calling countTables()).
    */
    readTableTags :: (this: *SkTypeface, tags: SkSpan(SkFontTableTag)) -> s32 #cpp_method #foreign libskia "?readTableTags@SkTypeface@@QEBAHV?$SkSpan@I@@@Z";

    /** Given a table tag, return the size of its contents, or 0 if not present
    */
    getTableSize :: (this: *SkTypeface, unknown0: SkFontTableTag) -> u64 #cpp_method #foreign libskia "?getTableSize@SkTypeface@@QEBA_KI@Z";

    /** Copy the contents of a table into data (allocated by the caller). Note
    *  that the contents of the table will be in their native endian order
    *  (which for most truetype tables is big endian). If the table tag is
    *  not found, or there is an error copying the data, then 0 is returned.
    *  If this happens, it is possible that some or all of the memory pointed
    *  to by data may have been written to, even though an error has occured.
    *
    *  @param tag  The table tag whose contents are to be copied
    *  @param offset The offset in bytes into the table's contents where the
    *  copy should start from.
    *  @param length The number of bytes, starting at offset, of table data
    *  to copy.
    *  @param data storage address where the table contents are copied to
    *  @return the number of bytes actually copied into data. If offset+length
    *  exceeds the table's size, then only the bytes up to the table's
    *  size are actually copied, and this is the value returned. If
    *  offset > the table's size, or tag is not a valid table,
    *  then 0 is returned.
    */
    getTableData :: (this: *SkTypeface, tag: SkFontTableTag, offset: u64, length: u64, data: *void) -> u64 #cpp_method #foreign libskia "?getTableData@SkTypeface@@QEBA_KI_K0PEAX@Z";

    /**
    *  Return an immutable copy of the requested font table, or nullptr if that table was
    *  not found. This can sometimes be faster than calling getTableData() twice: once to find
    *  the length, and then again to copy the data.
    *
    *  @param tag  The table tag whose contents are to be copied
    *  @return an immutable copy of the table's data, or nullptr.
    */
    copyTableData :: (this: *SkTypeface, tag: SkFontTableTag) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?copyTableData@SkTypeface@@QEBA?AV?$sk_sp@VSkData@@@@I@Z";

    /**
    *  Return the units-per-em value for this typeface, or zero if there is an
    *  error.
    */
    getUnitsPerEm :: (this: *SkTypeface) -> s32 #cpp_method #foreign libskia "?getUnitsPerEm@SkTypeface@@QEBAHXZ";

    /**
    *  Given a run of glyphs, return the associated horizontal adjustments.
    *  Adjustments are in "design units", which are integers relative to the
    *  typeface's units per em (see getUnitsPerEm).
    *
    *  Some typefaces are known to never support kerning. Calling this method
    *  with empty spans (e.g. getKerningPairAdustments({}, {})) returns
    *  a boolean indicating if the typeface might support kerning. If it
    *  returns false, then it will always return false (no kerning) for all
    *  possible glyph runs. If it returns true, then it *may* return true for
    *  some glyph runs.
    *
    *  If the method returns true, and there are 1 or more glyphs in the span, then
    *  this will return in adjustments N values,
    *  where N = min(glyphs.size() - 1, adjustments.size()).
    
    *  If the method returns false, then no kerning should be applied, and the adjustments
    *  array will be in an undefined state (possibly some values may have been
    *  written, but none of them should be interpreted as valid values).
    */
    getKerningPairAdjustments :: (this: *SkTypeface, glyphs: SkSpan(SkGlyphID), adjustments: SkSpan(s32)) -> bool #cpp_method #foreign libskia "?getKerningPairAdjustments@SkTypeface@@QEBA_NV?$SkSpan@$$CBG@@V?$SkSpan@H@@@Z";

    LocalizedString :: struct {
        fString:   SkString;
        fLanguage: SkString;
    }

    LocalizedStrings :: struct {
        vtable: *LocalizedStrings_VTable;

//         Constructor :: (this: *LocalizedStrings) -> void #cpp_method #foreign libskia "??0LocalizedStrings@SkTypeface@@QEAA@XZ";

//         unref :: (this: *LocalizedStrings) -> void #cpp_method #foreign libskia "?unref@LocalizedStrings@SkTypeface@@QEAAXXZ";

//         CopyConstructor :: (this: *LocalizedStrings, unknown0: *LocalizedStrings) -> void #cpp_method #foreign libskia "??0LocalizedStrings@SkTypeface@@AEAA@AEBV01@@Z";
        CopyConstructor :: (this: *LocalizedStrings, unknown0: LocalizedStrings) #no_context {
            CopyConstructor(this, *unknown0);
        }

        // Virtual functions:
        // Normally you should call them via the vtable.
        // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
        // or need to create a vtable yourself.

//         virtual_Destructor :: (this: *LocalizedStrings, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1LocalizedStrings@SkTypeface@@UEAA@XZ";
//         virtual_next :: (this: *LocalizedStrings, localizedString: *LocalizedString) -> bool #cpp_method #foreign libskia "?next@LocalizedStrings@SkTypeface@@UEAA_NPEAULocalizedString@2@@Z";
    }
    LocalizedStrings_VTable :: struct #type_info_none {
        Destructor: #type (this: *SkTypeface.LocalizedStrings, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;
        next:       #type (this: *SkTypeface.LocalizedStrings, localizedString: *SkTypeface.LocalizedString) -> bool #cpp_method;
    }
    LocalizedStrings_Destructor :: inline (this: *LocalizedStrings, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }
    LocalizedStrings_next :: inline (this: *LocalizedStrings, localizedString: *LocalizedString) -> bool { return this.vtable.next(this, localizedString); }

    get_vtable :: (obj: *LocalizedStrings) -> *LocalizedStrings_VTable { return obj.vtable; }


//     operator_assign :: (this: *SkTypeface.LocalizedStrings, unknown0: *SkTypeface.LocalizedStrings) -> *SkTypeface.LocalizedStrings #cpp_method #foreign libskia "??4LocalizedStrings@SkTypeface@@AEAAAEAV01@AEBV01@@Z";
    operator_assign :: (this: *SkTypeface.LocalizedStrings, unknown0: SkTypeface.LocalizedStrings) -> *SkTypeface.LocalizedStrings #no_context {
        return operator_assign(this, *unknown0);
    }

    /**
    *  Returns an iterator which will attempt to enumerate all of the
    *  family names specified by the font.
    *  It is the caller's responsibility to unref() the returned pointer.
    */
    createFamilyNameIterator :: (this: *SkTypeface) -> *SkTypeface.LocalizedStrings #cpp_method #foreign libskia "?createFamilyNameIterator@SkTypeface@@QEBAPEAVLocalizedStrings@1@XZ";

    /**
    *  Return the family name for this typeface. It will always be returned
    *  encoded as UTF8, but the language of the name is whatever the host
    *  platform chooses.
    */
    getFamilyName :: (this: *SkTypeface, name: *SkString) -> void #cpp_method #foreign libskia "?getFamilyName@SkTypeface@@QEBAXPEAVSkString@@@Z";

    /**
    *  Return the PostScript name for this typeface.
    *  Value may change based on variation parameters.
    *  Returns false if no PostScript name is available.
    */
    getPostScriptName :: (this: *SkTypeface, name: *SkString) -> bool #cpp_method #foreign libskia "?getPostScriptName@SkTypeface@@QEBA_NPEAVSkString@@@Z";

    /**
    *  If the primary resource backing this typeface has a name (like a file
    *  path or URL) representable by unicode code points, the `resourceName`
    *  will be set. The primary purpose is as a user facing indication about
    *  where the data was obtained (which font file was used).
    *
    *  Returns the number of resources backing this typeface.
    *
    *  For local font collections resource name will often be a file path. The
    *  file path may or may not exist. If it does exist, using it to create an
    *  SkTypeface may or may not create a similar SkTypeface to this one.
    */
    getResourceName :: (this: *SkTypeface, resourceName: *SkString) -> s32 #cpp_method #foreign libskia "?getResourceName@SkTypeface@@QEBAHPEAVSkString@@@Z";

    /**
    *  Return a stream for the contents of the font data, or NULL on failure.
    *  If ttcIndex is not null, it is set to the TrueTypeCollection index
    *  of this typeface within the stream, or 0 if the stream is not a
    *  collection.
    *  The caller is responsible for deleting the stream.
    */
    openStream :: (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?openStream@SkTypeface@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@PEAH@Z";

    /**
    * Return a stream for the contents of the font data.
    * Returns nullptr on failure or if the font data isn't already available in stream form.
    * Use when the stream can be used opportunistically but the calling code would prefer
    * to fall back to table access if creating the stream would be expensive.
    * Otherwise acts the same as openStream.
    */
    openExistingStream :: (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?openExistingStream@SkTypeface@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@PEAH@Z";

    /**
    *  Return a scalercontext for the given descriptor. It may return a
    *  stub scalercontext that will not crash, but will draw nothing.
    */
    createScalerContext :: (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor) -> std.unique_ptr(SkScalerContext) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?createScalerContext@SkTypeface@@QEBA?AV?$unique_ptr@VSkScalerContext@@U?$default_delete@VSkScalerContext@@@std@@@std@@AEBUSkScalerContextEffects@@PEBVSkDescriptor@@@Z";
    createScalerContext :: (this: *SkTypeface, unknown0: SkScalerContextEffects, unknown1: *SkDescriptor) -> std.unique_ptr(SkScalerContext) #no_context {
        return createScalerContext(this, *unknown0, unknown1);
    }

    /**
    *  Return a rectangle (scaled to 1-pt) that represents the union of the bounds of all
    *  of the glyphs, but each one positioned at (0,). This may be conservatively large, and
    *  will not take into account any hinting or other size-specific adjustments.
    */
    getBounds :: (this: *SkTypeface) -> SkRect #cpp_method #foreign libskia "?getBounds@SkTypeface@@QEBA?AUSkRect@@XZ";

    // PRIVATE / EXPERIMENTAL -- do not call
    filterRec :: (this: *SkTypeface, rec: *SkScalerContextRec) -> void #cpp_method #foreign libskia "?filterRec@SkTypeface@@QEBAXPEAUSkScalerContextRec@@@Z";

    // PRIVATE / EXPERIMENTAL -- do not call
    getFontDescriptor :: (this: *SkTypeface, desc: *SkFontDescriptor, isLocal: *bool) -> void #cpp_method #foreign libskia "?getFontDescriptor@SkTypeface@@QEBAXPEAVSkFontDescriptor@@PEA_N@Z";

    // PRIVATE / EXPERIMENTAL -- do not call
    internal_private_getCTFontRef :: (this: *SkTypeface) -> *void #cpp_method #foreign libskia "?internal_private_getCTFontRef@SkTypeface@@QEBAPEAXXZ";

    /* Skia reserves all tags that begin with a lower case letter and 0 */
    FactoryId :: SkFourByteTag;
    Register :: (id: SkTypeface.FactoryId, make: #type (unknown0: std.unique_ptr(SkStreamAsset), unknown1: *SkFontArguments) -> sk_sp(SkTypeface) #c_call #cpp_return_type_is_non_pod) -> void #foreign libskia "?Register@SkTypeface@@SAXIP6A?AV?$sk_sp@VSkTypeface@@@@V?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@AEBUSkFontArguments@@@Z@Z";

    // needed until onGetTableTags() is updated to take a span
    anon_enum_4 :: enum s32 {
        MAX_REASONABLE_TABLE_COUNT :: 65535;
    }

    Constructor :: (this: *SkTypeface, style: *SkFontStyle, isFixedPitch := false) -> void #cpp_method #foreign libskia "??0SkTypeface@@IEAA@AEBVSkFontStyle@@_N@Z";
    Constructor :: (this: *SkTypeface, style: SkFontStyle, isFixedPitch := false) #no_context {
        Constructor(this, *style, isFixedPitch);
    }

    /** Sets the fixedPitch bit. If used, must be called in the constructor. */
    setIsFixedPitch :: (this: *SkTypeface, isFixedPitch: bool) -> void #cpp_method #foreign libskia "?setIsFixedPitch@SkTypeface@@IEAAX_N@Z";

    /** Sets the font style. If used, must be called in the constructor. */
    setFontStyle :: (this: *SkTypeface, style: SkFontStyle) -> void #cpp_method #foreign libskia "?setFontStyle@SkTypeface@@IEAAXVSkFontStyle@@@Z";

    /** Returns true if the typeface's glyph masks may refer to the foreground
    *  paint foreground color. This is needed to determine caching requirements. Usually true for
    *  typefaces that contain a COLR table.
    */
    glyphMaskNeedsCurrentColor :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?glyphMaskNeedsCurrentColor@SkTypeface@@AEBA_NXZ";

    /** Retrieve detailed typeface metrics.  Used by the PDF backend.  */
    getAdvancedMetrics :: (this: *SkTypeface) -> std.unique_ptr(SkAdvancedTypefaceMetrics) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getAdvancedMetrics@SkTypeface@@AEBA?AV?$unique_ptr@USkAdvancedTypefaceMetrics@@U?$default_delete@USkAdvancedTypefaceMetrics@@@std@@@std@@XZ";

    fUniqueID:         SkTypefaceID #align 8;
    fStyle:            SkFontStyle;
    fBounds:           SkRect;
    fBoundsOnce:       SkOnce;
    fIsFixedPitch:     bool;

    INHERITED :: SkWeakRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkTypeface, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkTypeface@@MEAA@XZ";

//     virtual_onMakeClone :: (this: *SkTypeface, unknown0: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMakeClone@SkTypeface@@MEBA?AV?$sk_sp@VSkTypeface@@@@AEBUSkFontArguments@@@Z";

    virtual_onGetFontStyle :: (this: *SkTypeface) -> SkFontStyle #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onGetFontStyle@SkTypeface@@MEBA?AVSkFontStyle@@XZ";

    virtual_onGetFixedPitch :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?onGetFixedPitch@SkTypeface@@MEBA_NXZ";

    // Must return a valid scaler context. It can not return nullptr.
//     virtual_onCreateScalerContext :: (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor) -> std.unique_ptr(SkScalerContext) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onCreateScalerContext@SkTypeface@@MEBA?AV?$unique_ptr@VSkScalerContext@@U?$default_delete@VSkScalerContext@@@std@@@std@@AEBUSkScalerContextEffects@@PEBVSkDescriptor@@@Z";

    virtual_onCreateScalerContextAsProxyTypeface :: (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor, proxyTypeface: *SkTypeface) -> std.unique_ptr(SkScalerContext) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onCreateScalerContextAsProxyTypeface@SkTypeface@@MEBA?AV?$unique_ptr@VSkScalerContext@@U?$default_delete@VSkScalerContext@@@std@@@std@@AEBUSkScalerContextEffects@@PEBVSkDescriptor@@PEAV1@@Z";

//     virtual_onFilterRec :: (this: *SkTypeface, unknown0: *SkScalerContextRec) -> void #cpp_method #foreign libskia "?onFilterRec@SkTypeface@@MEBAXPEAUSkScalerContextRec@@@Z";

    //  Subclasses *must* override this method to work with the PDF backend.
//     virtual_onGetAdvancedMetrics :: (this: *SkTypeface) -> std.unique_ptr(SkAdvancedTypefaceMetrics) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onGetAdvancedMetrics@SkTypeface@@MEBA?AV?$unique_ptr@USkAdvancedTypefaceMetrics@@U?$default_delete@USkAdvancedTypefaceMetrics@@@std@@@std@@XZ";

    // For type1 postscript fonts only, set the glyph names for each glyph.
    // destination array is non-null, and points to an array of size this->countGlyphs().
    // Backends that do not suport type1 fonts should not override.
//     virtual_getPostScriptGlyphNames :: (this: *SkTypeface, unknown0: *SkString) -> void #cpp_method #foreign libskia "?getPostScriptGlyphNames@SkTypeface@@MEBAXPEAVSkString@@@Z";

    // The mapping from glyph to Unicode; array indices are glyph ids.
    // For each glyph, give the default Unicode value, if it exists.
    // dstArray is non-null, and points to an array of size this->countGlyphs().
    virtual_getGlyphToUnicodeMap :: (this: *SkTypeface, dstArray: SkSpan(SkUnichar)) -> void #cpp_method #foreign libskia "?getGlyphToUnicodeMap@SkTypeface@@MEBAXV?$SkSpan@H@@@Z";

//     virtual_onOpenStream :: (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onOpenStream@SkTypeface@@MEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@PEAH@Z";

    virtual_onOpenExistingStream :: (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onOpenExistingStream@SkTypeface@@MEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@PEAH@Z";

//     virtual_onGlyphMaskNeedsCurrentColor :: (this: *SkTypeface) -> bool #cpp_method #foreign libskia "?onGlyphMaskNeedsCurrentColor@SkTypeface@@MEBA_NXZ";

//     virtual_onGetVariationDesignPosition :: (this: *SkTypeface, unknown0: SkSpan(SkFontArguments.VariationPosition.Coordinate)) -> s32 #cpp_method #foreign libskia "?onGetVariationDesignPosition@SkTypeface@@MEBAHV?$SkSpan@UCoordinate@VariationPosition@SkFontArguments@@@@@Z";

//     virtual_onGetVariationDesignParameters :: (this: *SkTypeface, unknown0: SkSpan(SkFontParameters.Variation.Axis)) -> s32 #cpp_method #foreign libskia "?onGetVariationDesignParameters@SkTypeface@@MEBAHV?$SkSpan@UAxis@Variation@SkFontParameters@@@@@Z";

//     virtual_onGetFontDescriptor :: (this: *SkTypeface, unknown0: *SkFontDescriptor, isLocal: *bool) -> void #cpp_method #foreign libskia "?onGetFontDescriptor@SkTypeface@@MEBAXPEAVSkFontDescriptor@@PEA_N@Z";

//     virtual_onCharsToGlyphs :: (this: *SkTypeface, unknown0: SkSpan(SkUnichar), unknown1: SkSpan(SkGlyphID)) -> void #cpp_method #foreign libskia "?onCharsToGlyphs@SkTypeface@@MEBAXV?$SkSpan@$$CBH@@V?$SkSpan@G@@@Z";
//     virtual_onCountGlyphs :: (this: *SkTypeface) -> s32 #cpp_method #foreign libskia "?onCountGlyphs@SkTypeface@@MEBAHXZ";

//     virtual_onGetUPEM :: (this: *SkTypeface) -> s32 #cpp_method #foreign libskia "?onGetUPEM@SkTypeface@@MEBAHXZ";
    virtual_onGetKerningPairAdjustments :: (this: *SkTypeface, unknown0: SkSpan(SkGlyphID), adjustments: SkSpan(s32)) -> bool #cpp_method #foreign libskia "?onGetKerningPairAdjustments@SkTypeface@@MEBA_NV?$SkSpan@$$CBG@@V?$SkSpan@H@@@Z";

    /** Returns the family name of the typeface as known by its font manager.
    *  This name may or may not be produced by the family name iterator.
    */
//     virtual_onGetFamilyName :: (this: *SkTypeface, familyName: *SkString) -> void #cpp_method #foreign libskia "?onGetFamilyName@SkTypeface@@MEBAXPEAVSkString@@@Z";
//     virtual_onGetPostScriptName :: (this: *SkTypeface, unknown0: *SkString) -> bool #cpp_method #foreign libskia "?onGetPostScriptName@SkTypeface@@MEBA_NPEAVSkString@@@Z";
    virtual_onGetResourceName :: (this: *SkTypeface, resourceName: *SkString) -> s32 #cpp_method #foreign libskia "?onGetResourceName@SkTypeface@@MEBAHPEAVSkString@@@Z";

    /** Returns an iterator over the family names in the font. */
//     virtual_onCreateFamilyNameIterator :: (this: *SkTypeface) -> *SkTypeface.LocalizedStrings #cpp_method #foreign libskia "?onCreateFamilyNameIterator@SkTypeface@@MEBAPEAVLocalizedStrings@1@XZ";

//     virtual_onGetTableTags :: (this: *SkTypeface, unknown0: SkSpan(SkFontTableTag)) -> s32 #cpp_method #foreign libskia "?onGetTableTags@SkTypeface@@MEBAHV?$SkSpan@I@@@Z";
//     virtual_onGetTableData :: (this: *SkTypeface, unknown0: SkFontTableTag, offset: u64, length: u64, data: *void) -> u64 #cpp_method #foreign libskia "?onGetTableData@SkTypeface@@MEBA_KI_K0PEAX@Z";

    virtual_onCopyTableData :: (this: *SkTypeface, unknown0: SkFontTableTag) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onCopyTableData@SkTypeface@@MEBA?AV?$sk_sp@VSkData@@@@I@Z";

    virtual_onComputeBounds :: (this: *SkTypeface, unknown0: *SkRect) -> bool #cpp_method #foreign libskia "?onComputeBounds@SkTypeface@@MEBA_NPEAUSkRect@@@Z";

    virtual_onGetCTFontRef :: (this: *SkTypeface) -> *void #cpp_method #foreign libskia "?onGetCTFontRef@SkTypeface@@MEBAPEAXXZ";
}
SkTypeface_VTable :: struct #type_info_none {
    using,except(vtable) vtable:                               SkWeakRefCnt_VTable;

    onMakeClone:                          #type (this: *SkTypeface, unknown0: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onGetFontStyle:                       #type (this: *SkTypeface) -> SkFontStyle #cpp_method #cpp_return_type_is_non_pod;

    onGetFixedPitch:                      #type (this: *SkTypeface) -> bool #cpp_method;

    onCreateScalerContext:                #type (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor) -> std.unique_ptr(SkScalerContext) #cpp_method #cpp_return_type_is_non_pod;

    onCreateScalerContextAsProxyTypeface: #type (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor, proxyTypeface: *SkTypeface) -> std.unique_ptr(SkScalerContext) #cpp_method #cpp_return_type_is_non_pod;

    onFilterRec:                          #type (this: *SkTypeface, unknown0: *SkScalerContextRec) -> void #cpp_method;

    onGetAdvancedMetrics:                 #type (this: *SkTypeface) -> std.unique_ptr(SkAdvancedTypefaceMetrics) #cpp_method #cpp_return_type_is_non_pod;

    getPostScriptGlyphNames:              #type (this: *SkTypeface, unknown0: *SkString) -> void #cpp_method;

    getGlyphToUnicodeMap:                 #type (this: *SkTypeface, dstArray: SkSpan(SkUnichar)) -> void #cpp_method;

    onOpenStream:                         #type (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod;

    onOpenExistingStream:                 #type (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod;

    onGlyphMaskNeedsCurrentColor:         #type (this: *SkTypeface) -> bool #cpp_method;

    onGetVariationDesignPosition:         #type (this: *SkTypeface, unknown0: SkSpan(SkFontArguments.VariationPosition.Coordinate)) -> s32 #cpp_method;

    onGetVariationDesignParameters:       #type (this: *SkTypeface, unknown0: SkSpan(SkFontParameters.Variation.Axis)) -> s32 #cpp_method;

    onGetFontDescriptor:                  #type (this: *SkTypeface, unknown0: *SkFontDescriptor, isLocal: *bool) -> void #cpp_method;

    onCharsToGlyphs:                      #type (this: *SkTypeface, unknown0: SkSpan(SkUnichar), unknown1: SkSpan(SkGlyphID)) -> void #cpp_method;
    onCountGlyphs:                        #type (this: *SkTypeface) -> s32 #cpp_method;

    onGetUPEM:                            #type (this: *SkTypeface) -> s32 #cpp_method;
    onGetKerningPairAdjustments:          #type (this: *SkTypeface, unknown0: SkSpan(SkGlyphID), adjustments: SkSpan(s32)) -> bool #cpp_method;

    onGetFamilyName:                      #type (this: *SkTypeface, familyName: *SkString) -> void #cpp_method;
    onGetPostScriptName:                  #type (this: *SkTypeface, unknown0: *SkString) -> bool #cpp_method;
    onGetResourceName:                    #type (this: *SkTypeface, resourceName: *SkString) -> s32 #cpp_method;

    onCreateFamilyNameIterator:           #type (this: *SkTypeface) -> *SkTypeface.LocalizedStrings #cpp_method;

    onGetTableTags:                       #type (this: *SkTypeface, unknown0: SkSpan(SkFontTableTag)) -> s32 #cpp_method;
    onGetTableData:                       #type (this: *SkTypeface, unknown0: SkFontTableTag, offset: u64, length: u64, data: *void) -> u64 #cpp_method;

    onCopyTableData:                      #type (this: *SkTypeface, unknown0: SkFontTableTag) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod;

    onComputeBounds:                      #type (this: *SkTypeface, unknown0: *SkRect) -> bool #cpp_method;

    onGetCTFontRef:                       #type (this: *SkTypeface) -> *void #cpp_method;
}
SkTypeface_onMakeClone :: inline (this: *SkTypeface, unknown0: *SkFontArguments) -> sk_sp(SkTypeface) { return this.vtable.onMakeClone(this, unknown0); }

SkTypeface_onGetFontStyle :: inline (this: *SkTypeface) -> SkFontStyle { return this.vtable.onGetFontStyle(this); }

SkTypeface_onGetFixedPitch :: inline (this: *SkTypeface) -> bool { return this.vtable.onGetFixedPitch(this); }

SkTypeface_onCreateScalerContext :: inline (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor) -> std.unique_ptr(SkScalerContext) { return this.vtable.onCreateScalerContext(this, unknown0, unknown1); }

SkTypeface_onCreateScalerContextAsProxyTypeface :: inline (this: *SkTypeface, unknown0: *SkScalerContextEffects, unknown1: *SkDescriptor, proxyTypeface: *SkTypeface) -> std.unique_ptr(SkScalerContext) { return this.vtable.onCreateScalerContextAsProxyTypeface(this, unknown0, unknown1, proxyTypeface); }

SkTypeface_onFilterRec :: inline (this: *SkTypeface, unknown0: *SkScalerContextRec) { this.vtable.onFilterRec(this, unknown0); }

SkTypeface_onGetAdvancedMetrics :: inline (this: *SkTypeface) -> std.unique_ptr(SkAdvancedTypefaceMetrics) { return this.vtable.onGetAdvancedMetrics(this); }

SkTypeface_getPostScriptGlyphNames :: inline (this: *SkTypeface, unknown0: *SkString) { this.vtable.getPostScriptGlyphNames(this, unknown0); }

SkTypeface_getGlyphToUnicodeMap :: inline (this: *SkTypeface, dstArray: SkSpan(SkUnichar)) { this.vtable.getGlyphToUnicodeMap(this, dstArray); }

SkTypeface_onOpenStream :: inline (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) { return this.vtable.onOpenStream(this, ttcIndex); }

SkTypeface_onOpenExistingStream :: inline (this: *SkTypeface, ttcIndex: *s32) -> std.unique_ptr(SkStreamAsset) { return this.vtable.onOpenExistingStream(this, ttcIndex); }

SkTypeface_onGlyphMaskNeedsCurrentColor :: inline (this: *SkTypeface) -> bool { return this.vtable.onGlyphMaskNeedsCurrentColor(this); }

SkTypeface_onGetVariationDesignPosition :: inline (this: *SkTypeface, unknown0: SkSpan(SkFontArguments.VariationPosition.Coordinate)) -> s32 { return this.vtable.onGetVariationDesignPosition(this, unknown0); }

SkTypeface_onGetVariationDesignParameters :: inline (this: *SkTypeface, unknown0: SkSpan(SkFontParameters.Variation.Axis)) -> s32 { return this.vtable.onGetVariationDesignParameters(this, unknown0); }

SkTypeface_onGetFontDescriptor :: inline (this: *SkTypeface, unknown0: *SkFontDescriptor, isLocal: *bool) { this.vtable.onGetFontDescriptor(this, unknown0, isLocal); }

SkTypeface_onCharsToGlyphs :: inline (this: *SkTypeface, unknown0: SkSpan(SkUnichar), unknown1: SkSpan(SkGlyphID)) { this.vtable.onCharsToGlyphs(this, unknown0, unknown1); }
SkTypeface_onCountGlyphs :: inline (this: *SkTypeface) -> s32 { return this.vtable.onCountGlyphs(this); }

SkTypeface_onGetUPEM :: inline (this: *SkTypeface) -> s32 { return this.vtable.onGetUPEM(this); }
SkTypeface_onGetKerningPairAdjustments :: inline (this: *SkTypeface, unknown0: SkSpan(SkGlyphID), adjustments: SkSpan(s32)) -> bool { return this.vtable.onGetKerningPairAdjustments(this, unknown0, adjustments); }

SkTypeface_onGetFamilyName :: inline (this: *SkTypeface, familyName: *SkString) { this.vtable.onGetFamilyName(this, familyName); }
SkTypeface_onGetPostScriptName :: inline (this: *SkTypeface, unknown0: *SkString) -> bool { return this.vtable.onGetPostScriptName(this, unknown0); }
SkTypeface_onGetResourceName :: inline (this: *SkTypeface, resourceName: *SkString) -> s32 { return this.vtable.onGetResourceName(this, resourceName); }

SkTypeface_onCreateFamilyNameIterator :: inline (this: *SkTypeface) -> *SkTypeface.LocalizedStrings { return this.vtable.onCreateFamilyNameIterator(this); }

SkTypeface_onGetTableTags :: inline (this: *SkTypeface, unknown0: SkSpan(SkFontTableTag)) -> s32 { return this.vtable.onGetTableTags(this, unknown0); }
SkTypeface_onGetTableData :: inline (this: *SkTypeface, unknown0: SkFontTableTag, offset: u64, length: u64, data: *void) -> u64 { return this.vtable.onGetTableData(this, unknown0, offset, length, data); }

SkTypeface_onCopyTableData :: inline (this: *SkTypeface, unknown0: SkFontTableTag) -> sk_sp(SkData) { return this.vtable.onCopyTableData(this, unknown0); }

SkTypeface_onComputeBounds :: inline (this: *SkTypeface, unknown0: *SkRect) -> bool { return this.vtable.onComputeBounds(this, unknown0); }

SkTypeface_onGetCTFontRef :: inline (this: *SkTypeface) -> *void { return this.vtable.onGetCTFontRef(this); }

get_vtable :: (obj: *SkTypeface) -> *SkTypeface_VTable { return obj.vtable; }


skcpu :: struct {
    GlyphRunListPainter :: struct {}
}

/** \class SkFont
SkFont controls options applied when drawing and measuring text.
*/
SkFont :: struct {
    /** Whether edge pixels draw opaque or with partial transparency.
    */
    Edging :: enum s32 {
        Alias             :: 0;
        AntiAlias         :: 1;
        SubpixelAntiAlias :: 2;

        kAlias             :: Alias;
        kAntiAlias         :: AntiAlias;
        kSubpixelAntiAlias :: SubpixelAntiAlias;
    }

    /** Constructs SkFont with default values.
    
    @return  default initialized SkFont
    */
    Constructor :: (this: *SkFont) -> void #cpp_method #foreign libskia "??0SkFont@@QEAA@XZ";

    /** Constructs SkFont with default values with SkTypeface and size.
    
    @param typeface  font and style used to draw and measure text
    @param size      EM size in local coordinate units
    @return          initialized SkFont
    */
    Constructor :: (this: *SkFont, typeface: sk_sp(SkTypeface), size: SkScalar) -> void #cpp_method #foreign libskia "??0SkFont@@QEAA@V?$sk_sp@VSkTypeface@@@@M@Z";

    /** Constructs SkFont with default values with SkTypeface.
    
    @param typeface  font and style used to draw and measure text
    @return          initialized SkFont
    */
    Constructor :: (this: *SkFont, typeface: sk_sp(SkTypeface)) -> void #cpp_method #foreign libskia "??0SkFont@@QEAA@V?$sk_sp@VSkTypeface@@@@@Z";

    /** Constructs SkFont with default values with SkTypeface and size in points,
    horizontal scale, and horizontal skew. Horizontal scale emulates condensed
    and expanded fonts. Horizontal skew emulates oblique fonts.
    
    @param typeface  font and style used to draw and measure text
    @param size      EM size in local coordinate units
    @param scaleX    text horizontal scale
    @param skewX     additional shear on x-axis relative to y-axis
    @return          initialized SkFont
    */
    Constructor :: (this: *SkFont, typeface: sk_sp(SkTypeface), size: SkScalar, scaleX: SkScalar, skewX: SkScalar) -> void #cpp_method #foreign libskia "??0SkFont@@QEAA@V?$sk_sp@VSkTypeface@@@@MMM@Z";

    /** If true, instructs the font manager to always hint glyphs.
    Returned value is only meaningful if platform uses FreeType as the font manager.
    
    @return  true if all glyphs are hinted
    */
    isForceAutoHinting :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isForceAutoHinting@SkFont@@QEBA_NXZ";

    /** Returns true if font engine may return glyphs from font bitmaps instead of from outlines.
    
    @return  true if glyphs may be font bitmaps
    */
    isEmbeddedBitmaps :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isEmbeddedBitmaps@SkFont@@QEBA_NXZ";

    /** Returns true if glyphs may be drawn at sub-pixel offsets.
    
    @return  true if glyphs may be drawn at sub-pixel offsets.
    */
    isSubpixel :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isSubpixel@SkFont@@QEBA_NXZ";

    /** Returns true if font and glyph metrics are requested to be linearly scalable.
    
    @return  true if font and glyph metrics are requested to be linearly scalable.
    */
    isLinearMetrics :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isLinearMetrics@SkFont@@QEBA_NXZ";

    /** Returns true if bold is approximated by increasing the stroke width when creating glyph
    bitmaps from outlines.
    
    @return  bold is approximated through stroke width
    */
    isEmbolden :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isEmbolden@SkFont@@QEBA_NXZ";

    /** Returns true if baselines will be snapped to pixel positions when the current transformation
    matrix is axis aligned.
    
    @return  baselines may be snapped to pixels
    */
    isBaselineSnap :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?isBaselineSnap@SkFont@@QEBA_NXZ";

    /** Sets whether to always hint glyphs.
    If forceAutoHinting is set, instructs the font manager to always hint glyphs.
    
    Only affects platforms that use FreeType as the font manager.
    
    @param forceAutoHinting  setting to always hint glyphs
    */
    setForceAutoHinting :: (this: *SkFont, forceAutoHinting: bool) -> void #cpp_method #foreign libskia "?setForceAutoHinting@SkFont@@QEAAX_N@Z";

    /** Requests, but does not require, to use bitmaps in fonts instead of outlines.
    
    @param embeddedBitmaps  setting to use bitmaps in fonts
    */
    setEmbeddedBitmaps :: (this: *SkFont, embeddedBitmaps: bool) -> void #cpp_method #foreign libskia "?setEmbeddedBitmaps@SkFont@@QEAAX_N@Z";

    /** Requests, but does not require, that glyphs respect sub-pixel positioning.
    
    @param subpixel  setting for sub-pixel positioning
    */
    setSubpixel :: (this: *SkFont, subpixel: bool) -> void #cpp_method #foreign libskia "?setSubpixel@SkFont@@QEAAX_N@Z";

    /** Requests, but does not require, linearly scalable font and glyph metrics.
    
    For outline fonts 'true' means font and glyph metrics should ignore hinting and rounding.
    Note that some bitmap formats may not be able to scale linearly and will ignore this flag.
    
    @param linearMetrics  setting for linearly scalable font and glyph metrics.
    */
    setLinearMetrics :: (this: *SkFont, linearMetrics: bool) -> void #cpp_method #foreign libskia "?setLinearMetrics@SkFont@@QEAAX_N@Z";

    /** Increases stroke width when creating glyph bitmaps to approximate a bold typeface.
    
    @param embolden  setting for bold approximation
    */
    setEmbolden :: (this: *SkFont, embolden: bool) -> void #cpp_method #foreign libskia "?setEmbolden@SkFont@@QEAAX_N@Z";

    /** Requests that baselines be snapped to pixels when the current transformation matrix is axis
    aligned.
    
    @param baselineSnap  setting for baseline snapping to pixels
    */
    setBaselineSnap :: (this: *SkFont, baselineSnap: bool) -> void #cpp_method #foreign libskia "?setBaselineSnap@SkFont@@QEAAX_N@Z";

    /** Whether edge pixels draw opaque or with partial transparency.
    */
    getEdging :: (this: *SkFont) -> Edging #cpp_method #foreign libskia "?getEdging@SkFont@@QEBA?AW4Edging@1@XZ";

    /** Requests, but does not require, that edge pixels draw opaque or with
    partial transparency.
    */
    setEdging :: (this: *SkFont, edging: Edging) -> void #cpp_method #foreign libskia "?setEdging@SkFont@@QEAAXW4Edging@1@@Z";

    /** Sets level of glyph outline adjustment.
    Does not check for valid values of hintingLevel.
    */
    setHinting :: (this: *SkFont, hintingLevel: SkFontHinting) -> void #cpp_method #foreign libskia "?setHinting@SkFont@@QEAAXW4SkFontHinting@@@Z";

    /** Returns level of glyph outline adjustment.
    */
    getHinting :: (this: *SkFont) -> SkFontHinting #cpp_method #foreign libskia "?getHinting@SkFont@@QEBA?AW4SkFontHinting@@XZ";

    /** Returns a font with the same attributes of this font, but with the specified size.
    Returns nullptr if size is less than zero, infinite, or NaN.
    
    @param size  EM size in local coordinate units
    @return      initialized SkFont
    */
    makeWithSize :: (this: *SkFont, size: SkScalar) -> SkFont #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeWithSize@SkFont@@QEBA?AV1@M@Z";

    /** Does not alter SkTypeface SkRefCnt.
    
    @return  non-null SkTypeface
    */
    getTypeface :: (this: *SkFont) -> *SkTypeface #cpp_method #foreign libskia "?getTypeface@SkFont@@QEBAPEAVSkTypeface@@XZ";

    /** Return EM size in local coordinate units.
    See https://skia.org/docs/user/coordinates/#local-coordinates .
    
    @return  EM size in local coordinate units
    */
    getSize :: (this: *SkFont) -> SkScalar #cpp_method #foreign libskia "?getSize@SkFont@@QEBAMXZ";

    /** Returns text scale on x-axis.
    Default value is 1.
    
    @return  text horizontal scale
    */
    getScaleX :: (this: *SkFont) -> SkScalar #cpp_method #foreign libskia "?getScaleX@SkFont@@QEBAMXZ";

    /** Returns text skew on x-axis.
    Default value is zero.
    
    @return  additional shear on x-axis relative to y-axis
    */
    getSkewX :: (this: *SkFont) -> SkScalar #cpp_method #foreign libskia "?getSkewX@SkFont@@QEBAMXZ";

    /** Increases SkTypeface SkRefCnt by one.
    
    @return  A non-null SkTypeface.
    */
    refTypeface :: (this: *SkFont) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refTypeface@SkFont@@QEBA?AV?$sk_sp@VSkTypeface@@@@XZ";

    /** Sets SkTypeface to typeface, decreasing SkRefCnt of the previous SkTypeface.
    Pass nullptr to clear SkTypeface and use an empty typeface (which draws nothing).
    Increments tf SkRefCnt by one.
    
    @param tf  font and style used to draw text
    */
    setTypeface :: (this: *SkFont, tf: sk_sp(SkTypeface)) -> void #cpp_method #foreign libskia "?setTypeface@SkFont@@QEAAXV?$sk_sp@VSkTypeface@@@@@Z";

    /** Sets the EM size in local coordinate units.
    See https://skia.org/docs/user/coordinates/#local-coordinates .
    Has no effect if textSize is not greater than or equal to zero.
    
    @param textSize  EM size in local coordinate units
    */
    setSize :: (this: *SkFont, textSize: SkScalar) -> void #cpp_method #foreign libskia "?setSize@SkFont@@QEAAXM@Z";

    /** Sets text scale on x-axis.
    Default value is 1.
    
    @param scaleX  text horizontal scale
    */
    setScaleX :: (this: *SkFont, scaleX: SkScalar) -> void #cpp_method #foreign libskia "?setScaleX@SkFont@@QEAAXM@Z";

    /** Sets text skew on x-axis.
    Default value is zero.
    
    @param skewX  additional shear on x-axis relative to y-axis
    */
    setSkewX :: (this: *SkFont, skewX: SkScalar) -> void #cpp_method #foreign libskia "?setSkewX@SkFont@@QEAAXM@Z";

    /** Converts text into glyph indices.
    Returns the number of glyph indices represented by text.
    SkTextEncoding specifies how text represents characters or glyphs.
    glyphs may be empty, to compute the glyph count.
    
    Does not check text for valid character codes or valid glyph indices.
    
    If byteLength equals zero, returns zero.
    If byteLength includes a partial character, the partial character is ignored.
    
    If encoding is SkTextEncoding::kUTF8 and text contains an invalid UTF-8 sequence,
    zero is returned.
    
    When encoding is SkTextEncoding::kUTF8, SkTextEncoding::kUTF16, or
    SkTextEncoding::kUTF32; then each Unicode codepoint is mapped to a
    single glyph.  This function uses the default character-to-glyph
    mapping from the SkTypeface and maps characters not found in the
    SkTypeface to zero.
    
    If glyphs.size() is not sufficient to store all the glyphs, no glyphs are copied.
    The total glyph count is returned for subsequent buffer reallocation.
    
    @param text          character storage encoded with SkTextEncoding
    @param byteLength    length of character storage in bytes
    @param glyphs        storage for glyph indices; may be empty
    @return number of glyphs represented by text of length byteLength
    */
    textToGlyphs :: (this: *SkFont, text: *void, byteLength: u64, encoding: SkTextEncoding, glyphs: SkSpan(SkGlyphID)) -> u64 #cpp_method #foreign libskia "?textToGlyphs@SkFont@@QEBA_KPEBX_KW4SkTextEncoding@@V?$SkSpan@G@@@Z";

    /** Returns glyph index for Unicode character.
    
    If the character is not supported by the SkTypeface, returns 0.
    
    @param uni  Unicode character
    @return     glyph index
    */
    unicharToGlyph :: (this: *SkFont, uni: SkUnichar) -> SkGlyphID #cpp_method #foreign libskia "?unicharToGlyph@SkFont@@QEBAGH@Z";

    unicharsToGlyphs :: (this: *SkFont, src: SkSpan(SkUnichar), dst: SkSpan(SkGlyphID)) -> void #cpp_method #foreign libskia "?unicharsToGlyphs@SkFont@@QEBAXV?$SkSpan@$$CBH@@V?$SkSpan@G@@@Z";

    /** Returns number of glyphs represented by text.
    
    If encoding is SkTextEncoding::kUTF8, SkTextEncoding::kUTF16, or
    SkTextEncoding::kUTF32; then each Unicode codepoint is mapped to a
    single glyph.
    
    @param text          character storage encoded with SkTextEncoding
    @param byteLength    length of character storage in bytes
    @return              number of glyphs represented by text of length byteLength
    */
    countText :: (this: *SkFont, text: *void, byteLength: u64, encoding: SkTextEncoding) -> u64 #cpp_method #foreign libskia "?countText@SkFont@@QEBA_KPEBX_KW4SkTextEncoding@@@Z";

    /** Returns the advance width of text.
    The advance is the normal distance to move before drawing additional text.
    Returns the bounding box of text if bounds is not nullptr.
    
    @param text        character storage encoded with SkTextEncoding
    @param byteLength  length of character storage in bytes
    @param bounds      returns bounding box relative to (0, 0) if not nullptr
    @return            the sum of the default advance widths
    */
    measureText :: (this: *SkFont, text: *void, byteLength: u64, encoding: SkTextEncoding, bounds: *SkRect = null) -> SkScalar #cpp_method #foreign libskia "?measureText@SkFont@@QEBAMPEBX_KW4SkTextEncoding@@PEAUSkRect@@@Z";

    /** Returns the advance width of text.
    The advance is the normal distance to move before drawing additional text.
    Returns the bounding box of text if bounds is not nullptr. The paint
    stroke settings, mask filter, or path effect may modify the bounds.
    
    @param text        character storage encoded with SkTextEncoding
    @param byteLength  length of character storage in bytes
    @param bounds      returns bounding box relative to (0, 0) if not nullptr
    @param paint       optional; may be nullptr
    @return            the sum of the default advance widths
    */
    measureText :: (this: *SkFont, text: *void, byteLength: u64, encoding: SkTextEncoding, bounds: *SkRect, paint: *SkPaint) -> SkScalar #cpp_method #foreign libskia "?measureText@SkFont@@QEBAMPEBX_KW4SkTextEncoding@@PEAUSkRect@@PEBVSkPaint@@@Z";

    /** Retrieves the advance and bounds for each glyph in glyphs.
    widths receives min(widths.size(), glyphs.size()) values.
    bounds receives min(bounds.size(), glyphs.size()) values.
    
    @param glyphs      array of glyph indices to be measured
    @param widths      returns text advances for each glyph
    @param bounds      returns bounds for each glyph relative to (0, 0)
    @param paint       optional, specifies stroking, SkPathEffect and SkMaskFilter
    */
    getWidthsBounds :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), widths: SkSpan(SkScalar), bounds: SkSpan(SkRect), paint: *SkPaint) -> void #cpp_method #foreign libskia "?getWidthsBounds@SkFont@@QEBAXV?$SkSpan@$$CBG@@V?$SkSpan@M@@V?$SkSpan@USkRect@@@@PEBVSkPaint@@@Z";

    /** Retrieves the advance and bounds for each glyph in glyphs.
    widths receives min(widths.size(), glyphs.size()) values.
    
    @param glyphs      array of glyph indices to be measured
    @param widths      returns text advances for each glyph
    */
    getWidths :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), widths: SkSpan(SkScalar)) -> void #cpp_method #foreign libskia "?getWidths@SkFont@@QEBAXV?$SkSpan@$$CBG@@V?$SkSpan@M@@@Z";

    getWidth :: (this: *SkFont, glyph: SkGlyphID) -> SkScalar #cpp_method #foreign libskia "?getWidth@SkFont@@QEBAMG@Z";

    /** Retrieves the bounds for each glyph in glyphs.
    bounds receives min(bounds.size(), glyphs.size()) values.
    If paint is not nullptr, its stroking, SkPathEffect, and SkMaskFilter fields are respected.
    
    @param glyphs      array of glyph indices to be measured
    @param bounds      returns bounds for each glyph relative to (0, 0); may be nullptr
    @param paint       optional, specifies stroking, SkPathEffect, and SkMaskFilter
    */
    getBounds :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), bounds: SkSpan(SkRect), paint: *SkPaint) -> void #cpp_method #foreign libskia "?getBounds@SkFont@@QEBAXV?$SkSpan@$$CBG@@V?$SkSpan@USkRect@@@@PEBVSkPaint@@@Z";

    getBounds :: (this: *SkFont, glyph: SkGlyphID, paint: *SkPaint) -> SkRect #cpp_method #foreign libskia "?getBounds@SkFont@@QEBA?AUSkRect@@GPEBVSkPaint@@@Z";

    /** Retrieves the positions for each glyph, beginning at the specified origin.
    pos receives min(pos.size(), glyphs.size()) values.
    
    @param glyphs   array of glyph indices to be positioned
    @param pos      returns glyphs positions
    @param origin   location of the first glyph. Defaults to {0, 0}.
    */
    getPos :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), pos: SkSpan(SkPoint), origin: SkPoint) -> void #cpp_method #foreign libskia "?getPos@SkFont@@QEBAXV?$SkSpan@$$CBG@@V?$SkSpan@USkPoint@@@@USkPoint@@@Z";

    /** Retrieves the x-positions for each glyph, beginning at the specified origin.
    xpos receives min(xpos.size(), glyphs.size()) values.
    
    @param glyphs   array of glyph indices to be positioned
    @param xpos     returns glyphs x-positions
    @param origin   x-position of the first glyph. Defaults to 0.
    */
    getXPos :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), xpos: SkSpan(SkScalar), origin: SkScalar = 0) -> void #cpp_method #foreign libskia "?getXPos@SkFont@@QEBAXV?$SkSpan@$$CBG@@V?$SkSpan@M@@M@Z";

    /** Returns intervals [start, end] describing lines parallel to the advance that intersect
    *  with the glyphs.
    *
    *  @param glyphs   the glyphs to intersect
    *  @param pos      the position of each glyph
    *  @param top      the top of the line intersecting
    *  @param bottom   the bottom of the line intersecting
    @return         array of pairs of x values [start, end]. May be empty.
    */
    getIntercepts :: (this: *SkFont, glyphs: SkSpan(SkGlyphID), pos: SkSpan(SkPoint), top: SkScalar, bottom: SkScalar, unknown0: *SkPaint = null) -> std.vector(SkScalar) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getIntercepts@SkFont@@QEBA?AV?$vector@MV?$allocator@M@std@@@std@@V?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkPoint@@@@MMPEBVSkPaint@@@Z";

    /*
    * If the specified glyph can be represented as a path, return its path.
    * If it is not (e.g. it is represented with a bitmap) return {}.
    *
    * Note: an 'empty' glyph (e.g. what a space " " character might map to) can return
    * a path, but that path may have zero contours.
    */
    getPath :: (this: *SkFont, glyphID: SkGlyphID) -> std.optional(SkPath) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getPath@SkFont@@QEBA?AV?$optional@VSkPath@@@std@@G@Z";

//     getPath :: (this: *SkFont, glyphID: SkGlyphID, path: *SkPath) -> bool #cpp_method #foreign libskia "?getPath@SkFont@@QEBA_NGPEAVSkPath@@@Z";

    /** Returns path corresponding to glyph array.
    
    @param glyphIDs      array of glyph indices
    @param glyphPathProc function returning one glyph description as path
    @param ctx           function context
    */
    getPaths :: (this: *SkFont, glyphIDs: SkSpan(SkGlyphID), glyphPathProc: #type (pathOrNull: *SkPath, mx: *SkMatrix, ctx: *void) -> void #c_call, ctx: *void) -> void #cpp_method #foreign libskia "?getPaths@SkFont@@QEBAXV?$SkSpan@$$CBG@@P6AXPEBVSkPath@@AEBVSkMatrix@@PEAX@Z3@Z";

    /** Returns SkFontMetrics associated with SkTypeface.
    The return value is the recommended spacing between lines: the sum of metrics
    descent, ascent, and leading.
    If metrics is not nullptr, SkFontMetrics is copied to metrics.
    Results are scaled by text size but does not take into account
    dimensions required by text scale, text skew, fake bold,
    style stroke, and SkPathEffect.
    
    @param metrics  storage for SkFontMetrics; may be nullptr
    @return         recommended spacing between lines
    */
    getMetrics :: (this: *SkFont, metrics: *SkFontMetrics) -> SkScalar #cpp_method #foreign libskia "?getMetrics@SkFont@@QEBAMPEAUSkFontMetrics@@@Z";

    /** Returns the recommended spacing between lines: the sum of metrics
    descent, ascent, and leading.
    Result is scaled by text size but does not take into account
    dimensions required by stroking and SkPathEffect.
    Returns the same result as getMetrics().
    
    @return  recommended spacing between lines
    */
    getSpacing :: (this: *SkFont) -> SkScalar #cpp_method #foreign libskia "?getSpacing@SkFont@@QEBAMXZ";

    /** Dumps fields of the font to SkDebugf. May change its output over time, so clients should
    *  not rely on this for anything specific. Used to aid in debugging.
    */
    dump :: (this: *SkFont) -> void #cpp_method #foreign libskia "?dump@SkFont@@QEBAXXZ";

    sk_is_trivially_relocatable :: std.true_type;

    PrivFlags :: enum s32 {
        ForceAutoHinting_PrivFlag :: 1;
        EmbeddedBitmaps_PrivFlag  :: 2;
        Subpixel_PrivFlag         :: 4;
        LinearMetrics_PrivFlag    :: 8;
        Embolden_PrivFlag         :: 16;
        BaselineSnap_PrivFlag     :: 32;

        kForceAutoHinting_PrivFlag :: ForceAutoHinting_PrivFlag;
        kEmbeddedBitmaps_PrivFlag  :: EmbeddedBitmaps_PrivFlag;
        kSubpixel_PrivFlag         :: Subpixel_PrivFlag;
        kLinearMetrics_PrivFlag    :: LinearMetrics_PrivFlag;
        kEmbolden_PrivFlag         :: Embolden_PrivFlag;
        kBaselineSnap_PrivFlag     :: BaselineSnap_PrivFlag;
    }

    kAllFlags:                   u32 : xx PrivFlags.ForceAutoHinting_PrivFlag | xx PrivFlags.EmbeddedBitmaps_PrivFlag | xx PrivFlags.Subpixel_PrivFlag | xx PrivFlags.LinearMetrics_PrivFlag | xx PrivFlags.Embolden_PrivFlag | xx PrivFlags.BaselineSnap_PrivFlag;

    fTypeface:                   sk_sp(SkTypeface);
    fSize:                       SkScalar;
    fScaleX:                     SkScalar;
    fSkewX:                      SkScalar;
    fFlags:                      u8;
    fEdging:                     u8;
    fHinting:                    u8;

    setupForAsPaths :: (this: *SkFont, unknown0: *SkPaint) -> SkScalar #cpp_method #foreign libskia "?setupForAsPaths@SkFont@@AEAAMPEAVSkPaint@@@Z";
    hasSomeAntiAliasing :: (this: *SkFont) -> bool #cpp_method #foreign libskia "?hasSomeAntiAliasing@SkFont@@AEBA_NXZ";
}

/** Compares SkFont and font, and returns true if they are equivalent.
May return false if SkTypeface has identical contents but different pointers.

@param font  font to compare
@return      true if SkFont pair are equivalent
*/
operator_eq :: (this: *SkFont, font: *SkFont) -> bool #cpp_method #foreign libskia "??8SkFont@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkFont, font: SkFont) -> bool #no_context {
    return operator_eq(*this, *font);
}

/** Compares SkFont and font, and returns true if they are not equivalent.
May return true if SkTypeface has identical contents but different pointers.

@param font  font to compare
@return      true if SkFont pair are not equivalent
*/
operator_neq :: (this: *SkFont, font: *SkFont) -> bool #cpp_method #foreign libskia "??9SkFont@@QEBA_NAEBV0@@Z";
operator_neq :: (this: SkFont, font: SkFont) -> bool #no_context {
    return operator_neq(*this, *font);
}

/** \class SkFontMetrics
The metrics of an SkFont.
The metric values are consistent with the Skia y-down coordinate system.
*/
SkFontMetrics :: struct {
    /** \enum FontMetricsFlags
    FontMetricsFlags indicate when certain metrics are valid;
    the underline or strikeout metrics may be valid and zero.
    Fonts with embedded bitmaps may not have valid underline or strikeout metrics.
    */
    FontMetricsFlags :: enum s32 {
        UnderlineThicknessIsValid_Flag :: 1;
        UnderlinePositionIsValid_Flag  :: 2;
        StrikeoutThicknessIsValid_Flag :: 4;
        StrikeoutPositionIsValid_Flag  :: 8;
        BoundsInvalid_Flag             :: 16;

        kUnderlineThicknessIsValid_Flag :: UnderlineThicknessIsValid_Flag;
        kUnderlinePositionIsValid_Flag  :: UnderlinePositionIsValid_Flag;
        kStrikeoutThicknessIsValid_Flag :: StrikeoutThicknessIsValid_Flag;
        kStrikeoutPositionIsValid_Flag  :: StrikeoutPositionIsValid_Flag;
        kBoundsInvalid_Flag             :: BoundsInvalid_Flag;
    }

    fFlags:              u32; //!< FontMetricsFlags indicating which metrics are valid
    fTop:                SkScalar; //!< greatest extent above origin of any glyph bounding box, typically negative; deprecated with variable fonts
    fAscent:             SkScalar; //!< distance to reserve above baseline, typically negative
    fDescent:            SkScalar; //!< distance to reserve below baseline, typically positive
    fBottom:             SkScalar; //!< greatest extent below origin of any glyph bounding box, typically positive; deprecated with variable fonts
    fLeading:            SkScalar; //!< distance to add between lines, typically positive or zero
    fAvgCharWidth:       SkScalar; //!< average character width, zero if unknown
    fMaxCharWidth:       SkScalar; //!< maximum character width, zero if unknown
    fXMin:               SkScalar; //!< greatest extent to left of origin of any glyph bounding box, typically negative; deprecated with variable fonts
    fXMax:               SkScalar; //!< greatest extent to right of origin of any glyph bounding box, typically positive; deprecated with variable fonts
    fXHeight:            SkScalar; //!< height of lower-case 'x', zero if unknown, typically negative
    fCapHeight:          SkScalar; //!< height of an upper-case letter, zero if unknown, typically negative
    fUnderlineThickness: SkScalar; //!< underline thickness
    fUnderlinePosition:  SkScalar; //!< distance from baseline to top of stroke, typically positive
    fStrikeoutThickness: SkScalar; //!< strikeout thickness
    fStrikeoutPosition:  SkScalar; //!< distance from baseline to bottom of stroke, typically negative

    /** Returns true if SkFontMetrics has a valid underline thickness, and sets
    thickness to that value. If the underline thickness is not valid,
    return false, and ignore thickness.
    
    @param thickness  storage for underline width
    @return           true if font specifies underline width
    */
    hasUnderlineThickness :: (this: *SkFontMetrics, thickness: *SkScalar) -> bool #cpp_method #foreign libskia "?hasUnderlineThickness@SkFontMetrics@@QEBA_NPEAM@Z";

    /** Returns true if SkFontMetrics has a valid underline position, and sets
    position to that value. If the underline position is not valid,
    return false, and ignore position.
    
    @param position  storage for underline position
    @return          true if font specifies underline position
    */
    hasUnderlinePosition :: (this: *SkFontMetrics, position: *SkScalar) -> bool #cpp_method #foreign libskia "?hasUnderlinePosition@SkFontMetrics@@QEBA_NPEAM@Z";

    /** Returns true if SkFontMetrics has a valid strikeout thickness, and sets
    thickness to that value. If the underline thickness is not valid,
    return false, and ignore thickness.
    
    @param thickness  storage for strikeout width
    @return           true if font specifies strikeout width
    */
    hasStrikeoutThickness :: (this: *SkFontMetrics, thickness: *SkScalar) -> bool #cpp_method #foreign libskia "?hasStrikeoutThickness@SkFontMetrics@@QEBA_NPEAM@Z";

    /** Returns true if SkFontMetrics has a valid strikeout position, and sets
    position to that value. If the underline position is not valid,
    return false, and ignore position.
    
    @param position  storage for strikeout position
    @return          true if font specifies strikeout position
    */
    hasStrikeoutPosition :: (this: *SkFontMetrics, position: *SkScalar) -> bool #cpp_method #foreign libskia "?hasStrikeoutPosition@SkFontMetrics@@QEBA_NPEAM@Z";

    /** Returns true if SkFontMetrics has a valid fTop, fBottom, fXMin, and fXMax.
    If the bounds are not valid, return false.
    
    @return        true if font specifies maximum glyph bounds
    */
    hasBounds :: (this: *SkFontMetrics) -> bool #cpp_method #foreign libskia "?hasBounds@SkFontMetrics@@QEBA_NXZ";
}

operator_eq :: (this: *SkFontMetrics, that: *SkFontMetrics) -> bool #cpp_method #foreign libskia "??8SkFontMetrics@@QEBA_NAEBU0@@Z";
operator_eq :: (this: SkFontMetrics, that: SkFontMetrics) -> bool #no_context {
    return operator_eq(*this, *that);
}

SkFontStyleSet :: struct {
    vtable:                    *SkFontStyleSet_VTable;
    using skfontstyleset__raw: SkFontStyleSet__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkFontStyleSet without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFontStyleSet
SkFontStyleSet__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    CreateEmpty :: () -> sk_sp(SkFontStyleSet) #cpp_return_type_is_non_pod #foreign libskia "?CreateEmpty@SkFontStyleSet@@SA?AV?$sk_sp@VSkFontStyleSet@@@@XZ";

    matchStyleCSS3 :: (this: *SkFontStyleSet, pattern: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?matchStyleCSS3@SkFontStyleSet@@IEAA?AV?$sk_sp@VSkTypeface@@@@AEBVSkFontStyle@@@Z";
    matchStyleCSS3 :: (this: *SkFontStyleSet, pattern: SkFontStyle) -> sk_sp(SkTypeface) #no_context {
        return matchStyleCSS3(this, *pattern);
    }

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

//     virtual_count :: (this: *SkFontStyleSet) -> s32 #cpp_method #foreign libskia "?count@SkFontStyleSet@@UEAAHXZ";
//     virtual_getStyle :: (this: *SkFontStyleSet, index: s32, unknown0: *SkFontStyle, style: *SkString) -> void #cpp_method #foreign libskia "?getStyle@SkFontStyleSet@@UEAAXHPEAVSkFontStyle@@PEAVSkString@@@Z";
//     virtual_createTypeface :: (this: *SkFontStyleSet, index: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?createTypeface@SkFontStyleSet@@UEAA?AV?$sk_sp@VSkTypeface@@@@H@Z";
//     virtual_matchStyle :: (this: *SkFontStyleSet, pattern: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?matchStyle@SkFontStyleSet@@UEAA?AV?$sk_sp@VSkTypeface@@@@AEBVSkFontStyle@@@Z";
}
SkFontStyleSet_VTable :: struct #type_info_none {
    using vtable:   SkRefCntBase_VTable;

    count:          #type (this: *SkFontStyleSet) -> s32 #cpp_method;
    getStyle:       #type (this: *SkFontStyleSet, index: s32, unknown0: *SkFontStyle, style: *SkString) -> void #cpp_method;
    createTypeface: #type (this: *SkFontStyleSet, index: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;
    matchStyle:     #type (this: *SkFontStyleSet, pattern: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;
}
SkFontStyleSet_count :: inline (this: *SkFontStyleSet) -> s32 { return this.vtable.count(this); }
SkFontStyleSet_getStyle :: inline (this: *SkFontStyleSet, index: s32, unknown0: *SkFontStyle, style: *SkString) { this.vtable.getStyle(this, index, unknown0, style); }
SkFontStyleSet_createTypeface :: inline (this: *SkFontStyleSet, index: s32) -> sk_sp(SkTypeface) { return this.vtable.createTypeface(this, index); }
SkFontStyleSet_matchStyle :: inline (this: *SkFontStyleSet, pattern: *SkFontStyle) -> sk_sp(SkTypeface) { return this.vtable.matchStyle(this, pattern); }

get_vtable :: (obj: *SkFontStyleSet) -> *SkFontStyleSet_VTable { return obj.vtable; }


SkFontMgr :: struct {
    vtable:               *SkFontMgr_VTable;
    using skfontmgr__raw: SkFontMgr__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkFontMgr without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFontMgr
SkFontMgr__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    countFamilies :: (this: *SkFontMgr) -> s32 #cpp_method #foreign libskia "?countFamilies@SkFontMgr@@QEBAHXZ";
    getFamilyName :: (this: *SkFontMgr, index: s32, familyName: *SkString) -> void #cpp_method #foreign libskia "?getFamilyName@SkFontMgr@@QEBAXHPEAVSkString@@@Z";
    createStyleSet :: (this: *SkFontMgr, index: s32) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?createStyleSet@SkFontMgr@@QEBA?AV?$sk_sp@VSkFontStyleSet@@@@H@Z";

    /**
    *  The caller must call unref() on the returned object.
    *  Never returns NULL; will return an empty set if the name is not found.
    *
    *  Passing nullptr as the parameter will return the default system family.
    *  Note that most systems don't have a default system family, so passing nullptr will often
    *  result in the empty set.
    *
    *  It is possible that this will return a style set not accessible from
    *  createStyleSet(int) due to hidden or auto-activated fonts.
    */
    matchFamily :: (this: *SkFontMgr, familyName: *u8) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?matchFamily@SkFontMgr@@QEBA?AV?$sk_sp@VSkFontStyleSet@@@@QEBD@Z";

    /**
    *  Find the closest matching typeface to the specified familyName and style
    *  and return a ref to it. The caller must call unref() on the returned
    *  object. Will return nullptr if no 'good' match is found.
    *
    *  Passing |nullptr| as the parameter for |familyName| will return the
    *  default system font.
    *
    *  It is possible that this will return a style set not accessible from
    *  createStyleSet(int) or matchFamily(const char[]) due to hidden or
    *  auto-activated fonts.
    */
    matchFamilyStyle :: (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?matchFamilyStyle@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@QEBDAEBVSkFontStyle@@@Z";
    matchFamilyStyle :: (this: *SkFontMgr, familyName: *u8, unknown0: SkFontStyle) -> sk_sp(SkTypeface) #no_context {
        return matchFamilyStyle(this, familyName, *unknown0);
    }

    /**
    *  Use the system fallback to find a typeface for the given character.
    *  Note that bcp47 is a combination of ISO 639, 15924, and 3166-1 codes,
    *  so it is fine to just pass a ISO 639 here.
    *
    *  Will return NULL if no family can be found for the character
    *  in the system fallback.
    *
    *  Passing |nullptr| as the parameter for |familyName| will return the
    *  default system font.
    *
    *  bcp47[0] is the least significant fallback, bcp47[bcp47Count-1] is the
    *  most significant. If no specified bcp47 codes match, any font with the
    *  requested character will be matched.
    */
    matchFamilyStyleCharacter :: (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle, bcp47: **u8, bcp47Count: s32, character: SkUnichar) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?matchFamilyStyleCharacter@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@QEBDAEBVSkFontStyle@@QEAPEBDHH@Z";
    matchFamilyStyleCharacter :: (this: *SkFontMgr, familyName: *u8, unknown0: SkFontStyle, bcp47: **u8, bcp47Count: s32, character: SkUnichar) -> sk_sp(SkTypeface) #no_context {
        return matchFamilyStyleCharacter(this, familyName, *unknown0, bcp47, bcp47Count, character);
    }

    /**
    *  Create a typeface for the specified data and TTC index (pass 0 for none)
    *  or NULL if the data is not recognized. The caller must call unref() on
    *  the returned object if it is not null.
    */
    makeFromData :: (this: *SkFontMgr, unknown0: sk_sp(SkData), ttcIndex: s32 = 0) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeFromData@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@V?$sk_sp@VSkData@@@@H@Z";

    /**
    *  Create a typeface for the specified stream and TTC index
    *  (pass 0 for none) or NULL if the stream is not recognized. The caller
    *  must call unref() on the returned object if it is not null.
    */
    makeFromStream :: (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), ttcIndex: s32 = 0) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeFromStream@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@V?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@H@Z";

    /* Experimental, API subject to change. */
    makeFromStream :: (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), unknown1: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeFromStream@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@V?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@AEBUSkFontArguments@@@Z";
    makeFromStream :: (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), unknown1: SkFontArguments) -> sk_sp(SkTypeface) #no_context {
        return makeFromStream(this, unknown0, *unknown1);
    }

    /**
    *  Create a typeface for the specified fileName and TTC index
    *  (pass 0 for none) or NULL if the file is not found, or its contents are
    *  not recognized. The caller must call unref() on the returned object
    *  if it is not null.
    */
    makeFromFile :: (this: *SkFontMgr, path: *u8, ttcIndex: s32 = 0) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeFromFile@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@QEBDH@Z";

    legacyMakeTypeface :: (this: *SkFontMgr, familyName: *u8, style: SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?legacyMakeTypeface@SkFontMgr@@QEBA?AV?$sk_sp@VSkTypeface@@@@QEBDVSkFontStyle@@@Z";

    /* Returns an empty font manager without any typeface dependencies */
    RefEmpty :: () -> sk_sp(SkFontMgr) #cpp_return_type_is_non_pod #foreign libskia "?RefEmpty@SkFontMgr@@SA?AV?$sk_sp@VSkFontMgr@@@@XZ";

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

//     virtual_onCountFamilies :: (this: *SkFontMgr) -> s32 #cpp_method #foreign libskia "?onCountFamilies@SkFontMgr@@MEBAHXZ";
//     virtual_onGetFamilyName :: (this: *SkFontMgr, index: s32, familyName: *SkString) -> void #cpp_method #foreign libskia "?onGetFamilyName@SkFontMgr@@MEBAXHPEAVSkString@@@Z";
//     virtual_onCreateStyleSet :: (this: *SkFontMgr, index: s32) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onCreateStyleSet@SkFontMgr@@MEBA?AV?$sk_sp@VSkFontStyleSet@@@@H@Z";

    /** May return NULL if the name is not found. */
//     virtual_onMatchFamily :: (this: *SkFontMgr, familyName: *u8) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMatchFamily@SkFontMgr@@MEBA?AV?$sk_sp@VSkFontStyleSet@@@@QEBD@Z";

//     virtual_onMatchFamilyStyle :: (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMatchFamilyStyle@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@QEBDAEBVSkFontStyle@@@Z";

//     virtual_onMatchFamilyStyleCharacter :: (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle, bcp47: **u8, bcp47Count: s32, character: SkUnichar) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMatchFamilyStyleCharacter@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@QEBDAEBVSkFontStyle@@QEAPEBDHH@Z";

//     virtual_onMakeFromData :: (this: *SkFontMgr, unknown0: sk_sp(SkData), ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMakeFromData@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@V?$sk_sp@VSkData@@@@H@Z";
//     virtual_onMakeFromStreamIndex :: (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMakeFromStreamIndex@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@V?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@H@Z";

//     virtual_onMakeFromStreamArgs :: (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), unknown1: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMakeFromStreamArgs@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@V?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@AEBUSkFontArguments@@@Z";

//     virtual_onMakeFromFile :: (this: *SkFontMgr, path: *u8, ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onMakeFromFile@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@QEBDH@Z";

//     virtual_onLegacyMakeTypeface :: (this: *SkFontMgr, familyName: *u8, unknown0: SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?onLegacyMakeTypeface@SkFontMgr@@MEBA?AV?$sk_sp@VSkTypeface@@@@QEBDVSkFontStyle@@@Z";
}
SkFontMgr_VTable :: struct #type_info_none {
    using vtable:                SkRefCntBase_VTable;

    onCountFamilies:             #type (this: *SkFontMgr) -> s32 #cpp_method;
    onGetFamilyName:             #type (this: *SkFontMgr, index: s32, familyName: *SkString) -> void #cpp_method;
    onCreateStyleSet:            #type (this: *SkFontMgr, index: s32) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod;

    onMatchFamily:               #type (this: *SkFontMgr, familyName: *u8) -> sk_sp(SkFontStyleSet) #cpp_method #cpp_return_type_is_non_pod;

    onMatchFamilyStyle:          #type (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onMatchFamilyStyleCharacter: #type (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle, bcp47: **u8, bcp47Count: s32, character: SkUnichar) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onMakeFromData:              #type (this: *SkFontMgr, unknown0: sk_sp(SkData), ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;
    onMakeFromStreamIndex:       #type (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onMakeFromStreamArgs:        #type (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), unknown1: *SkFontArguments) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onMakeFromFile:              #type (this: *SkFontMgr, path: *u8, ttcIndex: s32) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;

    onLegacyMakeTypeface:        #type (this: *SkFontMgr, familyName: *u8, unknown0: SkFontStyle) -> sk_sp(SkTypeface) #cpp_method #cpp_return_type_is_non_pod;
}
SkFontMgr_onCountFamilies :: inline (this: *SkFontMgr) -> s32 { return this.vtable.onCountFamilies(this); }
SkFontMgr_onGetFamilyName :: inline (this: *SkFontMgr, index: s32, familyName: *SkString) { this.vtable.onGetFamilyName(this, index, familyName); }
SkFontMgr_onCreateStyleSet :: inline (this: *SkFontMgr, index: s32) -> sk_sp(SkFontStyleSet) { return this.vtable.onCreateStyleSet(this, index); }

SkFontMgr_onMatchFamily :: inline (this: *SkFontMgr, familyName: *u8) -> sk_sp(SkFontStyleSet) { return this.vtable.onMatchFamily(this, familyName); }

SkFontMgr_onMatchFamilyStyle :: inline (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle) -> sk_sp(SkTypeface) { return this.vtable.onMatchFamilyStyle(this, familyName, unknown0); }

SkFontMgr_onMatchFamilyStyleCharacter :: inline (this: *SkFontMgr, familyName: *u8, unknown0: *SkFontStyle, bcp47: **u8, bcp47Count: s32, character: SkUnichar) -> sk_sp(SkTypeface) { return this.vtable.onMatchFamilyStyleCharacter(this, familyName, unknown0, bcp47, bcp47Count, character); }

SkFontMgr_onMakeFromData :: inline (this: *SkFontMgr, unknown0: sk_sp(SkData), ttcIndex: s32) -> sk_sp(SkTypeface) { return this.vtable.onMakeFromData(this, unknown0, ttcIndex); }
SkFontMgr_onMakeFromStreamIndex :: inline (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), ttcIndex: s32) -> sk_sp(SkTypeface) { return this.vtable.onMakeFromStreamIndex(this, unknown0, ttcIndex); }

SkFontMgr_onMakeFromStreamArgs :: inline (this: *SkFontMgr, unknown0: std.unique_ptr(SkStreamAsset), unknown1: *SkFontArguments) -> sk_sp(SkTypeface) { return this.vtable.onMakeFromStreamArgs(this, unknown0, unknown1); }

SkFontMgr_onMakeFromFile :: inline (this: *SkFontMgr, path: *u8, ttcIndex: s32) -> sk_sp(SkTypeface) { return this.vtable.onMakeFromFile(this, path, ttcIndex); }

SkFontMgr_onLegacyMakeTypeface :: inline (this: *SkFontMgr, familyName: *u8, unknown0: SkFontStyle) -> sk_sp(SkTypeface) { return this.vtable.onLegacyMakeTypeface(this, familyName, unknown0); }

get_vtable :: (obj: *SkFontMgr) -> *SkFontMgr_VTable { return obj.vtable; }


GrDirectContext :: struct {}

SkImageGenerator :: struct {}

SkMipmap :: struct {}

SkTextureCompressionType :: enum s32 {
}

SkImages :: struct {
    /** Caller data passed to RasterReleaseProc; may be nullptr. */
    ReleaseContext :: *void;

    /** Function called when SkImage no longer shares pixels. ReleaseContext is
    provided by caller when SkImage is created, and may be nullptr.
    */
    RasterReleaseProc :: #type (pixels: *void, unknown0: ReleaseContext) -> void #c_call;

    /** Creates a CPU-backed SkImage from bitmap, sharing or copying bitmap pixels. If the bitmap
    is marked immutable, and its pixel memory is shareable, it may be shared
    instead of copied.
    
    SkImage is returned if bitmap is valid. Valid SkBitmap parameters include:
    dimensions are greater than zero;
    each dimension fits in 29 bits;
    SkColorType and SkAlphaType are valid, and SkColorType is not kUnknown_SkColorType;
    row bytes are large enough to hold one row of pixels;
    pixel address is not nullptr.
    
    @param bitmap  SkImageInfo, row bytes, and pixels
    @return        created SkImage, or nullptr
    */
    RasterFromBitmap :: (bitmap: *SkBitmap) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?RasterFromBitmap@SkImages@@YA?AV?$sk_sp@VSkImage@@@@AEBVSkBitmap@@@Z";
    RasterFromBitmap :: (bitmap: SkBitmap) -> sk_sp(SkImage) #no_context {
        return RasterFromBitmap(*bitmap);
    }

    /** Creates a CPU-backed SkImage from compressed data.
    
    This method will decompress the compressed data and create an image wrapping
    it. Any mipmap levels present in the compressed data are discarded.
    
    @param data     compressed data to store in SkImage
    @param width    width of full SkImage
    @param height   height of full SkImage
    @param type     type of compression used
    @return         created SkImage, or nullptr
    */
    RasterFromCompressedTextureData :: (data: sk_sp(SkData), width: s32, height: s32, type: SkTextureCompressionType) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?RasterFromCompressedTextureData@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@VSkData@@@@HHW4SkTextureCompressionType@@@Z";

    /**
    *  Return a SkImage using the encoded data, but attempts to defer decoding until the
    *  image is actually used/drawn. This deferral allows the system to cache the result, either on the
    *  CPU or on the GPU, depending on where the image is drawn. If memory is low, the cache may
    *  be purged, causing the next draw of the image to have to re-decode.
    *
    *  If alphaType is nullopt, the image's alpha type will be chosen automatically based on the
    *  image format. Transparent images will default to kPremul_SkAlphaType. If alphaType contains
    *  kPremul_SkAlphaType or kUnpremul_SkAlphaType, that alpha type will be used. Forcing opaque
    *  (passing kOpaque_SkAlphaType) is not allowed, and will return nullptr.
    *
    *  If the encoded format is not supported, nullptr is returned.
    *
    *  If possible, clients should use SkCodecs::DeferredImage instead.
    *
    *  @param encoded  the encoded data
    *  @return         created SkImage, or nullptr
    
    example: https://fiddle.skia.org/c/@Image_DeferredFromEncodedData
    */
    DeferredFromEncodedData :: (encoded: sk_sp(SkData), alphaType: std.optional(SkAlphaType)) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?DeferredFromEncodedData@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@$$CBVSkData@@@@V?$optional@W4SkAlphaType@@@std@@@Z";

    /** Creates SkImage from data returned by imageGenerator. The image data will not be created
    (on either the CPU or GPU) until the image is actually drawn.
    Generated data is owned by SkImage and may not be shared or accessed.
    
    SkImage is returned if generator data is valid. Valid data parameters vary by type of data
    and platform.
    
    imageGenerator may wrap SkPicture data, codec data, or custom data.
    
    @param imageGenerator  stock or custom routines to retrieve SkImage
    @return                created SkImage, or nullptr
    */
    DeferredFromGenerator :: (imageGenerator: std.unique_ptr(SkImageGenerator)) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?DeferredFromGenerator@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V?$unique_ptr@VSkImageGenerator@@U?$default_delete@VSkImageGenerator@@@std@@@std@@@Z";

    BitDepth :: enum s32 {
        U8  :: 0;
        F16 :: 1;

        kU8  :: U8;
        kF16 :: F16;
    }

    /** Creates SkImage from picture. Returned SkImage width and height are set by dimensions.
    SkImage draws picture with matrix and paint, set to bitDepth and colorSpace.
    
    The Picture data is not turned into an image (CPU or GPU) until it is drawn.
    
    If matrix is nullptr, draws with identity SkMatrix. If paint is nullptr, draws
    with default SkPaint. colorSpace may be nullptr.
    
    @param picture     stream of drawing commands
    @param dimensions  width and height
    @param matrix      SkMatrix to rotate, scale, translate, and so on; may be nullptr
    @param paint       SkPaint to apply transparency, filtering, and so on; may be nullptr
    @param bitDepth    8-bit integer or 16-bit float: per component
    @param colorSpace  range of colors; may be nullptr
    @param props       props to use when rasterizing the picture
    @return            created SkImage, or nullptr
    */
    DeferredFromPicture :: (picture: sk_sp(SkPicture), dimensions: *SkISize, matrix: *SkMatrix, paint: *SkPaint, bitDepth: BitDepth, colorSpace: sk_sp(SkColorSpace), props: SkSurfaceProps) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?DeferredFromPicture@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@VSkPicture@@@@AEBUSkISize@@PEBVSkMatrix@@PEBVSkPaint@@W4BitDepth@1@V?$sk_sp@VSkColorSpace@@@@VSkSurfaceProps@@@Z";
    DeferredFromPicture :: (picture: sk_sp(SkPicture), dimensions: SkISize, matrix: *SkMatrix, paint: *SkPaint, bitDepth: BitDepth, colorSpace: sk_sp(SkColorSpace), props: SkSurfaceProps) -> sk_sp(SkImage) #no_context {
        return DeferredFromPicture(picture, *dimensions, matrix, paint, bitDepth, colorSpace, props);
    }

    DeferredFromPicture :: (picture: sk_sp(SkPicture), dimensions: *SkISize, matrix: *SkMatrix, paint: *SkPaint, bitDepth: BitDepth, colorSpace: sk_sp(SkColorSpace)) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?DeferredFromPicture@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@VSkPicture@@@@AEBUSkISize@@PEBVSkMatrix@@PEBVSkPaint@@W4BitDepth@1@V?$sk_sp@VSkColorSpace@@@@@Z";
    DeferredFromPicture :: (picture: sk_sp(SkPicture), dimensions: SkISize, matrix: *SkMatrix, paint: *SkPaint, bitDepth: BitDepth, colorSpace: sk_sp(SkColorSpace)) -> sk_sp(SkImage) #no_context {
        return DeferredFromPicture(picture, *dimensions, matrix, paint, bitDepth, colorSpace);
    }

    /** Creates a CPU-backed SkImage from pixmap, copying the pixel data.
    As a result, pixmap pixels may be modified or deleted without affecting SkImage.
    
    SkImage is returned if SkPixmap is valid. Valid SkPixmap parameters include:
    dimensions are greater than zero;
    each dimension fits in 29 bits;
    SkColorType and SkAlphaType are valid, and SkColorType is not kUnknown_SkColorType;
    row bytes are large enough to hold one row of pixels;
    pixel address is not nullptr.
    
    @param pixmap  SkImageInfo, pixel address, and row bytes
    @return        copy of SkPixmap pixels, or nullptr
    
    example: https://fiddle.skia.org/c/@Image_RasterFromPixmapCopy
    */
    RasterFromPixmapCopy :: (pixmap: *SkPixmap) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?RasterFromPixmapCopy@SkImages@@YA?AV?$sk_sp@VSkImage@@@@AEBVSkPixmap@@@Z";
    RasterFromPixmapCopy :: (pixmap: SkPixmap) -> sk_sp(SkImage) #no_context {
        return RasterFromPixmapCopy(*pixmap);
    }

    /** Creates CPU-backed SkImage from pixmap, sharing SkPixmap pixels. Pixels must remain valid and
    unchanged until rasterReleaseProc is called. rasterReleaseProc is passed
    releaseContext when SkImage is deleted or no longer refers to pixmap pixels.
    
    Pass nullptr for rasterReleaseProc to share SkPixmap without requiring a callback
    when SkImage is released. Pass nullptr for releaseContext if rasterReleaseProc
    does not require state.
    
    SkImage is returned if pixmap is valid. Valid SkPixmap parameters include:
    dimensions are greater than zero;
    each dimension fits in 29 bits;
    SkColorType and SkAlphaType are valid, and SkColorType is not kUnknown_SkColorType;
    row bytes are large enough to hold one row of pixels;
    pixel address is not nullptr.
    
    @param pixmap             SkImageInfo, pixel address, and row bytes
    @param rasterReleaseProc  function called when pixels can be released; or nullptr
    @param releaseContext     state passed to rasterReleaseProc; or nullptr
    @return                   SkImage sharing pixmap
    */
    RasterFromPixmap :: (pixmap: *SkPixmap, rasterReleaseProc: RasterReleaseProc, releaseContext: ReleaseContext) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?RasterFromPixmap@SkImages@@YA?AV?$sk_sp@VSkImage@@@@AEBVSkPixmap@@P6AXPEBXPEAX@Z2@Z";
    RasterFromPixmap :: (pixmap: SkPixmap, rasterReleaseProc: RasterReleaseProc, releaseContext: ReleaseContext) -> sk_sp(SkImage) #no_context {
        return RasterFromPixmap(*pixmap, rasterReleaseProc, releaseContext);
    }

    /** Creates CPU-backed SkImage from pixel data described by info.
    The pixels data will *not* be copied.
    
    SkImage is returned if SkImageInfo is valid. Valid SkImageInfo parameters include:
    dimensions are greater than zero;
    each dimension fits in 29 bits;
    SkColorType and SkAlphaType are valid, and SkColorType is not kUnknown_SkColorType;
    rowBytes are large enough to hold one row of pixels;
    pixels is not nullptr, and contains enough data for SkImage.
    
    @param info      contains width, height, SkAlphaType, SkColorType, SkColorSpace
    @param pixels    address or pixel storage
    @param rowBytes  size of pixel row or larger
    @return          SkImage sharing pixels, or nullptr
    */
    RasterFromData :: (info: *SkImageInfo, pixels: sk_sp(SkData), rowBytes: u64) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?RasterFromData@SkImages@@YA?AV?$sk_sp@VSkImage@@@@AEBUSkImageInfo@@V?$sk_sp@VSkData@@@@_K@Z";
    RasterFromData :: (info: SkImageInfo, pixels: sk_sp(SkData), rowBytes: u64) -> sk_sp(SkImage) #no_context {
        return RasterFromData(*info, pixels, rowBytes);
    }

    /** Creates a filtered SkImage on the CPU. filter processes the src image, potentially changing
    the color, position, and size. subset is the bounds of src that are processed
    by filter. clipBounds is the expected bounds of the filtered SkImage. outSubset
    is required storage for the actual bounds of the filtered SkImage. offset is
    required storage for translation of returned SkImage.
    
    Returns nullptr a filtered result could not be created. If nullptr is returned, outSubset
    and offset are undefined.
    
    Useful for animation of SkImageFilter that varies size from frame to frame.
    outSubset describes the valid bounds of returned image. offset translates the returned SkImage
    to keep subsequent animation frames aligned with respect to each other.
    
    @param src         the image to be filtered
    @param filter      the image filter to be applied
    @param subset      bounds of SkImage processed by filter
    @param clipBounds  expected bounds of filtered SkImage
    @param outSubset   storage for returned SkImage bounds
    @param offset      storage for returned SkImage translation
    @return            filtered SkImage, or nullptr
    */
    MakeWithFilter :: (src: sk_sp(SkImage), filter: *SkImageFilter, subset: *SkIRect, clipBounds: *SkIRect, outSubset: *SkIRect, offset: *SkIPoint) -> sk_sp(SkImage) #cpp_return_type_is_non_pod #foreign libskia "?MakeWithFilter@SkImages@@YA?AV?$sk_sp@VSkImage@@@@V2@PEBVSkImageFilter@@AEBUSkIRect@@2PEAU4@PEAUSkIPoint@@@Z";
    MakeWithFilter :: (src: sk_sp(SkImage), filter: *SkImageFilter, subset: SkIRect, clipBounds: SkIRect, outSubset: *SkIRect, offset: *SkIPoint) -> sk_sp(SkImage) #no_context {
        return MakeWithFilter(src, filter, *subset, *clipBounds, outSubset, offset);
    }
}

/** \class SkImage
SkImage describes a two dimensional array of pixels to draw. The pixels may be
decoded in a raster bitmap, encoded in a SkPicture or compressed data stream,
or located in GPU memory as a GPU texture.

SkImage cannot be modified after it is created. SkImage may allocate additional
storage as needed; for instance, an encoded SkImage may decode when drawn.

SkImage width and height are greater than zero. Creating an SkImage with zero width
or height returns SkImage equal to nullptr.

SkImage may be created from SkBitmap, SkPixmap, SkSurface, SkPicture, encoded streams,
GPU texture, YUV_ColorSpace data, or hardware buffer. Encoded streams supported
include BMP, GIF, HEIF, ICO, JPEG, PNG, WBMP, WebP. Supported encoding details
vary with platform.

See SkImages namespace for the static factory methods to make SkImages.

Clients should *not* subclass SkImage as there is a lot of internal machinery that is
not publicly accessible.
*/
SkImage :: struct {
    vtable:             *SkImage_VTable;
    using skimage__raw: SkImage__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkImage without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkImage
SkImage__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    /** Returns a SkImageInfo describing the width, height, color type, alpha type, and color space
    of the SkImage.
    
    @return  image info of SkImage.
    */
    imageInfo :: (this: *SkImage) -> *SkImageInfo #cpp_method #foreign libskia "?imageInfo@SkImage@@QEBAAEBUSkImageInfo@@XZ";

    /** Returns pixel count in each row.
    
    @return  pixel width in SkImage
    */
    width :: (this: *SkImage) -> s32 #cpp_method #foreign libskia "?width@SkImage@@QEBAHXZ";

    /** Returns pixel row count.
    
    @return  pixel height in SkImage
    */
    height :: (this: *SkImage) -> s32 #cpp_method #foreign libskia "?height@SkImage@@QEBAHXZ";

    /** Returns SkISize { width(), height() }.
    
    @return  integral size of width() and height()
    */
    dimensions :: (this: *SkImage) -> SkISize #cpp_method #foreign libskia "?dimensions@SkImage@@QEBA?AUSkISize@@XZ";

    /** Returns SkIRect { 0, 0, width(), height() }.
    
    @return  integral rectangle from origin to width() and height()
    */
    bounds :: (this: *SkImage) -> SkIRect #cpp_method #foreign libskia "?bounds@SkImage@@QEBA?AUSkIRect@@XZ";

    /** Returns value unique to image. SkImage contents cannot change after SkImage is
    created. Any operation to create a new SkImage will receive generate a new
    unique number.
    
    @return  unique identifier
    */
    uniqueID :: (this: *SkImage) -> u32 #cpp_method #foreign libskia "?uniqueID@SkImage@@QEBAIXZ";

    /** Returns SkAlphaType.
    
    SkAlphaType returned was a parameter to an SkImage constructor,
    or was parsed from encoded data.
    
    @return  SkAlphaType in SkImage
    
    example: https://fiddle.skia.org/c/@Image_alphaType
    */
    alphaType :: (this: *SkImage) -> SkAlphaType #cpp_method #foreign libskia "?alphaType@SkImage@@QEBA?AW4SkAlphaType@@XZ";

    /** Returns SkColorType if known; otherwise, returns kUnknown_SkColorType.
    
    @return  SkColorType of SkImage
    
    example: https://fiddle.skia.org/c/@Image_colorType
    */
    colorType :: (this: *SkImage) -> SkColorType #cpp_method #foreign libskia "?colorType@SkImage@@QEBA?AW4SkColorType@@XZ";

    /** Returns SkColorSpace, the range of colors, associated with SkImage.  The
    reference count of SkColorSpace is unchanged. The returned SkColorSpace is
    immutable.
    
    SkColorSpace returned was passed to an SkImage constructor,
    or was parsed from encoded data. SkColorSpace returned may be ignored when SkImage
    is drawn, depending on the capabilities of the SkSurface receiving the drawing.
    
    @return  SkColorSpace in SkImage, or nullptr
    
    example: https://fiddle.skia.org/c/@Image_colorSpace
    */
    colorSpace :: (this: *SkImage) -> *SkColorSpace #cpp_method #foreign libskia "?colorSpace@SkImage@@QEBAPEAVSkColorSpace@@XZ";

    /** Returns a smart pointer to SkColorSpace, the range of colors, associated with
    SkImage.  The smart pointer tracks the number of objects sharing this
    SkColorSpace reference so the memory is released when the owners destruct.
    
    The returned SkColorSpace is immutable.
    
    SkColorSpace returned was passed to an SkImage constructor,
    or was parsed from encoded data. SkColorSpace returned may be ignored when SkImage
    is drawn, depending on the capabilities of the SkSurface receiving the drawing.
    
    @return  SkColorSpace in SkImage, or nullptr, wrapped in a smart pointer
    
    example: https://fiddle.skia.org/c/@Image_refColorSpace
    */
    refColorSpace :: (this: *SkImage) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refColorSpace@SkImage@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /** Returns true if SkImage pixels represent transparency only. If true, each pixel
    is packed in 8 bits as defined by kAlpha_8_SkColorType.
    
    @return  true if pixels represent a transparency mask
    
    example: https://fiddle.skia.org/c/@Image_isAlphaOnly
    */
    isAlphaOnly :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?isAlphaOnly@SkImage@@QEBA_NXZ";

    /** Returns true if pixels ignore their alpha value and are treated as fully opaque.
    
    @return  true if SkAlphaType is kOpaque_SkAlphaType
    */
    isOpaque :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?isOpaque@SkImage@@QEBA_NXZ";

    /**
    *  Make a shader with the specified tiling and mipmap sampling.
    */
    makeShader :: (this: /*const*/ *SkImage, tmx: SkTileMode, tmy: SkTileMode, unknown0: /*const reference*/ *SkSamplingOptions, localMatrix: /*const*/ *SkMatrix = null) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@W4SkTileMode@@0AEBUSkSamplingOptions@@PEBVSkMatrix@@@Z";
    makeShader :: (this: *SkImage, tmx: SkTileMode, tmy: SkTileMode, unknown0: SkSamplingOptions, localMatrix: *SkMatrix = null) -> sk_sp(SkShader) #no_context {
        return makeShader(this, tmx, tmy, *unknown0, localMatrix);
    }

    makeShader_1 :: (this: /*const*/ *SkImage, tmx: SkTileMode, tmy: SkTileMode, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const reference*/ *SkMatrix) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@W4SkTileMode@@0AEBUSkSamplingOptions@@AEBVSkMatrix@@@Z";
    makeShader_1 :: (this: *SkImage, tmx: SkTileMode, tmy: SkTileMode, sampling: SkSamplingOptions, lm: SkMatrix) -> sk_sp(SkShader) #no_context {
        return makeShader_1(this, tmx, tmy, *sampling, *lm);
    }

    /** Defaults to clamp in both X and Y. */
    makeShader :: (this: /*const*/ *SkImage, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const reference*/ *SkMatrix) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@AEBUSkSamplingOptions@@AEBVSkMatrix@@@Z";
    makeShader :: (this: *SkImage, sampling: SkSamplingOptions, lm: SkMatrix) -> sk_sp(SkShader) #no_context {
        return makeShader(this, *sampling, *lm);
    }
    makeShader_1 :: (this: /*const*/ *SkImage, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const*/ *SkMatrix = null) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@AEBUSkSamplingOptions@@PEBVSkMatrix@@@Z";
    makeShader_1 :: (this: *SkImage, sampling: SkSamplingOptions, lm: *SkMatrix = null) -> sk_sp(SkShader) #no_context {
        return makeShader_1(this, *sampling, lm);
    }

    /**
    *  makeRawShader functions like makeShader, but for images that contain non-color data.
    *  This includes images encoding things like normals, material properties (eg, roughness),
    *  heightmaps, or any other purely mathematical data that happens to be stored in an image.
    *  These types of images are useful with some programmable shaders (see: SkRuntimeEffect).
    *
    *  Raw image shaders work like regular image shaders (including filtering and tiling), with
    *  a few major differences:
    *    - No color space transformation is ever applied (the color space of the image is ignored).
    *    - Images with an alpha type of kUnpremul are *not* automatically premultiplied.
    *    - Bicubic filtering is not supported. If SkSamplingOptions::useCubic is true, these
    *      factories will return nullptr.
    */
    makeRawShader :: (this: /*const*/ *SkImage, tmx: SkTileMode, tmy: SkTileMode, unknown0: /*const reference*/ *SkSamplingOptions, localMatrix: /*const*/ *SkMatrix = null) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRawShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@W4SkTileMode@@0AEBUSkSamplingOptions@@PEBVSkMatrix@@@Z";
    makeRawShader :: (this: *SkImage, tmx: SkTileMode, tmy: SkTileMode, unknown0: SkSamplingOptions, localMatrix: *SkMatrix = null) -> sk_sp(SkShader) #no_context {
        return makeRawShader(this, tmx, tmy, *unknown0, localMatrix);
    }

    makeRawShader_1 :: (this: /*const*/ *SkImage, tmx: SkTileMode, tmy: SkTileMode, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const reference*/ *SkMatrix) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRawShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@W4SkTileMode@@0AEBUSkSamplingOptions@@AEBVSkMatrix@@@Z";
    makeRawShader_1 :: (this: *SkImage, tmx: SkTileMode, tmy: SkTileMode, sampling: SkSamplingOptions, lm: SkMatrix) -> sk_sp(SkShader) #no_context {
        return makeRawShader_1(this, tmx, tmy, *sampling, *lm);
    }

    /** Defaults to clamp in both X and Y. */
    makeRawShader :: (this: /*const*/ *SkImage, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const reference*/ *SkMatrix) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRawShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@AEBUSkSamplingOptions@@AEBVSkMatrix@@@Z";
    makeRawShader :: (this: *SkImage, sampling: SkSamplingOptions, lm: SkMatrix) -> sk_sp(SkShader) #no_context {
        return makeRawShader(this, *sampling, *lm);
    }
    makeRawShader_1 :: (this: /*const*/ *SkImage, sampling: /*const reference*/ *SkSamplingOptions, lm: /*const*/ *SkMatrix = null) -> sk_sp(SkShader) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRawShader@SkImage@@QEBA?AV?$sk_sp@VSkShader@@@@AEBUSkSamplingOptions@@PEBVSkMatrix@@@Z";
    makeRawShader_1 :: (this: *SkImage, sampling: SkSamplingOptions, lm: *SkMatrix = null) -> sk_sp(SkShader) #no_context {
        return makeRawShader_1(this, *sampling, lm);
    }

    /** Copies SkImage pixel address, row bytes, and SkImageInfo to pixmap, if address
    is available, and returns true. If pixel address is not available, return
    false and leave pixmap unchanged.
    
    @param pixmap  storage for pixel state if pixels are readable; otherwise, ignored
    @return        true if SkImage has direct access to pixels
    
    example: https://fiddle.skia.org/c/@Image_peekPixels
    */
    peekPixels :: (this: *SkImage, pixmap: *SkPixmap) -> bool #cpp_method #foreign libskia "?peekPixels@SkImage@@QEBA_NPEAVSkPixmap@@@Z";

    /** \enum SkImage::CachingHint
    CachingHint selects whether Skia may internally cache SkBitmap generated by
    decoding SkImage, or by copying SkImage from GPU to CPU. The default behavior
    allows caching SkBitmap.
    
    Choose kDisallow_CachingHint if SkImage pixels are to be used only once, or
    if SkImage pixels reside in a cache outside of Skia, or to reduce memory pressure.
    
    Choosing kAllow_CachingHint does not ensure that pixels will be cached.
    SkImage pixels may not be cached if memory requirements are too large or
    pixels are not accessible.
    */
    CachingHint :: enum s32 {
        Allow_CachingHint    :: 0;
        Disallow_CachingHint :: 1;

        kAllow_CachingHint    :: Allow_CachingHint;
        kDisallow_CachingHint :: Disallow_CachingHint;
    }

    /** Copies SkRect of pixels from SkImage to dstPixels. Copy starts at offset (srcX, srcY),
    and does not exceed SkImage (width(), height()).
    
    Graphite has deprecated this API in favor of the equivalent asynchronous API on
    skgpu::graphite::Context (with an optional explicit synchonization).
    
    dstInfo specifies width, height, SkColorType, SkAlphaType, and SkColorSpace of
    destination. dstRowBytes specifies the gap from one destination row to the next.
    Returns true if pixels are copied. Returns false if:
    - dstInfo.addr() equals nullptr
    - dstRowBytes is less than dstInfo.minRowBytes()
    - SkPixelRef is nullptr
    
    Pixels are copied only if pixel conversion is possible. If SkImage SkColorType is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dstInfo.colorType() must match.
    If SkImage SkColorType is kGray_8_SkColorType, dstInfo.colorSpace() must match.
    If SkImage SkAlphaType is kOpaque_SkAlphaType, dstInfo.alphaType() must
    match. If SkImage SkColorSpace is nullptr, dstInfo.colorSpace() must match. Returns
    false if pixel conversion is not possible.
    
    srcX and srcY may be negative to copy only top or left of source. Returns
    false if width() or height() is zero or negative.
    Returns false if abs(srcX) >= Image width(), or if abs(srcY) >= Image height().
    
    If cachingHint is kAllow_CachingHint, pixels may be retained locally.
    If cachingHint is kDisallow_CachingHint, pixels are not added to the local cache.
    
    @param context      the GrDirectContext in play, if it exists
    @param dstInfo      destination width, height, SkColorType, SkAlphaType, SkColorSpace
    @param dstPixels    destination pixel storage
    @param dstRowBytes  destination row length
    @param srcX         column index whose absolute value is less than width()
    @param srcY         row index whose absolute value is less than height()
    @param cachingHint  whether the pixels should be cached locally
    @return             true if pixels are copied to dstPixels
    */
    readPixels :: (this: *SkImage, _context: *GrDirectContext, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #cpp_method #foreign libskia "?readPixels@SkImage@@QEBA_NPEAVGrDirectContext@@AEBUSkImageInfo@@PEAX_KHHW4CachingHint@1@@Z";
    readPixels :: (this: *SkImage, _context: *GrDirectContext, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #no_context {
        return readPixels(this, _context, *dstInfo, dstPixels, dstRowBytes, srcX, srcY, cachingHint);
    }

    /** Copies a SkRect of pixels from SkImage to dst. Copy starts at (srcX, srcY), and
    does not exceed SkImage (width(), height()).
    
    Graphite has deprecated this API in favor of the equivalent asynchronous API on
    skgpu::graphite::Context (with an optional explicit synchonization).
    
    dst specifies width, height, SkColorType, SkAlphaType, SkColorSpace, pixel storage,
    and row bytes of destination. dst.rowBytes() specifics the gap from one destination
    row to the next. Returns true if pixels are copied. Returns false if:
    - dst pixel storage equals nullptr
    - dst.rowBytes is less than SkImageInfo::minRowBytes
    - SkPixelRef is nullptr
    
    Pixels are copied only if pixel conversion is possible. If SkImage SkColorType is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dst.colorType() must match.
    If SkImage SkColorType is kGray_8_SkColorType, dst.colorSpace() must match.
    If SkImage SkAlphaType is kOpaque_SkAlphaType, dst.alphaType() must
    match. If SkImage SkColorSpace is nullptr, dst.colorSpace() must match. Returns
    false if pixel conversion is not possible.
    
    srcX and srcY may be negative to copy only top or left of source. Returns
    false if width() or height() is zero or negative.
    Returns false if abs(srcX) >= Image width(), or if abs(srcY) >= Image height().
    
    If cachingHint is kAllow_CachingHint, pixels may be retained locally.
    If cachingHint is kDisallow_CachingHint, pixels are not added to the local cache.
    
    @param context      the GrDirectContext in play, if it exists
    @param dst          destination SkPixmap: SkImageInfo, pixels, row bytes
    @param srcX         column index whose absolute value is less than width()
    @param srcY         row index whose absolute value is less than height()
    @param cachingHint  whether the pixels should be cached locallyZ
    @return             true if pixels are copied to dst
    */
    readPixels :: (this: *SkImage, _context: *GrDirectContext, dst: *SkPixmap, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #cpp_method #foreign libskia "?readPixels@SkImage@@QEBA_NPEAVGrDirectContext@@AEBVSkPixmap@@HHW4CachingHint@1@@Z";
    readPixels :: (this: *SkImage, _context: *GrDirectContext, dst: SkPixmap, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #no_context {
        return readPixels(this, _context, *dst, srcX, srcY, cachingHint);
    }

    /** Deprecated. Use the variants that accept a GrDirectContext. */
    readPixels :: (this: *SkImage, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #cpp_method #foreign libskia "?readPixels@SkImage@@QEBA_NAEBUSkImageInfo@@PEAX_KHHW4CachingHint@1@@Z";
    readPixels :: (this: *SkImage, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #no_context {
        return readPixels(this, *dstInfo, dstPixels, dstRowBytes, srcX, srcY, cachingHint);
    }

    readPixels :: (this: *SkImage, dst: *SkPixmap, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #cpp_method #foreign libskia "?readPixels@SkImage@@QEBA_NAEBVSkPixmap@@HHW4CachingHint@1@@Z";
    readPixels :: (this: *SkImage, dst: SkPixmap, srcX: s32, srcY: s32, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #no_context {
        return readPixels(this, *dst, srcX, srcY, cachingHint);
    }

    /** The result from asyncRescaleAndReadPixels() or asyncRescaleAndReadPixelsYUV420(). */
    AsyncReadResult :: struct {
        vtable: *AsyncReadResult_VTable;

//         CopyConstructor :: (this: *AsyncReadResult, unknown0: *AsyncReadResult) -> void #cpp_method #foreign libskia "??0AsyncReadResult@SkImage@@QEAA@AEBV01@@Z";
        CopyConstructor :: (this: *AsyncReadResult, unknown0: AsyncReadResult) #no_context {
            CopyConstructor(this, *unknown0);
        }

//         Constructor :: (this: *AsyncReadResult) -> void #cpp_method #foreign libskia "??0AsyncReadResult@SkImage@@IEAA@XZ";

        // Virtual functions:
        // Normally you should call them via the vtable.
        // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
        // or need to create a vtable yourself.

//         virtual_Destructor :: (this: *AsyncReadResult, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1AsyncReadResult@SkImage@@UEAA@XZ";

        /** Returns how many planes of data are in the result. e.g. 3 for YUV data. */
//         virtual_count :: (this: *AsyncReadResult) -> s32 #cpp_method #foreign libskia "?count@AsyncReadResult@SkImage@@UEBAHXZ";

        /** Returns the raw pixel data for a given plane.
        *
        * It will be organized as per the dst SkImageInfo passed in to the async read call.
        *
        * Clients may wish to create an SkPixmap with this data using the dst SkImageInfo
        * and rowBytes(i).
        */
//         virtual_data :: (this: *AsyncReadResult, i: s32) -> *void #cpp_method #foreign libskia "?data@AsyncReadResult@SkImage@@UEBAPEBXH@Z";

        /** Returns how many bytes correspond to a single row of image data */
//         virtual_rowBytes :: (this: *AsyncReadResult, i: s32) -> u64 #cpp_method #foreign libskia "?rowBytes@AsyncReadResult@SkImage@@UEBA_KH@Z";
    }
    AsyncReadResult_VTable :: struct #type_info_none {
        Destructor: #type (this: *SkImage.AsyncReadResult, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

        count:      #type (this: *SkImage.AsyncReadResult) -> s32 #cpp_method;

        data:       #type (this: *SkImage.AsyncReadResult, i: s32) -> *void #cpp_method;

        rowBytes:   #type (this: *SkImage.AsyncReadResult, i: s32) -> u64 #cpp_method;
    }
    AsyncReadResult_Destructor :: inline (this: *AsyncReadResult, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

    AsyncReadResult_count :: inline (this: *AsyncReadResult) -> s32 { return this.vtable.count(this); }

    AsyncReadResult_data :: inline (this: *AsyncReadResult, i: s32) -> *void { return this.vtable.data(this, i); }

    AsyncReadResult_rowBytes :: inline (this: *AsyncReadResult, i: s32) -> u64 { return this.vtable.rowBytes(this, i); }

    get_vtable :: (obj: *AsyncReadResult) -> *AsyncReadResult_VTable { return obj.vtable; }


//     operator_assign :: (this: *SkImage.AsyncReadResult, unknown0: *SkImage.AsyncReadResult) -> *SkImage.AsyncReadResult #cpp_method #foreign libskia "??4AsyncReadResult@SkImage@@QEAAAEAV01@AEBV01@@Z";
    operator_assign :: (this: *SkImage.AsyncReadResult, unknown0: SkImage.AsyncReadResult) -> *SkImage.AsyncReadResult #no_context {
        return operator_assign(this, *unknown0);
    }

    /** Client-provided context that is passed to client-provided ReadPixelsContext. */
    ReadPixelsContext :: *void;

    /**  Client-provided callback to asyncRescaleAndReadPixels() or
    asyncRescaleAndReadPixelsYUV420() that is called when read result is ready or on failure.
    */
    ReadPixelsCallback :: #type (unknown0: ReadPixelsContext, unknown1: std.unique_ptr(AsyncReadResult)) -> void #c_call;

    RescaleGamma :: enum u8 {
        Src    :: 0;
        Linear :: 1;
        kSrc    :: Src;
        kLinear :: Linear;
    }

    RescaleMode :: enum s32 {
        Nearest        :: 0;
        Linear         :: 1;
        RepeatedLinear :: 2;
        RepeatedCubic  :: 3;

        kNearest        :: Nearest;
        kLinear         :: Linear;
        kRepeatedLinear :: RepeatedLinear;
        kRepeatedCubic  :: RepeatedCubic;
    }

    /** Makes image pixel data available to caller, possibly asynchronously. It can also rescale
    the image pixels.
    
    Currently asynchronous reads are only supported in the Ganesh GPU backend and only when the
    underlying 3D API supports transfer buffers and CPU/GPU synchronization primitives. In all
    other cases this operates synchronously.
    
    For the Graphite backend this API has been deprecated in favor of the equivalent API
    on skgpu::graphite::Context.
    
    Data is read from the source sub-rectangle, is optionally converted to a linear gamma, is
    rescaled to the size indicated by 'info', is then converted to the color space, color type,
    and alpha type of 'info'. A 'srcRect' that is not contained by the bounds of the image
    causes failure.
    
    When the pixel data is ready the caller's ReadPixelsCallback is called with a
    AsyncReadResult containing pixel data in the requested color type, alpha type, and color
    space. The AsyncReadResult will have count() == 1. Upon failure the callback is called with
    nullptr for AsyncReadResult. For a GPU image this flushes work but a submit must occur to
    guarantee a finite time before the callback is called.
    
    The data is valid for the lifetime of AsyncReadResult with the exception that if the SkImage
    is GPU-backed the data is immediately invalidated if the context is abandoned or
    destroyed.
    
    @param info            info of the requested pixels
    @param srcRect         subrectangle of image to read
    @param rescaleGamma    controls whether rescaling is done in the image's gamma or whether
    the source data is transformed to a linear gamma before rescaling.
    @param rescaleMode     controls the technique (and cost) of the rescaling
    @param callback        function to call with result of the read
    @param context         passed to callback
    */
    asyncRescaleAndReadPixels :: (this: *SkImage, info: *SkImageInfo, srcRect: *SkIRect, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixels@SkImage@@QEBAXAEBUSkImageInfo@@AEBUSkIRect@@W4RescaleGamma@1@W4RescaleMode@1@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z4@Z";
    asyncRescaleAndReadPixels :: (this: *SkImage, info: SkImageInfo, srcRect: SkIRect, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixels(this, *info, *srcRect, rescaleGamma, rescaleMode, callback, _context);
    }

    /**
    Similar to asyncRescaleAndReadPixels but performs an additional conversion to YUV. The
    RGB->YUV conversion is controlled by 'yuvColorSpace'. The YUV data is returned as three
    planes ordered y, u, v. The u and v planes are half the width and height of the resized
    rectangle. The y, u, and v values are single bytes. Currently this fails if 'dstSize'
    width and height are not even. A 'srcRect' that is not contained by the bounds of the
    image causes failure.
    
    When the pixel data is ready the caller's ReadPixelsCallback is called with a
    AsyncReadResult containing the planar data. The AsyncReadResult will have count() == 3.
    Upon failure the callback is called with nullptr for AsyncReadResult. For a GPU image this
    flushes work but a submit must occur to guarantee a finite time before the callback is
    called.
    
    The data is valid for the lifetime of AsyncReadResult with the exception that if the SkImage
    is GPU-backed the data is immediately invalidated if the context is abandoned or
    destroyed.
    
    @param yuvColorSpace  The transformation from RGB to YUV. Applied to the resized image
    after it is converted to dstColorSpace.
    @param dstColorSpace  The color space to convert the resized image to, after rescaling.
    @param srcRect        The portion of the image to rescale and convert to YUV planes.
    @param dstSize        The size to rescale srcRect to
    @param rescaleGamma   controls whether rescaling is done in the image's gamma or whether
    the source data is transformed to a linear gamma before rescaling.
    @param rescaleMode    controls the technique (and cost) of the rescaling
    @param callback       function to call with the planar read result
    @param context        passed to callback
    */
    asyncRescaleAndReadPixelsYUV420 :: (this: *SkImage, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: *SkIRect, dstSize: *SkISize, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixelsYUV420@SkImage@@QEBAXW4SkYUVColorSpace@@V?$sk_sp@VSkColorSpace@@@@AEBUSkIRect@@AEBUSkISize@@W4RescaleGamma@1@W4RescaleMode@1@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z6@Z";
    asyncRescaleAndReadPixelsYUV420 :: (this: *SkImage, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: SkIRect, dstSize: SkISize, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixelsYUV420(this, yuvColorSpace, dstColorSpace, *srcRect, *dstSize, rescaleGamma, rescaleMode, callback, _context);
    }

    /**
    * Identical to asyncRescaleAndReadPixelsYUV420 but a fourth plane is returned in the
    * AsyncReadResult passed to 'callback'. The fourth plane contains the alpha chanel at the
    * same full resolution as the Y plane.
    */
    asyncRescaleAndReadPixelsYUVA420 :: (this: *SkImage, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: *SkIRect, dstSize: *SkISize, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixelsYUVA420@SkImage@@QEBAXW4SkYUVColorSpace@@V?$sk_sp@VSkColorSpace@@@@AEBUSkIRect@@AEBUSkISize@@W4RescaleGamma@1@W4RescaleMode@1@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z6@Z";
    asyncRescaleAndReadPixelsYUVA420 :: (this: *SkImage, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: SkIRect, dstSize: SkISize, rescaleGamma: SkImage.RescaleGamma, rescaleMode: SkImage.RescaleMode, callback: SkImage.ReadPixelsCallback, _context: SkImage.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixelsYUVA420(this, yuvColorSpace, dstColorSpace, *srcRect, *dstSize, rescaleGamma, rescaleMode, callback, _context);
    }

    /** Copies SkImage to dst, scaling pixels to fit dst.width() and dst.height(), and
    converting pixels to match dst.colorType() and dst.alphaType(). Returns true if
    pixels are copied. Returns false if dst.addr() is nullptr, or dst.rowBytes() is
    less than dst SkImageInfo::minRowBytes.
    
    Pixels are copied only if pixel conversion is possible. If SkImage SkColorType is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dst.colorType() must match.
    If SkImage SkColorType is kGray_8_SkColorType, dst.colorSpace() must match.
    If SkImage SkAlphaType is kOpaque_SkAlphaType, dst.alphaType() must
    match. If SkImage SkColorSpace is nullptr, dst.colorSpace() must match. Returns
    false if pixel conversion is not possible.
    
    If cachingHint is kAllow_CachingHint, pixels may be retained locally.
    If cachingHint is kDisallow_CachingHint, pixels are not added to the local cache.
    
    @param dst            destination SkPixmap: SkImageInfo, pixels, row bytes
    @return               true if pixels are scaled to fit dst
    */
    scalePixels :: (this: *SkImage, dst: *SkPixmap, unknown0: *SkSamplingOptions, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #cpp_method #foreign libskia "?scalePixels@SkImage@@QEBA_NAEBVSkPixmap@@AEBUSkSamplingOptions@@W4CachingHint@1@@Z";
    scalePixels :: (this: *SkImage, dst: SkPixmap, unknown0: SkSamplingOptions, cachingHint: SkImage.CachingHint = .Allow_CachingHint) -> bool #no_context {
        return scalePixels(this, *dst, *unknown0, cachingHint);
    }

    /**
    * Create a new image by copying this image and scaling to fit the ImageInfo's dimensions
    * and converting the pixels into the ImageInfo's ColorInfo.
    * This is done retaining the domain (backend) of the image (e.g. gpu, raster)
    *
    * The Recorder parameter is required if the original image was created on a graphite Recorder,
    * but must be nullptr if it was create in some other way (e.g. GrContext, raster, deferred).
    *
    * return nullptr if the requested ColorInfo is not supported, its dimesions are out of range,
    *  or if the recorder is null on a graphite Image.
    */
    makeScaled :: (this: *SkImage, unknown0: *SkRecorder, unknown1: *SkImageInfo, unknown2: *SkSamplingOptions) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeScaled@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@PEAVSkRecorder@@AEBUSkImageInfo@@AEBUSkSamplingOptions@@@Z";
    makeScaled :: (this: *SkImage, unknown0: *SkRecorder, unknown1: SkImageInfo, unknown2: SkSamplingOptions) -> sk_sp(SkImage) #no_context {
        return makeScaled(this, unknown0, *unknown1, *unknown2);
    }
    makeScaled :: (this: *SkImage, unknown0: *SkRecorder, unknown1: *SkImageInfo, unknown2: *SkSamplingOptions, unknown3: *SkSurfaceProps) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeScaled@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@PEAVSkRecorder@@AEBUSkImageInfo@@AEBUSkSamplingOptions@@AEBVSkSurfaceProps@@@Z";
    makeScaled :: (this: *SkImage, unknown0: *SkRecorder, unknown1: SkImageInfo, unknown2: SkSamplingOptions, unknown3: SkSurfaceProps) -> sk_sp(SkImage) #no_context {
        return makeScaled(this, unknown0, *unknown1, *unknown2, *unknown3);
    }

    makeScaled :: (this: *SkImage, info: *SkImageInfo, sampling: *SkSamplingOptions) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeScaled@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@AEBUSkImageInfo@@AEBUSkSamplingOptions@@@Z";
    makeScaled :: (this: *SkImage, info: SkImageInfo, sampling: SkSamplingOptions) -> sk_sp(SkImage) #no_context {
        return makeScaled(this, *info, *sampling);
    }

    refEncodedData :: (this: *SkImage) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refEncodedData@SkImage@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

    RequiredProperties :: struct {
        fMipmapped  := false;
    }

//     operator_eq :: (this: *SkImage.RequiredProperties, other: *SkImage.RequiredProperties) -> bool #cpp_method #foreign libskia "??8RequiredProperties@SkImage@@QEBA_NAEBU01@@Z";
    operator_eq :: (this: SkImage.RequiredProperties, other: SkImage.RequiredProperties) -> bool #no_context {
        return operator_eq(*this, *other);
    }

//     operator_neq :: (this: *SkImage.RequiredProperties, other: *SkImage.RequiredProperties) -> bool #cpp_method #foreign libskia "??9RequiredProperties@SkImage@@QEBA_NAEBU01@@Z";
    operator_neq :: (this: SkImage.RequiredProperties, other: SkImage.RequiredProperties) -> bool #no_context {
        return operator_neq(*this, *other);
    }

//     operator_less :: (this: *SkImage.RequiredProperties, other: *SkImage.RequiredProperties) -> bool #cpp_method #foreign libskia "??MRequiredProperties@SkImage@@QEBA_NAEBU01@@Z";
    operator_less :: (this: SkImage.RequiredProperties, other: SkImage.RequiredProperties) -> bool #no_context {
        return operator_less(*this, *other);
    }

    /**
    *  Returns true if the image has mipmap levels.
    */
    hasMipmaps :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?hasMipmaps@SkImage@@QEBA_NXZ";

    /**
    *  Returns true if the image holds protected content.
    */
    isProtected :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?isProtected@SkImage@@QEBA_NXZ";

    /**
    *  Returns an image with the same "base" pixels as the this image, but with mipmap levels
    *  automatically generated and attached.
    */
    withDefaultMipmaps :: (this: *SkImage) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?withDefaultMipmaps@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@XZ";

    /** Returns raster image or lazy image. Copies SkImage backed by GPU texture into
    CPU memory if needed. Returns original SkImage if decoded in raster bitmap,
    or if encoded in a stream.
    
    Returns nullptr if backed by GPU texture and copy fails.
    
    @return  raster image, lazy image, or nullptr
    
    example: https://fiddle.skia.org/c/@Image_makeNonTextureImage
    */
    makeNonTextureImage :: (this: *SkImage, unknown0: *GrDirectContext = null) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeNonTextureImage@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@PEAVGrDirectContext@@@Z";

    /** Returns raster image. Copies SkImage backed by GPU texture into CPU memory,
    or decodes SkImage from lazy image. Returns original SkImage if decoded in
    raster bitmap.
    
    Returns nullptr if copy, decode, or pixel read fails.
    
    If cachingHint is kAllow_CachingHint, pixels may be retained locally.
    If cachingHint is kDisallow_CachingHint, pixels are not added to the local cache.
    
    @return  raster image, or nullptr
    
    example: https://fiddle.skia.org/c/@Image_makeRasterImage
    */
    makeRasterImage :: (this: *SkImage, unknown0: *GrDirectContext, cachingHint: SkImage.CachingHint = .Disallow_CachingHint) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRasterImage@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@PEAVGrDirectContext@@W4CachingHint@1@@Z";

    makeRasterImage :: (this: *SkImage, cachingHint: SkImage.CachingHint = .Disallow_CachingHint) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeRasterImage@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@W4CachingHint@1@@Z";

    /** Deprecated.
    */
    LegacyBitmapMode :: enum s32 {
        kRO_LegacyBitmapMode :: 0;
    }

    /** Deprecated.
    Creates raster SkBitmap with same pixels as SkImage. If legacyBitmapMode is
    kRO_LegacyBitmapMode, returned bitmap is read-only and immutable.
    Returns true if SkBitmap is stored in bitmap. Returns false and resets bitmap if
    SkBitmap write did not succeed.
    
    @param bitmap            storage for legacy SkBitmap
    @param legacyBitmapMode  bitmap is read-only and immutable
    @return                  true if SkBitmap was created
    */
    asLegacyBitmap :: (this: *SkImage, bitmap: *SkBitmap, legacyBitmapMode: SkImage.LegacyBitmapMode = .kRO_LegacyBitmapMode) -> bool #cpp_method #foreign libskia "?asLegacyBitmap@SkImage@@QEBA_NPEAVSkBitmap@@W4LegacyBitmapMode@1@@Z";

    /** Creates a new SkImage identical to this one, but with a different SkColorSpace.
    This does not convert the underlying pixel data, so the resulting image will draw
    differently.
    */
    reinterpretColorSpace :: (this: *SkImage, newColorSpace: sk_sp(SkColorSpace)) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?reinterpretColorSpace@SkImage@@QEBA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@VSkColorSpace@@@@@Z";

    Constructor :: (this: *SkImage, info: *SkImageInfo, uniqueID: u32) -> void #cpp_method #foreign libskia "??0SkImage@@AEAA@AEBUSkImageInfo@@I@Z";
    Constructor :: (this: *SkImage, info: SkImageInfo, uniqueID: u32) #no_context {
        Constructor(this, *info, uniqueID);
    }

    fInfo:               SkImageInfo;

    withMipmaps :: (this: *SkImage, unknown0: sk_sp(SkMipmap)) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?withMipmaps@SkImage@@AEBA?AV?$sk_sp@VSkImage@@@@V?$sk_sp@VSkMipmap@@@@@Z";

    INHERITED :: SkRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Returns true if the contents of SkImage was created on or uploaded to GPU memory,
    and is available as a GPU texture.
    
    @return  true if SkImage is a GPU texture
    
    example: https://fiddle.skia.org/c/@Image_isTextureBacked
    */
//     virtual_isTextureBacked :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?isTextureBacked@SkImage@@UEBA_NXZ";

    /** Returns an approximation of the amount of texture memory used by the image. Returns
    zero if the image is not texture backed or if the texture has an external format.
    */
//     virtual_textureSize :: (this: *SkImage) -> u64 #cpp_method #foreign libskia "?textureSize@SkImage@@UEBA_KXZ";

    /** Returns true if SkImage can be drawn on either raster surface or GPU surface.
    If recorder is nullptr, tests if SkImage draws on raster surface;
    otherwise, tests if SkImage draws on the associated GPU surface.
    
    SkImage backed by GPU texture may become invalid if associated context is
    invalid. lazy image may be invalid and may not draw to raster surface or
    GPU surface or both.
    
    @param context  GPU context
    @return         true if SkImage can be drawn
    
    example: https://fiddle.skia.org/c/@Image_isValid
    */
//     virtual_isValid :: (this: *SkImage, unknown0: *SkRecorder) -> bool #cpp_method #foreign libskia "?isValid@SkImage@@UEBA_NPEAVSkRecorder@@@Z";

    /** Returns subset of this image.
    
    Returns nullptr if any of the following are true:
    - Subset is empty
    - Subset is not contained inside the image's bounds
    - Pixels in the image could not be read or copied
    - This image is texture-backed and the provided context is null or does not match
    the source image's context.
    
    If the source image was texture-backed, the resulting image will be texture-backed also.
    Otherwise, the returned image will be raster-backed.
    
    @param recorder            the recorder of the source image (nullptr is ok if the
    source image was texture-backed).
    @param subset              bounds of returned SkImage
    @param RequiredProperties  properties the returned SkImage must possess (e.g. mipmaps)
    @return                    the subsetted image, or nullptr
    */
//     virtual_makeSubset :: (this: *SkImage, unknown0: *SkRecorder, subset: *SkIRect, unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeSubset@SkImage@@UEBA?AV?$sk_sp@VSkImage@@@@PEAVSkRecorder@@AEBUSkIRect@@URequiredProperties@1@@Z";

    /** Returns true if SkImage is backed by an image-generator or other service that creates
    and caches its pixels or texture on-demand.
    
    @return  true if SkImage is created as needed
    
    example: https://fiddle.skia.org/c/@Image_isLazyGenerated_a
    example: https://fiddle.skia.org/c/@Image_isLazyGenerated_b
    */
//     virtual_isLazyGenerated :: (this: *SkImage) -> bool #cpp_method #foreign libskia "?isLazyGenerated@SkImage@@UEBA_NXZ";

    /** Creates SkImage in target SkColorSpace.
    Returns nullptr if SkImage could not be created.
    
    Returns original SkImage if it is in target SkColorSpace.
    Otherwise, converts pixels from SkImage SkColorSpace to target SkColorSpace.
    If SkImage colorSpace() returns nullptr, SkImage SkColorSpace is assumed to be sRGB.
    
    If this image is graphite-backed, the recorder parameter is required.
    
    @param targetColorSpace    SkColorSpace describing color range of returned SkImage
    @param recorder            The Recorder in which to create the new image
    @param RequiredProperties  properties the returned SkImage must possess (e.g. mipmaps)
    @return                    created SkImage in target SkColorSpace
    */
//     virtual_makeColorSpace :: (this: *SkImage, unknown0: *SkRecorder, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorSpace@SkImage@@UEBA?AV?$sk_sp@VSkImage@@@@PEAVSkRecorder@@V?$sk_sp@VSkColorSpace@@@@URequiredProperties@1@@Z";

    /** Experimental.
    Creates SkImage in target SkColorType and SkColorSpace.
    Returns nullptr if SkImage could not be created.
    
    Returns original SkImage if it is in target SkColorType and SkColorSpace.
    
    If this image is graphite-backed, the recorder parameter is required.
    
    @param targetColorType     SkColorType of returned SkImage
    @param targetColorSpace    SkColorSpace of returned SkImage
    @param recorder            The Recorder in which to create the new image
    @param RequiredProperties  properties the returned SkImage must possess (e.g. mipmaps)
    @return                    created SkImage in target SkColorType and SkColorSpace
    */
//     virtual_makeColorTypeAndColorSpace :: (this: *SkImage, unknown0: *SkRecorder, targetColorType: SkColorType, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorTypeAndColorSpace@SkImage@@UEBA?AV?$sk_sp@VSkImage@@@@PEAVSkRecorder@@W4SkColorType@@V?$sk_sp@VSkColorSpace@@@@URequiredProperties@1@@Z";
}
SkImage_VTable :: struct #type_info_none {
    using vtable:               SkRefCntBase_VTable;

    isTextureBacked:            #type (this: *SkImage) -> bool #cpp_method;

    textureSize:                #type (this: *SkImage) -> u64 #cpp_method;

    isValid:                    #type (this: *SkImage, unknown0: *SkRecorder) -> bool #cpp_method;

    makeSubset:                 #type (this: *SkImage, unknown0: *SkRecorder, subset: *SkIRect, unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod;

    isLazyGenerated:            #type (this: *SkImage) -> bool #cpp_method;

    makeColorSpace:             #type (this: *SkImage, unknown0: *SkRecorder, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod;

    makeColorTypeAndColorSpace: #type (this: *SkImage, unknown0: *SkRecorder, targetColorType: SkColorType, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod;
}
SkImage_isTextureBacked :: inline (this: *SkImage) -> bool { return this.vtable.isTextureBacked(this); }

SkImage_textureSize :: inline (this: *SkImage) -> u64 { return this.vtable.textureSize(this); }

SkImage_isValid :: inline (this: *SkImage, unknown0: *SkRecorder) -> bool { return this.vtable.isValid(this, unknown0); }

SkImage_makeSubset :: inline (this: *SkImage, unknown0: *SkRecorder, subset: *SkIRect, unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) { return this.vtable.makeSubset(this, unknown0, subset, unknown1); }

SkImage_isLazyGenerated :: inline (this: *SkImage) -> bool { return this.vtable.isLazyGenerated(this); }

SkImage_makeColorSpace :: inline (this: *SkImage, unknown0: *SkRecorder, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) { return this.vtable.makeColorSpace(this, unknown0, targetColorSpace, unknown1); }

SkImage_makeColorTypeAndColorSpace :: inline (this: *SkImage, unknown0: *SkRecorder, targetColorType: SkColorType, targetColorSpace: sk_sp(SkColorSpace), unknown1: SkImage.RequiredProperties) -> sk_sp(SkImage) { return this.vtable.makeColorTypeAndColorSpace(this, unknown0, targetColorType, targetColorSpace, unknown1); }

get_vtable :: (obj: *SkImage) -> *SkImage_VTable { return obj.vtable; }


SkMask :: struct {}

/** \class SkPixmap
SkPixmap provides a utility to pair SkImageInfo with pixels and row bytes.
SkPixmap is a low level class which provides convenience functions to access
raster destinations. SkCanvas can not draw SkPixmap, nor does SkPixmap provide
a direct drawing destination.

Use SkBitmap to draw pixels referenced by SkPixmap; use SkSurface to draw into
pixels referenced by SkPixmap.

SkPixmap does not try to manage the lifetime of the pixel memory. Use SkPixelRef
to manage pixel memory; SkPixelRef is safe across threads.
*/
SkPixmap :: struct {
    /** Creates an empty SkPixmap without pixels, with kUnknown_SkColorType, with
    kUnknown_SkAlphaType, and with a width and height of zero. Use
    reset() to associate pixels, SkColorType, SkAlphaType, width, and height
    after SkPixmap has been created.
    
    @return  empty SkPixmap
    */
    Constructor :: (this: *SkPixmap) -> void #cpp_method #foreign libskia "??0SkPixmap@@QEAA@XZ";

    /** Creates SkPixmap from info width, height, SkAlphaType, and SkColorType.
    addr points to pixels, or nullptr. rowBytes should be info.width() times
    info.bytesPerPixel(), or larger.
    
    No parameter checking is performed; it is up to the caller to ensure that
    addr and rowBytes agree with info.
    
    The memory lifetime of pixels is managed by the caller. When SkPixmap goes
    out of scope, addr is unaffected.
    
    SkPixmap may be later modified by reset() to change its size, pixel type, or
    storage.
    
    @param info      width, height, SkAlphaType, SkColorType of SkImageInfo
    @param addr      pointer to pixels allocated by caller; may be nullptr
    @param rowBytes  size of one row of addr; width times pixel size, or larger
    @return          initialized SkPixmap
    */
    Constructor :: (this: *SkPixmap, info: *SkImageInfo, addr: *void, rowBytes: u64) -> void #cpp_method #foreign libskia "??0SkPixmap@@QEAA@AEBUSkImageInfo@@PEBX_K@Z";
    Constructor :: (this: *SkPixmap, info: SkImageInfo, addr: *void, rowBytes: u64) #no_context {
        Constructor(this, *info, addr, rowBytes);
    }

    /** Sets width, height, row bytes to zero; pixel address to nullptr; SkColorType to
    kUnknown_SkColorType; and SkAlphaType to kUnknown_SkAlphaType.
    
    The prior pixels are unaffected; it is up to the caller to release pixels
    memory if desired.
    
    example: https://fiddle.skia.org/c/@Pixmap_reset
    */
    reset :: (this: *SkPixmap) -> void #cpp_method #foreign libskia "?reset@SkPixmap@@QEAAXXZ";

    /** Sets width, height, SkAlphaType, and SkColorType from info.
    Sets pixel address from addr, which may be nullptr.
    Sets row bytes from rowBytes, which should be info.width() times
    info.bytesPerPixel(), or larger.
    
    Does not check addr. Asserts if built with SK_DEBUG defined and if rowBytes is
    too small to hold one row of pixels.
    
    The memory lifetime pixels are managed by the caller. When SkPixmap goes
    out of scope, addr is unaffected.
    
    @param info      width, height, SkAlphaType, SkColorType of SkImageInfo
    @param addr      pointer to pixels allocated by caller; may be nullptr
    @param rowBytes  size of one row of addr; width times pixel size, or larger
    
    example: https://fiddle.skia.org/c/@Pixmap_reset_2
    */
    reset :: (this: *SkPixmap, info: *SkImageInfo, addr: *void, rowBytes: u64) -> void #cpp_method #foreign libskia "?reset@SkPixmap@@QEAAXAEBUSkImageInfo@@PEBX_K@Z";
    reset :: (this: *SkPixmap, info: SkImageInfo, addr: *void, rowBytes: u64) #no_context {
        reset(this, *info, addr, rowBytes);
    }

    /** Changes SkColorSpace in SkImageInfo; preserves width, height, SkAlphaType, and
    SkColorType in SkImage, and leaves pixel address and row bytes unchanged.
    SkColorSpace reference count is incremented.
    
    @param colorSpace  SkColorSpace moved to SkImageInfo
    
    example: https://fiddle.skia.org/c/@Pixmap_setColorSpace
    */
    setColorSpace :: (this: *SkPixmap, colorSpace: sk_sp(SkColorSpace)) -> void #cpp_method #foreign libskia "?setColorSpace@SkPixmap@@QEAAXV?$sk_sp@VSkColorSpace@@@@@Z";

    /** Deprecated.
    */
    reset :: (this: *SkPixmap, mask: *SkMask) -> bool #cpp_method #foreign libskia "?reset@SkPixmap@@QEAA_NAEBUSkMask@@@Z";
    reset :: (this: *SkPixmap, mask: SkMask) -> bool #no_context {
        return reset(this, *mask);
    }

    /** Sets subset width, height, pixel address to intersection of SkPixmap with area,
    if intersection is not empty; and return true. Otherwise, leave subset unchanged
    and return false.
    
    Failing to read the return value generates a compile time warning.
    
    @param subset  storage for width, height, pixel address of intersection
    @param area    bounds to intersect with SkPixmap
    @return        true if intersection of SkPixmap and area is not empty
    */
    extractSubset :: (this: *SkPixmap, subset: *SkPixmap, area: *SkIRect) -> bool #cpp_method #foreign libskia "?extractSubset@SkPixmap@@QEBA_NPEAV1@AEBUSkIRect@@@Z";
    extractSubset :: (this: *SkPixmap, subset: *SkPixmap, area: SkIRect) -> bool #no_context {
        return extractSubset(this, subset, *area);
    }

    /** Returns width, height, SkAlphaType, SkColorType, and SkColorSpace.
    
    @return  reference to SkImageInfo
    */
    info :: (this: *SkPixmap) -> *SkImageInfo #cpp_method #foreign libskia "?info@SkPixmap@@QEBAAEBUSkImageInfo@@XZ";

    /** Returns row bytes, the interval from one pixel row to the next. Row bytes
    is at least as large as: width() * info().bytesPerPixel().
    
    Returns zero if colorType() is kUnknown_SkColorType.
    It is up to the SkBitmap creator to ensure that row bytes is a useful value.
    
    @return  byte length of pixel row
    */
    rowBytes :: (this: *SkPixmap) -> u64 #cpp_method #foreign libskia "?rowBytes@SkPixmap@@QEBA_KXZ";

    /** Returns pixel address, the base address corresponding to the pixel origin.
    
    It is up to the SkPixmap creator to ensure that pixel address is a useful value.
    
    @return  pixel address
    */
    addr :: (this: *SkPixmap) -> *void #cpp_method #foreign libskia "?addr@SkPixmap@@QEBAPEBXXZ";

    /** Returns pixel count in each pixel row. Should be equal or less than:
    rowBytes() / info().bytesPerPixel().
    
    @return  pixel width in SkImageInfo
    */
    width :: (this: *SkPixmap) -> s32 #cpp_method #foreign libskia "?width@SkPixmap@@QEBAHXZ";

    /** Returns pixel row count.
    
    @return  pixel height in SkImageInfo
    */
    height :: (this: *SkPixmap) -> s32 #cpp_method #foreign libskia "?height@SkPixmap@@QEBAHXZ";

    /**
    *  Return the dimensions of the pixmap (from its ImageInfo)
    */
    dimensions :: (this: *SkPixmap) -> SkISize #cpp_method #foreign libskia "?dimensions@SkPixmap@@QEBA?AUSkISize@@XZ";

    colorType :: (this: *SkPixmap) -> SkColorType #cpp_method #foreign libskia "?colorType@SkPixmap@@QEBA?AW4SkColorType@@XZ";

    alphaType :: (this: *SkPixmap) -> SkAlphaType #cpp_method #foreign libskia "?alphaType@SkPixmap@@QEBA?AW4SkAlphaType@@XZ";

    /** Returns SkColorSpace, the range of colors, associated with SkImageInfo. The
    reference count of SkColorSpace is unchanged. The returned SkColorSpace is
    immutable.
    
    @return  SkColorSpace in SkImageInfo, or nullptr
    */
    colorSpace :: (this: *SkPixmap) -> *SkColorSpace #cpp_method #foreign libskia "?colorSpace@SkPixmap@@QEBAPEAVSkColorSpace@@XZ";

    /** Returns smart pointer to SkColorSpace, the range of colors, associated with
    SkImageInfo. The smart pointer tracks the number of objects sharing this
    SkColorSpace reference so the memory is released when the owners destruct.
    
    The returned SkColorSpace is immutable.
    
    @return  SkColorSpace in SkImageInfo wrapped in a smart pointer
    */
    refColorSpace :: (this: *SkPixmap) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?refColorSpace@SkPixmap@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /** Returns true if SkAlphaType is kOpaque_SkAlphaType.
    Does not check if SkColorType allows alpha, or if any pixel value has
    transparency.
    
    @return  true if SkImageInfo has opaque SkAlphaType
    */
    isOpaque :: (this: *SkPixmap) -> bool #cpp_method #foreign libskia "?isOpaque@SkPixmap@@QEBA_NXZ";

    /** Returns SkIRect { 0, 0, width(), height() }.
    
    @return  integral rectangle from origin to width() and height()
    */
    bounds :: (this: *SkPixmap) -> SkIRect #cpp_method #foreign libskia "?bounds@SkPixmap@@QEBA?AUSkIRect@@XZ";

    /** Returns number of pixels that fit on row. Should be greater than or equal to
    width().
    
    @return  maximum pixels per row
    */
    rowBytesAsPixels :: (this: *SkPixmap) -> s32 #cpp_method #foreign libskia "?rowBytesAsPixels@SkPixmap@@QEBAHXZ";

    /** Returns bit shift converting row bytes to row pixels.
    Returns zero for kUnknown_SkColorType.
    
    @return  one of: 0, 1, 2, 3; left shift to convert pixels to bytes
    */
    shiftPerPixel :: (this: *SkPixmap) -> s32 #cpp_method #foreign libskia "?shiftPerPixel@SkPixmap@@QEBAHXZ";

    /** Returns minimum memory required for pixel storage.
    Does not include unused memory on last row when rowBytesAsPixels() exceeds width().
    Returns SIZE_MAX if result does not fit in size_t.
    Returns zero if height() or width() is 0.
    Returns height() times rowBytes() if colorType() is kUnknown_SkColorType.
    
    @return  size in bytes of image buffer
    */
    computeByteSize :: (this: *SkPixmap) -> u64 #cpp_method #foreign libskia "?computeByteSize@SkPixmap@@QEBA_KXZ";

    /** Returns true if all pixels are opaque. SkColorType determines how pixels
    are encoded, and whether pixel describes alpha. Returns true for SkColorType
    without alpha in each pixel; for other SkColorType, returns true if all
    pixels have alpha values equivalent to 1.0 or greater.
    
    For SkColorType kRGB_565_SkColorType or kGray_8_SkColorType: always
    returns true. For SkColorType kAlpha_8_SkColorType, kBGRA_8888_SkColorType,
    kRGBA_8888_SkColorType: returns true if all pixel alpha values are 255.
    For SkColorType kARGB_4444_SkColorType: returns true if all pixel alpha values are 15.
    For kRGBA_F16_SkColorType: returns true if all pixel alpha values are 1.0 or
    greater.
    
    Returns false for kUnknown_SkColorType.
    
    @return  true if all pixels have opaque values or SkColorType is opaque
    
    example: https://fiddle.skia.org/c/@Pixmap_computeIsOpaque
    */
    computeIsOpaque :: (this: *SkPixmap) -> bool #cpp_method #foreign libskia "?computeIsOpaque@SkPixmap@@QEBA_NXZ";

    /** Returns pixel at (x, y) as unpremultiplied color.
    Returns black with alpha if SkColorType is kAlpha_8_SkColorType.
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined; and returns undefined values or may crash if
    SK_RELEASE is defined. Fails if SkColorType is kUnknown_SkColorType or
    pixel address is nullptr.
    
    SkColorSpace in SkImageInfo is ignored. Some color precision may be lost in the
    conversion to unpremultiplied color; original pixel data may have additional
    precision.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   pixel converted to unpremultiplied color
    
    example: https://fiddle.skia.org/c/@Pixmap_getColor
    */
    getColor :: (this: *SkPixmap, x: s32, y: s32) -> SkColor #cpp_method #foreign libskia "?getColor@SkPixmap@@QEBAIHH@Z";

    /** Returns pixel at (x, y) as unpremultiplied color as an SkColor4f.
    Returns black with alpha if SkColorType is kAlpha_8_SkColorType.
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined; and returns undefined values or may crash if
    SK_RELEASE is defined. Fails if SkColorType is kUnknown_SkColorType or
    pixel address is nullptr.
    
    SkColorSpace in SkImageInfo is ignored. Some color precision may be lost in the
    conversion to unpremultiplied color; original pixel data may have additional
    precision, though this is less likely than for getColor(). Rounding errors may
    occur if the underlying type has lower precision.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   pixel converted to unpremultiplied float color
    */
    getColor4f :: (this: *SkPixmap, x: s32, y: s32) -> SkColor4f #cpp_method #foreign libskia "?getColor4f@SkPixmap@@QEBA?AU?$SkRGBA4f@$02@@HH@Z";

    /** Look up the pixel at (x,y) and return its alpha component, normalized to [0..1].
    This is roughly equivalent to SkGetColorA(getColor()), but can be more efficent
    (and more precise if the pixels store more than 8 bits per component).
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   alpha converted to normalized float
    */
    getAlphaf :: (this: *SkPixmap, x: s32, y: s32) -> float #cpp_method #foreign libskia "?getAlphaf@SkPixmap@@QEBAMHH@Z";

    /** Returns readable pixel address at (x, y). Returns nullptr if SkPixelRef is nullptr.
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined. Returns nullptr if SkColorType is kUnknown_SkColorType.
    
    Performs a lookup of pixel size; for better performance, call
    one of: addr8, addr16, addr32, addr64, or addrF16().
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable generic pointer to pixel
    */
    addr :: (this: *SkPixmap, x: s32, y: s32) -> *void #cpp_method #foreign libskia "?addr@SkPixmap@@QEBAPEBXHH@Z";

    /** Returns readable base pixel address. Result is addressable as unsigned 8-bit bytes.
    Will trigger an assert() if SkColorType is not kAlpha_8_SkColorType or
    kGray_8_SkColorType, and is built with SK_DEBUG defined.
    
    One byte corresponds to one pixel.
    
    @return  readable unsigned 8-bit pointer to pixels
    */
    addr8 :: (this: *SkPixmap) -> *u8 #cpp_method #foreign libskia "?addr8@SkPixmap@@QEBAPEBEXZ";

    /** Returns readable base pixel address. Result is addressable as unsigned 16-bit words.
    Will trigger an assert() if SkColorType is not kRGB_565_SkColorType or
    kARGB_4444_SkColorType, and is built with SK_DEBUG defined.
    
    One word corresponds to one pixel.
    
    @return  readable unsigned 16-bit pointer to pixels
    */
    addr16 :: (this: *SkPixmap) -> *u16 #cpp_method #foreign libskia "?addr16@SkPixmap@@QEBAPEBGXZ";

    /** Returns readable base pixel address. Result is addressable as unsigned 32-bit words.
    Will trigger an assert() if SkColorType is not kRGBA_8888_SkColorType or
    kBGRA_8888_SkColorType, and is built with SK_DEBUG defined.
    
    One word corresponds to one pixel.
    
    @return  readable unsigned 32-bit pointer to pixels
    */
    addr32 :: (this: *SkPixmap) -> *u32 #cpp_method #foreign libskia "?addr32@SkPixmap@@QEBAPEBIXZ";

    /** Returns readable base pixel address. Result is addressable as unsigned 64-bit words.
    Will trigger an assert() if SkColorType is not kRGBA_F16_SkColorType and is built
    with SK_DEBUG defined.
    
    One word corresponds to one pixel.
    
    @return  readable unsigned 64-bit pointer to pixels
    */
    addr64 :: (this: *SkPixmap) -> *u64 #cpp_method #foreign libskia "?addr64@SkPixmap@@QEBAPEB_KXZ";

    /** Returns readable base pixel address. Result is addressable as unsigned 16-bit words.
    Will trigger an assert() if SkColorType is not kRGBA_F16_SkColorType and is built
    with SK_DEBUG defined.
    
    Each word represents one color component encoded as a half float.
    Four words correspond to one pixel.
    
    @return  readable unsigned 16-bit pointer to first component of pixels
    */
    addrF16 :: (this: *SkPixmap) -> *u16 #cpp_method #foreign libskia "?addrF16@SkPixmap@@QEBAPEBGXZ";

    /** Returns readable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined.
    
    Will trigger an assert() if SkColorType is not kAlpha_8_SkColorType or
    kGray_8_SkColorType, and is built with SK_DEBUG defined.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable unsigned 8-bit pointer to pixel at (x, y)
    */
    addr8 :: (this: *SkPixmap, x: s32, y: s32) -> *u8 #cpp_method #foreign libskia "?addr8@SkPixmap@@QEBAPEBEHH@Z";

    /** Returns readable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined.
    
    Will trigger an assert() if SkColorType is not kRGB_565_SkColorType or
    kARGB_4444_SkColorType, and is built with SK_DEBUG defined.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable unsigned 16-bit pointer to pixel at (x, y)
    */
    addr16 :: (this: *SkPixmap, x: s32, y: s32) -> *u16 #cpp_method #foreign libskia "?addr16@SkPixmap@@QEBAPEBGHH@Z";

    /** Returns readable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined.
    
    Will trigger an assert() if SkColorType is not kRGBA_8888_SkColorType or
    kBGRA_8888_SkColorType, and is built with SK_DEBUG defined.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable unsigned 32-bit pointer to pixel at (x, y)
    */
    addr32 :: (this: *SkPixmap, x: s32, y: s32) -> *u32 #cpp_method #foreign libskia "?addr32@SkPixmap@@QEBAPEBIHH@Z";

    /** Returns readable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined.
    
    Will trigger an assert() if SkColorType is not kRGBA_F16_SkColorType and is built
    with SK_DEBUG defined.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable unsigned 64-bit pointer to pixel at (x, y)
    */
    addr64 :: (this: *SkPixmap, x: s32, y: s32) -> *u64 #cpp_method #foreign libskia "?addr64@SkPixmap@@QEBAPEB_KHH@Z";

    /** Returns readable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined.
    
    Will trigger an assert() if SkColorType is not kRGBA_F16_SkColorType and is built
    with SK_DEBUG defined.
    
    Each unsigned 16-bit word represents one color component encoded as a half float.
    Four words correspond to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   readable unsigned 16-bit pointer to pixel component at (x, y)
    */
    addrF16 :: (this: *SkPixmap, x: s32, y: s32) -> *u16 #cpp_method #foreign libskia "?addrF16@SkPixmap@@QEBAPEBGHH@Z";

    /** Returns writable base pixel address.
    
    @return  writable generic base pointer to pixels
    */
    writable_addr :: (this: *SkPixmap) -> *void #cpp_method #foreign libskia "?writable_addr@SkPixmap@@QEBAPEAXXZ";

    /** Returns writable pixel address at (x, y).
    
    Input is not validated: out of bounds values of x or y trigger an assert() if
    built with SK_DEBUG defined. Returns zero if SkColorType is kUnknown_SkColorType.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable generic pointer to pixel
    */
    writable_addr :: (this: *SkPixmap, x: s32, y: s32) -> *void #cpp_method #foreign libskia "?writable_addr@SkPixmap@@QEBAPEAXHH@Z";

    /** Returns writable pixel address at (x, y). Result is addressable as unsigned
    8-bit bytes. Will trigger an assert() if SkColorType is not kAlpha_8_SkColorType
    or kGray_8_SkColorType, and is built with SK_DEBUG defined.
    
    One byte corresponds to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable unsigned 8-bit pointer to pixels
    */
    writable_addr8 :: (this: *SkPixmap, x: s32, y: s32) -> *u8 #cpp_method #foreign libskia "?writable_addr8@SkPixmap@@QEBAPEAEHH@Z";

    /** Returns writable_addr pixel address at (x, y). Result is addressable as unsigned
    16-bit words. Will trigger an assert() if SkColorType is not kRGB_565_SkColorType
    or kARGB_4444_SkColorType, and is built with SK_DEBUG defined.
    
    One word corresponds to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable unsigned 16-bit pointer to pixel
    */
    writable_addr16 :: (this: *SkPixmap, x: s32, y: s32) -> *u16 #cpp_method #foreign libskia "?writable_addr16@SkPixmap@@QEBAPEAGHH@Z";

    /** Returns writable pixel address at (x, y). Result is addressable as unsigned
    32-bit words. Will trigger an assert() if SkColorType is not
    kRGBA_8888_SkColorType or kBGRA_8888_SkColorType, and is built with SK_DEBUG
    defined.
    
    One word corresponds to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable unsigned 32-bit pointer to pixel
    */
    writable_addr32 :: (this: *SkPixmap, x: s32, y: s32) -> *u32 #cpp_method #foreign libskia "?writable_addr32@SkPixmap@@QEBAPEAIHH@Z";

    /** Returns writable pixel address at (x, y). Result is addressable as unsigned
    64-bit words. Will trigger an assert() if SkColorType is not
    kRGBA_F16_SkColorType and is built with SK_DEBUG defined.
    
    One word corresponds to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable unsigned 64-bit pointer to pixel
    */
    writable_addr64 :: (this: *SkPixmap, x: s32, y: s32) -> *u64 #cpp_method #foreign libskia "?writable_addr64@SkPixmap@@QEBAPEA_KHH@Z";

    /** Returns writable pixel address at (x, y). Result is addressable as unsigned
    16-bit words. Will trigger an assert() if SkColorType is not
    kRGBA_F16_SkColorType and is built with SK_DEBUG defined.
    
    Each word represents one color component encoded as a half float.
    Four words correspond to one pixel.
    
    @param x  column index, zero or greater, and less than width()
    @param y  row index, zero or greater, and less than height()
    @return   writable unsigned 16-bit pointer to first component of pixel
    */
    writable_addrF16 :: (this: *SkPixmap, x: s32, y: s32) -> *u16 #cpp_method #foreign libskia "?writable_addrF16@SkPixmap@@QEBAPEAGHH@Z";

    /** Copies a SkRect of pixels to dstPixels. Copy starts at (0, 0), and does not
    exceed SkPixmap (width(), height()).
    
    dstInfo specifies width, height, SkColorType, SkAlphaType, and
    SkColorSpace of destination. dstRowBytes specifics the gap from one destination
    row to the next. Returns true if pixels are copied. Returns false if
    dstInfo address equals nullptr, or dstRowBytes is less than dstInfo.minRowBytes().
    
    Pixels are copied only if pixel conversion is possible. If SkPixmap colorType() is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dstInfo.colorType() must match.
    If SkPixmap colorType() is kGray_8_SkColorType, dstInfo.colorSpace() must match.
    If SkPixmap alphaType() is kOpaque_SkAlphaType, dstInfo.alphaType() must
    match. If SkPixmap colorSpace() is nullptr, dstInfo.colorSpace() must match. Returns
    false if pixel conversion is not possible.
    
    Returns false if SkPixmap width() or height() is zero or negative.
    
    @param dstInfo      destination width, height, SkColorType, SkAlphaType, SkColorSpace
    @param dstPixels    destination pixel storage
    @param dstRowBytes  destination row length
    @return             true if pixels are copied to dstPixels
    */
    readPixels :: (this: *SkPixmap, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64) -> bool #cpp_method #foreign libskia "?readPixels@SkPixmap@@QEBA_NAEBUSkImageInfo@@PEAX_K@Z";
    readPixels :: (this: *SkPixmap, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64) -> bool #no_context {
        return readPixels(this, *dstInfo, dstPixels, dstRowBytes);
    }

    /** Copies a SkRect of pixels to dstPixels. Copy starts at (srcX, srcY), and does not
    exceed SkPixmap (width(), height()).
    
    dstInfo specifies width, height, SkColorType, SkAlphaType, and
    SkColorSpace of destination. dstRowBytes specifics the gap from one destination
    row to the next. Returns true if pixels are copied. Returns false if
    dstInfo address equals nullptr, or dstRowBytes is less than dstInfo.minRowBytes().
    
    Pixels are copied only if pixel conversion is possible. If SkPixmap colorType() is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dstInfo.colorType() must match.
    If SkPixmap colorType() is kGray_8_SkColorType, dstInfo.colorSpace() must match.
    If SkPixmap alphaType() is kOpaque_SkAlphaType, dstInfo.alphaType() must
    match. If SkPixmap colorSpace() is nullptr, dstInfo.colorSpace() must match. Returns
    false if pixel conversion is not possible.
    
    srcX and srcY may be negative to copy only top or left of source. Returns
    false if SkPixmap width() or height() is zero or negative. Returns false if:
    abs(srcX) >= Pixmap width(), or if abs(srcY) >= Pixmap height().
    
    @param dstInfo      destination width, height, SkColorType, SkAlphaType, SkColorSpace
    @param dstPixels    destination pixel storage
    @param dstRowBytes  destination row length
    @param srcX         column index whose absolute value is less than width()
    @param srcY         row index whose absolute value is less than height()
    @return             true if pixels are copied to dstPixels
    */
    readPixels :: (this: *SkPixmap, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkPixmap@@QEBA_NAEBUSkImageInfo@@PEAX_KHH@Z";
    readPixels :: (this: *SkPixmap, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dstInfo, dstPixels, dstRowBytes, srcX, srcY);
    }

    /** Copies a SkRect of pixels to dst. Copy starts at (srcX, srcY), and does not
    exceed SkPixmap (width(), height()). dst specifies width, height, SkColorType,
    SkAlphaType, and SkColorSpace of destination.  Returns true if pixels are copied.
    Returns false if dst address equals nullptr, or dst.rowBytes() is less than
    dst SkImageInfo::minRowBytes.
    
    Pixels are copied only if pixel conversion is possible. If SkPixmap colorType() is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dst.info().colorType must match.
    If SkPixmap colorType() is kGray_8_SkColorType, dst.info().colorSpace must match.
    If SkPixmap alphaType() is kOpaque_SkAlphaType, dst.info().alphaType must
    match. If SkPixmap colorSpace() is nullptr, dst.info().colorSpace must match. Returns
    false if pixel conversion is not possible.
    
    srcX and srcY may be negative to copy only top or left of source. Returns
    false SkPixmap width() or height() is zero or negative. Returns false if:
    abs(srcX) >= Pixmap width(), or if abs(srcY) >= Pixmap height().
    
    @param dst   SkImageInfo and pixel address to write to
    @param srcX  column index whose absolute value is less than width()
    @param srcY  row index whose absolute value is less than height()
    @return      true if pixels are copied to dst
    */
    readPixels :: (this: *SkPixmap, dst: *SkPixmap, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkPixmap@@QEBA_NAEBV1@HH@Z";
    readPixels :: (this: *SkPixmap, dst: SkPixmap, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dst, srcX, srcY);
    }

    /** Copies pixels inside bounds() to dst. dst specifies width, height, SkColorType,
    SkAlphaType, and SkColorSpace of destination.  Returns true if pixels are copied.
    Returns false if dst address equals nullptr, or dst.rowBytes() is less than
    dst SkImageInfo::minRowBytes.
    
    Pixels are copied only if pixel conversion is possible. If SkPixmap colorType() is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dst SkColorType must match.
    If SkPixmap colorType() is kGray_8_SkColorType, dst SkColorSpace must match.
    If SkPixmap alphaType() is kOpaque_SkAlphaType, dst SkAlphaType must
    match. If SkPixmap colorSpace() is nullptr, dst SkColorSpace must match. Returns
    false if pixel conversion is not possible.
    
    Returns false if SkPixmap width() or height() is zero or negative.
    
    @param dst  SkImageInfo and pixel address to write to
    @return     true if pixels are copied to dst
    */
    readPixels :: (this: *SkPixmap, dst: *SkPixmap) -> bool #cpp_method #foreign libskia "?readPixels@SkPixmap@@QEBA_NAEBV1@@Z";
    readPixels :: (this: *SkPixmap, dst: SkPixmap) -> bool #no_context {
        return readPixels(this, *dst);
    }

    /** Copies SkBitmap to dst, scaling pixels to fit dst.width() and dst.height(), and
    converting pixels to match dst.colorType() and dst.alphaType(). Returns true if
    pixels are copied. Returns false if dst address is nullptr, or dst.rowBytes() is
    less than dst SkImageInfo::minRowBytes.
    
    Pixels are copied only if pixel conversion is possible. If SkPixmap colorType() is
    kGray_8_SkColorType, or kAlpha_8_SkColorType; dst SkColorType must match.
    If SkPixmap colorType() is kGray_8_SkColorType, dst SkColorSpace must match.
    If SkPixmap alphaType() is kOpaque_SkAlphaType, dst SkAlphaType must
    match. If SkPixmap colorSpace() is nullptr, dst SkColorSpace must match. Returns
    false if pixel conversion is not possible.
    
    Returns false if SkBitmap width() or height() is zero or negative.
    
    @param dst            SkImageInfo and pixel address to write to
    @return               true if pixels are scaled to fit dst
    
    example: https://fiddle.skia.org/c/@Pixmap_scalePixels
    */
    scalePixels :: (this: *SkPixmap, dst: *SkPixmap, unknown0: *SkSamplingOptions) -> bool #cpp_method #foreign libskia "?scalePixels@SkPixmap@@QEBA_NAEBV1@AEBUSkSamplingOptions@@@Z";
    scalePixels :: (this: *SkPixmap, dst: SkPixmap, unknown0: SkSamplingOptions) -> bool #no_context {
        return scalePixels(this, *dst, *unknown0);
    }

    /** Writes color to pixels bounded by subset; returns true on success.
    Returns false if colorType() is kUnknown_SkColorType, or if subset does
    not intersect bounds().
    
    @param color   sRGB unpremultiplied color to write
    @param subset  bounding integer SkRect of written pixels
    @return        true if pixels are changed
    
    example: https://fiddle.skia.org/c/@Pixmap_erase
    */
    erase :: (this: *SkPixmap, color: SkColor, subset: *SkIRect) -> bool #cpp_method #foreign libskia "?erase@SkPixmap@@QEBA_NIAEBUSkIRect@@@Z";
    erase :: (this: *SkPixmap, color: SkColor, subset: SkIRect) -> bool #no_context {
        return erase(this, color, *subset);
    }

    /** Writes color to pixels inside bounds(); returns true on success.
    Returns false if colorType() is kUnknown_SkColorType, or if bounds()
    is empty.
    
    @param color  sRGB unpremultiplied color to write
    @return       true if pixels are changed
    */
    erase :: (this: *SkPixmap, color: SkColor) -> bool #cpp_method #foreign libskia "?erase@SkPixmap@@QEBA_NI@Z";

    /** Writes color to pixels bounded by subset; returns true on success.
    if subset is nullptr, writes colors pixels inside bounds(). Returns false if
    colorType() is kUnknown_SkColorType, if subset is not nullptr and does
    not intersect bounds(), or if subset is nullptr and bounds() is empty.
    
    @param color   unpremultiplied color to write
    @param subset  bounding integer SkRect of pixels to write; may be nullptr
    @return        true if pixels are changed
    */
    erase :: (this: *SkPixmap, color: *SkColor4f, subset: *SkIRect = null) -> bool #cpp_method #foreign libskia "?erase@SkPixmap@@QEBA_NAEBU?$SkRGBA4f@$02@@PEBUSkIRect@@@Z";
    erase :: (this: *SkPixmap, color: SkColor4f, subset: *SkIRect = null) -> bool #no_context {
        return erase(this, *color, subset);
    }

    fPixels:   *void;
    fRowBytes: u64;
    fInfo:     SkImageInfo;
}

GrBackendSemaphore :: struct {}
GrBackendTexture :: struct {}

GrSurfaceCharacterization :: struct {}

SkCapabilities :: struct {}

GrSurfaceOrigin :: enum s32 {
}

SkSurfaces :: struct {
    BackendSurfaceAccess :: enum s32 {
        NoAccess :: 0;
        Present  :: 1;

        kNoAccess :: NoAccess;
        kPresent  :: Present;
    }

    /** Returns SkSurface without backing pixels. Drawing to SkCanvas returned from SkSurface
    has no effect. Calling makeImageSnapshot() on returned SkSurface returns nullptr.
    
    @param width   one or greater
    @param height  one or greater
    @return        SkSurface if width and height are positive; otherwise, nullptr
    
    example: https://fiddle.skia.org/c/@Surface_MakeNull
    */
    Null :: (width: s32, height: s32) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?Null@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@HH@Z";

    /** Allocates raster SkSurface. SkCanvas returned by SkSurface draws directly into those allocated
    pixels, which are zeroed before use. Pixel memory size is imageInfo.height() times
    imageInfo.minRowBytes() or rowBytes, if provided and non-zero.
    
    Pixel memory is deleted when SkSurface is deleted.
    
    Validity constraints include:
    - info dimensions are greater than zero;
    - info contains SkColorType and SkAlphaType supported by raster surface.
    
    @param imageInfo  width, height, SkColorType, SkAlphaType, SkColorSpace,
    of raster surface; width and height must be greater than zero
    @param rowBytes   interval from one SkSurface row to the next.
    @param props      LCD striping orientation and setting for device independent fonts;
    may be nullptr
    @return           SkSurface if parameters are valid and memory was allocated, else nullptr.
    */
    Raster :: (imageInfo: *SkImageInfo, rowBytes: u64, surfaceProps: *SkSurfaceProps) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?Raster@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@_KPEBVSkSurfaceProps@@@Z";
    Raster :: (imageInfo: SkImageInfo, rowBytes: u64, surfaceProps: *SkSurfaceProps) -> sk_sp(SkSurface) #no_context {
        return Raster(*imageInfo, rowBytes, surfaceProps);
    }

//     Raster :: (imageInfo: *SkImageInfo, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?Raster@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@PEBVSkSurfaceProps@@@Z";
    Raster :: (imageInfo: SkImageInfo, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #no_context {
        return Raster(*imageInfo, props);
    }

    /** Allocates raster SkSurface. SkCanvas returned by SkSurface draws directly into the
    provided pixels.
    
    SkSurface is returned if all parameters are valid.
    Valid parameters include:
    info dimensions are greater than zero;
    info contains SkColorType and SkAlphaType supported by raster surface;
    pixels is not nullptr;
    rowBytes is large enough to contain info width pixels of SkColorType.
    
    Pixel buffer size should be info height times computed rowBytes.
    Pixels are not initialized.
    To access pixels after drawing, peekPixels() or readPixels().
    
    @param imageInfo     width, height, SkColorType, SkAlphaType, SkColorSpace,
    of raster surface; width and height must be greater than zero
    @param pixels        pointer to destination pixels buffer
    @param rowBytes      interval from one SkSurface row to the next
    @param surfaceProps  LCD striping orientation and setting for device independent fonts;
    may be nullptr
    @return              SkSurface if all parameters are valid; otherwise, nullptr
    */
    WrapPixels :: (imageInfo: *SkImageInfo, pixels: *void, rowBytes: u64, surfaceProps: *SkSurfaceProps = null) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?WrapPixels@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@PEAX_KPEBVSkSurfaceProps@@@Z";
    WrapPixels :: (imageInfo: SkImageInfo, pixels: *void, rowBytes: u64, surfaceProps: *SkSurfaceProps = null) -> sk_sp(SkSurface) #no_context {
        return WrapPixels(*imageInfo, pixels, rowBytes, surfaceProps);
    }

//     WrapPixels :: (pm: *SkPixmap, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?WrapPixels@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@AEBVSkPixmap@@PEBVSkSurfaceProps@@@Z";
    WrapPixels :: (pm: SkPixmap, props: *SkSurfaceProps = null) -> sk_sp(SkSurface) #no_context {
        return WrapPixels(*pm, props);
    }

    PixelsReleaseProc :: #type (pixels: *void, _context: *void) -> void #c_call;

    /** Allocates raster SkSurface. SkCanvas returned by SkSurface draws directly into the provided
    pixels. releaseProc is called with pixels and context when SkSurface is deleted.
    
    SkSurface is returned if all parameters are valid.
    Valid parameters include:
    info dimensions are greater than zero;
    info contains SkColorType and SkAlphaType supported by raster surface;
    pixels is not nullptr;
    rowBytes is large enough to contain info width pixels of SkColorType.
    
    Pixel buffer size should be info height times computed rowBytes.
    Pixels are not initialized.
    To access pixels after drawing, call flush() or peekPixels().
    
    @param imageInfo     width, height, SkColorType, SkAlphaType, SkColorSpace,
    of raster surface; width and height must be greater than zero
    @param pixels        pointer to destination pixels buffer
    @param rowBytes      interval from one SkSurface row to the next
    @param releaseProc   called when SkSurface is deleted; may be nullptr
    @param context       passed to releaseProc; may be nullptr
    @param surfaceProps  LCD striping orientation and setting for device independent fonts;
    may be nullptr
    @return              SkSurface if all parameters are valid; otherwise, nullptr
    */
    WrapPixels :: (imageInfo: *SkImageInfo, pixels: *void, rowBytes: u64, unknown0: PixelsReleaseProc, _context: *void, surfaceProps: *SkSurfaceProps = null) -> sk_sp(SkSurface) #cpp_return_type_is_non_pod #foreign libskia "?WrapPixels@SkSurfaces@@YA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@PEAX_KP6AX11@Z1PEBVSkSurfaceProps@@@Z";
    WrapPixels :: (imageInfo: SkImageInfo, pixels: *void, rowBytes: u64, unknown0: PixelsReleaseProc, _context: *void, surfaceProps: *SkSurfaceProps = null) -> sk_sp(SkSurface) #no_context {
        return WrapPixels(*imageInfo, pixels, rowBytes, unknown0, _context, surfaceProps);
    }
}

/** \class SkSurface
SkSurface is responsible for managing the pixels that a canvas draws into. The pixels can be
allocated either in CPU memory (a raster surface) or on the GPU (a GrRenderTarget surface).
SkSurface takes care of allocating a SkCanvas that will draw into the surface. Call
surface->getCanvas() to use that canvas (but don't delete it, it is owned by the surface).
SkSurface always has non-zero dimensions. If there is a request for a new surface, and either
of the requested dimensions are zero, then nullptr will be returned.

Clients should *not* subclass SkSurface as there is a lot of internal machinery that is
not publicly accessible.
*/
SkSurface :: struct {
    vtable:               *SkSurface_VTable;
    using sksurface__raw: SkSurface__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkSurface without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkSurface
SkSurface__RAW :: struct {
    using skrefcnt__raw:               SkRefCnt__RAW;

    /** Is this surface compatible with the provided characterization?
    
    This method can be used to determine if an existing SkSurface is a viable destination
    for an GrDeferredDisplayList.
    
    @param characterization  The characterization for which a compatibility check is desired
    @return                  true if this surface is compatible with the characterization;
    false otherwise
    */
    isCompatible :: (this: *SkSurface, characterization: *GrSurfaceCharacterization) -> bool #cpp_method #foreign libskia "?isCompatible@SkSurface@@QEBA_NAEBVGrSurfaceCharacterization@@@Z";
    isCompatible :: (this: *SkSurface, characterization: GrSurfaceCharacterization) -> bool #no_context {
        return isCompatible(this, *characterization);
    }

    /** Returns pixel count in each row; may be zero or greater.
    
    @return  number of pixel columns
    */
    width :: (this: *SkSurface) -> s32 #cpp_method #foreign libskia "?width@SkSurface@@QEBAHXZ";

    /** Returns pixel row count; may be zero or greater.
    
    @return  number of pixel rows
    */
    height :: (this: *SkSurface) -> s32 #cpp_method #foreign libskia "?height@SkSurface@@QEBAHXZ";

    /** Returns unique value identifying the content of SkSurface. Returned value changes
    each time the content changes. Content is changed by drawing, or by calling
    notifyContentWillChange().
    
    @return  unique content identifier
    
    example: https://fiddle.skia.org/c/@Surface_notifyContentWillChange
    */
    generationID :: (this: *SkSurface) -> u32 #cpp_method #foreign libskia "?generationID@SkSurface@@QEAAIXZ";

    /** \enum SkSurface::ContentChangeMode
    ContentChangeMode members are parameters to notifyContentWillChange().
    */
    ContentChangeMode :: enum s32 {
        Discard_ContentChangeMode :: 0;
        Retain_ContentChangeMode  :: 1;

        kDiscard_ContentChangeMode :: Discard_ContentChangeMode;
        kRetain_ContentChangeMode  :: Retain_ContentChangeMode;
    }

    /** Notifies that SkSurface contents will be changed by code outside of Skia.
    Subsequent calls to generationID() return a different value.
    
    TODO: Can kRetain_ContentChangeMode be deprecated?
    
    example: https://fiddle.skia.org/c/@Surface_notifyContentWillChange
    */
    notifyContentWillChange :: (this: *SkSurface, mode: SkSurface.ContentChangeMode) -> void #cpp_method #foreign libskia "?notifyContentWillChange@SkSurface@@QEAAXW4ContentChangeMode@1@@Z";

    /** Returns the recording context being used by the SkSurface.
    
    @return the recording context, if available; nullptr otherwise
    */
    recordingContext :: (this: *SkSurface) -> *GrRecordingContext #cpp_method #foreign libskia "?recordingContext@SkSurface@@QEBAPEAVGrRecordingContext@@XZ";

    /** Returns the recorder being used by the SkSurface.
    
    @return the recorder, if available; nullptr otherwise
    */
    recorder :: (this: *SkSurface) -> *skgpu.graphite.Recorder #cpp_method #foreign libskia "?recorder@SkSurface@@QEBAPEAVRecorder@graphite@skgpu@@XZ";

    /** Returns the base SkRecorder being used by the SkSurface.
    
    @return the recorder; should be non-null for drawable surfaces
    */
    baseRecorder :: (this: *SkSurface) -> *SkRecorder #cpp_method #foreign libskia "?baseRecorder@SkSurface@@QEBAPEAVSkRecorder@@XZ";

    BackendHandleAccess :: enum s32 {
        FlushRead                        :: 0;
        FlushWrite                       :: 1;
        DiscardWrite                     :: 2;

        FlushRead_BackendHandleAccess    :: 0;
        FlushWrite_BackendHandleAccess   :: 1;
        DiscardWrite_BackendHandleAccess :: 2;

        kFlushRead                        :: FlushRead;
        kFlushWrite                       :: FlushWrite;
        kDiscardWrite                     :: DiscardWrite;

        kFlushRead_BackendHandleAccess    :: FlushRead_BackendHandleAccess;
        kFlushWrite_BackendHandleAccess   :: FlushWrite_BackendHandleAccess;
        kDiscardWrite_BackendHandleAccess :: DiscardWrite_BackendHandleAccess;
    }

    // Legacy names, remove when clients are migrated
    kFlushRead_BackendHandleAccess:    SkSurface.BackendHandleAccess : .FlushRead;

    kFlushWrite_BackendHandleAccess:   SkSurface.BackendHandleAccess : .FlushWrite;

    kDiscardWrite_BackendHandleAccess: SkSurface.BackendHandleAccess : .DiscardWrite;

    /** Caller data passed to TextureReleaseProc; may be nullptr. */
    ReleaseContext :: *void;

    /** User function called when supplied texture may be deleted. */
    TextureReleaseProc :: #type (unknown0: ReleaseContext) -> void #c_call;

    /** Returns SkCanvas that draws into SkSurface. Subsequent calls return the same SkCanvas.
    SkCanvas returned is managed and owned by SkSurface, and is deleted when SkSurface
    is deleted.
    
    @return  drawing SkCanvas for SkSurface
    
    example: https://fiddle.skia.org/c/@Surface_getCanvas
    */
    getCanvas :: (this: *SkSurface) -> *SkCanvas #cpp_method #foreign libskia "?getCanvas@SkSurface@@QEAAPEAVSkCanvas@@XZ";

    /** Returns SkCapabilities that describes the capabilities of the SkSurface's device.
    
    @return  SkCapabilities of SkSurface's device.
    */
    capabilities :: (this: *SkSurface) -> sk_sp(SkCapabilities) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?capabilities@SkSurface@@QEAA?AV?$sk_sp@$$CBVSkCapabilities@@@@XZ";

    /** Returns a compatible SkSurface, or nullptr. Returned SkSurface contains
    the same raster, GPU, or null properties as the original. Returned SkSurface
    does not share the same pixels.
    
    Returns nullptr if imageInfo width or height are zero, or if imageInfo
    is incompatible with SkSurface.
    
    @param imageInfo  width, height, SkColorType, SkAlphaType, SkColorSpace,
    of SkSurface; width and height must be greater than zero
    @return           compatible SkSurface or nullptr
    
    example: https://fiddle.skia.org/c/@Surface_makeSurface
    */
    makeSurface :: (this: *SkSurface, imageInfo: *SkImageInfo) -> sk_sp(SkSurface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeSurface@SkSurface@@QEAA?AV?$sk_sp@VSkSurface@@@@AEBUSkImageInfo@@@Z";
    makeSurface :: (this: *SkSurface, imageInfo: SkImageInfo) -> sk_sp(SkSurface) #no_context {
        return makeSurface(this, *imageInfo);
    }

    /** Calls makeSurface(ImageInfo) with the same ImageInfo as this surface, but with the
    *  specified width and height.
    */
    makeSurface :: (this: *SkSurface, width: s32, height: s32) -> sk_sp(SkSurface) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeSurface@SkSurface@@QEAA?AV?$sk_sp@VSkSurface@@@@HH@Z";

    /** Returns SkImage capturing SkSurface contents. Subsequent drawing to SkSurface contents
    are not captured. SkImage allocation is accounted for if SkSurface was created with
    skgpu::Budgeted::kYes.
    
    @return  SkImage initialized with SkSurface contents
    
    example: https://fiddle.skia.org/c/@Surface_makeImageSnapshot
    */
    makeImageSnapshot :: (this: *SkSurface) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeImageSnapshot@SkSurface@@QEAA?AV?$sk_sp@VSkImage@@@@XZ";

    /**
    *  Like the no-parameter version, this returns an image of the current surface contents.
    *  This variant takes a rectangle specifying the subset of the surface that is of interest.
    *  These bounds will be sanitized before being used.
    *  - If bounds extends beyond the surface, it will be trimmed to just the intersection of
    *    it and the surface.
    *  - If bounds does not intersect the surface, then this returns nullptr.
    *  - If bounds == the surface, then this is the same as calling the no-parameter variant.
    
    example: https://fiddle.skia.org/c/@Surface_makeImageSnapshot_2
    */
    makeImageSnapshot :: (this: *SkSurface, bounds: *SkIRect) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeImageSnapshot@SkSurface@@QEAA?AV?$sk_sp@VSkImage@@@@AEBUSkIRect@@@Z";
    makeImageSnapshot :: (this: *SkSurface, bounds: SkIRect) -> sk_sp(SkImage) #no_context {
        return makeImageSnapshot(this, *bounds);
    }

    /** Returns an SkImage capturing the current SkSurface contents. However, the contents of the
    SkImage are only valid as long as no other writes to the SkSurface occur. If writes to the
    original SkSurface happen then contents of the SkImage are undefined. However, continued use
    of the SkImage should not cause crashes or similar fatal behavior.
    
    This API is useful for cases where the client either immediately destroys the SkSurface
    after the SkImage is created or knows they will destroy the SkImage before writing to the
    SkSurface again.
    
    This API can be more performant than makeImageSnapshot as it never does an internal copy
    of the data assuming the user frees either the SkImage or SkSurface as described above.
    */
    makeTemporaryImage :: (this: *SkSurface) -> sk_sp(SkImage) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeTemporaryImage@SkSurface@@QEAA?AV?$sk_sp@VSkImage@@@@XZ";

    /** Draws SkSurface contents to canvas, with its top-left corner at (x, y).
    
    If SkPaint paint is not nullptr, apply SkColorFilter, alpha, SkImageFilter, and SkBlendMode.
    
    @param canvas  SkCanvas drawn into
    @param x       horizontal offset in SkCanvas
    @param y       vertical offset in SkCanvas
    @param sampling what technique to use when sampling the surface pixels
    @param paint   SkPaint containing SkBlendMode, SkColorFilter, SkImageFilter,
    and so on; or nullptr
    
    example: https://fiddle.skia.org/c/@Surface_draw
    */
    draw :: (this: *SkSurface, canvas: *SkCanvas, x: SkScalar, y: SkScalar, sampling: *SkSamplingOptions, paint: *SkPaint) -> void #cpp_method #foreign libskia "?draw@SkSurface@@QEAAXPEAVSkCanvas@@MMAEBUSkSamplingOptions@@PEBVSkPaint@@@Z";
    draw :: (this: *SkSurface, canvas: *SkCanvas, x: SkScalar, y: SkScalar, sampling: SkSamplingOptions, paint: *SkPaint) #no_context {
        draw(this, canvas, x, y, *sampling, paint);
    }

    draw :: (this: *SkSurface, canvas: *SkCanvas, x: SkScalar, y: SkScalar, paint: *SkPaint = null) -> void #cpp_method #foreign libskia "?draw@SkSurface@@QEAAXPEAVSkCanvas@@MMPEBVSkPaint@@@Z";

    /** Copies SkSurface pixel address, row bytes, and SkImageInfo to SkPixmap, if address
    is available, and returns true. If pixel address is not available, return
    false and leave SkPixmap unchanged.
    
    pixmap contents become invalid on any future change to SkSurface.
    
    @param pixmap  storage for pixel state if pixels are readable; otherwise, ignored
    @return        true if SkSurface has direct access to pixels
    
    example: https://fiddle.skia.org/c/@Surface_peekPixels
    */
    peekPixels :: (this: *SkSurface, pixmap: *SkPixmap) -> bool #cpp_method #foreign libskia "?peekPixels@SkSurface@@QEAA_NPEAVSkPixmap@@@Z";

    /** Copies SkRect of pixels to dst.
    
    Source SkRect corners are (srcX, srcY) and SkSurface (width(), height()).
    Destination SkRect corners are (0, 0) and (dst.width(), dst.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to dst.colorType() and dst.alphaType() if required.
    
    Pixels are readable when SkSurface is raster, or backed by a Ganesh GPU backend. Graphite
    has deprecated this API in favor of the equivalent asynchronous API on
    skgpu::graphite::Context (with an optional explicit synchonization).
    
    The destination pixel storage must be allocated by the caller.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. dst contents outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down destination.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkPixmap pixels could not be allocated.
    - dst.rowBytes() is too small to contain one row of pixels.
    
    @param dst   storage for pixels copied from SkSurface
    @param srcX  offset into readable pixels on x-axis; may be negative
    @param srcY  offset into readable pixels on y-axis; may be negative
    @return      true if pixels were copied
    
    example: https://fiddle.skia.org/c/@Surface_readPixels
    */
    readPixels :: (this: *SkSurface, dst: *SkPixmap, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkSurface@@QEAA_NAEBVSkPixmap@@HH@Z";
    readPixels :: (this: *SkSurface, dst: SkPixmap, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dst, srcX, srcY);
    }

    /** Copies SkRect of pixels from SkCanvas into dstPixels.
    
    Source SkRect corners are (srcX, srcY) and SkSurface (width(), height()).
    Destination SkRect corners are (0, 0) and (dstInfo.width(), dstInfo.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to dstInfo.colorType() and dstInfo.alphaType() if required.
    
    Pixels are readable when SkSurface is raster, or backed by a Ganesh GPU backend. Graphite
    has deprecated this API in favor of the equivalent asynchronous API on
    skgpu::graphite::Context (with an optional explicit synchonization).
    
    The destination pixel storage must be allocated by the caller.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. dstPixels contents outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down destination.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkSurface pixels could not be converted to dstInfo.colorType() or dstInfo.alphaType().
    - dstRowBytes is too small to contain one row of pixels.
    
    @param dstInfo      width, height, SkColorType, and SkAlphaType of dstPixels
    @param dstPixels    storage for pixels; dstInfo.height() times dstRowBytes, or larger
    @param dstRowBytes  size of one destination row; dstInfo.width() times pixel size, or larger
    @param srcX         offset into readable pixels on x-axis; may be negative
    @param srcY         offset into readable pixels on y-axis; may be negative
    @return             true if pixels were copied
    */
    readPixels :: (this: *SkSurface, dstInfo: *SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkSurface@@QEAA_NAEBUSkImageInfo@@PEAX_KHH@Z";
    readPixels :: (this: *SkSurface, dstInfo: SkImageInfo, dstPixels: *void, dstRowBytes: u64, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dstInfo, dstPixels, dstRowBytes, srcX, srcY);
    }

    /** Copies SkRect of pixels from SkSurface into bitmap.
    
    Source SkRect corners are (srcX, srcY) and SkSurface (width(), height()).
    Destination SkRect corners are (0, 0) and (bitmap.width(), bitmap.height()).
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to bitmap.colorType() and bitmap.alphaType() if required.
    
    Pixels are readable when SkSurface is raster, or backed by a Ganesh GPU backend. Graphite
    has deprecated this API in favor of the equivalent asynchronous API on
    skgpu::graphite::Context (with an optional explicit synchonization).
    
    The destination pixel storage must be allocated by the caller.
    
    Pixel values are converted only if SkColorType and SkAlphaType
    do not match. Only pixels within both source and destination rectangles
    are copied. dst contents outside SkRect intersection are unchanged.
    
    Pass negative values for srcX or srcY to offset pixels across or down destination.
    
    Does not copy, and returns false if:
    - Source and destination rectangles do not intersect.
    - SkSurface pixels could not be converted to dst.colorType() or dst.alphaType().
    - dst pixels could not be allocated.
    - dst.rowBytes() is too small to contain one row of pixels.
    
    @param dst   storage for pixels copied from SkSurface
    @param srcX  offset into readable pixels on x-axis; may be negative
    @param srcY  offset into readable pixels on y-axis; may be negative
    @return      true if pixels were copied
    
    example: https://fiddle.skia.org/c/@Surface_readPixels_3
    */
    readPixels :: (this: *SkSurface, dst: *SkBitmap, srcX: s32, srcY: s32) -> bool #cpp_method #foreign libskia "?readPixels@SkSurface@@QEAA_NAEBVSkBitmap@@HH@Z";
    readPixels :: (this: *SkSurface, dst: SkBitmap, srcX: s32, srcY: s32) -> bool #no_context {
        return readPixels(this, *dst, srcX, srcY);
    }

    AsyncReadResult :: SkImage.AsyncReadResult;

    /** Client-provided context that is passed to client-provided ReadPixelsContext. */
    ReadPixelsContext :: *void;

    /**  Client-provided callback to asyncRescaleAndReadPixels() or
    asyncRescaleAndReadPixelsYUV420() that is called when read result is ready or on failure.
    */
    ReadPixelsCallback :: #type (unknown0: ReadPixelsContext, unknown1: std.unique_ptr(AsyncReadResult)) -> void #c_call;

    /** Controls the gamma that rescaling occurs in for asyncRescaleAndReadPixels() and
    asyncRescaleAndReadPixelsYUV420().
    */
    RescaleGamma :: SkImage.RescaleGamma;
    RescaleMode :: SkImage.RescaleMode;

    /** Makes surface pixel data available to caller, possibly asynchronously. It can also rescale
    the surface pixels.
    
    Currently asynchronous reads are only supported in the Ganesh GPU backend and only when the
    underlying 3D API supports transfer buffers and CPU/GPU synchronization primitives. In all
    other cases this operates synchronously.
    
    For the Graphite backend this API has been deprecated in favor of the equivalent API
    on skgpu::graphite::Context.
    
    Data is read from the source sub-rectangle, is optionally converted to a linear gamma, is
    rescaled to the size indicated by 'info', is then converted to the color space, color type,
    and alpha type of 'info'. A 'srcRect' that is not contained by the bounds of the surface
    causes failure.
    
    When the pixel data is ready the caller's ReadPixelsCallback is called with a
    AsyncReadResult containing pixel data in the requested color type, alpha type, and color
    space. The AsyncReadResult will have count() == 1. Upon failure the callback is called
    with nullptr for AsyncReadResult. For a GPU surface this flushes work but a submit must
    occur to guarantee a finite time before the callback is called.
    
    The data is valid for the lifetime of AsyncReadResult with the exception that if the
    SkSurface is GPU-backed the data is immediately invalidated if the context is abandoned
    or destroyed.
    
    @param info            info of the requested pixels
    @param srcRect         subrectangle of surface to read
    @param rescaleGamma    controls whether rescaling is done in the surface's gamma or whether
    the source data is transformed to a linear gamma before rescaling.
    @param rescaleMode     controls the technique of the rescaling
    @param callback        function to call with result of the read
    @param context         passed to callback
    */
    asyncRescaleAndReadPixels :: (this: *SkSurface, info: *SkImageInfo, srcRect: *SkIRect, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixels@SkSurface@@QEAAXAEBUSkImageInfo@@AEBUSkIRect@@W4RescaleGamma@SkImage@@W4RescaleMode@5@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z4@Z";
    asyncRescaleAndReadPixels :: (this: *SkSurface, info: SkImageInfo, srcRect: SkIRect, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixels(this, *info, *srcRect, rescaleGamma, rescaleMode, callback, _context);
    }

    /**
    Similar to asyncRescaleAndReadPixels but performs an additional conversion to YUV. The
    RGB->YUV conversion is controlled by 'yuvColorSpace'. The YUV data is returned as three
    planes ordered y, u, v. The u and v planes are half the width and height of the resized
    rectangle. The y, u, and v values are single bytes. Currently this fails if 'dstSize'
    width and height are not even. A 'srcRect' that is not contained by the bounds of the
    surface causes failure.
    
    When the pixel data is ready the caller's ReadPixelsCallback is called with a
    AsyncReadResult containing the planar data. The AsyncReadResult will have count() == 3.
    Upon failure the callback is called with nullptr for AsyncReadResult. For a GPU surface this
    flushes work but a submit must occur to guarantee a finite time before the callback is
    called.
    
    The data is valid for the lifetime of AsyncReadResult with the exception that if the
    SkSurface is GPU-backed the data is immediately invalidated if the context is abandoned
    or destroyed.
    
    @param yuvColorSpace  The transformation from RGB to YUV. Applied to the resized image
    after it is converted to dstColorSpace.
    @param dstColorSpace  The color space to convert the resized image to, after rescaling.
    @param srcRect        The portion of the surface to rescale and convert to YUV planes.
    @param dstSize        The size to rescale srcRect to
    @param rescaleGamma   controls whether rescaling is done in the surface's gamma or whether
    the source data is transformed to a linear gamma before rescaling.
    @param rescaleMode    controls the sampling technique of the rescaling
    @param callback       function to call with the planar read result
    @param context        passed to callback
    */
    asyncRescaleAndReadPixelsYUV420 :: (this: *SkSurface, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: *SkIRect, dstSize: *SkISize, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixelsYUV420@SkSurface@@QEAAXW4SkYUVColorSpace@@V?$sk_sp@VSkColorSpace@@@@AEBUSkIRect@@AEBUSkISize@@W4RescaleGamma@SkImage@@W4RescaleMode@7@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z6@Z";
    asyncRescaleAndReadPixelsYUV420 :: (this: *SkSurface, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: SkIRect, dstSize: SkISize, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixelsYUV420(this, yuvColorSpace, dstColorSpace, *srcRect, *dstSize, rescaleGamma, rescaleMode, callback, _context);
    }

    /**
    * Identical to asyncRescaleAndReadPixelsYUV420 but a fourth plane is returned in the
    * AsyncReadResult passed to 'callback'. The fourth plane contains the alpha chanel at the
    * same full resolution as the Y plane.
    */
    asyncRescaleAndReadPixelsYUVA420 :: (this: *SkSurface, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: *SkIRect, dstSize: *SkISize, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) -> void #cpp_method #foreign libskia "?asyncRescaleAndReadPixelsYUVA420@SkSurface@@QEAAXW4SkYUVColorSpace@@V?$sk_sp@VSkColorSpace@@@@AEBUSkIRect@@AEBUSkISize@@W4RescaleGamma@SkImage@@W4RescaleMode@7@P6AXPEAXV?$unique_ptr@$$CBVAsyncReadResult@SkImage@@U?$default_delete@$$CBVAsyncReadResult@SkImage@@@std@@@std@@@Z6@Z";
    asyncRescaleAndReadPixelsYUVA420 :: (this: *SkSurface, yuvColorSpace: SkYUVColorSpace, dstColorSpace: sk_sp(SkColorSpace), srcRect: SkIRect, dstSize: SkISize, rescaleGamma: SkSurface.RescaleGamma, rescaleMode: SkSurface.RescaleMode, callback: SkSurface.ReadPixelsCallback, _context: SkSurface.ReadPixelsContext) #no_context {
        asyncRescaleAndReadPixelsYUVA420(this, yuvColorSpace, dstColorSpace, *srcRect, *dstSize, rescaleGamma, rescaleMode, callback, _context);
    }

    /** Copies SkRect of pixels from the src SkPixmap to the SkSurface.
    
    Source SkRect corners are (0, 0) and (src.width(), src.height()).
    Destination SkRect corners are (dstX, dstY) and
    (dstX + Surface width(), dstY + Surface height()).
    
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to SkSurface colorType() and SkSurface alphaType() if required.
    
    @param src   storage for pixels to copy to SkSurface
    @param dstX  x-axis position relative to SkSurface to begin copy; may be negative
    @param dstY  y-axis position relative to SkSurface to begin copy; may be negative
    
    example: https://fiddle.skia.org/c/@Surface_writePixels
    */
    writePixels :: (this: *SkSurface, src: *SkPixmap, dstX: s32, dstY: s32) -> void #cpp_method #foreign libskia "?writePixels@SkSurface@@QEAAXAEBVSkPixmap@@HH@Z";
    writePixels :: (this: *SkSurface, src: SkPixmap, dstX: s32, dstY: s32) #no_context {
        writePixels(this, *src, dstX, dstY);
    }

    /** Copies SkRect of pixels from the src SkBitmap to the SkSurface.
    
    Source SkRect corners are (0, 0) and (src.width(), src.height()).
    Destination SkRect corners are (dstX, dstY) and
    (dstX + Surface width(), dstY + Surface height()).
    
    Copies each readable pixel intersecting both rectangles, without scaling,
    converting to SkSurface colorType() and SkSurface alphaType() if required.
    
    @param src   storage for pixels to copy to SkSurface
    @param dstX  x-axis position relative to SkSurface to begin copy; may be negative
    @param dstY  y-axis position relative to SkSurface to begin copy; may be negative
    
    example: https://fiddle.skia.org/c/@Surface_writePixels_2
    */
    writePixels :: (this: *SkSurface, src: *SkBitmap, dstX: s32, dstY: s32) -> void #cpp_method #foreign libskia "?writePixels@SkSurface@@QEAAXAEBVSkBitmap@@HH@Z";
    writePixels :: (this: *SkSurface, src: SkBitmap, dstX: s32, dstY: s32) #no_context {
        writePixels(this, *src, dstX, dstY);
    }

    /** Returns SkSurfaceProps for surface.
    
    @return  LCD striping orientation and setting for device independent fonts
    */
    props :: (this: *SkSurface) -> *SkSurfaceProps #cpp_method #foreign libskia "?props@SkSurface@@QEBAAEBVSkSurfaceProps@@XZ";

    /** Inserts a list of GPU semaphores that the current GPU-backed API must wait on before
    executing any more commands on the GPU for this surface. We only guarantee blocking
    transfer and fragment shader work, but may block earlier stages as well depending on the
    backend.
    If this call returns false, then the GPU back-end will not wait on any passed in
    semaphores, and the client will still own the semaphores, regardless of the value of
    deleteSemaphoresAfterWait.
    
    If deleteSemaphoresAfterWait is false then Skia will not delete the semaphores. In this case
    it is the client's responsibility to not destroy or attempt to reuse the semaphores until it
    knows that Skia has finished waiting on them. This can be done by using finishedProcs
    on flush calls.
    
    @param numSemaphores               size of waitSemaphores array
    @param waitSemaphores              array of semaphore containers
    @paramm deleteSemaphoresAfterWait  who owns and should delete the semaphores
    @return                            true if GPU is waiting on semaphores
    */
    wait :: (this: *SkSurface, numSemaphores: s32, waitSemaphores: *GrBackendSemaphore, deleteSemaphoresAfterWait := true) -> bool #cpp_method #foreign libskia "?wait@SkSurface@@QEAA_NHPEBVGrBackendSemaphore@@_N@Z";

    /** Initializes GrSurfaceCharacterization that can be used to perform GPU back-end
    processing in a separate thread. Typically this is used to divide drawing
    into multiple tiles. GrDeferredDisplayListRecorder records the drawing commands
    for each tile.
    
    Return true if SkSurface supports characterization. raster surface returns false.
    
    @param characterization  properties for parallel drawing
    @return                  true if supported
    
    example: https://fiddle.skia.org/c/@Surface_characterize
    */
    characterize :: (this: *SkSurface, characterization: *GrSurfaceCharacterization) -> bool #cpp_method #foreign libskia "?characterize@SkSurface@@QEBA_NPEAVGrSurfaceCharacterization@@@Z";

    Constructor :: (this: *SkSurface, width: s32, height: s32, surfaceProps: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkSurface@@IEAA@HHPEBVSkSurfaceProps@@@Z";
    Constructor :: (this: *SkSurface, imageInfo: *SkImageInfo, surfaceProps: *SkSurfaceProps) -> void #cpp_method #foreign libskia "??0SkSurface@@IEAA@AEBUSkImageInfo@@PEBVSkSurfaceProps@@@Z";
    Constructor :: (this: *SkSurface, imageInfo: SkImageInfo, surfaceProps: *SkSurfaceProps) #no_context {
        Constructor(this, *imageInfo, surfaceProps);
    }

    // called by subclass if their contents have changed
    dirtyGenerationID :: (this: *SkSurface) -> void #cpp_method #foreign libskia "?dirtyGenerationID@SkSurface@@IEAAXXZ";

    fGenerationID:                     u32 #align 8;

    INHERITED :: SkRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Returns an ImageInfo describing the surface.
    */
    virtual_imageInfo :: (this: *SkSurface) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?imageInfo@SkSurface@@UEBA?AUSkImageInfo@@XZ";

    /** If the surface was made via MakeFromBackendTexture then it's backing texture may be
    substituted with a different texture. The contents of the previous backing texture are
    copied into the new texture. SkCanvas state is preserved. The original sample count is
    used. The GrBackendFormat and dimensions of replacement texture must match that of
    the original.
    
    Upon success textureReleaseProc is called when it is safe to delete the texture in the
    backend API (accounting only for use of the texture by this surface). If SkSurface creation
    fails textureReleaseProc is called before this function returns.
    
    @param backendTexture      the new backing texture for the surface
    @param mode                Retain or discard current Content
    @param TextureReleaseProc  function called when texture can be released
    @param ReleaseContext      state passed to textureReleaseProc
    */
//     virtual_replaceBackendTexture :: (this: *SkSurface, backendTexture: *GrBackendTexture, origin: GrSurfaceOrigin, mode: SkSurface.ContentChangeMode = .Retain_ContentChangeMode, unknown0: SkSurface.TextureReleaseProc = null, unknown1: SkSurface.ReleaseContext = null) -> bool #cpp_method #foreign libskia "?replaceBackendTexture@SkSurface@@UEAA_NAEBVGrBackendTexture@@W4GrSurfaceOrigin@@W4ContentChangeMode@1@P6AXPEAX@Z3@Z";
}
SkSurface_VTable :: struct #type_info_none {
    using vtable:          SkRefCntBase_VTable;

    imageInfo:             #type (this: *SkSurface) -> SkImageInfo #cpp_method #cpp_return_type_is_non_pod;

    replaceBackendTexture: #type (this: *SkSurface, backendTexture: *GrBackendTexture, origin: GrSurfaceOrigin, mode: SkSurface.ContentChangeMode = .Retain_ContentChangeMode, unknown0: SkSurface.TextureReleaseProc = null, unknown1: SkSurface.ReleaseContext = null) -> bool #cpp_method;
}
SkSurface_imageInfo :: inline (this: *SkSurface) -> SkImageInfo { return this.vtable.imageInfo(this); }

SkSurface_replaceBackendTexture :: inline (this: *SkSurface, backendTexture: *GrBackendTexture, origin: GrSurfaceOrigin, mode: SkSurface.ContentChangeMode = .Retain_ContentChangeMode, unknown0: SkSurface.TextureReleaseProc = null, unknown1: SkSurface.ReleaseContext = null) -> bool { return this.vtable.replaceBackendTexture(this, backendTexture, origin, mode, unknown0, unknown1); }

get_vtable :: (obj: *SkSurface) -> *SkSurface_VTable { return obj.vtable; }


/**
*  SkData holds a data buffer. It can be created to allocate its own buffer
*  for the contents, or to share a pointer to the client's buffer. The size and
*  address of the contents never change for the lifetime of the data object.
*/
SkData :: struct {
    #as using sknvrefcnt: SkNVRefCnt(SkData);

    /**
    * Calls == operator, but first checks if other is null (in which case it returns false)
    */
    equals :: (this: *SkData, other: *SkData) -> bool #cpp_method #foreign libskia "?equals@SkData@@QEBA_NPEBV1@@Z";

    /**
    * Return true if both arguments are the same size and contain the same bytes, or if both
    * arguments are null.
    */
    Equals :: (a: *SkData, b: *SkData) -> bool #foreign libskia "?Equals@SkData@@SA_NPEBV1@0@Z";

    /**
    *  Returns the number of bytes stored.
    */
    size :: (this: *SkData) -> u64 #cpp_method #foreign libskia "?size@SkData@@QEBA_KXZ";

    /**
    *  Returns the ptr to the data.
    */
    data :: (this: *SkData) -> *void #cpp_method #foreign libskia "?data@SkData@@QEBAPEBXXZ";

    empty :: (this: *SkData) -> bool #cpp_method #foreign libskia "?empty@SkData@@QEBA_NXZ";

    bytes :: (this: *SkData) -> *u8 #cpp_method #foreign libskia "?bytes@SkData@@QEBAPEBEXZ";

    byteSpan :: (this: *SkData) -> SkSpan(u8) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?byteSpan@SkData@@QEBA?AV?$SkSpan@$$CBE@@XZ";

    /**
    *  USE WITH CAUTION.
    *  Be sure other 'owners' of this object are not accessing it in aother thread.
    */
    writable_data :: (this: *SkData) -> *void #cpp_method #foreign libskia "?writable_data@SkData@@QEAAPEAXXZ";

    /** Attempt to create a deep copy of the original data, using the default allocator.
    *
    *  If  offset+length > this->size(), then this returns nullptr.
    */
    copySubset :: (this: *SkData, offset: u64, length: u64) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?copySubset@SkData@@QEBA?AV?$sk_sp@VSkData@@@@_K0@Z";

    /** Attempt to return a data that is a reference to a subset of the original data,
    *  This will never make a deep copy of the contents, but will retain a reference
    *  to the original data object.
    *
    *  If  offset+length > this->size(), then this returns nullptr.
    */
    shareSubset :: (this: *SkData, offset: u64, length: u64) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?shareSubset@SkData@@QEAA?AV?$sk_sp@VSkData@@@@_K0@Z";
//     shareSubset_1 :: (this: /*const*/ *SkData, offset: u64, length: u64) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?shareSubset@SkData@@QEBA?AV?$sk_sp@$$CBVSkData@@@@_K0@Z";

    /**
    *  Helper to copy a range of the data into a caller-provided buffer.
    *  Returns the actual number of bytes copied, after clamping offset and
    *  length to the size of this data. If buffer is NULL, it is ignored, and
    *  only the computed number of bytes is returned.
    */
    copyRange :: (this: *SkData, offset: u64, length: u64, buffer: *void) -> u64 #cpp_method #foreign libskia "?copyRange@SkData@@QEBA_K_K0PEAX@Z";

    /**
    *  Function that, if provided, will be called when the SkData goes out
    *  of scope, allowing for custom allocation/freeing of the data's contents.
    */
    ReleaseProc :: #type (ptr: *void, _context: *void) -> void #c_call;

    /**
    *  Create a new dataref by copying the specified data
    */
    MakeWithCopy :: (data: *void, length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeWithCopy@SkData@@SA?AV?$sk_sp@VSkData@@@@PEBX_K@Z";

    /**
    *  Create a new data with uninitialized contents. The caller should call writable_data()
    *  to write into the buffer, but this must be done before another ref() is made.
    */
    MakeUninitialized :: (length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeUninitialized@SkData@@SA?AV?$sk_sp@VSkData@@@@_K@Z";

    /**
    *  Create a new data with zero-initialized contents. The caller should call writable_data()
    *  to write into the buffer, but this must be done before another ref() is made.
    */
    MakeZeroInitialized :: (length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeZeroInitialized@SkData@@SA?AV?$sk_sp@VSkData@@@@_K@Z";

    /**
    *  Create a new dataref by copying the specified c-string
    *  (a null-terminated array of bytes). The returned SkData will have size()
    *  equal to strlen(cstr) + 1. If cstr is NULL, it will be treated the same
    *  as "".
    */
    MakeWithCString :: (cstr: *u8) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeWithCString@SkData@@SA?AV?$sk_sp@VSkData@@@@QEBD@Z";

    /**
    *  Create a new dataref, taking the ptr as is, and using the
    *  releaseproc to free it. The proc may be NULL.
    */
    MakeWithProc :: (ptr: *void, length: u64, proc: ReleaseProc, ctx: *void) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeWithProc@SkData@@SA?AV?$sk_sp@VSkData@@@@PEBX_KP6AX0PEAX@Z2@Z";

    /**
    *  Call this when the data parameter is already const and will outlive the lifetime of the
    *  SkData. Suitable for globals.
    */
    MakeWithoutCopy :: (data: *void, length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeWithoutCopy@SkData@@SA?AV?$sk_sp@VSkData@@@@PEBX_K@Z";

    /**
    *  Create a new dataref from a pointer allocated by malloc. The Data object
    *  takes ownership of that allocation, and will handling calling sk_free.
    */
    MakeFromMalloc :: (data: *void, length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromMalloc@SkData@@SA?AV?$sk_sp@VSkData@@@@PEBX_K@Z";

    /**
    *  Create a new dataref the file with the specified path.
    *  If the file cannot be opened, this returns NULL.
    */
    MakeFromFileName :: (path: *u8) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromFileName@SkData@@SA?AV?$sk_sp@VSkData@@@@QEBD@Z";

    /**
    *  Create a new dataref from a stdio FILE.
    *  This does not take ownership of the FILE, nor close it.
    *  The caller is free to close the FILE at its convenience.
    *  The FILE must be open for reading only.
    *  Returns NULL on failure.
    */
    MakeFromFILE :: (f: *FILE) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromFILE@SkData@@SA?AV?$sk_sp@VSkData@@@@PEAU_iobuf@@@Z";

    /**
    *  Create a new dataref from a file descriptor.
    *  This does not take ownership of the file descriptor, nor close it.
    *  The caller is free to close the file descriptor at its convenience.
    *  The file descriptor must be open for reading only.
    *  Returns NULL on failure.
    */
    MakeFromFD :: (fd: s32) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromFD@SkData@@SA?AV?$sk_sp@VSkData@@@@H@Z";

    /**
    *  Attempt to read size bytes into a SkData. If the read succeeds, return the data,
    *  else return NULL. Either way the stream's cursor may have been changed as a result
    *  of calling read().
    */
    MakeFromStream :: (unknown0: *SkStream, size: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromStream@SkData@@SA?AV?$sk_sp@VSkData@@@@PEAVSkStream@@_K@Z";

    /**
    *  DEPRECATED variant of src->shareSubset(offset, length)
    *
    *  This variant checks if shaerSubset() returned null (because offset or length were out-of-range)
    *  and returns an empty SkData, rather than returning null.
    */
    MakeSubset :: (src: *SkData, offset: u64, length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeSubset@SkData@@SA?AV?$sk_sp@VSkData@@@@PEBV1@_K1@Z";

    /**
    *  Returns a new empty dataref (or a reference to a shared empty dataref).
    *  New or shared, the caller must see that unref() is eventually called.
    */
    MakeEmpty :: () -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?MakeEmpty@SkData@@SA?AV?$sk_sp@VSkData@@@@XZ";

    /**
    *  DEPRECATED -- use empty()
    */
    isEmpty :: (this: *SkData) -> bool #cpp_method #foreign libskia "?isEmpty@SkData@@QEBA_NXZ";

    fReleaseProc:         ReleaseProc;
    fReleaseProcContext:  *void;
    fSpan:                SkSpan(std.byte);

    Constructor :: (this: *SkData, unknown0: SkSpan(std.byte), unknown1: ReleaseProc, _context: *void) -> void #cpp_method #foreign libskia "??0SkData@@AEAA@V?$SkSpan@W4byte@std@@@@P6AXPEBXPEAX@Z2@Z";
    Constructor :: (this: *SkData, size: u64) -> void #cpp_method #foreign libskia "??0SkData@@AEAA@_K@Z";
    Destructor :: (this: *SkData) -> void #cpp_method #foreign libskia "??1SkData@@AEAA@XZ";

    // shared internal factory
    PrivateNewWithCopy :: (srcOrNull: *void, length: u64) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?PrivateNewWithCopy@SkData@@CA?AV?$sk_sp@VSkData@@@@PEBX_K@Z";

    NoopReleaseProc :: (unknown0: *void, unknown1: *void) -> void #foreign libskia "?NoopReleaseProc@SkData@@CAXPEBXPEAX@Z";

    INHERITED :: SkRefCnt;
}

/**
*  Returns true if this and rhs are the same size, and contain the same contents.
*  All empty objects compare as equal.
*/
operator_eq :: (this: *SkData, rhs: *SkData) -> bool #cpp_method #foreign libskia "??8SkData@@QEBA_NAEBV0@@Z";
operator_eq :: (this: SkData, rhs: SkData) -> bool #no_context {
    return operator_eq(*this, *rhs);
}
operator_neq :: (this: *SkData, rhs: *SkData) -> bool #cpp_method #foreign libskia "??9SkData@@QEBA_NAEBV0@@Z";
operator_neq :: (this: SkData, rhs: SkData) -> bool #no_context {
    return operator_neq(*this, *rhs);
}

// Ensure the unsized delete is called.
operatordelete :: (this: *SkData, p: *void) -> void #cpp_method #foreign libskia "??3SkData@@CAXPEAX@Z";
operatordelete :: (this: SkData, p: *void) #no_context {
    operatordelete(*this, p);
}

/**
*  SkStream -- abstraction for a source of bytes. Subclasses can be backed by
*  memory, or a file, or something else.
*/
SkStream :: struct {
    vtable: *SkStream_VTable;

    Constructor :: (this: *SkStream) -> void #cpp_method #foreign libskia "??0SkStream@@QEAA@XZ";

    /**
    *  Attempts to open the specified file as a stream, returns nullptr on failure.
    */
    MakeFromFile :: (path: *u8) -> std.unique_ptr(SkStreamAsset) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromFile@SkStream@@SA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@QEBD@Z";

    /** Skip size number of bytes.
    *  @return the actual number bytes that could be skipped.
    */
    skip :: (this: *SkStream, size: u64) -> u64 #cpp_method #foreign libskia "?skip@SkStream@@QEAA_K_K@Z";

    readS8 :: (this: *SkStream, unknown0: *s8) -> bool #cpp_method #foreign libskia "?readS8@SkStream@@QEAA_NPEAC@Z";
    readS16 :: (this: *SkStream, unknown0: *s16) -> bool #cpp_method #foreign libskia "?readS16@SkStream@@QEAA_NPEAF@Z";
    readS32 :: (this: *SkStream, unknown0: *s32) -> bool #cpp_method #foreign libskia "?readS32@SkStream@@QEAA_NPEAH@Z";
    readS64 :: (this: *SkStream, unknown0: *s64) -> bool #cpp_method #foreign libskia "?readS64@SkStream@@QEAA_NPEA_J@Z";

    readU8 :: (this: *SkStream, i: *u8) -> bool #cpp_method #foreign libskia "?readU8@SkStream@@QEAA_NPEAE@Z";
    readU16 :: (this: *SkStream, i: *u16) -> bool #cpp_method #foreign libskia "?readU16@SkStream@@QEAA_NPEAG@Z";
    readU32 :: (this: *SkStream, i: *u32) -> bool #cpp_method #foreign libskia "?readU32@SkStream@@QEAA_NPEAI@Z";
    readU64 :: (this: *SkStream, i: *u64) -> bool #cpp_method #foreign libskia "?readU64@SkStream@@QEAA_NPEA_K@Z";

    readBool :: (this: *SkStream, b: *bool) -> bool #cpp_method #foreign libskia "?readBool@SkStream@@QEAA_NPEA_N@Z";

    readScalar :: (this: *SkStream, unknown0: *SkScalar) -> bool #cpp_method #foreign libskia "?readScalar@SkStream@@QEAA_NPEAM@Z";
    readPackedUInt :: (this: *SkStream, unknown0: *u64) -> bool #cpp_method #foreign libskia "?readPackedUInt@SkStream@@QEAA_NPEA_K@Z";

    /** Duplicates this stream. If this cannot be done, returns NULL.
    *  The returned stream will be positioned at the beginning of its data.
    */
    duplicate :: (this: *SkStream) -> std.unique_ptr(SkStream) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkStream@@QEBA?AV?$unique_ptr@VSkStream@@U?$default_delete@VSkStream@@@std@@@std@@XZ";

    /** Duplicates this stream. If this cannot be done, returns NULL.
    *  The returned stream will be positioned the same as this stream.
    */
    fork :: (this: *SkStream) -> std.unique_ptr(SkStream) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkStream@@QEBA?AV?$unique_ptr@VSkStream@@U?$default_delete@VSkStream@@@std@@@std@@XZ";

//     CopyConstructor :: (this: *SkStream, unknown0: *SkStream) -> void #cpp_method #foreign libskia "??0SkStream@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkStream, unknown0: SkStream) #no_context {
        CopyConstructor(this, *unknown0);
    }

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkStream@@UEAA@XZ";

    /** Reads or skips size number of bytes.
    *  If buffer == NULL, skip size bytes, return how many were skipped.
    *  If buffer != NULL, copy size bytes into buffer, return how many were copied.
    *  @param buffer when NULL skip size bytes, otherwise copy size bytes into buffer
    *  @param size the number of bytes to skip or copy
    *  @return the number of bytes actually read.
    */
//     virtual_read :: (this: *SkStream, buffer: *void, size: u64) -> u64 #cpp_method #foreign libskia "?read@SkStream@@UEAA_KPEAX_K@Z";

    /**
    *  Attempt to peek at size bytes.
    *  If this stream supports peeking, copy min(size, peekable bytes) into
    *  buffer, and return the number of bytes copied.
    *  If the stream does not support peeking, or cannot peek any bytes,
    *  return 0 and leave buffer unchanged.
    *  The stream is guaranteed to be in the same visible state after this
    *  call, regardless of success or failure.
    *  @param buffer Must not be NULL, and must be at least size bytes. Destination
    *      to copy bytes.
    *  @param size Number of bytes to copy.
    *  @return The number of bytes peeked/copied.
    */
    virtual_peek :: (this: *SkStream, unknown0: *void, unknown1: u64) -> u64 #cpp_method #foreign libskia "?peek@SkStream@@UEBA_KPEAX_K@Z";

    /** Returns true when all the bytes in the stream have been read.
    *  As SkStream represents synchronous I/O, isAtEnd returns false when the
    *  final stream length isn't known yet, even when all the bytes available
    *  so far have been read.
    *  This may return true early (when there are no more bytes to be read)
    *  or late (after the first unsuccessful read).
    */
//     virtual_isAtEnd :: (this: *SkStream) -> bool #cpp_method #foreign libskia "?isAtEnd@SkStream@@UEBA_NXZ";

    //SkStreamRewindable
    /** Rewinds to the beginning of the stream. Returns true if the stream is known
    *  to be at the beginning after this call returns.
    */
    virtual_rewind :: (this: *SkStream) -> bool #cpp_method #foreign libskia "?rewind@SkStream@@UEAA_NXZ";

    //SkStreamSeekable
    /** Returns true if this stream can report its current position. */
    virtual_hasPosition :: (this: *SkStream) -> bool #cpp_method #foreign libskia "?hasPosition@SkStream@@UEBA_NXZ";

    /** Returns the current position in the stream. If this cannot be done, returns 0. */
    virtual_getPosition :: (this: *SkStream) -> u64 #cpp_method #foreign libskia "?getPosition@SkStream@@UEBA_KXZ";

    /** Seeks to an absolute position in the stream. If this cannot be done, returns false.
    *  If an attempt is made to seek past the end of the stream, the position will be set
    *  to the end of the stream.
    */
    virtual_seek :: (this: *SkStream, unknown0: u64) -> bool #cpp_method #foreign libskia "?seek@SkStream@@UEAA_N_K@Z";

    /** Seeks to an relative offset in the stream. If this cannot be done, returns false.
    *  If an attempt is made to move to a position outside the stream, the position will be set
    *  to the closest point within the stream (beginning or end).
    */
    virtual_move :: (this: *SkStream, unknown0: s32) -> bool #cpp_method #foreign libskia "?move@SkStream@@UEAA_NJ@Z";

    //SkStreamAsset
    /** Returns true if this stream can report its total length. */
    virtual_hasLength :: (this: *SkStream) -> bool #cpp_method #foreign libskia "?hasLength@SkStream@@UEBA_NXZ";

    /** Returns the total length of the stream. If this cannot be done, returns 0. */
    virtual_getLength :: (this: *SkStream) -> u64 #cpp_method #foreign libskia "?getLength@SkStream@@UEBA_KXZ";

    //SkStreamMemory
    /** Returns the starting address for the data. If this cannot be done, returns NULL. */
    virtual_getMemoryBase :: (this: *SkStream) -> *void #cpp_method #foreign libskia "?getMemoryBase@SkStream@@UEAAPEBXXZ";
    virtual_getData :: (this: *SkStream) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getData@SkStream@@UEBA?AV?$sk_sp@$$CBVSkData@@@@XZ";

    virtual_onDuplicate :: (this: *SkStream) -> *SkStream #cpp_method #foreign libskia "?onDuplicate@SkStream@@EEBAPEAV1@XZ";
    virtual_onFork :: (this: *SkStream) -> *SkStream #cpp_method #foreign libskia "?onFork@SkStream@@EEBAPEAV1@XZ";
}
SkStream_VTable :: struct #type_info_none {
    Destructor:    #type (this: *SkStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    read:          #type (this: *SkStream, buffer: *void, size: u64) -> u64 #cpp_method;

    peek:          #type (this: *SkStream, unknown0: *void, unknown1: u64) -> u64 #cpp_method;

    isAtEnd:       #type (this: *SkStream) -> bool #cpp_method;

    rewind:        #type (this: *SkStream) -> bool #cpp_method;

    hasPosition:   #type (this: *SkStream) -> bool #cpp_method;

    getPosition:   #type (this: *SkStream) -> u64 #cpp_method;

    seek:          #type (this: *SkStream, unknown0: u64) -> bool #cpp_method;

    move:          #type (this: *SkStream, unknown0: s32) -> bool #cpp_method;

    hasLength:     #type (this: *SkStream) -> bool #cpp_method;

    getLength:     #type (this: *SkStream) -> u64 #cpp_method;

    getMemoryBase: #type (this: *SkStream) -> *void #cpp_method;
    getData:       #type (this: *SkStream) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod;

    onDuplicate:   #type (this: *SkStream) -> *SkStream #cpp_method;
    onFork:        #type (this: *SkStream) -> *SkStream #cpp_method;
}
SkStream_Destructor :: inline (this: *SkStream, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkStream_read :: inline (this: *SkStream, buffer: *void, size: u64) -> u64 { return this.vtable.read(this, buffer, size); }

SkStream_peek :: inline (this: *SkStream, unknown0: *void, unknown1: u64) -> u64 { return this.vtable.peek(this, unknown0, unknown1); }

SkStream_isAtEnd :: inline (this: *SkStream) -> bool { return this.vtable.isAtEnd(this); }

SkStream_rewind :: inline (this: *SkStream) -> bool { return this.vtable.rewind(this); }

SkStream_hasPosition :: inline (this: *SkStream) -> bool { return this.vtable.hasPosition(this); }

SkStream_getPosition :: inline (this: *SkStream) -> u64 { return this.vtable.getPosition(this); }

SkStream_seek :: inline (this: *SkStream, unknown0: u64) -> bool { return this.vtable.seek(this, unknown0); }

SkStream_move :: inline (this: *SkStream, unknown0: s32) -> bool { return this.vtable.move(this, unknown0); }

SkStream_hasLength :: inline (this: *SkStream) -> bool { return this.vtable.hasLength(this); }

SkStream_getLength :: inline (this: *SkStream) -> u64 { return this.vtable.getLength(this); }

SkStream_getMemoryBase :: inline (this: *SkStream) -> *void { return this.vtable.getMemoryBase(this); }
SkStream_getData :: inline (this: *SkStream) -> sk_sp(SkData) { return this.vtable.getData(this); }

SkStream_onDuplicate :: inline (this: *SkStream) -> *SkStream { return this.vtable.onDuplicate(this); }
SkStream_onFork :: inline (this: *SkStream) -> *SkStream { return this.vtable.onFork(this); }

get_vtable :: (obj: *SkStream) -> *SkStream_VTable { return obj.vtable; }


// operator_assign :: (this: *SkStream, unknown0: *SkStream) -> *SkStream #cpp_method #foreign libskia "??4SkStream@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkStream, unknown0: SkStream) -> *SkStream #no_context {
    return operator_assign(this, *unknown0);
}

/** SkStreamRewindable is a SkStream for which rewind and duplicate are required. */
SkStreamRewindable :: struct {
    vtable: *SkStream_VTable;

    duplicate :: (this: *SkStreamRewindable) -> std.unique_ptr(SkStreamRewindable) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkStreamRewindable@@QEBA?AV?$unique_ptr@VSkStreamRewindable@@U?$default_delete@VSkStreamRewindable@@@std@@@std@@XZ";
    #place vtable; #as skstream: SkStream; // Support cast to SkStream

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

//     virtual_rewind :: (this: *SkStreamRewindable) -> bool #cpp_method #foreign libskia "?rewind@SkStreamRewindable@@UEAA_NXZ";

//     virtual_onDuplicate :: (this: *SkStreamRewindable) -> *SkStreamRewindable #cpp_method #foreign libskia "?onDuplicate@SkStreamRewindable@@EEBAPEAV1@XZ";
}

/** SkStreamSeekable is a SkStreamRewindable for which position, seek, move, and fork are required. */
SkStreamSeekable :: struct {
    vtable: *SkStream_VTable;

    duplicate :: (this: *SkStreamSeekable) -> std.unique_ptr(SkStreamSeekable) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkStreamSeekable@@QEBA?AV?$unique_ptr@VSkStreamSeekable@@U?$default_delete@VSkStreamSeekable@@@std@@@std@@XZ";

    fork :: (this: *SkStreamSeekable) -> std.unique_ptr(SkStreamSeekable) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkStreamSeekable@@QEBA?AV?$unique_ptr@VSkStreamSeekable@@U?$default_delete@VSkStreamSeekable@@@std@@@std@@XZ";
    #place vtable; #as skstreamrewindable: SkStreamRewindable; // Support cast to SkStreamRewindable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_hasPosition :: (this: *SkStreamSeekable) -> bool #cpp_method #foreign libskia "?hasPosition@SkStreamSeekable@@UEBA_NXZ";
//     virtual_getPosition :: (this: *SkStreamSeekable) -> u64 #cpp_method #foreign libskia "?getPosition@SkStreamSeekable@@UEBA_KXZ";
//     virtual_seek :: (this: *SkStreamSeekable, position: u64) -> bool #cpp_method #foreign libskia "?seek@SkStreamSeekable@@UEAA_N_K@Z";
//     virtual_move :: (this: *SkStreamSeekable, offset: s32) -> bool #cpp_method #foreign libskia "?move@SkStreamSeekable@@UEAA_NJ@Z";

//     virtual_onDuplicate :: (this: *SkStreamSeekable) -> *SkStreamSeekable #cpp_method #foreign libskia "?onDuplicate@SkStreamSeekable@@EEBAPEAV1@XZ";
//     virtual_onFork :: (this: *SkStreamSeekable) -> *SkStreamSeekable #cpp_method #foreign libskia "?onFork@SkStreamSeekable@@EEBAPEAV1@XZ";
}

/** SkStreamAsset is a SkStreamSeekable for which getLength is required. */
SkStreamAsset :: struct {
    vtable: *SkStream_VTable;

    duplicate :: (this: *SkStreamAsset) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkStreamAsset@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@XZ";

    fork :: (this: *SkStreamAsset) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkStreamAsset@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@XZ";
    #place vtable; #as skstreamseekable: SkStreamSeekable; // Support cast to SkStreamSeekable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_hasLength :: (this: *SkStreamAsset) -> bool #cpp_method #foreign libskia "?hasLength@SkStreamAsset@@UEBA_NXZ";
//     virtual_getLength :: (this: *SkStreamAsset) -> u64 #cpp_method #foreign libskia "?getLength@SkStreamAsset@@UEBA_KXZ";

//     virtual_onDuplicate :: (this: *SkStreamAsset) -> *SkStreamAsset #cpp_method #foreign libskia "?onDuplicate@SkStreamAsset@@EEBAPEAV1@XZ";
//     virtual_onFork :: (this: *SkStreamAsset) -> *SkStreamAsset #cpp_method #foreign libskia "?onFork@SkStreamAsset@@EEBAPEAV1@XZ";
}

/** SkStreamMemory is a SkStreamAsset for which getMemoryBase is required. */
SkStreamMemory :: struct {
    vtable: *SkStream_VTable;

    duplicate :: (this: *SkStreamMemory) -> std.unique_ptr(SkStreamMemory) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkStreamMemory@@QEBA?AV?$unique_ptr@VSkStreamMemory@@U?$default_delete@VSkStreamMemory@@@std@@@std@@XZ";

    fork :: (this: *SkStreamMemory) -> std.unique_ptr(SkStreamMemory) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkStreamMemory@@QEBA?AV?$unique_ptr@VSkStreamMemory@@U?$default_delete@VSkStreamMemory@@@std@@@std@@XZ";
    #place vtable; #as skstreamasset: SkStreamAsset; // Support cast to SkStreamAsset

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

//     virtual_getMemoryBase :: (this: *SkStreamMemory) -> *void #cpp_method #foreign libskia "?getMemoryBase@SkStreamMemory@@UEAAPEBXXZ";

//     virtual_onDuplicate :: (this: *SkStreamMemory) -> *SkStreamMemory #cpp_method #foreign libskia "?onDuplicate@SkStreamMemory@@EEBAPEAV1@XZ";
//     virtual_onFork :: (this: *SkStreamMemory) -> *SkStreamMemory #cpp_method #foreign libskia "?onFork@SkStreamMemory@@EEBAPEAV1@XZ";
}

SkWStream :: struct {
    vtable: *SkWStream_VTable;

    Constructor :: (this: *SkWStream) -> void #cpp_method #foreign libskia "??0SkWStream@@QEAA@XZ";

    // helpers
    write8 :: (this: *SkWStream, value: U8CPU) -> bool #cpp_method #foreign libskia "?write8@SkWStream@@QEAA_NI@Z";

    write16 :: (this: *SkWStream, value: U16CPU) -> bool #cpp_method #foreign libskia "?write16@SkWStream@@QEAA_NI@Z";

    write32 :: (this: *SkWStream, value: u32) -> bool #cpp_method #foreign libskia "?write32@SkWStream@@QEAA_NI@Z";

    write64 :: (this: *SkWStream, value: u64) -> bool #cpp_method #foreign libskia "?write64@SkWStream@@QEAA_N_K@Z";

    writeText :: (this: *SkWStream, text: *u8) -> bool #cpp_method #foreign libskia "?writeText@SkWStream@@QEAA_NQEBD@Z";

    newline :: (this: *SkWStream) -> bool #cpp_method #foreign libskia "?newline@SkWStream@@QEAA_NXZ";

    writeDecAsText :: (this: *SkWStream, unknown0: s32) -> bool #cpp_method #foreign libskia "?writeDecAsText@SkWStream@@QEAA_NH@Z";
    writeBigDecAsText :: (this: *SkWStream, unknown0: s64, minDigits: s32 = 0) -> bool #cpp_method #foreign libskia "?writeBigDecAsText@SkWStream@@QEAA_N_JH@Z";
    writeHexAsText :: (this: *SkWStream, unknown0: u32, minDigits: s32 = 0) -> bool #cpp_method #foreign libskia "?writeHexAsText@SkWStream@@QEAA_NIH@Z";
    writeScalarAsText :: (this: *SkWStream, unknown0: SkScalar) -> bool #cpp_method #foreign libskia "?writeScalarAsText@SkWStream@@QEAA_NM@Z";

    writeBool :: (this: *SkWStream, v: bool) -> bool #cpp_method #foreign libskia "?writeBool@SkWStream@@QEAA_N_N@Z";
    writeScalar :: (this: *SkWStream, unknown0: SkScalar) -> bool #cpp_method #foreign libskia "?writeScalar@SkWStream@@QEAA_NM@Z";
    writePackedUInt :: (this: *SkWStream, unknown0: u64) -> bool #cpp_method #foreign libskia "?writePackedUInt@SkWStream@@QEAA_N_K@Z";

    writeStream :: (this: *SkWStream, input: *SkStream, length: u64) -> bool #cpp_method #foreign libskia "?writeStream@SkWStream@@QEAA_NPEAVSkStream@@_K@Z";

    /**
    * This returns the number of bytes in the stream required to store
    * 'value'.
    */
    SizeOfPackedUInt :: (value: u64) -> s32 #foreign libskia "?SizeOfPackedUInt@SkWStream@@SAH_K@Z";

//     CopyConstructor :: (this: *SkWStream, unknown0: *SkWStream) -> void #cpp_method #foreign libskia "??0SkWStream@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkWStream, unknown0: SkWStream) #no_context {
        CopyConstructor(this, *unknown0);
    }

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkWStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkWStream@@UEAA@XZ";

    /** Called to write bytes to a SkWStream. Returns true on success
    @param buffer the address of at least size bytes to be written to the stream
    @param size The number of bytes in buffer to write to the stream
    @return true on success
    */
//     virtual_write :: (this: *SkWStream, buffer: *void, size: u64) -> bool #cpp_method #foreign libskia "?write@SkWStream@@UEAA_NPEBX_K@Z";
    virtual_flush :: (this: *SkWStream) -> void #cpp_method #foreign libskia "?flush@SkWStream@@UEAAXXZ";

//     virtual_bytesWritten :: (this: *SkWStream) -> u64 #cpp_method #foreign libskia "?bytesWritten@SkWStream@@UEBA_KXZ";
}
SkWStream_VTable :: struct #type_info_none {
    Destructor:   #type (this: *SkWStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    write:        #type (this: *SkWStream, buffer: *void, size: u64) -> bool #cpp_method;
    flush:        #type (this: *SkWStream) -> void #cpp_method;

    bytesWritten: #type (this: *SkWStream) -> u64 #cpp_method;
}
SkWStream_Destructor :: inline (this: *SkWStream, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkWStream_write :: inline (this: *SkWStream, buffer: *void, size: u64) -> bool { return this.vtable.write(this, buffer, size); }
SkWStream_flush :: inline (this: *SkWStream) { this.vtable.flush(this); }

SkWStream_bytesWritten :: inline (this: *SkWStream) -> u64 { return this.vtable.bytesWritten(this); }

get_vtable :: (obj: *SkWStream) -> *SkWStream_VTable { return obj.vtable; }


// operator_assign :: (this: *SkWStream, unknown0: *SkWStream) -> *SkWStream #cpp_method #foreign libskia "??4SkWStream@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkWStream, unknown0: SkWStream) -> *SkWStream #no_context {
    return operator_assign(this, *unknown0);
}

SkNullWStream :: struct {
    vtable:                   *SkWStream_VTable;
    using sknullwstream__raw: SkNullWStream__RAW;
    #place vtable; #as skwstream: SkWStream; // Support cast to SkWStream
}
// SkNullWStream without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkNullWStream
SkNullWStream__RAW :: struct {
    Constructor :: (this: *SkNullWStream) -> void #cpp_method #foreign libskia "??0SkNullWStream@@QEAA@XZ";

    fBytesWritten: u64;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_write :: (this: *SkNullWStream, unknown0: *void, n: u64) -> bool #cpp_method #foreign libskia "?write@SkNullWStream@@UEAA_NPEBX_K@Z";
    virtual_flush :: (this: *SkNullWStream) -> void #cpp_method #foreign libskia "?flush@SkNullWStream@@UEAAXXZ";
    virtual_bytesWritten :: (this: *SkNullWStream) -> u64 #cpp_method #foreign libskia "?bytesWritten@SkNullWStream@@UEBA_KXZ";
}

/** A stream that wraps a C FILE* file stream. */
SkFILEStream :: struct {
    vtable:                  *SkStream_VTable;
    using skfilestream__raw: SkFILEStream__RAW;
    #place vtable; #as skstreamasset: SkStreamAsset; // Support cast to SkStreamAsset
}
// SkFILEStream without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFILEStream
SkFILEStream__RAW :: struct {
    /** Initialize the stream by calling sk_fopen on the specified path.
    *  This internal stream will be closed in the destructor.
    */
    Constructor :: (this: *SkFILEStream, path: *u8 = null) -> void #cpp_method #foreign libskia "??0SkFILEStream@@QEAA@QEBD@Z";

    /** Initialize the stream with an existing C FILE stream.
    *  The current position of the C FILE stream will be considered the
    *  beginning of the SkFILEStream and the current seek end of the FILE will be the end.
    *  The C FILE stream will be closed in the destructor.
    */
    Constructor :: (this: *SkFILEStream, file: *FILE) -> void #cpp_method #foreign libskia "??0SkFILEStream@@QEAA@PEAU_iobuf@@@Z";

    /** Initialize the stream with an existing C FILE stream.
    *  The current position of the C FILE stream will be considered the
    *  beginning of the SkFILEStream and size bytes later will be the end.
    *  The C FILE stream will be closed in the destructor.
    */
    Constructor :: (this: *SkFILEStream, file: *FILE, size: u64) -> void #cpp_method #foreign libskia "??0SkFILEStream@@QEAA@PEAU_iobuf@@_K@Z";

    Make :: (path: *u8) -> std.unique_ptr(SkFILEStream) #cpp_return_type_is_non_pod #foreign libskia "?Make@SkFILEStream@@SA?AV?$unique_ptr@VSkFILEStream@@U?$default_delete@VSkFILEStream@@@std@@@std@@QEBD@Z";

    /** Returns true if the current path could be opened. */
    isValid :: (this: *SkFILEStream) -> bool #cpp_method #foreign libskia "?isValid@SkFILEStream@@QEBA_NXZ";

    /** Close this SkFILEStream. */
    close :: (this: *SkFILEStream) -> void #cpp_method #foreign libskia "?close@SkFILEStream@@QEAAXXZ";

    duplicate :: (this: *SkFILEStream) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkFILEStream@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@XZ";

    fork :: (this: *SkFILEStream) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkFILEStream@@QEBA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@XZ";

    Constructor :: (this: *SkFILEStream, unknown0: *FILE, size: u64, start: u64) -> void #cpp_method #foreign libskia "??0SkFILEStream@@AEAA@PEAU_iobuf@@_K1@Z";
    Constructor :: (this: *SkFILEStream, unknown0: std.shared_ptr(FILE), end: u64, start: u64) -> void #cpp_method #foreign libskia "??0SkFILEStream@@AEAA@V?$shared_ptr@U_iobuf@@@std@@_K1@Z";
    Constructor :: (this: *SkFILEStream, unknown0: std.shared_ptr(FILE), end: u64, start: u64, current: u64) -> void #cpp_method #foreign libskia "??0SkFILEStream@@AEAA@V?$shared_ptr@U_iobuf@@@std@@_K11@Z";

    fFILE:     std.shared_ptr(FILE);

    // My own council will I keep on sizes and offsets.
    // These are seek positions in the underling FILE, not offsets into the stream.
    fEnd:      u64;
    fStart:    u64;
    fCurrent:  u64;

    INHERITED :: SkStreamAsset;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkFILEStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkFILEStream@@UEAA@XZ";

    virtual_read :: (this: *SkFILEStream, buffer: *void, size: u64) -> u64 #cpp_method #foreign libskia "?read@SkFILEStream@@UEAA_KPEAX_K@Z";
    virtual_isAtEnd :: (this: *SkFILEStream) -> bool #cpp_method #foreign libskia "?isAtEnd@SkFILEStream@@UEBA_NXZ";

    virtual_rewind :: (this: *SkFILEStream) -> bool #cpp_method #foreign libskia "?rewind@SkFILEStream@@UEAA_NXZ";

    virtual_getPosition :: (this: *SkFILEStream) -> u64 #cpp_method #foreign libskia "?getPosition@SkFILEStream@@UEBA_KXZ";
    virtual_seek :: (this: *SkFILEStream, position: u64) -> bool #cpp_method #foreign libskia "?seek@SkFILEStream@@UEAA_N_K@Z";
    virtual_move :: (this: *SkFILEStream, offset: s32) -> bool #cpp_method #foreign libskia "?move@SkFILEStream@@UEAA_NJ@Z";

    virtual_getLength :: (this: *SkFILEStream) -> u64 #cpp_method #foreign libskia "?getLength@SkFILEStream@@UEBA_KXZ";

    virtual_onDuplicate :: (this: *SkFILEStream) -> *SkStreamAsset #cpp_method #foreign libskia "?onDuplicate@SkFILEStream@@EEBAPEAVSkStreamAsset@@XZ";
    virtual_onFork :: (this: *SkFILEStream) -> *SkStreamAsset #cpp_method #foreign libskia "?onFork@SkFILEStream@@EEBAPEAVSkStreamAsset@@XZ";
}

// A read only view into a block of memory.
SkMemoryStream :: struct {
    vtable:                    *SkMemoryStream_VTable;
    using skmemorystream__raw: SkMemoryStream__RAW;
    #place vtable; #as skstreammemory: SkStreamMemory; // Support cast to SkStreamMemory
}
// SkMemoryStream without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkMemoryStream
SkMemoryStream__RAW :: struct {
    Constructor :: (this: *SkMemoryStream) -> void #cpp_method #foreign libskia "??0SkMemoryStream@@QEAA@XZ";

    /** We allocate (and free) the memory. Write to it via getMemoryBase() */
    Constructor :: (this: *SkMemoryStream, length: u64) -> void #cpp_method #foreign libskia "??0SkMemoryStream@@QEAA@_K@Z";

    /** If copyData is true, the stream makes a private copy of the data. */
    Constructor :: (this: *SkMemoryStream, data: *void, length: u64, copyData := false) -> void #cpp_method #foreign libskia "??0SkMemoryStream@@QEAA@PEBX_K_N@Z";

    /** Creates the stream to read from the specified data */
    Constructor :: (this: *SkMemoryStream, data: sk_sp(SkData)) -> void #cpp_method #foreign libskia "??0SkMemoryStream@@QEAA@V?$sk_sp@$$CBVSkData@@@@@Z";

    /** Returns a stream with a copy of the input data. */
    MakeCopy :: (data: *void, length: u64) -> std.unique_ptr(SkMemoryStream) #cpp_return_type_is_non_pod #foreign libskia "?MakeCopy@SkMemoryStream@@SA?AV?$unique_ptr@VSkMemoryStream@@U?$default_delete@VSkMemoryStream@@@std@@@std@@PEBX_K@Z";

    /** Returns a stream with a bare pointer reference to the input data. */
    MakeDirect :: (data: *void, length: u64) -> std.unique_ptr(SkMemoryStream) #cpp_return_type_is_non_pod #foreign libskia "?MakeDirect@SkMemoryStream@@SA?AV?$unique_ptr@VSkMemoryStream@@U?$default_delete@VSkMemoryStream@@@std@@@std@@PEBX_K@Z";

    /** Returns a stream with a shared reference to the input data. */
    Make :: (data: sk_sp(SkData)) -> std.unique_ptr(SkMemoryStream) #cpp_return_type_is_non_pod #foreign libskia "?Make@SkMemoryStream@@SA?AV?$unique_ptr@VSkMemoryStream@@U?$default_delete@VSkMemoryStream@@@std@@@std@@V?$sk_sp@$$CBVSkData@@@@@Z";

    /** Replace any memory buffer with the specified buffer. The caller
    must have allocated data with sk_malloc or sk_realloc, since it
    will be freed with sk_free.
    */
    setMemoryOwned :: (this: *SkMemoryStream, data: *void, length: u64) -> void #cpp_method #foreign libskia "?setMemoryOwned@SkMemoryStream@@QEAAXPEBX_K@Z";

    setData :: (this: *SkMemoryStream, data: sk_sp(SkData)) -> void #cpp_method #foreign libskia "?setData@SkMemoryStream@@QEAAXV?$sk_sp@$$CBVSkData@@@@@Z";

    getAtPos :: (this: *SkMemoryStream) -> *void #cpp_method #foreign libskia "?getAtPos@SkMemoryStream@@QEAAPEBXXZ";

    duplicate :: (this: *SkMemoryStream) -> std.unique_ptr(SkMemoryStream) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?duplicate@SkMemoryStream@@QEBA?AV?$unique_ptr@VSkMemoryStream@@U?$default_delete@VSkMemoryStream@@@std@@@std@@XZ";

    fork :: (this: *SkMemoryStream) -> std.unique_ptr(SkMemoryStream) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?fork@SkMemoryStream@@QEBA?AV?$unique_ptr@VSkMemoryStream@@U?$default_delete@VSkMemoryStream@@@std@@@std@@XZ";

    fData:     sk_sp(SkData);
    fOffset:   u64;

    INHERITED :: SkStreamMemory;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /** Resets the stream to the specified data and length,
    just like the constructor.
    if copyData is true, the stream makes a private copy of the data
    */
    virtual_setMemory :: (this: *SkMemoryStream, data: *void, length: u64, copyData := false) -> void #cpp_method #foreign libskia "?setMemory@SkMemoryStream@@UEAAXPEBX_K_N@Z";

    virtual_getData :: (this: *SkMemoryStream) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getData@SkMemoryStream@@UEBA?AV?$sk_sp@$$CBVSkData@@@@XZ";

    virtual_read :: (this: *SkMemoryStream, buffer: *void, size: u64) -> u64 #cpp_method #foreign libskia "?read@SkMemoryStream@@UEAA_KPEAX_K@Z";
    virtual_isAtEnd :: (this: *SkMemoryStream) -> bool #cpp_method #foreign libskia "?isAtEnd@SkMemoryStream@@UEBA_NXZ";

    virtual_peek :: (this: *SkMemoryStream, buffer: *void, size: u64) -> u64 #cpp_method #foreign libskia "?peek@SkMemoryStream@@UEBA_KPEAX_K@Z";

    virtual_rewind :: (this: *SkMemoryStream) -> bool #cpp_method #foreign libskia "?rewind@SkMemoryStream@@UEAA_NXZ";

    virtual_getPosition :: (this: *SkMemoryStream) -> u64 #cpp_method #foreign libskia "?getPosition@SkMemoryStream@@UEBA_KXZ";
    virtual_seek :: (this: *SkMemoryStream, position: u64) -> bool #cpp_method #foreign libskia "?seek@SkMemoryStream@@UEAA_N_K@Z";
    virtual_move :: (this: *SkMemoryStream, offset: s32) -> bool #cpp_method #foreign libskia "?move@SkMemoryStream@@UEAA_NJ@Z";

    virtual_getLength :: (this: *SkMemoryStream) -> u64 #cpp_method #foreign libskia "?getLength@SkMemoryStream@@UEBA_KXZ";

    virtual_getMemoryBase :: (this: *SkMemoryStream) -> *void #cpp_method #foreign libskia "?getMemoryBase@SkMemoryStream@@UEAAPEBXXZ";

    virtual_onDuplicate :: (this: *SkMemoryStream) -> *SkMemoryStream #cpp_method #foreign libskia "?onDuplicate@SkMemoryStream@@EEBAPEAV1@XZ";
    virtual_onFork :: (this: *SkMemoryStream) -> *SkMemoryStream #cpp_method #foreign libskia "?onFork@SkMemoryStream@@EEBAPEAV1@XZ";
}
SkMemoryStream_VTable :: struct #type_info_none {
    using vtable: SkStream_VTable;

    setMemory:    #type (this: *SkMemoryStream, data: *void, length: u64, copyData := false) -> void #cpp_method;
}
SkMemoryStream_setMemory :: inline (this: *SkMemoryStream, data: *void, length: u64, copyData := false) { this.vtable.setMemory(this, data, length, copyData); }

get_vtable :: (obj: *SkMemoryStream) -> *SkMemoryStream_VTable { return obj.vtable; }


/////////////////////////////////////////////////////////////////////////////////////////////
SkFILEWStream :: struct {
    vtable:                   *SkWStream_VTable;
    using skfilewstream__raw: SkFILEWStream__RAW;
    #place vtable; #as skwstream: SkWStream; // Support cast to SkWStream
}
// SkFILEWStream without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkFILEWStream
SkFILEWStream__RAW :: struct {
    Constructor :: (this: *SkFILEWStream, path: *u8) -> void #cpp_method #foreign libskia "??0SkFILEWStream@@QEAA@QEBD@Z";

    /** Returns true if the current path could be opened.
    */
    isValid :: (this: *SkFILEWStream) -> bool #cpp_method #foreign libskia "?isValid@SkFILEWStream@@QEBA_NXZ";

    fsync :: (this: *SkFILEWStream) -> void #cpp_method #foreign libskia "?fsync@SkFILEWStream@@QEAAXXZ";

    fFILE:     *FILE;

    INHERITED :: SkWStream;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkFILEWStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkFILEWStream@@UEAA@XZ";

    virtual_write :: (this: *SkFILEWStream, buffer: *void, size: u64) -> bool #cpp_method #foreign libskia "?write@SkFILEWStream@@UEAA_NPEBX_K@Z";
    virtual_flush :: (this: *SkFILEWStream) -> void #cpp_method #foreign libskia "?flush@SkFILEWStream@@UEAAXXZ";

    virtual_bytesWritten :: (this: *SkFILEWStream) -> u64 #cpp_method #foreign libskia "?bytesWritten@SkFILEWStream@@UEBA_KXZ";
}

SkDynamicMemoryWStream :: struct {
    vtable:                            *SkWStream_VTable;
    using skdynamicmemorywstream__raw: SkDynamicMemoryWStream__RAW;
    #place vtable; #as skwstream: SkWStream; // Support cast to SkWStream
}
// SkDynamicMemoryWStream without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkDynamicMemoryWStream
SkDynamicMemoryWStream__RAW :: struct {
    Constructor :: (this: *SkDynamicMemoryWStream) -> void #cpp_method #foreign libskia "??0SkDynamicMemoryWStream@@QEAA@XZ";

    read :: (this: *SkDynamicMemoryWStream, buffer: *void, offset: u64, size: u64) -> bool #cpp_method #foreign libskia "?read@SkDynamicMemoryWStream@@QEAA_NPEAX_K1@Z";

    /** More efficient version of read(dst, 0, bytesWritten()). */
    copyTo :: (this: *SkDynamicMemoryWStream, dst: *void) -> void #cpp_method #foreign libskia "?copyTo@SkDynamicMemoryWStream@@QEBAXPEAX@Z";
    writeToStream :: (this: *SkDynamicMemoryWStream, dst: *SkWStream) -> bool #cpp_method #foreign libskia "?writeToStream@SkDynamicMemoryWStream@@QEBA_NPEAVSkWStream@@@Z";

    /** Equivalent to copyTo() followed by reset(), but may save memory use. */
    copyToAndReset :: (this: *SkDynamicMemoryWStream, dst: *void) -> void #cpp_method #foreign libskia "?copyToAndReset@SkDynamicMemoryWStream@@QEAAXPEAX@Z";

    /** Equivalent to writeToStream() followed by reset(), but may save memory use. */
    writeToAndReset :: (this: *SkDynamicMemoryWStream, dst: *SkWStream) -> bool #cpp_method #foreign libskia "?writeToAndReset@SkDynamicMemoryWStream@@QEAA_NPEAVSkWStream@@@Z";

    /** Equivalent to writeToStream() followed by reset(), but may save memory use.
    When the dst is also a SkDynamicMemoryWStream, the implementation is constant time. */
    writeToAndReset :: (this: *SkDynamicMemoryWStream, dst: *SkDynamicMemoryWStream) -> bool #cpp_method #foreign libskia "?writeToAndReset@SkDynamicMemoryWStream@@QEAA_NPEAV1@@Z";

    /** Prepend this stream to dst, resetting this. */
    prependToAndReset :: (this: *SkDynamicMemoryWStream, dst: *SkDynamicMemoryWStream) -> void #cpp_method #foreign libskia "?prependToAndReset@SkDynamicMemoryWStream@@QEAAXPEAV1@@Z";

    /** Return the contents as SkData, and then reset the stream. */
    detachAsData :: (this: *SkDynamicMemoryWStream) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?detachAsData@SkDynamicMemoryWStream@@QEAA?AV?$sk_sp@VSkData@@@@XZ";

    /** Return the contents as vector, and then reset the stream. */
    detachAsVector :: (this: *SkDynamicMemoryWStream) -> std.vector(u8) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?detachAsVector@SkDynamicMemoryWStream@@QEAA?AV?$vector@EV?$allocator@E@std@@@std@@XZ";

    /** Reset, returning a reader stream with the current content. */
    detachAsStream :: (this: *SkDynamicMemoryWStream) -> std.unique_ptr(SkStreamAsset) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?detachAsStream@SkDynamicMemoryWStream@@QEAA?AV?$unique_ptr@VSkStreamAsset@@U?$default_delete@VSkStreamAsset@@@std@@@std@@XZ";

    /** Reset the stream to its original, empty, state. */
    reset :: (this: *SkDynamicMemoryWStream) -> void #cpp_method #foreign libskia "?reset@SkDynamicMemoryWStream@@QEAAXXZ";
    padToAlign4 :: (this: *SkDynamicMemoryWStream) -> void #cpp_method #foreign libskia "?padToAlign4@SkDynamicMemoryWStream@@QEAAXXZ";

    Block :: struct {}
    fHead:                   *SkDynamicMemoryWStream.Block = null;
    fTail:                   *SkDynamicMemoryWStream.Block = null;
    fBytesWrittenBeforeTail: u64 = 0;

    validate :: (this: *SkDynamicMemoryWStream) -> void #cpp_method #foreign libskia "?validate@SkDynamicMemoryWStream@@AEBAXXZ";

    INHERITED :: SkWStream;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkDynamicMemoryWStream, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkDynamicMemoryWStream@@UEAA@XZ";

    virtual_write :: (this: *SkDynamicMemoryWStream, buffer: *void, size: u64) -> bool #cpp_method #foreign libskia "?write@SkDynamicMemoryWStream@@UEAA_NPEBX_K@Z";
    virtual_bytesWritten :: (this: *SkDynamicMemoryWStream) -> u64 #cpp_method #foreign libskia "?bytesWritten@SkDynamicMemoryWStream@@UEBA_KXZ";
}

// The sknonstd namespace contains things we would like to be proposed and feel std-ish.
sknonstd :: struct {
    // The name 'copy' here is fraught with peril. In this case it means 'append', not 'overwrite'.
    // Alternate proposed names are 'propagate', 'augment', or 'append' (and 'add', but already taken).
    // std::experimental::propagate_const already exists for other purposes in TSv2.
    // These also follow the <dest, source> pattern used by boost.
    copy_const :: struct(D: Type, S: Type) {
        using,except(D, S) copy_const__raw:        copy_const__RAW(D, S);
        #if size_of(copy_const__RAW(D, S)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // copy_const without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from copy_const
    copy_const__RAW :: struct(D: Type, S: Type) {}

    copy_volatile :: struct(D: Type, S: Type) {
        using,except(D, S) copy_volatile__raw:     copy_volatile__RAW(D, S);
        #if size_of(copy_volatile__RAW(D, S)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // copy_volatile without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from copy_volatile
    copy_volatile__RAW :: struct(D: Type, S: Type) {}

    copy_cv :: struct(D: Type, S: Type) {
        using,except(D, S) copy_cv__raw:           copy_cv__RAW(D, S);
        #if size_of(copy_cv__RAW(D, S)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // copy_cv without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from copy_cv
    copy_cv__RAW :: struct(D: Type, S: Type) {}
}

SkOverloadedFunctionObject :: struct(T: Type, P: Type) {
    using,except(T, P) skoverloadedfunctionobject__raw: SkOverloadedFunctionObject__RAW(T, P);
    #if size_of(SkOverloadedFunctionObject__RAW(T, P)) == 0 {
        __empty_struct_padding:          u8; // C++ makes empty structs have length 1
    }
}
// SkOverloadedFunctionObject without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkOverloadedFunctionObject
SkOverloadedFunctionObject__RAW :: struct(T: Type, P: Type) {}

/** \class SkAutoTCallVProc

Call a function when this goes out of scope. The template uses two
parameters, the object, and a function that is to be called in the destructor.
If release() is called, the object reference is set to null. If the object
reference is null when the destructor is called, we do not call the
function.
*/
SkAutoTCallVProc :: struct(T: Type, P: #type (unknown0: *T) -> void #c_call) {
    using,except(T, P) skautotcallvproc__raw:  SkAutoTCallVProc__RAW(T, P);
    #if size_of(SkAutoTCallVProc__RAW(T, P)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// SkAutoTCallVProc without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkAutoTCallVProc
SkAutoTCallVProc__RAW :: struct(T: Type, P: #type (unknown0: *T) -> void #c_call) {}

/** \class SkTextBlob
SkTextBlob combines multiple text runs into an immutable container. Each text
run consists of glyphs, SkPaint, and position. Only parts of SkPaint related to
fonts and text rendering are used by run.
*/
SkTextBlob :: struct {
    #as using sknvrefcnt: SkNVRefCnt(SkTextBlob);

    RunRecord :: struct {}

    /** Returns conservative bounding box. Uses SkPaint associated with each glyph to
    determine glyph bounds, and unions all bounds. Returned bounds may be
    larger than the bounds of all glyphs in runs.
    
    @return  conservative bounding box
    */
    bounds :: (this: *SkTextBlob) -> *SkRect #cpp_method #foreign libskia "?bounds@SkTextBlob@@QEBAAEBUSkRect@@XZ";

    /** Returns a non-zero value unique among all text blobs.
    
    @return  identifier for SkTextBlob
    */
    uniqueID :: (this: *SkTextBlob) -> u32 #cpp_method #foreign libskia "?uniqueID@SkTextBlob@@QEBAIXZ";

    /** Returns the number of intervals that intersect bounds.
    bounds describes a pair of lines parallel to the text advance.
    The return count is zero or a multiple of two, and is at most twice the number of glyphs in
    the the blob.
    
    Pass nullptr for intervals to determine the size of the interval array.
    
    Runs within the blob that contain SkRSXform are ignored when computing intercepts.
    
    @param bounds     lower and upper line parallel to the advance
    @param intervals  returned intersections; may be nullptr
    @param paint      specifies stroking, SkPathEffect that affects the result; may be nullptr
    @return           number of intersections; may be zero
    */
    getIntercepts :: (this: *SkTextBlob, bounds: *[2] SkScalar, intervals: *SkScalar, paint: *SkPaint = null) -> s32 #cpp_method #foreign libskia "?getIntercepts@SkTextBlob@@QEBAHQEBMQEAMPEBVSkPaint@@@Z";

    /** Creates SkTextBlob with a single run.
    
    font contains attributes used to define the run text.
    
    When encoding is SkTextEncoding::kUTF8, SkTextEncoding::kUTF16, or
    SkTextEncoding::kUTF32, this function uses the default
    character-to-glyph mapping from the SkTypeface in font.  It does not
    perform typeface fallback for characters not found in the SkTypeface.
    It does not perform kerning or other complex shaping; glyphs are
    positioned based on their default advances.
    
    @param text        character code points or glyphs drawn
    @param byteLength  byte length of text array
    @param font        text size, typeface, text scale, and so on, used to draw
    @param encoding    text encoding used in the text array
    @return            SkTextBlob constructed from one run
    */
    MakeFromText :: (text: *void, byteLength: u64, font: *SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromText@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBX_KAEBVSkFont@@W4SkTextEncoding@@@Z";
    MakeFromText :: (text: *void, byteLength: u64, font: SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromText(text, byteLength, *font, encoding);
    }

    /** Creates SkTextBlob with a single run. string meaning depends on SkTextEncoding;
    by default, string is encoded as UTF-8.
    
    font contains attributes used to define the run text.
    
    When encoding is SkTextEncoding::kUTF8, SkTextEncoding::kUTF16, or
    SkTextEncoding::kUTF32, this function uses the default
    character-to-glyph mapping from the SkTypeface in font.  It does not
    perform typeface fallback for characters not found in the SkTypeface.
    It does not perform kerning or other complex shaping; glyphs are
    positioned based on their default advances.
    
    @param string   character code points or glyphs drawn
    @param font     text size, typeface, text scale, and so on, used to draw
    @param encoding text encoding used in the text array
    @return         SkTextBlob constructed from one run
    */
    MakeFromString :: (_string: *u8, font: *SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromString@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBDAEBVSkFont@@W4SkTextEncoding@@@Z";
    MakeFromString :: (_string: *u8, font: SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromString(_string, *font, encoding);
    }

    /** Returns a textblob built from a single run of text with x-positions and a single y value.
    This is equivalent to using SkTextBlobBuilder and calling allocRunPosH().
    Returns nullptr if byteLength is zero.
    
    @param text        character code points or glyphs drawn (based on encoding)
    @param byteLength  byte length of text array
    @param xpos    array of x-positions, must contain values for all of the character points.
    @param constY  shared y-position for each character point, to be paired with each xpos.
    @param font    SkFont used for this run
    @param encoding specifies the encoding of the text array.
    @return        new textblob or nullptr
    */
    MakeFromPosTextH :: (text: *void, byteLength: u64, xpos: SkSpan(SkScalar), constY: SkScalar, font: *SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromPosTextH@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBX_KV?$SkSpan@$$CBM@@MAEBVSkFont@@W4SkTextEncoding@@@Z";
    MakeFromPosTextH :: (text: *void, byteLength: u64, xpos: SkSpan(SkScalar), constY: SkScalar, font: SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromPosTextH(text, byteLength, xpos, constY, *font, encoding);
    }

    /** Returns a textblob built from a single run of text with positions.
    This is equivalent to using SkTextBlobBuilder and calling allocRunPos().
    Returns nullptr if byteLength is zero.
    
    @param text        character code points or glyphs drawn (based on encoding)
    @param byteLength  byte length of text array
    @param pos     array of positions, must contain values for all of the character points.
    @param font    SkFont used for this run
    @param encoding specifies the encoding of the text array.
    @return        new textblob or nullptr
    */
    MakeFromPosText :: (text: *void, byteLength: u64, pos: SkSpan(SkPoint), font: *SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromPosText@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBX_KV?$SkSpan@$$CBUSkPoint@@@@AEBVSkFont@@W4SkTextEncoding@@@Z";
    MakeFromPosText :: (text: *void, byteLength: u64, pos: SkSpan(SkPoint), font: SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromPosText(text, byteLength, pos, *font, encoding);
    }

    MakeFromRSXform :: (text: *void, byteLength: u64, xform: SkSpan(SkRSXform), font: *SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromRSXform@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBX_KV?$SkSpan@$$CBUSkRSXform@@@@AEBVSkFont@@W4SkTextEncoding@@@Z";
    MakeFromRSXform :: (text: *void, byteLength: u64, xform: SkSpan(SkRSXform), font: SkFont, encoding: SkTextEncoding = .UTF8) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromRSXform(text, byteLength, xform, *font, encoding);
    }

    // Helpers for glyphs
    MakeFromPosHGlyphs :: (glyphs: SkSpan(SkGlyphID), xpos: SkSpan(SkScalar), constY: SkScalar, font: *SkFont) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromPosHGlyphs@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@V?$SkSpan@$$CBG@@V?$SkSpan@$$CBM@@MAEBVSkFont@@@Z";
    MakeFromPosHGlyphs :: (glyphs: SkSpan(SkGlyphID), xpos: SkSpan(SkScalar), constY: SkScalar, font: SkFont) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromPosHGlyphs(glyphs, xpos, constY, *font);
    }

    MakeFromPosGlyphs :: (glyphs: SkSpan(SkGlyphID), pos: SkSpan(SkPoint), font: *SkFont) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromPosGlyphs@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@V?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkPoint@@@@AEBVSkFont@@@Z";
    MakeFromPosGlyphs :: (glyphs: SkSpan(SkGlyphID), pos: SkSpan(SkPoint), font: SkFont) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromPosGlyphs(glyphs, pos, *font);
    }

    MakeFromRSXformGlyphs :: (glyphs: SkSpan(SkGlyphID), xform: SkSpan(SkRSXform), font: *SkFont) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?MakeFromRSXformGlyphs@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@V?$SkSpan@$$CBG@@V?$SkSpan@$$CBUSkRSXform@@@@AEBVSkFont@@@Z";
    MakeFromRSXformGlyphs :: (glyphs: SkSpan(SkGlyphID), xform: SkSpan(SkRSXform), font: SkFont) -> sk_sp(SkTextBlob) #no_context {
        return MakeFromRSXformGlyphs(glyphs, xform, *font);
    }

    /** Writes data to allow later reconstruction of SkTextBlob. memory points to storage
    to receive the encoded data, and memory_size describes the size of storage.
    Returns bytes used if provided storage is large enough to hold all data;
    otherwise, returns zero.
    
    procs.fTypefaceProc permits supplying a custom function to encode SkTypeface.
    If procs.fTypefaceProc is nullptr, default encoding is used. procs.fTypefaceCtx
    may be used to provide user context to procs.fTypefaceProc; procs.fTypefaceProc
    is called with a pointer to SkTypeface and user context.
    
    @param procs       custom serial data encoders; may be nullptr
    @param memory      storage for data
    @param memory_size size of storage
    @return            bytes written, or zero if required storage is larger than memory_size
    
    example: https://fiddle.skia.org/c/@TextBlob_serialize
    */
    serialize :: (this: *SkTextBlob, procs: *SkSerialProcs, memory: *void, memory_size: u64) -> u64 #cpp_method #foreign libskia "?serialize@SkTextBlob@@QEBA_KAEBUSkSerialProcs@@PEAX_K@Z";
    serialize :: (this: *SkTextBlob, procs: SkSerialProcs, memory: *void, memory_size: u64) -> u64 #no_context {
        return serialize(this, *procs, memory, memory_size);
    }

    /** Returns storage containing SkData describing SkTextBlob, using optional custom
    encoders.
    
    procs.fTypefaceProc permits supplying a custom function to encode SkTypeface.
    If procs.fTypefaceProc is nullptr, default encoding is used. procs.fTypefaceCtx
    may be used to provide user context to procs.fTypefaceProc; procs.fTypefaceProc
    is called with a pointer to SkTypeface and user context.
    
    @param procs  custom serial data encoders; may be nullptr
    @return       storage containing serialized SkTextBlob
    
    example: https://fiddle.skia.org/c/@TextBlob_serialize_2
    */
    serialize :: (this: *SkTextBlob, procs: *SkSerialProcs) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@SkTextBlob@@QEBA?AV?$sk_sp@VSkData@@@@AEBUSkSerialProcs@@@Z";
    serialize :: (this: *SkTextBlob, procs: SkSerialProcs) -> sk_sp(SkData) #no_context {
        return serialize(this, *procs);
    }

    /** Recreates SkTextBlob that was serialized into data. Returns constructed SkTextBlob
    if successful; otherwise, returns nullptr. Fails if size is smaller than
    required data length, or if data does not permit constructing valid SkTextBlob.
    
    procs.fTypefaceProc permits supplying a custom function to decode SkTypeface.
    If procs.fTypefaceProc is nullptr, default decoding is used. procs.fTypefaceCtx
    may be used to provide user context to procs.fTypefaceProc; procs.fTypefaceProc
    is called with a pointer to SkTypeface data, data byte length, and user context.
    
    @param data   pointer for serial data
    @param size   size of data
    @param procs  custom serial data decoders; may be nullptr
    @return       SkTextBlob constructed from data in memory
    */
    Deserialize :: (data: *void, size: u64, procs: *SkDeserialProcs) -> sk_sp(SkTextBlob) #cpp_return_type_is_non_pod #foreign libskia "?Deserialize@SkTextBlob@@SA?AV?$sk_sp@VSkTextBlob@@@@PEBX_KAEBUSkDeserialProcs@@@Z";
    Deserialize :: (data: *void, size: u64, procs: SkDeserialProcs) -> sk_sp(SkTextBlob) #no_context {
        return Deserialize(data, size, *procs);
    }

    Iter :: struct {
        Run :: struct {
            fTypeface:     *SkTypeface;
            fGlyphCount:   s32;
            fGlyphIndices: *SkGlyphID;
        }

        Constructor :: (this: *Iter, unknown0: *SkTextBlob) -> void #cpp_method #foreign libskia "??0Iter@SkTextBlob@@QEAA@AEBV1@@Z";
        Constructor :: (this: *Iter, unknown0: SkTextBlob) #no_context {
            Constructor(this, *unknown0);
        }

        /**
        * Returns true for each "run" inside the textblob, setting the Run fields (if not null).
        * If this returns false, there are no more runs, and the Run parameter will be ignored.
        */
        next :: (this: *Iter, unknown0: *Run) -> bool #cpp_method #foreign libskia "?next@Iter@SkTextBlob@@QEAA_NPEAURun@12@@Z";

        // Experimental, DO NO USE, will change/go-away
        ExperimentalRun :: struct {
            font:      SkFont;
            count:     s32;
            glyphs:    *SkGlyphID;
            positions: *SkPoint;
        }

        experimentalNext :: (this: *Iter, unknown0: *ExperimentalRun) -> bool #cpp_method #foreign libskia "?experimentalNext@Iter@SkTextBlob@@QEAA_NPEAUExperimentalRun@12@@Z";

        fRunRecord: *RunRecord;
    }

    GlyphPositioning :: enum u8 {
    }

    Constructor :: (this: *SkTextBlob, bounds: *SkRect) -> void #cpp_method #foreign libskia "??0SkTextBlob@@AEAA@AEBUSkRect@@@Z";
    Constructor :: (this: *SkTextBlob, bounds: SkRect) #no_context {
        Constructor(this, *bounds);
    }

    Destructor :: (this: *SkTextBlob) -> void #cpp_method #foreign libskia "??1SkTextBlob@@AEAA@XZ";

    ScalarsPerGlyph :: (pos: GlyphPositioning) -> u32 #foreign libskia "?ScalarsPerGlyph@SkTextBlob@@CAIW4GlyphPositioning@1@@Z";

    PurgeDelegate :: #type (blobID: u32, cacheID: u32) -> void #c_call;

    // Call when this blob is part of the key to a cache entry. This allows the cache
    // to know automatically those entries can be purged when this SkTextBlob is deleted.
    notifyAddedToCache :: (this: *SkTextBlob, cacheID: u32, purgeDelegate: PurgeDelegate) -> void #cpp_method #foreign libskia "?notifyAddedToCache@SkTextBlob@@AEBAXIP6AXII@Z@Z";

    fCacheID:             std.atomic(u32);
    fPurgeDelegate:       std.atomic(PurgeDelegate);

    fStorageSize:         u64;

    // The actual payload resides in externally-managed storage, following the object.
    // (see the .cpp for more details)
    INHERITED :: SkRefCnt;
}

// Memory for objects of this class is created with sk_malloc rather than operator new and must
// be freed with sk_free.
operatordelete :: (this: *SkTextBlob, p: *void) -> void #cpp_method #foreign libskia "??3SkTextBlob@@CAXPEAX@Z";
operatordelete :: (this: SkTextBlob, p: *void) #no_context {
    operatordelete(*this, p);
}
operatornew :: (this: *SkTextBlob, unknown0: u64) -> *void #cpp_method #foreign libskia "??2SkTextBlob@@CAPEAX_K@Z";
operatornew :: (this: SkTextBlob, unknown0: u64) -> *void #no_context {
    return operatornew(*this, unknown0);
}
operatornew :: (this: *SkTextBlob, unknown0: u64, p: *void) -> *void #cpp_method #foreign libskia "??2SkTextBlob@@CAPEAX_KPEAX@Z";
operatornew :: (this: SkTextBlob, unknown0: u64, p: *void) -> *void #no_context {
    return operatornew(*this, unknown0, p);
}

/** \class SkTextBlobBuilder
Helper class for constructing SkTextBlob.
*/
SkTextBlobBuilder :: struct {
    /** Constructs empty SkTextBlobBuilder. By default, SkTextBlobBuilder has no runs.
    
    @return  empty SkTextBlobBuilder
    
    example: https://fiddle.skia.org/c/@TextBlobBuilder_empty_constructor
    */
    Constructor :: (this: *SkTextBlobBuilder) -> void #cpp_method #foreign libskia "??0SkTextBlobBuilder@@QEAA@XZ";

    /** Deletes data allocated internally by SkTextBlobBuilder.
    */
    Destructor :: (this: *SkTextBlobBuilder) -> void #cpp_method #foreign libskia "??1SkTextBlobBuilder@@QEAA@XZ";

    /** Returns SkTextBlob built from runs of glyphs added by builder. Returned
    SkTextBlob is immutable; it may be copied, but its contents may not be altered.
    Returns nullptr if no runs of glyphs were added by builder.
    
    Resets SkTextBlobBuilder to its initial empty state, allowing it to be
    reused to build a new set of runs.
    
    @return  SkTextBlob or nullptr
    
    example: https://fiddle.skia.org/c/@TextBlobBuilder_make
    */
    make :: (this: *SkTextBlobBuilder) -> sk_sp(SkTextBlob) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?make@SkTextBlobBuilder@@QEAA?AV?$sk_sp@VSkTextBlob@@@@XZ";

    /** \struct SkTextBlobBuilder::RunBuffer
    RunBuffer supplies storage for glyphs and positions within a run.
    
    A run is a sequence of glyphs sharing font metrics and positioning.
    Each run may position its glyphs in one of three ways:
    by specifying where the first glyph is drawn, and allowing font metrics to
    determine the advance to subsequent glyphs; by specifying a baseline, and
    the position on that baseline for each glyph in run; or by providing SkPoint
    array, one per glyph.
    */
    RunBuffer :: struct {
        glyphs:   *SkGlyphID; //!< storage for glyph indexes in run
        pos:      *SkScalar; //!< storage for glyph positions in run
        utf8text: *u8; //!< storage for text UTF-8 code units in run
        clusters: *u32; //!< storage for glyph clusters (index of UTF-8 code unit)

        // Helpers, since the "pos" field can be different types (always some number of floats).
//         points :: (this: *RunBuffer) -> *SkPoint #cpp_method #foreign libskia "?points@RunBuffer@SkTextBlobBuilder@@QEBAPEAUSkPoint@@XZ";
//         xforms :: (this: *RunBuffer) -> *SkRSXform #cpp_method #foreign libskia "?xforms@RunBuffer@SkTextBlobBuilder@@QEBAPEAUSkRSXform@@XZ";
    }

    /** Returns run with storage for glyphs. Caller must write count glyphs to
    RunBuffer::glyphs before next call to SkTextBlobBuilder.
    
    RunBuffer::pos, RunBuffer::utf8text, and RunBuffer::clusters should be ignored.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned on a baseline at (x, y), using font metrics to
    determine their relative placement.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from (x, y) and RunBuffer::glyphs metrics.
    
    @param font    SkFont used for this run
    @param count   number of glyphs
    @param x       horizontal offset within the blob
    @param y       vertical offset within the blob
    @param bounds  optional run bounding box
    @return writable glyph buffer
    */
    allocRun :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, x: SkScalar, y: SkScalar, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRun@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HMMPEBUSkRect@@@Z";
    allocRun :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, x: SkScalar, y: SkScalar, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRun(this, *font, count, x, y, bounds);
    }

    /** Returns run with storage for glyphs and positions along baseline. Caller must
    write count glyphs to RunBuffer::glyphs and count scalars to RunBuffer::pos
    before next call to SkTextBlobBuilder.
    
    RunBuffer::utf8text and RunBuffer::clusters should be ignored.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned on a baseline at y, using x-axis positions written by
    caller to RunBuffer::pos.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from y, RunBuffer::pos, and RunBuffer::glyphs metrics.
    
    @param font    SkFont used for this run
    @param count   number of glyphs
    @param y       vertical offset within the blob
    @param bounds  optional run bounding box
    @return writable glyph buffer and x-axis position buffer
    */
    allocRunPosH :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, y: SkScalar, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunPosH@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HMPEBUSkRect@@@Z";
    allocRunPosH :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, y: SkScalar, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunPosH(this, *font, count, y, bounds);
    }

    /** Returns run with storage for glyphs and SkPoint positions. Caller must
    write count glyphs to RunBuffer::glyphs and count SkPoint to RunBuffer::pos
    before next call to SkTextBlobBuilder.
    
    RunBuffer::utf8text and RunBuffer::clusters should be ignored.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned using SkPoint written by caller to RunBuffer::pos, using
    two scalar values for each SkPoint.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from RunBuffer::pos, and RunBuffer::glyphs metrics.
    
    @param font    SkFont used for this run
    @param count   number of glyphs
    @param bounds  optional run bounding box
    @return writable glyph buffer and SkPoint buffer
    */
    allocRunPos :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunPos@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HPEBUSkRect@@@Z";
    allocRunPos :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunPos(this, *font, count, bounds);
    }

    // RunBuffer.pos points to SkRSXform array
    allocRunRSXform :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32) -> *RunBuffer #cpp_method #foreign libskia "?allocRunRSXform@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@H@Z";
    allocRunRSXform :: (this: *SkTextBlobBuilder, font: SkFont, count: s32) -> *RunBuffer #no_context {
        return allocRunRSXform(this, *font, count);
    }

    /** Returns run with storage for glyphs, text, and clusters. Caller must
    write count glyphs to RunBuffer::glyphs, textByteCount UTF-8 code units
    into RunBuffer::utf8text, and count monotonic indexes into utf8text
    into RunBuffer::clusters before next call to SkTextBlobBuilder.
    
    RunBuffer::pos should be ignored.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned on a baseline at (x, y), using font metrics to
    determine their relative placement.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from (x, y) and RunBuffer::glyphs metrics.
    
    @param font          SkFont used for this run
    @param count         number of glyphs
    @param x             horizontal offset within the blob
    @param y             vertical offset within the blob
    @param textByteCount number of UTF-8 code units
    @param bounds        optional run bounding box
    @return writable glyph buffer, text buffer, and cluster buffer
    */
    allocRunText :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, x: SkScalar, y: SkScalar, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunText@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HMMHPEBUSkRect@@@Z";
    allocRunText :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, x: SkScalar, y: SkScalar, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunText(this, *font, count, x, y, textByteCount, bounds);
    }

    /** Returns run with storage for glyphs, positions along baseline, text,
    and clusters. Caller must write count glyphs to RunBuffer::glyphs,
    count scalars to RunBuffer::pos, textByteCount UTF-8 code units into
    RunBuffer::utf8text, and count monotonic indexes into utf8text into
    RunBuffer::clusters before next call to SkTextBlobBuilder.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned on a baseline at y, using x-axis positions written by
    caller to RunBuffer::pos.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from y, RunBuffer::pos, and RunBuffer::glyphs metrics.
    
    @param font          SkFont used for this run
    @param count         number of glyphs
    @param y             vertical offset within the blob
    @param textByteCount number of UTF-8 code units
    @param bounds        optional run bounding box
    @return writable glyph buffer, x-axis position buffer, text buffer, and cluster buffer
    */
    allocRunTextPosH :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, y: SkScalar, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunTextPosH@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HMHPEBUSkRect@@@Z";
    allocRunTextPosH :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, y: SkScalar, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunTextPosH(this, *font, count, y, textByteCount, bounds);
    }

    /** Returns run with storage for glyphs, SkPoint positions, text, and
    clusters. Caller must write count glyphs to RunBuffer::glyphs, count
    SkPoint to RunBuffer::pos, textByteCount UTF-8 code units into
    RunBuffer::utf8text, and count monotonic indexes into utf8text into
    RunBuffer::clusters before next call to SkTextBlobBuilder.
    
    Glyphs share metrics in font.
    
    Glyphs are positioned using SkPoint written by caller to RunBuffer::pos, using
    two scalar values for each SkPoint.
    
    bounds defines an optional bounding box, used to suppress drawing when SkTextBlob
    bounds does not intersect SkSurface bounds. If bounds is nullptr, SkTextBlob bounds
    is computed from RunBuffer::pos, and RunBuffer::glyphs metrics.
    
    @param font          SkFont used for this run
    @param count         number of glyphs
    @param textByteCount number of UTF-8 code units
    @param bounds        optional run bounding box
    @return writable glyph buffer, SkPoint buffer, text buffer, and cluster buffer
    */
    allocRunTextPos :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunTextPos@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HHPEBUSkRect@@@Z";
    allocRunTextPos :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunTextPos(this, *font, count, textByteCount, bounds);
    }

    // RunBuffer.pos points to SkRSXform array
    allocRunTextRSXform :: (this: *SkTextBlobBuilder, font: *SkFont, count: s32, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #cpp_method #foreign libskia "?allocRunTextRSXform@SkTextBlobBuilder@@QEAAAEBURunBuffer@1@AEBVSkFont@@HHPEBUSkRect@@@Z";
    allocRunTextRSXform :: (this: *SkTextBlobBuilder, font: SkFont, count: s32, textByteCount: s32, bounds: *SkRect = null) -> *RunBuffer #no_context {
        return allocRunTextRSXform(this, *font, count, textByteCount, bounds);
    }

    reserve :: (this: *SkTextBlobBuilder, size: u64) -> void #cpp_method #foreign libskia "?reserve@SkTextBlobBuilder@@AEAAX_K@Z";
    allocInternal :: (this: *SkTextBlobBuilder, font: *SkFont, positioning: SkTextBlob.GlyphPositioning, count: s32, textBytes: s32, offset: SkPoint, bounds: *SkRect) -> void #cpp_method #foreign libskia "?allocInternal@SkTextBlobBuilder@@AEAAXAEBVSkFont@@W4GlyphPositioning@SkTextBlob@@HHUSkPoint@@PEBUSkRect@@@Z";
    allocInternal :: (this: *SkTextBlobBuilder, font: SkFont, positioning: SkTextBlob.GlyphPositioning, count: s32, textBytes: s32, offset: SkPoint, bounds: *SkRect) #no_context {
        allocInternal(this, *font, positioning, count, textBytes, offset, bounds);
    }

    mergeRun :: (this: *SkTextBlobBuilder, font: *SkFont, positioning: SkTextBlob.GlyphPositioning, count: u32, offset: SkPoint) -> bool #cpp_method #foreign libskia "?mergeRun@SkTextBlobBuilder@@AEAA_NAEBVSkFont@@W4GlyphPositioning@SkTextBlob@@IUSkPoint@@@Z";
    mergeRun :: (this: *SkTextBlobBuilder, font: SkFont, positioning: SkTextBlob.GlyphPositioning, count: u32, offset: SkPoint) -> bool #no_context {
        return mergeRun(this, *font, positioning, count, offset);
    }

    updateDeferredBounds :: (this: *SkTextBlobBuilder) -> void #cpp_method #foreign libskia "?updateDeferredBounds@SkTextBlobBuilder@@AEAAXXZ";

    ConservativeRunBounds :: (unknown0: *SkTextBlob.RunRecord) -> SkRect #foreign libskia "?ConservativeRunBounds@SkTextBlobBuilder@@CA?AUSkRect@@AEBVRunRecord@SkTextBlob@@@Z";
    ConservativeRunBounds :: (unknown0: SkTextBlob.RunRecord) -> SkRect #no_context {
        return ConservativeRunBounds(*unknown0);
    }
    TightRunBounds :: (unknown0: *SkTextBlob.RunRecord) -> SkRect #foreign libskia "?TightRunBounds@SkTextBlobBuilder@@CA?AUSkRect@@AEBVRunRecord@SkTextBlob@@@Z";
    TightRunBounds :: (unknown0: SkTextBlob.RunRecord) -> SkRect #no_context {
        return TightRunBounds(*unknown0);
    }

    fStorage:          skia_private.AutoTMalloc(u8);
    fStorageSize:      u64;
    fStorageUsed:      u64;

    fBounds:           SkRect;
    fRunCount:         s32;
    fDeferredBounds:   bool;
    fLastRun:          u64; // index into fStorage

    fCurrentRunBuffer: RunBuffer;
}

/**
*  Like SkData, SkDataTable holds an immutable data buffer. The data buffer is
*  organized into a table of entries, each with a length, so the entries are
*  not required to all be the same size.
*/
SkDataTable :: struct {
    vtable:                 *SkRefCntBase_VTable;
    using skdatatable__raw: SkDataTable__RAW;
    #place vtable; #as skrefcnt: SkRefCnt; // Support cast to SkRefCnt
}
// SkDataTable without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkDataTable
SkDataTable__RAW :: struct {
    using skrefcnt__raw: SkRefCnt__RAW;

    /**
    *  Returns true if the table is empty (i.e. has no entries).
    */
    isEmpty :: (this: *SkDataTable) -> bool #cpp_method #foreign libskia "?isEmpty@SkDataTable@@QEBA_NXZ";

    /**
    *  Return the number of entries in the table. 0 for an empty table
    */
    count :: (this: *SkDataTable) -> s32 #cpp_method #foreign libskia "?count@SkDataTable@@QEBAHXZ";

    /**
    *  Return the size of the index'th entry in the table. The caller must
    *  ensure that index is valid for this table.
    */
    atSize :: (this: *SkDataTable, index: s32) -> u64 #cpp_method #foreign libskia "?atSize@SkDataTable@@QEBA_KH@Z";

    /**
    *  Return a pointer to the data of the index'th entry in the table.
    *  The caller must ensure that index is valid for this table.
    *
    *  @param size If non-null, this returns the byte size of this entry. This
    *              will be the same value that atSize(index) would return.
    */
    at :: (this: *SkDataTable, index: s32, size: *u64 = null) -> *void #cpp_method #foreign libskia "?at@SkDataTable@@QEBAPEBXHPEA_K@Z";

    /**
    *  Returns the index'th entry as a c-string, and assumes that the trailing
    *  null byte had been copied into the table as well.
    */
    atStr :: (this: *SkDataTable, index: s32) -> *u8 #cpp_method #foreign libskia "?atStr@SkDataTable@@QEBAPEBDH@Z";

    FreeProc :: #type (_context: *void) -> void #c_call;

    MakeEmpty :: () -> sk_sp(SkDataTable) #cpp_return_type_is_non_pod #foreign libskia "?MakeEmpty@SkDataTable@@SA?AV?$sk_sp@VSkDataTable@@@@XZ";

    /**
    *  Return a new DataTable that contains a copy of the data stored in each
    *  "array".
    *
    *  @param ptrs array of points to each element to be copied into the table.
    *  @param sizes array of byte-lengths for each entry in the corresponding
    *               ptrs[] array.
    *  @param count the number of array elements in ptrs[] and sizes[] to copy.
    */
    MakeCopyArrays :: (ptrs: **void, sizes: *u64, count: s32) -> sk_sp(SkDataTable) #cpp_return_type_is_non_pod #foreign libskia "?MakeCopyArrays@SkDataTable@@SA?AV?$sk_sp@VSkDataTable@@@@PEBQEBXQEB_KH@Z";

    /**
    *  Return a new table that contains a copy of the data in array.
    *
    *  @param array contiguous array of data for all elements to be copied.
    *  @param elemSize byte-length for a given element.
    *  @param count the number of entries to be copied out of array. The number
    *               of bytes that will be copied is count * elemSize.
    */
    MakeCopyArray :: (array: *void, elemSize: u64, count: s32) -> sk_sp(SkDataTable) #cpp_return_type_is_non_pod #foreign libskia "?MakeCopyArray@SkDataTable@@SA?AV?$sk_sp@VSkDataTable@@@@PEBX_KH@Z";

    MakeArrayProc :: (array: *void, elemSize: u64, count: s32, proc: SkDataTable.FreeProc, _context: *void) -> sk_sp(SkDataTable) #cpp_return_type_is_non_pod #foreign libskia "?MakeArrayProc@SkDataTable@@SA?AV?$sk_sp@VSkDataTable@@@@PEBX_KHP6AXPEAX@Z2@Z";

    Dir :: struct {
        fPtr:  *void;
        fSize: u64;
    }

    fCount:              s32 #align 8;
    fElemSize:           u64;
    fU:                  union {
        fDir:   *Dir;
        fElems: *u8;
    };

    fFreeProc:           SkDataTable.FreeProc;
    fFreeProcContext:    *void;

    Constructor :: (this: *SkDataTable) -> void #cpp_method #foreign libskia "??0SkDataTable@@AEAA@XZ";
    Constructor :: (this: *SkDataTable, array: *void, elemSize: u64, count: s32, unknown0: SkDataTable.FreeProc, _context: *void) -> void #cpp_method #foreign libskia "??0SkDataTable@@AEAA@PEBX_KHP6AXPEAX@Z2@Z";

    Constructor :: (this: *SkDataTable, unknown0: *SkDataTable.Dir, count: s32, unknown1: SkDataTable.FreeProc, _context: *void) -> void #cpp_method #foreign libskia "??0SkDataTable@@AEAA@PEBUDir@0@HP6AXPEAX@Z1@Z";

    INHERITED :: SkRefCnt;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkDataTable, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkDataTable@@EEAA@XZ";
}

/** 32 bit signed integer used to represent fractions values with 16 bits to the right of the decimal point
*/
SkFixed :: s32;

// SkFloatToFixed_Check :: (x: float) -> SkFixed #foreign libskia "?SkFloatToFixed_Check@@YAHM@Z";

// SkIntToFixed :: (n: s32) -> SkFixed #foreign libskia "?SkIntToFixed@@YAHH@Z";

// SkFixedRoundToFixed :: (x: SkFixed) -> SkFixed #foreign libskia "?SkFixedRoundToFixed@@YAHH@Z";

// SkFixedCeilToFixed :: (x: SkFixed) -> SkFixed #foreign libskia "?SkFixedCeilToFixed@@YAHH@Z";

// SkFixedFloorToFixed :: (x: SkFixed) -> SkFixed #foreign libskia "?SkFixedFloorToFixed@@YAHH@Z";

// SkFixedMul :: (a: SkFixed, b: SkFixed) -> SkFixed #foreign libskia "?SkFixedMul@@YAHHH@Z";

///////////////////////////////////////////////////////////////////////////////
SkFixed3232 :: s64;

// A row-major 3x3 matrix (ie vals[row][col])
skcms_Matrix3x3 :: struct {
    vals: [3] [3] float;
}

// It is _not_ safe to alias the pointers to invert in-place.
// skcms_Matrix3x3_invert :: (unknown0: *skcms_Matrix3x3, unknown1: *skcms_Matrix3x3) -> bool #foreign libskia;
// skcms_Matrix3x3_concat :: (unknown0: *skcms_Matrix3x3, unknown1: *skcms_Matrix3x3) -> skcms_Matrix3x3 #foreign libskia;

// A row-major 3x4 matrix (ie vals[row][col])
skcms_Matrix3x4 :: struct {
    vals: [3] [4] float;
}

// A transfer function mapping encoded values to linear values,
// represented by this 7-parameter piecewise function:
//
//   linear = sign(encoded) *  (c*|encoded| + f)       , 0 <= |encoded| < d
//          = sign(encoded) * ((a*|encoded| + b)^g + e), d <= |encoded|
//
// (A simple gamma transfer function sets g to gamma and a to 1.)
skcms_TransferFunction :: struct {
    g: float;
    a: float;
    b: float;
    c: float;
    d: float;
    e: float;
    f: float;
}

// skcms_TransferFunction_eval :: (unknown0: *skcms_TransferFunction, unknown1: float) -> float #foreign libskia;
// skcms_TransferFunction_invert :: (unknown0: *skcms_TransferFunction, unknown1: *skcms_TransferFunction) -> bool #foreign libskia;

skcms_TFType :: enum s32 {
    Invalid   :: 0;
    sRGBish   :: 1;
    PQish     :: 2;
    HLGish    :: 3;
    HLGinvish :: 4;
    PQ        :: 5;
    HLG       :: 6;

    skcms_TFType_Invalid   :: Invalid;
    skcms_TFType_sRGBish   :: sRGBish;
    skcms_TFType_PQish     :: PQish;
    skcms_TFType_HLGish    :: HLGish;
    skcms_TFType_HLGinvish :: HLGinvish;
    skcms_TFType_PQ        :: PQ;
    skcms_TFType_HLG       :: HLG;
}

// Identify which kind of transfer function is encoded in an skcms_TransferFunction
// skcms_TransferFunction_getType :: (unknown0: *skcms_TransferFunction) -> skcms_TFType #foreign libskia;

// We can jam a couple alternate transfer function forms into skcms_TransferFunction,
// including those matching the general forms of the SMPTE ST 2084 PQ function or HLG.
//
// PQish:
//                              max(A + B|encoded|^C, 0)
//    linear = sign(encoded) * (------------------------) ^ F
//                                  D + E|encoded|^C
// skcms_TransferFunction_makePQish :: (unknown0: *skcms_TransferFunction, A: float, B: float, C: float, D: float, E: float, F: float) -> bool #foreign libskia;

// HLGish:
//            { K * sign(encoded) * ( (R|encoded|)^G )          when 0   <= |encoded| <= 1/R
//   linear = { K * sign(encoded) * ( e^(a(|encoded|-c)) + b )  when 1/R <  |encoded|
// skcms_TransferFunction_makeScaledHLGish :: (unknown0: *skcms_TransferFunction, K: float, R: float, G: float, a: float, b: float, c: float) -> bool #foreign libskia;

// Compatibility shim with K=1 for old callers.
// skcms_TransferFunction_makeHLGish :: (fn: *skcms_TransferFunction, R: float, G: float, a: float, b: float, c: float) -> bool #foreign libskia "?skcms_TransferFunction_makeHLGish@@YA_NPEAUskcms_TransferFunction@@MMMMM@Z";

// The PQ transfer function. The function skcms_TransferFunction_eval will always evaluate to the
// unit PQ EOTF, which maps [0, 1] to [0, 1], regardless of the other parameters.
// This is stored differently from PQish transfer functions. In particular:
//   - the constant -5 is stored in g
//   - the hdr_reference_white_luminance parameter is stored in a
//   - all other parameters are set to 0
// When this is used as an SkColorSpace, the transformation to XYZD50 will be as follows:
//   1. Apply the unit PQ EOTF to each channel
//   2. Multiply by 10,000 nits
//   3. Divide by hdr_reference_white_luminance nits (default is 203)
//   4. Transform primaries to XYZD50
// skcms_TransferFunction_makePQ :: (unknown0: *skcms_TransferFunction, hdr_reference_white_luminance: float) -> void #foreign libskia;

// The HLG transfer function. The function skcms_TransferFunction_eval will always evaluate to the
// HLG inverse OETF, which maps [0, 1] to [0, 1], regardless of the other parameters.
// This is stored differently from PQish transfer functions. In particular:
//   - the constant -6 is stored in g
//   - the hdr_reference_white_luminance parameter is stored in a
//   - the peak_white_luminance parameter is stored in b
//   - the system_gamma parameter is stored in c
//   - all other parameters are set to 0
// When this is used as an SkColorSpace, the transformation to XYZD50 will be as follows:
//   1. Apply the HLG inverse OETF to each channel
//   2. Transform primaries to Rec2020
//   3. Apply the channel-mixing HLG OOTF using system_gamma (default is 1.2)
//   4. Multiply by peak_luminance nits (default is 1,000)
//   5. Divide by hdr_reference_white nits (default is 203)
//   6. Transform primaries to XYZD50
// skcms_TransferFunction_makeHLG :: (unknown0: *skcms_TransferFunction, hdr_reference_white_luminance: float, peak_luminance: float, system_gamma: float) -> void #foreign libskia;

// Is this an ordinary sRGB-ish transfer function, or one of the HDR forms we support?
// skcms_TransferFunction_isSRGBish :: (unknown0: *skcms_TransferFunction) -> bool #foreign libskia;
// skcms_TransferFunction_isPQish :: (unknown0: *skcms_TransferFunction) -> bool #foreign libskia;
// skcms_TransferFunction_isHLGish :: (unknown0: *skcms_TransferFunction) -> bool #foreign libskia;
// skcms_TransferFunction_isPQ :: (unknown0: *skcms_TransferFunction) -> bool #foreign libskia;
// skcms_TransferFunction_isHLG :: (unknown0: *skcms_TransferFunction) -> bool #foreign libskia;

// Unified representation of 'curv' or 'para' tag data, or a 1D table from 'mft1' or 'mft2'
skcms_Curve :: union {
    struct {
        // this needs to line up with alias_of_table_entries so we can tell if there are or
        // are not table entries. If this is 0, this struct is a parametric function,
        // otherwise it's a table entry.
        alias_of_table_entries: u32;
        parametric:             skcms_TransferFunction;
    }

    struct {
        table_entries: u32;
        table_8:       *u8;
        table_16:      *u8;
    }
}

// Complex transforms between device space (A) and profile connection space (B):
//   A2B:  device -> [ "A" curves -> CLUT ] -> [ "M" curves -> matrix ] -> "B" curves -> PCS
//   B2A:  device <- [ "A" curves <- CLUT ] <- [ "M" curves <- matrix ] <- "B" curves <- PCS
skcms_A2B :: struct {
    // Optional: N 1D "A" curves, followed by an N-dimensional CLUT.
    // If input_channels == 0, these curves and CLUT are skipped,
    // Otherwise, input_channels must be in [1, 4].
    input_curves:    [4] skcms_Curve;
    grid_8:          *u8;
    grid_16:         *u8;
    input_channels:  u32;
    grid_points:     [4] u8;

    // Optional: 3 1D "M" curves, followed by a color matrix.
    // If matrix_channels == 0, these curves and matrix are skipped,
    // Otherwise, matrix_channels must be 3.
    matrix_curves:   [3] skcms_Curve;
    matrix:          skcms_Matrix3x4;
    matrix_channels: u32;

    output_channels: u32; // list first to pack with matrix_channels
    output_curves:   [3] skcms_Curve;
}

skcms_B2A :: struct {
    // Required: 3 1D "B" curves. Always present, and input_channels must be 3.
    input_curves:    [3] skcms_Curve;
    input_channels:  u32;

    matrix_channels: u32; // list first to pack with input_channels
    matrix_curves:   [3] skcms_Curve;
    matrix:          skcms_Matrix3x4;

    // Optional: an N-dimensional CLUT, followed by N 1D "A" curves.
    // If output_channels == 0, this CLUT and these curves are skipped,
    // Otherwise, output_channels must be in [1, 4].
    output_curves:   [4] skcms_Curve;
    grid_8:          *u8;
    grid_16:         *u8;
    grid_points:     [4] u8;
    output_channels: u32;
}

skcms_CICP :: struct {
    color_primaries:          u8;
    transfer_characteristics: u8;
    matrix_coefficients:      u8;
    video_full_range_flag:    u8;
}

skcms_ICCProfile :: struct {
    buffer:           *u8;

    size:             u32;
    data_color_space: u32;
    pcs:              u32;
    tag_count:        u32;

    // If we can parse red, green and blue transfer curves from the profile,
    // trc will be set to those three curves, and has_trc will be true.
    trc:              [3] skcms_Curve;

    // If this profile's gamut can be represented by a 3x3 transform to XYZD50,
    // skcms_Parse() sets toXYZD50 to that transform and has_toXYZD50 to true.
    toXYZD50:         skcms_Matrix3x3;

    // If the profile has a valid A2B0 or A2B1 tag, skcms_Parse() sets A2B to
    // that data, and has_A2B to true.  skcms_ParseWithA2BPriority() does the
    // same following any user-provided prioritization of A2B0, A2B1, or A2B2.
    A2B:              skcms_A2B;

    // If the profile has a valid B2A0 or B2A1 tag, skcms_Parse() sets B2A to
    // that data, and has_B2A to true.  skcms_ParseWithA2BPriority() does the
    // same following any user-provided prioritization of B2A0, B2A1, or B2A2.
    B2A:              skcms_B2A;

    // If the profile has a valid CICP tag, skcms_Parse() sets CICP to that data,
    // and has_CICP to true.
    CICP:             skcms_CICP;

    has_trc:          bool;
    has_toXYZD50:     bool;
    has_A2B:          bool;
    has_B2A:          bool;
    has_CICP:         bool;
}

// The sRGB color profile is so commonly used that we offer a canonical skcms_ICCProfile for it.
// skcms_sRGB_profile :: () -> *skcms_ICCProfile #foreign libskia;

// Ditto for XYZD50, the most common profile connection space.
// skcms_XYZD50_profile :: () -> *skcms_ICCProfile #foreign libskia;

// skcms_sRGB_TransferFunction :: () -> *skcms_TransferFunction #foreign libskia;
// skcms_sRGB_Inverse_TransferFunction :: () -> *skcms_TransferFunction #foreign libskia;
// skcms_Identity_TransferFunction :: () -> *skcms_TransferFunction #foreign libskia;

// Practical equality test for two skcms_ICCProfiles.
// The implementation is subject to change, but it will always try to answer
// "can I substitute A for B?" and "can I skip transforming from A to B?".
// skcms_ApproximatelyEqualProfiles :: (A: *skcms_ICCProfile, B: *skcms_ICCProfile) -> bool #foreign libskia;

// Practical test that answers: Is curve roughly the inverse of inv_tf? Typically used by passing
// the inverse of a known parametric transfer function (like sRGB), to determine if a particular
// curve is very close to sRGB.
// skcms_AreApproximateInverses :: (curve: *skcms_Curve, inv_tf: *skcms_TransferFunction) -> bool #foreign libskia;

// Similar to above, answering the question for all three TRC curves of the given profile. Again,
// passing skcms_sRGB_InverseTransferFunction as inv_tf will answer the question:
// "Does this profile have a transfer function that is very close to sRGB?"
// skcms_TRCs_AreApproximateInverse :: (profile: *skcms_ICCProfile, inv_tf: *skcms_TransferFunction) -> bool #foreign libskia;

// Parse an ICC profile and return true if possible, otherwise return false.
// Selects an A2B profile (if present) according to priority list (each entry 0-2).
// The buffer is not copied; it must remain valid as long as the skcms_ICCProfile will be used.
// skcms_ParseWithA2BPriority :: (unknown0: *void, unknown1: u64, priority: *s32, priorities: s32, unknown2: *skcms_ICCProfile) -> bool #foreign libskia;

// skcms_Parse :: (buf: *void, len: u64, profile: *skcms_ICCProfile) -> bool #foreign libskia "?skcms_Parse@@YA_NPEBX_KPEAUskcms_ICCProfile@@@Z";

// skcms_ApproximateCurve :: (curve: *skcms_Curve, approx: *skcms_TransferFunction, max_error: *float) -> bool #foreign libskia;

// skcms_GetCHAD :: (unknown0: *skcms_ICCProfile, unknown1: *skcms_Matrix3x3) -> bool #foreign libskia;
// skcms_GetWTPT :: (unknown0: *skcms_ICCProfile, xyz: *[3] float) -> bool #foreign libskia;

// Returns the number of channels of input data that are expected on the "A" side of the profile.
// This is useful for image codecs, where the image data and the accompanying profile might have
// conflicting data shapes. In some cases, the result is unclear or invalid. In that case, the
// function will return a negative value to signal an error.
// skcms_GetInputChannelCount :: (unknown0: *skcms_ICCProfile) -> s32 #foreign libskia;

// These are common ICC signature values
skcms_Signature :: enum s32 {
    CMYK   :: 1129142603;
    Gray   :: 1196573017;
    RGB    :: 1380401696;

    Lab    :: 1281450528;
    XYZ    :: 1482250784;

    CIELUV :: 1282766368;
    YCbCr  :: 1497588338;
    CIEYxy :: 1501067552;
    HSV    :: 1213421088;
    HLS    :: 1212961568;
    CMY    :: 1129142560;
    _2CLR  :: 843271250;
    _3CLR  :: 860048466;
    _4CLR  :: 876825682;
    _5CLR  :: 893602898;
    _6CLR  :: 910380114;
    _7CLR  :: 927157330;
    _8CLR  :: 943934546;
    _9CLR  :: 960711762;
    _10CLR :: 1094929490;
    _11CLR :: 1111706706;
    _12CLR :: 1128483922;
    _13CLR :: 1145261138;
    _14CLR :: 1162038354;
    _15CLR :: 1178815570;

    skcms_Signature_CMYK   :: CMYK;
    skcms_Signature_Gray   :: Gray;
    skcms_Signature_RGB    :: RGB;

    skcms_Signature_Lab    :: Lab;
    skcms_Signature_XYZ    :: XYZ;

    skcms_Signature_CIELUV :: CIELUV;
    skcms_Signature_YCbCr  :: YCbCr;
    skcms_Signature_CIEYxy :: CIEYxy;
    skcms_Signature_HSV    :: HSV;
    skcms_Signature_HLS    :: HLS;
    skcms_Signature_CMY    :: CMY;
    skcms_Signature_2CLR   :: _2CLR;
    skcms_Signature_3CLR   :: _3CLR;
    skcms_Signature_4CLR   :: _4CLR;
    skcms_Signature_5CLR   :: _5CLR;
    skcms_Signature_6CLR   :: _6CLR;
    skcms_Signature_7CLR   :: _7CLR;
    skcms_Signature_8CLR   :: _8CLR;
    skcms_Signature_9CLR   :: _9CLR;
    skcms_Signature_10CLR  :: _10CLR;
    skcms_Signature_11CLR  :: _11CLR;
    skcms_Signature_12CLR  :: _12CLR;
    skcms_Signature_13CLR  :: _13CLR;
    skcms_Signature_14CLR  :: _14CLR;
    skcms_Signature_15CLR  :: _15CLR;
}

skcms_PixelFormat :: enum s32 {
    A_8              :: 0;
    A_8_             :: 1;
    G_8              :: 2;
    G_8_             :: 3;
    GA_88            :: 4;
    GA_88_           :: 5;

    RGB_565          :: 6;
    BGR_565          :: 7;

    ABGR_4444        :: 8;
    ARGB_4444        :: 9;

    RGB_888          :: 10;
    BGR_888          :: 11;
    RGBA_8888        :: 12;
    BGRA_8888        :: 13;
    RGBA_8888_sRGB   :: 14;
    BGRA_8888_sRGB   :: 15;

    RGBA_1010102     :: 16;
    BGRA_1010102     :: 17;

    RGB_161616LE     :: 18;
    BGR_161616LE     :: 19;
    RGBA_16161616LE  :: 20;
    BGRA_16161616LE  :: 21;

    RGB_161616BE     :: 22;
    BGR_161616BE     :: 23;
    RGBA_16161616BE  :: 24;
    BGRA_16161616BE  :: 25;

    RGB_hhh_Norm     :: 26;
    BGR_hhh_Norm     :: 27;
    RGBA_hhhh_Norm   :: 28;
    BGRA_hhhh_Norm   :: 29;

    RGB_hhh          :: 30;
    BGR_hhh          :: 31;
    RGBA_hhhh        :: 32;
    BGRA_hhhh        :: 33;

    RGB_fff          :: 34;
    BGR_fff          :: 35;
    RGBA_ffff        :: 36;
    BGRA_ffff        :: 37;

    RGB_101010x_XR   :: 38;
    BGR_101010x_XR   :: 39;
    RGBA_10101010_XR :: 40;
    BGRA_10101010_XR :: 41;

    skcms_PixelFormat_A_8              :: A_8;
    skcms_PixelFormat_A_8_             :: A_8_;
    skcms_PixelFormat_G_8              :: G_8;
    skcms_PixelFormat_G_8_             :: G_8_;
    skcms_PixelFormat_GA_88            :: GA_88;
    skcms_PixelFormat_GA_88_           :: GA_88_;

    skcms_PixelFormat_RGB_565          :: RGB_565;
    skcms_PixelFormat_BGR_565          :: BGR_565;

    skcms_PixelFormat_ABGR_4444        :: ABGR_4444;
    skcms_PixelFormat_ARGB_4444        :: ARGB_4444;

    skcms_PixelFormat_RGB_888          :: RGB_888;
    skcms_PixelFormat_BGR_888          :: BGR_888;
    skcms_PixelFormat_RGBA_8888        :: RGBA_8888;
    skcms_PixelFormat_BGRA_8888        :: BGRA_8888;
    skcms_PixelFormat_RGBA_8888_sRGB   :: RGBA_8888_sRGB;
    skcms_PixelFormat_BGRA_8888_sRGB   :: BGRA_8888_sRGB;

    skcms_PixelFormat_RGBA_1010102     :: RGBA_1010102;
    skcms_PixelFormat_BGRA_1010102     :: BGRA_1010102;

    skcms_PixelFormat_RGB_161616LE     :: RGB_161616LE;
    skcms_PixelFormat_BGR_161616LE     :: BGR_161616LE;
    skcms_PixelFormat_RGBA_16161616LE  :: RGBA_16161616LE;
    skcms_PixelFormat_BGRA_16161616LE  :: BGRA_16161616LE;

    skcms_PixelFormat_RGB_161616BE     :: RGB_161616BE;
    skcms_PixelFormat_BGR_161616BE     :: BGR_161616BE;
    skcms_PixelFormat_RGBA_16161616BE  :: RGBA_16161616BE;
    skcms_PixelFormat_BGRA_16161616BE  :: BGRA_16161616BE;

    skcms_PixelFormat_RGB_hhh_Norm     :: RGB_hhh_Norm;
    skcms_PixelFormat_BGR_hhh_Norm     :: BGR_hhh_Norm;
    skcms_PixelFormat_RGBA_hhhh_Norm   :: RGBA_hhhh_Norm;
    skcms_PixelFormat_BGRA_hhhh_Norm   :: BGRA_hhhh_Norm;

    skcms_PixelFormat_RGB_hhh          :: RGB_hhh;
    skcms_PixelFormat_BGR_hhh          :: BGR_hhh;
    skcms_PixelFormat_RGBA_hhhh        :: RGBA_hhhh;
    skcms_PixelFormat_BGRA_hhhh        :: BGRA_hhhh;

    skcms_PixelFormat_RGB_fff          :: RGB_fff;
    skcms_PixelFormat_BGR_fff          :: BGR_fff;
    skcms_PixelFormat_RGBA_ffff        :: RGBA_ffff;
    skcms_PixelFormat_BGRA_ffff        :: BGRA_ffff;

    skcms_PixelFormat_RGB_101010x_XR   :: RGB_101010x_XR;
    skcms_PixelFormat_BGR_101010x_XR   :: BGR_101010x_XR;
    skcms_PixelFormat_RGBA_10101010_XR :: RGBA_10101010_XR;
    skcms_PixelFormat_BGRA_10101010_XR :: BGRA_10101010_XR;
}

// We used to offer multiple types of premultiplication, but now just one, PremulAsEncoded.
// This is the premul you're probably used to working with.
skcms_AlphaFormat :: enum s32 {
    Opaque          :: 0;

    Unpremul        :: 1;

    PremulAsEncoded :: 2;

    skcms_AlphaFormat_Opaque          :: Opaque;

    skcms_AlphaFormat_Unpremul        :: Unpremul;

    skcms_AlphaFormat_PremulAsEncoded :: PremulAsEncoded;
}

// Convert npixels pixels from src format and color profile to dst format and color profile
// and return true, otherwise return false.  It is safe to alias dst == src if dstFmt == srcFmt.
// skcms_Transform :: (src: *void, srcFmt: skcms_PixelFormat, srcAlpha: skcms_AlphaFormat, srcProfile: *skcms_ICCProfile, dst: *void, dstFmt: skcms_PixelFormat, dstAlpha: skcms_AlphaFormat, dstProfile: *skcms_ICCProfile, npixels: u64) -> bool #foreign libskia;

// If profile can be used as a destination in skcms_Transform, return true. Otherwise, attempt to
// rewrite it with approximations where reasonable. If successful, return true. If no reasonable
// approximation exists, leave the profile unchanged and return false.
// skcms_MakeUsableAsDestination :: (profile: *skcms_ICCProfile) -> bool #foreign libskia;

// If profile can be used as a destination with a single parametric transfer function (ie for
// rasterization), return true. Otherwise, attempt to rewrite it with approximations where
// reasonable. If successful, return true. If no reasonable approximation exists, leave the
// profile unchanged and return false.
// skcms_MakeUsableAsDestinationWithSingleCurve :: (profile: *skcms_ICCProfile) -> bool #foreign libskia;

// Returns a matrix to adapt XYZ color from given the whitepoint to D50.
// skcms_AdaptToXYZD50 :: (wx: float, wy: float, toXYZD50: *skcms_Matrix3x3) -> bool #foreign libskia;

// Returns a matrix to convert RGB color into XYZ adapted to D50, given the
// primaries and whitepoint of the RGB model.
// skcms_PrimariesToXYZD50 :: (rx: float, ry: float, gx: float, gy: float, bx: float, by: float, wx: float, wy: float, toXYZD50: *skcms_Matrix3x3) -> bool #foreign libskia;

// Call before your first call to skcms_Transform() to skip runtime CPU detection.
// skcms_DisableRuntimeCPUDetection :: () -> void #foreign libskia;

// Utilities for programmatically constructing profiles
// skcms_Init :: (p: *skcms_ICCProfile) -> void #foreign libskia "?skcms_Init@@YAXPEAUskcms_ICCProfile@@@Z";

// skcms_SetTransferFunction :: (p: *skcms_ICCProfile, tf: *skcms_TransferFunction) -> void #foreign libskia "?skcms_SetTransferFunction@@YAXPEAUskcms_ICCProfile@@PEBUskcms_TransferFunction@@@Z";

// skcms_SetXYZD50 :: (p: *skcms_ICCProfile, m: *skcms_Matrix3x3) -> void #foreign libskia "?skcms_SetXYZD50@@YAXPEAUskcms_ICCProfile@@PEBUskcms_Matrix3x3@@@Z";

/**
*  Describes a color gamut with primaries and a white point.
*/
SkColorSpacePrimaries :: struct {
    fRX: float;
    fRY: float;
    fGX: float;
    fGY: float;
    fBX: float;
    fBY: float;
    fWX: float;
    fWY: float;

    /**
    *  Convert primaries and a white point to a toXYZD50 matrix, the preferred color gamut
    *  representation of SkColorSpace.
    */
    toXYZD50 :: (this: *SkColorSpacePrimaries, toXYZD50: *skcms_Matrix3x3) -> bool #cpp_method #foreign libskia "?toXYZD50@SkColorSpacePrimaries@@QEBA_NPEAUskcms_Matrix3x3@@@Z";
}

SkNamedPrimaries :: struct {
    // Mapping between names of color primaries and the number of the corresponding
    // row in ITU-T H.273, table 2.  As above, the constants are named based on the
    // first specification referenced in the value's row.
    CicpId :: enum u8 {
        Rec709             :: 1;

        Rec470SystemM      :: 4;
        Rec470SystemBG     :: 5;
        Rec601             :: 6;
        SMPTE_ST_240       :: 7;
        GenericFilm        :: 8;
        Rec2020            :: 9;
        SMPTE_ST_428_1     :: 10;
        SMPTE_RP_431_2     :: 11;
        SMPTE_EG_432_1     :: 12;

        ITU_T_H273_Value22 :: 22;

        kRec709             :: Rec709;

        kRec470SystemM      :: Rec470SystemM;
        kRec470SystemBG     :: Rec470SystemBG;
        kRec601             :: Rec601;
        kSMPTE_ST_240       :: SMPTE_ST_240;
        kGenericFilm        :: GenericFilm;
        kRec2020            :: Rec2020;
        kSMPTE_ST_428_1     :: SMPTE_ST_428_1;
        kSMPTE_RP_431_2     :: SMPTE_RP_431_2;
        kSMPTE_EG_432_1     :: SMPTE_EG_432_1;

        kITU_T_H273_Value22 :: ITU_T_H273_Value22;
    }
}

SkNamedTransferFn :: struct {
    // Mapping between transfer function names and the number of the corresponding
    // row in ITU-T H.273, table 3.  As above, the constants are named based on the
    // first specification referenced in the value's row.
    CicpId :: enum u8 {
        Rec709         :: 1;

        Rec470SystemM  :: 4;
        Rec470SystemBG :: 5;
        Rec601         :: 6;
        SMPTE_ST_240   :: 7;
        Linear         :: 8;

        IEC61966_2_4   :: 11;

        IEC61966_2_1   :: 13;
        SRGB           :: 13;
        Rec2020_10bit  :: 14;
        Rec2020_12bit  :: 15;
        PQ             :: 16;
        SMPTE_ST_428_1 :: 17;
        HLG            :: 18;

        kRec709         :: Rec709;

        kRec470SystemM  :: Rec470SystemM;
        kRec470SystemBG :: Rec470SystemBG;
        kRec601         :: Rec601;
        kSMPTE_ST_240   :: SMPTE_ST_240;
        kLinear         :: Linear;

        kIEC61966_2_4   :: IEC61966_2_4;

        kIEC61966_2_1   :: IEC61966_2_1;
        kSRGB           :: SRGB;
        kRec2020_10bit  :: Rec2020_10bit;
        kRec2020_12bit  :: Rec2020_12bit;
        kPQ             :: PQ;
        kSMPTE_ST_428_1 :: SMPTE_ST_428_1;
        kHLG            :: HLG;
    }
}

SkColorSpace :: struct {
    #as using sknvrefcnt: SkNVRefCnt(SkColorSpace);

    /**
    *  Create the sRGB color space.
    */
    MakeSRGB :: () -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?MakeSRGB@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /**
    *  Colorspace with the sRGB primaries, but a linear (1.0) gamma.
    */
    MakeSRGBLinear :: () -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?MakeSRGBLinear@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /**
    *  Create an SkColorSpace from a transfer function and a row-major 3x3 transformation to XYZ.
    */
    MakeRGB :: (transferFn: *skcms_TransferFunction, toXYZ: *skcms_Matrix3x3) -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?MakeRGB@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@AEBUskcms_TransferFunction@@AEBUskcms_Matrix3x3@@@Z";
    MakeRGB :: (transferFn: skcms_TransferFunction, toXYZ: skcms_Matrix3x3) -> sk_sp(SkColorSpace) #no_context {
        return MakeRGB(*transferFn, *toXYZ);
    }

    /**
    *  Create an SkColorSpace from code points specified in Rec. ITU-T H.273.
    *  Null will be returned for invalid or unsupported combination of code
    *  points.
    *
    *  Parameters:
    *
    * - `color_primaries` identifies an entry in Rec. ITU-T H.273, Table 2.
    * - `transfer_characteristics` identifies an entry in Rec. ITU-T H.273, Table 3.
    *
    * `SkColorSpace` (and the underlying `skcms_ICCProfile`) only supports RGB
    * color spaces and therefore this function does not take a
    * `matrix_coefficients` parameter - the caller is expected to verify that
    * `matrix_coefficients` is `0`.
    *
    * Narrow range images are extremely rare - see
    * https://github.com/w3c/png/issues/312#issuecomment-2327349614.  Therefore
    * this function doesn't take a `video_full_range_flag` - the caller is
    * expected to verify that it is `1` (indicating a full range image).
    */
    MakeCICP :: (color_primaries: SkNamedPrimaries.CicpId, transfer_characteristics: SkNamedTransferFn.CicpId) -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?MakeCICP@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@W4CicpId@SkNamedPrimaries@@W43SkNamedTransferFn@@@Z";

    /**
    *  Create an SkColorSpace from a parsed (skcms) ICC profile.
    */
    Make :: (unknown0: *skcms_ICCProfile) -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?Make@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@AEBUskcms_ICCProfile@@@Z";
    Make :: (unknown0: skcms_ICCProfile) -> sk_sp(SkColorSpace) #no_context {
        return Make(*unknown0);
    }

    /**
    *  Convert this color space to an skcms ICC profile struct.
    */
    toProfile :: (this: *SkColorSpace, unknown0: *skcms_ICCProfile) -> void #cpp_method #foreign libskia "?toProfile@SkColorSpace@@QEBAXPEAUskcms_ICCProfile@@@Z";

    /**
    *  Returns true if the color space gamma is near enough to be approximated as sRGB.
    */
    gammaCloseToSRGB :: (this: *SkColorSpace) -> bool #cpp_method #foreign libskia "?gammaCloseToSRGB@SkColorSpace@@QEBA_NXZ";

    /**
    *  Returns true if the color space gamma is linear.
    */
    gammaIsLinear :: (this: *SkColorSpace) -> bool #cpp_method #foreign libskia "?gammaIsLinear@SkColorSpace@@QEBA_NXZ";

    /**
    *  Sets |fn| to the transfer function from this color space. Returns true if the transfer
    *  function can be represented as coefficients to the standard ICC 7-parameter equation.
    *  Returns false otherwise (eg, PQ, HLG).
    */
    isNumericalTransferFn :: (this: *SkColorSpace, fn: *skcms_TransferFunction) -> bool #cpp_method #foreign libskia "?isNumericalTransferFn@SkColorSpace@@QEBA_NPEAUskcms_TransferFunction@@@Z";

    /**
    *  Returns true and sets |toXYZD50|.
    */
    toXYZD50 :: (this: *SkColorSpace, toXYZD50: *skcms_Matrix3x3) -> bool #cpp_method #foreign libskia "?toXYZD50@SkColorSpace@@QEBA_NPEAUskcms_Matrix3x3@@@Z";

    /**
    *  Returns a hash of the gamut transformation to XYZ D50. Allows for fast equality checking
    *  of gamuts, at the (very small) risk of collision.
    */
    toXYZD50Hash :: (this: *SkColorSpace) -> u32 #cpp_method #foreign libskia "?toXYZD50Hash@SkColorSpace@@QEBAIXZ";

    /**
    *  Returns a color space with the same gamut as this one, but with a linear gamma.
    */
    makeLinearGamma :: (this: *SkColorSpace) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeLinearGamma@SkColorSpace@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /**
    *  Returns a color space with the same gamut as this one, but with the sRGB transfer
    *  function.
    */
    makeSRGBGamma :: (this: *SkColorSpace) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeSRGBGamma@SkColorSpace@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /**
    *  Returns a color space with the same transfer function as this one, but with the primary
    *  colors rotated. In other words, this produces a new color space that maps RGB to GBR
    *  (when applied to a source), and maps RGB to BRG (when applied to a destination).
    *
    *  This is used for testing, to construct color spaces that have severe and testable behavior.
    */
    makeColorSpin :: (this: *SkColorSpace) -> sk_sp(SkColorSpace) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorSpin@SkColorSpace@@QEBA?AV?$sk_sp@VSkColorSpace@@@@XZ";

    /**
    *  Returns true if the color space is sRGB.
    *  Returns false otherwise.
    *
    *  This allows a little bit of tolerance, given that we might see small numerical error
    *  in some cases: converting ICC fixed point to float, converting white point to D50,
    *  rounding decisions on transfer function and matrix.
    *
    *  This does not consider a 2.2f exponential transfer function to be sRGB. While these
    *  functions are similar (and it is sometimes useful to consider them together), this
    *  function checks for logical equality.
    */
    isSRGB :: (this: *SkColorSpace) -> bool #cpp_method #foreign libskia "?isSRGB@SkColorSpace@@QEBA_NXZ";

    /**
    *  Returns a serialized representation of this color space.
    */
    serialize :: (this: *SkColorSpace) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@SkColorSpace@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

    /**
    *  If |memory| is nullptr, returns the size required to serialize.
    *  Otherwise, serializes into |memory| and returns the size.
    */
    writeToMemory :: (this: *SkColorSpace, memory: *void) -> u64 #cpp_method #foreign libskia "?writeToMemory@SkColorSpace@@QEBA_KPEAX@Z";

    Deserialize :: (data: *void, length: u64) -> sk_sp(SkColorSpace) #cpp_return_type_is_non_pod #foreign libskia "?Deserialize@SkColorSpace@@SA?AV?$sk_sp@VSkColorSpace@@@@PEBX_K@Z";

    /**
    *  If both are null, we return true. If one is null and the other is not, we return false.
    *  If both are non-null, we do a deeper compare.
    */
    Equals :: (unknown0: *SkColorSpace, unknown1: *SkColorSpace) -> bool #foreign libskia "?Equals@SkColorSpace@@SA_NPEBV1@0@Z";

    transferFn :: (this: *SkColorSpace, gabcdef: *[7] float) -> void #cpp_method #foreign libskia "?transferFn@SkColorSpace@@QEBAXQEAM@Z";
    transferFn :: (this: *SkColorSpace, fn: *skcms_TransferFunction) -> void #cpp_method #foreign libskia "?transferFn@SkColorSpace@@QEBAXPEAUskcms_TransferFunction@@@Z";
    invTransferFn :: (this: *SkColorSpace, fn: *skcms_TransferFunction) -> void #cpp_method #foreign libskia "?invTransferFn@SkColorSpace@@QEBAXPEAUskcms_TransferFunction@@@Z";
    gamutTransformTo :: (this: *SkColorSpace, dst: *SkColorSpace, src_to_dst: *skcms_Matrix3x3) -> void #cpp_method #foreign libskia "?gamutTransformTo@SkColorSpace@@QEBAXPEBV1@PEAUskcms_Matrix3x3@@@Z";

    transferFnHash :: (this: *SkColorSpace) -> u32 #cpp_method #foreign libskia "?transferFnHash@SkColorSpace@@QEBAIXZ";
    hash :: (this: *SkColorSpace) -> u64 #cpp_method #foreign libskia "?hash@SkColorSpace@@QEBA_KXZ";

    Constructor :: (this: *SkColorSpace, transferFn: *skcms_TransferFunction, toXYZ: *skcms_Matrix3x3) -> void #cpp_method #foreign libskia "??0SkColorSpace@@AEAA@AEBUskcms_TransferFunction@@AEBUskcms_Matrix3x3@@@Z";
    Constructor :: (this: *SkColorSpace, transferFn: skcms_TransferFunction, toXYZ: skcms_Matrix3x3) #no_context {
        Constructor(this, *transferFn, *toXYZ);
    }

    computeLazyDstFields :: (this: *SkColorSpace) -> void #cpp_method #foreign libskia "?computeLazyDstFields@SkColorSpace@@AEBAXXZ";

    fTransferFnHash:      u32;
    fToXYZD50Hash:        u32;

    fTransferFn:          skcms_TransferFunction;
    fToXYZD50:            skcms_Matrix3x3;

    fInvTransferFn:       skcms_TransferFunction;
    fFromXYZD50:          skcms_Matrix3x3;
    fLazyDstFieldsOnce:   SkOnce;
}

skhdr :: struct {
    /**
    * Content light level metadata.
    * The semantics of this metadata is defined in:
    *   ANSI/CTA-861-H A DTV Profile for Uncompressed High Speed Digital Interfaces
    *   Annex P Calculation of MaxCLL and MaxFALL
    * Slightly different semantics for this metadata are defined in:
    *   Portable Network Graphics (PNG) Specification (Third Edition)
    *   11.3.2.8 cLLI Content Light Level Information
    *   https://www.w3.org/TR/png-3/#cLLI-chunk
    * This metadata should only be used in ways that work with both semantics.
    */
    ContentLightLevelInformation :: struct {
        fMaxCLL:  float = 0.0;
        fMaxFALL: float = 0.0;

        /**
        * Decode from the binary encoding listed at:
        *   AV1 Bitstream & Decoding Process Specification Version 1.0.0 Errata 1
        *   https://aomediacodec.github.io/av1-spec/av1-spec.pdf
        *   5.8.3 Metadata high dynamic range content light level syntax
        * This encoding is equivalent to:
        *   ITU-T H.265 (V10) (07/2024)
        *   D.2.35 Content light level information SEI message syntax
        * Return false if parsing fails.
        */
        parse :: (this: *ContentLightLevelInformation, data: *SkData) -> bool #cpp_method #foreign libskia "?parse@ContentLightLevelInformation@skhdr@@QEAA_NPEBVSkData@@@Z";

        /**
        * Serialize to the encoding used by parse().
        */
        serialize :: (this: *ContentLightLevelInformation) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@ContentLightLevelInformation@skhdr@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

        /**
        * Decode from the binary encoding listed at:
        *   Portable Network Graphics (PNG) Specification (Third Edition)
        *   11.3.2.8 cLLI Content Light Level Information
        *   https://www.w3.org/TR/png-3/#cLLI-chunk
        * This encoding is not equivalent to the encoding used by parse().
        * Return false if parsing fails.
        */
        parsePngChunk :: (this: *ContentLightLevelInformation, data: *SkData) -> bool #cpp_method #foreign libskia "?parsePngChunk@ContentLightLevelInformation@skhdr@@QEAA_NPEBVSkData@@@Z";

        /**
        * Serialize to the encoding used by parsePngChunk().
        */
        serializePngChunk :: (this: *ContentLightLevelInformation) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serializePngChunk@ContentLightLevelInformation@skhdr@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

        /**
        * Return a human-readable description.
        */
        toString :: (this: *ContentLightLevelInformation) -> SkString #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?toString@ContentLightLevelInformation@skhdr@@QEBA?AVSkString@@XZ";
    }

    operator_eq :: (this: *skhdr.ContentLightLevelInformation, other: *skhdr.ContentLightLevelInformation) -> bool #cpp_method #foreign libskia "??8ContentLightLevelInformation@skhdr@@QEBA_NAEBU01@@Z";
    operator_eq :: (this: skhdr.ContentLightLevelInformation, other: skhdr.ContentLightLevelInformation) -> bool #no_context {
        return operator_eq(*this, *other);
    }
    operator_neq :: (this: *skhdr.ContentLightLevelInformation, other: *skhdr.ContentLightLevelInformation) -> bool #cpp_method #foreign libskia "??9ContentLightLevelInformation@skhdr@@QEBA_NAEBU01@@Z";
    operator_neq :: (this: skhdr.ContentLightLevelInformation, other: skhdr.ContentLightLevelInformation) -> bool #no_context {
        return operator_neq(*this, *other);
    }

    /**
    * Mastering display color volume metadata.
    * The semantics of this metadata is defined in:
    * SMPTE ST 2086:2018 Mastering Display Color Volume Metadata Supporting
    * High Luminance and Wide Color Gamut Images
    */
    MasteringDisplayColorVolume :: struct {
        fDisplayPrimaries:                 SkColorSpacePrimaries;
        fMaximumDisplayMasteringLuminance: float = 0.0;
        fMinimumDisplayMasteringLuminance: float = 0.0;

        /**
        * The encoding as defined in:
        *   AV1 Bitstream & Decoding Process Specification Version 1.0.0 Errata 1
        *   https://aomediacodec.github.io/av1-spec/av1-spec.pdf
        *   5.8.4 Metadata high dynamic range mastering display color volume syntax
        * This encoding is equivalent to:
        *   ITU-T H.265 (V10) (07/2024)
        *   D.2.35 Content light level information SEI message syntax
        * This encoding is also equivalent to:
        *   Portable Network Graphics (PNG) Specification (Third Edition)
        *   11.3.2.7 mDCV Mastering Display Color Volume
        *   https://www.w3.org/TR/png-3/#mDCV-chunk
        * Return false if parsing fails.
        */
        parse :: (this: *MasteringDisplayColorVolume, data: *SkData) -> bool #cpp_method #foreign libskia "?parse@MasteringDisplayColorVolume@skhdr@@QEAA_NPEBVSkData@@@Z";

        /**
        * Serialize to the encoding used by parse().
        */
        serialize :: (this: *MasteringDisplayColorVolume) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@MasteringDisplayColorVolume@skhdr@@QEBA?AV?$sk_sp@VSkData@@@@XZ";

        /**
        * Return a human-readable description.
        */
        toString :: (this: *MasteringDisplayColorVolume) -> SkString #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?toString@MasteringDisplayColorVolume@skhdr@@QEBA?AVSkString@@XZ";
    }

    operator_eq :: (this: *skhdr.MasteringDisplayColorVolume, other: *skhdr.MasteringDisplayColorVolume) -> bool #cpp_method #foreign libskia "??8MasteringDisplayColorVolume@skhdr@@QEBA_NAEBU01@@Z";
    operator_eq :: (this: skhdr.MasteringDisplayColorVolume, other: skhdr.MasteringDisplayColorVolume) -> bool #no_context {
        return operator_eq(*this, *other);
    }
    operator_neq :: (this: *skhdr.MasteringDisplayColorVolume, other: *skhdr.MasteringDisplayColorVolume) -> bool #cpp_method #foreign libskia "??9MasteringDisplayColorVolume@skhdr@@QEBA_NAEBU01@@Z";
    operator_neq :: (this: skhdr.MasteringDisplayColorVolume, other: skhdr.MasteringDisplayColorVolume) -> bool #no_context {
        return operator_neq(*this, *other);
    }

    /**
    * Adaptive Global Tone Mapping HDR metadata
    * The semantics of this metadata is defined in:
    * SMPTE ST 2094-50: Dynamic metadata for color volume transform — Application #5
    * Under development at:
    * https://github.com/SMPTE/st2094-50
    */
    Agtm :: struct {
        vtable:                    *Agtm_VTable;

        /**
        * Parse the specified SkData. Returns nullptr if the data fails to parse.
        */
        Make :: (data: *SkData) -> std.unique_ptr(Agtm) #cpp_return_type_is_non_pod #foreign libskia "?Make@Agtm@skhdr@@SA?AV?$unique_ptr@VAgtm@skhdr@@U?$default_delete@VAgtm@skhdr@@@std@@@std@@PEBVSkData@@@Z";

        /**
        * Generate reference white tone mapping metadata for the specified baseline HDR headroom and
        * HDR reference white values.
        */
        MakeReferenceWhite :: (hdrReferenceWhite: float, baselineHdrHeadroom: float) -> std.unique_ptr(Agtm) #cpp_return_type_is_non_pod #foreign libskia "?MakeReferenceWhite@Agtm@skhdr@@SA?AV?$unique_ptr@VAgtm@skhdr@@U?$default_delete@VAgtm@skhdr@@@std@@@std@@MM@Z";

        /**
        * Generate metadata with a HDR reference white set to `hdrReferenceWhite`, that specifies that
        * no tone mapping is to be done (that is, just clamping is to be performed), and that the
        * content has HDR headroom specified by `baselineHdrHeadroom`.
        */
        MakeClamp :: (hdrReferenceWhite: float, baselineHdrHeadroom: float) -> std.unique_ptr(Agtm) #cpp_return_type_is_non_pod #foreign libskia "?MakeClamp@Agtm@skhdr@@SA?AV?$unique_ptr@VAgtm@skhdr@@U?$default_delete@VAgtm@skhdr@@@std@@@std@@MM@Z";

        /**
        * The default value for the HdrReferenceWhite metadata item.
        */
        kDefaultHdrReferenceWhite: float : 203.0;

        // Virtual functions:
        // Normally you should call them via the vtable.
        // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
        // or need to create a vtable yourself.

        virtual_Destructor :: (this: *Agtm, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1Agtm@skhdr@@UEAA@XZ";

        /**
        * Serialize the data to the format parsed by Make.
        */
//         virtual_serialize :: (this: *Agtm) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?serialize@Agtm@skhdr@@UEBA?AV?$sk_sp@VSkData@@@@XZ";

        /**
        * Return the HdrReferenceWhite metadata item value.
        */
//         virtual_getHdrReferenceWhite :: (this: *Agtm) -> float #cpp_method #foreign libskia "?getHdrReferenceWhite@Agtm@skhdr@@UEBAMXZ";

        /**
        * Functions to query if the BaselineHdrHeadroom metadata item was specified and retrieve it
        * (which will assert if was not specified).
        */
//         virtual_hasBaselineHdrHeadroom :: (this: *Agtm) -> bool #cpp_method #foreign libskia "?hasBaselineHdrHeadroom@Agtm@skhdr@@UEBA_NXZ";
//         virtual_getBaselineHdrHeadroom :: (this: *Agtm) -> float #cpp_method #foreign libskia "?getBaselineHdrHeadroom@Agtm@skhdr@@UEBAMXZ";

        /**
        * Return true if this metadata specifies not to do any tone mapping (it is the type that
        * was created using MakeClamp).
        */
//         virtual_isClamp :: (this: *Agtm) -> bool #cpp_method #foreign libskia "?isClamp@Agtm@skhdr@@UEBA_NXZ";

        /**
        * Return the SkColorFilter to tone map to the specified targeted HDR headroom.
        */
//         virtual_makeColorFilter :: (this: *Agtm, targetedHdrHeadroom: float) -> sk_sp(SkColorFilter) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?makeColorFilter@Agtm@skhdr@@UEBA?AV?$sk_sp@VSkColorFilter@@@@M@Z";

        /**
        * Return a human-readable description.
        */
//         virtual_toString :: (this: *Agtm) -> SkString #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?toString@Agtm@skhdr@@UEBA?AVSkString@@XZ";
    }
    Agtm_VTable :: struct #type_info_none {
        Destructor:             #type (this: *skhdr.Agtm, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

        serialize:              #type (this: *skhdr.Agtm) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod;

        getHdrReferenceWhite:   #type (this: *skhdr.Agtm) -> float #cpp_method;

        hasBaselineHdrHeadroom: #type (this: *skhdr.Agtm) -> bool #cpp_method;
        getBaselineHdrHeadroom: #type (this: *skhdr.Agtm) -> float #cpp_method;

        isClamp:                #type (this: *skhdr.Agtm) -> bool #cpp_method;

        makeColorFilter:        #type (this: *skhdr.Agtm, targetedHdrHeadroom: float) -> sk_sp(SkColorFilter) #cpp_method #cpp_return_type_is_non_pod;

        toString:               #type (this: *skhdr.Agtm) -> SkString #cpp_method #cpp_return_type_is_non_pod;
    }
    Agtm_Destructor :: inline (this: *Agtm, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

    Agtm_serialize :: inline (this: *Agtm) -> sk_sp(SkData) { return this.vtable.serialize(this); }

    Agtm_getHdrReferenceWhite :: inline (this: *Agtm) -> float { return this.vtable.getHdrReferenceWhite(this); }

    Agtm_hasBaselineHdrHeadroom :: inline (this: *Agtm) -> bool { return this.vtable.hasBaselineHdrHeadroom(this); }
    Agtm_getBaselineHdrHeadroom :: inline (this: *Agtm) -> float { return this.vtable.getBaselineHdrHeadroom(this); }

    Agtm_isClamp :: inline (this: *Agtm) -> bool { return this.vtable.isClamp(this); }

    Agtm_makeColorFilter :: inline (this: *Agtm, targetedHdrHeadroom: float) -> sk_sp(SkColorFilter) { return this.vtable.makeColorFilter(this, targetedHdrHeadroom); }

    Agtm_toString :: inline (this: *Agtm) -> SkString { return this.vtable.toString(this); }

    get_vtable :: (obj: *Agtm) -> *Agtm_VTable { return obj.vtable; }


    /**
    * Structure containing all HDR metadata that can be attached to an image or video frame.
    */
    Metadata :: struct {
        /**
        * Return a container with no metadata.
        */
        MakeEmpty :: () -> Metadata #foreign libskia "?MakeEmpty@Metadata@skhdr@@SA?AV12@XZ";

        /**
        * If there does not exists Content Light Level Information metadata, then return false.
        * Otherwise return true and if `clli` is non-nullptr then write the metadata to `clli`.
        */
        getContentLightLevelInformation :: (this: *Metadata, clli: *ContentLightLevelInformation) -> bool #cpp_method #foreign libskia "?getContentLightLevelInformation@Metadata@skhdr@@QEBA_NPEAUContentLightLevelInformation@2@@Z";

        /**
        * Set the Content Light Level Information metadata.
        */
        setContentLightLevelInformation :: (this: *Metadata, clli: *ContentLightLevelInformation) -> void #cpp_method #foreign libskia "?setContentLightLevelInformation@Metadata@skhdr@@QEAAXAEBUContentLightLevelInformation@2@@Z";
        setContentLightLevelInformation :: (this: *Metadata, clli: ContentLightLevelInformation) #no_context {
            setContentLightLevelInformation(this, *clli);
        }

        /**
        * If there does not exists Mastering Display Color Volume metadata, then return false.
        * Otherwise return true and if `mdcv` is non-nullptr then write the metadata to `mdcv`.
        */
        getMasteringDisplayColorVolume :: (this: *Metadata, mdcv: *MasteringDisplayColorVolume) -> bool #cpp_method #foreign libskia "?getMasteringDisplayColorVolume@Metadata@skhdr@@QEBA_NPEAUMasteringDisplayColorVolume@2@@Z";

        /**
        * Set the Mastering Display Color Volume metadata.
        */
        setMasteringDisplayColorVolume :: (this: *Metadata, mdcv: *MasteringDisplayColorVolume) -> void #cpp_method #foreign libskia "?setMasteringDisplayColorVolume@Metadata@skhdr@@QEAAXAEBUMasteringDisplayColorVolume@2@@Z";
        setMasteringDisplayColorVolume :: (this: *Metadata, mdcv: MasteringDisplayColorVolume) #no_context {
            setMasteringDisplayColorVolume(this, *mdcv);
        }

        /**
        * Return the serialized Adaptive Global Tone Mapping metadata, or nullptr if none has been set.
        */
        getSerializedAgtm :: (this: *Metadata) -> sk_sp(SkData) #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?getSerializedAgtm@Metadata@skhdr@@QEBA?AV?$sk_sp@$$CBVSkData@@@@XZ";

        /**
        * Set the serialized Adaptive Global Tone Mapping metadata.
        */
        setSerializedAgtm :: (this: *Metadata, unknown0: sk_sp(SkData)) -> void #cpp_method #foreign libskia "?setSerializedAgtm@Metadata@skhdr@@QEAAXV?$sk_sp@$$CBVSkData@@@@@Z";

        /**
        * Return a human-readable description.
        */
        toString :: (this: *Metadata) -> SkString #cpp_method #cpp_return_type_is_non_pod #foreign libskia "?toString@Metadata@skhdr@@QEBA?AVSkString@@XZ";

        fContentLightLevelInformation: std.optional(ContentLightLevelInformation);
        fMasteringDisplayColorVolume:  std.optional(MasteringDisplayColorVolume);
        fAgtm:                         sk_sp(SkData);
    }

    operator_eq :: (this: *skhdr.Metadata, other: *skhdr.Metadata) -> bool #cpp_method #foreign libskia "??8Metadata@skhdr@@QEBA_NAEBV01@@Z";
    operator_eq :: (this: skhdr.Metadata, other: skhdr.Metadata) -> bool #no_context {
        return operator_eq(*this, *other);
    }
    operator_neq :: (this: *skhdr.Metadata, other: *skhdr.Metadata) -> bool #cpp_method #foreign libskia "??9Metadata@skhdr@@QEBA_NAEBV01@@Z";
    operator_neq :: (this: skhdr.Metadata, other: skhdr.Metadata) -> bool #no_context {
        return operator_neq(*this, *other);
    }
}

/** \class SkNoncopyable (DEPRECATED)

SkNoncopyable is the base class for objects that do not want to
be copied. It hides its copy-constructor and its assignment-operator.
*/
SkNoncopyable :: struct {
    using sknoncopyable__raw: SkNoncopyable__RAW;
    __empty_struct_padding:   u8; // C++ makes empty structs have length 1
}
// SkNoncopyable without empty struct padding. Needed to generate a C++-equivalent struct layout when "inheriting" from SkNoncopyable
SkNoncopyable__RAW :: struct {
//     Constructor :: (this: *SkNoncopyable) -> void #cpp_method #foreign libskia "??0SkNoncopyable@@QEAA@XZ";

//     CopyConstructor :: (this: *SkNoncopyable, unknown0: *SkNoncopyable) -> void #cpp_method #foreign libskia "??0SkNoncopyable@@AEAA@AEBV0@@Z";
    CopyConstructor :: (this: *SkNoncopyable, unknown0: SkNoncopyable) #no_context {
        CopyConstructor(this, *unknown0);
    }
}
// operator_assign :: (this: *SkNoncopyable, unknown0: *SkNoncopyable) -> *SkNoncopyable #cpp_method #foreign libskia "??4SkNoncopyable@@AEAAAEAV0@AEBV0@@Z";
operator_assign :: (this: *SkNoncopyable, unknown0: SkNoncopyable) -> *SkNoncopyable #no_context {
    return operator_assign(this, *unknown0);
}

SkEncoder :: struct {
    vtable:               *SkEncoder_VTable;
    using skencoder__raw: SkEncoder__RAW;
    #place sknoncopyable__raw; #as sknoncopyable: SkNoncopyable; // Support cast to SkNoncopyable
}
// SkEncoder without vtable pointer. Needed to generate a C++-equivalent struct layout when "inheriting" from SkEncoder
SkEncoder__RAW :: struct {
    using sknoncopyable__raw: SkNoncopyable__RAW;

    /**
    * A single frame to be encoded into an animated image.
    *
    * If a frame does not fit in the canvas size, this is an error.
    * TODO(skbug.com/40044793): Add offsets when we have support for an encoder that supports using
    * offsets.
    */
    Frame :: struct {
        /**
        *  Pixmap of the frame.
        */
        pixmap:   SkPixmap;

        /**
        *  Duration of the frame in millseconds.
        */
        duration: s32;
    }

    /**
    *  Encode |numRows| rows of input.  If the caller requests more rows than are remaining
    *  in the src, this will encode all of the remaining rows.  |numRows| must be greater
    *  than zero.
    */
    encodeRows :: (this: *SkEncoder, numRows: s32) -> bool #cpp_method #foreign libskia "?encodeRows@SkEncoder@@QEAA_NH@Z";

    Constructor :: (this: *SkEncoder, src: *SkPixmap, storageBytes: u64) -> void #cpp_method #foreign libskia "??0SkEncoder@@IEAA@AEBVSkPixmap@@_K@Z";
    Constructor :: (this: *SkEncoder, src: SkPixmap, storageBytes: u64) #no_context {
        Constructor(this, *src, storageBytes);
    }

    fSrc:                     *SkPixmap;
    fCurrRow:                 s32;
    fStorage:                 skia_private.AutoTMalloc(u8);

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *SkEncoder, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign libskia "??1SkEncoder@@UEAA@XZ";

//     virtual_onEncodeRows :: (this: *SkEncoder, numRows: s32) -> bool #cpp_method #foreign libskia "?onEncodeRows@SkEncoder@@MEAA_NH@Z";
}
SkEncoder_VTable :: struct #type_info_none {
    Destructor:   #type (this: *SkEncoder, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    onEncodeRows: #type (this: *SkEncoder, numRows: s32) -> bool #cpp_method;
}
SkEncoder_Destructor :: inline (this: *SkEncoder, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

SkEncoder_onEncodeRows :: inline (this: *SkEncoder, numRows: s32) -> bool { return this.vtable.onEncodeRows(this, numRows); }

get_vtable :: (obj: *SkEncoder) -> *SkEncoder_VTable { return obj.vtable; }


SkGainmapInfo :: struct {}

SkPngEncoder :: struct {
    FilterFlag :: enum s32 {
        Zero  :: 0;
        None  :: 8;
        Sub   :: 16;
        Up    :: 32;
        Avg   :: 64;
        Paeth :: 128;
        All   :: 248;

        kZero  :: Zero;
        kNone  :: None;
        kSub   :: Sub;
        kUp    :: Up;
        kAvg   :: Avg;
        kPaeth :: Paeth;
        kAll   :: All;
    }

//     operator| :: (x: FilterFlag, y: FilterFlag) -> FilterFlag #foreign libskia "??USkPngEncoder@@YA?AW4FilterFlag@0@W410@0@Z";

    Options :: struct {
        /**
        *  Selects which filtering strategies to use.
        *
        *  If a single filter is chosen, libpng will use that filter for every row.
        *
        *  If multiple filters are chosen, libpng will use a heuristic to guess which filter
        *  will encode smallest, then apply that filter.  This happens on a per row basis,
        *  different rows can use different filters.
        *
        *  Using a single filter (or less filters) is typically faster.  Trying all of the
        *  filters may help minimize the output file size.
        *
        *  Our default value matches libpng's default.
        */
        fFilterFlags: FilterFlag = .All;

        /**
        *  Must be in [0, 9] where 9 corresponds to maximal compression.  This value is passed
        *  directly to zlib.  0 is a special case to skip zlib entirely, creating dramatically
        *  larger pngs.
        *
        *  Our default value matches libpng's default.
        */
        fZLibLevel:   s32 = 6;

        /**
        *  Represents comments in the tEXt ancillary chunk of the png.
        *  The 2i-th entry is the keyword for the i-th comment,
        *  and the (2i + 1)-th entry is the text for the i-th comment.
        */
        fComments:    sk_sp(SkDataTable);

        /**
        * Container for any HDR metadata to include in the encoded image.
        */
        fHdrMetadata: skhdr.Metadata;

        /**
        * If non-null, then a gainmap and its metadata will be encoded as png chunks.
        * The gainmap will be encoded in a gmAP chunk as a full PNG container. The
        * gainmap info will be encoded in a gdAT chunk inside of the gmAP chunk.
        * This effectively is Option B proposed in this discussion for adding gainmaps
        * into PNG: https://github.com/w3c/png/issues/380#issuecomment-2325163149.
        *
        * Note that if fGainmapInfo is null, then fGainmap will fail to encode, as the
        * gainmap metadata is required to correctly interpret the encoded gainmap.
        */
        fGainmap:     *SkPixmap = null;
        fGainmapInfo: *SkGainmapInfo = null;
    }

    /**
    *  Encode the |src| pixels to the |dst| stream.
    *  |options| may be used to control the encoding behavior.
    *
    *  Returns true on success.  Returns false on an invalid or unsupported |src|.
    */
    Encode :: (dst: *SkWStream, src: *SkPixmap, options: *Options) -> bool #foreign libskia "?Encode@SkPngEncoder@@YA_NPEAVSkWStream@@AEBVSkPixmap@@AEBUOptions@1@@Z";
    Encode :: (dst: *SkWStream, src: SkPixmap, options: Options) -> bool #no_context {
        return Encode(dst, *src, *options);
    }

    /**
    *  Returns the encoded data for the pixmap, or nullptr on failure.
    */
    Encode :: (src: *SkPixmap, options: *Options) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?Encode@SkPngEncoder@@YA?AV?$sk_sp@VSkData@@@@AEBVSkPixmap@@AEBUOptions@1@@Z";
    Encode :: (src: SkPixmap, options: Options) -> sk_sp(SkData) #no_context {
        return Encode(*src, *options);
    }

    /**
    *  Encode the provided image and return the resulting bytes. If the image was created as
    *  a texture-backed image on a GPU context, that |ctx| must be provided so the pixels
    *  can be read before being encoded. For raster-backed images, |ctx| can be nullptr.
    *  |options| may be used to control the encoding behavior.
    *
    *  Returns nullptr if the pixels could not be read or encoding otherwise fails.
    */
    Encode :: (ctx: *GrDirectContext, img: *SkImage, options: *Options) -> sk_sp(SkData) #cpp_return_type_is_non_pod #foreign libskia "?Encode@SkPngEncoder@@YA?AV?$sk_sp@VSkData@@@@PEAVGrDirectContext@@PEBVSkImage@@AEBUOptions@1@@Z";
    Encode :: (ctx: *GrDirectContext, img: *SkImage, options: Options) -> sk_sp(SkData) #no_context {
        return Encode(ctx, img, *options);
    }

    /**
    *  Create a png encoder that will encode the |src| pixels to the |dst| stream.
    *  |options| may be used to control the encoding behavior.
    *
    *  The primary use of this is incremental encoding of the pixels.
    *
    *  |dst| is unowned but must remain valid for the lifetime of the object.
    *
    *  This returns nullptr on an invalid or unsupported |src|.
    */
    Make :: (dst: *SkWStream, src: *SkPixmap, options: *Options) -> std.unique_ptr(SkEncoder) #cpp_return_type_is_non_pod #foreign libskia "?Make@SkPngEncoder@@YA?AV?$unique_ptr@VSkEncoder@@U?$default_delete@VSkEncoder@@@std@@@std@@PEAVSkWStream@@AEBVSkPixmap@@AEBUOptions@1@@Z";
    Make :: (dst: *SkWStream, src: SkPixmap, options: Options) -> std.unique_ptr(SkEncoder) #no_context {
        return Make(dst, *src, *options);
    }
}

#scope_file

#import "Basic"; // For push_context



//
//  ColorVisionFilter.metal
//  OwlLala
//
//  OVERVIEW
//  --------
//  The GPU half of the in-app color-vision filter. SwiftUI's `.colorEffect`
//  runs this function once per rendered pixel, letting us re-map colors with a
//  3x3 RGB matrix — the same technique iOS uses for its accessibility
//  "Color Filters" (Red/Green, Green/Red, Blue/Yellow).
//
//  WHERE IT IS USED
//  ----------------
//  Invoked from `DisplayFilters.swift` via
//  `ShaderLibrary.colorVisionFilter(.floatArray(matrix))`, where `matrix` is
//  the 9-element row-major matrix for the selected `ColorVisionSimulation`.
//  Xcode compiles this file into the app's default Metal library automatically.
//

#include <metal_stdlib>
using namespace metal;

/// Re-maps one pixel's color through a 3x3 RGB matrix.
///
/// - position: The pixel's position (unused — the filter is position-independent).
/// - color:    The pixel's current color.
/// - m:        Row-major 3x3 matrix as 9 floats: [rr, rg, rb, gr, gg, gb, br, bg, bb].
/// - count:    Number of floats supplied; anything under 9 leaves pixels unchanged.
[[ stitchable ]] half4 colorVisionFilter(float2 position, half4 color, device const float *m, int count) {
    if (count < 9) {
        return color;
    }

    half3 rgb = color.rgb;
    half3 filtered = half3(
        half(m[0]) * rgb.r + half(m[1]) * rgb.g + half(m[2]) * rgb.b,
        half(m[3]) * rgb.r + half(m[4]) * rgb.g + half(m[5]) * rgb.b,
        half(m[6]) * rgb.r + half(m[7]) * rgb.g + half(m[8]) * rgb.b
    );

    return half4(clamp(filtered, half3(0.0), half3(1.0)), color.a);
}

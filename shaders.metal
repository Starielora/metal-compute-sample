#include <metal_stdlib>

using namespace metal;

kernel void compute(texture2d<half, access::read_write> output [[texture(0)]], uint2 id [[thread_position_in_grid]])
{
    constexpr auto thickness = 0.25f;
    const auto v = float2((float(id.x) / 400), (float(id.y) / 400));
    const float len = length(v - float2(1, 1));
    if (len < 1 - thickness || len > 1.f)
        output.write(half4(0.0, 0.0, 0.0, 1.0), id);
    else
        output.write(half4(0.0, len, 0.5, 1.0), id);
}

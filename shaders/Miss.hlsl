#include "Common.hlsl"

// ---[ Miss Shader ]---

[shader("miss")]
void Miss(inout HitInfo payload)
{
    // payload.ShadedColor = float3(0.f, 0.f, 0.f); // night
    payload.ShadedColor = float3(0.8f, 0.8, 1.0f); // day
    payload.HitT = -1.0f;
}
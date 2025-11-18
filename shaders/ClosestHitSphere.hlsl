#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attrib)
{
    float3 normalWS = normalize(attrib.normal.xyz);

    // Pure grey sphere color
    float3 color = float3(0.3f, 0.3f, 0.3f);

    // Write result to the payload
    payload.ShadedColor = color;
    payload.HitT = RayTCurrent();
    payload.normal = attrib.normal;
}
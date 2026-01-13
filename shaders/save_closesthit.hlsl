#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attrib)
{
    float3 normalWS = normalize(attrib.normal.xyz);

    // Use material diffuse color (and optionally ambient)
    float3 baseColor    = diffuse.rgb;      // from MaterialCB
    float3 ambientTerm  = ambient.rgb;      // from MaterialCB

    // For now, just use diffuse as the sphere color
    float3 color = baseColor;

    // To simulate the old version...
    // float3 color = float3(0.3, 0.3, 0.3);

    // Write result to the payload
    payload.ShadedColor = color;
    payload.HitT        = RayTCurrent();
    payload.normal      = attrib.normal;
}
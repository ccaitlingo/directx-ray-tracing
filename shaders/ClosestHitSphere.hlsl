#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attrib)
{
    // Simple diffuse shading
    float3 normal = normalize(attrib.normal);
    float3 lightDir = normalize(float3(1.0f, 1.0f, 1.0f));
    float intensity = max(0.0f, dot(normal, lightDir));
    float3 color = intensity * float3(1.0f, 0.7f, 0.3f); // Orange diffuse

    payload.ShadedColorAndHitT = float4(color, RayTCurrent());
}
#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attrib)
{
    // Get instance ID, material, and normal
    uint instanceID = InstanceID();
    MaterialCB material = materials[instanceID];
    float3 normalWS = normalize(attrib.normal.xyz);

    // Use material diffuse color (and optionally ambient)
    float3 baseColor    = material.diffuse.rgb;      // from MaterialCB
    float3 ambientTerm  = material.ambient.rgb;      // from MaterialCB

    // For now, just use diffuse as the sphere color
    float3 color = baseColor;

    // Write result to the payload
    payload.ShadedColor = color;
    payload.HitT        = RayTCurrent();
    payload.normal      = attrib.normal;
}
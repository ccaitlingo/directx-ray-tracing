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

    // Reflection

    // Write result to the payload
    payload.ShadedColor = color;
    payload.HitT        = RayTCurrent();
    payload.normal      = attrib.normal;
}

// Generate a random float in [0,1) per thread. Later, replace with preferred randomness generator
// float RandomFloat(uint2 pixelCoords, uint bounce, uint seed)
// {
//     // Simple hash-based hash random number generator
//     uint hash = pixelCoords.x + pixelCoords.y * 73856093u + bounce * 19349663u + seed * 83492791u;
//     hash ^= hash << 13;
//     hash ^= hash >> 17;
//     hash ^= hash << 5;
//     return (float)(hash & 0x00FFFFFF) / 16777216.0f;
// }
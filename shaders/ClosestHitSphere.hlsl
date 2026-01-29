#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attrib)
{
    // Get instance ID and material
    uint instanceID = InstanceID();
    MaterialCB material = materials[instanceID];

    // Material
    float3 baseColor    = material.diffuse.rgb;
    float3 ambientTerm  = material.ambient.rgb;
    float shininess     = material.shininess;
    float3 color = baseColor;

    // Calculate hit position from ray origin + direction * t
    float3 hitPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
    float3 sampleDir = float3(0.f, 0.f, 0.f);
    float3 newDir = float3(0.f, 0.f, 0.f);

    // Create orthonormal basis
    float3 T, B;
    float3 N = normalize(attrib.normal.xyz);
    CreateCoordinateSystem(N, T, B);

    // ***** REFLECT or DIFFUSE *****
    if (shininess > 0)
    {
        // Reflect
        float fuzz = saturate(1.0f - shininess / 100.0f);
        float3 incidentDir = WorldRayDirection();
        float3 reflectedDir = reflect(incidentDir, N);

        // Fuzz
        float3 nextDir = normalize(reflectedDir + fuzz * RandomUnitVector(payload.random));

        // Reject rays that go below the surface
        if (dot(nextDir, N) <= 0.0f)
        {
            payload.throughput = float3(0, 0, 0); // absorb
            return;
        }

        payload.nextDir = nextDir;
        payload.throughput *= color;
    }
    else
    {
        // Diffuse
        // Sample hemisphere direction in tangent space
        sampleDir = SampleCosineWeightedHemisphere(payload.random);
        float3 nextDir = normalize(sampleDir.x * T + sampleDir.y * B + sampleDir.z * N);

        // Transform sampleDir to world space coordinate system
        payload.nextDir = nextDir;

        // Update throughput by multiplying by cosine and color
        payload.throughput *= color * dot(nextDir, N);
        payload.throughput = saturate(payload.throughput); // clamp to [0,1]
    }

    
    // Write result to the payload
    payload.ShadedColor = color;
    payload.HitT        = RayTCurrent();
    payload.HitNormal   = N;
    payload.nextPos     = hitPos;
}
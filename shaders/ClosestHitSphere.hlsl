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
    float illum         = material.illum.x;
    float3 color = baseColor;

    // Early termination when a ray hits a light source
    if (illum > 0)
    {
        payload.ShadedColor = color *illum;
        payload.illum = illum;
        payload.throughput = float3(1.0f, 1.0f, 1.0f); // No attenuation
        return;
    }

    // Calculate hit position from ray origin + direction * t
    float3 hitPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

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
        if (dot(nextDir, N) <= 0.f)
        {
            nextDir = reflectedDir; // fall back to perfect reflection
        }

        // Fresnel (Schlick Approximation)
        float cosTheta = saturate(dot(-incidentDir, N));
        float3 F0 = baseColor;
        float3 F = F0 + (1.0f - F0) * pow(1.0f - cosTheta, 5.0f);

        payload.nextDir = nextDir;
        payload.throughput *= F;
    }
    else
    {
        // Diffuse
        // Sample hemisphere direction in tangent space
        float3 sampleDir = SampleCosineWeightedHemisphere(payload.random);
        float3 nextDir = normalize(sampleDir.x * T + sampleDir.y * B + sampleDir.z * N);

        // Transform sampleDir to world space coordinate system
        payload.nextDir = nextDir;

        // Update throughput by multiplying by cosine and color
        payload.throughput *= color * dot(nextDir, N);
        payload.throughput = saturate(payload.throughput); // clamp to [0,1]
    }
    
    // Write result to the payload
    payload.ShadedColor = float3(0.f, 0.f, 0.f);
    payload.illum       = illum;
    payload.HitT        = RayTCurrent();
    payload.HitNormal   = N;
    payload.nextPos     = hitPos;
}
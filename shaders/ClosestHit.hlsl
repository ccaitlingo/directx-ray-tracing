#include "Common.hlsl"

// ---[ Triangle Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, TriangleAttributes attrib)
{
	// Get primitive index, instance ID, and material
	uint triangleIndex = PrimitiveIndex();
    uint instanceID = InstanceID();
    uint matIndex = instanceID == 0 ? 0 : ((instanceID - 1u) % 5u) + 1u; // Except ground, map to 1-5
    MaterialCB material = materials[matIndex];

	// Material
	float3 baseColor    = material.diffuse.rgb;
    float3 ambientTerm  = material.ambient.rgb;
    float shininess     = material.shininess;
	float illum         = material.illum.x;
	float3 color = baseColor;

	// Calculate the triangle barycentric coordinates
	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);

	// Get the base color from the texture
	VertexAttributes vertex = GetVertexAttributes(triangleIndex, barycentrics);
	int2 coord = floor(vertex.uv * material.textureResolution.x);
	// float3 color = albedo.Load(int3(coord, 0)).rgb;

	// Early termination when a ray hits a light source
    if (illum > 0)
    {
        payload.ShadedColor = color * illum;
        payload.throughput = float3(1.0f, 1.0f, 1.0f); // No attenuation
        return;
    }

	// Calculate hit position from ray origin + direction * t
    float3 hitPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

	// Prepare to calculate normal
	VertexAttributes v0 = GetVertexAttributes(triangleIndex, float3(1,0,0));
	VertexAttributes v1 = GetVertexAttributes(triangleIndex, float3(0,1,0));
	VertexAttributes v2 = GetVertexAttributes(triangleIndex, float3(0,0,1));

    // Create orthonormal basis
    float3 T, B;
    float3 N = normalize(barycentrics.x * v0.normal + barycentrics.y * v1.normal + barycentrics.z * v2.normal);
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
        float3 F0 = color;
        float3 F = F0 + (1.0f - F0) * pow(1.0f - cosTheta, 5.0f);

        payload.nextDir = nextDir;
        payload.throughput *= F;
    }
    else
    {
        // Diffuse
        // Sample hemisphere direction in tangent space
        float3 sampleDir = SampleCosineWeightedHemisphere(payload.random);

        // Transform sampleDir to world space coordinate system
        float3 nextDir = normalize(sampleDir.x * T + sampleDir.y * B + sampleDir.z * N);

        payload.nextDir = nextDir;
        payload.throughput *= color; // Attenuation = albedo
    }

	// Write result to the payload
    payload.ShadedColor = float3(0.f, 0.f, 0.f); // No emission
    payload.HitT = RayTCurrent();
}
#include "Common.hlsl"

// ---[ Triangle Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, TriangleAttributes attrib)
{
    // Get primitive index, instance ID, and material
	uint triangleIndex = PrimitiveIndex();
    uint instanceID = InstanceID();
    uint matIndex = instanceID == 0 ? 0 : ((instanceID - 1u) % 6u) + 1u; // Except ground, map to 1-6
    MaterialCB material = materials[matIndex];

	// Material
	float3 baseColor    = material.diffuse.rgb;
    float shininess     = material.shininess;
	float illum         = material.illum.x;
	float3 color        = baseColor;

    // Early termination when a ray hits a light source
    if (illum > 0)
    {
        payload.ShadedColor = color * illum;
        payload.throughput = float3(1.0f, 1.0f, 1.0f); // No attenuation
        return;
    }

	// Calculate the triangle barycentric coordinates
	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);

	// Get the base color from the texture
	VertexAttributes vertex = GetVertexAttributes(triangleIndex, barycentrics);
	int2 coord = floor(vertex.uv * material.textureResolution.x);

	// Calculate hit position from ray origin + direction * t
    float3 hitPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

    // Build orthonormal basis
    // float3 T, B;
    // float3 objectNormal = normalize(vertex.normal);
    // float3x3 objectToWorld = (float3x3)ObjectToWorld3x4();
    // float3 N = normalize(mul(objectToWorld, objectNormal));
    // if (HitKind() == HIT_KIND_TRIANGLE_BACK_FACE) { N = -N; }
    // CreateCoordinateSystem(N, T, B);

    // --------------------------------------------------
    // GEOMETRIC NORMAL TEST
    // --------------------------------------------------

    // Fetch triangle indices
    uint3 triIndices = GetIndices(triangleIndex);

    // Fetch all 3 vertex positions from the mesh
    float3 p0, p1, p2;

    {
        int addr0 = (triIndices[0] * 8) * 4;
        int addr1 = (triIndices[1] * 8) * 4;
        int addr2 = (triIndices[2] * 8) * 4;

        p0 = asfloat(vertices.Load3(addr0));
        p1 = asfloat(vertices.Load3(addr1));
        p2 = asfloat(vertices.Load3(addr2));
    }

    // Compute geometric normal in object space
    float3 edge1 = p1 - p0;
    float3 edge2 = p2 - p0;

    float3 objectNormal = normalize(cross(edge1, edge2));

    // Transform to world space
    float3x3 objectToWorld = (float3x3)ObjectToWorld3x4();

    float3 N = normalize(mul(objectToWorld, objectNormal));

    // Handle backfaces
    if (HitKind() == HIT_KIND_TRIANGLE_BACK_FACE)
    {
        N = -N;
    }

    // Build tangent basis
    float3 T, B;
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
#include "Common.hlsl"

// ---[ Sphere Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHitSphere(inout HitInfo payload, SphereAttributes attr)
{
    float3 N = normalize(attr.normal);
    float3 V = normalize(WorldRayDirection());

    // Compute reflection direction
    float3 R = reflect(-V, N);

    // Offset origin slightly to avoid self-intersection
    float3 origin = WorldRayOrigin() + N * 1e-3f;

    RayDesc bounceRay;
    bounceRay.Origin = origin;
    bounceRay.Direction = R;
    bounceRay.TMin = 0.001f;
    bounceRay.TMax = 1e6f;

    BouncePayload bouncePayload;
    bouncePayload.colorAndT = float4(0.0f, 0.0f, 0.0f, 1e30f);

    TraceRay(
        SceneTLAS,
        RAY_FLAG_NONE,
        0xFF,
        /* RayContributionToHitGroupIndex = */ 0,
        /* MultiplierForGeometryContributionToShaderIndex = */ 1,
        /* MissShaderIndex = */ 0,
        bounceRay,
        bouncePayload
    );

    // Base ambient contribution
    float3 color = ambient.rgb;

    // Only apply bounce light if it hit the background (i.e., bouncePayload.a is very large)
    if (bouncePayload.colorAndT.a > 1e20f)
    {
        // Use miss shader’s result as indirect light
        float3 indirectLight = bouncePayload.colorAndT.rgb;

        // Apply diffuse BRDF-like model
        float NdotL = max(dot(N, normalize(bounceRay.Direction)), 0.0f);
        color += diffuse.rgb * NdotL * indirectLight;
    }

    // Apply dissolve
    color *= dissolve;

    // Store final color and hit distance
    payload.ShadedColorAndHitT = float4(color, RayTCurrent());
}
#include "Common.hlsl"

// ---[ Sphere Intersection Shader ]---

[shader("intersection")]
void IntersectionSphere()
{
    float RayTMax = 10000.0f;
    
    // For now, transformation is identity
    float4x4 worldToObject = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    
    // Get world-space ray origin and direction
    float3 rayOriginWS = WorldRayOrigin();
    float3 rayDirWS = WorldRayDirection();

    // Transform ray to object space
    float4 rayOriginOS4 = mul(worldToObject, float4(rayOriginWS, 1.0f));
    float4 rayDirOS4   = mul(worldToObject, float4(rayDirWS, 0.0f));
    float3 rayOriginOS = rayOriginOS4.xyz / rayOriginOS4.w;
    float3 rayDirOS    = normalize(rayDirOS4.xyz); // Direction may be scaled by matrix; normalize it

    // For now, unit sphere at origin (object space)
    float3 sphereCenterOS = float3(0.0f, 0.0f, 0.0f);
    float radius = 1.0f;

    float3 oc = rayOriginOS - sphereCenterOS;
    float a = dot(rayDirOS, rayDirOS);
    float b = 2.0f * dot(oc, rayDirOS);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0f * a * c;

    if (discriminant > 0.0f)
    {
        float sqrtDisc = sqrt(discriminant);
        float t0 = (-b - sqrtDisc) / (2.0f * a);
        float t1 = (-b + sqrtDisc) / (2.0f * a);

        // Find the valid hit distance (t0 or t1)
        float tHit = (t0 >= RayTMin() && t0 <= RayTMax) ? t0 :
                     (t1 >= RayTMin() && t1 <= RayTMax) ? t1 : -1.0f;

        if (tHit >= 0.0f)
        {
            // Object-space hit point and normal
            float3 hitOS = rayOriginOS + tHit * rayDirOS;
            float3 normalOS = normalize(hitOS);

            // Transform the normal to world space (ignore translation, scale by inverse transpose)
            float3 normalWS = normalize(mul((float3x3)transpose(worldToObject), normalOS));

            SphereAttributes attrib;
            attrib.normal = normalWS;

            // Use a hit kind constant for custom or triangle analogs
            ReportHit(tHit, 0, attrib);
        }
    }
}
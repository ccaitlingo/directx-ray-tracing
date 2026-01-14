#include "Common.hlsl"

// ---[ Sphere Intersection Shader ]---

[shader("intersection")]
void IntersectionSphere()
{
    float RayTMax = 10000.0f;
    uint id = InstanceID();
    float3x4 worldToObject = WorldToObject3x4();

    // Transform ray from world space to object space
    float3 rayOriginOS = mul(worldToObject, float4(WorldRayOrigin(), 1.0f));
    float3 rayDirOS   = mul(worldToObject, float4(WorldRayDirection(), 0.0f));

    // Position in object space
    float3 sphereCenterOS = float3(0.0f, 0.0f, 0.0f);

    // Unit sphere
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
            attrib.normal = float4(normalWS, 0.f);

            // Use a hit kind constant for custom or triangle analogs
            ReportHit(tHit, 0, attrib);
        }
    }
}
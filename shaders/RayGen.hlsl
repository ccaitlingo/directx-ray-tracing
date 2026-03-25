#include "Common.hlsl"

// ---[ Ray Generation Shader ]---

[shader("raygeneration")]
void RayGen()
{
    uint2 LaunchIndex = DispatchRaysIndex().xy;
    uint2 LaunchDimensions = DispatchRaysDimensions().xy;

    float2 d = (((LaunchIndex.xy + 0.5f) / resolution.xy) * 2.f - 1.f);
    float aspectRatio = (resolution.x / resolution.y);

    const int SAMPLES_PER_PIXEL = 64;

    float3 accumulatedColor = float3(0.f, 0.f, 0.f);

    // Multiple samples per pixel
    for (int sample = 0; sample < SAMPLES_PER_PIXEL; ++sample)
    {
        // Setup the ray
        RayDesc ray;
        ray.Origin = viewOriginAndTanHalfFovY.xyz;
        ray.Direction = normalize(
            (d.x * view[0].xyz * viewOriginAndTanHalfFovY.w * aspectRatio) -
            (d.y * view[1].xyz * viewOriginAndTanHalfFovY.w) +
            view[2].xyz
        );
        ray.TMin = 0.001;
        ray.TMax = 1000.f;
        int depth = 0;

        // Initialize the payload
        // HitInfo payload;
        // payload.ShadedColor = float3(0.f, 0.f, 0.f);
        // payload.HitT = 0.f;
        // payload.throughput = float3(1.0f, 1.0f, 1.0f);
        // payload.HitNormal = float3(0.f, 0.f, 0.f);
        // payload.nextPos = float3(0.f, 0.f, 0.f);
        // payload.nextDir = float3(0.f, 0.f, 0.f);
        // payload.random = float2(0.f, 0.f);
        // payload.illum = 0.f;

        // Initialize the payload
        HitInfo payload = {
            float3(0.f, 0.f, 0.f), // ShadedColor
            float3(1.f, 1.f, 1.f), // throughput
            float3(0.f, 0.f, 0.f), // nextDir
            float2(0.f, 0.f), // random
            0.0f // HitT
        };

		// Initialized accumulated color
        float3 radiance = float3(0.f, 0.f, 0.f);

        // Trace the ray(s)
        for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce)
        {
            // Generate random numbers for hemisphere sampling
            // Build distinct keys for each dimension
            uint pixelID = LaunchIndex.x + LaunchIndex.y * LaunchDimensions.x;
            uint baseKey = pixelID
                        ^ (uint(sample) * 0x9E3779B9u)
                        ^ (uint(bounce) * 0x7F4A7C15u);

            float rnd1 = RandomFloat(baseKey ^ 0u);  // hemisphere phi / x
            float rnd2 = RandomFloat(baseKey ^ 0xB5297A4Du); // hemisphere y

            payload.random = float2(rnd1, rnd2);

            TraceRay(
                SceneBVH,
                RAY_FLAG_NONE,
                0xFF,
                0,
                0,
                0,
                ray,
                payload
            );

            // Accumulate color
            radiance += payload.throughput * payload.ShadedColor;
            
            // Check for termination
            if (bounce == MAX_BOUNCES - 1) break;

            // Check for light sources
            if (payload.HitT < 0.f || all(payload.ShadedColor > float3(0.f, 0.f, 0.f))) break;
            
            // Set up ray for next bounce
            ray.Origin = ray.Origin + ray.Direction * payload.HitT;
            ray.Direction = payload.nextDir;

            depth++;
        }

        // Add this sample's contribution
        accumulatedColor += radiance;
    }

    // Average the samples
    accumulatedColor /= SAMPLES_PER_PIXEL;

    RTOutput[LaunchIndex.xy] = float4(accumulatedColor, 1.f);
}

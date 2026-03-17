/* Copyright (c) 2018-2019, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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

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
        ray.TMin = 0.05f;
        ray.TMax = 1000.f;

        // Initialize the payload
        HitInfo payload;
        payload.ShadedColor = float3(0.f, 0.f, 0.f);
        payload.HitT = 0.f;
        payload.throughput = float3(1.0f, 1.0f, 1.0f);
        payload.depth = 0;

		// Initialized accumulated color
        float3 sampleColor = float3(0.f, 0.f, 0.f);

        // Trace the ray(s)
        for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce)
        {
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
            sampleColor += payload.throughput * payload.ShadedColor;

            // Check for termination
            if (bounce == MAX_BOUNCES - 1) // Max bounces
                break;

            if (payload.HitT == -1) // Miss
                break;

			// Calculate hit position from ray origin + direction * t
            float3 hitPos = ray.Origin + ray.Direction * payload.HitT;

            // Get normal at hit point (you need to provide a method or payload info)
			// Assume here payload.origin.xyz holds hit position and direction stores normal for demo
			// Usually normal is returned via a special attribute or intersection shader
			float3 N = normalize(payload.normal.rgb);

			// Create orthonormal basis
            float3 T, B;
            CreateCoordinateSystem(N, T, B);

            // Generate random numbers for hemisphere sampling
        	// Include 'sample' in RNG to decorrelate samples
            float rnd1 = RandomFloat(LaunchIndex, bounce + sample * MAX_BOUNCES, 0);
            float rnd2 = RandomFloat(LaunchIndex, bounce + sample * MAX_BOUNCES, 1);
            float2 xi = float2(rnd1, rnd2);

			// Sample hemisphere direction in tangent space
            float3 sampleDir = SampleCosineWeightedHemisphere(xi);
            
			// Transform sampleDir to world space coordinate system
			float3 newDir = normalize(sampleDir.x * T + sampleDir.y * B + sampleDir.z * N);

			// Update throughput by multiplying by cosine and albedo (assuming albedo == payload.ShadedColor for demo)
            payload.throughput *= payload.ShadedColor * dot(newDir, N);
            payload.throughput = saturate(payload.throughput); // clamp to [0,1]

			// Setup ray for next bounce
            ray.Origin = hitPos + newDir * 0.001f;
            ray.Direction = newDir;

            payload.depth++;
        }

        // Add this sample's contribution
        accumulatedColor += sampleColor;
    }

    // Average the samples
    accumulatedColor /= SAMPLES_PER_PIXEL;

    RTOutput[LaunchIndex.xy] = float4(accumulatedColor, 1.f);
}

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

// ---[ Constants ]---
#define MAX_BOUNCES 2

// ---[ Structures ]---

// struct HitInfo
// {
// 	float4 ShadedColorAndHitT;
// };

struct HitInfo
{
    float3 ShadedColor;
	float HitT;
    float3 throughput;
	uint depth;
	float4 normal;
};

struct TriangleAttributes 
{
	float2 uv;
};

struct SphereAttributes
{
	float4 normal;
};

// ---[ Constant Buffers ]---

cbuffer ViewCB : register(b0)
{
	matrix view;
	float4 viewOriginAndTanHalfFovY;
	float2 resolution;
};

cbuffer MaterialCB : register(b1)
{
	float4 textureResolution;
	float4 ambient;
	float4 diffuse;
	float dissolve;
	float shininess;
	float2 illum;	// should be an int, but we need 8 bytes for padding
};

// ---[ Resources ]---

RWTexture2D<float4> RTOutput				: register(u0);
RaytracingAccelerationStructure SceneBVH	: register(t0);

ByteAddressBuffer indices					: register(t1);
ByteAddressBuffer vertices					: register(t2);
Texture2D<float4> albedo					: register(t3);

// ---[ Helper Functions ]---

struct VertexAttributes
{
	float3 position;
	float2 uv;
};

uint3 GetIndices(uint triangleIndex)
{
	uint baseIndex = (triangleIndex * 3);
	int address = (baseIndex * 4);
	return indices.Load3(address);
}

VertexAttributes GetVertexAttributes(uint triangleIndex, float3 barycentrics)
{
	uint3 indices = GetIndices(triangleIndex);
	VertexAttributes v;
	v.position = float3(0, 0, 0);
	v.uv = float2(0, 0);

	for (uint i = 0; i < 3; i++)
	{
		int address = (indices[i] * 5) * 4;
		v.position += asfloat(vertices.Load3(address)) * barycentrics[i];
		address += (3 * 4);
		v.uv += asfloat(vertices.Load2(address)) * barycentrics[i];
	}

	return v;
}

// Generate a random float in [0,1) per thread. Later, replace with preferred randomness generator
float RandomFloat(uint2 pixelCoords, uint bounce, uint seed)
{
    // Simple hash-based hash random number generator
    uint hash = pixelCoords.x + pixelCoords.y * 73856093u + bounce * 19349663u + seed * 83492791u;
    hash ^= hash << 13;
    hash ^= hash >> 17;
    hash ^= hash << 5;
    return (float)(hash & 0x00FFFFFF) / 16777216.0f;
}

// Create an orthonormal basis (Tangent, Bitangent) from a given normal
void CreateCoordinateSystem(float3 N, out float3 T, out float3 B)
{
    if (abs(N.x) > abs(N.z))
    {
        T = normalize(float3(-N.y, N.x, 0));
    }
    else
    {
        T = normalize(float3(0, -N.z, N.y));
    }
    B = cross(N, T);
}

// Cosine-weighted hemisphere sampling function
float3 SampleCosineWeightedHemisphere(float2 xi)
{
    float phi = 2.0f * 3.14159265359f * xi.x;
    float cosTheta = sqrt(1.0f - xi.y);
    float sinTheta = sqrt(1.0f - cosTheta * cosTheta);
    return float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}
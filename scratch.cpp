// 1. Prepare the transformation matrix
// For each TLAS instance, compute the inverse of the object-to-world matrix (so you can transform rays from world space to object space in your intersection shader):

#include <DirectXMath.h>
using namespace DirectX;

XMMATRIX objectToWorld = ...; // Your instance's transform
XMMATRIX worldToObject = XMMatrixInverse(nullptr, objectToWorld);

// 2. Set up the root signature
// See notes for more info.
#include "d3dx12.h"

CD3DX12_ROOT_PARAMETER1 rootParams[1]; // Create an array to hold one root param
rootParams[0].InitAsConstants(16, 0, 0, D3D12_SHADER_VISIBILITY_ALL); // 16 floats for float4x4
// That line sets up the first root parameter as 16 32-bit constants/floats (4x4 matrix)
// The first 0 means bind to register b0
// The second 0 means register space, which is usually 0

CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC rootSigDesc;
rootSigDesc.Init_1_1(_countof(rootParams), rootParams, 0, nullptr); // User Adam's code instead

// 3. Build the shader binding table
// For each instance, create a hit group record containing: The shader identifier for your hit group, The 16 floats of your world-to-object matrix

ID3D12StateObjectProperties* stateObjectProps = ...;
void* hitGroupShaderId = stateObjectProps->GetShaderIdentifier(L"MyHitGroup");

const UINT shaderIdSize = D3D12_SHADER_IDENTIFIER_SIZE_IN_BYTES; // 32 bytes
const UINT matrixSize = sizeof(float) * 16; // 64 bytes
const UINT recordSize = shaderIdSize + matrixSize;

std::vector<uint8_t> sbtRecord(recordSize);
memcpy(sbtRecord.data(), hitGroupShaderId, shaderIdSize);
memcpy(sbtRecord.data() + shaderIdSize, &worldToObject, matrixSize);

// Copy sbtRecord to your SBT buffer at the correct offset for this instance

// 4. Access the matrix in HLSL
// [shader("intersection")]
// void SphereIntersection(in float4x4 worldToObject)
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

#include "Window.h"
#include "Graphics.h"
#include "Utils.h"

#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#include <random>
#include <vector>

// Random number seed
static std::mt19937_64 gRng{1234u};

/**
 * Your ray tracing application!
 */
class DXRApplication
{
public:

	inline float RandomFloat(float minVal = 0.0f, float maxVal = 1.0f) {
		std::uniform_real_distribution<float> dist(minVal, maxVal);
		return dist(gRng);
	}

	// Generate famous RTOW scene
	void BuildRandomSpheresScene(std::vector<Instance>& world_objs) {
		uint32_t instanceID = 0;

		// Ground
		Utils::CreateInstance(world_objs, 
			DirectX::XMFLOAT3(0.0f, -1001.0f, 0.0f),
			DirectX::XMFLOAT3(1000.0f, 1000.0f, 1000.0f),
			DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
			instanceID++, 0);

		// A bunch of random small spheres
		const float smallRadius = 0.2f;
		for (int a = -11; a < 11; ++a) {
			for (int b = -11; b < 11; ++b) {
				float choose_mat = RandomFloat();
				float centerX = a + 0.9f * RandomFloat();
				float centerZ = b + 0.9f * RandomFloat();

				// Collision detection with three large spheres
				float smallY = -0.8f;
				float dx1 = centerX - 0.0f, dz1 = centerZ - 0.0f;
				float dist1 = std::sqrt(dx1*dx1 + (smallY-0.0f)*(smallY-0.0f));
				if (dist1 < 1.2f) continue;  // 1.0 + 0.2

				float dx2 = centerX + 2.5f, dz2 = centerZ - 0.0f;  
				float dist2 = std::sqrt(dx2*dx2 + (smallY-0.0f)*(smallY-0.0f));
				if (dist2 < 1.2f) continue;

				float dx3 = centerX - 2.5f, dz3 = centerZ - 0.0f;
				float dist3 = std::sqrt(dx3*dx3 + (smallY-0.0f)*(smallY-0.0f));
				if (dist3 < 1.2f) continue;

				// Create small sphere
				Utils::CreateInstance(world_objs,
					DirectX::XMFLOAT3(centerX, -0.8f, centerZ),
					DirectX::XMFLOAT3(smallRadius, smallRadius, smallRadius),
					DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
					instanceID++, 0);
			}
		}

		// Three large spheres
		const float bigRadius = 1.0f;
		Utils::CreateInstance(world_objs,
			DirectX::XMFLOAT3(0.0f, 0.0f, 0.0f), 
			DirectX::XMFLOAT3(bigRadius, bigRadius, bigRadius),
			DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f), instanceID++, 0);
		Utils::CreateInstance(world_objs,
			DirectX::XMFLOAT3(-2.5f, 0.0f, 0.0f), 
			DirectX::XMFLOAT3(bigRadius, bigRadius, bigRadius),
			DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f), instanceID++, 0);
		Utils::CreateInstance(world_objs,
			DirectX::XMFLOAT3(2.5f, 0.0f, 0.0f), 
			DirectX::XMFLOAT3(bigRadius, bigRadius, bigRadius),
			DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f), instanceID++, 0);
	}

	void Init(ConfigInfo &config) 
	{		
		// Create a new window
		HRESULT hr = Window::Create(config.width, config.height, config.instance, window, L"Introduction to DirectX Raytracing (DXR)");
		Utils::Validate(hr, L"Error: failed to create window!");

		d3d.width = config.width;
		d3d.height = config.height;
		d3d.vsync = config.vsync;

		// Load a model
		// Utils::LoadModel(config.model, model, material);

		// Create a sphere
		Utils::CreateSphere(1.0f, sphere, "colors.mtl", materials);

		// Create the scene
		BuildRandomSpheresScene(world_objs);

		// // Create Instance 0 of sphere (ground)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(0.0f, -81.0f, 0.0f), // position
		// 	DirectX::XMFLOAT3(80.0f, 80.0f, 80.0f), // scale
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f), // rotation
		// 	0, // id
		// 	0 // hitGroup
		// );
		// // Create Instance 1 of sphere (center)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(0.0f, 0.0f, 0.0f),
		// 	DirectX::XMFLOAT3(1.0f, 1.0f, 1.0f),
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
		// 	1,
		// 	0
		// );
		// // Create Instance 2 of sphere (right)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(-2.0f, 0.0f, -0.5f),
		// 	DirectX::XMFLOAT3(1.0f, 1.0f, 1.0f),
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
		// 	2,
		// 	0
		// );
		// // Create Instance 3 of sphere (left)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(2.0f, -0.05f, -2.5f),
		// 	DirectX::XMFLOAT3(1.0f, 1.0f, 1.0f),
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
		// 	3,
		// 	0
		// );
		// // Create Instance 4 of sphere (small left)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(1.25f, -0.65f, 0.0f),
		// 	DirectX::XMFLOAT3(0.35f, 0.35f, 0.35f),
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
		// 	4,
		// 	0
		// );
		// // Create Instance 4 of sphere (small right)
		// Utils::CreateInstance(
		// 	world_objs,
		// 	DirectX::XMFLOAT3(-1.2f, -0.75f, 0.0f),
		// 	DirectX::XMFLOAT3(0.25f, 0.25f, 0.25f),
		// 	DirectX::XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f),
		// 	5,
		// 	0
		// );

		// Initialize the shader compiler
		D3DShaders::Init_Shader_Compiler(shaderCompiler);

		// Initialize D3D12
		D3D12::Create_Device(d3d);
		D3D12::Create_Command_Queue(d3d);
		D3D12::Create_Command_Allocator(d3d);
		D3D12::Create_Fence(d3d);		
		D3D12::Create_SwapChain(d3d, window);
		D3D12::Create_CommandList(d3d);
		D3D12::Reset_CommandList(d3d);

		// Create common resources
		D3DResources::Create_Descriptor_Heaps(d3d, resources);
		D3DResources::Create_BackBuffer_RTV(d3d, resources);
		// D3DResources::Create_Vertex_Buffer(d3d, resources, model);
		// D3DResources::Create_Index_Buffer(d3d, resources, model);
		D3DResources::Create_AABB_Buffer(d3d, resources, sphere);
		// D3DResources::Create_Texture(d3d, resources, material);
		D3DResources::Create_View_CB(d3d, resources);
		// D3DResources::Create_Material_CB(d3d, resources, materials);
		D3DResources::Create_Material_Buffer(d3d, resources, materials);
		
		// Create DXR specific resources
		DXR::Create_Bottom_Level_AS_Sphere(d3d, dxr, resources, sphere);
		DXR::Create_Top_Level_AS(d3d, dxr, resources, world_objs);
		DXR::Create_DXR_Output(d3d, resources);
		DXR::Create_Descriptor_Heaps(d3d, dxr, resources, model, materials);	
		DXR::Create_RayGen_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Miss_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Closest_Hit_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Sphere_Hit_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Pipeline_State_Object(d3d, dxr);
		DXR::Create_Shader_Table(d3d, dxr, resources);

		d3d.cmdList->Close();
		ID3D12CommandList* pGraphicsList = { d3d.cmdList };
		d3d.cmdQueue->ExecuteCommandLists(1, &pGraphicsList);

		D3D12::WaitForGPU(d3d);
		D3D12::Reset_CommandList(d3d);
	}
	
	void Update() 
	{
		D3DResources::Update_View_CB(d3d, resources);
	}

	void Render() 
	{		
		DXR::Build_Command_List(d3d, dxr, resources);
		D3D12::Present(d3d);
		D3D12::MoveToNextFrame(d3d);
		D3D12::Reset_CommandList(d3d);
	}

	void Cleanup() 
	{
		D3D12::WaitForGPU(d3d);
		CloseHandle(d3d.fenceEvent);

		DXR::Destroy(dxr);
		D3DResources::Destroy(resources);		
		D3DShaders::Destroy(shaderCompiler);
		D3D12::Destroy(d3d);

		DestroyWindow(window);
	}
	
private:
	HWND window;
	Model model;
	Sphere sphere;
	// Material material;
	std::vector<Material> materials;
	std::vector<Instance> world_objs;

	DXRGlobal dxr = {};
	D3D12Global d3d = {};
	D3D12Resources resources = {};
	D3D12ShaderCompilerInfo shaderCompiler;
};

/**
 * Program entry point.
 */
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) 
{	
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

	HRESULT hr = EXIT_SUCCESS;
	{
		MSG msg = { 0 };

		// Get the application configuration
		ConfigInfo config;
		hr = Utils::ParseCommandLine(lpCmdLine, config);
		if (hr != EXIT_SUCCESS) return hr;

		// Initialize
		DXRApplication app;
		app.Init(config);

		// Main loop
		while (WM_QUIT != msg.message) 
		{
			if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) 
			{
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}

			app.Update();
			app.Render();
		}

		app.Cleanup();
	}

#if defined _CRTDBG_MAP_ALLOC
	_CrtDumpMemoryLeaks();
#endif

	return hr;
}
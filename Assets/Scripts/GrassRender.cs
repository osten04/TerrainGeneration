using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine;

public class passData
{
	public BufferHandle output;
	public int tile_index;
}

public class GrassRendererFeature : ScriptableRendererFeature
{
	// We will treat the compute pass as a normal Scriptable Render Pass.
	public class grassPass : ScriptableRenderPass
	{
		public grassPass()
		{
			renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
		}

		public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer contextData)
		{
			// Use AddComputePass instead of AddRasterRenderPass.

			for (int i = 0; i < Grass.m_grass.tiles.Length; i++)
			{
				using (var builder = renderGraph.AddComputePass("GrassComputePass", out passData data))
				{
					data.tile_index = i;

					// Use ComputeGraphContext instead of RasterGraphContext.
					builder.SetRenderFunc((passData data, ComputeGraphContext context) => Grass.m_grass.DrawGrassCompute(data, context));

				}

				using (var builder = renderGraph.AddRasterRenderPass("GrassRenderPass", out passData data))
				{
					data.tile_index = i;

					// Use ComputeGraphContext instead of RasterGraphContext.
					builder.SetRenderFunc((passData data, RasterGraphContext context) => Grass.m_grass.DrawGrassShader(data, context));

				}
			}
		}

	}

	[SerializeField]
	int test;

	grassPass m_ComputePass;

	/// <inheritdoc/>
	public override void Create()
	{
		// Initialize the compute pass.
		m_ComputePass = new grassPass();
	}

	// Here you can inject one or multiple render passes in the renderer.
	// This method is called when setting up the renderer once per-camera.
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		// Check if the system support compute shaders, if not make an early exit.
		if (!SystemInfo.supportsComputeShaders)
		{
			Debug.LogWarning("Device does not support compute shaders. The pass will be skipped.");
			return;
		}
		
		// Enqueue the compute pass.
		renderer.EnqueuePass(m_ComputePass);
	}
}
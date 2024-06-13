using System;
using System.Drawing;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using static UnityEngine.GraphicsBuffer;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

public class Grass : MonoBehaviour
{

	public static Grass m_grass = null;
	public struct sTile
	{
		public float3 position;
		public float  size;
	};

	private struct sGrass
	{
		public float3 position;
		public float2 facing;
		public float  height;
		public float  width;
		public uint   hash;
		public float  tilt;
	};


	private ComputeBuffer tile_buffer;
	private ComputeBuffer instance_buffer;

	private GraphicsBuffer index_buffer;
	private GraphicsBuffer draw_args;

	[SerializeField]
	private Material material;

	[SerializeField]
	private ComputeShader compute_shader;

	public sTile[] tiles { get; private set; }

	// Start is called before the first frame update
	void Start()
	{
		m_grass = this;

		tile_buffer = new(1, Marshal.SizeOf<sTile>(), ComputeBufferType.Structured);
		instance_buffer = new(32 * 32, Marshal.SizeOf<sGrass>(), ComputeBufferType.Structured);
		index_buffer = new(GraphicsBuffer.Target.Index, GraphicsBuffer.UsageFlags.LockBufferForWrite, 39, sizeof(uint));
		draw_args = new(GraphicsBuffer.Target.IndirectArguments, GraphicsBuffer.UsageFlags.None, 1, Marshal.SizeOf<IndirectDrawIndexedArgs>());


		tiles = new sTile[8 * 8];

		for (int i = 0; i < 8; i++)
		{
			for (int j = 0; j < 8; j++)
			{
				tiles[i + j * 8] = new sTile()
				{
					position = new(TerrainManager.m_tiling * (float)(i - 4), 0.0f, TerrainManager.m_tiling * (float)(j - 4)),
					size = TerrainManager.m_tiling
				};
			}
		}


		uint[] indecies = new uint[39]
		{
			0, 3, 1,
			0, 2, 3,
			2, 5, 3,
			2, 4, 5,
			4, 7, 5,
			4, 6, 7,
			6, 9, 7,
			6, 8, 9,
			8, 11, 9,
			8, 10, 11,
			10, 13, 11,
			10, 12, 13,
			12, 14, 13,
		};

		index_buffer.SetData(indecies);

		IndirectDrawIndexedArgs args = new IndirectDrawIndexedArgs()
		{
			baseVertexIndex = 0,
			instanceCount = 32 * 32,
			indexCountPerInstance = 39,
			startIndex = 0,
			startInstance = 0
		};

		draw_args.SetData(new IndirectDrawIndexedArgs[1] { args });

		int id = compute_shader.FindKernel("CSMain");
		compute_shader.SetBuffer(id, Shader.PropertyToID("input"), tile_buffer);
	}

	private GrassRendererFeature.grassPass m_grass_pass;

	private void OnBeginCamera(ScriptableRenderContext context, Camera cam)
	{
		// Use the EnqueuePass method to inject a custom render pass
		cam.GetUniversalAdditionalCameraData().scriptableRenderer.EnqueuePass(m_grass_pass);
	}

	private void OnEnable()
	{
		// Remove WriteLogMessage as a delegate of the  RenderPipelineManager.beginCameraRendering event
		RenderPipelineManager.beginCameraRendering += OnBeginCamera;
	}

	private void OnDisable()
	{
		// Remove WriteLogMessage as a delegate of the  RenderPipelineManager.beginCameraRendering event
		RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
	}

	private void OnDestroy()
	{
		tile_buffer.Dispose();
		instance_buffer.Dispose();
		index_buffer.Dispose();
		draw_args.Dispose();
	}

	public void DrawGrassCompute( passData data, ComputeGraphContext context )
	{
		int id  = compute_shader.FindKernel( "CSMain" );
		compute_shader.SetBuffer( id, Shader.PropertyToID( "Result" ), instance_buffer );

		RenderParams render_args = new RenderParams( material );
		
		compute_shader.SetVector( Shader.PropertyToID( "u_offset" ), TerrainManager.worldoffset );
		compute_shader.SetFloat( Shader.PropertyToID( "u_height" ), TerrainManager.terrain_height );

		tile_buffer.SetData( tiles, data.tile_index, 0, 1 );

		context.cmd.DispatchCompute( compute_shader, id, 32, 32, 1 );
	}

	public void DrawGrassShader( passData data, RasterGraphContext context )
	{
		//RenderParams render_args = new RenderParams(material);

		material.SetBuffer(Shader.PropertyToID("instance_buffer"), instance_buffer);

		//float size = tiles[data.tile_index].size * 1.2f;
		//float3 pos = tiles[data.tile_index].position;
		//
		//render_args.worldBounds = new(new Vector3(size, 1024, size) * 0.5f, new Vector3(size, 1024, size) + new Vector3(pos.x, pos.y, pos.z));

		context.cmd.DrawProceduralIndirect(index_buffer, Matrix4x4.identity, material, -1, MeshTopology.Triangles, draw_args );
	}
}


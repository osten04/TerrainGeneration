using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using Unity.Mathematics;
using UnityEngine;
using System.Runtime.InteropServices;
using static UnityEngine.GraphicsBuffer;

public class Grass : MonoBehaviour
{
	private struct sTile
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
	};


	private ComputeBuffer tile_buffer;
	private ComputeBuffer instance_buffer;

	private GraphicsBuffer index_buffer;
	private GraphicsBuffer draw_args;

	[SerializeField]
	private Material material;

	[SerializeField]
	private ComputeShader compute_shader;

	private sTile[] tiles;

	// Start is called before the first frame update
	void Start()
    {
		MeshRenderer renderer = GetComponent<MeshRenderer>();

		tile_buffer     = new( 1, Marshal.SizeOf< sTile >(), ComputeBufferType.Structured );
		instance_buffer = new(32 * 32, Marshal.SizeOf< sGrass >(), ComputeBufferType.Structured );
		index_buffer    = new( GraphicsBuffer.Target.Index, GraphicsBuffer.UsageFlags.LockBufferForWrite, 39, sizeof( uint ) );
		draw_args       = new( GraphicsBuffer.Target.IndirectArguments, GraphicsBuffer.UsageFlags.None, 1, Marshal.SizeOf<IndirectDrawIndexedArgs>());

		sTile t = new()
		{
			position = new float3(0, 0, 0),
			size     = 1.0f
		};

		tile_buffer.SetData( new sTile[ 1 ] { t } );

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

		index_buffer.SetData( indecies );

		IndirectDrawIndexedArgs args = new IndirectDrawIndexedArgs()
		{
			baseVertexIndex = 0,
			instanceCount = 16 * 16,
			indexCountPerInstance = 39,
			startIndex = 0,
			startInstance = 0
		};

		draw_args.SetData( new IndirectDrawIndexedArgs[ 1 ]{ args } );
	}

	private void OnDestroy()
	{
		tile_buffer.Dispose();
		instance_buffer.Dispose();
		index_buffer.Dispose();
		draw_args.Dispose();
	}

	// Update is called once per frame
	void Update()
    {
		OnPreRender();
	}

	private void OnPreRender()
	{
		int id  = compute_shader.FindKernel( "CSMain" );
		compute_shader.SetVector( Shader.PropertyToID( "u_offset" ), new Vector4( 0.0f, 0.0f, 0.0f, 0.0f ) );
		compute_shader.SetBuffer( id, Shader.PropertyToID( "input" ), tile_buffer );
		compute_shader.SetBuffer( id, Shader.PropertyToID( "Result" ), instance_buffer );
		compute_shader.Dispatch( id, 32, 32, 1 );

		material.SetBuffer( Shader.PropertyToID( "instance_buffer" ), instance_buffer );

		float size = 1.0f;

		RenderParams render_args = new RenderParams(material)
		{
			worldBounds = new( new Vector3( size, size, size ) * 0.5f , new Vector3( size, size, size ) )
		};

		Graphics.RenderPrimitivesIndexedIndirect( render_args, MeshTopology.Triangles, index_buffer, draw_args, 1, 0 );
	}
}

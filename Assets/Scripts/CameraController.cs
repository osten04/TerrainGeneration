using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Unity.Mathematics;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    // Start is called before the first frame update
    public  Vector3 m_position { get; private set; }
    private Vector3 m_rotation;

    void Start()
    {
        m_position = new Vector3();
		m_rotation = new Vector3();
	}

	// Update is called once per frame
	void Update()
	{
		if (!Application.isFocused)
			return;

		float horizontalInput = Input.GetAxis("Mouse X");
		float verticalInput = Input.GetAxis("Mouse Y");

		m_rotation += new Vector3(-verticalInput, horizontalInput, 0.0f);
		transform.rotation = Quaternion.Euler(m_rotation);

		Vector3 move = 20.0f * Time.deltaTime * new Vector3( Input.GetAxis( "Horizontal" ), 0, Input.GetAxis("Vertical") ).normalized;
		
		m_position  += Quaternion.AngleAxis( m_rotation.y, Vector3.up ) * move;
		transform.position = new Vector3( transform.position.x, GetHeight( math.float2( m_position.x * 0.02f, m_position.z * 0.02f ) ) * 64.0f + 2.0f, transform.position.z );
	}

	private float wglnoise_mod(float x, float y)
	{
		return x - y * math.floor(x / y);
	}

	private float2 wglnoise_mod(float2 x, float2 y)
	{
		return x - y * math.floor(x / y);
	}

	private float3 wglnoise_mod(float3 x, float3 y)
	{
		return x - y * math.floor(x / y);
	}

	private float4 wglnoise_mod(float4 x, float4 y)
	{
		return x - y * math.floor(x / y);
	}

	private float2 wglnoise_fade(float2 t)
	{
		return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
	}

	private float3 wglnoise_fade(float3 t)
	{
		return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
	}

	private float wglnoise_mod289(float x)
	{
		return x - math.floor(x / 289.0f) * 289.0f;
	}

	private float2 wglnoise_mod289(float2 x)
	{
		return x - math.floor(x / 289.0f) * 289.0f;
	}

	private float3 wglnoise_mod289(float3 x)
	{
		return x - math.floor(x / 289.0f) * 289.0f;
	}

	private float4 wglnoise_mod289(float4 x)
	{
		return x - math.floor(x / 289.0f) * 289.0f;
	}

	private float3 wglnoise_permute(float3 x)
	{
		return wglnoise_mod289((x * 34.0f + 1.0f) * x);
	}

	private float4 wglnoise_permute(float4 x)
	{
		return wglnoise_mod289((x * 34.0f + 1.0f) * x);
	}

	private float ClassicNoise_impl(float2 pi0, float2 pf0, float2 pi1, float2 pf1)
	{
		pi0 = wglnoise_mod289(pi0); // To avoid truncation effects in permutation
		pi1 = wglnoise_mod289(pi1);

		float4 ix = math.float2(pi0.x, pi1.x).xyxy;
		float4 iy = math.float2(pi0.y, pi1.y).xxyy;
		float4 fx = math.float2(pf0.x, pf1.x).xyxy;
		float4 fy = math.float2(pf0.y, pf1.y).xxyy;

		float4 i = wglnoise_permute(wglnoise_permute(ix) + iy);

		float4 phi = i / 41.0f * 3.14159265359f * 2.0f;
		float2 g00 = math.float2(math.cos(phi.x), math.sin(phi.x));
		float2 g10 = math.float2(math.cos(phi.y), math.sin(phi.y));
		float2 g01 = math.float2(math.cos(phi.z), math.sin(phi.z));
		float2 g11 = math.float2(math.cos(phi.w), math.sin(phi.w));

		float n00 = math.dot(g00, math.float2(fx.x, fy.x));
		float n10 = math.dot(g10, math.float2(fx.y, fy.y));
		float n01 = math.dot(g01, math.float2(fx.z, fy.z));
		float n11 = math.dot(g11, math.float2(fx.w, fy.w));

		float2 fade_xy = wglnoise_fade(pf0);
		float2 n_x = math.lerp(math.float2(n00, n01), math.float2(n10, n11), fade_xy.x);
		float n_xy = math.lerp(n_x.x, n_x.y, fade_xy.y);
		return 1.44f * n_xy;
	}

	// Classic Perlin noise
	private float ClassicNoise(float2 p)
	{
		float2 i = math.floor(p);
		float2 f = math.frac(p);
		return ClassicNoise_impl(i, f, i + 1.0f, f - 1.0f);
	}

	// Classic Perlin noise, periodic variant
	private float PeriodicNoise(float2 p, float2 rep)
	{
		float2 i0 = wglnoise_mod(math.floor(p), rep);
		float2 i1 = wglnoise_mod(i0 + 1.0f, rep);
		float2 f = math.frac(p);
		return ClassicNoise_impl(i0, f, i1, f - 1.0f);
	}

	private float GetHeight(float2 _world_pos)
	{
		return + ClassicNoise( _world_pos * math.float2( 0.02f, 0.02f ) ) * 8.0f + 8.0f + ClassicNoise( _world_pos ) * 0.5f + 0.5f;
	}
}

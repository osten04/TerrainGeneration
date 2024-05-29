float wglnoise_mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 wglnoise_mod(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

float3 wglnoise_mod(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

float4 wglnoise_mod(float4 x, float4 y)
{
    return x - y * floor(x / y);
}

float2 wglnoise_fade(float2 t)
{
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

float3 wglnoise_fade(float3 t)
{
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

float wglnoise_mod289(float x)
{
    return x - floor(x / 289.0f) * 289.0f;
}

float2 wglnoise_mod289(float2 x)
{
    return x - floor(x / 289.0f) * 289.0f;
}

float3 wglnoise_mod289(float3 x)
{
    return x - floor(x / 289.0f) * 289.0f;
}

float4 wglnoise_mod289(float4 x)
{
    return x - floor(x / 289.0f) * 289.0f;
}

float3 wglnoise_permute(float3 x)
{
    return wglnoise_mod289((x * 34.0f + 1.0f) * x);
}

float4 wglnoise_permute(float4 x)
{
    return wglnoise_mod289((x * 34.0f + 1.0f) * x);
}

float ClassicNoise_impl(float2 pi0, float2 pf0, float2 pi1, float2 pf1)
{
    pi0 = wglnoise_mod289(pi0); // To avoid truncation effects in permutation
    pi1 = wglnoise_mod289(pi1);

    float4 ix = float2(pi0.x, pi1.x).xyxy;
    float4 iy = float2(pi0.y, pi1.y).xxyy;
    float4 fx = float2(pf0.x, pf1.x).xyxy;
    float4 fy = float2(pf0.y, pf1.y).xxyy;

    float4 i = wglnoise_permute(wglnoise_permute(ix) + iy);

    float4 phi = i / 41.0f * 3.14159265359f * 2.0f;
    float2 g00 = float2(cos(phi.x), sin(phi.x));
    float2 g10 = float2(cos(phi.y), sin(phi.y));
    float2 g01 = float2(cos(phi.z), sin(phi.z));
    float2 g11 = float2(cos(phi.w), sin(phi.w));

    float n00 = dot(g00, float2(fx.x, fy.x));
    float n10 = dot(g10, float2(fx.y, fy.y));
    float n01 = dot(g01, float2(fx.z, fy.z));
    float n11 = dot(g11, float2(fx.w, fy.w));

    float2 fade_xy = wglnoise_fade(pf0);
    float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
    float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
    return 1.44f * n_xy;
}

// Classic Perlin noise
float ClassicNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    return ClassicNoise_impl(i, f, i + 1.0f, f - 1.0f);
}

// Classic Perlin noise, periodic variant
float PeriodicNoise(float2 p, float2 rep)
{
    float2 i0 = wglnoise_mod(floor(p), rep);
    float2 i1 = wglnoise_mod(i0 + 1.0f, rep);
    float2 f = frac(p);
    return ClassicNoise_impl(i0, f, i1, f - 1.0f);
}

float GetHeight( float2 _world_pos )
{
    return + ClassicNoise( _world_pos * 0.02 ) * 8.0f + 8.0f + ClassicNoise( _world_pos ) * 0.5f + 0.5f;
}
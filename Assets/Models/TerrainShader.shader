Shader "Custom/TerrainShader"
{
    Properties
    {
        u_main_tex   ( "Texture",    2D    ) = "white" {}
        u_height_map ( "Height Map", 2D    ) = "white" {}
        u_height     ( "Height",     float ) = 1
        u_dropoff    ( "dropoff",    float ) = 0
        u_delta      ( "delta",      Range(0.001, 0.0001) ) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.6

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex    : SV_POSITION;
                float2 uv        : TEXCOORD0;
                float3 tangent   : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal    : TEXCOORD3;
                float  height    : TEXCOORD4;
                float4 worldPos  : TEXCOORD5;
            };

            sampler2D u_height_map;
            float     u_height;
            float     u_dropoff;
            float     u_delta;

#include "HeightMap.cginc"

            v2f vert (appdata v)
            {
                v2f o;

                o.height = 0.0f;
                o.worldPos = mul( unity_ObjectToWorld, v.vertex );

                float2 cord = v.uv - float2( 0.5f, 0.5f );
                if( max( abs( cord.x ), abs( cord.y ) ) * 2.0f + 0.01f > u_dropoff )
                {
                    float  dropoff      = max( abs( v.uv.x - 0.5f ), abs( v.uv.y - 0.5f ) ) * 2.0f;
                    float  delta_height = dropoff - u_dropoff;
                    
                    o.height            = GetHeight( o.worldPos.xz );
                    
                    float dx    = GetHeight( mul( unity_ObjectToWorld, v.vertex ).xz + float2( u_delta, 0.0f ) ) * u_height + v.vertex.y;
                    float dy    = GetHeight( mul( unity_ObjectToWorld, v.vertex ).xz + float2( 0.0f, u_delta ) ) * u_height + v.vertex.y;
                    
                    float3 vert = v.vertex.xyz;
                    vert.y = o.height;

                    float3 tangent   = normalize( float3( v.vertex.x + u_delta, dx, v.vertex.z ) - vert );
                    float3 bitangent = normalize( float3( v.vertex.x, dy, v.vertex.z + u_delta ) - vert );
                    float3 normal    = normalize( cross( tangent, bitangent ) );

                    v.vertex.y += min( o.height, o.height + ( delta_height ) ) * u_height;
                    

                    o.tangent   = tangent;
                    o.bitangent = bitangent;
                    o.normal    = normal;

                    o.uv = v.uv;
                }
                else
                {
                    o.uv        = 0.0f;
                    o.tangent   = 0.0f;
                    o.bitangent = 0.0f;
                    o.normal    = 0.0f;
                    o.height    = 0.0f;
                }

                o.vertex = UnityObjectToClipPos( v.vertex );
                
                return o;

            }

            sampler2D u_main_tex;

            float4 frag (v2f i) : SV_Target
            {
                if( i.height == 0.0f )
                    discard;

                return float4( i.normal, 1.0);
            }
            ENDCG
        }
    }
}

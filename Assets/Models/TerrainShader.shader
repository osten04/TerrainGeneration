Shader "Custom/TerrainShader"
{
    Properties
    {
        u_main_tex   ( "Texture",    2D    ) = "white" {}
        u_height_map ( "Height Map", 2D    ) = "white" {}
        u_height     ( "Height",     float ) = 1
        u_scale      ( "Scale",      float ) = 1
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float  height : TEXCOORD1;
            };

            sampler2D u_height_map;
            float     u_height;
            float     u_scale;


            v2f vert (appdata v)
            {
                v2f o;

                float2 uv = ( v.uv - float2( 0.5f, 0.5f ) ) * u_scale * 0.5f + float2( 0.5f, 0.5f );
                o.height    = tex2Dlod( u_height_map, float4( uv, 0, 0 ) ).x;
                v.vertex.y += o.height * u_height;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.uv = v.uv;
                return o;
            }

            sampler2D u_main_tex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D( u_main_tex, i.uv );
                col.rgb = col.rgb * i.height;
                return col;
            }
            ENDCG
        }
    }
}

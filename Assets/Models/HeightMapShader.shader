Shader "Unlit/HeightMapShader"
{
    Properties
    {
        u_pos   ( "Position", Vector ) = ( 0, 0, 0, 0 )
        u_Seed  ( "Seed",     Float  ) = 420691337
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "HeightMap.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 position : TEXCOORD0;
            };

            float4 u_pos;
            float  u_Seed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex   = UnityObjectToClipPos( v.vertex );
                o.position = v.vertex.xz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = GetHeight( i.position );
                return col;
            }
            ENDCG
        }
    }
}

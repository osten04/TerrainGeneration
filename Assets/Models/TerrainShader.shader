Shader "Custom/TerrainShader"
{
    Properties
    {
        u_main_tex   ( "Texture",    2D    ) = "white" {}
        u_height     ( "Height",     float ) = 1
        u_dropoff    ( "dropoff",    float ) = 0
        u_sharpness  ( "Sharpness",  float ) = 0
        u_delta      ( "delta",      Range( 1, 0.0001 ) ) = 0.01
        u_rim_color ("Rim Color", Color) = (0.26,0.19,0.16,0.0)
        u_rim_power ("Rim Power", Range(0.5,8.0)) = 3.0
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D u_main_tex;
        float4 u_main_tex_ST;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        //UNITY_INSTANCING_BUFFER_START(Props)
        //    // put more per-instance properties here
        //UNITY_INSTANCING_BUFFER_END(Props)

        float u_height;
        float u_dropoff;
        float u_delta;

        #include "HeightMap.cginc"
        #include "UnityCG.cginc"

        void vert (inout appdata_full v) 
        {
            const float scale = 0.02f;

            float4x4 scale_matrix = float4x4
            (
                float4( scale, 0.0f,  0.0f,  0.0f ),
                float4( 0.0f,  scale, 0.0f,  0.0f ),
                float4( 0.0f,  0.0f,  scale, 0.0f ),
                float4( 0.0f,  0.0f,  0.0f,  1.0f )
            );

            const float4x4 worldMatrix = mul( scale_matrix, unity_ObjectToWorld );

            float3 vertex = mul( worldMatrix, v.vertex );

            float2 cord = v.texcoord  - float2( 0.5f, 0.5f );
            if( max( abs( cord.x ), abs( cord.y ) ) * 2.0f + 0.01f > u_dropoff )
            {
                float  dropoff      = max( abs( v.texcoord .x - 0.5f ), abs( v.texcoord.y - 0.5f ) ) * 20.0f;
                float  delta_height = dropoff - u_dropoff;
                    
                float height = GetHeight( vertex.xz );
                    
                float dx = GetHeight( ( vertex ).xz + float2( u_delta, 0.0f ) );
                float dy = GetHeight( ( vertex ).xz + float2( 0.0f, u_delta ) );
                    
                vertex.y = height;

                float3 tangent   = normalize( float3( v.vertex.x + u_delta, dx, v.vertex.z ) - vertex );
                float3 bitangent = normalize( float3( v.vertex.x, dy, v.vertex.z + u_delta ) - vertex );
                float3 normal    = normalize( cross( tangent, bitangent ) );

                v.vertex.y += min( height, height + delta_height ) * u_height;
                    

                v.tangent  = float4( tangent, 1.0f );
                v.normal   = float4( normal, 1.0f );
            }
            else
            {
                v.vertex.y = 0.0f;
            }
        }

        struct Input
        {
            float3 worldPos;
            float3 viewDir;
            float3 Normal;
            float2 uv_MainTex;
        };

        float  u_sharpness;
        float4 u_rim_color;
        float  u_rim_power;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            
            const float scale = 0.02f;
            
            float3 pos = IN.worldPos * float3( scale, scale, scale );
            
            //calculate UV coordinates for three projections
            float2 uv_front = TRANSFORM_TEX(pos.xy, u_main_tex);
            float2 uv_side  = TRANSFORM_TEX(pos.yz, u_main_tex);
            float2 uv_top   = TRANSFORM_TEX(pos.zx, u_main_tex);
            
            //read texture at uv position of the three projections
            fixed4 col_front = tex2D(u_main_tex, uv_front);
            fixed4 col_side  = tex2D(u_main_tex, uv_side);
            fixed4 col_top   = tex2D(u_main_tex, uv_top);
            
            float3 weights = normalize( pow( abs( IN.Normal ), u_sharpness ) );
            
            //combine weights with projected colors
            col_front *= weights.z;
            col_side  *= weights.x;
            col_top   *= weights.y;
            
            //combine the projected colors
            fixed4 c = col_front + col_side + col_top;
               
            o.Albedo     = c.rgb;
            o.Normal     = IN.Normal;
            o.Emission   = 0.0f;
            o.Metallic   = _Metallic;
            o.Smoothness = _Glossiness;
            o.Occlusion  = 0.5f;
            o.Alpha      = c.a;
        }
        ENDCG
    }
}

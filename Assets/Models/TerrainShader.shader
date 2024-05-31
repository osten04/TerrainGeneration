Shader "Custom/TerrainShader"
{
    Properties
    {
        u_height     ( "Height",     float ) = 1
        u_dropoff    ( "dropoff",    float ) = 0
        u_delta      ( "delta",      Range( 2, 0.0001 ) ) = 0.01
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Occlusion ("Occlusion", Range(0,1)) = 0.5
        _Smoothness ("Smoothness", Range(0,1)) = 0.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Sharpness ("Blend sharpness", Range(1, 64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float4    _MainTex_ST;

        struct Input
        {
            float3 worldPos;
            float3 normal;
            float2 texcoord1;
            float2 texcoord2;
        };

        uniform float4 u_offset;

        half   _Occlusion;
        half   _Smoothness;
        fixed4 _Color;
        fixed3 _Specular;
        float _Sharpness;

        float u_height;
        float u_dropoff;
        float u_delta;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        #include "HeightMap.cginc"
        #include "UnityCG.cginc"

        void vert (inout appdata_tan v, out Input o ) 
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);

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

            float3 offset = u_offset.xyz;

            float2 cord    = ( v.texcoord - float2( 0.5f, 0.5f ) ) * 2.0f;
            float  dropoff = max( abs( cord.x ), abs( cord.y ) );

            if( max( abs( cord.x ), abs( cord.y ) ) + 0.01f > u_dropoff )
            {
                float  delta_height = dropoff - u_dropoff;
                    
                vertex.y = GetHeight( vertex.xz + offset.xz ) * u_height;
                
                float3 dx = vertex; 
                float3 dz = vertex;

                dx.x += u_delta;
                dz.z += u_delta;

                dx.y = GetHeight( dx.xz + offset.xz ) * u_height;
                dz.y = GetHeight( dz.xz + offset.xz ) * u_height;

                float3 tangent   = normalize( dx - vertex );
                float3 bitangent = normalize( dz - vertex );
                float3 normal    = normalize( cross( bitangent, tangent ) );
                
                o.worldPos = v.vertex + offset;

                v.vertex.y = min( vertex.y, vertex.y + delta_height );
                
                v.tangent  = float4( tangent, 1.0f );
                v.normal   = normal;

                o.normal   = normal;
            }
            else
            {
                o.worldPos = v.vertex + offset;
                v.vertex.y = -0.01f;
            }
        }

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            clip( IN.worldPos.y );

            float3 uv = IN.worldPos;

            float2 uv_front = TRANSFORM_TEX( uv.xy, _MainTex );
			float2 uv_side  = TRANSFORM_TEX( uv.yz, _MainTex );
			float2 uv_top   = TRANSFORM_TEX( uv.xz, _MainTex );
				
			fixed4 col_front = tex2D( _MainTex, uv_front );
			fixed4 col_side  = tex2D( _MainTex, uv_side );
			fixed4 col_top   = tex2D( _MainTex, uv_top );

			float3 weights = pow( abs( IN.normal ), _Sharpness );
			weights = weights / ( weights.x + weights.y + weights.z );

            fixed4 col   = col_top * _Color;
			col_front *= weights.z;
			col_side  *= weights.x;
			col_top   *= weights.y;

            //fixed4 col   = ( col_front + col_side + col_top ) * _Color;
            o.Albedo = col.rgb;
            o.Specular = _Specular;
            o.Smoothness = _Smoothness;
            o.Occlusion = _Occlusion;
            o.Alpha = col.a;
        }
        ENDCG
    }
}

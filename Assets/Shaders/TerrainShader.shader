Shader "Custom/TerrainShader"
{
    Properties
    {
        u_dropoff    ( "dropoff",         float )              = 0
        u_delta      ( "delta",           Range( 2, 0.0001 ) ) = 0.01
        _Color       ( "Color",           Color )              = ( 1,1,1,1 )
        _MainTex     ( "Albedo (RGB)",    2D )                 = "white" { }
        _Occlusion   ( "Occlusion",       Range( 0,1 ) )       = 0.5
        _Smoothness  ( "Smoothness",      Range( 0,1 ) )       = 0.0
        _Specular    ( "Specular",        Color )              = ( 1, 1, 1,1 )
        _Sharpness   ( "Blend sharpness", Range( 1, 64 ) )     = 1
    }
    SubShader
    {
        Pass
        {
            Name "MainPass"
            Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            sampler2D _MainTex;
            float4    _MainTex_ST;

            struct Input
            {
                float4 vertex   : SV_Position;
                float3 normal   : texcord0;
                float3 offset   : texcord1;
                float3 worldPos : texcord2;
            };

            float4 u_offset;

            float   _Occlusion;
            float   _Smoothness;
            float4 _Color;
            float3 _Specular;
            float _Sharpness;

            float u_height;
            float u_dropoff;
            float u_delta;


            #include "HeightMap.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            Input vert ( in appdata v  )
            {
                Input o;

                const float scale = 0.02f;

                float4x4 scale_matrix = float4x4
                (
                    float4( scale, 0.0f,  0.0f,  0.0f ),
                    float4( 0.0f,  scale, 0.0f,  0.0f ),
                    float4( 0.0f,  0.0f,  scale, 0.0f ),
                    float4( 0.0f,  0.0f,  0.0f,  1.0f )
                );

                const float4x4 worldMatrix = mul( scale_matrix, unity_ObjectToWorld );

                float3 offset = u_offset.xyz * scale;
                o.offset      = u_offset.xyz;
                o.worldPos    = mul( unity_ObjectToWorld, v.vertex );

                float3 vertex = mul( worldMatrix, v.vertex.xyz ) + offset;

                float2 cord    = ( v.uv - float2( 0.5f, 0.5f ) ) * 2.0f;
                float  dropoff = max( abs( cord.x ), abs( cord.y ) );

                if( max( abs( cord.x ), abs( cord.y ) ) + 0.01f > u_dropoff )
                {
                    float  delta_height = dropoff - u_dropoff;
                    
                    vertex.y = GetHeight( vertex.xz ) * u_height;
                
                    float3 dx = vertex;
                    float3 dz = vertex;

                    dx.x += u_delta;
                    dz.z += u_delta;

                    dx.y = GetHeight( dx.xz ) * u_height;
                    dz.y = GetHeight( dz.xz ) * u_height;

                    float3 tangent   = normalize( dx - vertex );
                    float3 bitangent = normalize( dz - vertex );
                    float3 normal    = normalize( cross( bitangent, tangent ) );
                
                    v.vertex.y = min( vertex.y, vertex.y + delta_height );
                
                    o.normal   = normal;
                }
                else
                {
                    o.normal = float3( 0.0f, 1.0f, 0.0f );
                    o.vertex.y = -0.01f;
                }

                o.vertex = UnityObjectToClipPos( v.vertex );

                return o;
            }

            float4 frag ( Input IN ) : SV_Target
            {
                //if( IN.worldPos.y < 0.0f )
                //    discard;

                float3 uv = IN.worldPos + IN.offset;

                float2 uv_front = TRANSFORM_TEX( uv.xy, _MainTex );
		        float2 uv_side  = TRANSFORM_TEX( uv.yz, _MainTex );
		        float2 uv_top   = TRANSFORM_TEX( uv.xz, _MainTex );
				
		        float4 col_front = tex2D( _MainTex, uv_front );
		        float4 col_side  = tex2D( _MainTex, uv_side );
		        float4 col_top   = tex2D( _MainTex, uv_top );

		        float3 weights = pow( abs( IN.normal ), _Sharpness );
		        weights = weights / ( weights.x + weights.y + weights.z );

                float4 col   = col_top * _Color;
		        col_front *= weights.z;
		        col_side  *= weights.x;
		        col_top   *= weights.y;


                return col;
            }
            ENDHLSL
        }
    }
}

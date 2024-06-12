Shader "Unlit/Grass"
{
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
        }
        LOD 0
        Cull Off

        Pass
        {
            Tags { "LightMode" = "Grass" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"

            #include "cubicBezier.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float  height : TEXCOORD1;

            };

            struct grass
            {
                float3 position;
                float2 facing;
                float  height;
                float  width;
                uint   hash;
                float  tilt;
            };

            StructuredBuffer< grass > instance_buffer;

            v2f vert ( uint svVertexID: SV_VertexID, uint svInstanceID : SV_InstanceID )
            {
                v2f o;

                float height = floor( float( svVertexID ) * 0.5f ) * 0.143;
                float left   = ( float( svVertexID % 2 ) - 0.5f ) * instance_buffer[ svInstanceID ].width * ( 1.0f - height * height );

                cubicControllPoints points;
                
                points.p0 = float2( 0.0f, 0.0f );
                points.p1 = float2( 0.0f, 0.71f );
                points.p2 = float2( 0.36f, 1.0f );
                points.p3 = float2( 0.5f, 1.0f );
                

                float2 curve = bezierCurve( points, height );
                curve.x *= instance_buffer[ svInstanceID ].tilt;

                float2 pos2D = instance_buffer[ svInstanceID ].facing * left;
                float3 position = float3( pos2D.y, curve.y * instance_buffer[ svInstanceID ].height, -pos2D.x );

                float2 derivative = bezierCurveDerivative( points, height );
                float2 tangent2D  = instance_buffer[ svInstanceID ].facing * derivative.x * instance_buffer[ svInstanceID ].tilt;

                float3 tangent    = normalize( float3( tangent2D.x, derivative.y * instance_buffer[ svInstanceID ].height, tangent2D.y ) );
                float3 bitangent  = normalize( float3( instance_buffer[ svInstanceID ].facing.y, 0.0f, -instance_buffer[ svInstanceID ].facing.x ) );
                o.normal          = cross( bitangent, tangent );

                float2 tilt = instance_buffer[ svInstanceID ].facing * curve.x;
                position += float3( tilt.x, 0.0f, tilt.y );
                o.vertex = mul( UNITY_MATRIX_VP, float4( position + instance_buffer[ svInstanceID ].position, 1.0f ) );

                float3 cam_vec = normalize( _WorldSpaceCameraPos - ( position + instance_buffer[ svInstanceID ].position ) );
                if( dot( o.normal, cam_vec ) < 0.0f )
                {
                    o.normal *= -1.0f;
                }

                o.normal = normalize( o.normal + bitangent * left / abs( left ) * 0.6f );
                o.height = position.y;

                return o;
            }

            fixed4 frag ( v2f i ) : SV_Target
            {
                fixed3 col = fixed3( 0.12f, 0.41f, 0.0f );
                col += ShadeSH9( fixed4( i.normal, 1.0f ) );
                col *= i.height * 0.8f;

                return fixed4( col * ( dot( _WorldSpaceLightPos0.xyz, i.normal ) + 1.0f ), 1.0f );
            }
            ENDCG
        }
    }
}

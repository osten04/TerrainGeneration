Shader "Unlit/Grass"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 0
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"


            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            struct grass
            {
                float3 position;
                float2 facing;
                float  height;
                float  width;
                uint   hash;
            };

            StructuredBuffer< grass > instance_buffer;

            v2f vert ( uint svVertexID: SV_VertexID, uint svInstanceID : SV_InstanceID )
            {
                v2f o;

                float left   = ( float( svVertexID % 2 ) - 0.5f ) * instance_buffer[ svInstanceID ].width;
                float height = floor( float( svVertexID ) * 0.5f ) * 0.125f * instance_buffer[ svInstanceID ].height;

                float2 pos2D = instance_buffer[ svInstanceID ].facing * left;

                float3 position = float3( pos2D.y, height, -pos2D.x );

                float2 tilt = instance_buffer[ svInstanceID ].facing * position.y * position.y * 0.5f;

                position += float3( tilt.x, 0.0f, tilt.y );


                o.vertex = mul( UNITY_MATRIX_VP, float4( position + instance_buffer[ svInstanceID ].position, 1.0f ) );

                return o;
            }

            fixed4 frag ( v2f i ) : SV_Target
            {
                return fixed4( 0.12f, 0.41f, 0.0f, 1.0f );
            }
            ENDCG
        }
    }
}

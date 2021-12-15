Shader "Unlit/Flame_"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float noise(float3 p) //Thx to Las^Mercury
            {
                float3 i = floor(p);
                float4 a = dot(i, float3(1., 57., 21.)) + float4(0., 57., 21., 78.);
                float3 f = cos((p - i) * acos(-1.)) * (-.5) + .5;
                a = lerp(sin(cos(a) * a), sin(cos(1. + a) * (1. + a)), f.x);
                a.xy = lerp(a.xz, a.yw, f.y);
                return lerp(a.x, a.y, f.z);
            }

            float sphere(float3 p, float4 spr)
            {
                return length(spr.xyz - p) - spr.w;
            }

            float flame(float3 p)
            {
                float d = sphere(p * float3(1., .5, 1.), float4(.0, -1., .0, 1.));
                return d + (noise(p + float3(.0, _Time.y * 2., .0)) + noise(p * 3.) * .5) * .25 * (p.y);
            }

            float scene(float3 p)
            {
                return min(100. - length(p), abs(flame(p)));
            }

            float4 raymarch(float3 org, float3 dir)
            {
                float d = 0.0, glow = 0.0, eps = 0.02;
                float3  p = org;
                bool glowed = false;

                for (int i = 0; i < 64; i++)
                {
                    d = scene(p) + eps;
                    p += d * dir;
                    if (d > eps)
                    {
                        if (flame(p) < .0)
                            glowed = true;
                        if (glowed)
                            glow = float(i) / 64.;
                    }
                }
                return float4(p, glow);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //// sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                //// apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //return col;

                float2 v = -1.0 + 2.0 * i.vertex.xy / _ScreenParams.xy;
                v.x *= _ScreenParams.x / _ScreenParams.y;

                float3 org = float3(0., -2., 4.);
                float3 dir = normalize(float3(v.x * 1.6, -v.y, -1.5));

                float4 p = raymarch(org, float3(0.,0.,0.));
                float glow = p.w;

                float4 col = lerp(float4(1., .5, .1, 1.), float4(0.1, .5, 1., 1.), p.y * .02 + .4);

                return lerp(float4(0., 0., 0., 0.), col, pow(glow * 2., 4.));
            }
            ENDCG
        }
    }
}

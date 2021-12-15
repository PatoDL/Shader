

Shader "Unlit/Shader_"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Zoom("Zoom",float) = 9.
		_Z("Z",float) = .07
		_SpeedMultiplier("SpeedMultiplier",float) = 2
        _Angle("Angle",range(-3.1415,3.1415)) = 0
             _Area("Area",vector) = (0,0,4,4)
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
			
			#define mod(x,y) (x-y*floor(x/y))

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
			float1 _Zoom;
			float _OffsetX;
			float _OffsetY;
			float _Z;
			float _SpeedMultiplier;
            float _Angle;
            float4 _Area;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float2 rot(float2 p, float2 pivot, float a)
            {
                float s = sin(a);
                float c = cos(a);

                p -= pivot;

                p = float2(p.x * c - p.y * s, p.x * s + p.y * c);
                p += pivot;
                return p;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //// sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                //// apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

				float3 c;
				float1 l;
				float1 z = _Time.y;
				
				for (int j = 0; j < 3; j++)
				{
					float2 uv = _Area.xy + (i.uv - .5) * _Area.zw;
					float2 uvOffset = float2(uv.x +_Area.x,uv.y+_Area.y);
                    uv = rot(uv, _Area.xy, _Angle);
					z += _Z;
					l = length(uvOffset);
					uv += uvOffset / l * (sin(z) + 1.) * sin(l * _Zoom - z* _SpeedMultiplier);
					c[j] = .01 / length(mod(uv, 1.) - .5);
				}



                return float4(c / l, _Time.y);
            }
            ENDCG
        }
    }
}
/*
#define t iTime
#define r iResolution.xy

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	vec3 c;
	float l,z=t;
	for(int i=0;i<3;i++) {
		vec2 uv,p=fragCoord.xy/r;
		uv=p;
		p-=.5;
		p.x*=r.x/r.y;
		z+=.07;
		l=length(p);
		uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z-z));
		c[i]=.01/length(mod(uv,1.)-.5);
	}
	fragColor=vec4(c/l,t);
}
*/
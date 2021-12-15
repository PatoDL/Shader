Shader "Unlit/Emoji"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MousePos ("Mouse Position", vector) = (0,0,0,0)
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

            #define S(a, b, t) smoothstep(a, b, t)
            #define B(a, b, blur, t) S(a-blur, a+blur, t)*S(b+blur, b-blur, t)
            #define sat(x) clamp(x, 0., 1.)

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
            float2 _MousePos;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // "Smiley Tutorial" by Martijn Steinrucken aka BigWings - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
//
// This Smiley is part of my ShaderToy Tutorial series on YouTube:
// Part 1 - Creating the Smiley - https://www.youtube.com/watch?v=ZlNnrpM0TRg
// Part 2 - Animating the Smiley - https://www.youtube.com/watch?v=vlD_KOrzGDc&t=83s

            float remap01(float a, float b, float t) {
                return sat((t - a) / (b - a));
            }

            float remap(float a, float b, float c, float d, float t) {
                return sat((t - a) / (b - a)) * (d - c) + c;
            }

            float2 within(float2 uv, float4 rect) {
                return (uv - rect.xy) / (rect.zw - rect.xy);
            }

            float4 Brow(float2 uv, float smile) {
                float offs = lerp(.2, 0., smile);
                uv.y += offs;

                float y = uv.y;
                uv.y += uv.x * lerp(.5, .8, smile) - lerp(.1, .3, smile);
                uv.x -= lerp(.0, .1, smile);
                uv -= .5;

                float4 col = float4(0.,0.,0.,0.);

                float blur = .1;

                float d1 = length(uv);
                float s1 = S(.45, .45 - blur, d1);
                float d2 = length(uv - float2(.1, -.2) * .7);
                float s2 = S(.5, .5 - blur, d2);

                float browMask = sat(s1 - s2);

                float colMask = remap01(.7, .8, y) * .75;
                colMask *= S(.6, .9, browMask);
                colMask *= smile;
                float4 browCol = lerp(float4(.4, .2, .2, 1.), float4(1., .75, .5, 1.), colMask);

                uv.y += .15 - offs * .5;
                blur += lerp(.0, .1, smile);
                d1 = length(uv);
                s1 = S(.45, .45 - blur, d1);
                d2 = length(uv - float2(.1, -.2) * .7);
                s2 = S(.5, .5 - blur, d2);
                float shadowMask = sat(s1 - s2);

                col = lerp(col, float4(0., 0., 0., 1.), S(.0, 1., shadowMask) * .5);

                col = lerp(col, browCol, S(.2, .4, browMask));

                return col;
            }

            float4 Eye(float2 uv, float side, float2 m, float smile) {
                uv -= .5;
                uv.x *= side;

                float d = length(uv);
                float4 irisCol = float4(.3, .5, 1., 1.);
                float4 col = lerp(float4(1.,1.,1.,1.), irisCol, S(.1, .7, d) * .5);		// gradient in eye-white
                col.a = S(.5, .48, d);									// eye mask

                col.rgb *= 1. - S(.45, .5, d) * .5 * sat(-uv.y - uv.x * side); 	// eye shadow

                d = length(uv - m * .4);									// offset iris pos to look at mouse cursor
                col.rgb = lerp(col.rgb, float3(0.,0.,0.), S(.3, .28, d)); 		// iris outline

                irisCol.rgb *= 1. + S(.3, .05, d);						// iris lighter in center
                float irisMask = S(.28, .25, d);
                col.rgb = lerp(col.rgb, irisCol.rgb, irisMask);			// blend in iris

                d = length(uv - m * .45);									// offset pupile to look at mouse cursor

                float pupilSize = lerp(.4, .16, smile);
                float pupilMask = S(pupilSize, pupilSize * .85, d);
                pupilMask *= irisMask;
                col.rgb = lerp(col.rgb, float3(0.,0.,0.), pupilMask);		// blend in pupil

                float t = _Time.y * 3.;
                float2 offs = float2(sin(t + uv.y * 25.), sin(t + uv.x * 25.));
                offs *= .01 * (1. - smile);

                uv += offs;
                float highlight = S(.1, .09, length(uv - float2(-.15, .15)));
                highlight += S(.07, .05, length(uv + float2(-.08, .08)));
                col.rgb = lerp(col.rgb, float3(1.,1.,1.), highlight);			// blend in highlight

                return col;
            }

            float4 Mouth(float2 uv, float smile) {
                uv -= .5;
                float4 col = float4(.5, .18, .05, 1.);

                uv.y *= 1.5;
                uv.y -= uv.x * uv.x * 2. /** smile*/;

                //uv.x *= lerp(2.5, 1., smile);

                float d = length(uv);
                col.a = S(.5, .48, d);

                float2 tUv = uv;
                tUv.y += (abs(uv.x) * .5 + .1) /** (1. - smile)*/;
                float td = length(tUv - float2(0., .5));
                
                float3 toothCol = float3(0., 0., 0. /** S(1., 0., length(tUv)*/);
                col.rgb = lerp(col.rgb, toothCol, S(.39, .38, td));

                tUv = uv;
                tUv.y += (abs(uv.x) * .5 + .1) /** (1. - smile)*/;
                 td = length(tUv - float2(0., .6));

                 toothCol = float3(1., 1., 1.) /** S(.6, .35, d)*/;
                col.rgb = lerp(col.rgb, toothCol, S(.4, .37, td));

                td = length(uv + float2(0., .5));
                col.rgb = lerp(col.rgb, float3(1., .5, .5), S(.5, .2, td));
                return col;
            }

            float4 Head(float2 uv) {
                float4 col = float4(.9, .65, .1, 1.);

                float d = length(uv);

                //col.a = S(.5, .49, d);

                float edgeShade = remap01(.35, .5, d);
                edgeShade *= edgeShade;
                //col.rgb *= 1. - edgeShade * .5;

                //col.rgb = lerp(col.rgb, float3(.6, .3, .1), S(.47, .48, d));

                float highlight = S(.23, .24, .5 - length(uv - float2(0., .1))); //gris
                //highlight *= remap(.41, -.1, .75, 0., uv.y);
                //highlight *= S(.21, .22, length(uv));
                //highlight *= S(.19, .20, length(uv-float2(0., .10)));
                //col.rgb = lerp(col.rgb, float3(.5),highlight);
                //highlight = lerp(highlight,float4(1.,1.,1.,1.));
                col.rgb = lerp(col.rgb, float3(.7,.7,.7), highlight);
                highlight = S(.23, .24, .5 - length(uv - float2(0., .1))); //negro1
                highlight *= S(.255, .26, length(uv - float2(0., .1)));
                col.rgb = lerp(col.rgb, float3(0.,0.,0.), highlight);
                highlight = S(.3, .31, .5 - length(uv - float2(0., .1))); //negro2
                highlight *= S(.18, .19, length(uv - float2(0., .1)));
                col.rgb = lerp(col.rgb, float3(0.,0.,0.), highlight);
                highlight = S(.31, .315, .5 - length(uv - float2(0., .1))); //blanco
                col.rgb = lerp(col.rgb, float3(1.,1.,1.), highlight);
                highlight = S(.4, .405, .5 - length(uv - float2(0., .1))); //pupila
                col.rgb = lerp(col.rgb, float3(0.,0.,0.), highlight);

                d = length(uv - float2(.25, -.2));
                float cheek = S(.2, .01, d) * .4;
                cheek *= S(.17, .16, d);
                col.rgb = lerp(col.rgb, float3(1., .1, .1), cheek);

                d = length(uv - float2(-.25, -.2));
                cheek = S(.2, .01, d) * .4;
                cheek *= S(.17, .16, d);
                col.rgb = lerp(col.rgb, float3(1., .1, .1), cheek);

                return col;
            }

            float4 Smiley(float2 uv, float2 m, float smile) {
                float4 col = float4(0.,0.,0.,0.);

                if (length(uv) < .5 || (length(uv.x) < .499 && uv.y < .04)) {					// only bother about pixels that are actually inside the head
                    float side = sign(uv.x);
                    //uv.x = abs(uv.x);
                    float4 head = Head(uv);
                    col = lerp(col, head, head.a);

                    if (length(uv - float2(.2, .075)) < .175) {
                        float4 eye = Eye(within(uv, float4(.03, -.1, .37, .25)), side, m, smile);
                        //col = lerp(col, eye, eye.a);
                    }

                    if (length(uv - float2(.0, -.15)) < .3) {
                        float4 mouth = Mouth(within(uv, float4(-.3, -.43, .3, -.13)), smile);
                        col = lerp(col, mouth, mouth.a);
                    }

                    if (length(uv - float2(.185, .325)) < .18) {
                        float4 brow = Brow(within(uv, float4(.03, .2, .4, .45)), smile);
                        //col = lerp(col, brow, brow.a);
                    }
                }

                return col;
            }

            void mainImage(out float4 fragColor, in float2 fragCoord)
            {
                float t = _Time.y;

                float2 uv = fragCoord.xy / _ScreenParams.xy;
                uv -= .5;
                uv.x *= _ScreenParams.x / _ScreenParams.y;

                float2 m = _MousePos.xy / _ScreenParams.xy;
                m -= .5;

                if (m.x < -.49 && m.y < -.49) {			// make it that he looks around when the mouse hasn't been used
                    float s = sin(t * .5);
                    float c = cos(t * .38);

                    m = float2(s, c) * .4;
                }

                if (length(m) > .707) m *= 0.;		// fix bug when coming back from fullscreen

                float d = dot(uv, uv);
                //uv -= m*sat(.23-d);

                float smile = sin(t * .5) * .5 + .5;
                fragColor = Smiley(uv, m, smile);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float t = _Time.y;

                float2 uv = i.vertex.xy / _ScreenParams.xy;
                uv -= .5;
                uv.x *= _ScreenParams.x / _ScreenParams.y;

                float2 m = _MousePos.xy / _ScreenParams.xy;
                m -= .5;

                if (m.x < -.49 && m.y < -.49) {			// make it that he looks around when the mouse hasn't been used
                    float s = sin(t * .5);
                    float c = cos(t * .38);

                    m = float2(s, c) * .4;
                }

                if (length(m) > .707) m *= 0.;		// fix bug when coming back from fullscreen

                float d = dot(uv, uv);
                //uv -= m*sat(.23-d);

                float smile = sin(t * .5) * .5 + .5;
                return Smiley(uv, m, smile);
            }
            ENDCG
        }
    }
}

Shader "Unlit/MineDepthShader"
{
	Properties
	{
		_DepthScale("DepthScale", float) = 1
		_ProjectorTex ("ProjectorTex", 2D) = "white" {}
		_ProjectorTexMask("FallOffTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="true" "DisableBatching"="true" }
		LOD 100
		ZWrite Off
		ColorMask RGB
		Blend DstColor Zero
		Offset -1, -1

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
			};

			float4x4 _WorldToProjector;
			float4x4 _WorldToProjectorClip;
			sampler2D _ProjectorTexMask;
			sampler2D _ProjectorTex;
			sampler2D _CameraDepthTexture;
			float _DepthScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 screenPos = i.screenPos;
				screenPos.xy = screenPos.xy / screenPos.w;

				float depth = tex2D(_CameraDepthTexture, screenPos).r;
				float displayDepth = Linear01Depth(depth) * _DepthScale;

				//还原回-1 ,1 的clip控件坐标 inv ComputeScreenPos
				fixed4 clipPos = fixed4(screenPos.x * 2 - 1, screenPos.y * 2 - 1, -depth * 2 + 1, 1);

				//还原回相机空间
				fixed4 cameraSpacePos = mul(unity_CameraInvProjection, clipPos);
				//还原回世界空间
				fixed4 worldSpacePos = mul(unity_MatrixInvV, cameraSpacePos);

				//变换到自定义投影器投影空间
				fixed4 projectorPos = mul(_WorldToProjector, worldSpacePos);
				projectorPos /= projectorPos.w;

				fixed2 projUV = projectorPos.xy * 0.5 + 0.5;  //变换到uv坐标系

				fixed4 col = tex2D(_ProjectorTex, projUV);
				fixed4 mask = tex2D(_ProjectorTexMask, projUV);

				col.rgb =  lerp(fixed3(1, 1, 1), col.rgb, (1 - mask.r));

				return col;
			}

			ENDCG
		}
	}
}

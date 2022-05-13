#ifndef TMP3D_COMMON_CG_INCLUDED
#define TMP3D_COMMON_CG_INCLUDED

#include "TMP3D_Structs.cginc"
#include "TMP3D_Properties.cginc"

float InverseLerp(float a, float b, float x)
{
	return (x - a) * (1 / (b - a));
}

float SampleSDF3D(float3 mask3D, tmp3d_g2f input)
{
	float2 maskUV = float2(0, 0);
	maskUV.x = saturate(lerp(input.boundariesUV.x, input.boundariesUV.x + input.boundariesUV.z, mask3D.x));
	maskUV.y = saturate(lerp(input.boundariesUV.y, input.boundariesUV.y + input.boundariesUV.w, mask3D.y));
	return tex2D(_MainTex, maskUV).a;
}

// tests if a fragment is outside of bounds
float IsInBounds(float3 mask3D)
{
	float clipX = -(abs(mask3D.x - 0.5) - 0.5) + 0.01;
	float clipY = -(abs(mask3D.y - 0.5) - 0.5) + 0.01;
	float clipZ = -(abs(mask3D.z - 0.5) - 0.5) + 0.01;
	return min(0, min(clipX, min(clipY, clipZ)));
}

// Clips a fragment if outside of bounds
void ClipBounds(float3 mask3D)
{
	clip(IsInBounds(mask3D));
}

float3 PositionToMask(float3 localPos, tmp3d_g2f input)
{
	float3 mask3D = float3(-1, -1, -1);
	mask3D.y = InverseLerp(input.boundariesLocal.y, input.boundariesLocal.y + input.boundariesLocal.w, localPos.y);
	float xOffset = saturate(mask3D.y) * input.boundariesLocalZ.z;
	mask3D.x = InverseLerp(input.boundariesLocal.x, input.boundariesLocal.x + input.boundariesLocal.z, localPos.x - xOffset);
	mask3D.z = InverseLerp(input.boundariesLocalZ.x, input.boundariesLocalZ.y, localPos.z);
	return mask3D;
}

float GradientToLocalLength(tmp3d_g2f input)
{
	float l = input.boundariesLocal.z;
	return l * 0.01 * _GradientScale;
}

float4x4 tmp3d_l2w;
float4x4 tmp3d_w2l;

float4x4 quaternion_to_matrix(float4 quat)
{
	float4x4 m = float4x4(float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0));

	float x = quat.x, y = quat.y, z = quat.z, w = quat.w;
	float x2 = x + x, y2 = y + y, z2 = z + z;
	float xx = x * x2, xy = x * y2, xz = x * z2;
	float yy = y * y2, yz = y * z2, zz = z * z2;
	float wx = w * x2, wy = w * y2, wz = w * z2;

	m[0][0] = 1.0 - (yy + zz);
	m[0][1] = xy - wz;
	m[0][2] = xz + wy;

	m[1][0] = xy + wz;
	m[1][1] = 1.0 - (xx + zz);
	m[1][2] = yz - wx;

	m[2][0] = xz - wy;
	m[2][1] = yz + wx;
	m[2][2] = 1.0 - (xx + yy);

	m[3][3] = 1.0;

	return m;
}

float4x4 inverse(float4x4 m) {
	float n11 = m[0][0], n12 = m[1][0], n13 = m[2][0], n14 = m[3][0];
	float n21 = m[0][1], n22 = m[1][1], n23 = m[2][1], n24 = m[3][1];
	float n31 = m[0][2], n32 = m[1][2], n33 = m[2][2], n34 = m[3][2];
	float n41 = m[0][3], n42 = m[1][3], n43 = m[2][3], n44 = m[3][3];

	float t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
	float t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
	float t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
	float t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

	float det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
	float idet = 1.0f / det;

	float4x4 ret;

	ret[0][0] = t11 * idet;
	ret[0][1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * idet;
	ret[0][2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * idet;
	ret[0][3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * idet;

	ret[1][0] = t12 * idet;
	ret[1][1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * idet;
	ret[1][2] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * idet;
	ret[1][3] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * idet;

	ret[2][0] = t13 * idet;
	ret[2][1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * idet;
	ret[2][2] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * idet;
	ret[2][3] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * idet;

	ret[3][0] = t14 * idet;
	ret[3][1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * idet;
	ret[3][2] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * idet;
	ret[3][3] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * idet;

	return ret;
}

tmp3d_v2g TMP3D_VERT(tmp3d_a2v input)
{
	tmp3d_v2g output;

	output.position = mul(unity_ObjectToWorld, input.position);
	output.normal = mul(unity_ObjectToWorld, input.normal);
	float4 pos = mul(unity_WorldToObject, float4(0,1,0,1));
	output.color = input.color;
	output.texcoord0 = input.texcoord0;
	output.texcoord1 = input.texcoord1;
	output.texcoord2 = input.texcoord2;
	output.texcoord3 = input.texcoord3;

	return output;
}

// "Creates a vertex" with an offset and boundary values
tmp3d_g2f CreateVertex(tmp3d_v2g input, float3 positionOffset, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	tmp3d_g2f output;

	input.normal = mul(unity_WorldToObject, input.normal);

	UNITY_INITIALIZE_OUTPUT(tmp3d_g2f, output);
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	input.position /= input.position.w;

	output.worldPos = input.position;
	output.worldPos.xyz += positionOffset;
	float4 vert = mul(unity_WorldToObject, output.worldPos);
	float4 vPosition = UnityObjectToClipPos(vert);

	output.position = vPosition;
	output.color = input.color;
	output.atlas = input.texcoord0;
	output.boundariesUV = boundariesUV;
	output.boundariesLocal = boundariesLocal;
	output.boundariesLocalZ = boundariesLocalZ;
	output.tmp3d = input.texcoord2;
	output.tmp = input.texcoord1;
	output.quaternion = input.texcoord3;

	return output;
}

void TMP3D_FILLGEOMETRY(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	// Top
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Bottom
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side A
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side B
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side C is in between of the quad's triangles and not wanted
}

void TMP3D_FILLGEOMETRY_INVERTED(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream, float3 def, float3 normal, float4 boundariesUV, float4 boundariesLocal, float4 boundariesLocalZ)
{
	// Top
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Bottom
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side A
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[0], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side B
	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	triStream.RestartStrip();
	triStream.Append(CreateVertex(input[1], def, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], normal, boundariesUV, boundariesLocal, boundariesLocalZ));
	triStream.Append(CreateVertex(input[2], def, boundariesUV, boundariesLocal, boundariesLocalZ));

	// Side C is in between of the quad's triangles and not wanted
}

// Extrudes the TMP quads
[maxvertexcount(24)]
void TMP3D_GEOM(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream)
{
	tmp3d_g2f o;

	float3 def = float3(0, 0, 0);
	float depth = input[0].texcoord2.r;
	float3 normal = input[0].normal * depth;

	float skewUV = abs(input[1].texcoord0.x - input[0].texcoord0.x);
	float widthUV = abs(input[2].texcoord0.x - input[1].texcoord0.x);
	float heightUV = abs(input[1].texcoord0.y - input[0].texcoord0.y);
	float xUV = min(input[0].texcoord0.x, input[2].texcoord0.x);
	float yUV = min(input[0].texcoord0.y, input[1].texcoord0.y);
	float4 boundariesUV = float4(xUV, yUV, widthUV, heightUV);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float4x4 w2l = inverse(quaternion_to_matrix(input[0].texcoord3));
	v0local = mul(w2l, float4(v0local.xyz, 1)).xyz;
	v1local = mul(w2l, float4(v1local.xyz, 1)).xyz;
	v2local = mul(w2l, float4(v2local.xyz, 1)).xyz;

	//input[0].color = float4(v0local.xyz, 1);
	//input[1].color = float4(v1local.xyz, 1);
	//input[2].color = float4(v2local.xyz, 1);

	float skewLocal = abs(v1local.x - v0local.x);
	float widthLocal = abs(v2local.x - v1local.x);
	float heightLocal = abs(v1local.y - v0local.y);
	float xLocal = min(v0local.x, v2local.x);
	float yLocal = min(v0local.y, v1local.y);
	float4 boundariesLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

	float4 boundariesLocalZ = float4(-depth, 0, skewLocal, skewUV);

	TMP3D_FILLGEOMETRY(input, triStream, def, normal, boundariesUV, boundariesLocal, boundariesLocalZ);
}

// Extrudes the TMP quads
[maxvertexcount(24)]
void TMP3D_GEOM_INVERTED(triangle tmp3d_v2g input[3], inout TriangleStream<tmp3d_g2f> triStream)
{
	tmp3d_g2f o;

	float3 def = float3(0, 0, 0);
	float depth = input[0].texcoord2.r;
	float3 normal = input[0].normal * depth;

	float skewUV = abs(input[1].texcoord0.x - input[0].texcoord0.x);
	float widthUV = abs(input[2].texcoord0.x - input[1].texcoord0.x);
	float heightUV = abs(input[1].texcoord0.y - input[0].texcoord0.y);
	float xUV = min(input[0].texcoord0.x, input[2].texcoord0.x);
	float yUV = min(input[0].texcoord0.y, input[1].texcoord0.y);
	float4 boundariesUV = float4(xUV, yUV, widthUV, heightUV);

	float3 v0local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
	float3 v1local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
	float3 v2local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

	float4x4 w2l = inverse(quaternion_to_matrix(input[0].texcoord3));
	v0local = mul(w2l, float4(v0local.xyz, 1)).xyz;
	v1local = mul(w2l, float4(v1local.xyz, 1)).xyz;
	v2local = mul(w2l, float4(v2local.xyz, 1)).xyz;

	float skewLocal = abs(v1local.x - v0local.x);
	float widthLocal = abs(v2local.x - v1local.x);
	float heightLocal = abs(v1local.y - v0local.y);
	float xLocal = min(v0local.x, v2local.x);
	float yLocal = min(v0local.y, v1local.y);
	float4 boundariesLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

	float4 boundariesLocalZ = float4(-depth, 0, skewLocal, skewUV);

	TMP3D_FILLGEOMETRY_INVERTED(input, triStream, def, normal, boundariesUV, boundariesLocal, boundariesLocalZ);
}

#endif
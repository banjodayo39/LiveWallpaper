//
//  MainShader.metal
//  LiveWallpaper
//
//  Created by Dayo Banjo on 4/18/23.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;


float sin_shape2(float2 uv, float offset_y, float time) {
    // Time varying pixel color
    float y = sin((uv.x + time * -0.06 + offset_y) * 5.5);
    float x = uv.x * 8.;
    float a=1.;
    for (int i=0; i<5; i++) {
        x*=0.53562;
        x+=6.56248;
        y+=sin(x)*a;
        a*=.5;
    }
    float y0 = step(0.0, y * 0.08 - uv.y + offset_y);
    return y0;
}

float2 rotate2(float2 coord, float alpha) {
    float cosA = cos(alpha);
    float sinA = sin(alpha);
    return float2(coord.x * cosA - coord.y * sinA, coord.x * sinA + coord.y * cosA);
}

float3 spectrumWaves2(float2 uv, float time) {
    float3 col = float3(0.0, 0.0, 0.0);
    col += sin_shape2(uv, 0.3, time) * 0.2;
    col += sin_shape2(uv, 0.7, time) * 0.2;
    col += sin_shape2(uv, 1.1, time) * 0.2;
    float3 fragColor;
    if (col.x >= 0.8 ) {
        fragColor = float3(0.96, 0.77, 0.77); // light pink
    } else if (col.x >= 0.6) {
        fragColor = float3(0.96, 0.52, 0.71); // light magenta
    } else if (col.x >= 0.4) {
        fragColor = float3(0.96, 0.33, 0.56); // deep pink
    } else if (col.x >= 0.2) {
        fragColor = float3(0.96, 0.21, 0.38); // magenta red
    } else if (col.x >= 0.1) {
        fragColor = float3(0.95, 0.10, 0.25); // scarlet red
    } else {
        fragColor = float3(0.94, 0.00, 0.14); // vermillion red
    }

    return fragColor;
}


void voronoi(float2 uv,  float3 col, float time)
{
  constexpr int POINTS = 16;
  constexpr float WAVE_OFFSET = 12000.0;
  constexpr float SPEED = 1.0 / 12.0;
  constexpr float COLOR_SPEED = 1.0 / 4.0;
  constexpr float BRIGHTNESS = 1.2;
  
    float3 voronoi = float3(0.0);
    float bestDistance = 999.0;
    float lastBestDistance = bestDistance;

    for (int i = 0; i < POINTS; i++)
    {
        float fi = float(i);
        float2 p = float2(fmod(fi, 1.0) * 0.1 + sin(fi), -0.05 + 0.15 * float(i / 10) + cos(fi + time * cos(uv.x * 0.025)));
        float d = distance(uv, p);
        if (d < bestDistance)
        {
            lastBestDistance = bestDistance;
            bestDistance = d;

            voronoi.x = p.x;
            voronoi.yz = float2(p.x * 0.4 + p.y, p.y) * float2(0.9, 0.87);
        }
    }

    col *= 0.68 + 0.19 * voronoi;
    col += smoothstep(0.99, 1.05, 1.0 - abs(bestDistance - lastBestDistance)) * 0.9;
    col += smoothstep(0.95, 1.01, 1.0 - abs(bestDistance - lastBestDistance)) * 0.1 * col;
    col += voronoi * 0.1 * smoothstep(0.5, 1.0, 1.0 - abs(bestDistance - lastBestDistance));
}

struct VertexIn {
  float3 position [[attribute(0)]];
  float3 normal [[attribute(1)]];
  float4 color [[attribute(2)]];
  float2 tex [[attribute(3)]];
};

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float2 tex;
  float time;
  int2 resolution;

  // Optional for point primitives
  float pointSize [[point_size]];
};

struct FragmentOut {
  float4 color0 [[color(0)]];
};

struct Uniforms {
  float time;
  float2 touchPoint;
  int2 resolution;
  float4x4 view;
  float4x4 inverseView;
  float4x4 viewProjection;
};

struct ModelConstants {
  float4x4 modelMatrix;
  float4x4 inverseModelMatrix;
};

vertex VertexOut basic_vertex(
  const VertexIn vIn [[ stage_in ]],
  const device Uniforms& uniforms [[ buffer(0) ]],
  const device ModelConstants& constants [[ buffer(1) ]]) {

  VertexOut vOut;
  vOut.position = uniforms.viewProjection * constants.modelMatrix * float4(vIn.position, 1.0);
  vOut.color = vIn.color;
  vOut.tex = vIn.tex;
  vOut.pointSize = 30.0;
  vOut.time = uniforms.time;
    vOut.resolution = uniforms.resolution;
    
//  vOut.color.x *= sign(cos(length(ceil(vOut.color.xy /= 50.))*99.));
//  float value = cos(min(length(vOut.tex = fract(vOut.tex)), length(--vOut.tex))*44.);
//  vOut.color = float4(value, value, value, 1);

  return vOut;
}

//https://www.shadertoy.com/view/ctd3Rl
//https://www.shadertoy.com/view/4dcGW2
fragment FragmentOut color_fragment(VertexOut interpolated [[stage_in]],
                              float2 pointCoord [[point_coord]],
                              const device Uniforms& uniforms [[ buffer(0) ]]) {
  //float dist = length(pointCoord - float2(0.5));

  FragmentOut out;
  float gradient = interpolated.position.x;
  out.color0 =  float4(gradient, gradient, gradient, 0.5);
  return out;
}

fragment FragmentOut vortex_fragment(VertexOut interpolated [[stage_in]],
                              float2 pointCoord [[point_coord]],
                              const device Uniforms& uniforms [[ buffer(0) ]]) {
  //float dist = length(pointCoord - float2(0.5));
  FragmentOut out;
//  if (pointCoord.x > 0.5) {
//    out.color0 = float4(1.0, 0.0, 0.0, 1.0);
//  } else {
//  }
  //out.color0 =  float4(1.0, 1.0, 0.0, 1.0);
  //interpolated.color;
  
  //** Monterery
  float2 fragCoord = interpolated.position.xy;
     float2 resolution = float2(interpolated.resolution.y, interpolated.resolution.y);
     float time = interpolated.time;
     fragCoord = rotate2(fragCoord + float2(0.0, -300.0), 0.5);
     
     // Normalized pixel coordinates (from 0 to 1)
     float3 col0 = spectrumWaves2((fragCoord * 2.0) / resolution.xy, time);
     float3 col1 = spectrumWaves2(((fragCoord * 2.0) + float2(1.0, 0.0)) / resolution.xy, time);
     float3 col2 = spectrumWaves2(((fragCoord * 2.0) + float2(1.0, 1.0)) / resolution.xy, time);
     float3 col3 = spectrumWaves2(((fragCoord * 2.0) + float2(0.0, 1.0)) / resolution.xy, time);
     
     float4 fragColor = float4((col0 + col1 + col2 + col3) / 4.0, 1.0);
     
     float2 uv = fragCoord / resolution.xy;
     fragColor.xyz *= (uv.y * 1.08 + 0.65) * float3(uv, 1.0);
     
     out.color0 = float4(col3, 1.0);
     return out;
}

fragment FragmentOut texture_fragment(
  VertexOut interpolated [[stage_in]],
  texture2d<float, access::sample> diffuseTexture [[texture(0)]],
  sampler diffuseSampler [[sampler(0)]]) {

  FragmentOut out;
//  out.color0 = diffuseTexture.sample(diffuseSampler, interpolated.tex).rgba;
//  return out;
    
    float2 fragCoord = interpolated.position.xy;
       float2 resolution = float2(interpolated.resolution.y, interpolated.resolution.y);
       float time = interpolated.time;
       fragCoord = rotate2(fragCoord + float2(0.0, -300.0), 0.5);
       
       // Normalized pixel coordinates (from 0 to 1)
       float3 col0 = spectrumWaves2((fragCoord * 2.0) / resolution.xy, time);
       float3 col1 = spectrumWaves2(((fragCoord * 2.0) + float2(1.0, 0.0)) / resolution.xy, time);
       float3 col2 = spectrumWaves2(((fragCoord * 2.0) + float2(1.0, 1.0)) / resolution.xy, time);
       float3 col3 = spectrumWaves2(((fragCoord * 2.0) + float2(0.0, 1.0)) / resolution.xy, time);
       
       float4 fragColor = float4((col0 + col1 + col2 + col3) / 4.0, 1.0);
       
       float2 uv = fragCoord / resolution.xy;
       float4 tex_color = diffuseTexture.sample(diffuseSampler, uv);
       fragColor.xyz *= (uv.y * 1.08 + 0.65) * tex_color.xyz;
       
       out.color0 = float4(col3, 1.0);
       return out;
}


// For use with rendering ARKit video

typedef struct {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} ImageVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;

// Captured image vertex function
vertex ImageColorInOut capturedImageVertexTransform(ImageVertex in [[stage_in]]) {
    ImageColorInOut out;

    // Pass through the image vertex's position
    out.position = float4(in.position, 0.0, 1.0);

    // Pass through the texture coordinate
    out.texCoord = in.texCoord;

    return out;
}

// Captured image fragment function
fragment float4 capturedImageFragmentShader(ImageColorInOut in [[stage_in]],
                                            texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]]) {

    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoord).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.texCoord).rg, 1.0);

    // Return converted RGB color
  return ycbcrToRGBTransform * ycbcr;
}

#include <metal_stdlib>

using namespace metal;

float C (float2 uv, float2 R) {
    return smoothstep(4.0 / R.y, 0.0, length(uv) - 0.5);
}

kernel void splitView(
                      texture2d<float, access::write> outputTexture [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
 
  
  
//    uint2 size = inputTexture.get_width();
//    float2 uv = float2(gid) / float2(size);
//
//    if (uv.x < 0.5) {
//        // Left half of the view
//        outputTexture.write(inputTexture.read(gid), gid);
//    } else {
//        // Right half of the view
//        uint2 mirroredGid = uint2(size.x - gid.x - 1, gid.y);
//        outputTexture.write(inputTexture.read(mirroredGid), gid);
//    }
      float2 R = float2(1.0); // initialize R
      float2 uv = 1.5 * (float2(gid) - 0.005 * R.xy);
      float3 col1 = float3(1.0, 0.1, 0.13);
      float3 col2 = float3(0.65, 0.0, 0.1);
      
      float h = C(uv * float2(1.0, 0.35), R);
      float c1 = C(uv, R) - C(uv * float2(0.275, 0.16) - float2(0.175, 0.0), R);
      float c2 = C(uv, R) - c1;

      float3 l = c1 * mix(col2, col1, uv.y + 0.5)
                + c2 * mix(col1 + float3(0.1), col2 - float3(0.1), uv.y + 0.5);
  outputTexture.write(float4(mix(float3(1.0, 0.1, 0.3), l, c1 + c2 - h), 1.0), gid);

}

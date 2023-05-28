//
//  WaterEffect.metal
//  LiveWallpaper
//
//  Created by Dayo Banjo on 4/21/23.
//
#include <metal_stdlib>
using namespace metal;

constant float PI = 3.1415926535897932;

// play with these parameters to custimize the effect
// ===================================================


//speed
constant float speed_x = 0.2;
constant float speed_y = 0.2;

// refraction
constant float emboss = 0.50;
constant float intensity = 2.4;
constant int steps = 8;
constant float frequency = 6.0;
constant int angle = 7; // better when a prime

// reflection
constant float delta = 60.;

constant float reflectionCutOff = 0.012;
constant float reflectionIntence = 200000.;

float col(float2 coord,float time, float speed);
// ===================================================


float col(float2 coord,float time, float speed)
{
    float delta_theta = 2.0 * PI / float(angle);
    float col = 0.0;
    float theta = 0.0;
    for (int i = 0; i < steps; i++)
    {
        float2 adjc = coord;
        theta = delta_theta*float(i);
        adjc.x += cos(theta)*time*speed + time * speed_x;
        adjc.y -= sin(theta)*time*speed - time * speed_y;
        col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*frequency)*intensity;
    }
    
    return cos(col);
}

struct Uniforms2 {
  float time;
  int2 resolution;
  float4x4 view;
  float4x4 inverseView;
  float4x4 viewProjection;
};

#include <metal_stdlib>
using namespace metal;

float sin_shape(float2 uv, float offset_y, float iTime) {
  // Time varying pixel color
  float y = sin((uv.x + iTime * -0.06 + offset_y) * 5.5);

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

float2 rotate(float2 coord, float alpha) {
  float cosA = cos(alpha);
  float sinA = sin(alpha);
  return float2(coord.x * cosA - coord.y * sinA, coord.x * sinA + coord.y * cosA);
}

float3 scene(float2 uv, float iTime) {
  float3 col = float3(0.0, 0.0, 0.0);
  col += sin_shape(uv, 0.3, iTime) * 0.2;
  col += sin_shape(uv, 0.7, iTime) * 0.2;
  col += sin_shape(uv, 1.1, iTime) * 0.2;

  float3 fragColor;

  if (col.x >= 0.6 ) {
    fragColor = float3(0.27, 0.11, 0.64);
  } else if (col.x >= 0.4) {
    fragColor = float3(0.55, 0.19, 0.69);
  } else if (col.x >= 0.2) {
    fragColor = float3(0.68, 0.23, 0.65);
  } else {
    fragColor = float3(0.86, 0.57, 0.68);
  }
  return fragColor;
}

kernel void waterEffect(texture2d<float, access::write> output [[texture(0)]],
                           texture2d<float, access::sample> input [[texture(1)]],
                           const device Uniforms2& uniforms [[ buffer(0) ]],
                           constant float &speed [[buffer(1)]],
                           constant float &intense [[buffer(2)]],
                           constant float &timer [[buffer(3)]],
                           sampler sample2d [[ sampler(0) ]],
                           uint2 gid [[thread_position_in_grid]]) {
  float2 fragCoord = input.sample(sample2d, float2(0.2)).xy;

  fragCoord = rotate(fragCoord + float2(0.0, -300.0), 0.5);
  // Normalized pixel coordinates (from 0 to 1)
  float2 iResolution = float2(uniforms.resolution).xy;
  float3 col0 = scene((fragCoord * float(2.0))/iResolution, uniforms.time);
  float3 col1 = scene(((fragCoord * 2.0) + float2(1.0, 0.0))/iResolution, uniforms.time);
  float3 col2 = scene(((fragCoord * 2.0) + float2(1.0, 1.0))/iResolution, uniforms.time);
  float3 col3 = scene(((fragCoord * 2.0) + float2(0.0, 1.0))/iResolution, uniforms.time);

  // Output to screen
  float3 fragColor = (col0 + col1 + col2 + col3) / 4.0;
  float4 color =  float4(fragColor, 1.0);
  output.write(color, gid);
}

/*
kernel void waterEffect(texture2d<float, access::write> output [[texture(0)]],
                        texture2d<float, access::sample> input [[texture(1)]],
                        const device Uniforms2& uniforms [[ buffer(0) ]],
                        constant float &speed [[buffer(1)]],
                        constant float &intense [[buffer(2)]],
                        constant float &timer [[buffer(3)]],
                        uint2 gid [[thread_position_in_grid]])
{
    
    float time = timer *  1.3;
    
    int width = output.get_width();
    int height = output.get_height();
    
    float2 p = float2(gid) / float2(width, height);
    
    p = float2(p.x, 1 - p.y);
    
    float2 c1 = p, c2 = p;
    float cc1 = col(c1, time, speed);
    
    c2.x += width/delta;
    float dx = emboss*(cc1-col(c2,time, speed))/delta;
    
    
    c2.x = p.x;
    c2.y += height/delta;
    float dy = emboss*(cc1-col(c2,time, speed))/delta;
    
    
    
    c1.x += dx*2.;
    c1.y = -(c1.y+dy*2.);
    
    float alpha = 1. +  dx * dy *intense;
    
    float ddx = dx - reflectionCutOff;
    float ddy = dy - reflectionCutOff;
    if (ddx > 0. && ddy > 0.)
        alpha = pow(alpha, ddx*ddy*reflectionIntence);
    
    
    constexpr sampler textureSampler(coord::normalized,
                                     address::repeat,
                                     min_filter::linear,
                                     mag_filter::linear,
                                     mip_filter::linear );
    
    
    float4 color = input.sample(textureSampler,c1).rgba;
    output.write(color*(alpha), gid);
}
*/


//void mainImage( out vec4 fragColor, in vec2 fragCoord )
//{
//    // Normalized pixel coordinates (from 0 to 1)
//    vec2 uv = fragCoord/iResolution.xy;
//
//    // Time varying pixel color
//    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
//
//    // Output to screen
//    fragColor = vec4(col,0.4);
//}




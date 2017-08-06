//
//  basic.metal
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;


struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

struct UITouchState {
    bool isTouching;
};

struct Particle
{
    packed_float3 position;
    packed_float3 velocity;
    float mass;
    packed_float3 startPos;
};

float constrain(float val, float min, float max) {
    if (val < min) {
        return min;
    } else if (val > max) {
        return max;
    } else {
        return val;
    }
}

Particle slowDown(Particle thisParticle) {
    thisParticle.velocity[0] *= 0.995;
    thisParticle.velocity[1] *= 0.995;
    thisParticle.velocity[2] *= 0.995;
    return thisParticle;
}

kernel void particleRendererShader(
                                   device Particle *inParticle [[ buffer(0) ]],
                                   device Particle *outParticle [[ buffer(1) ]],
                                   const device Particle &mouse [[ buffer(2) ]],
                                   const device UITouchState &uiTouchState [[ buffer(3) ]],
                                   uint id [[thread_position_in_grid]])
{
    bool isHead = (id % 2 == 0);
    Particle thisParticle = inParticle[id];
    
    if (uiTouchState.isTouching) {
        if (isHead) {
            float3 diff;

            diff = thisParticle.position - (mouse.position);
//            diff = thisParticle.position - float3(0.0);

            float distance = constrain(length(diff), 10.0, 70.0);
            float strength = thisParticle.mass * mouse.mass / (distance * distance);
            
            diff = normalize(diff);
            diff = diff * strength * -0.083;
            
            thisParticle.velocity = thisParticle.velocity + diff;
            thisParticle.position = thisParticle.position + thisParticle.velocity;

            if (thisParticle.position[0] > 1.0 || thisParticle.position[0] < -1.0 ) {
                thisParticle = slowDown(thisParticle);
            } else if (thisParticle.position[1] > 1.0 || thisParticle.position[1] < -1.0 ) {
                thisParticle = slowDown(thisParticle);
            } else if (thisParticle.position[2] > 1.0 || thisParticle.position[2] < -1.0 ) {
                thisParticle = slowDown(thisParticle);
            }
        } else {
            Particle headParticle = inParticle[id-1];
            thisParticle.position = headParticle.position - headParticle.velocity * 2.5;
        }
    } else {
        if (isHead) {
            float3 diff;
            
            diff = (thisParticle.startPos) - thisParticle.position;
//            diff = thisParticle.position - float3(0.0);

            thisParticle.velocity = thisParticle.velocity * 0.99 + diff / 500;
            thisParticle.position = thisParticle.position + thisParticle.velocity;
        } else {
            Particle headParticle = inParticle[id-1];
            thisParticle.position = headParticle.position - headParticle.velocity * 2.5;
        }
    }
    
    
    //mass
    outParticle[id].position = thisParticle.position;
    outParticle[id].velocity = thisParticle.velocity;
    outParticle[id].mass = thisParticle.mass;
}

struct VertexOut {
    float4 position [[position]];
    float pointsize [[point_size]];
    float3 color;
};

vertex VertexOut particle_vertex(                           // 1
                           device Particle *inParticle [[ buffer(0) ]], // 2
                           const device Uniforms &uniforms [[ buffer(1) ]],
                           unsigned int id [[ vertex_id ]]) {                 // 3
    
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    Particle thisParticle = inParticle[id];
    VertexOut VertexOut;
    
    VertexOut.position = proj_Matrix * mv_Matrix * float4(thisParticle.position, 1.0);
    VertexOut.pointsize = 1.0;
    VertexOut.color = thisParticle.velocity;
    
    return VertexOut;              // 4
}


fragment half4 particle_fragment(
                                 VertexOut         interpolated       [[stage_in]]
                                 ) {
    
    interpolated.color *= 100.0;
    
    if (interpolated.color.x < 0.5) {
        interpolated.color.x += 0.35;
    }
    if (interpolated.color.y < 0.5) {
        interpolated.color.y += 0.35;
    }
    if (interpolated.color.z < 0.5) {
        interpolated.color.z += 0.35;
    }
    
    return half4(
                 interpolated.color.x,
                 interpolated.color.y,
                 interpolated.color.z, 1.0);
}




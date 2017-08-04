//
//  basic.metal
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;



struct Particle
{
    packed_float3 position;
    packed_float3 velocity;
    packed_float3 acceleration;
    
    float mass;
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

kernel void particleRendererShader(
                                   device Particle *inParticle [[ buffer(0) ]],
                                   device Particle *outParticle [[ buffer(1) ]],
                                   const device Particle &mouse [[ buffer(2) ]],
                                   uint id [[thread_position_in_grid]])
{
    Particle thisParticle = inParticle[id];
    
    //outParticle[id].position = thisParticle.position + thisParticle.velocity;
    
//    //calc force
//    float mass = thisParticle.mass;
//    float3 force = thisParticle.position - mouse.position;
//    float distance = length(force);
//    float d = constrain(distance, 10.0, 50.0);
//    force = normalize(force);
//    float strength = 1.0 * mass * mouse.mass / (d * d);
//    force = force * strength;
//
//    // apply force
//    float3 f = force / thisParticle.mass;
//    thisParticle.acceleration = thisParticle.acceleration + f;
//
//    // update position
//    thisParticle.velocity = thisParticle.velocity + thisParticle.acceleration;
//    thisParticle.position = thisParticle.position + thisParticle.velocity;
//    thisParticle.acceleration = thisParticle.acceleration * 0.0;
    
    
    //mass
    outParticle[id].position = thisParticle.position;
    outParticle[id].velocity = thisParticle.velocity;
    outParticle[id].acceleration = thisParticle.acceleration;
    outParticle[id].mass = thisParticle.mass;
}

struct VertexOut {
    float4 position[[position]];
    float pointsize[[point_size]];
};

vertex VertexOut particle_vertex(                           // 1
                           device Particle *inParticle [[ buffer(0) ]], // 2
                           unsigned int id [[ vertex_id ]]) {                 // 3
    
    
    VertexOut VertexOut;
    
    VertexOut.position = float4(inParticle[id].position, 1.0);
    VertexOut.pointsize = 5.0;
    
    return VertexOut;              // 4
}


fragment half4 particle_fragment() {
    return half4(1.0, 0.0, 1.0, 1.0);
}




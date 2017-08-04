//
//  ComputeShaders.metal
//  LokLokMetalCompute
//
//  Created by LOK on 4/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
//
//struct Mover{
//    float3 position;
//    float3 velocity;
//    float3 acceleration;
//    float mass;
//

//};


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
                                   const device Particle &mouse [[ buffer(3) ]],
                                   constant float &particleBrightness [[buffer(2)]],
                                   uint id [[thread_position_in_grid]])
{
    Particle thisParticle = inParticle[id];
    
    //outParticle[id].position = thisParticle.position + thisParticle.velocity;
    
    //calc force
    float mass = thisParticle.mass;
    float3 force = thisParticle.position - mouse.position;
    float distance = length(force);
    float d = constrain(distance, 10.0, 50.0);
    force = normalize(force);
    float strength = 1.0 * mass * mass / (d * d);
    force = force * strength;
    
    // apply force
    float3 f = force / thisParticle.mass;
    thisParticle.acceleration = thisParticle.acceleration + f;
    
    // update position
    thisParticle.velocity = thisParticle.velocity + thisParticle.acceleration;
    thisParticle.position = thisParticle.position + thisParticle.velocity;
    thisParticle.acceleration = thisParticle.acceleration * 0.0;
    
    //mass
    outParticle[id].position = thisParticle.position;
    outParticle[id].velocity = thisParticle.velocity;
    outParticle[id].acceleration = thisParticle.acceleration;
    outParticle[id].mass = thisParticle.mass;

}





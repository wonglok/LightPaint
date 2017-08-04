//
//  Compute.swift
//  LokLokMetalCompute
//
//  Created by LOK on 4/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation
import Metal
import simd
import MetalKit

class LokCompute {
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var defaultLibrary: MTLLibrary!
    var computePipelineState: MTLComputePipelineState!
    
    var particleBrightnessBuffer: MTLBuffer!
    
    var mouseVectorBuffer: MTLBuffer!
    var inVectorBuffer: MTLBuffer!
    var outVectorBuffer: MTLBuffer!
    
    var textureA: MTLTexture!
    
    var particles: [Particle]!

    var i:Int = 0
    
    var count: Int!
    var bufferSize: Int!
    
    init () {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        defaultLibrary = device.makeDefaultLibrary()
        
        let particleRendererShader = defaultLibrary.makeFunction(name: "particleRendererShader")

        do {
            try computePipelineState = device.makeComputePipelineState(function: particleRendererShader!)
        } catch {
            print(error)
        }
        
    }
    
    func setup () {
        setupData()
        setupTexture()
    }
    
    func setupData () {
        // Set some parameters
        var particleBrightness: Float = 0.8
        particleBrightnessBuffer = device.makeBuffer(bytes: &particleBrightness, length: MemoryLayout.size(ofValue: particleBrightness), options: [])
        
        var mouseParticle = Particle()
        mouseParticle.pX = 0.5
        mouseParticle.pY = 0.5

        mouseVectorBuffer = device.makeBuffer(bytes: &mouseParticle, length: MemoryLayout.size(ofValue: mouseParticle), options: [])
        
        count = 1
        
        particles = [Particle]()
        
        for _ in 0...(count-1) {
            var eachParticle = Particle()
            particles.append(eachParticle)
        }
        
        bufferSize = particles.count * MemoryLayout.size(ofValue: particles[0])
        
        inVectorBuffer = device.makeBuffer(bytes: particles, length: bufferSize, options: [])
        
        var particlesOut = [Particle]()
        
        for _ in 0...(count-1) {
            particlesOut.append(Particle())
        }
        bufferSize = particlesOut.count * MemoryLayout.size(ofValue: particlesOut[0])
        
        outVectorBuffer = device.makeBuffer(bytes: particlesOut, length: bufferSize, options: [])
    }
    
    func setupTexture () {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 512, height: 512, mipmapped: false)
        textureA = device.makeTexture(descriptor: textureDescriptor)
    }
    
    func getInVertex () -> MTLBuffer{
        if (i % 2 == 0) {
            return inVectorBuffer
        } else {
            return outVectorBuffer
        }
    }
    func getOutVertex () -> MTLBuffer {
        if (i % 2 == 0) {
            return outVectorBuffer
        } else {
            return inVectorBuffer
        }
    }
    
    func run () {
        
        let nowInBuff = getInVertex()
        let nowOutBuff = getOutVertex()
        
        i = i + 1
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeCommandEncoder.setComputePipelineState(computePipelineState!)
                
                computeCommandEncoder.setTexture(textureA, index: 0)
                
                computeCommandEncoder.setBuffer(nowInBuff, offset: 0, index: 0)
                computeCommandEncoder.setBuffer(nowOutBuff, offset: 0, index: 1)
                computeCommandEncoder.setBuffer(particleBrightnessBuffer, offset: 0, index: 2)
                computeCommandEncoder.setBuffer(mouseVectorBuffer, offset: 0, index: 3)
                
                
                // A one dimensional thread group Swift to pass Metal a one dimensional array
                let threadGroupCount = MTLSize(width:32, height:1, depth:1)
                let threadGroups = MTLSize(width:(1024 + 31) / 32, height:1, depth:1)

                computeCommandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)

                computeCommandEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()

                let result = nowOutBuff.contents().bindMemory(to: Particle.self, capacity: count)
                var data = [Particle]()
                for i in 0...count-1{
                    data.append(result[i])
                }
                print(data)

            }
        }

    }
   
    
}

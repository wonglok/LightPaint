//
//  basic.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation
import Metal
import MetalKit


class ParticlePipeline {
    var renderPipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    
    var gpuSync = SyncGPU(numOfBuffer: 2)
    
    init (device: MTLDevice) {
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "particle_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "particle_vertex")
        
        // 2
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 3
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        // 4
        let particleRendererShader = defaultLibrary.makeFunction(name: "particleRendererShader")
        computePipelineState = try! device.makeComputePipelineState(function: particleRendererShader!)
        
        setupData(device: device)
    }
    
    var bufferSize: Int!
    var count: Int!
    var mouseVectorBuffer: MTLBuffer!
    var inVectorBuffer: MTLBuffer!
    var outVectorBuffer: MTLBuffer!
    
    func setupData (device: MTLDevice) {
        var mouseParticle = Particle()
        mouseParticle.pX = 0
        mouseParticle.pY = 0
        mouseParticle.pZ = 0
        mouseParticle.mass = 1.5
        
        mouseVectorBuffer = device.makeBuffer(bytes: &mouseParticle, length: MemoryLayout.size(ofValue: mouseParticle), options: [])
        
        count = 1024
        
        var particles = [Particle]()
        
        for _ in 0...(count-1) {
            var eachParticle = Particle()
            eachParticle.pX = Float(arc4random_uniform(10) / 10) - 0.5
            eachParticle.pY = Float(arc4random_uniform(10) / 10) - 0.5
            eachParticle.pZ = Float(arc4random_uniform(10) / 10) - 0.5
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
    
    var _io_buffer_: Int = 0
    
    func getInVertex () -> MTLBuffer{
        if (_io_buffer_ % 2 == 0) {
            return inVectorBuffer
        } else {
            return outVectorBuffer
        }
    }
    func getOutVertex () -> MTLBuffer {
        if (_io_buffer_ % 2 == 0) {
            return outVectorBuffer
        } else {
            return inVectorBuffer
        }
    }
    func tickBuffer (){
        _io_buffer_ += 1
    }
    
    func render (commandQueue: MTLCommandQueue, drawable: CAMetalDrawable) {
        
        gpuSync.waitForResource()
        
        let nowInBuff = getInVertex()
        let nowOutBuff = getOutVertex()

        tickBuffer()
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                computeEncoder.setComputePipelineState(computePipelineState!)
                computeEncoder.setBuffer(nowInBuff, offset: 0, index: 0)
                computeEncoder.setBuffer(nowOutBuff, offset: 0, index: 1)
                computeEncoder.setBuffer(mouseVectorBuffer, offset: 0, index: 2)
            
                let threadGroupCount = MTLSize(width:32, height:1, depth:1)
                let threadGroups = MTLSize(width:(count + 31) / 32, height:1, depth:1)
                
                computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                
                computeEncoder.endEncoding()
                
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                
                
                let result = nowOutBuff.contents().bindMemory(to: Particle.self, capacity: count)
                var data = [Particle]()
                for i in 0...count-1{
                    data.append(result[i])
                }
//                print(datap[0])
            }
        }
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(renderPipelineState)
                
                renderEncoder.setVertexBuffer(nowOutBuff, offset: 0, index: 0)
                
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count)
                
//                renderEncoder.drawPrimitives(
//                    type: .point,
//                    vertexStart: 0,
//                    vertexCount: count,
//                    instanceCount: count
//                )
                
                renderEncoder.endEncoding()
                commandBuffer.present(drawable)
                commandBuffer.addCompletedHandler({ (_) in
                    self.gpuSync.freeResource()
                })
                commandBuffer.commit()
                
                
            }
            
            
        }
    }
}


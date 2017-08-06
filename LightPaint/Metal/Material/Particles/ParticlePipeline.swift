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
    
    var bufferProvider: BufferProvider!
    
    var syncGPU = SyncGPU(numOfBuffer: 2)
    
    init (device: MTLDevice, view: UIView) {
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
        
        // Buffers
        setupData(device: device)
        
        // Matrix
        bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3)
        setupMatrix(view: view)
    }
    
    var bufferSize: Int!
    var count: Int!
    var mouseParticle: Particle!
    var mouseVectorBuffer: MTLBuffer!
    var inVectorBuffer: MTLBuffer!
    var outVectorBuffer: MTLBuffer!
    
    var particles = [Particle]()
    
    func updateMouse (x: Float, y: Float) {
        if (x == mouseParticle.pX && y == mouseParticle.pY * -1 ) {
            return
        }
        mouseParticle.pX = x
        mouseParticle.pY = -1 * y
        
        let pointer = mouseVectorBuffer.contents()
        let size = MemoryLayout.size(ofValue: mouseVectorBuffer)
        memcpy(pointer, &mouseParticle, size)
    }
    
    func setEachParticle (_ eP: Particle) -> Particle{
        var eachParticle = eP
        eachParticle.pX = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
        eachParticle.pY = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
        eachParticle.pZ = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
    
        eachParticle.sX = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
        eachParticle.sY = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
        eachParticle.sZ = (Float(arc4random_uniform(100000000)) / Float(100000000)) * 2.0 - 1.0
        return eachParticle
    }
    
    func setupData (device: MTLDevice) {
        mouseParticle = Particle()
        mouseParticle.pX = 0
        mouseParticle.pY = 0
        mouseParticle.pZ = 0
        mouseParticle.mass = 2.5
        
        mouseVectorBuffer = device.makeBuffer(bytes: &mouseParticle, length: MemoryLayout.size(ofValue: mouseParticle), options: [])
        
        count = 1024 * 32
        
        for _ in 0...(count-1) {
            var eachParticle = Particle()
            eachParticle = setEachParticle(eachParticle)
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
    
    func setupMatrix (view: UIView) {
        
        makeWorldMatrix()
        makeProjectMatrix(view: view)
    }
    
    var worldModelMatrix: float4x4!
    func makeWorldMatrix () {
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: -2.0)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 25), y: 0.0, z: 0.0)
    }
    
    var projectionMatrix: float4x4!
    func makeProjectMatrix (view: UIView) {
        projectionMatrix = float4x4.makePerspectiveViewAngle(
            float4x4.degrees(toRad: 85.0),
            aspectRatio: Float(view.bounds.size.width / view.bounds.size.height),
            nearZ: 0.01,
            farZ: 100.0
        )
    }
    
    func resize (view: UIView) {
        makeProjectMatrix(view: view)
    }
    
    func render (commandQueue: MTLCommandQueue, drawable: CAMetalDrawable) {
        
        syncGPU.waitForResource()
        
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
                
//                let result = nowOutBuff.contents().bindMemory(to: Particle.self, capacity: count)
//                var data = [Particle]()
//                for i in 0...count-1{
//                    data.append(result[i])
//                }
//                print(datap[0])
            }
        }
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(renderPipelineState)
                
                var modelViewMatrix = matrix_identity_float4x4
                modelViewMatrix.multiplyLeft(worldModelMatrix)
                
                let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix, modelViewMatrix: modelViewMatrix)
                
                renderEncoder.setVertexBuffer(nowOutBuff, offset: 0, index: 0)
                renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
                
                renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: count)

                renderEncoder.endEncoding()
                commandBuffer.present(drawable)
                commandBuffer.addCompletedHandler({ (_) in
                    self.syncGPU.freeResource()
                })
                commandBuffer.commit()
                
                
            }
            
            
        }
    }
}


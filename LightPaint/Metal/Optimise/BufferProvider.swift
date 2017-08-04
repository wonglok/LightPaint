//
//  BufferProvider.swift
//  LokLokMetal
//
//  Created by LOK on 2/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//
import simd
import Foundation
import Metal

class BufferProvider {
    var avaliableResourcesSemaphore: DispatchSemaphore
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    
    let matrixMemorySize = MemoryLayout<Float>.size * 16
    
    init(device:MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        
        for _ in 0...inflightBuffersCount-1 {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
            uniformsBuffers.append(uniformsBuffer!)
        }
        
        avaliableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)
    }
    
    deinit{
        for _ in 0...self.inflightBuffersCount{
            self.avaliableResourcesSemaphore.signal()
        }
    }

    func configTryWait () {
        _ = avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    func configResourceRestore (commandBuffer: MTLCommandBuffer) {
        commandBuffer.addCompletedHandler { (_) in
            self.avaliableResourcesSemaphore.signal()
        }
    }
    
    func nextUniformsBuffer(projectionMatrix: float4x4, modelViewMatrix: float4x4) -> MTLBuffer {
        
        var projectionMatrix = projectionMatrix
        var modelViewMatrix = modelViewMatrix
        
        // 1
        let buffer = uniformsBuffers[avaliableBufferIndex]
        
        // 2
        let bufferPointer = buffer.contents()
        
        // 3
        memcpy(bufferPointer,                                &modelViewMatrix,  matrixMemorySize)
        memcpy(bufferPointer.advanced(by: matrixMemorySize * 1), &projectionMatrix, matrixMemorySize)
        
        // 4
        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount{
            avaliableBufferIndex = 0
        }
        
        return buffer
    }
    
}


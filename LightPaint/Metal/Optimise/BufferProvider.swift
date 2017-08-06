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
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    
    let matrixMemorySize = MemoryLayout<Float>.size * 16
    
    init(device:MTLDevice, inflightBuffersCount: Int) {
        
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2
        
        for _ in 0...inflightBuffersCount-1 {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
            uniformsBuffers.append(uniformsBuffer!)
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
        memcpy(bufferPointer,                                    &modelViewMatrix,  matrixMemorySize)
        memcpy(bufferPointer.advanced(by: matrixMemorySize * 1), &projectionMatrix, matrixMemorySize)
        
        // 4
        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount{
            avaliableBufferIndex = 0
        }
        
        return buffer
    }
    
}


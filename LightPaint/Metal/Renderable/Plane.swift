//
//  Plane.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class Plane: Renderable{
    var vertexBuffer: MTLBuffer!
    var verticesArray: Array<Vertex>!
    var vertexCount: Int!
    
    override init () {
        let A = Vertex(x: -1.0 * 0.5, y:   1.0 * 0.5, z:  0.0, w: 1.0)
        let B = Vertex(x: -1.0 * 0.5, y:  -1.0 * 0.5, z:  0.0, w: 1.0)
        let C = Vertex(x:  1.0 * 0.5, y:  -1.0 * 0.5, z:  0.0, w: 1.0)
        let D = Vertex(x:  1.0 * 0.5, y:   1.0 * 0.5, z:  0.0, w: 1.0)
        
        verticesArray = [
            A,B,C ,A,C,D   //Front
        ]
        
        super.init()
    }
    
    func makeBuffer (device: MTLDevice) {
        var vertexData = [Float]()
        for vertex in verticesArray{
            vertexData += vertex.floatBuffer()
        }
        vertexCount = verticesArray.count
        // 2
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        try! vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    }
    func render (commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setRenderPipelineState(pipelineState)
                
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(
                    type: .triangle,
                    vertexStart: 0,
                    vertexCount: vertexCount,
                    instanceCount: vertexCount / 3
                )
                
                renderEncoder.endEncoding()
                
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
        }
    }
}

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

class Plane{
    var vertexBuffer: MTLBuffer!
    var verticesArray: Array<Vertex>!
    var vertexCount: Int!
    
    init (device: MTLDevice) {
        let A = Vertex(x: -1.0 * 0.5, y:   1.0 * 0.5, z:  0.0, w: 1.0)
        let B = Vertex(x: -1.0 * 0.5, y:  -1.0 * 0.5, z:  0.0, w: 1.0)
        let C = Vertex(x:  1.0 * 0.5, y:  -1.0 * 0.5, z:  0.0, w: 1.0)
        let D = Vertex(x:  1.0 * 0.5, y:   1.0 * 0.5, z:  0.0, w: 1.0)
        
        verticesArray = [
            A,B,C ,A,C,D   //Front
        ]
        
        self.makeBuffer(device: device)
    }
    
    func makeBuffer (device: MTLDevice) {
        var vertexData = [Float]()
        for vertex in verticesArray{
            vertexData += vertex.floatBuffer()
        }
        vertexCount = verticesArray.count
        // 2
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    }
}


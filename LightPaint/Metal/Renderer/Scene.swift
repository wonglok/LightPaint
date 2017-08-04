//
//  Scene.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation
import MetalKit

class Scene {
    func render (renderer: Renderer, drawable: CAMetalDrawable) {
    }
}

class BasicLightPaint: Scene {
    var basicPipeline: BasicPipeline!
    var plane: Plane!
    
    init (device: MTLDevice) {
        plane = Plane(device: device)
        basicPipeline = BasicPipeline(device: device)
    }
    
    override func render (renderer: Renderer, drawable: CAMetalDrawable) {
       basicPipeline.render(commandQueue: renderer.commandQueue, drawable: drawable, vertexBuffer: plane.vertexBuffer, vertexCount: plane.vertexCount)
    }
}

class ParticleScene: Scene {
    var pipeline: ParticlePipeline!
    
    init (device: MTLDevice) {
        pipeline = ParticlePipeline(device: device)
    }
    
    override func render (renderer: Renderer, drawable: CAMetalDrawable) {
        pipeline.render(commandQueue: renderer.commandQueue, drawable: drawable)
    }
}


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
    var basicMaterial: BasicMaterial!
    var plane: Plane!
    
    init (device: MTLDevice) {
        plane = Plane()
        plane.makeBuffer(device: device)
        basicMaterial = BasicMaterial(device: device)
    }
    
    override func render (renderer: Renderer, drawable: CAMetalDrawable) {
        plane.render(commandQueue: renderer.commandQueue, pipelineState: basicMaterial.pipelineState, drawable: drawable)
    }
}


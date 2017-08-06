//
//  Renderer.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    // MARK: - Properties
    var device : MTLDevice!
    var view : UIView!
    var commandQueue: MTLCommandQueue!
    var scene: ParticleScene!
    var t1x: Float = 0.0
    var t1y: Float = 0.0

    init (device: MTLDevice, view: UIView) {
        self.device = device
        self.view = view
        self.commandQueue = device.makeCommandQueue()
        
        scene = ParticleScene(device: device, view: view)
    }
    
    // MARK: - Delegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.autoResizeDrawable = true
        scene.resize(view: view)
    }
    func draw(in view: MTKView) {
        guard   let drawable = view.currentDrawable,
                let scene = self.scene
            else { return }
        
        scene.render(renderer: self, drawable: drawable)
    }
}

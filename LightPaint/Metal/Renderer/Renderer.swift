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
    var scene: Scene!

    init (device: MTLDevice, view: UIView) {
        self.device = device
        self.view = view
        self.commandQueue = device.makeCommandQueue()
        
        scene = BasicLightPaint(device: device)
    }
    
    // MARK: - Delegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.autoResizeDrawable = true
    }
    func draw(in view: MTKView) {
        guard   let drawable = view.currentDrawable,
                let scene = self.scene
            else { return }
        
        scene.render(renderer: self, drawable: drawable)
    }
}

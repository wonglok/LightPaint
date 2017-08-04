//
//  ViewController.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var renderer : Renderer!
    
    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        guard let device = mtkView.device else {
            fatalError("Device not created. Run on a physical device")
        }
        
        renderer = Renderer(device: device, view: view)
        mtkView.delegate = renderer
        mtkView.preferredFramesPerSecond = 120
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


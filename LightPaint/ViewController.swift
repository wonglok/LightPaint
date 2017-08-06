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
        setupGestures()
    }
    
    let panSensivity:Float = 5
    var lastPanLocation: CGPoint!
    
    func setupGestures(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tap))
        tap.numberOfTapsRequired = 2;
        self.view.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.pan))
        self.view.addGestureRecognizer(pan)
    }
    @objc func tap(tapGesture: UITapGestureRecognizer) {
        if (tapGesture.state == UIGestureRecognizerState.recognized) {
            renderer.scene.pipeline.uiTouchState.isTouching = true
        } else if (tapGesture.state == UIGestureRecognizerState.ended) {
            renderer.scene.pipeline.uiTouchState.isTouching = false
        }
    }
    
    @objc func pan(panGesture: UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizerState.changed {
            
            let pointInView = panGesture.location(in: self.view)
            // 3

//            let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
//            let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
//            renderer.scene.pipeline.uiTouchState.rY += xDelta
//            renderer.scene.pipeline.uiTouchState.rX += -yDelta
            
            let cX = Float(pointInView.x / self.view.bounds.width) * 2.0 - 1.0
            let cY = Float(pointInView.y / self.view.bounds.height) * 2.0 - 1.0
            
            renderer?.t1x = cX
            renderer?.t1y = cY
            
            renderer.scene.pipeline.uiTouchState.isTouching = true
            
            lastPanLocation = pointInView
        } else if panGesture.state == UIGestureRecognizerState.began {
            lastPanLocation = panGesture.location(in: self.view)
            renderer.scene.pipeline.uiTouchState.isTouching = true
        } else if panGesture.state == UIGestureRecognizerState.ended {
            renderer.scene.pipeline.uiTouchState.isTouching = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


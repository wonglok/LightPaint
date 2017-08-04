//
//  SyncGPU.swift
//  LightPaint
//
//  Created by LOK on 5/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Metal
import MetalKit
import Foundation

class SyncGPU {
    var avaliableResourcesSemaphore: DispatchSemaphore
    var numOfBuffer: Int = 5

    init (numOfBuffer: Int) {
        self.numOfBuffer = numOfBuffer
        avaliableResourcesSemaphore = DispatchSemaphore(value: numOfBuffer)
    }

    deinit{
        for _ in 0...self.numOfBuffer{
            self.avaliableResourcesSemaphore.signal()
        }
    }

    func waitForResource () {
        _ = avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func freeResource () {
        self.avaliableResourcesSemaphore.signal()
    }
    
}

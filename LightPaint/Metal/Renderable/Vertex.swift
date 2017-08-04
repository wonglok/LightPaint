//
//  Vertex.swift
//  LightPaint
//
//  Created by LOK on 3/8/2017.
//  Copyright © 2017 WONG LOK. All rights reserved.
//

import Foundation

struct Vertex{
    var x,y,z,w: Float     // position data

    func floatBuffer() -> [Float] {
        return [
            x,y,z,w
        ]
    }
};


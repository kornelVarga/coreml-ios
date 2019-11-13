//
//  Prediction.swift
//  CoreMLDemo
//
//  Created by Kornel Varga on 2019. 11. 13..
//  Copyright © 2019. Kornel Varga. All rights reserved.
//

import Foundation

class Prediction {
    
    let label: String
    let probability: Double
    
    init(label: String, probability: Double) {
        self.label = label
        self.probability = probability
    }
}

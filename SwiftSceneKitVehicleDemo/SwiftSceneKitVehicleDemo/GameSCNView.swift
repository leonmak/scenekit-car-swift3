//
//  GameSCNView.swift
//  SwiftSceneKitVehicleDemo
//
//  Created by Matteo Cocon on 18/01/15.
//  Copyright (c) 2015 Matteo Cocon. All rights reserved.
//

import SceneKit

class GameSCNView: SCNView {
  
  var touchCount: Int = 0
  var inCarView: Bool = false
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let _ = touches.first else { return }
    touchCount += touches.count
  }
  
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchCount = 0
  }
}

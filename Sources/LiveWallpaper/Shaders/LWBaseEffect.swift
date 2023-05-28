//
//  LWBaseEffect.swift
//  LiveWallpaper
//
//  Created by Dayo Banjo on 5/4/23.
//

import Foundation

public class LWBaseEffect {
  
  let vertexFunctionName: String
  let fragmentFunctionName: String
  var kernelFunctionName: String?
  
  init(vertexFunctionName: String, fragmentFunctionName: String, kernelFunctionName: String? = nil) {
    self.vertexFunctionName = vertexFunctionName
    self.fragmentFunctionName = fragmentFunctionName
    self.kernelFunctionName = kernelFunctionName
  }
  
  func modifyParams(for keyValue: [String: Any]) {
    
  }
}

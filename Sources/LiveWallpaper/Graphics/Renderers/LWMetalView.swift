//
//  LWMetalView.swift
//  LiveWallpaper
//
//  Created by Dayo Banjo on 5/5/23.
//
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import MetalKit
import Metal

class LWMetalView: MTKView {
  
  #if os(iOS)
  typealias TouchType = UITouch
  #elseif os(macOS)
  typealias TouchType = NSTouch
  #endif
  
  var touchHandler: ((TouchType) -> Void)?  
  
 #if os(iOS)
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    touchHandler?(touch)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    touchHandler?(touch)
  }
  
 #elseif os(macOS)
  override func touchesBegan(with event: NSEvent) {
    guard let touch = event.touches(matching: .began, in: self).first else { return }
    touchHandler?(touch)
  }
  
  override func touchesMoved(with event: NSEvent) {
    guard let touch = event.touches(matching: .moved, in: self).first else { return }
    touchHandler?(touch)
  }
#endif
}

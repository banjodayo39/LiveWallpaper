//
//  Examples.swift
//  LiveWallpaper
//
//  Created by Dayo Banjo on 4/18/23.
//

import Foundation
import simd
import MetalKit

public protocol LiveWallpaperDelegate: AnyObject {
  
  func liveWallpaper(_ liveWallpaper: LiveWallpaper, didProduceDrawable drawable: CAMetalDrawable)
  
  func liveWallpaper(_ liveWallpaper: LiveWallpaper, willRenderNewFrameWithDrawable drawable: CAMetalDrawable)
  
  func liveWallpaper(_ liveWallpaper: LiveWallpaper, didChangeViewportSizeToSize size: CGSize)
}

@objc public protocol LiveWallpaperStateDelegate: AnyObject {
  @objc func liveWallpaper(didChangeState state: LiveWallpaperState)
}

@objc public enum LiveWallpaperState: Int {
  case initial
  case playing
  case pause
}

public final class LiveWallpaper {
    
  private let renderer: LWRenderer
  private var videoTexture: LWTexture?
  private var videoTextureSource: LWVideoTextureSource?
  
  weak var delegate: LiveWallpaperDelegate?
  
  // TO do makje it also set and can mofi
  let effect: LWBaseEffect
  
  let bunnyEffect = LWBaseEffect(vertexFunctionName: "basic_vertex",
                                 fragmentFunctionName: "texture_fragment")
  
  init(renderer: LWRenderer, effect: LWBaseEffect?) {
    self.renderer = renderer
    guard let effect = effect else {
      self.effect = LWBaseEffect(vertexFunctionName: "basic_vertex",
                                 fragmentFunctionName: "vortex_fragment")
      return
    }
    self.effect = effect
  }

  func onRendererFrame() {
    // With a video texture, every frame we try to extract the new frame then apply
    // the new frame to the Texture instace
    guard let videoTextureSource = self.videoTextureSource else {
      return
    }

    guard let texture = videoTextureSource.createTexture(hostTime: nil) else {
      return
    }

    videoTexture?.mtlTexture = texture
  }
  
  func addNode(node: LWNode) {
    renderer.scene.root.addChild(node)
  }
  
  func clearAllNodes() {
    renderer.scene.root.clearAllChildren()
  }
  
  func setClear(clearColor: MTLClearColor) {
    renderer.scene.clearColor = clearColor
  }

  func createPointCloud() {
    renderer.scene.root.clearAllChildren()
  }
  
  func createPlane(textured: Bool = false) {
    
    guard let planeMesh = LWPrimitives.plane(renderer: renderer,
                                           width: 5,
                                           length: 10,
                                             color: MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1) as! CGColor)
    else {
      print("Failed to create the plane mesh")
      return
    }
    
    var texture: LWTexture?
    if textured {
      guard let metalTexture = LWTexture.loadMetalTexture(device: renderer.device, named: "flower") else {
        return
      }

      let samplerDescriptor = MTLSamplerDescriptor()
      samplerDescriptor.normalizedCoordinates = true
      samplerDescriptor.minFilter = .linear
      samplerDescriptor.magFilter = .linear
      samplerDescriptor.mipFilter = .linear
      guard let sampler = renderer.device.makeSamplerState(descriptor: samplerDescriptor) else {
        return
      }

      texture = LWTexture(mtlTexture: metalTexture, samplerState: sampler)
    }
    let material = LWMaterial.standardMaterial(renderer: renderer, effect: effect, mainTexture: texture)

    planeMesh.material = material
    let node = LWNode(mesh: planeMesh)
    node.orientation = Quaternion(
      angle: Math.toRadians(90.0),
      axis: [1, 0, 0]
    )
    renderer.scene.root.addChild(node)
  }
}

extension LiveWallpaper: LWRendererDelegate {
  
  func onFrameReady(for renderer: LWRenderer) {}
  
  func renderer(_ renderer: LWRenderer, didProduceDrawable drawable: CAMetalDrawable) {
    delegate?.liveWallpaper(self,didProduceDrawable: drawable)
  }
  
  func renderer(_ renderer: LWRenderer, willRenderNewFrameWith drawable: CAMetalDrawable) {
    delegate?.liveWallpaper(self, willRenderNewFrameWithDrawable: drawable)
  }
  
  func renderer(_ renderer: LWRenderer, didChangeViewportSizeTo size: CGSize) {
    delegate?.liveWallpaper(self, didChangeViewportSizeToSize: size)
  }
}

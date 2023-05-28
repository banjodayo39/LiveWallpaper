//
//  VideoTextureCache.swift
//  
//
//  Created by Mark Dawson on 3/28/20.
//
import CoreVideo
import Foundation

/// A cache used to interact with ARFrame video frames
public final class VideoTextureCache {
  private var capturedImageTextureCache: CVMetalTextureCache!

  public init?(device: MTLDevice) {
    var textureCache: CVMetalTextureCache?
    let result = CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
    if result != kCVReturnSuccess {
      return nil
    }
    capturedImageTextureCache = textureCache
  }
    
   private func createTexture(
     fromPixelBuffer pixelBuffer: CVPixelBuffer,
     pixelFormat: MTLPixelFormat,
     planeIndex: Int
   ) -> CVMetalTexture? {
     let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
     let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

     var texture: CVMetalTexture? = nil
     let status = CVMetalTextureCacheCreateTextureFromImage(
       nil,
       capturedImageTextureCache,
       pixelBuffer,
       nil,
       pixelFormat,
       width,
       height,
       planeIndex,
       &texture)

     if status != kCVReturnSuccess {
         return nil
     }

     return texture
   }

}

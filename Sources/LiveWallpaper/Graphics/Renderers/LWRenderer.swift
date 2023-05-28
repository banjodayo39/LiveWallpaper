
// https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/FunctionsandLibraries.html#//apple_ref/doc/uid/TP40016642-CH24-SW1


import MetalKit
import MetalPerformanceShaders

/**
 The render class is our entry point into a 3D scene. It is repsonsible for creating the MTLDevice and
 command queue and also creates a Scene object that will can use to populate with 3D object.

 The renderer also implements the MTKViewDelegate protocol and gets the per frame updates
 from MTKView for rendering.

 You will want to create the renderer instance first and hold on to it for the lifetime of your app.
 */

protocol LWRendererDelegate: AnyObject {
  func renderer(_ renderer: LWRenderer, didProduceDrawable drawable: CAMetalDrawable)
  func renderer(_ renderer: LWRenderer, willRenderNewFrameWith drawable: CAMetalDrawable)
  func renderer(_ renderer: LWRenderer, didChangeViewportSizeTo size: CGSize)
  func onFrameReady(for renderer: LWRenderer)
}

public final class LWRenderer: NSObject {
//https://github.com/gsurma/metal_camera/blob/master/MetalCamera-iOS/MetalCamera/Main/MetalView/MetalView.swift
  // Internally we are using two vertex buffer slots for uniform
  // and per model data in slots 0 and 1. This value lets callers
  // know what is the first buffer they can use safely
  //https://www.shadertoy.com/view/wlXcDS
  weak var delegate: LWRendererDelegate?
  public static let firstFreeVertexBufferIndex = 2
  
  var isPlaying: Bool = true {
    didSet {
      
    }
  }
  
  var touchPoint: Vec2 = Vec2(-2.0, -2.0)
  var timer: Float = 0
  var timerBuffer: MTLBuffer
  var time = TimeInterval(0.0)
  
  var speed: Float = 0.0
  var speedBuffer: MTLBuffer
  var intense: Float = 100.0
  var intenseBuffer: MTLBuffer
  
  private var computePipeline: MTLComputePipelineState!
  var inputTexture: MTLTexture!
  var outputTexture: MTLTexture!
  var sampleState: MTLSamplerState?

  public let device: MTLDevice
  public let library: MTLLibrary
  public let commandQueue: MTLCommandQueue
  public let scene = LWScene()
  public let fpsCounter = FPSCounter(sampleCount: 100)
 // public var onFrame: (() -> Void)?
  public var onViewportSizeChanged: ((CGSize) -> Void)?

  internal var enabledDepthStencilState: MTLDepthStencilState
  internal var disabledDepthStencilState: MTLDepthStencilState

  private var lastTime: TimeInterval?
  private let creationTime: TimeInterval
  private let mtkView: MTKView
  private let uniformBuffers: BufferManager
  
  private var threadgroupSize: MTLSize!
  private var threadgroupCount: MTLSize?

  public init(mtkView: MTKView) {

    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal is not supported")
    }
    self.device = device

    guard let library = device.makeDefaultLibrary() else {
      fatalError("Failed to make default library")
    }
    self.library = library

    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("Failed to make a command queue")
    }
    self.commandQueue = commandQueue

    self.mtkView = mtkView
    mtkView.device = device

    mtkView.colorPixelFormat = .bgra8Unorm_srgb
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.framebufferOnly = false

    uniformBuffers = BufferManager(device: device, inflightCount: 3, createBuffer: { (device) in
      return device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [])
    })
    uniformBuffers.createBuffers()

    let enabledDepthDescriptor = MTLDepthStencilDescriptor()
    enabledDepthDescriptor.isDepthWriteEnabled = true
    enabledDepthDescriptor.depthCompareFunction = .less
    enabledDepthStencilState = device.makeDepthStencilState(descriptor: enabledDepthDescriptor)!

    let disabledDepthDescriptor = MTLDepthStencilDescriptor()
    disabledDepthDescriptor.isDepthWriteEnabled = false
    disabledDepthDescriptor.depthCompareFunction = .less
    disabledDepthStencilState = device.makeDepthStencilState(descriptor: disabledDepthDescriptor)!

    creationTime = Date.timeIntervalSinceReferenceDate
    
    timerBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!
    speedBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!
    intenseBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!

    super.init()
    setUPComputePipeline()
    buildSamplerState()
  }

  func defaultPipelineDescriptor() -> MTLRenderPipelineDescriptor {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
    return descriptor
  }
  
  func setUPComputePipeline() {
    do {
      guard let kernelFunction = device.makeDefaultLibrary()?.makeFunction(name: "waterEffect") else  { return }
      computePipeline = try device.makeComputePipelineState(function: kernelFunction)
      threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
      
      inputTexture = TexturableLoader.setTexturable(device: device, name: "water")
      outputTexture = TexturableLoader.setTexturable(device: device, name: "flower")

    } catch {
      // Handle the error
     }
  }
  
  func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        sampleState = device.makeSamplerState(descriptor: descriptor)
    }
}

extension LWRenderer: MTKViewDelegate {

  /// This is called anytime the view size changes. If this happens we need to update
  /// the camera values accordingly
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    scene.camera.aspectRatio = Float(size.width / size.height)
    onViewportSizeChanged?(size)
    delegate?.renderer(self, didChangeViewportSizeTo: size)
  }

  /// Called every frame
  public func draw(in view: MTKView) {
    guard isPlaying else { return }
    //onFrame?()
    delegate?.onFrameReady(for: self)

    guard let descriptor = view.currentRenderPassDescriptor else {
      return
    }

    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      return
    }

    guard let drawable = view.currentDrawable else {
      return
    }

    delegate?.renderer(self, willRenderNewFrameWith: drawable)
    let attachment = descriptor.colorAttachments[0]
    attachment?.loadAction = .clear
    attachment?.clearColor = scene.clearColor
    
    view.drawableSize = UIScreen.main.bounds.size

    let now = Date.timeIntervalSinceReferenceDate
    if lastTime == nil {
      lastTime = now
    }

    let time = Time(
      totalTime: Date.timeIntervalSinceReferenceDate - creationTime,
      updateTime: now - lastTime!
    )
    lastTime = now

    // The uniform buffers store values that are constant across the entire frame
    let uniformBuffer = uniformBuffers.nextSync()
    let uniformContents = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
    uniformContents.pointee.time = Float(time.totalTime)

    uniformContents.pointee.touchPoint = touchPoint
    
    let viewMatrix = scene.camera.viewMatrix
    uniformContents.pointee.view = viewMatrix

    uniformContents.pointee.inverseView = viewMatrix.inverse
    uniformContents.pointee.viewProjection = scene.camera.projectionMatrix * viewMatrix
    uniformContents.pointee.resolution = [
      Int32(mtkView.frame.size.width * UIScreen.main.scale),
      Int32(mtkView.frame.size.height * UIScreen.main.scale)
    ]
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      return
    }
    encoder.setDepthStencilState(enabledDepthStencilState)
    encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 0)
    encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)

    fpsCounter.newFrame(time: time)
    scene.update(time: time)

    scene.render(
      time: time,
      renderer: self,
      encoder: encoder,
      uniformBuffer: uniformBuffer
    )
    encoder.endEncoding()

//    guard let encoderC = commandBuffer.makeComputeCommandEncoder() else { return }
//
//    encoderC.label = "name" + "Encoder"
//    encoderC.setComputePipelineState(computePipeline)
//    encoderC.setTexture(inputTexture, index: 1)
//    encoderC.setTexture(drawable.texture, index: 0)
//    var uniforms = uniformBuffer.contents()
//    encoderC.setBytes(&uniforms, length: uniformBuffer.length, index: 0)
//   
//                
//    encoderC.setBuffer(speedBuffer, offset: 0, index: 1)
//    encoderC.setBytes(&speed, length: MemoryLayout<Float>.size, index: 1)
//                
//    encoderC.setBuffer(intenseBuffer, offset: 0, index: 2)
//    encoderC.setBytes(&intense, length: MemoryLayout<Float>.size, index: 2)
//    encoderC.setBuffer(timerBuffer, offset: 0, index: 3)
//                
//                let timestep = 1.0 / TimeInterval(view.preferredFramesPerSecond)
//                updateWithTimestep(timestep)
//    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
//       let threadsPerGrid = MTLSize(width: (inputTexture.width + 15) / 16,
//                                    height: (inputTexture.height + 15) / 16,
//                                    depth: 1)
//    if let sampleState = sampleState {
//      encoderC.setSamplerState(sampleState, index: 0)
//    }
//    encoderC.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
//    encoderC.endEncoding()
    /**do  compute shadering here
     
     
     */

    commandBuffer.addCompletedHandler { [weak self] (MTLCommandBuffer) in
      guard let self else { return }
        
      delegate?.renderer(self, didProduceDrawable: drawable)
      uniformBuffers.release()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func updateWithTimestep(_ timestep: TimeInterval) {
         time = time + timestep
         timer = Float(time)
         let bufferPointer = timerBuffer.contents()
         memcpy(bufferPointer, &timer, MemoryLayout<Float>.size)
     }
}

class TexturableLoader {
    static func setTexturable(device: MTLDevice) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
      let descriptor = MTLTextureDescriptor()
      descriptor.pixelFormat = .rgba8Unorm
      descriptor.width = 256
      descriptor.height = 256
      descriptor.usage = [.shaderRead, .shaderWrite]
      var textureIn: MTLTexture?
      textureIn =  device.makeTexture(descriptor: descriptor)

        return textureIn
    }
  
  // Texture from UIImage
  static func setTexturable(device: MTLDevice, image: UIImage) -> MTLTexture? {
      let textureLoader = MTKTextureLoader(device: device)
      let cgImage = image.cgImage!
      do {
          return try textureLoader.newTexture(cgImage: cgImage, options: nil)
      } catch {
          print("Error creating texture from image: \(error.localizedDescription)")
          return nil
      }
  }
  
  //Texture from name
  static func setTexturable(device: MTLDevice, name: String) -> MTLTexture? {
      let textureLoader = MTKTextureLoader(device: device)
      do {
        return  try textureLoader.newTexture(name: name, scaleFactor: 1, bundle: nil)
      }
      catch let error {
          print("Error \(error) loading texture")
        return nil
      }
  }
}

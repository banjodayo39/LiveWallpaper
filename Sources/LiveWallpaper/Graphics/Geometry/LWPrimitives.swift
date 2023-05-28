import CoreGraphics
import MetalKit

public final class LWPrimitives {
  
  static func plane(
      renderer: LWRenderer,
      width: Float,
      length: Float,
      color: CGColor = UIColor.white.cgColor
  ) -> LWMesh? {
      let hw = width / 2.0
      let hl = length / 2.0

    let vertices = [        Vertex(position: [-hw, 0, hl], normal: [0, 0, 1], color: Vec4.from(color), texuture: [0, 1]),
        Vertex(position: [hw, 0, hl], normal: [0, 1, 0], color: Vec4.from(color), texuture: [1, 1]),
        Vertex(position: [hw, 0, -hl], normal: [0, 1, 0], color: Vec4.from(color), texuture: [1, 0]),
        Vertex(position: [-hw, 0, hl], normal: [0, 1, 0], color: Vec4.from(color), texuture: [0, 1]),
        Vertex(position: [hw, 0, -hl], normal: [0, 1, 0], color: Vec4.from(color), texuture: [1, 0]),
        Vertex(position: [-hw, 0, -hl], normal: [0, 1, 0], color: Vec4.from(color), texuture: [0, 0]),
    ]

    guard let buffer = Vertex.toBuffer(device: renderer.device, vertices: vertices) else {
      return nil
    }

    let vertexBuffer = LWMesh.VertexBuffer(
      buffer: buffer,
      bufferIndex: LWRenderer.firstFreeVertexBufferIndex,
      primitiveType: .triangle,
      vertexCount: vertices.count
    )

    return LWMesh(vertexBuffer: vertexBuffer)
  }
  
  /**
   Creates a cuboid object centered around 0,0,0 with dimensions width, height and length. Each face of the cube
   can have a color and also texture coordinates are set from 0,0 top left of each face to 1,1 bottom right.

   - Note: Normals are not currently set, they are just set to (0, 0, 0)
   */
  public static func cuboid(
    renderer: LWRenderer,
    width: Float,
    height: Float,
    length: Float,
    topColor: CGColor = UIColor.white.cgColor,
    rightColor: CGColor = UIColor.white.cgColor,
    bottomColor: CGColor = UIColor.white.cgColor,
    leftColor: CGColor = UIColor.white.cgColor,
    frontColor: CGColor = UIColor.white.cgColor,
    backColor: CGColor = UIColor.white.cgColor
  ) -> LWMesh? {
    let hw = width / 2.0
    let hh = height / 2.0
    let hl = length / 2.0

    // Because we can have a different color per face, we can't share vertices across
    // faces, so they must be duplicated
    let vertices = [
      // top
      Vertex(position: [-hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [0, 1]),
      Vertex(position: [hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [1, 1]),
      Vertex(position: [hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [1, 0]),
      Vertex(position: [-hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [0, 1]),
      Vertex(position: [hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [1, 0]),
      Vertex(position: [-hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(topColor), texuture: [0, 0]),

      // right
      Vertex(position: [hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [0, 1]),
      Vertex(position: [hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [1, 1]),
      Vertex(position: [hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [1, 0]),
      Vertex(position: [hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [0, 1]),
      Vertex(position: [hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [1, 0]),
      Vertex(position: [hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(rightColor), texuture: [0, 0]),

      // bottom
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [0, 0]),
      Vertex(position: [-hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [0, 1]),
      Vertex(position: [hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [1, 1]),
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [0, 0]),
      Vertex(position: [hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [1, 1]),
      Vertex(position: [hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(bottomColor), texuture: [1, 0]),

      // left
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [1, 1]),
      Vertex(position: [-hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [0, 1]),
      Vertex(position: [-hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [0, 0]),
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [1, 1]),
      Vertex(position: [-hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [0, 0]),
      Vertex(position: [-hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(leftColor), texuture: [1, 0]),

      // front
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [0, 1]),
      Vertex(position: [hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [1, 1]),
      Vertex(position: [hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [1, 0]),
      Vertex(position: [-hw, -hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [0, 1]),
      Vertex(position: [hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [1, 0]),
      Vertex(position: [-hw, hh, hl], normal: [0, 0, 0], color: Vec4.from(frontColor), texuture: [0, 0]),

      // back
      Vertex(position: [hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [0, 1]),
      Vertex(position: [-hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [1, 1]),
      Vertex(position: [-hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [1, 0]),
      Vertex(position: [hw, -hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [0, 1]),
      Vertex(position: [-hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [1, 0]),
      Vertex(position: [hw, hh, -hl], normal: [0, 0, 0], color: Vec4.from(backColor), texuture: [0, 0]),
    ]

    guard let buffer = Vertex.toBuffer(device: renderer.device, vertices: vertices) else {
      return nil
    }

    let vertexBuffer = LWMesh.VertexBuffer(
      buffer: buffer,
      bufferIndex: LWRenderer.firstFreeVertexBufferIndex,
      primitiveType: .triangle,
      vertexCount: vertices.count
    )

    return LWMesh(vertexBuffer: vertexBuffer)
  }

  // TODO: return a node
  static func sphere(device: MTLDevice, radius: Float) -> MDLMesh {
    let allocator = MTKMeshBufferAllocator(device: device)
    let mesh = MDLMesh.newEllipsoid(
      withRadii: [radius, radius, radius],
      radialSegments: 8,
      verticalSegments: 8,
      geometryType: .triangles,
      inwardNormals: false,
      hemisphere: false,
      allocator: allocator
    )

    // TODO: How would someone define these vertices
    return mesh
  }
  
}

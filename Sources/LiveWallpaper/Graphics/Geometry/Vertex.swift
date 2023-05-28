import Metal

/**
 BasicVertex represents a common set of values that you might want to associate with a vertex.

 This one supports position, color, normal and texture coordinates.
 */
//Suggested name is LVGeometry pos
public struct Vertex {

  // Empty vertex, useful when initiaizing arrays with a fixed size
  public static let zero = Vertex(position: [0, 0, 0],
                                       normal: [0, 0, 0],
                                       color: [0, 0, 0, 0],
                                       texuture: [0, 0])

  // Vertex Position
  public var x, y, z : Float

  /// Helper wrapper around the x, y, z values
  public var position: Vec3 {
     get { return Vec3(x, y, z) }
     set {
       x = newValue.x;
       y = newValue.y;
       z = newValue.z
     }
   }

  // normal
  public var nx, ny, nz: Float

  /// Helper wrapper around the nx, ny, nz values
  public var normal: Vec3 {
    get { return Vec3(nx, ny, nz) }
    set {
      nx = newValue.x
      ny = newValue.y
      nz = newValue.z
    }
  }

  // color
  public var r, g, b, a: Float

  // texCoords
  public var u, v: Float

  public init(position: Vec3, normal: Vec3, color: Vec4, texuture: Vec2) {
    x = position.x
    y = position.y
    z = position.z
    nx = normal.x
    ny = normal.y
    nz = normal.z
    r = color.x
    g = color.y
    b = color.z
    a = color.w
    u = texuture.x
    v = texuture.y
  }

  public func floatBuffer() -> [Float] {
    return [x, y, z, nx, ny, nz, r, g, b, a, u, v]
  }

  /// Given an array of vertices, returns an MTLBuffer containing the vertex data
  public static func toBuffer(device: MTLDevice, vertices: [Vertex]) -> MTLBuffer? {
    var data = [Float]()
    vertices.forEach { (vertex) in
      data.append(contentsOf: vertex.floatBuffer())
    }

    let size = MemoryLayout<Vertex>.stride * vertices.count
    return device.makeBuffer(bytes: data, length: size, options: [])
  }
}

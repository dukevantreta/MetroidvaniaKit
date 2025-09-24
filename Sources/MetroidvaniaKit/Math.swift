
public func lerp(from a: Double, to b: Double, by t: Double) -> Double {
    (1.0 - t) * a + t * b
}


// public func lerp(from a: Double, to b: Double, by t: Double) -> Double {
//     (1.0 - t) * a + t * b
// }

public func lerp<T>(from a: T, to b: T, by t: T) -> T where T: Numeric & BinaryFloatingPoint {
    (1.0 - t) * a + t * b
}

public func clamp<T>(_ value: T, min: T, max: T) -> T where T: Numeric & BinaryInteger {
    return value < min ? min : value > max ? max : value
}

public func anticlamp<T>(_ value: T, min: T, max: T) -> T where T: Numeric & BinaryInteger {
    if value > min && value < max {
        let mid = (max - min / 2) + min
        return value < mid ? min : max
    }
    return value
}

public func anticlamp<T>(_ value: T, min: T, max: T) -> T where T: Numeric & BinaryFloatingPoint {
    if value > min && value < max {
        let mid = (max - min / 2) + min
        return value < mid ? min : max
    }
    return value
}
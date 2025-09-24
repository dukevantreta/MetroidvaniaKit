import SwiftGodot

/**
 Log to Godot console directly from a node by calling `log()`
 */

protocol TypeDescribable {
    static var typeDescription: String { get }
    var typeDescription: String { get }
}

extension TypeDescribable {
    static var typeDescription: String {
        return String(describing: self)
    }
    
    var typeDescription: String {
        return type(of: self).typeDescription
    }
}

protocol GodotLogger: TypeDescribable {
    func log(_ message: String)
    func logError(_ message: String)
}

extension GodotLogger {
    func log(_ message: String) {
        GD.print("[\(typeDescription)] \(message)")
    }
    func logError(_ message: String) {
        GD.pushError("[\(typeDescription)] \(message)")
    }
}

extension Node: GodotLogger {}
extension Resource: GodotLogger {}

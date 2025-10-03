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
    func logWarning(_ message: String)
    func logError(_ message: String)
}

extension GodotLogger {
    func log(_ message: String) {
        GD.print("[\(typeDescription)] \(message)")
    }
    func logWarning(_ message: String) {
        GD.pushWarning("[\(typeDescription)] \(message)")
    }
    func logError(_ message: String) {
        GD.pushError("[\(typeDescription)] \(message)")
    }
}

protocol VerboseLogger {
    var verbose: Bool { get set }
    func logVerbose(_ message: String, level: Int)
}

extension VerboseLogger where Self: RefCounted {
    func logVerbose(_ message: String, level: Int = 0) {
        if verbose { 
            var padding = ""
            for _ in (0..<level) { padding += "    " }
            log(padding + message) 
        }
    }
}

extension Object: GodotLogger {}
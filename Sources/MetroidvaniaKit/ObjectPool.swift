import SwiftGodot

/**
Objects created from within the pool or acquired via `acquire()` are bound to the pool. 
Only objects bound to a given pool can be returned to it.

This implementation trades-off memory for constant time membership check and retrieval.
*/
final class ObjectPool<T: Node2D> {

    private let objectInit: () -> T

    private var all: Set<T> = []
    private var free: Set<T> = []

    deinit {
        all.forEach { $0.queueFree() }
    }

    init(objectInit: @escaping () -> T = T.init) {
        self.objectInit = objectInit
    }

    /// Creates `n` instances and adds them to the pool. Must only be called when the pool is empty.
    func preload(_ n: Int) {
        assert(all.isEmpty)
        all = Set(minimumCapacity: n)
        free = Set(minimumCapacity: n)
        for _ in 1...n {
            let object = objectInit()
            all.insert(object)
            free.insert(object)
        }
    }

    /// Takes an object from the pool. If the pool is empty, creates a new object.
    func acquire() -> T {
        if let object = free.popFirst() {
            return object
        }
        let new = objectInit()
        all.insert(new)
        return new
    }

    /// Puts an object back to the pool. The object must be bound to the pool.
    func release(_ object: T) {
        assert(object.getParent() == nil)
        assert(all.contains(object))
        free.insert(object)
    }

    /// Erases all objects bound to the pool, both inactive and active, and calls `queueFree()` on all of them.
    func flush() {
        all.forEach { $0.queueFree() }
        all.removeAll(keepingCapacity: true)
        free.removeAll(keepingCapacity: true)
    }
}
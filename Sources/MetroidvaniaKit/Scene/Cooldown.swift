final class Cooldown {

    var duration: Double

    private(set) var timeLeft: Double = 0.0

    var isReady: Bool {
        timeLeft <= 0.0
    }

    init(time: Double = 0.0) {
        duration = time
    }

    func reset() {
        timeLeft = 0.0
    }

    func update(_ dt: Double) {
        timeLeft = max(timeLeft - dt, 0.0)
    }

    @discardableResult
    func use() -> Bool {
        guard isReady else { return false }
        timeLeft = duration
        return true
    }
}
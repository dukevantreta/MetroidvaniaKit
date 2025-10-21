final class Cooldown {

    var time: Double = 0.0

    private(set) var timeLeft: Double = 0.0

    var isReady: Bool {
        timeLeft <= 0.0
    }

    init(time: Double) {
        self.time = time
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
        timeLeft = time
        return true
    }
}
public final class GameTimer {

    var onTimeout: (() -> Void)?

    var duration: Double

    var isRepeating: Bool

    private(set) var isStopped = true

    private(set) var timeLeft: Double = 0.0

    var timeElapsed: Double {
        duration - timeLeft
    }

    init(time: Double = 1.0, repeats: Bool = false) {
        self.duration = time
        self.isRepeating = repeats
    }

    func start(time: Double? = nil) {
        if let time {
            duration = time
        }
        timeLeft = duration
        isStopped = false
    }

    func stop() {
        isStopped = true
    }

    func resume() {
        isStopped = false
    }

    func update(_ dt: Double) {
        guard !isStopped else { return }
        timeLeft -= dt
        if timeLeft <= 0.0 {
            onTimeout?()
            if isRepeating {
                timeLeft += duration
            } else {
                timeLeft = 0.0
                isStopped = true
            }
        }
    }
}
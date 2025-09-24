final class DropTable { // TODO: use another drop table if player doesnt have ammo yet

    struct Entry {
        let type: DropType?
        let weight: Int
    }

    static let `default` = DropTable(drops: [
        .init(type: .health, weight: 20),
        .init(type: .healthBig, weight: 10),
        .init(type: .ammo, weight: 20),
        .init(type: nil, weight: 50)
    ])

    private let drops: [Entry]
    private let totalWeight: Int

    init(drops: [Entry]) {
        self.drops = drops
        self.totalWeight = drops.reduce(0) { $0 + $1.weight }
    }

    func rollDrop() -> DropType? {
        guard totalWeight > 0 else { return nil }

        let roll = Int.random(in: 1...totalWeight)
        
        var cumulativeWeight = 0
        for drop in drops {
            cumulativeWeight += drop.weight
            if roll <= cumulativeWeight {
                return drop.type
            }
        }
        return nil
    }
}

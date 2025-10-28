final class ServiceLocator {

    private static var services: [ObjectIdentifier: Any] = [:]

    static func register<T>(_ service: T) {
        services[ObjectIdentifier(T.self)] = service
    }

    static func resolve<T>() -> T? {
        return services[ObjectIdentifier(T.self)] as? T
    }

    static func unregister<T>(_ type: T.Type) {
        services.removeValue(forKey: ObjectIdentifier(type))
    }
}
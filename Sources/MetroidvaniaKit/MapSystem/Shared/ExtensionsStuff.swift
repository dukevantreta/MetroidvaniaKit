import SwiftGodot

extension Object {
    
    func setMeta<T>(name: String, value: T?) where T: VariantConvertible {
        self.setMeta(name: StringName(name), value: value?.toVariant())
    }

    func getMeta<T>(name: String, default: T?) -> T? where T: VariantConvertible {
        self.getMeta(name: StringName(name), default: `default`?.toVariant())?.to(T.self)
    }
}
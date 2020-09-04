import Foundation

public protocol Identifiable {
    /// A type representing the stable identity of the entity associated with
    /// an instance.
    associatedtype ID : Hashable
    /// The stable identity of the entity associated with this instance.
    var id: ID { get }
}

extension Identifiable where Self: AnyObject {
    /// The stable identity of the entity associated with this instance.
    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

import UIKit

internal extension IndexPath {
    init?(string: String) {
        let components = string.components(separatedBy: ".").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        self.init(item: components[1], section: components[0])
    }

    var string: NSString {
        return "\(section).\(item)" as NSString
    }
}

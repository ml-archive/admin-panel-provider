import Vapor

extension Content {
    func getBool(_ path: String) throws -> Bool {
        let string: String? = try get(path)
        return string == path
    }
}

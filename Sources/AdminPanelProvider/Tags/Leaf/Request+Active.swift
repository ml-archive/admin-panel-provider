import Leaf
import Vapor

extension ArgumentList {
    func extractPath() -> String? {
        return context.get(path: ["request", "uri", "path"])?.string
    }
}

extension Request {
    static func isActive(_ path: String?, _ defaultPath: String?, _ args: ArraySlice<Argument>, _ stem: Stem, _ context: LeafContext) -> Bool {
        guard args.count > 0 else {
            return path == defaultPath
        }

        for arg in args {
            guard let searchPath = arg.value(with: stem, in: context)?.string else { continue }

            if searchPath.hasSuffix("*"), path?.contains(searchPath.replacingOccurrences(of: "*", with: "")) ?? false {
                return true
            }

            if searchPath == path {
                return true
            }
        }
        
        return false
    }
}

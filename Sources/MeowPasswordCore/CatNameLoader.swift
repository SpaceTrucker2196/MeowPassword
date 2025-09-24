import Foundation

public class CatNameLoader {
    private let catNames: [String]
    
    public init(catNames: [String]) {
        self.catNames = catNames
    }
    
    public convenience init?(from filePath: String) {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return nil
        }
        
        let names = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        self.init(catNames: names)
    }
    
    public func randomNames(count: Int) -> [String] {
        guard count > 0, !catNames.isEmpty else { return [] }
        
        let actualCount = min(count, catNames.count)
        return Array(catNames.shuffled().prefix(actualCount))
    }
    
    public var count: Int {
        return catNames.count
    }
}
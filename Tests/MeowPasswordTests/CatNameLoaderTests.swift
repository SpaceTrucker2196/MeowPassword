import XCTest
@testable import MeowPasswordCore

final class CatNameLoaderTests: XCTestCase {
    
    func testInitWithCatNames() {
        let names = ["Fluffy", "Whiskers", "Shadow", "Mittens"]
        let loader = CatNameLoader(catNames: names)
        
        XCTAssertEqual(loader.count, 4)
    }
    
    func testRandomNamesReturnsCorrectCount() {
        let names = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger"]
        let loader = CatNameLoader(catNames: names)
        
        let randomNames = loader.randomNames(count: 3)
        XCTAssertEqual(randomNames.count, 3)
    }
    
    func testRandomNamesDoesNotExceedAvailable() {
        let names = ["Fluffy", "Whiskers"]
        let loader = CatNameLoader(catNames: names)
        
        let randomNames = loader.randomNames(count: 5)
        XCTAssertEqual(randomNames.count, 2)
    }
    
    func testRandomNamesWithZeroCount() {
        let names = ["Fluffy", "Whiskers", "Shadow"]
        let loader = CatNameLoader(catNames: names)
        
        let randomNames = loader.randomNames(count: 0)
        XCTAssertEqual(randomNames.count, 0)
    }
    
    func testRandomNamesFromEmptyList() {
        let loader = CatNameLoader(catNames: [])
        
        let randomNames = loader.randomNames(count: 3)
        XCTAssertEqual(randomNames.count, 0)
    }
    
    func testInitFromFileWithInvalidPath() {
        let loader = CatNameLoader(from: "/nonexistent/path/file.txt")
        XCTAssertNil(loader)
    }
    
    func testInitFromValidFile() throws {
        // Create a temporary file with cat names
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_cats.txt")
        
        let testContent = "Fluffy\nWhiskers\nShadow\n\nMittens\n"
        try testContent.write(to: tempFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let loader = CatNameLoader(from: tempFile.path)
        XCTAssertNotNil(loader)
        XCTAssertEqual(loader?.count, 4) // Empty line should be filtered out
    }
}
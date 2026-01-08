import XCTest
import Foundation
@testable import DVR

class URLRequestExtensionTests: XCTestCase {
    
    // MARK: - parameterDifference tests
    
    func testParameterDifference_identicalURLs() {
        let url = URL(string: "http://example.com/path?key1=value1&key2=value2")!
        let request1 = URLRequest(url: url)
        let request2 = URLRequest(url: url)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "none (other URL components differ)")
    }
    
    func testParameterDifference_missingParameterInRequest2() {
        let url1 = URL(string: "http://example.com/path?key1=value1&key2=value2")!
        let url2 = URL(string: "http://example.com/path?key1=value1")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "only in interaction: key2")
    }
    
    func testParameterDifference_extraParameterInRequest2() {
        let url1 = URL(string: "http://example.com/path?key1=value1")!
        let url2 = URL(string: "http://example.com/path?key1=value1&key2=value2")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "only in request: key2")
    }
    
    func testParameterDifference_differentValues() {
        let url1 = URL(string: "http://example.com/path?key1=value1&key2=value2")!
        let url2 = URL(string: "http://example.com/path?key1=different&key2=value2")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "different values: key1")
    }
    
    func testParameterDifference_multipleDifferences() {
        let url1 = URL(string: "http://example.com/path?key1=value1&key2=value2&key3=value3")!
        let url2 = URL(string: "http://example.com/path?key1=different&key4=value4")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssert(difference.contains("only in interaction: key2, key3") || difference.contains("only in interaction: key3, key2"))
        XCTAssert(difference.contains("only in request: key4"))
        XCTAssert(difference.contains("different values: key1"))
    }
    
    func testParameterDifference_withIgnoreParameters() {
        let url1 = URL(string: "http://example.com/path?key1=value1&key2=value2&key3=value3")!
        let url2 = URL(string: "http://example.com/path?key1=different&key4=value4")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2, ignoreParameters: ["key1", "key4"])
        
        XCTAssert(difference.contains("only in interaction: key2, key3") || difference.contains("only in interaction: key3, key2"))
        XCTAssertFalse(difference.contains("key1"))
        XCTAssertFalse(difference.contains("key4"))
    }
    
    func testParameterDifference_noQueryParameters() {
        let url1 = URL(string: "http://example.com/path")!
        let url2 = URL(string: "http://example.com/path")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "none (other URL components differ)")
    }
    
    func testParameterDifference_oneHasParametersOtherDoesNot() {
        let url1 = URL(string: "http://example.com/path?key1=value1")!
        let url2 = URL(string: "http://example.com/path")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "only in interaction: key1")
    }
    
    func testParameterDifference_missingURL() {
        let url1 = URL(string: "http://example.com/path?key1=value1")!
        let request1 = URLRequest(url: url1)
        var request2 = URLRequest(url: url1)
        request2.url = nil
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssertEqual(difference, "unable to compare (missing URLs)")
    }
    
    func testParameterDifference_multipleDifferentValues() {
        let url1 = URL(string: "http://example.com/path?key1=value1&key2=value2&key3=value3")!
        let url2 = URL(string: "http://example.com/path?key1=different1&key2=different2&key3=value3")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        XCTAssert(difference.contains("different values: key1, key2") || difference.contains("different values: key2, key1"))
    }
    
    func testParameterDifference_sortedKeys() {
        let url1 = URL(string: "http://example.com/path?zebra=1&apple=2&banana=3")!
        let url2 = URL(string: "http://example.com/path?only=4")!
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        
        let difference = request1.parameterDifference(from: request2)
        
        // Keys should be sorted alphabetically
        XCTAssert(difference.contains("only in interaction: apple, banana, zebra"))
        XCTAssert(difference.contains("only in request: only"))
    }
}

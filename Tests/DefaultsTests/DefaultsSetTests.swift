import Foundation
import Defaults
import XCTest

let fixtureSet = Set(1...5)

extension Defaults.Keys {
	static let set = Key<Set<Int>>("setInt", default: fixtureSet)
}

final class DefaultsSetTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Set<Int>>("independentSetKey", default: fixtureSet)
		XCTAssertEqual(Defaults[key].count, fixtureSet.count)
		Defaults[key].insert(6)
		XCTAssertEqual(Defaults[key], Set(1...6))
	}
}

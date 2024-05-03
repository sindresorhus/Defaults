import SwiftUI
import Defaults
import XCTest

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, visionOS 1.0, *)
final class DefaultsColorTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testPreservesColorSpace() {
		let fixture = Color(.displayP3, red: 1, green: 0.3, blue: 0.7, opacity: 1)
		let key = Defaults.Key<Color?>("independentColorPreservesColorSpaceKey")
		Defaults[key] = fixture
		XCTAssertEqual(Defaults[key]?.cgColor?.colorSpace, fixture.cgColor?.colorSpace)
		XCTAssertEqual(Defaults[key]?.cgColor, fixture.cgColor)
	}
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
final class DefaultsColorResolvedTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func test() {
		let fixture = Color(.displayP3, red: 1, green: 0.3, blue: 0.7, opacity: 1).resolve(in: .init())
		let key = Defaults.Key<Color.Resolved?>("independentColorResolvedKey")
		Defaults[key] = fixture
		XCTAssertEqual(Defaults[key]?.cgColor, fixture.cgColor)
	}
}

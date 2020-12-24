import XCTest
import Foundation
import SwiftUI
import Defaults

extension Defaults.Keys {
	static let hasUnicorn = Key<Bool>("hasUnicorn", default: false)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn
	@Default(.user) var user

	var body: some View {
		Text("User : \(user.username) has Unicorn: \(String(hasUnicorn))")
		Toggle("Toggle Unicorn", isOn: $hasUnicorn)
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DefaultsSwiftUITests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testSwiftUIObserve() {
		let view = ContentView()
		XCTAssertFalse(view.hasUnicorn)
		XCTAssertEqual(view.user.username, fixtureCustomBridge.username)
		view.hasUnicorn.toggle()
		view.user = User(username: "hank", password: "1234")
		XCTAssertTrue(view.hasUnicorn)
		XCTAssertEqual(view.user.username, "hank")
	}
}

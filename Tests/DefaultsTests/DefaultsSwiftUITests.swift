import XCTest
import Foundation
import SwiftUI
import Defaults

extension Defaults.Keys {
	static let hasUnicorn = Key<Bool>("swiftui_hasUnicorn", default: false)
	static let user = Key<User>("swiftui_user", default: User(username: "Hank", password: "123456"))
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn
	@Default(.user) var user

	var body: some View {
		Text("User \(user.username) has Unicorn: \(String(hasUnicorn))")
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
		XCTAssertEqual(view.user.username, "Hank")
		view.user = User(username: "Chen", password: "123456")
		view.hasUnicorn.toggle()
		XCTAssertTrue(view.hasUnicorn)
		XCTAssertEqual(view.user.username, "Chen")
	}
}

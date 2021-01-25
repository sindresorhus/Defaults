import XCTest
import Foundation
import SwiftUI
import Defaults

extension Defaults.Keys {
	fileprivate static let hasUnicorn = Key<Bool>("swiftui_hasUnicorn", default: false)
	fileprivate static let user = Key<User>("swiftui_user", default: User(username: "Hank", password: "123456"))
	fileprivate static let setInt = Key<Set<Int>>("swiftui_setInt", default: Set(1...3))
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn
	@Default(.user) var user
	@Default(.setInt) var setInt

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
		super.tearDown()
		Defaults.removeAll()
	}

	func testSwiftUIObserve() {
		let view = ContentView()
		XCTAssertFalse(view.hasUnicorn)
		XCTAssertEqual(view.user.username, "Hank")
		XCTAssertEqual(view.setInt.count, 3)
		view.user = User(username: "Chen", password: "123456")
		view.hasUnicorn.toggle()
		view.setInt.insert(4)
		XCTAssertTrue(view.hasUnicorn)
		XCTAssertEqual(view.user.username, "Chen")
		XCTAssertEqual(view.setInt, Set(1...4))
	}
}

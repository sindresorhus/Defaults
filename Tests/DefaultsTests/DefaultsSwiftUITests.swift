import XCTest
import Foundation
import SwiftUI
import Defaults

#if os(macOS)
typealias XColor = NSColor
#else
typealias XColor = UIColor
#endif

extension Defaults.Keys {
	fileprivate static let hasUnicorn = Key<Bool>("swiftui_hasUnicorn", default: false)
	fileprivate static let user = Key<User>("swiftui_user", default: User(username: "Hank", password: "123456"))
	fileprivate static let setInt = Key<Set<Int>>("swiftui_setInt", default: Set(1...3))
	fileprivate static let color = Key<Color>("swiftui_color", default: .black)
}

struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn
	@Default(.user) var user
	@Default(.setInt) var setInt
	@Default(.color) var color

	var body: some View {
		Text("User \(user.username) has Unicorn: \(String(hasUnicorn))")
			.foregroundColor(color)
		Toggle("Toggle Unicorn", isOn: $hasUnicorn)
	}
}

@MainActor
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
		XCTAssertEqual(XColor(view.color), XColor(Color.black))
		view.user = User(username: "Chen", password: "123456")
		view.hasUnicorn.toggle()
		view.setInt.insert(4)
		view.color = Color(.sRGB, red: 100, green: 100, blue: 100, opacity: 1)
		XCTAssertTrue(view.hasUnicorn)
		XCTAssertEqual(view.user.username, "Chen")
		XCTAssertEqual(view.setInt, Set(1...4))
		XCTAssertFalse(Default(.hasUnicorn).defaultValue)
		XCTAssertFalse(Default(.hasUnicorn).isDefaultValue)
		XCTAssertNotEqual(XColor(view.color), XColor(Color.black))
		XCTAssertEqual(XColor(view.color), XColor(Color(.sRGB, red: 100, green: 100, blue: 100, opacity: 1)))
	}
}

import Foundation
import Defaults
import XCTest

private struct CustomDate {
	let year: Int
	let month: Int
	let day: Int
}

extension CustomDate: Defaults.Serializable {
	public struct CustomDateBridge: Defaults.Bridge {
		public typealias Value = CustomDate
		public typealias Serializable = [Int]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let value = value else {
				return nil
			}

			return [value.year, value.month, value.day]
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let object = object else {
				return nil
			}

			return .init(year: object[0], month: object[1], day: object[2])
		}
	}

	public static let bridge = CustomDateBridge()
}

extension CustomDate: Comparable {
	static func < (lhs: CustomDate, rhs: CustomDate) -> Bool {
		if lhs.year != rhs.year {
				return lhs.year < rhs.year
		} else if lhs.month != rhs.month {
				return lhs.month < rhs.month
		} else {
				return lhs.day < rhs.day
		}
	}

	static func == (lhs: CustomDate, rhs: CustomDate) -> Bool {
		lhs.year == rhs.year && lhs.month == rhs.month
				&& lhs.day == rhs.day
	}
}

// Fixtures:
private let fixtureRange = 0..<10
private let nextFixtureRange = 1..<20
private let fixtureDateRange = CustomDate(year: 2022, month: 4, day: 0)..<CustomDate(year: 2022, month: 5, day: 0)
private let nextFixtureDateRange = CustomDate(year: 2022, month: 6, day: 1)..<CustomDate(year: 2022, month: 7, day: 1)
private let fixtureClosedRange = 0...10
private let nextFixtureClosedRange = 1...20
private let fixtureDateClosedRange = CustomDate(year: 2022, month: 4, day: 0)...CustomDate(year: 2022, month: 5, day: 0)
private let nextFixtureDateClosedRange = CustomDate(year: 2022, month: 6, day: 1)...CustomDate(year: 2022, month: 7, day: 1)

final class DefaultsClosedRangeTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		// Test native support Range type
		let key = Defaults.Key<Range>("independentRangeKey", default: fixtureRange)
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key].upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key].lowerBound)
		Defaults[key] = nextFixtureRange
		XCTAssertEqual(nextFixtureRange.upperBound, Defaults[key].upperBound)
		XCTAssertEqual(nextFixtureRange.lowerBound, Defaults[key].lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<Range<CustomDate>>("independentRangeDateKey", default: fixtureDateRange)
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey].upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey].lowerBound)
		Defaults[dateKey] = nextFixtureDateRange
		XCTAssertEqual(nextFixtureDateRange.upperBound, Defaults[dateKey].upperBound)
		XCTAssertEqual(nextFixtureDateRange.lowerBound, Defaults[dateKey].lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<ClosedRange>("independentClosedRangeKey", default: fixtureClosedRange)
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey].upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey].lowerBound)
		Defaults[closedKey] = nextFixtureClosedRange
		XCTAssertEqual(nextFixtureClosedRange.upperBound, Defaults[closedKey].upperBound)
		XCTAssertEqual(nextFixtureClosedRange.lowerBound, Defaults[closedKey].lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<ClosedRange<CustomDate>>("independentClosedRangeDateKey", default: fixtureDateClosedRange)
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey].upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey].lowerBound)
		Defaults[closedDateKey] = nextFixtureDateClosedRange
		XCTAssertEqual(nextFixtureDateClosedRange.upperBound, Defaults[closedDateKey].upperBound)
		XCTAssertEqual(nextFixtureDateClosedRange.lowerBound, Defaults[closedDateKey].lowerBound)
	}

	func testOptionalKey() {
		// Test native support Range type
		let key = Defaults.Key<Range<Int>?>("independentRangeOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureRange
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key]?.upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key]?.lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<Range<CustomDate>?>("independentRangeDateOptionalKey")
		XCTAssertNil(Defaults[dateKey])
		Defaults[dateKey] = fixtureDateRange
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey]?.upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey]?.lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<ClosedRange<Int>?>("independentClosedRangeOptionalKey")
		XCTAssertNil(Defaults[closedKey])
		Defaults[closedKey] = fixtureClosedRange
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey]?.upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey]?.lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<ClosedRange<CustomDate>?>("independentClosedRangeDateOptionalKey")
		XCTAssertNil(Defaults[closedDateKey])
		Defaults[closedDateKey] = fixtureDateClosedRange
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey]?.upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey]?.lowerBound)
	}

	func testArrayKey() {
		// Test native support Range type
		let key = Defaults.Key<[Range]>("independentRangeArrayKey", default: [fixtureRange])
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key][0].upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key][0].lowerBound)
		Defaults[key].append(nextFixtureRange)
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key][0].upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key][0].lowerBound)
		XCTAssertEqual(nextFixtureRange.upperBound, Defaults[key][1].upperBound)
		XCTAssertEqual(nextFixtureRange.lowerBound, Defaults[key][1].lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<[Range<CustomDate>]>("independentRangeDateArrayKey", default: [fixtureDateRange])
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey][0].upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey][0].lowerBound)
		Defaults[dateKey].append(nextFixtureDateRange)
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey][0].upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey][0].lowerBound)
		XCTAssertEqual(nextFixtureDateRange.upperBound, Defaults[dateKey][1].upperBound)
		XCTAssertEqual(nextFixtureDateRange.lowerBound, Defaults[dateKey][1].lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<[ClosedRange]>("independentClosedRangeArrayKey", default: [fixtureClosedRange])
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey][0].upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey][0].lowerBound)
		Defaults[closedKey].append(nextFixtureClosedRange)
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey][0].upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey][0].lowerBound)
		XCTAssertEqual(nextFixtureClosedRange.upperBound, Defaults[closedKey][1].upperBound)
		XCTAssertEqual(nextFixtureClosedRange.lowerBound, Defaults[closedKey][1].lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<[ClosedRange<CustomDate>]>("independentClosedRangeDateArrayKey", default: [fixtureDateClosedRange])
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey][0].upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey][0].lowerBound)
		Defaults[closedDateKey].append(nextFixtureDateClosedRange)
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey][0].upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey][0].lowerBound)
		XCTAssertEqual(nextFixtureDateClosedRange.upperBound, Defaults[closedDateKey][1].upperBound)
		XCTAssertEqual(nextFixtureDateClosedRange.lowerBound, Defaults[closedDateKey][1].lowerBound)
	}

	func testDictionaryKey() {
		// Test native support Range type
		let key = Defaults.Key<[String: Range]>("independentRangeDictionaryKey", default: ["0": fixtureRange])
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key]["0"]?.upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key]["0"]?.lowerBound)
		Defaults[key]["1"] = nextFixtureRange
		XCTAssertEqual(fixtureRange.upperBound, Defaults[key]["0"]?.upperBound)
		XCTAssertEqual(fixtureRange.lowerBound, Defaults[key]["0"]?.lowerBound)
		XCTAssertEqual(nextFixtureRange.upperBound, Defaults[key]["1"]?.upperBound)
		XCTAssertEqual(nextFixtureRange.lowerBound, Defaults[key]["1"]?.lowerBound)

		// Test serializable Range type
		let dateKey = Defaults.Key<[String: Range<CustomDate>]>("independentRangeDateDictionaryKey", default: ["0": fixtureDateRange])
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey]["0"]?.lowerBound)
		Defaults[dateKey]["1"] = nextFixtureDateRange
		XCTAssertEqual(fixtureDateRange.upperBound, Defaults[dateKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureDateRange.lowerBound, Defaults[dateKey]["0"]?.lowerBound)
		XCTAssertEqual(nextFixtureDateRange.upperBound, Defaults[dateKey]["1"]?.upperBound)
		XCTAssertEqual(nextFixtureDateRange.lowerBound, Defaults[dateKey]["1"]?.lowerBound)

		// Test native support ClosedRange type
		let closedKey = Defaults.Key<[String: ClosedRange]>("independentClosedRangeDictionaryKey", default: ["0": fixtureClosedRange])
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey]["0"]?.lowerBound)
		Defaults[closedKey]["1"] = nextFixtureClosedRange
		XCTAssertEqual(fixtureClosedRange.upperBound, Defaults[closedKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureClosedRange.lowerBound, Defaults[closedKey]["0"]?.lowerBound)
		XCTAssertEqual(nextFixtureClosedRange.upperBound, Defaults[closedKey]["1"]?.upperBound)
		XCTAssertEqual(nextFixtureClosedRange.lowerBound, Defaults[closedKey]["1"]?.lowerBound)

		// Test serializable ClosedRange type
		let closedDateKey = Defaults.Key<[String: ClosedRange<CustomDate>]>("independentClosedRangeDateDictionaryKey", default: ["0": fixtureDateClosedRange])
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey]["0"]?.lowerBound)
		Defaults[closedDateKey]["1"] = nextFixtureDateClosedRange
		XCTAssertEqual(fixtureDateClosedRange.upperBound, Defaults[closedDateKey]["0"]?.upperBound)
		XCTAssertEqual(fixtureDateClosedRange.lowerBound, Defaults[closedDateKey]["0"]?.lowerBound)
		XCTAssertEqual(nextFixtureDateClosedRange.upperBound, Defaults[closedDateKey]["1"]?.upperBound)
		XCTAssertEqual(nextFixtureDateClosedRange.lowerBound, Defaults[closedDateKey]["1"]?.lowerBound)
	}
}

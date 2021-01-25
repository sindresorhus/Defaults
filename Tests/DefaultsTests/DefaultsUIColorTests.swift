import Foundation
import Defaults
import XCTest
import UIKit

private let fixtureColor = UIColor(red: CGFloat(103) / CGFloat(0xFF), green: CGFloat(132) / CGFloat(0xFF), blue: CGFloat(255) / CGFloat(0xFF), alpha: 1)
private let fixtureColor1 = UIColor(red: CGFloat(255) / CGFloat(0xFF), green: CGFloat(241) / CGFloat(0xFF), blue: CGFloat(180) / CGFloat(0xFF), alpha: 1)
private let fixtureColor2 = UIColor(red: CGFloat(255) / CGFloat(0xFF), green: CGFloat(180) / CGFloat(0xFF), blue: CGFloat(194) / CGFloat(0xFF), alpha: 1)

extension Defaults.Keys {
	fileprivate static let color = Defaults.Key<UIColor>("NSColor", default: fixtureColor)
	fileprivate static let colorArray = Defaults.Key<[UIColor]>("NSColorArray", default: [fixtureColor])
	fileprivate static let colorDictionary = Defaults.Key<[String: UIColor]>("NSColorArray", default: ["0": fixtureColor])
}

final class DefaultsNSColorTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<UIColor>("independentNSColorKey", default: fixtureColor)
		XCTAssertTrue(Defaults[key].isEqual(fixtureColor))
		Defaults[key] = fixtureColor1
		XCTAssertTrue(Defaults[key].isEqual(fixtureColor1))
	}

	func testOptionalKey() {
		let key = Defaults.Key<UIColor?>("independentNSColorOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureColor
		XCTAssertTrue(Defaults[key]?.isEqual(fixtureColor) ?? false)
	}

	func testArrayKey() {
		let key = Defaults.Key<[UIColor]>("independentNSColorArrayKey", default: [fixtureColor])
		XCTAssertTrue(Defaults[key][0].isEqual(fixtureColor))
		Defaults[key].append(fixtureColor1)
		XCTAssertTrue(Defaults[key][1].isEqual(fixtureColor1))
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[UIColor]?>("independentNSColorOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [fixtureColor]
		Defaults[key]?.append(fixtureColor1)
		XCTAssertTrue(Defaults[key]?[0].isEqual(fixtureColor) ?? false)
		XCTAssertTrue(Defaults[key]?[1].isEqual(fixtureColor1) ?? false)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[UIColor]]>("independentNSColorNestedArrayKey", default: [[fixtureColor]])
		XCTAssertTrue(Defaults[key][0][0].isEqual(fixtureColor))
		Defaults[key][0].append(fixtureColor1)
		Defaults[key].append([fixtureColor2])
		XCTAssertTrue(Defaults[key][0][1].isEqual(fixtureColor1))
		XCTAssertTrue(Defaults[key][1][0].isEqual(fixtureColor2))
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: UIColor]]>("independentNSColorArrayDictionaryKey", default: [["0": fixtureColor]])
		XCTAssertTrue(Defaults[key][0]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[key][0]["1"] = fixtureColor1
		Defaults[key].append(["0": fixtureColor2])
		XCTAssertTrue(Defaults[key][0]["1"]?.isEqual(fixtureColor1) ?? false)
		XCTAssertTrue(Defaults[key][1]["0"]?.isEqual(fixtureColor2) ?? false)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: UIColor]>("independentNSColorDictionaryKey", default: ["0": fixtureColor])
		XCTAssertTrue(Defaults[key]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[key]["1"] = fixtureColor1
		XCTAssertTrue(Defaults[key]["1"]?.isEqual(fixtureColor1) ?? false)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: UIColor]?>("independentNSColorDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": fixtureColor]
		Defaults[key]?["1"] = fixtureColor1
		XCTAssertTrue(Defaults[key]?["0"]?.isEqual(fixtureColor) ?? false)
		XCTAssertTrue(Defaults[key]?["1"]?.isEqual(fixtureColor1) ?? false)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [UIColor]]>("independentNSColorDictionaryArrayKey", default: ["0": [fixtureColor]])
		XCTAssertTrue(Defaults[key]["0"]?[0].isEqual(fixtureColor) ?? false)
		Defaults[key]["0"]?.append(fixtureColor1)
		Defaults[key]["1"] = [fixtureColor2]
		XCTAssertTrue(Defaults[key]["0"]?[1].isEqual(fixtureColor1) ?? false)
		XCTAssertTrue(Defaults[key]["1"]?[0].isEqual(fixtureColor2) ?? false)
	}

	func testType() {
		XCTAssert(Defaults[.color].isEqual(fixtureColor))
		Defaults[.color] = fixtureColor1
		XCTAssert(Defaults[.color].isEqual(fixtureColor1))
	}

	func testArrayType() {
		XCTAssertTrue(Defaults[.colorArray][0].isEqual(fixtureColor))
		Defaults[.colorArray][0] = fixtureColor1
		XCTAssertTrue(Defaults[.colorArray][0].isEqual(fixtureColor1))
	}

	func testDictionaryType() {
		XCTAssertTrue(Defaults[.colorDictionary]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[.colorDictionary]["0"] = fixtureColor1
		XCTAssertTrue(Defaults[.colorDictionary]["0"]?.isEqual(fixtureColor1) ?? false)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<UIColor>("observeNSColorKeyCombine", default: fixtureColor)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureColor, fixtureColor1), (fixtureColor1, fixtureColor)].enumerated() {
				XCTAssertTrue(expected.0.isEqual(tuples[index].0))
				XCTAssertTrue(expected.1.isEqual(tuples[index].1))
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureColor1
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<UIColor?>("observeNSColorOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(UIColor?, UIColor?)] = [(nil, fixtureColor), (fixtureColor, fixtureColor1), (fixtureColor1, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				guard let oldValue = expected.0 else {
					XCTAssertNil(tuples[index].0)
					continue
				}
				guard let newValue = expected.1 else {
					XCTAssertNil(tuples[index].1)
					continue
				}
				XCTAssertTrue(oldValue.isEqual(tuples[index].0))
				XCTAssertTrue(newValue.isEqual(tuples[index].1))
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureColor
		Defaults[key] = fixtureColor1
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[UIColor]>("observeNSColorArrayKeyCombine", default: [fixtureColor])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureColor, fixtureColor1), (fixtureColor1, fixtureColor)].enumerated() {
				XCTAssertTrue(expected.0.isEqual(tuples[index].0[0]))
				XCTAssertTrue(expected.1.isEqual(tuples[index].1[0]))
			}

			expect.fulfill()
		}

		Defaults[key][0] = fixtureColor1
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: UIColor]>("observeNSColorDictionaryKeyCombine", default: ["0": fixtureColor])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureColor, fixtureColor1), (fixtureColor1, fixtureColor)].enumerated() {
				XCTAssertTrue(expected.0.isEqual(tuples[index].0["0"]))
				XCTAssertTrue(expected.1.isEqual(tuples[index].1["0"]))
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = fixtureColor1
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<UIColor>("observeNSColorKey", default: fixtureColor)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue.isEqual(fixtureColor))
			XCTAssertTrue(change.newValue.isEqual(fixtureColor1))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureColor1
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<UIColor?>("observeNSColorOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertTrue(change.newValue?.isEqual(fixtureColor) ?? false)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureColor
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[UIColor]>("observeNSColorArrayKey", default: [fixtureColor])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue[0].isEqual(fixtureColor))
			XCTAssertTrue(change.newValue[0].isEqual(fixtureColor))
			XCTAssertTrue(change.newValue[1].isEqual(fixtureColor1))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].append(fixtureColor1)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: UIColor]>("observeNSColorDictionaryKey", default: ["0": fixtureColor])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue["0"]?.isEqual(fixtureColor) ?? false)
			XCTAssertTrue(change.newValue["0"]?.isEqual(fixtureColor) ?? false)
			XCTAssertTrue(change.newValue["1"]?.isEqual(fixtureColor1) ?? false)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["1"] = fixtureColor1
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}

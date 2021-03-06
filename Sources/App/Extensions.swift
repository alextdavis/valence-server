import Random

//These next two thanks to Nate Cook from http://stackoverflow.com/a/24029847/5870145
extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else {
            return
        }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(makeRandom(min: 0, max: numericCast(unshuffledCount) - 1))
            guard d != 0 else {
                continue
            }
            let i = index(firstUnshuffled, offsetBy: d)
            self.swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

extension JSON {
    static func makeFromDict(_ dict: [String: Any?]) -> JSON {
        var json = JSON()
        for (k, v) in dict {
            do {
                try json.set(k, v)
            } catch {
            }
        }
        return json
    }
}

extension Date {
    static func -(lhs: Date, rhs: Date) -> Double {
        return lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970
    }
}

class Queue<T> {
    private var ary: [T]

    init() {
        ary = Array<T>()
    }

    init(_ input: [T]) {
        ary = Array(input.reversed())
    }

    init(_ input: ArraySlice<T>) {
        ary = Array(input.reversed())
    }

    public var isEmpty: Bool {
        return ary.isEmpty
    }

    public func enqueue(_ ele: T) {
        self.enqueue([ele])
    }

    public func enqueue(_ eles: [T]) {
        ary.insert(contentsOf: eles, at: 0)
    }

    public func prepend(_ ele: T) {
        self.prepend([ele])
    }

    public func prepend(_ eles: [T]) {
        ary.append(contentsOf: eles)
    }

    public func dequeue() -> T? {
        return ary.popLast()
    }

    public func peek() -> T? {
        return ary.last
    }

    public func makeArray() -> [T] {
        return Array(ary.reversed())
    }
}

extension Sequence where Self.Iterator.Element: Equatable {
    func contains(keys: [Self.Iterator.Element]) -> Bool {
        for key in keys {
            if !self.contains(key) {
                return false
            }
        }
        return true
    }
}

protocol OptionalType {
    associatedtype Wrapped

    func map<U>(_ f: (Wrapped) throws -> U) rethrows -> U?
}

extension Optional: OptionalType {
}

extension Sequence where Iterator.Element: OptionalType {
    func removeNils() -> [Iterator.Element.Wrapped] {
        var result: [Iterator.Element.Wrapped] = []
        for element in self {
            if let element = element.map({ $0 }) {
                result.append(element)
            }
        }
        return result
    }
}

class SomeError: Swift.Error { //TODO: Proper error instead of SomeError
    init() {
    }
}

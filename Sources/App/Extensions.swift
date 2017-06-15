
//These next two thanks to Nate Cook from http://stackoverflow.com/a/24029847/5870145
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
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

class Queue<T> {
    private var ary: [T]
    
    init() {
        ary = Array<T>()
    }
    
    init(_ input: [T]) {
        ary = Array(input.reversed())
    }
    
    convenience init(_ input: ArraySlice<T>) {
        self.init(Array(input.reversed()))
    }
    
    public var isEmpty: Bool {
        return ary.isEmpty
    }
    
    public func enqueue(_ ele: T) {
        ary.insert(ele, at: 0)
    }
    
    public func prepend(_ ele: T) {
        ary.append(ele)
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

extension Sequence where Self.Iterator.Element : Equatable {
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

extension Optional: OptionalType {}

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

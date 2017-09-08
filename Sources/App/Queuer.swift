class Queuer {
    public static let q = Queuer()

    private(set) var queue = Queue<Int>()
    private(set) var history = Array<Int>()
    private(set) var list = Array<Int>()
    private var viewList = Array<Int>()
    private var current: Int? {
        didSet {
            if (history.last != current && current != nil) {
                history.append(current!)
            }
        }
    }
    private(set) var shuffling = false
    private(set) var repeating = false
    private var isManual = false

    public var subscribers: [WebSocket] = Array()

    var status: JSON {
        get {
            do {
                var json = JSON()
                try json.set("shuffle", shuffling)
                try json.set("repeat", repeating)
                try json.set("queue", queue.makeArray())
                try json.set("history", history)
                try json.set("current", current ?? 0)
                return json
            } catch {
                return JSON()
            }
        }
    }

    init() {
        updateViewList([])
    }

    func updateViewList(_ viewList: [Int]) {
        self.viewList = viewList
    }

    func next() {
        if queue.isEmpty {
            generateQueue()
        }
        current = queue.dequeue()
        notify()
    }

    func previous() {
        if history.count > 1 || history[0] != current {
            if current != nil {
                queue.prepend(current!)
            }
            history.popLast()
            current = history.last
        } else {
            history = []
            current = nil
        }
        notify()
    }

    func directPlay(_ id: Int) {
        generateList()
        current = id
        generateQueue(id)
        notify()
    }

    func directPlay(list: [Int]) {
        self.list = list
        if shuffling {
            current = list.shuffled()[0] //TODO inefficient
        } else {
            current = list[0]
        }
        generateQueue(current)
        notify()
    }

    func enqueueNext(_ id: Int) {
        self.enqueueNext([id])
    }

    func enqueueNext(_ ids: [Int]) {
        if !isManual {
            queue = Queue()
        }
        queue.prepend(ids)
        notify()
    }

    func enqueueAppend(_ id: Int) {
        self.enqueueAppend([id])
    }

    func enqueueAppend(_ ids: [Int]) {
        if !isManual {
            queue = Queue()
        }
        queue.enqueue(ids)
        notify()
    }

    func shuffle() {
        shuffling = !shuffling
        if shuffling && !isManual && current != nil {
            generateQueue(current!)
        }
        notify()
    }

    private func generateQueue(_ id: Int? = nil) {
        isManual = false
        if shuffling {
            var shuffledList = list.shuffled()
            if id != nil, let index = list.index(of: id!) {
                shuffledList.remove(at: index)
            }
            queue = Queue(shuffledList)
        } else if id != nil, let index = list.index(of: id!) {
            queue = Queue(list[Range((index + 1)..<list.count)])
        } else {
            queue = Queue(list)
        }
    }

    private func generateList() {
        list = viewList
    }

    private func notify() {
        for ws in subscribers {
            do {
                try ws.send("notify")
            } catch {
                print("[WebSockets Error] \(error)")
            }
        }
    }

}

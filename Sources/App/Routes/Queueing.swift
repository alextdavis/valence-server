import Vapor
import HTTP

class QueueingRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.group("q") { b in
            b.post("dispatch") { req in
                let message = req.data["message"] ?? ""
                switch message {
                case "next":
                    Queuer.q.next()
                case "prev":
                    Queuer.q.previous()
                case "direct_play", "enqueue_now":
                    Queuer.q.directPlay((req.data["id"]?.int)!)
                case "enqueue_next":
                    Queuer.q.enqueueNext((req.data["id"]?.int)!)
                case "enqueue_append":
                    Queuer.q.enqueueAppend((req.data["id"]?.int)!)
                case "shuffle":
                    Queuer.q.shuffle()
                case "repeat":
                    ()
                case "update":
                    ()
                case "greetings":
                    print("New client at... somewhere")
                default:
                    throw Abort(.badRequest, reason: "improper dispatch: `\(message)`")
                }

                return Queuer.q.status
            }

            b.get("status") { req in
                return Queuer.q.status
            }

            b.get("ws") { req in
                try req.upgradeToWebSocket { ws in
                    print("Websocket connected")
                    Queuer.q.subscribers.append(ws)

                    ws.onText = { ws, text in
                        switch text {
                        case "next":
                            Queuer.q.next()
                        case "prev":
                            Queuer.q.previous()
                        case "direct_play", "enqueue_now":
                            Queuer.q.directPlay((req.data["id"]?.int)!)
                        case "enqueue_next":
                            Queuer.q.enqueueNext((req.data["id"]?.int)!)
                        case "enqueue_append":
                            Queuer.q.enqueueAppend((req.data["id"]?.int)!)
                        case "shuffle":
                            Queuer.q.shuffle()
                        case "repeat":
                            ()
                        case "update":
                            ()
                        case "greetings":
                            print("New client at... somewhere")
                        default:
                            print("Invalid WS Dispatch")
                        }
                        try ws.send("notify")
                    }

                    ws.onClose = { ws, _, _, _ in
                        let websock: WebSocket = ws
                        for index in Queuer.q.subscribers.indices {
                            if Queuer.q.subscribers[index] === websock {
                                Queuer.q.subscribers.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
    }
}

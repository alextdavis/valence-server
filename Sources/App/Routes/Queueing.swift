import Vapor
import HTTP

class QueueingRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.post("q", "dispatch") { req in
            let message = req.data["message"] ?? ""
            switch message {
            case "next":
                Queuer.q.next()
            case "prev":
                Queuer.q.previous()
            case "direct_play", "enqueue_now":
                if let id = req.data["id"]?.int {
                    Queuer.q.directPlay(id)
                } else if let str = req.data["search"]?.string {
                    Queuer.q.directPlay(try Search(str).getIDs())
                } else {
                    throw Abort(.badRequest, reason: "bad id or search data")
                }
            case "enqueue_next":
                if let id = req.data["id"]?.int {
                    Queuer.q.enqueueNext(id)
                } else if let str = req.data["search"]?.string {
                    Queuer.q.enqueueNext(try Search(str).getIDs())
                } else {
                    throw Abort(.badRequest, reason: "bad id or search data")
                }
            case "enqueue_append":
                if let id = req.data["id"]?.int {
                    Queuer.q.enqueueAppend(id)
                } else if let str = req.data["search"]?.string {
                    Queuer.q.enqueueAppend(try Search(str).getIDs())
                } else {
                    throw Abort(.badRequest, reason: "bad id or search data")
                }
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
    }
}

import Vapor
import HTTP

class QueueingRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.post("q", "dispatch") { req in
            switch req.parameters["message"]?.string ?? "" {
            case "next":
                Queuer.q.next()
            case "prev":
                Queuer.q.previous()
            case "enqueue_now":
                Queuer.q.enqueueNow((req.parameters["id"]?.int)!)
            case "enqueue_next":
                Queuer.q.enqueueNext((req.parameters["id"]?.int)!)
            case "enqueue_append":
                Queuer.q.enqueueAppend((req.parameters["id"]?.int)!)
            case "shuffle":
                Queuer.q.shuffle()
            case "update":
                ()
            case "greetings":
                print("New client at... somewhwere")
            default:
                throw Abort(.badRequest, reason: "improper dispatch")
            }
            
            return Queuer.q.status
        }
    }
}

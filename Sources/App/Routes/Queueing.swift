import Vapor
import HTTP

class QueueingRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.post("q", "dispatch", String.parameter) { req in //TODO: Switch this back to a post parameter
            let message = try req.parameters.next(String.self)
            switch message {
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
            case "repeat":
                ()
            case "update":
                ()
            case "greetings":
                print("New client at... somewhwere")
            default:
                throw Abort(.badRequest, reason: "improper dispatch: `\(message)`")
            }
            
            return Queuer.q.status
        }
    }
}

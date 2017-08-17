import Vapor

class PlayerRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.get("p") { req in
            return try self.view.make("browser.erb")
        }

        builder.get("player") { req in
            return try self.view.make("player.erb", ["layout": false])
        }

        builder.get("queue") { req in
            return try self.view.make("queue.erb",
                    ["layout": false,
                     "@songs": Song.songs(ids: Queuer.q.queue).map({ $0.makeJSON(.qlist) })
                    ])
        }
    }
}

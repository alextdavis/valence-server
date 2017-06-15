import Vapor

class BrowseRoutes: Routes {

    override func build(_ builder: RouteBuilder) throws {
        builder.group("b") { b in

            b.get("all") { req in
                let songs = try Song.makeQuery().limit(100).all()
//                if let by = req.parameters["by"], let order = req.parameters["order"] { //TODO: Ordering
//                    songs = try Song.all()
//                } else {
//                    songs = try Array(Song.all()[Range(0...100)])
//                }

                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                return try self.view.make("table.erb",
                        ["layout": "just_container.erb",
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON])
                        ])
            }

            b.get("albums") { req in
                return try self.view.make("split.erb",
                        ["layout": false,
                         "@albums": Album.all().map({ $0.makeJSON() }) as [JSON]
                        ])
            }

            b.get("artists") { req in
                return try self.view.make("split.erb",
                        ["layout": false,
                         "@artists": Artist.all().map({ $0.makeJSON() })
                        ])
            }

            b.get("tags") { req in
                return try self.view.make("split.erb",
                        ["layout": false,
                         "@tags": Tag.all().map({ $0.makeJSON() })
                        ])
            }

            b.get("artist", Int.parameter) { req in
                guard let songs = try? Artist.find(try req.parameters.next(Int.self))?.songs.all() else {
                    throw Abort.notFound
                }
                let cols = ["rank", "track", "name", "tags", "time", "rating", "artists", "album"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs!.map({ $0.makeJSON(cols: cols) }) as [JSON])
                        ])
            }

            b.get("album", Int.parameter) { req in
                guard let songs = try? Album.find(try req.parameters.next(Int.self))?.songs.all() else {
                    throw Abort.notFound
                }
                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs!.map({ $0.makeJSON(cols: cols) }) as [JSON])
                        ])
            }

            b.get("tag", Int.parameter) { req in
                guard let songs = try? Tag.find(try req.parameters.next(Int.self))?.songs.all() else {
                    throw Abort.notFound
                }
                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs!.map({ $0.makeJSON(cols: cols) }) as [JSON])
                        ])
            }


        }//group
    }
}

import Vapor

class BrowseRoutes: Routes {

    override func build(_ builder: RouteBuilder) throws {
        builder.group("b") { b in

            b.get("all") { req in
                var query = try Song.makeQuery().limit(100)
                var orderStrs: [String]? = nil

                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = [by, order]
                    //TODO: Abstract ordering process
                    //TODO: Implement ordering for things like album/artist of a song.
                }
                let songs = try query.all()

                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                return try self.view.make("table.erb",
                        ["layout": "just_container.erb",
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON]),
                         "@order": orderStrs as Any?,
                        ])
            }

            b.get("albums") { req in
                return try self.view.make("split.erb",
                        ["layout": false,
                         "@albums": Album.all().map({ $0.makeJSON() })
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

            b.get("artist", Artist.parameter) { req in
                var query = try req.parameters.next(Artist.self).songs.makeQuery()

                var orderStrs: [String]? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = [by, order]
                }
                let songs = try query.all()

                let cols = ["rank", "track", "name", "tags", "time", "rating", "artists", "album"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON]),
                         "@order": orderStrs as Any?,
                        ])
            }

            b.get("album", Album.parameter) { req in
                var query = try req.parameters.next(Album.self).songs.makeQuery()

                var orderStrs: [String]? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = [by, order]
                }
                let songs = try query.all()

                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON]),
                         "@order": orderStrs as Any?,
                        ])
            }

            b.get("tag", Tag.parameter) { req in
                guard let songs = try? req.parameters.next(Tag.self).songs.all() else {
                    throw Abort.notFound
                }
                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try self.view.make("table.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON])
                        ])
            }


        }//group
    }
}

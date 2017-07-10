import Vapor

class BrowseRoutes: Routes {

    override func build(_ builder: RouteBuilder) throws {
        builder.group("b") { b in
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

            b.get("all") { req in
                let start = Date()
                var query = try Song.makeQuery().limit(1000)
                var orderStrs: [String]? = nil

                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = [by, order]
                    //TODO: Abstract ordering process
                    //TODO: Implement ordering for things like album/artist of a song.
                } else {
                    query = try query.sort("id", .ascending)
                }
                let formQuery = Date()
                let songs = try query.all()
                let issueQuery = Date()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                let jsonify = Date()
                let json = try Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON])
                let startRender = Date()
                let retval = try self.view.make("table.erb",
                        ["layout": "just_container.erb",
                         "@cols": Node(node: cols),
                         "@songs": json,
                         "@order": orderStrs as Any?,
                        ])
                let endRender = Date()
                print("FormQuery: \(formQuery - start), issueQuery: \(issueQuery - formQuery), jsonify: \(startRender - jsonify) render: \(endRender - startRender)")
                return retval
            }

            b.get("artist", Artist.parameter) { req in
                var query = try req.parameters.next(Artist.self).songs.makeQuery()

                var orderStrs: [String]? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = [by, order]
                } else {
                    query = try query.sort("album_id", .ascending).sort("disc", .ascending).sort("track", .ascending)
                }
                let songs = try query.all()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

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
                } else {
                    query = try query.sort("disc", .ascending).sort("track", .ascending)
                }
                let songs = try query.all()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

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
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

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

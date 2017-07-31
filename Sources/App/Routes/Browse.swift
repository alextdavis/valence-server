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

            b.get("stars") { req in
                return try self.view.make("split.erb",
                        ["layout": false,
                         "@stars": [1, 2, 3, 4, 5]
                        ])
            }

            b.get("all1") { req in
                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                var orderStrs: (String, String)? = nil

                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    orderStrs = (by, order)
                }
                let json = try Song.database!.raw("SELECT array_to_json(array_agg(row_to_json(a)))FROM" +
                        "(SELECT id, name, rank, track, time, rating, year," +
                        "        (SELECT array_to_json(array_agg(row_to_json(b)))" +
                        "         FROM (SELECT a.id, a.name " +
                        "               FROM artists AS a, songs AS s, artist_song AS ass" +
                        "               WHERE a.id = ass.artist_id AND s.id = ass.song_id AND s.id = songs.id" +
                        "              ) b)                         artists," +
                        "        album_id," +
                        "        (SELECT albums.name" +
                        "         FROM albums" +
                        "         WHERE albums.id = songs.album_id) album_name," +
                        "        (SELECT albums.sort_artist" +
                        "         FROM albums" +
                        "         WHERE albums.id = songs.album_id) album_sort_artist" +
                        "      FROM songs" +
                        "      WHERE rating = 5" +
                        "      ORDER BY album_sort_artist, year, album_name, disc, track" +
                        "     ) a")
                return try self.view.make("songs_show.erb",
                        ["layout": false,
                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
                         "@cols": Node(node: cols),
                         "@songs": json[0]?["array_to_json"],
                         "@order": orderStrs as Any?,
                        ])
            }

            b.get("all") { req in
                let start = Date()
                var query = try Song.makeQuery().limit(1000)
                var orderStrs: (String, String)? = nil

                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = (by, order)
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
                let startRender = Date()
                let retval = try TableRender.render(songs: songs, cols: cols, order: orderStrs)
                let endRender = Date()
                print("FormQuery: \(formQuery - start), issueQuery: \(issueQuery - formQuery), render: \(endRender - startRender)")
                return "<div class=\"table-container\">" + retval + "</div>"
            }

            b.get("artist", Artist.parameter) { req in
                var query = try req.parameters.next(Artist.self).songs.makeQuery()

                var orderStrs: (String, String)? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = (by, order)
                } else {
                    query = try query.sort("album_id", .ascending).sort("disc", .ascending).sort("track", .ascending)
                }
                let songs = try query.all()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

                let cols = ["rank", "track", "name", "tags", "time", "rating", "artists", "album"]
                return try TableRender.render(songs: songs, cols: cols, order: orderStrs)
//                return try self.view.make("table.erb",
//                        ["layout": false,
//                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
//                         "@cols": Node(node: cols),
//                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON]),
//                         "@order": orderStrs as Any?,
//                        ])
            }

            b.get("album", Album.parameter) { req in
                var query = try req.parameters.next(Album.self).songs.makeQuery()

                var orderStrs: (String, String)? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = (by, order)
                } else {
                    query = try query.sort("disc", .ascending).sort("track", .ascending)
                }
                let songs = try query.all()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try TableRender.render(songs: songs, cols: cols, order: orderStrs)
//                return try self.view.make("table.erb",
//                        ["layout": false,
//                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
//                         "@cols": Node(node: cols),
//                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON]),
//                         "@order": orderStrs as Any?,
//                        ])
            }

            b.get("tag", Tag.parameter) { req in
                guard let songs = try? req.parameters.next(Tag.self).songs.all() else {
                    throw Abort.notFound
                }
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

                let cols = ["rank", "track", "name", "time", "rating", "tags", "artists", "year"]
                return try TableRender.render(songs: songs, cols: cols, order: ("nothing", "nothing"))
//                return try self.view.make("table.erb",
//                        ["layout": false,
//                         "@all_tags": Node(node: Tag.all().map({ $0.name })),
//                         "@cols": Node(node: cols),
//                         "@songs": Node(node: songs.map({ $0.makeJSON(cols: cols) }) as [JSON])
//                        ])
            }

            b.get("star", Int.parameter) { req in
                let starNo = try req.parameters.next(Int.self)
                var query = try Song.makeQuery().filter("rating", .greaterThanOrEquals, starNo)

                var orderStrs: (String, String)? = nil
                if let by = req.query?["by"]?.string, let order = req.query?["order"]?.string {
                    query = try query.sort(by, (order == "desc") ? .descending : .ascending)
                    orderStrs = (by, order)
                } else {
                    query = try query.sort("album_id", .ascending).sort("disc", .ascending).sort("track", .ascending)
                }
                let songs = try query.all()
                Queuer.q.updateViewList(songs.map({ $0.id!.int! }))

                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                return try TableRender.render(songs: songs, cols: cols, order: orderStrs)
            }

        }//group
    }
}

import Vapor
import FluentProvider
import HTTP

final class Album: Model {
    let storage = Storage()
    var name: String
    var year: Int
    
    static func findOrCreate(name: String) throws -> Album {
        do {
            if let album = try Album.makeQuery().filter("name", name).first() {
                return album
            }
        }
        
        let album = Album(name: name)
        try album.save()
        return album
        
    }
    
    init(name: String, year: Int = 0) {
        self.name = name
        self.year = year
    }
    
    init(row: Row) throws {
        name = try row.get("name")
        year = try row.get("year")
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name", name)
        try row.set("year", year)
        return row
    }
    
    func artists() throws -> Siblings<Album, Artist, Pivot<Album, Artist>> {
        return siblings()
    }
    
    func songs() throws -> Children<Album, Song> {
        return children()
    }
    
    //    func tags() throws -> Siblings<Tag> {
    //        return try siblings()
    //    }
    
    func artwork() throws -> MediaAsset? {
        return try children().first()
    }
}

extension Album: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { albums in
            albums.id()
            albums.string("name")
            albums.int("year")
            albums.foreignId(for: MediaAsset.self, optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

@_exported import Vapor
import FluentProvider
import ErbProvider
import MySQLProvider

extension Droplet {
    public func setup() throws {
        try collection(Routes(self.view))
        try collection(PlayerRoutes(self.view))
        try collection(BrowseRoutes(self.view))
        try collection(QueueingRoutes(self.view))
        try collection(InfoRoutes(self.view))
    }
}

extension Config {
    public func setup() throws {
        try addProvider(FluentProvider.Provider.self)
        try addProvider(ErbProvider.Provider.self)
        try addProvider(MySQLProvider.Provider.self)
        
        preparations.append(MediaAsset.self)
        preparations.append(Artist.self)
        preparations.append(Album.self)
        preparations.append(Pivot<Album, Artist>.self)
        preparations.append(Song.self)
        preparations.append(Pivot<Artist, Song>.self)
        preparations.append(Tag.self)
        preparations.append(Pivot<Song, Tag>.self)
        preparations.append(Pivot<Artist, Tag>.self)
        preparations.append(Pivot<Album, Tag>.self)
    }
}

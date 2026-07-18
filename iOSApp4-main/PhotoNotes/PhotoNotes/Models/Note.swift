//
//  Note.swift
//  PhotoNotes
//
//  Created by Kenneth Plumstead on 2025-10-29.
//

import Foundation

/// Data model stored in Realtime Database.
/// We write as a Dictionary<[String: Any]> to avoid extra dependencies.
struct Note: Identifiable, Hashable {
    var id: String               // Firebase node key
    var title: String
    var body: String
    var imageURL: String?
    var createdAt: TimeInterval

    init(id: String = UUID().uuidString,
         title: String,
         body: String,
         imageURL: String? = nil,
         createdAt: TimeInterval = Date().timeIntervalSince1970) {
        self.id = id
        self.title = title
        self.body = body
        self.imageURL = imageURL
        self.createdAt = createdAt
    }

    var asDict: [String: Any] {
        [
            "title": title,
            "body": body,
            "imageURL": imageURL as Any,
            "createdAt": createdAt
        ]
    }

    static func fromDict(id: String, _ dict: [String: Any]) -> Note? {
        guard
            let title = dict["title"] as? String,
            let body = dict["body"] as? String,
            let createdAt = dict["createdAt"] as? TimeInterval
        else { return nil }
        let imageURL = dict["imageURL"] as? String
        return Note(id: id, title: title, body: body, imageURL: imageURL, createdAt: createdAt)
    }
}

//
//  Formatters.swift
//  PhotoNotes
//
//  Created by Kenneth Plumstead on 2025-10-29.
//

import Foundation

enum Formatters {
    static let dateTime: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}

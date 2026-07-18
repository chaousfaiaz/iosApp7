//
//  Formatters.swift
//  PhotoNotes
//
//  Created by MD FAIAZ on 2026-06-21.
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

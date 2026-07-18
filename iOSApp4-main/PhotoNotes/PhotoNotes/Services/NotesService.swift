//
//  NotesServices.swift
//  PhotoNotes
//
//  Created by Kenneth Plumstead on 2025-10-29.
//

import Foundation
import Combine
import FirebaseDatabase
import FirebaseStorage
import UIKit

// Handles all Firebase read/write operations for notes and images
final class NotesService: ObservableObject {

    private let db = Database
        .database(url: "https://photonotesapp-17082-default-rtdb.firebaseio.com")
        .reference()

    private let storage = Storage
        .storage(url: "gs://photonotesapp-17082.appspot.com")
        .reference()

    @Published var notes: [Note] = []

    // MARK: - Load notes
    func observeNotes() {
        db.child("notes").observe(.value) { [weak self] snapshot in
            guard let self else { return }

            guard let data = snapshot.value as? [String: Any] else {
                self.notes = []
                return
            }

            var loadedNotes: [Note] = []
            for (key, value) in data {
                if let map = value as? [String: Any],
                   let note = Note.fromDict(id: key, map) {
                    loadedNotes.append(note)
                }
            }

            self.notes = loadedNotes.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - Create or update a note
    func upsert(
        note: Note,
        image: UIImage?,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // If there's no image, just save the note
        guard let image else {
            db.child("notes/\(note.id)").setValue(note.asDict) { error, _ in
                if let error { completion(.failure(error)) }
                else { completion(.success(())) }
            }
            return
        }

        // Upload the image before saving the note
        let imageRef = storage.child("images/\(note.id).jpg")

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            completion(.failure(NSError(
                domain: "PhotoNotes",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image data."]
            )))
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadTask = imageRef.putData(data, metadata: metadata)

        uploadTask.observe(.progress) { snapshot in
            let fraction = snapshot.progress?.fractionCompleted ?? 0
            progress(fraction)
        }

        uploadTask.observe(.success) { [weak self] _ in
            guard let self else { return }

            imageRef.downloadURL { url, error in
                if let error { completion(.failure(error)); return }
                guard let url else {
                    completion(.failure(NSError(
                        domain: "PhotoNotes",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Download URL not found."]
                    )))
                    return
                }

                var updated = note
                updated.imageURL = url.absoluteString

                self.db.child("notes/\(updated.id)").setValue(updated.asDict) { error, _ in
                    if let error { completion(.failure(error)) }
                    else { completion(.success(())) }
                }
            }
        }

        uploadTask.observe(.failure) { snapshot in
            let error = snapshot.error ?? NSError(
                domain: "PhotoNotes",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Image upload failed."]
            )
            completion(.failure(error))
        }
    }

    // MARK: - Delete a note
    func delete(note: Note, completion: @escaping (Result<Void, Error>) -> Void) {
        db.child("notes/\(note.id)").removeValue { [weak self] error, _ in
            if let error { completion(.failure(error)); return }

            let imageRef = self?.storage.child("images/\(note.id).jpg")
            imageRef?.delete { _ in completion(.success(())) }
        }
    }
}

//
//  NoteEditorView.swift
//  PhotoNotes
//
//  Created by Kenneth Plumstead on 2025-10-29.
//

import SwiftUI
import Combine
import PhotosUI
import UIKit

struct NoteEditorView: View {
    @ObservedObject var service: NotesService
    let existing: Note?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var pickedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    @State private var isSaving = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Title", text: $title)
                    TextField("Body", text: $bodyText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Photo (optional)") {
                    if let image = pickedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(pickedImage == nil ? "Choose Photo" : "Replace Photo",
                              systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: pickerItem) { newItem in
                        Task {
                            guard let newItem else { return }
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let ui = UIImage(data: data) {
                                pickedImage = ui
                            }
                        }
                    }
                }

                if isSaving {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Uploading…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(.linear)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
            .navigationTitle(existing == nil ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let n = existing {
                    title = n.title
                    bodyText = n.body
                }
            }
        }
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        uploadProgress = 0

        var base = existing ?? Note(title: title, body: bodyText)
        base.title = title
        base.body = bodyText

        service.upsert(
            note: base,
            image: pickedImage,
            progress: { pct in
                DispatchQueue.main.async { self.uploadProgress = pct }
            },
            completion: { result in
                DispatchQueue.main.async {
                    self.isSaving = false
                    switch result {
                    case .success:
                        self.dismiss()
                    case .failure(let err):
                        self.errorMessage = err.localizedDescription
                    }
                }
            }
        )
    }
}

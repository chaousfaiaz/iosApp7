//
//  NotesListView.swift
//  PhotoNotes
//
//  Created by Kenneth Plumstead on 2025-10-29.
//

import SwiftUI
import Combine

struct NotesListView: View {
    @StateObject private var service = NotesService()
    @State private var showEditor = false
    @State private var selected: Note?

    var body: some View {
        NavigationStack {
            Group {
                if service.notes.isEmpty {
                    // iOS 17+: nice built-in empty state
                    ContentUnavailableView("No Notes Yet",
                                           systemImage: "note.text",
                                           description: Text("Tap + to create your first note."))
                } else {
                    List {
                        ForEach(service.notes) { note in
                            Button {
                                selected = note
                                showEditor = true
                            } label: {
                                HStack(spacing: 12) {
                                    if let urlString = note.imageURL,
                                       let url = URL(string: urlString) {
                                        AsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "photo")
                                            .frame(width: 44, height: 44)
                                            .foregroundStyle(.secondary)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(note.title).font(.headline)
                                        Text(note.body)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .onDelete { indexSet in
                            indexSet
                                .map { service.notes[$0] }
                                .forEach { note in
                                    service.delete(note: note) { _ in }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Photo Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selected = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Note")
                }
            }
            .onAppear { service.observeNotes() }
            .sheet(isPresented: $showEditor) {
                NoteEditorView(service: service, existing: selected)
            }
        }
    }
}

//
//  PhotoMarkerView.swift
//  CircuitMap
//
//  Feature 11 — Photo / Marker. Capture or pick photos of the panel / cable
//  routes with captions, stored locally via PhotoStore.
//

import SwiftUI

struct PhotoMarkerView: View {
    @EnvironmentObject var store: AppStore
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var pendingImage: UIImage?
    @State private var caption = ""
    @State private var showCaptionSheet = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            CircuitBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Space.m) {
                    HStack(spacing: 10) {
                        PillButton(title: "Camera", systemImage: "camera.fill") {
                            pickerSource = .camera; showPicker = true
                        }
                        PillButton(title: "Library", systemImage: "photo.fill", tint: Theme.circuit) {
                            pickerSource = .photoLibrary; showPicker = true
                        }
                    }

                    if store.photos.isEmpty {
                        Card {
                            EmptyState(icon: "photo.on.rectangle.angled",
                                       title: "No photos",
                                       message: "Snap the panel or cable routes and add captions for your records.")
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.photos) { photo in
                                photoCell(photo)
                            }
                        }
                    }
                }
                .padding(Theme.Space.m)
            }
        }
        .navigationBarTitle("Photos & Markers", displayMode: .inline)
        .sheet(isPresented: $showPicker) {
            ImagePicker(sourceType: pickerSource) { image in
                pendingImage = image
                caption = ""
                // present caption entry after the picker dismisses
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showCaptionSheet = true }
            }
        }
        .sheet(isPresented: $showCaptionSheet) { captionSheet }
    }

    private func photoCell(_ photo: PhotoMarker) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let img = PhotoStore.shared.load(photo.imageRef) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle().fill(Theme.bgDeep).frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundColor(Theme.textMuted))
            }
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(photo.caption.isEmpty ? "Untitled" : photo.caption)
                        .font(Theme.caption(12)).foregroundColor(Theme.text).lineLimit(1)
                    Text(Fmt.dateStr(photo.date)).font(Theme.caption(9)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Button(action: { store.deletePhoto(photo) }) {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(Theme.textMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(8)
        }
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private var captionSheet: some View {
        NavigationView {
            ZStack {
                CircuitBackground()
                VStack(spacing: Theme.Space.m) {
                    if let img = pendingImage {
                        Image(uiImage: img).resizable().scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            FieldLabel(text: "Caption")
                            ThemedTextField(placeholder: "e.g. Main panel — left bank", text: $caption)
                        }
                    }
                    PrimaryButton(title: "Save Photo", systemImage: "checkmark.circle.fill") { savePhoto() }
                    Spacer()
                }
                .padding(Theme.Space.m)
            }
            .navigationBarTitle("Add Caption", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                pendingImage = nil; showCaptionSheet = false
            }.foregroundColor(Theme.textSecond))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func savePhoto() {
        guard let img = pendingImage, let ref = PhotoStore.shared.save(img) else {
            showCaptionSheet = false; return
        }
        store.addPhoto(PhotoMarker(caption: caption.trimmingCharacters(in: .whitespaces), imageRef: ref))
        pendingImage = nil
        showCaptionSheet = false
    }
}

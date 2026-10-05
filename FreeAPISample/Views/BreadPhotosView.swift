import SDWebImageSwiftUI
import SwiftUI

struct BreedPhotosView: View {
    @StateObject private var viewModel: BreedPhotosViewModel

    init(breed: Breed) {
        _viewModel = StateObject(wrappedValue: BreedPhotosViewModel(breed: breed))
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorRow(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            }

            ForEach(viewModel.images, id: \.self) { url in
                WebImage(url: url)
                    .placeholder {
                        ZStack {
                            Rectangle().fill(.quaternary)
                            ProgressView()
                        }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle(viewModel.breed.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading && viewModel.images.isEmpty {
                ProgressView("Fetching photos…")
            } else if viewModel.images.isEmpty && viewModel.errorMessage == nil {
                ContentUnavailableView("No photos", systemImage: "pawprint")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("New photos", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
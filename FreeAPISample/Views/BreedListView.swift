import SwiftUI

struct BreedListView: View {
    @ObservedObject var viewModel: BreedListViewModel

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorRow(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            }

            ForEach(viewModel.visibleBreeds) { breed in
                NavigationLink(value: breed) {
                    BreedRow(breed: breed)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dog Breeds")
        .navigationDestination(for: Breed.self) { breed in
            BreedPhotosView(breed: breed)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search breeds")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { viewModel.shuffle() }
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .disabled(viewModel.breeds.isEmpty)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.breeds.isEmpty {
                ProgressView("Loading breeds…")
            } else if viewModel.visibleBreeds.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

private struct BreedRow: View {
    let breed: Breed

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(breed.displayName)
                .font(.headline)
            Text(breed.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

struct ErrorRow: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Something went wrong")
                    .font(.subheadline.bold())
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Retry", action: retry)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
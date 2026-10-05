import Alamofire
import Foundation

@MainActor
final class BreedListViewModel: ObservableObject {
    @Published private(set) var breeds: [Breed] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    var visibleBreeds: [Breed] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return breeds }
        return breeds.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private let service: DogService
    private var request: DataRequest?

    init(service: DogService = DogService()) {
        self.service = service
    }

    func load() async {
        request?.cancel()
        isLoading = true
        errorMessage = nil

        do {
            breeds = try await service.allBreeds()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func shuffle() {
        breeds.shuffle()
    }
}
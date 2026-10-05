import Alamofire
import Foundation

@MainActor
final class BreedPhotosViewModel: ObservableObject {
    let breed: Breed

    @Published private(set) var images: [URL] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: DogService
    private let imageCount: Int
    private var request: DataRequest?

    init(breed: Breed, imageCount: Int = 12, service: DogService = DogService()) {
        self.breed = breed
        self.imageCount = imageCount
        self.service = service
    }

    func load() async {
        request?.cancel()
        isLoading = true
        errorMessage = nil

        do {
            images = try await service.randomImages(for: breed, count: imageCount)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
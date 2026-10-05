import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            BreedPhotosView(breed: Breed(name: "corgi", subbreeds: ["cardigan"]))
        }
    }
}

#Preview {
    ContentView()
}
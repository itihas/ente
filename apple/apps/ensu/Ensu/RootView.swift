import SwiftUI

struct RootView: View {
    let assetStoreTask: Task<AssetStore, Never>
    @State private var chatModel: ChatViewModel?

    var body: some View {
        ZStack {
            EnsuColor.backgroundBase
                .ignoresSafeArea()

            if let chatModel {
                HomeView(chatModel: chatModel)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(EnsuColor.action)
        .task {
            guard chatModel == nil else { return }
            let assetStore = await assetStoreTask.value
            chatModel = await ChatViewModel(assetStore: assetStore)
        }
    }
}

//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Samuel Pinheiro Junior on 16/07/20.
//  Copyright © 2020 Samuel Pinheiro Junior. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let pallet = "⭐️☁️🍎🌎🥨⚾️"
    
    @Published private var emojiArt: EmojiArt
    
    private var autoSaveCancelable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultKey)) ?? EmojiArt()
        autoSaveCancelable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.jason, forKey: defaultKey)
        }
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    @Published var steadyStatezoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    //MARK - Intent(s)
    
    func addEmoji(_ emoji:String, at location: CGPoint, size: CGFloat ) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moviEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    private var fetchImageCancellable: AnyCancellable?
    func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map{data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \.backgroundImage , on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

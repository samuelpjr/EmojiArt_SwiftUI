//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Samuel Pinheiro Junior on 16/07/20.
//  Copyright © 2020 Samuel Pinheiro Junior. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var choosenPallet: String = ""
    
    init(document: EmojiArtDocument) {
        self.document = document
        _choosenPallet = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $choosenPallet)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(choosenPallet.map{ String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
            }
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZom(in: geometry.size))
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                                .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(self.document.$backgroundImage) { image in
                    self.zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                        location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                        location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                        return self.drop(providers: providers, at: location)
                }
            .navigationBarItems(trailing: Button(action: {
                if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                    self.confirmBackgroundPast = true
                } else {
                    self.explainBackgroundPast = true
                }
            }, label: {
                Image(systemName: "doc.on.clipboard").imageScale(.large)
                    .alert(isPresented: self.$explainBackgroundPast) {
                        return Alert(
                            title: Text("Past the url"),
                            message: Text("Copy and past the url"),
                            dismissButton: .default(Text("Ok"))
                        )
                    }
                
                }))}
                .zIndex(-1)
        }
        .alert(isPresented: self.$confirmBackgroundPast) {
            return Alert(
                title: Text("Past the url"),
                message: Text("Replace your background with\(UIPasteboard.general.url?.absoluteString ?? "nothing")?."),
                primaryButton: .default(Text("Ok")) {
                    self.document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    @State private var explainBackgroundPast = false
    @State private var confirmBackgroundPast = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        (document.steadyStatezoomScale * gestureZoomScale)
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { lastestGestureScale, gestureZoomScale, transactions in
                gestureZoomScale = lastestGestureScale
            }
            .onEnded { finalGestureScale in
                self.document.steadyStatezoomScale *= finalGestureScale
            }
    }
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset){ lastestDragGestureValue, gesturePanOffset, transactions in
                gesturePanOffset = lastestDragGestureValue.translation / self.zoomScale
        }
            .onEnded { finalGestureValue in
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalGestureValue.translation / self.zoomScale)
            }
    }
    
    private func doubleTapToZom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = .zero
            document.steadyStatezoomScale = min(hZoom, vZoom)
        }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * self.zoomScale, y: location.y * self.zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + self.panOffset.width, y: location.y + self.panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool{
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("droped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}

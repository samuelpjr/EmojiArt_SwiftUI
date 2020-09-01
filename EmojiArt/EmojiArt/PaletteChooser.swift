//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Samuel Pinheiro Junior on 30/07/20.
//  Copyright © 2020 Samuel Pinheiro Junior. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var showPalletEditor = false
    
    @Binding var chosenPalette: String
    
    var body: some View {
        HStack{
            Stepper(onIncrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, onDecrement: {
                self.chosenPalette = self.document.palette(before: self.chosenPalette)
            }, label: {EmptyView()})
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    self.showPalletEditor = true
            }
                .popover(isPresented: $showPalletEditor) {
                    PalettEditor(chosenPalette: self.$chosenPalette, isShowing: self.$showPalletEditor)
                        .environmentObject(self.document)
                    .frame(minWidth: 300, minHeight: 500)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PalettEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @State private var paletteName = ""
    @State private var emojisToAdd = ""
    
    var body: some View {
        VStack(spacing: 0){
            ZStack{
                Text("Palette Editor").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {
                        self.isShowing = false
                    }, label: {Text("Done")}).padding()
                }
            }
            
            Divider()
            Form{
                Section {
                    TextField("Palette Name:", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                        }
                    })
                    TextField("Add Emoji:", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            self.chosenPalette = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPalette)
                            self.emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove emoji")) {
                    Grid(chosenPalette.map{String($0)}, id: \.self) { emoji in
                        Text(emoji).font(Font.system(size: self.fontSize))
                            .onTapGesture {
                                self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                        
                        }
                    }
                    .frame(height: self.height)
                }
            }
        }
        .onAppear{ self.paletteName = self.document.paletteNames[self.chosenPalette] ?? "" }
    }
    
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}

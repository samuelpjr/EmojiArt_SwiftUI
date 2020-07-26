//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Samuel Pinheiro Junior on 26/07/20.
//  Copyright © 2020 Samuel Pinheiro Junior. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}

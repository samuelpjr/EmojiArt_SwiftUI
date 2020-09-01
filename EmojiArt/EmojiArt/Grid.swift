//
//  Grid.swift
//  Memorizable
//
//  Created by Samuel Pinheiro Junior on 08/07/20.
//  Copyright © 2020 Samuel Pinheiro Junior. All rights reserved.
//

import SwiftUI

extension Grid where Item: Identifiable, ID == Item.ID {
    init (_ items: [Item], viewForItem: @escaping (Item) -> ItemForView) {
        self.init(items, id: \Item.id, viewForItem: viewForItem)
    }
}

struct Grid<Item, ID, ItemForView>: View where ID: Hashable, ItemForView: View {
    private var items: [Item]
    private var id: KeyPath<Item, ID>
    private var viewForItem: (Item) -> ItemForView
    
    init (_ item: [Item],id: KeyPath<Item, ID>, viewForItem: @escaping (Item) -> ItemForView) {
        self.items = item
        self.id = id
        self.viewForItem = viewForItem
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.body(for: GridLayout(itemCount: self.items.count, in: geometry.size) )
        }
    }
    
    private func body(for layout: GridLayout) -> some View {
        ForEach(items, id: id) { item in
            self.body(for: item, in: layout)
        }
    }
    
    private func body(for item: Item, in layout: GridLayout) -> some View {
        let index = items.firstIndex(where: { item[keyPath: id] == $0[keyPath: id] })
        return viewForItem(item)
            .frame(width: layout.itemSize.width, height: layout.itemSize.height)
            .position(layout.location(ofItemAt: index!))
        
    }
}

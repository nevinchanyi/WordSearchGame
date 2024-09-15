//
//  WelcomeView.swift
//  WordSearchGame
//
//  Created by Kostiantyn Nevinchanyi on 9/15/24.
//

import SwiftUI

struct WelcomeView: View {
    
    @State private var word = ""
    @State private var words: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(text: $word) {
                        Text("E.g.: Strawberry, car, etc.")
                    }
                    Button(action: {
                        add(word: word)
                    }, label: {
                        Text("Add Word")
                    })
                    .disabled(
                        words.contains(word.uppercased()) ||
                        word.isEmpty ||
                        word.contains(" ") ||
                        word.count > 8
                    )
                } header: {
                    Text("Word")
                } footer: {
                    Text("The added word appears in the word search game. The word MUST be unique, must not have spaces, and less than 8 charachters.")
                }
                
                Section {
                    NavigationLink {
                        WordGameView(words: words)
                    } label: {
                        Text("Start Game")
                            .bold()
                            .foregroundStyle(Color.blue)
                    }
                    .disabled(words.count != 5)
                } footer: {
                    Text("Choose 5 words to start the game.")
                }
                
                Section {
                    if words.isEmpty {
                        Text("No words. Add your first word.")
                            .foregroundStyle(Color.red.opacity(0.7))
                    }
                    ForEach(Array(words), id: \.self) { word in
                        Text(word)
                    }
                    .onDelete(perform: delete)
                } header: {
                    Text("Added Words")
                } footer: {
                    Text("The list of words for the game.")
                }
            }
            .navigationTitle("Word Search")
        }
    }
    func add(word: String) {
        words.append(word.uppercased())
        self.word = ""
    }
    
    func delete(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
    }
}

#Preview {
    WelcomeView()
}

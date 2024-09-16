//
//  WelcomeView.swift
//  WordSearchGame
//
//  Created by Kostiantyn Nevinchanyi on 9/15/24.
//

import SwiftUI

struct WelcomeView: View {
    
    @State private var words: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    
                    Button(action: {
                        getWords()
                    }, label: {
                        Text("Generate Words")
                            .bold()
                    })
                } header: {
                    Text("Words")
                } footer: {
                    Text("Generates 5 random words for game.")
                }
                
                Section {
                    NavigationLink {
                        WordGameView(words: words)
                    } label: {
                        Text("Start Game")
                            .bold()
                            .foregroundStyle(Color.blue)
                    }
                    .disabled(words.isEmpty)
                }
                
                Section {
                    if words.isEmpty {
                        Text("No words.")
                            .foregroundStyle(Color.red.opacity(0.7))
                    }
                    ForEach(Array(words), id: \.self) { word in
                        Text(word)
                    }
                } header: {
                    Text("Word list")
                } footer: {
                    Text("The list of words for the game.")
                }
            }
            .navigationTitle("Word Search")
        }
    }
    
    func getWords() {
        words = []
        for _ in 0..<5 {
            words.append(wordArray.randomElement() ?? "")
        }
    }
}

#Preview {
    WelcomeView()
}

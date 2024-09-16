//
//  ContentView.swift
//  WordSearchGame
//
//  Created by Kostiantyn Nevinchanyi on 9/15/24.
//

import SwiftUI

struct WordGameView: View {
    
    var words: [String]
    
    @StateObject private var viewModel = ContentViewModel()
    
    @Environment(\.dismiss) var dismiss
        
    var body: some View {
        VStack {
            Text("Words")
                .bold()
                .onAppear {
                    viewModel.generateGrid(with: words)
                }
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.words, id: \.text) { word in
                    Text(word.text)
                        .strikethrough(word.isFound)
                }
            }
            .padding()
            
            HStack {
                Text("Word Search:")
                    .bold()
                Text(viewModel.findingWord)
                    .bold()
            }
            
            VStack(spacing: 0) {
                ForEach(0..<viewModel.grid.count, id: \.self) { arrayIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<viewModel.grid[arrayIndex].count, id: \.self) { letterIndex in
                            HStack {
                                Spacer()
                                Text(String(viewModel.grid[arrayIndex][letterIndex].letter))
                                    .foregroundColor(Color.black)
                                    .frame(width: 26, height: 26)
                                    .background(
                                        GeometryReader(content: { geometry in
                                            Circle()
                                                .foregroundColor(
                                                    viewModel.isLetterInRoute(arrayIndex: arrayIndex, letterIndex: letterIndex) ?
                                                    Color.purple.opacity(0.6) :
                                                        viewModel.isPossibleMoveRoute(arrayIndex: arrayIndex, letterIndex: letterIndex) ?
                                                    Color.purple.opacity(0.3) :
                                                        Color.gray.opacity(0.2)
                                                )
                                                .onAppear {
                                                    viewModel.setup(arrayIndex: arrayIndex,
                                                                    letterIndex: letterIndex,
                                                                    frame: geometry.frame(in: .named("global")))
                                                }
                                        })
                                        
                                    )
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            Spacer()
        }
        .coordinateSpace(name: "global")
        .onTouch(type: .all, perform: viewModel.updateLocation)
        .overlay {
            viewModel.words.allSatisfy({ $0.isFound }) ?
            VStack {
                Text("Yahoo!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundStyle(Color.green)
                Text("You've completed the game in \(gameDuration)")
                
                Button {
                    dismiss()
                } label: {
                    Text("Go back")
                        .bold()
                        .foregroundStyle(Color.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .foregroundColor(.blue)
                        )
                }
            }
            .padding()
            .background(
                Material.ultraThin
            )
            : nil
        }
    }
    
    private var gameDuration: String {
        Duration.seconds(Int(viewModel.startTime.distance(to: viewModel.finishTime))).formatted(
            .time(pattern: .minuteSecond)
        )
    }
}


#Preview {
    WordGameView(words: ["CAT", "DOG", "DONKEY"])
}

final class ContentViewModel: ObservableObject {
    
    
    @Published var grid: [[Label]] = []
    
    @Published var words = [Word]() {
        didSet {
            if words.allSatisfy({ $0.isFound }) {
                finishTime = Date()
            }
        }
    }
    @Published var findingWord = ""
    
    var wordLocations: [WordLocation] = []
    var fingerInFrame: CGRect = .zero
    @Published var route: [(Int, Int)] = []
    @Published var possibileMoveRoute: [(Int, Int)] = []
    @Published var startTime = Date()
    @Published var finishTime = Date()
    
    // Words generation
    func generateGrid(with wordsArray: [String]) {
        let wordsArray = wordsArray.compactMap({ Word(text: $0) })
        self.words = wordsArray
        createGrid(words: wordsArray)
        startTime = Date()
    }
    
    func updateLocation(_ cgPoint: CGPoint, touchType: TouchLocatingView.TouchType) {
        if touchType == .ended {
            if let index = words.firstIndex(where: {
                $0.text.lowercased() == findingWord.lowercased()
            }) {
                withAnimation {
                    words[index].isFound = true
                }
                resetFindingWord()
            } else {
                resetFindingWord()
            }
        } else if touchType == .moved || touchType == .started,
                  !fingerInFrame.contains(cgPoint),
                  let wordLocation = wordLocations.first(where: {
                      $0.frame.contains(cgPoint)
                  }),
                  possibileMoveRoute.isEmpty || possibileMoveRoute.contains(where: { $0.0 == wordLocation.arrayIndex && $0.1 == wordLocation.letterIndex })
        {
            
            fingerInFrame = wordLocation.frame
            highlightCurrentSelection(wordLocation.arrayIndex, wordLocation.letterIndex)
        }
        
    }
    
    func isLetterInRoute(arrayIndex: Int, letterIndex: Int) -> Bool {
        route.contains(where: { $0.0 == arrayIndex && $0.1 == letterIndex })
    }
    
    func isPossibleMoveRoute(arrayIndex: Int, letterIndex: Int) -> Bool {
        possibileMoveRoute.contains(where: { $0.0 == arrayIndex && $0.1 == letterIndex })
    }
    
    func resetFindingWord() {
        fingerInFrame = .zero
        findingWord = ""
        route = []
        possibileMoveRoute = []
    }
    
    func highlightCurrentSelection(_ arrayIndex: Int, _ letterIndex: Int) {
        if let index = route.firstIndex(where: { $0.0 == arrayIndex && $0.1 == letterIndex }) {
            if index == route.count - 2 {
                route.remove(at: route.count - 1)
            } else {
                route.remove(at: index)
            }
        } else {
            route.append((arrayIndex, letterIndex))
        }
        
        findingWord = route.reduce(into: "", {
            $0 += String(grid[$1.0][$1.1].letter)
        })
        
        generatePossibleSelection()
    }
    
    func generatePossibleSelection() {
        if route.count == 1, let first = route.first {
            possibileMoveRoute = [
                (first.0 - 1, first.1),
                (first.0 - 1, first.1 - 1),
                (first.0 - 1, first.1 + 1),
                (first.0 + 1, first.1),
                (first.0 + 1, first.1 - 1),
                (first.0 + 1, first.1 + 1),
                (first.0, first.1 - 1),
                (first.0, first.1 + 1)
            ]
        } else if route.count == 2 {
            let direction = findDirection()
            
            possibileMoveRoute = [(route.first!.0, route.first!.1)]
            
            for index in 0..<8 {
                possibileMoveRoute.append(
                    (possibileMoveRoute.last!.0 + direction.movement.x, possibileMoveRoute.last!.1 + direction.movement.y)
                )
            }
        }
    }
    
    func findDirection() -> PlacementType {
        guard let last = route.last, let first = route.first else { return .leftRight }
        let difference = (last.0 - first.0, last.1 - first.1)
        return PlacementType.allCases.first(where: { $0.movement == difference }) ?? .leftRight
    }
    
    func createGrid(words: [Word]) {
        let wordSearch = WordSearch()
        wordSearch.words = words
        wordSearch.makeGrid()
        DispatchQueue.main.async {
            self.grid = wordSearch.labels
        }
    }
    
    func setup(arrayIndex: Int, letterIndex: Int, frame: CGRect) {
        let wordLocation = WordLocation(arrayIndex: arrayIndex,
                                        letterIndex: letterIndex,
                                        frame: frame,
                                        label: grid[arrayIndex][letterIndex])
        wordLocations.append(
            wordLocation
        )
    }
    
    struct WordLocation {
        var arrayIndex: Int
        var letterIndex: Int
        var frame: CGRect
        var label: Label
    }
}

struct Word {
    var text: String
    var isFound: Bool = false
}

enum PlacementType: CaseIterable {
    case leftRight
    case rightLeft
    case upDown
    case downUp
    case topLeftBottomRight
    case topRightBottomLeft
    case bottomLeftTopRight
    case bottomRightTopLeft

    var movement: (x: Int, y: Int) {
        switch self {
        case .leftRight:
            return (1, 0)
        case .rightLeft:
            return (-1, 0)
        case .upDown:
            return (0, 1)
        case .downUp:
            return (0, -1)
        case .topLeftBottomRight:
            return (1, 1)
        case .topRightBottomLeft:
            return (-1, 1)
        case .bottomLeftTopRight:
            return (1, -1)
        case .bottomRightTopLeft:
            return (-1, -1)
        }
    }
}


enum Difficulty {
    case easy
    case medium
    case hard

    var placementTypes: [PlacementType] {
        switch self {
        case .easy:
            return [.leftRight, .upDown].shuffled()

        case .medium:
            return [.leftRight, .rightLeft, .upDown, .downUp].shuffled()

        case .hard:
            return PlacementType.allCases.shuffled()
        }
    }
}


class Label {
    var letter: Character = " "
}


class WordSearch {
    var words = [Word]()
    var gridSize = 8

    var labels = [[Label]]()
    var difficulty = Difficulty.hard
    var numberOfPages = 10

    let allLetters = (65...90).map { Character(Unicode.Scalar($0)) }

    func makeGrid() {
        labels = (0 ..< gridSize).map { _ in
            (0 ..< gridSize).map { _ in Label() }
        }

        _ = placeWords()
        fillGaps()
        printGrid()
    }

    private func fillGaps() {
        for column in labels {
            for label in column {
                if label.letter == " " {
                    label.letter = allLetters.randomElement()!
                }
            }
        }
    }

    func printGrid() {
        for column in labels {
            for row in column {
                print(row.letter, terminator: "")
            }

            print("")
        }
    }

    private func labels(fromX x: Int, y: Int, word: String, movement: (x: Int, y: Int)) -> [Label]? {
        var returnValue = [Label]()

        var xPosition = x
        var yPosition = y

        for letter in word {
            let label = labels[xPosition][yPosition]

            if label.letter == " " || label.letter == letter {
                returnValue.append(label)
                xPosition += movement.x
                yPosition += movement.y
            } else {
                return nil
            }
        }

        return returnValue
    }

    private func tryPlacing(_ word: String, movement: (x: Int, y: Int)) -> Bool {
        let xLength = (movement.x * (word.count - 1))
        let yLength = (movement.y * (word.count - 1))
        
        let rows = (0 ..< gridSize).shuffled()
        let cols = (0 ..< gridSize).shuffled()
        
        for row in rows {
            for col in cols {
                let finalX = col + xLength
                let finalY = row + yLength
                
                if finalX >= 0 && finalX < gridSize && finalY >= 0 && finalY < gridSize {
                    if let returnValue = labels(fromX: col, y: row, word: word, movement: movement) {
                        for (index, letter) in word.enumerated() {
                            returnValue[index].letter = letter
                        }
                        
                        return true
                    }
                }
            }
        }
        
        return false
    }

    private func place(_ word: Word) -> Bool {
        let formattedWord = word.text.replacingOccurrences(of: " ", with: "").uppercased()

        return difficulty.placementTypes.contains {
            tryPlacing(formattedWord, movement: $0.movement)
        }
    }

    private func placeWords() -> [Word] {
        return words.shuffled().filter(place)
    }
}


struct TouchLocatingView: UIViewRepresentable {
    struct TouchType: OptionSet {
        let rawValue: Int

        static let started = TouchType(rawValue: 1 << 0)
        static let moved = TouchType(rawValue: 1 << 1)
        static let ended = TouchType(rawValue: 1 << 2)
        static let all: TouchType = [.started, .moved, .ended]
    }

    var onUpdate: (CGPoint, TouchLocatingView.TouchType) -> Void

    var types = TouchType.all

    var limitToBounds = true

    func makeUIView(context: Context) -> TouchLocatingUIView {
        let view = TouchLocatingUIView()
        view.onUpdate = onUpdate
        view.touchTypes = types
        view.limitToBounds = limitToBounds
        return view
    }

    func updateUIView(_ uiView: TouchLocatingUIView, context: Context) {
    }

    class TouchLocatingUIView: UIView {
        var onUpdate: ((CGPoint, TouchLocatingView.TouchType) -> Void)?
        var touchTypes: TouchLocatingView.TouchType = .all
        var limitToBounds = true

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = true
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            isUserInteractionEnabled = true
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            send(location, forEvent: .started)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            send(location, forEvent: .moved)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            send(location, forEvent: .ended)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            send(location, forEvent: .ended)
        }

        func send(_ location: CGPoint, forEvent event: TouchLocatingView.TouchType) {
            guard touchTypes.contains(event) else {
                return
            }

            if limitToBounds == false || bounds.contains(location) {
                onUpdate?(CGPoint(x: round(location.x), y: round(location.y)), event)
            }
        }
    }
}

struct TouchLocater: ViewModifier {
    var type: TouchLocatingView.TouchType = .all
    var limitToBounds = true
    let perform: (CGPoint, TouchLocatingView.TouchType) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                TouchLocatingView(onUpdate: perform, types: type, limitToBounds: limitToBounds)
            )
    }
}

extension View {
    func onTouch(type: TouchLocatingView.TouchType = .all, limitToBounds: Bool = true, perform: @escaping (CGPoint, TouchLocatingView.TouchType) -> Void) -> some View {
        self.modifier(TouchLocater(type: type, limitToBounds: limitToBounds, perform: perform))
    }
}


struct WordCoordinate {
    var arrayIndex: Int
    var letterIndex: Int
    
    func getAllDirections(_ arrayIndex: Int, _ letterIndex: Int) -> [WordCoordinate] {
        [
            WordCoordinate(arrayIndex: arrayIndex - 1, letterIndex: letterIndex),
            WordCoordinate(arrayIndex: arrayIndex + 1, letterIndex: letterIndex)
        ]
    }
    
    func getIndicies(_ arrayIndex: Int, _ letterIndex: Int) -> WordCoordinate {
        return WordCoordinate(arrayIndex: arrayIndex, letterIndex: letterIndex)
    }
}

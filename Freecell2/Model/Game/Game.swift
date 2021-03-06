//
//  Game.swift
//  Freegraveyard2
//
//  Created by gary on 15/08/2017.
//  Copyright © 2017 Gary Kerr. All rights reserved.
//

class Game {
    
    enum State {
        case notStarted
        case playing
        case done
    }
    
    // MARK: - Properties
    
    private let graveyards: [Graveyard]
    private let hands: [Hand]
    let decks: [Deck]
    
    private var moves = MoveHistory()
    private let deckConfig: [(Int, Int)] = [(0, 60), (7, 13), (14, 20), (21, 27), (28, 33), (34, 39), (40, 45), (46, 51)]
    
    
    // MARK: - Computed properties
    
    var isGameOver: Bool {
        return false
    }
    
    
    var state: State {
        if moves.noMovesMade {
            return .notStarted
        }
        return isGameOver ? .done : .playing
    }
    
    
    var lastMove: Move? {
        return moves.lastMove
    }
    
    
    // MARK: - Initialisers
    
    init() {
        graveyards = [Graveyard(), Graveyard(), Graveyard()]
        hands = [Hand(), Hand(), Hand(), Hand(), Hand(), Hand(), Hand()]
        decks = (0 ... 1).map({ _ in Deck() })
        self.new()
    }
    
    
    // MARK: - Methods
    
    func new() {
        let cards = Card.deck().shuffled()
        graveyards.forEach({ $0.reset() })
        hands.forEach({ $0.reset() })
        for (deck, _) in zip(decks, deckConfig) {
           // deck.cards = Array(cards[config.0 ... config.1])
            deck.cards = cards
        }
        moves.clear()
    }
    
    
    func canMove(card: Card) -> Bool {
//        guard let location = location(from: card) else {
//            return false
//        }
//        switch location {
//        case .graveyard:
//            return true
//        case .hand:
//            return true
//        case .deck(let value):
//            let deck = decks[value]
//           return deck.isBottom(card: card)
//
//    }
        return true
    }
    
    func move(from fromLocation: Location, to toLocation: Location) throws {
        guard let card = card(at: fromLocation) else {
            throw GameError.invalidMove
        }
        try move(card: card, to: toLocation)
        
        moves.add(move: Move(fromLocation: fromLocation, toLocation: toLocation))
        
        switch fromLocation {
        case .deck(let value):
            let deck = decks[value]
            deck.removeBottom()
        case .graveyard(let value):
            let graveyard = graveyards[value]
            graveyard.removeCard()
        case .hand(let value):
            let hand = hands[value]
            hand.state = .empty
        }
    }
    
    
//    func quickMove(from location: Location) throws -> Location {
//        switch location {
//        case .hand:
//            let newLocation = try moveToHand(from: location)
//            return newLocation
//        case .graveyard:
//            do {
//                let newLocation = try moveToHand(from: location)
//                return newLocation
//            }
//        case .deck:
//            do {
//                let newLocation = try moveToHand(from: location)
//                return newLocation
//            } catch {}
//            do {
//                let newLocation = try moveToGraveyard(from: location)
//                return newLocation
//            }
//        }
//    }
    
    
    func moveToHand(from location: Location) throws -> Location {
        guard let card = card(at: location) else {
            throw GameError.invalidMove
        }
        for (i, hand) in hands.enumerated() {
            switch hand.state {
            case .empty:
                    let newLocation = Location.hand(i)
                    try move(from: location, to: newLocation)
                    hand.state = .card(card)
                    return newLocation
                
            case .card( _):
                throw GameError.invalidMove
            }
        }
        return location
    }
    
    
    func moveToGraveyard(from location: Location) throws -> Location {
        //        guard let _ = card(at: location) else {
        //            throw GameError.invalidMove
        //        }
        for (i, _) in graveyards.enumerated() {
    
                let newLocation = Location.graveyard(i)
                try move(from: location, to: newLocation)
            return newLocation
        }
        return location
    }
    
    
    func location(from card: Card) -> Location? {
        for (i, graveyard) in graveyards.enumerated() {
            if graveyard.contains(card: card) {
                return Location.graveyard(i)
            }
        }
        for (i, hand) in hands.enumerated() {
            if hand.contains(card: card) {
                return Location.hand(i)
            }
        }
        for (i, deck) in decks.enumerated() {
            if deck.contains(card: card) {
                return Location.deck(i)
            }
        }
        return nil
    }
    
    
    func undo(move: Move) -> Card? {
        print("game", undo)
        guard let card = card(at: move.toLocation) else { return nil }
        
        //        moves.undo()
        return card
    }
    
    
    // MARK: - Private
    
    private func card(at location: Location) -> Card? {
        switch location {
        case .graveyard(let value):
            switch graveyards[value].state {
            case .empty: return nil
            case .card(let card): return card
            }
        case .hand(let value):
            switch hands[value].state {
            case .empty: return nil
            case .card(let card): return card
            }
        case .deck(let value):
            return decks[value].bottomCard
        }
    }
    
    
    private func move(card: Card, to location: Location) throws {
        switch location {
        case .graveyard(let value):
            let graveyard = graveyards[value]
            try graveyard.add(card: card)
        case .hand(let value):
            let hand = hands[value]
            try hand.add(card: card)
        case .deck(let value):
            let deck = decks[value]
            try deck.add(card: card)
        }
        
    }
}


extension Game: CustomDebugStringConvertible {
    var debugDescription: String {
        let parts = [
            "Graveyards: \(graveyards)",
            "Hand: \(hands)",
            decks.map({ "\($0)" }).joined(separator: "\n")
        ]
        
        return parts.joined(separator: "\n")
    }
}

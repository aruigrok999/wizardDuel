//
//  GameGraphics.swift
//  Freegraveyard2
//
//  Created by gary on 31/08/2017.
//  Copyright © 2017 Gary Kerr. All rights reserved.
//

import SpriteKit

struct GameGraphics {

    private var config = GameGraphicsConfig()

    private var graveyards: [SKSpriteNode] = []
    private var hands: [SKSpriteNode] = []
    private var decks: [SKSpriteNode] = []
    private var newGameButton: SKSpriteNode = SKSpriteNode(color: .red, size: CGSize(width: 75, height: 40))
    
    

    var cards: [PlayingCard] = []

    mutating func setup(width: CGFloat, height: CGFloat) {
        let baseZPosition: CGFloat = config.zIndexIncrement
        // Hand
        for i in 0 ..< config.graveyardCount {
            let graveyard = SKSpriteNode(color: config.backgroundColour, size: config.cardSize)
            graveyard.anchorPoint = config.topLeft
            graveyard.position = CGPoint(x: -config.margin + config.spacing + config.cardSize.width + CGFloat(i) * (config.cardSize.width + config.spacing), y: config.margin)
            graveyard.zPosition = baseZPosition
            graveyards.append(graveyard)
        }

        // Graveyards
        for i in 0 ..< config.handCount {
            let hand = SKSpriteNode(color: config.backgroundColour, size: config.cardSize)
            hand.anchorPoint = config.topLeft
            hand.position = CGPoint(x: config.margin + config.cardSize.width + CGFloat(i) * (config.cardSize.width + config.spacing/2), y: -config.margin - height + config.cardSize.height)

            hand.zPosition = baseZPosition
            hands.append(hand)
        }

        //let deckWidth = CGFloat(config.deckCount) * config.cardSize.width + CGFloat(config.deckCount - 1) * config.spacing
        //let deckMargin = (width - deckWidth) / 2

        // Decks
        for _ in 0 ..< config.deckCount {
            let deck = SKSpriteNode(color: config.backgroundColour, size: config.cardSize)
            deck.anchorPoint = config.topLeft
            deck.position = CGPoint(x: -config.margin, y: config.margin)
            deck.zPosition = baseZPosition
            decks.append(deck)
        }

        // New game button
        newGameButton.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        newGameButton.position = CGPoint(x: width / 2, y: -110)
        newGameButton.texture = SKTexture(imageNamed: "newGame")
        newGameButton.zPosition = baseZPosition
    }


    mutating func setupCards(gameDecks: [Deck]) {
        // Playing cards
        for (deckCards, deck) in zip(gameDecks, decks) {
            let deckPosition = deck.position
            for (i, gameCard) in deckCards.cards.enumerated() {
                let card = PlayingCard(card: gameCard, size: config.cardSize)
                card.anchorPoint = config.topLeft
                card.size = config.cardSize
               // card.position = CGPoint(x: deckPosition.x, y: deckPosition.y + config.margin * CGFloat(i))
                card.position = CGPoint(x: deckPosition.x + CGFloat(i/10), y: deckPosition.y + CGFloat(i/4))
                card.zPosition = config.getZIndex()
                cards.append(card)
            }
        }
    }

    //Adds all the children to the scene
    func addChildren(to scene: SKScene) {
        for graveyard in graveyards {
            scene.addChild(graveyard)
        }
        for hand in hands {
            scene.addChild(hand)
        }
        for deck in decks {
            scene.addChild(deck)
        }
        addCards(to: scene)
        scene.addChild(newGameButton)
    }

    //Creates the deck by adding all the cards to the deck
    func addCards(to scene: SKScene) {
        for card in cards {
            scene.addChild(card)
        }
    }
    
    //Creates the background and sets its image
    func setupBackground(to scene: SKScene) {
        let backgroundTexture = SKTexture(imageNamed: "background")
        let background: SKSpriteNode = SKSpriteNode( color: .clear, size: CGSize(width: scene.size.width, height: scene.size.height))
        
        background.texture = backgroundTexture
        background.anchorPoint = CGPoint(x: 0, y: 1)
        background.zPosition = -5
        scene.addChild(background)
        
       
    }


    func cardFrom(position: CGPoint) -> PlayingCard? {
        var candidateCards: [PlayingCard] = []
        for card in cards {
            if card.contains(position) {
                candidateCards.append(card)
            }
        }
        candidateCards.sort(by: { $0.zPosition < $1.zPosition })
        return candidateCards.last
    }


    func isNewGameTapped(point: CGPoint) -> Bool {
        return newGameButton.contains(point)
    }


    mutating func setActive(card: PlayingCard) {
        card.zPosition = config.getZIndex()
    }


    mutating func newGame(gameDecks: [Deck]) {
        for card in cards {
            card.removeFromParent()
        }
        cards = []
        setupCards(gameDecks: gameDecks)
    }


    func move(currentPlayingCard: CurrentPlayingCard, to location: Location, gameDecks: [Deck]) {
        let newPosition: CGPoint
        switch location {
        case .graveyard(let value):
            let graveyard = graveyards[value]
            newPosition = graveyard.position
        case .hand(let value):
            let hand = hands[value]
            newPosition = hand.position
        case .deck(let value):
            let deck = decks[value]
            let gameDeck = gameDecks[value]
            let cardCount = gameDeck.cards.count - 1
            let deckPosition = deck.position
            newPosition = CGPoint(x: deckPosition.x, y: deckPosition.y + CGFloat(cardCount) * config.margin)
        }
        currentPlayingCard.move(to: newPosition)
    }


    func dropLocation(from position: CGPoint, currentPlayingCard: CurrentPlayingCard, game: Game) -> Location? {
        for (i, graveyard) in graveyards.enumerated() {
            if graveyard.contains(position) {
                return .graveyard(i)
            }
        }
        for (i, hand) in hands.enumerated() {
            if hand.contains(position) {
                return .hand(i)
            }
        }
        for playingCard in cards {
            if playingCard == currentPlayingCard.playingCard { continue }
            if playingCard.contains(position) {
                if let location = game.location(from: playingCard.card) {
                    switch location {
                    case .deck(let value):
                        let deck = game.decks[value]
                        if deck.isBottom(card: playingCard.card) {
                            return location
                        }
                    default:
                        break
                    }
                }
            }
        }
        for (i, deck) in decks.enumerated() {
            if deck.contains(position) {
                let gameDeck = game.decks[i]
                if gameDeck.isEmpty {
                    return .deck(i)
                }
            }
        }
        return nil
    }


    func undo(move: Move, card: Card, gameDecks: [Deck]) {
        print("game graphics, undo", move)
        let position = positionFrom(location: move.toLocation)
        print(position)
        let playingCard = findPlayingCard(from: card)
        let currentPlayingCard = CurrentPlayingCard(playingCard: playingCard, startPosition: playingCard.position, touchPoint: playingCard.position, location: move.toLocation)
        self.move(currentPlayingCard: currentPlayingCard, to: move.fromLocation, gameDecks: gameDecks)
        
    }


    // MARK: - Private

    private func positionFrom(location: Location) -> CGPoint {
        let position: CGPoint
        switch location {
        case .deck(let value):
            let deck = decks[value]
            print("deck position")
            position = deck.position
        case .graveyard(let value):
            let graveyard = graveyards[value]
            print("graveyard position")
            position = graveyard.position
        case .hand(let value):
            let hand = hands[value]
            print("hand position")
            position = hand.position
        }
        return CGPoint(x: position.x + config.cardSize.width/2, y: position.y - config.cardSize.height/2)
    }


    private func findPlayingCard(from card: Card) -> PlayingCard {
        for playingCard in cards {
            if playingCard.card == card {
                return playingCard
            }
        }
        fatalError("Couldn't find PlayingCard from Card")
    }
}

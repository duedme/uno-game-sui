// This works in conjunction with the 'game' and 'colors' module. 
// Here are the most basic functionalities of the card game.
// Structures such as 'Game' are implemented, which hosts all
// the necessary information regarding players and shots, among others.

module local::game_objects {
    friend local::uno;

    use local::colors::{Self, Color};
    use std::ascii::{Self, String};
    use std::vector;
    use std::hash;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::event;
    use sui::tx_context::{Self, TxContext};

    const EMIN_NUMBER_OF_PLAYERS_NOT_REACHED: u8 = 2;
    const ENON_ADMIN_ENDING_GAME: u8 = 7;
    const ESIGNER_IS_NOT_ADMIN_OF_GAME: u8 = 8;

    // NFT with unique id of the game linked with special Decks so that previous ones do not work.
    // The'rounds' slot is type-vector which stores a Card-type vector. Its intention is to record all the
    // moves of the players.

    // Figure that houses a game ID, the administrator's address, a maximum number of players, the players,
    // the players who have thrown in each round and the cards that they have used.
    struct Game has key {
        id: UID,
        admin: address,
        max_number_of_players: u8,
        players: vector<address>,
        rounds: VecMap<u8, vector<address>>,
        moves: VecMap<address, vector<Card>>,
        all_used_cards: vector<Card>,
        //deck: VecMap<address, vector<Deck>>,
    }

    // The basic shape of a card that has a number and a color is housed.
    // There is also a pending option to implement special cards in the future.
    struct Card has store, copy, drop {
        number: u8,
        color: Color,
        //special: bool,
    }
    
    // The deck has an ID in case the player is in different games.
    // There is a special ID that is the same as the current 'Game' session has,
    // so that it can't be used after the game ends. 
    // Here the cards that the player has available and the quantity of them are
    // listed (in the classic game there can only be 7). 
    // Finally, there is a state that registers if a person has already checked that 
    // they have the card available to play in the next turn. 
    struct Deck has key, store {
        id: UID,
        id_from_game: ID,
        card: vector<Card>,
        amount: u8,
        state: VecMap<String, bool>,
        //special_cards: bool
    }

    struct Emit has copy, drop {
        addr: address,
        vec_addr: vector<address>,
        vec_card: vector<Card>,
        uint_8bit: u8,
        addr_vec_card_vecmap: VecMap<address, vector<Card>>,
        str: String,
    }

    // === `Basic` functions ===

    // Changes to true if the player has already checked that they have a card available to play 
    // and to false if the person has already thrown or does not have a card available to play.
    public(friend) fun update_state(deck: &mut Deck, stat: bool) {
        let status = vec_map::get_mut(&mut deck.state, &ascii::string(b"Checked"));
        *status = stat;
    }

    // Records that a person has already played in the current round.
    public(friend) fun check_participation(game: &Game, ctx: &mut TxContext) {
        let game_rounds = get_rounds(game);
        let round_number = (vec_map::size(&game_rounds) as u8);

        if(vec_map::is_empty<u8, vector<address>>(&game_rounds)) {
            vec_map::insert(&mut game_rounds, 1, vector::singleton(tx_context::sender(ctx)));
        } else {
            let addresses = vec_map::get_mut(&mut game_rounds, &round_number);
            vector::push_back(addresses, tx_context::sender(ctx));
        };

        let participations = vec_map::get(&mut game_rounds, &round_number);
        if(vector::length(participations) == vector::length(&get_players(game))) {
            vec_map::insert(&mut game_rounds, round_number + 1, vector::empty<address>());
        }
    }

    // Wins and finishes the game by dropping the struct 'Game'.
    public(friend) fun win(/*game: Game, */cards: vector<Card>, _ctx: &mut TxContext) {
        let game_won_and_finished: String = ascii::string(b"You won the game!");
        event::emit<vector<Card>>(cards);
        event::emit<String>(game_won_and_finished);

        //end_game(game, ctx);
    }

    // Tells the player he played his cards and the game continues.
    public(friend) fun game_continues(cards: vector<Card>) {
        let player_played_card: String = ascii::string(b"You played a card!");
        event::emit<vector<Card>>(cards);
        event::emit<String>(player_played_card);
    }

    /*// Deletes the current 'Game' struct.
    public(friend) fun end_game(game: Game, ctx: &mut TxContext)  {
        assert!(get_admin(&game) == tx_context::sender(ctx),
            (ENON_ADMIN_ENDING_GAME as u64));

        transfer::freeze_object(game);
    }*/

    // Makes one person the admin when the game starts. Here the new admin 
    // will be given a 'Game' structure with its address as identifier.
    public(friend) fun be_the_game_admin_at_start(number_of_players: u8, ctx: &mut TxContext) {
        assert!(number_of_players > 1, (EMIN_NUMBER_OF_PLAYERS_NOT_REACHED as u64));

        let moves = vec_map::empty<address, vector<Card>>();
        let game = new_game(moves, number_of_players, ctx);
        let deck = new_deck(&game, ctx);

        vec_map::insert(&mut moves, tx_context::sender(ctx), vector::empty<Card>());

        transfer::transfer(deck, tx_context::sender(ctx));
        transfer::share_object(game);
    }

    // Generates a new game object with fixed values.
    fun new_game(moves: VecMap<address, vector<Card>>, players: u8, ctx: &mut TxContext): Game {
            Game {
                id: object::new(ctx),
                admin: tx_context::sender(ctx),
                max_number_of_players: players,
                players: vector::singleton<address>(tx_context::sender(ctx)),
                rounds: vec_map::empty<u8, vector<address>>(),
                moves,
                all_used_cards: vector::empty<Card>(),
            }
    }

    // An admin can give game control to another player.
    public(friend) fun give_administration(game: Game, addr: address) {
        transfer::transfer(game, addr);
    }

    // Confirm that someone has the structure 'Game' and is therefore
    // the admin of the game.
    // TODO: check implementation and if method is necessary.
    /*public(friend) fun is_admin(addr: &address): bool {
        exists<Game>(*addr)
    }*/
    
    // A player will be removed from the player list in 'Game'.
    public(friend) fun leave_game(game: &Game, ctx: &mut TxContext) {
    let players = get_players(game);
    let j: u64;
    
    (_, j) = vector::index_of(&players, &tx_context::sender(ctx));

    vector::remove(&mut players, j);
}

// An admin can add someone to the player list and give them a deck.
public(friend) fun add_player(game: &Game, new_player: address, ctx: &mut TxContext) {
    let all_players = get_players(game);
    let new_moves = get_moves(game);

    transfer::transfer(new_deck(game, ctx), new_player);
    vector::push_back(&mut all_players, new_player);
    vec_map::insert(&mut new_moves, new_player, vector::empty<Card>());
}

    // A new deck is created with all available attributes. Exactly 7 random cards will be given to play.
    public(friend) fun new_deck(game: &Game, ctx: &mut TxContext): Deck {
        let i = 0u8;
        let state = vec_map::empty<String, bool>();
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);

        let deck = Deck {
            id: object::new(ctx),
            id_from_game: get_game_id(game),
            card: vector::empty<Card>(),
            amount: 7,
            state,
        };

        while( i < 7 ) {
            let random_card = generate_random_card(&deck, ctx);
            vector::push_back(&mut deck.card, random_card)
        };

        deck
    }

    // Summons a new random card and appends it to players deck.
    // It is usually used when the player cannot play more cards than he owns.
    public(friend) fun add_new_card_to_deck(deck: &Deck, ctx: &mut TxContext) {
        vector::push_back(&mut get_cards_in_deck(deck)
            , generate_random_card(deck, ctx));
    }

    // Generates random cards. There are 9 for each color (red, green, blue and yellow).
    fun generate_random_card(deck: &Deck, _ctx: &mut TxContext): Card {
        let hashed = hash::sha2_256(object::id_bytes(deck));
        let card_number = vector::pop_back(&mut hashed);
        card_number = card_number % 36;
        card_number = card_number + 1;

        if(card_number >= 27) {
            return Card { number: card_number % 9, color: colors::return_red() }
        } else if(card_number >= 18) { 
            return Card { number: card_number % 9, color: colors::return_green() }
        } else if(card_number >= 9) {
            return Card { number: card_number % 9, color: colors::return_blue() }
        } else {
            return Card { number: card_number % 9, color: colors::return_yellow() }
        }
    }

    // === `Getter` functions ===

        // It is consulted in 'Game' what is the maximum number of players in the game.
    public(friend) fun get_max_number_of_players(game: &Game): u64 {
        (game.max_number_of_players as u64)
    }
    
    // Unwraps the inner ID inside the UID of the game.
    public(friend) fun get_game_id(game: &Game): ID {
        object::id(game)
    }

    // Rounds are displayed.
    public(friend) fun get_rounds(game: &Game): VecMap<u8, vector<address>> {
        game.rounds
    }

    // Player list is displayed.
    public(friend) fun get_players(game: &Game): vector<address> {
        game.players
    }

    // The list of cards used by each player is displayed.
    public(friend) fun get_moves(game: &Game): VecMap<address, vector<Card>> {
        game.moves
    }

    // Tells a player who the admin is.
    public(friend) fun get_admin(game: &Game): address {
        game.admin
    }

    // Gives the number of players in the game.
    public(friend) fun get_number_of_players(game: &Game): u8 {
        (vector::length(&get_players(game)) as u8)
    }

    // Gives the number of rounds so far.
    public(friend) fun get_number_of_rounds(game: &Game): u8 {
        (vec_map::size(&get_rounds(game)) as u8)
    }
    
    // A player is shown its deck.
    /*public(friend) fun get_deck(deck: Deck): &Deck  {
        &deck
    }*/

    // Gives the number of remaining cards of the signer.
    public(friend) fun get_number_of_cards(deck: &Deck): u8 {
        (vector::length(&get_cards_in_deck(deck)) as u8)
    }

    // It tells if a player can throw or if he doesn't have the right cards.
    public(friend) fun get_state(deck: &Deck): bool {
        *vec_map::get(&deck.state, &ascii::string(b"Checked"))
    }

    // The cards available in a player's deck are displayed.
    public(friend) fun get_cards_in_deck(self: &Deck): vector<Card> {
        self.card
    }

    // Get a copy of all cards used in game.
    public(friend) fun get_all_used_cards(game: &Game): vector<Card> {
        game.all_used_cards
    }

    // Get the last card used in the game.
    public(friend) fun get_last_used_card(game: &Game): Card {
        let used_cards = get_all_used_cards(game);
        let number_of_used_cards = vector::length<Card>(&used_cards) - 1;
        *vector::borrow<Card>(&mut used_cards, number_of_used_cards)
    }

    // The color of a specific card in the deck is displayed.
    public(friend) fun get_index_color(self: &Deck, i: u64): Color {
        vector::borrow(&self.card, i).color
    }

    // The number of a specific card in the deck is displayed.
    public(friend) fun get_index_number(self: &Deck, i: u64): u8 {
        vector::borrow(&self.card, i).number
    }

    // The color of a card is shown only by giving the card as a sample.
    public(friend) fun get_color(self: &Card): Color {
        self.color
    }

    // The number of a card is shown only by giving the card as a sample.
    public(friend) fun get_number(self: &Card): u8 {
        self.number
    }
}
/// This works in conjunction with the 'game' and 'colors' module.
/// Here are the most basic functionalities of the card game.
/// Structures such as 'Game' are implemented, which hosts all
/// the necessary information regarding players and shots, among others.

/// @author Daniel Espejel
/// @title game_objects
module local::game_objects {
    friend local::uno;

    use local::colors::{Self, Color};
    use std::ascii::{Self, String};
    use std::vector;
    use std::hash;
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::event;
    use sui::tx_context::{Self, TxContext};

    const EMIN_NUMBER_OF_PLAYERS_NOT_REACHED: u8 = 2;

    /// @notice Figure that represents the whole game and its processes.
    ///     It houses a game ID, the administrator's address, a maximum number of players, the players,
    ///     the players who have thrown in each round and the cards that they have used.
    struct Game has key {
        id: UID,
        /// Maximum number of players to have in the game. This is set at the beggining of the.
        max_number_of_players: u8,
        /// Dynamic list of all players in the game.
        players: vector<address>,
        /// A map that takes a round as a key and a list of players who have participated in the current round
        /// as a value.
        rounds: VecMap<u8, vector<address>>,
        /// A map that takes a players's address as a key and a list of used cards as value.
        moves: VecMap<address, vector<Card>>,
        /// simulates where a person places a card they just played. The color or number of the last card in the
        /// list is taken as a reference for the next player's draw.
        all_used_cards: vector<Card>,
        /// Tells if a game has been won. Normally this is false.
        won: bool,
        //deck: VecMap<address, vector<Deck>>,
    }

    /// @notice The basic shape of a card that has a number and a color is housed.
    ///     There is also a pending option to implement special cards in the future.
    struct Card has store, copy, drop {
        /// The number of the card. Tipically between 0 and 9.
        number: u8,
        /// Color of the card. The colors are blue, gree, yellow and red.
        color: Color,
        //special: bool,
    }
    
    /// @notice The deck has an ID in case the player is in different games.
    ///     There is a special ID that is the same as the current 'Game' session has,
    ///     so that it can't be used after the game ends. 
    ///     Here the cards that the player has available and the quantity of them are
    ///     listed (in the classic game there can only be 7). 
    ///     Finally, there is a state that registers if a person has already checked that 
    ///     they have the card available to play in the next turn. 
    struct Deck has key, store {
        id: UID,
        /// The inner ID inside the UID of the 'Game' object. Meant to serve as a reference
        /// to the game the deck belongs to.
        id_from_game: ID,
        /// Dynamic list of cards available to a player.
        card: vector<Card>,
        /// The amount of cards there will be from the beginning. This number is always 7.
        amount: u8,
        /// Map matching the string "Checked" with a bool statement indicating whether the
        /// player has a card available.
        state: VecMap<String, bool>,
        /// Parameter that will help make things more random while creating cards.
        random_helper: u8,
        //special_cards: bool
    }

    /// @notice Emit wraps any object with copy and drop abilities. It is only used in 'emit_object()' 
    /// and 'emit_wrapper()' methods.
    struct Emit<T: copy + drop> has copy, drop {
        t: T,
    }

    // === `Basic` functions ===

    /// @notice Changes to true if the player has already checked that they have a card available for the 
    ///     round and to false if the person has already thrown or does not have a card available to play.
    /// @param deck (Deck) is the object Deck owned by an user.
    /// @param stat (bool) is true if it has an available card.
    public(friend) fun update_state(deck: &mut Deck, stat: bool) {
        let status = vec_map::get_mut(&mut deck.state, &ascii::string(b"Checked"));
        *status = stat;
    }

    /// @notice Stores an users address if they have played their turn in the current round.
    /// @param game (Game) is the shared object that stores all game information.
    /// @param ctx (TxContext) saves the transaction's context. Will be used to takes signers and addresses.
    public(friend) fun check_participation(game: &Game, ctx: &mut TxContext) {
        let game_rounds = get_rounds(game);
        let round_number = (vec_map::size(&game_rounds) as u8);
        let participations = vec_map::get(&mut game_rounds, &round_number);

        // Saves the player's address in different treatment depending on the number of rounds.
        if(vec_map::is_empty<u8, vector<address>>(&game_rounds)) {
            vec_map::insert(&mut game_rounds, 1, vector::singleton(tx_context::sender(ctx)));

        // If all players have participated, game goes to the next round.
        } else if(vector::length(participations) == vector::length(&get_players(game))) {
            vec_map::insert(&mut game_rounds, round_number + 1, vector::empty<address>());

        // If the game is in the middle of a round, just push the player to the list.
        } else {
            let addresses = vec_map::get_mut(&mut game_rounds, &round_number);
            vector::push_back(addresses, tx_context::sender(ctx));
        };
    }

    /// @notice Tells a player he has won the game.
    /// @param _ctx (TxContext) has the context of the transaction. Not used explicitly in method's implementation.
    /// @dev TODO: freeze or delete game. Maybe as an optional method for when the game is 
    ///     finished (restriction).
    ///     Maybe a flag indicating whether the game is finished would be useful. It should be added 
    ///     to the game's params.
    public(friend) fun win(/*game: Game, */ _ctx: &mut TxContext) {
        let game_won_and_finished: String = ascii::string(b"You won the game!");
        emit_object<String>(game_won_and_finished);
    }

    /// @notice Tells the player he played his cards and a message indicating the action.
    /// @param cards (vector<Card>) is the remaining list of cards.
    public(friend) fun game_continues(cards: vector<Card>) {
        let player_played_card: String = ascii::string(b"You played a card!");
        emit_object<vector<Card>>(cards);
        emit_object<String>(player_played_card);
    }

    /**
    /// @notice Deletes the current 'Game' struct.
    /// @dev This function's existence is still under discussion.
    public(friend) fun end_game(game: Game, ctx: &mut TxContext)  {
        assert!(get_admin(&game) == tx_context::sender(ctx),
            (ENON_ADMIN_ENDING_GAME as u64));

        transfer::freeze_object(game);
    }
    */

    /// @notice Freezes the game object. Makes impossible to mutate.
    /// @param game (Game) is the shared object that stores all game information.
    public(friend) fun freeze_game(game: Game) {
        transfer::freeze_object(game);
    }

    /// @notice Deletes the game object with its ID included. Will no longer be used.
    /// @param game (Game) is the shared object that stores all game information.
    public(friend) fun delete_game(game: Game) {
        let Game { id, max_number_of_players: _, players: _, rounds: _, moves: _, all_used_cards: _, won: _ } = game;
        object::delete(id);
    }

    /// @notice Start a game that will be shared later.
    /// @param number_of_players (u8) is the max number of players a game will be allowed to have.
    /// @param ctx (TxContext) takes the context of the transaction. It is used to get signer and address.
    public(friend) fun start(number_of_players: u8, ctx: &mut TxContext) {
        assert!(number_of_players > 1, (EMIN_NUMBER_OF_PLAYERS_NOT_REACHED as u64));

        // Calls a special method to create a new game.
        let game = new_game(number_of_players, ctx);

        // Initializes a map of cards linked to the sender's address.
        vec_map::insert(&mut get_moves(&mut game), tx_context::sender(ctx), vector::empty<Card>());

        // Adds the player to the list of players.
        add_player(&mut game, tx_context::sender(ctx), ctx);

        // Shares the new game.
        transfer::share_object(game);
    }

    /// @notice Generates a new game object with fixed values.
    /// @param players (u8) is the max number of players that will be allowed in the game.
    /// @param ctx (TxContext) is the context for the transaction. Used to get signer's address.
    /// @dev remove the 'moves' param and instead manually set moves equal to a new and empty vec_map.
    fun new_game(players: u8, ctx: &mut TxContext): Game {
            Game {
                id: object::new(ctx),
                max_number_of_players: players,
                players: vector::singleton<address>(tx_context::sender(ctx)),
                rounds: vec_map::empty<u8, vector<address>>(),
                moves: vec_map::empty<address, vector<Card>>(),
                all_used_cards: vector::empty<Card>(),
                won: false,
            }
    }

    /// @notice A player will be removed from the player list in 'Game'.
    /// @param game (Game) is the shared object that the player will be removed from.
    /// @param ctx (TxContext) is the context of the transaction. Used to get address of the player.
    public(friend) fun leave_game(game: &Game, ctx: &mut TxContext) {
    let players = get_players(game);
    let j: u64;
    
    (_, j) = vector::index_of(&players, &tx_context::sender(ctx));

    vector::remove(&mut players, j);
}

    /// @notice Add someone to the player list and give them a deck.
    ///     As game is shared, anyone can add anyone.
    /// @param game (Game) is the shared object to which to player will be added.
    /// @param new_player (address) is the new player's address.
    /// @param ctx (TxContext) is used to give a new UID (unique identifier) to the new deck.
    /// @dev TODO: is it right to use ctx to create an the deck's id?
    public(friend) fun add_player(game: &mut Game, new_player: address, ctx: &mut TxContext) {
    let all_players = &mut get_players(game);
    vector::push_back<address>(all_players, new_player);

    let new_moves = &mut get_moves(game);
    vec_map::insert(new_moves, new_player, vector::empty<Card>());

    transfer::transfer(new_deck(game, ctx), new_player);
}

    /// @notice A new deck is created with all available attributes. Exactly 7 random cards 
    ///     will be given to play.
    /// @param game (Game) is the shared object used to id id_from_game argument in new Deck object.
    /// @param ctx (TxContext)is used to give a new UID (unique identifier) to the new deck.
    /// @return Deck object given to the new player.
    /// @dev TODO: is it right to use ctx to create an the deck's id?
    public(friend) fun new_deck(game: &Game, ctx: &mut TxContext): Deck {
        let i = 0u8;
        let state = vec_map::empty<String, bool>();
        // Starts a new false state for the deck. Intended to be used in playing time.
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);

        // Creation of the new deck object.
        let deck = Deck {
            id: object::new(ctx),
            id_from_game: get_game_id(game),
            card: vector::empty<Card>(),
            amount: 7,
            state,
            random_helper: 0,
        };

        // Creation of random cards and given to the deck.
        while( i < 7 ) {
            let random_card = generate_random_card(&mut deck, ctx);
            vector::push_back(&mut deck.card, random_card);
            i = i + 1;
        };

        // Return deck to new player.
        deck
    }

    /// @notice Summons a new random card and appends it to players deck.
    ///     It is usually used when the player cannot play more cards than he owns.
    /// @param deck (Deck) is the owned object to which the new card is added to.
    /// @param ctx (TxContext) is the context of the transaction.
    public(friend) fun add_new_card_to_deck(deck: &mut Deck, ctx: &mut TxContext) {
        vector::push_back(&mut get_cards_in_deck(deck)
            , generate_random_card(deck, ctx));
    }

    /// @notice Generates random cards. There are 9 for each color (red, green, blue and yellow).
    /// @param deck (Deck) is the object owned by the player. Used to obtain a hash with pseudo-random numbers.
    /// @param _ctx (TxContext) is the context of the transaction.
    /// @return Card object appended to the a given deck.
    fun generate_random_card(deck: &mut Deck, _ctx: &mut TxContext): Card {
        let seed = object::id_bytes(deck);
        
        if(deck.random_helper != 255) { deck.random_helper = deck.random_helper + 1; }
        else { deck.random_helper = 0; };
        
        vector::push_back(&mut seed, deck.random_helper);

        let hashed = hash::sha2_256(seed);
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

    // === `Emit` function ===

    /// @notice Emits the 'Emit' object wrapping enything with copy and drop abilities.
    /// @param t (generic T) of generic type T should always have the copy and drop abilities.
    ///     It means anything (vectors, unsigned integers, etc) that will be displayed
    ///     to the user.
    /// @dev This method maked use of private fucntion emit_wrapper().
    public(friend) fun emit_object<T: copy + drop>(t: T) {
        event::emit<Emit<T>>(emit_wrapper(t));
    }

    /// @notice Wraps any type with copy and drop abilities into 'Emit' object. Meant to be used
    ///     with 'emit_object()' method.
    /// @param t (generic T) of generic type that will be wrapped in 'Emit' object.
    /// @return Emit wrapping a generic T object. Only used in emit_object() method.
    public fun emit_wrapper<T: copy + drop>(t: T): Emit<T> {
        Emit<T>{ t }
    }

    // === `Getter` functions ===

    /// @notice It is consulted in 'Game' what is the maximum number of players in the game.
    /// @param game (Game) shared between players.
    /// @return u64 representing the maximum number of players that could be added to the game.
    public(friend) fun get_max_number_of_players(game: &Game): u64 {
        (game.max_number_of_players as u64)
    }
    
    /// @notice Unwraps the inner ID inside the UID of the game.
    /// @param game (Game) shared between players.
    /// @return ID object extracted from game's unique ID (UID).
    public(friend) fun get_game_id(game: &Game): ID {
        object::id(game)
    }

    /// @notice Rounds are displayed.
    /// @param game (Game) shared between players.
    /// @return VecMap mapping the number of rounds to all the players who have played the round
    ///     at the moment of calling the function.
    public(friend) fun get_rounds(game: &Game): VecMap<u8, vector<address>> {
        game.rounds
    }

    /// @notice Player list is displayed.
    /// @param game (Game) shared between players.
    /// @return vector representing a dynamic list of the current players.
    public(friend) fun get_players(game: &Game): vector<address> {
        game.players
    }

    /// @notice The list of cards used by each player is displayed.
    /// @param game (Game) shared between players.
    /// @return VecMap mapping an user's address to a list of all the cards played.
    public(friend) fun get_moves(game: &Game): VecMap<address, vector<Card>> {
        game.moves
    }

    /// @notice Gives the number of players in the game.
    /// @param game (Game) shared between players.
    /// return u8 representing the number of players in the game at the moment of callig the function.
    public(friend) fun get_number_of_players(game: &Game): u8 {
        (vector::length(&get_players(game)) as u8)
    }

    /// @notice Gives the number of rounds so far.
    /// @param game (Game) shared between players.
    /// @return u8 with the number of rounds that have elapsed so far.
    public(friend) fun get_number_of_rounds(game: &Game): u8 {
        (vec_map::size(&get_rounds(game)) as u8)
    }

    /// @notice Gives the number of remaining cards of the signer.
    /// @param deck (Deck) owned by the player calling the method.
    /// @return u8 with the amount of remaining cards in deck.
    public(friend) fun get_number_of_cards(deck: &Deck): u8 {
        (vector::length(&get_cards_in_deck(deck)) as u8)
    }

    /// @notice It tells if a player can throw or if he doesn't have the right cards.
    /// @param deck (Deck) owned by the player calling the method.
    /// @return true if the player has checked he ownes a card to play.
    public(friend) fun get_state(deck: &Deck): bool {
        *vec_map::get(&deck.state, &ascii::string(b"Checked"))
    }

    /// @notice The cards available in a player's deck are displayed.
    /// @param deck (Deck) owned by the player calling the method.
    /// @return vector of cards representing the list of cards in the user's deck.
    public(friend) fun get_cards_in_deck(deck: &Deck): vector<Card> {
        deck.card
    }

    /// @notice Get a copy of all cards used in game.
    /// @param game (Game) shared between players.
    /// @return vector of cards representing all the cards that have been already used in game.
    public(friend) fun get_all_used_cards(game: &Game): vector<Card> {
        game.all_used_cards
    }

    /// @notice Get the last card used in the game.
    /// @param game (Game) shared between players.
    /// @return Option<Card>. It is a Card that may or may not be present.
    public(friend) fun get_last_used_card(game: &Game): Option<Card> {
        let used_cards = get_all_used_cards(game);
        let number_of_used_cards = vector::length<Card>(&used_cards);

        if(number_of_used_cards == 0) { option::none<Card>() }
        else {
            number_of_used_cards = number_of_used_cards - 1;
            option::some<Card>(
                *vector::borrow<Card>(&mut used_cards, number_of_used_cards)
            )
        }
    }

    public(friend) fun get_won(game: &Game): bool {
        game.won
    }

    /// @notice The color of a specific card in the deck is displayed.
    /// @param deck (Deck)owned by the player calling the method.
    /// @param i (u64) is the index of the card in the list of cards.
    /// @return color object in the color module that contains an RGB implementation of a color.
    public(friend) fun get_index_color(deck: &Deck, i: u64): Color {
        vector::borrow(&deck.card, i).color
    }

    /// @notice The number of a specific card in the deck is displayed.
    /// @param deck (Deck) owned by the player calling the method.
    /// @param i (u64) is the index of the card in the list of cards.
    /// @return u8 with the number of a card.
    public(friend) fun get_index_number(deck: &Deck, i: u64): u8 {
        vector::borrow(&deck.card, i).number
    }

    /// @notice The color of a card is shown only by giving the card as a sample.
    /// @param card (Card) from which you want to get its color.
    /// @return color object in the color module that contains an RGB implementation of a color.
    public(friend) fun get_color(card: &Card): Color {
        card.color
    }

    /// @notice The number of a card is shown only by giving the card as a sample.
    /// @param card (Card) from which you want to get its color.
    /// @return u8 with the number of a card.
    public(friend) fun get_number(card: &Card): u8 {
        card.number
    }

    // === `Test` functions ===

    #[test]
    fun test_transfer() {
        use sui::test_scenario;
        use sui::transfer;

        let user = @0x1;

        let scenario = test_scenario::begin(user);


        let players = 2;
        transfer::transfer(Game {
                id: object::new(test_scenario::ctx(&mut scenario)),
                max_number_of_players: players,
                players: vector::singleton<address>(test_scenario::sender(&mut scenario)),
                rounds: vec_map::empty<u8, vector<address>>(),
                moves: vec_map::empty<address, vector<Card>>(),
                all_used_cards: vector::empty<Card>(),
                won: false,
        },
        test_scenario::sender(&mut scenario));

        test_scenario::end(scenario);

    }

    #[test]
    fun test_transfer_2() {
        use sui::test_scenario;
        use sui::transfer;

        let user = @0x1;

        let scenario = test_scenario::begin(user);

        let players = 2;
        let game = new_game(players, test_scenario::ctx(&mut scenario));
        transfer::transfer(game, test_scenario::sender(&mut scenario));

        test_scenario::end(scenario);
    }

    #[test]
    fun test_start_deck() {
        use sui::test_scenario;
        use sui::transfer;

        let user = @0x1;

        let scenario = test_scenario::begin(user);

        let players = 2;
        let game = new_game(players, test_scenario::ctx(&mut scenario));

        //let deck = new_deck(&game, test_scenario::ctx(scenario));
        transfer::transfer(game, test_scenario::sender(&mut scenario));
        //transfer::transfer(deck, test_scenario::sender(scenario));

        test_scenario::end(scenario);
    }

    #[test_only]
    fun new_deck_(ctx: &mut TxContext): Deck {
        let i = 0u8;
        let state = vec_map::empty<String, bool>();
        // Starts a new false state for the deck. Intended to be used in playing time.
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);

        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        // Creation of the new deck object.
        let deck = Deck {
            id: id,
            id_from_game: game_id,
            card: vector::empty<Card>(),
            amount: 7,
            state,
            random_helper: 0,
        };

        // Creation of random cards and given to the deck.
        while( i < 7 ) {
            let random_card = generate_random_card(&mut deck, ctx);
            vector::push_back(&mut deck.card, random_card)
        };

        // Return deck to new player.
        deck
    }

    #[test]
    fun test_deck() {
        use sui::test_scenario;
        use sui::transfer;
        use std::vector;

        let user = @0x1;
        let i = 0u8;

        let scenario = test_scenario::begin(user);
        let id = object::new(test_scenario::ctx(&mut scenario));
        let game_id = object::uid_to_inner(&id);        //let deck = new_deck_(test_scenario::ctx(scenario));
        let state = vec_map::empty<String, bool>();
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);


        let deck = Deck {
            id: id,
            id_from_game: game_id,
            card: vector::empty<Card>(),
            amount: 7,
            state,
            random_helper: 0,
        };

        while( i < 7 ) {
            let random_card = generate_random_card(&mut deck, test_scenario::ctx(&mut scenario));
            vector::push_back(&mut deck.card, random_card);
            i = i + 1;
        };

        assert!(!vector::is_empty(&deck.card), 1000);

        transfer::transfer(deck, test_scenario::sender(&mut scenario));

        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_player() {
        use sui::test_scenario; 
        use sui::transfer;

        let player_one = @0x1;
        let player_two = @0x2;
        let player_three = @0x3;
        let player_four = @0x4;
        let scenario = test_scenario::begin(player_one);

        let game = new_game(2, test_scenario::ctx(&mut scenario));

        let all_players = &mut get_players(&game);

        vector::push_back<address>(all_players, player_two);

        let vec = vector::empty<u8>();
        vector::push_back<u8>(&mut vec, 1);

        assert!(vector::length(&vec) == 1, 10000000);
        assert!(vector::length(all_players) == 2, 1001000);

        vector::push_back<address>(all_players, player_three);

        assert!(vector::length(all_players) == 3, 1001000);

        test_scenario::next_tx(&mut scenario, player_four);
            add_player(&mut game, player_four, test_scenario::ctx(&mut scenario));
            let all_players = &mut get_players(&game);
            assert!(vector::length(all_players) == 1, 1001000);

            let all_players = &mut get_players(&game);
            assert!(vector::length(all_players) == 1, 1001000);
            vector::push_back<address>(all_players, player_four);
            
            // Why 2?
            assert!(vector::length(all_players) == 2, 1001000);
            vector::push_back<address>(all_players, player_one);
            assert!(vector::length(all_players) == 3, 1001000);

        test_scenario::next_tx(&mut scenario, player_one);
            let all_players = &mut get_players(&game);
            assert!(vector::length(all_players) == 1, 1001000);

        test_scenario::next_tx(&mut scenario, player_four);
            let all_players = &mut get_players(&game);
            assert!(vector::length(all_players) == 1, 1001000);

        transfer::share_object(game);

        test_scenario::end(scenario);
    }
}
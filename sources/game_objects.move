// This works in conjunction with the 'game' and 'colors' module. 
// Here are the most basic functionalities of the card game.
// Structures such as 'Game' are implemented, which hosts all
// the necessary information regarding players and shots, among others.

module local::game_objects {
    friend local::game;

    use local::colors::{Self, Color};
    use std::ascii::{Self, String};
    use std::vector;
    use std::signer;
    use std::hash;
    use sui::object::{Self, ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::event;

    const EMIN_NUMBER_OF_PLAYERS_NOT_REACHED: u8 = 2;
    const ENON_ADMIN_ENDING_GAME: u8 = 7;
    const ESIGNER_IS_NOT_ADMIN_OF_GAME: u8 = 8;

    // NFT with unique id of the game linked with special Decks so that previous ones do not work.
    // The'rounds' slot is type-vector which stores a Card-type vector. Its intention is to record all the
    // moves of the players.

    // Figure that houses a game ID, the administrator's address, a maximum number of players, the players,
    // the players who have thrown in each round and the cards that they have used.
    struct Game has key, copy, drop {
        id: ID,
        admin: address,
        max_number_of_players: u8,
        players: vector<address>,
        rounds: VecMap<u8, vector<address>>,
        moves: VecMap<address, vector<Card>>,
    }

    // The basic shape of a card that has a number and a color is housed.
    // There is also a pending option to implement special cards in the future.
    struct Card has key, store, copy, drop {
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
    struct Deck has key, store, copy, drop{
        id: ID,
        id_from_game: ID,
        card: vector<Card>,
        amount: u8,
        state: VecMap<String, bool>,
        //special_cards: bool
    }


    // === `Basic` functions ===

    // Changes to true if the player has already checked that they have a card available to play 
    // and to false if the person has already thrown or does not have a card available to play.
    public(friend) fun update_state(addr: address, stat: bool) acquires Deck {
        let status = vec_map::get_mut(&mut borrow_global_mut<Deck>(addr).state, &ascii::string(b"Checked"));
        *status = stat;
    }

    // Records that a person has already played in the current round.
    public(friend) fun check_participation(s: &signer) acquires Game {
        let game_rounds = get_game(signer::address_of(s)).rounds;
        let round_number = (vec_map::size(&game_rounds) as u8);

        if(vec_map::is_empty<u8, vector<address>>(&game_rounds)) {
            vec_map::insert(&mut game_rounds, 1, vector::singleton(signer::address_of(s)));
        } else {
            let addresses = vec_map::get_mut(&mut game_rounds, &round_number);
            vector::push_back(addresses, signer::address_of(s));
        };

        let participations = vec_map::get(&mut game_rounds, &round_number);
        if(vector::length(participations) == vector::length(&get_players(s))) {
            vec_map::insert(&mut game_rounds, round_number + 1, vector::empty<address>());
        }
    }

    // Wins and finishes the game by dropping the struct 'Game'.
    public(friend) fun win(s: &signer, cards: vector<Card>) acquires Game {
        let game_won_and_finished: String = ascii::string(b"You won the game!");
        event::emit(cards);
        event::emit(game_won_and_finished);

        end_game(s);
    }

    // Drops the current 'Game' struct.
    public(friend) fun end_game(s: &signer) acquires Game {
        assert!(get_game(signer::address_of(s)).admin == signer::address_of(s),
            (ENON_ADMIN_ENDING_GAME as u64));

        get_game(signer::address_of(s));
    }

    // Makes one person the admin when the game starts. Here the new admin 
    // will be given a 'Game' structure with its address as identifier.
    public(friend) fun be_the_game_admin_at_start(s: &signer, number_of_players: u8) {
        assert!(number_of_players > 1, (EMIN_NUMBER_OF_PLAYERS_NOT_REACHED as u64));

        let moves = vec_map::empty<address, vector<Card>>();
        vec_map::insert(&mut moves, signer::address_of(s), vector::empty<Card>());

        move_to(s, 
            Game {
                id: object::id_from_address(signer::address_of(s)),
                admin: signer::address_of(s),
                max_number_of_players: number_of_players,
                players: vector::singleton<address>(signer::address_of(s)),
                rounds: vec_map::empty<u8, vector<address>>(),
                moves,
            }
        );
    }

    // An admin can give game control to another player.
    public(friend) fun give_administration(s: &signer, addr: address) acquires Game {
        transfer::transfer(get_game(signer::address_of(s)), addr);
    }

    // Confirm that someone has the structure 'Game' and is therefore
    // the admin of the game.
    public(friend) fun is_admin(addr: &address): bool {
        exists<Game>(*addr)
    }
    
    // A player will be removed from the player list in 'Game'.
    public(friend) fun leave_game(s: &signer) acquires Game {
        let players = get_players(s);
        let j: u64;
        
        (_, j) = vector::index_of(&players, &signer::address_of(s));

        vector::remove(&mut players, j);
    }

    // An admin can add someone to the player list and give them a deck.
    public(friend) fun add_player(s: &signer, new_player: address) acquires Game, Deck {
        assert!(exists<Game>(signer::address_of(s)), (ESIGNER_IS_NOT_ADMIN_OF_GAME as u64));

        let all_players = get_players(s);
        let new_moves = get_moves(s);

        transfer::transfer(new_deck(s, new_player), new_player);
        vector::push_back(&mut all_players, new_player);
        vec_map::insert(&mut new_moves, new_player, vector::empty<Card>());
        transfer::share_object(get_game(new_player));
    }

    // A new deck is created with all available attributes. Exactly 7 random cards will be given to play.
    public(friend) fun new_deck(s: &signer, new_player: address): Deck acquires Deck, Game {
        let i = 0u8;
        let state = vec_map::empty<String, bool>();
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);

        let deck = Deck {
            id: object::id_from_address(new_player),
            id_from_game: get_game(signer::address_of(s)).id,
            card: vector::empty<Card>(),
            amount: 7,
            state,
        };

        while( i < 7 ) {
            vector::push_back( &mut deck.card, generate_random_card(s) )
        };

        deck
    }

    // Summons a new random card and appends it to players deck.
    // It is usually used when the player cannot play more cards than he owns.
    public(friend) fun add_new_card_to_deck(s: &signer) acquires Deck {
        vector::push_back(&mut get_cards_in_deck(&get_deck(s)), generate_random_card(s));
    }

    // Generates random cards. There are 9 for each color (red, green, blue and yellow).
    fun generate_random_card(s: &signer): Card acquires Deck {
        let hashed = hash::sha2_256(object::id_bytes(&get_deck(s)));
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

    // It tells if a player can throw or if he doesn't have the right cards.
    public(friend) fun get_state(addr: address): bool acquires Deck {
        *vec_map::get(&borrow_global<Deck>(addr).state, &ascii::string(b"Checked"))
    }

    // It is consulted in 'Game' what is the maximum number of players in the game.
    public(friend) fun get_max_number_of_players(s: &signer): u64 acquires Game {
        (borrow_global_mut<Game>(signer::address_of(s)).max_number_of_players as u64)
    }
    
    // A player is shown their deck.
    public(friend) fun get_deck(s: &signer): Deck acquires Deck {
        *borrow_global<Deck>(signer::address_of(s))
    }

    // The 'Game' structure is shown to a player.
    public(friend) fun get_game(addr: address): Game acquires Game {
        *borrow_global_mut<Game>(addr)
    }

    // Rounds are displayed.
    public(friend) fun get_rounds(addr: address): VecMap<u8, vector<address>> acquires Game {
        get_game(addr).rounds
    }

    // Player list is displayed.
    public(friend) fun get_players(s: &signer): vector<address> acquires Game {
        borrow_global<Game>(signer::address_of(s)).players
    }

    // The list of cards used by each player is displayed.
    public(friend) fun get_moves(s: &signer): VecMap<address, vector<Card>> acquires Game {
        borrow_global<Game>(signer::address_of(s)).moves
    }

    // The cards available in a player's deck are displayed.
    public(friend) fun get_cards_in_deck(self: &Deck): vector<Card> {
        self.card
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
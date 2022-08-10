module local::objects {
    friend local::game;

    use std::ascii::{Self, String};
    use local::colors::{Self, Color};
    use std::vector;
    use std::signer;
    use sui::object::{Self, ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use std::hash;

    const EMIN_NUMBER_OF_PLAYERS_NOT_REACHED: u8 = 2;
    const ENON_ADMIN_ENDING_GAME: u8 = 7;

    // NFT with unique id of the game linked with special Decks so that previous ones do not work.
    // The'rounds' slot is type-vector which stores a Card-type vector. Its intention is to record all the
    // moves of the players.
    // TODO: figure out how to share this structure from the admin to the other players. The idea
    // is that it remains property of the admin.
    struct Game has key, copy, drop {
        id: ID,
        admin: address,
        max_number_of_players: u8,
        players: vector<address>,
//        moves: vector<Playing_Moves>,
        moves: VecMap<address, vector<Card>>,
    }

    struct Card has key, store, copy, drop {
        number: u8,
        color: Color,
        //special: bool,
    }
    
    struct Deck has key, store, copy, drop{
        id: ID,
        id_from_game: ID,
        card: vector<Card>,
        amount: u8,
        state: VecMap<String, bool>,
        //special: bool
    }

    // Tells if player has checked wether it has a card to play in his round.
    // TODO: Used later to take new random cards from de pile.
   /* struct Status_Available_Cards {
//        status: vector<bool>,
        status: VecMap<String, bool>,
    }*/

    /*struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}*/

    public(friend) fun get_state(addr: address): bool acquires Deck {
        *vec_map::get(&borrow_global<Deck>(addr).state, &ascii::string(b"Checked"))
    }

    public(friend) fun update_state(addr: address, stat: bool) acquires Deck {
        let status = vec_map::get_mut(&mut borrow_global_mut<Deck>(addr).state, &ascii::string(b"Checked"));
        *status = stat;
    }

    // Drops the current 'Game' struct.
    public(friend) fun end_game(s: &signer) acquires Game {
        assert!(get_game(signer::address_of(s)).admin == signer::address_of(s),
            (ENON_ADMIN_ENDING_GAME as u64));

        get_game(signer::address_of(s));
    }

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
                moves,
            }
        );
    }

    public(friend) fun give_administration(s: &signer, addr: address) acquires Game {
        transfer::transfer(get_game(signer::address_of(s)), addr);
    }

    public(friend) fun is_admin(addr: &address): bool {
        exists<Game>(*addr)
    }
    
    // TODO: implement testing on this function.
    // TODO: it currently works only with the admin. Need to be implemented by the other
    // players too. Maybe whith the sharing atribute mentioned on line 12.
    public(friend) fun leave_game(s: &signer) acquires Game {
        let players = get_players(s);
        let j: u64;
        
        (_, j) = vector::index_of(&players, &signer::address_of(s));

        vector::remove(&mut players, j);
    }

    // TODO: esta se ve rara porque no puede usar get_players si todavia no esta en el juego.
    public(friend) fun add_player(s: &signer, new_players_address: address) acquires Game, Deck {
        let all_players = get_players(s);
        let new_moves = get_moves(s);

        move_to(&new_players_address, new_deck(s, &new_players_address));
        vector::push_back(&mut all_players, &new_players_address);
        vec_map::insert(&mut new_moves, &new_players_address, vector::empty<Card>());
        transfer::share_object(get_game(&new_players_address));
    }

    //TODO: agregar que la deck tenga el mismo id que el 'Game'. Pero se tiene que arreglar primero add_player().
    public(friend) fun new_deck(s: &signer, new_players_address: address): Deck acquires Deck {
        let i = 0u8;
        let state = vec_map::empty<String, bool>();
        vec_map::insert<String, bool>(&mut state, ascii::string(b"Checked"), false);

        let deck = Deck {
            id: object::id_from_address(&new_players_address),
            id_from_game: get_game(),
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
        vector::push_back(&mut unpack_deck_into_cards(&get_deck(s)), generate_random_card(s));
    }

    // Generates random cards. There are 9 for each color.
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

    public(friend) fun get_max_number_of_players(s: &signer): u64 acquires Game {
        (borrow_global_mut<Game>(signer::address_of(s)).max_number_of_players as u64)
    }
    
    //gives problems
    public(friend) fun get_deck(s: &signer): Deck acquires Deck {
        *borrow_global<Deck>(signer::address_of(s))
    }

    // TODO: Adapt this so every player is able to call it. Currently only the admin can do that.
    // Maybe with the sharing feature.
    /*public fun get_moves(s: &signer): &mut vector<vector<Card>> acquires Game {
        &mut borrow_global_mut<Game>(signer::address_of(s)).moves
    }*/

    // TODO: Adapt this so every player is able to call it. Currently only the admin can do that.
    // Maybe with the sharing feature. 
    public fun get_game(addr: address): Game acquires Game {
        *borrow_global_mut<Game>(addr)
    }

    public(friend) fun get_players(s: &signer): vector<address> acquires Game {
        borrow_global<Game>(signer::address_of(s)).players
    }

    public(friend) fun get_moves(s: &signer): VecMap<address, vector<Card>> acquires Game {
        borrow_global<Game>(signer::address_of(s)).moves
    }

    public(friend) fun unpack_deck_into_cards(self: &Deck): vector<Card> {
        self.card
    }

    public(friend) fun index_color(self: &Deck, i: u64): Color {
        vector::borrow(&self.card, i).color
    }

    public(friend) fun index_number(self: &Deck, i: u64): u8 {
        vector::borrow(&self.card, i).number
    }

    public(friend) fun get_color(self: &Card): Color {
        self.color
    }

    public(friend) fun get_number(self: &Card): u8 {
        self.number
    }
}
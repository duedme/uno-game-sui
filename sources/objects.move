module local::objects {
    use local::colors::{Self, Color};
    use std::vector;
    use std::signer;
    use sui::object::{Self, ID};

    const EMIN_NUMBER_OF_PLAYERS_NOT_REACHED: u8 = 2;

    // NFT with unique id of the game linked with special Decks so that previous ones do not work.
    // The'rounds' slot is type-vector which stores a Card-type vector. Its intention is to record all the
    // moves of the players.
    // TODO: figure out how to share this structure from the admin to the other players. The idea
    // is that it remains property of the admin.
    struct Game has key {
        id: ID,
        max_number_of_players: u8,
        players: vector<address>,
        moves: vector<vector<Card>>,
    }

    struct Card has key, store, copy, drop {
        number: u8,
        color: Color,
        //special: bool,
    }
    
    struct Deck has key, store, copy, drop{
        id: ID,
        card: vector<Card>,
        amount: u8,
        //special: bool
    }

    /*struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}*/

    public fun be_the_game_admin(s: &signer, number_of_players: u8) {
        assert!(number_of_players > 1, (EMIN_NUMBER_OF_PLAYERS_NOT_REACHED as u64));
        move_to(s, 
            Game {
                id: object::id_from_address(signer::address_of(s)),
                max_number_of_players: number_of_players,
                players: vector::singleton<address>(signer::address_of(s)),
                moves: vector::empty<vector<Card>>(),
            }
        );
    }

    public fun is_admin(addr: &address): bool {
        exists<Game>(*addr)
    }
    
    // TODO: implement testing on this function.
    // TODO: it currently works only with the admin. Need to be implemented by the other
    // players too. Maybe whith the sharing atribute mentioned on line 12.
    public fun leave_game(s: &signer) acquires Game {
        let players = *get_players(s);
        let j: u64;
        
        (_, j) = vector::index_of(&players, &signer::address_of(s));

        vector::remove(&mut players, j);

    }

    public fun add_player(s: &signer) acquires Game {
        let all_players = *get_players(s);
        move_to(s, new_deck(s));
        vector::push_back(&mut all_players, signer::address_of(s));
    }

    public fun new_deck(s: &signer): Deck {
        let i = 0u8;

        let deck = Deck {
            id: object::id_from_address(signer::address_of(s)),
            card: vector::empty<Card>(),
            amount: 7,
        };

        while( i < 7 ) {
            vector::push_back( &mut deck.card, generate_random_cards() )
        };

        deck
    }

    // ###Check it to make sure it works well.
    fun generate_random_cards(): Card { Card { number: 0, color: colors::return_red() }}

    public fun get_max_number_of_players(s: &signer): u64 acquires Game {
        (borrow_global_mut<Game>(signer::address_of(s)).max_number_of_players as u64)
    }
    
    //gives problems
    public fun get_deck(s: &signer): &Deck acquires Deck {
        borrow_global<Deck>(signer::address_of(s))
    }

    // TODO: Adapt this so every player is able to call it. Currently only the admin can do that.
    // Maybe with the sharing feature.
    /*public fun get_moves(s: &signer): &mut vector<vector<Card>> acquires Game {
        &mut borrow_global_mut<Game>(signer::address_of(s)).moves
    }*/

    // TODO: Adapt this so every player is able to call it. Currently only the admin can do that.
    // Maybe with the sharing feature. 
    /*public fun get_game(s: &signer): &Game acquires Game {
        borrow_global_mut<Game>(signer::address_of(s))
    }*/

    public fun get_players(s: &signer): &vector<address> acquires Game {
        &borrow_global<Game>(signer::address_of(s)).players
    }

    public fun unpack_deck_into_cards(self: &Deck): vector<Card> {
        self.card
    }

    public fun index_color(self: &Deck, i: u64): Color {
        vector::borrow(&self.card, i).color
    }

    public fun index_number(self: &Deck, i: u64): u8 {
        vector::borrow(&self.card, i).number
    }

    public fun get_color(self: &Card): Color {
        self.color
    }

    public fun get_number(self: &Card): u8 {
        self.number
    }
}
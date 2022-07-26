module local::objects {
    use local::colors::{Self, Color};
    use std::vector;
    use std::signer;
    use sui::id::{Self, ID};
    //use sui::epoch_time_lock::{Self, EpochTimeLock};

    struct Card has key, store, copy, drop {
        number: u8,
        color: Color,
        //special: bool,
    }

    /*struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}*/

    struct Deck has key {
        id: ID,
        card: vector<Card>,
        amount: u8,
        //special: bool
    }

    public fun new_deck(s: &signer): Deck {
        let i = 0u8;

        let deck = Deck {
            id: id::new(signer::address_of(s)),
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
    
    //gives problems
    public fun get_deck(s: &signer): &Deck acquires Deck {
        borrow_global<Deck>(signer::address_of(s))
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

    public fun init() {}
}
module local::objects {
    use local::colors::Color;
    use std::vector;

    struct Card has key, store, copy {
        number: u8,
        color: Color,
        special: bool,
    }

    /*struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}*/

    struct Deck has key, store {
        card: vector<Card>,
        amount: u8,
        special: bool
    }
    
    public fun unpack_deck(self: &mut Deck): &vector<Card> {
        &self.card
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
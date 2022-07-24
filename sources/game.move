module local::game {
    use local::objects::{Self, Deck, Card};
    use local::colors::Color;
    use std::signer;
    use std::vector;

    struct Place has key {
        last_card: Card,
    }

    entry fun split_cards(_players: u8) {}

    fun create_deck() {}

    public fun compare_cards(s: &signer, deck: &mut Deck): (bool, u64) acquires Place {
        let last_card = &borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let pack: &vector<Card> = objects::unpack_deck(deck);
        let color_pack: vector<Color> = vector::empty<Color>();
        let number_pack: vector<u8> = vector::empty<u8>();
        let _check: bool = false;
        let i: u64 = 0;

        while(i < vector::length(pack)) {
            vector::push_back(&mut color_pack, objects::index_color(deck, i));
            vector::push_back(&mut number_pack, objects::index_number(deck, i));
            i = i + 1;
        };

        (_check, i) = vector::index_of<Color>(&color_pack, &objects::get_color(last_card));
        if (_check == true) return (_check, i);
        (_check, i) = vector::index_of<u8>(&number_pack, &objects::get_number(last_card));
        (_check, i)

    }

}
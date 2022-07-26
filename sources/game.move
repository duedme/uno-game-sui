module local::game {
    use local::objects::{Self, Deck, Card};
    use local::colors::Color;
    use std::signer;
    use std::vector;
    use sui::event;

    struct Place has key {
        last_card: Card,
    }

    entry fun enter_new_player() {}

    public fun check_cards(s: &signer): (bool, u64) acquires Place {
        let deck: &Deck = objects::get_deck(s);
        let last_card = &borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let pack: &vector<Card> = &objects::unpack_deck_into_cards(deck);
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
        event::emit(*pack);
        (_check, i)

    }

    public fun use_card(s: &signer, card: Card) acquires Place {
        let last_card = &mut borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let deck: &Deck = objects::get_deck(s);
        let cards_in_deck = objects::unpack_deck_into_cards(deck);
        
        *last_card = card;
        let (_, i) = vector::index_of(&cards_in_deck, last_card);
        vector::remove(&mut cards_in_deck, i);

        let new_cards_in_deck = objects::unpack_deck_into_cards(deck);
        event::emit(new_cards_in_deck);
    }

    public fun compare_cards_and_use(s: &signer) acquires Place {
        let (_check, i) = check_cards(s);
        if (_check) {
            let deck: &Deck = objects::get_deck(s);
            let card = vector::borrow(&objects::unpack_deck_into_cards(deck), i);
            use_card(s, *card); 
        }
    }

}
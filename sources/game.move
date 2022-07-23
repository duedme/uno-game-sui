module local::game {
    use local::objects::{Card, Deck};
    use std::signer;

    struct Place has store {
        last_card: Card,
    }

    public fun split(players: u8) {}

    public fun use_card(card: Deck) acquires Balance {
        let place = borrow_global<Place>(signer::balance_of(&signer));
    }

}
module local::game {
    use std::ascii::{Self, String};
    use local::objects::{Self, Deck, Card};
    use local::colors::Color;
    use std::signer;
    use std::vector;
    use sui::event;

    const EMAX_NUMBER_OF_PLAYERS_REACHED: u8 = 1;
    const EADMIN_WANTS_TO_LEAVE: u8 = 3;

    // Tells if player has checked wether it has a card to play in his round
    struct Status_Available_Cards {
        status: vector<bool>,
    }

    struct Rounds {}

    // Simulate the place where everyone can see the cards played
    struct Place has key {
        last_card: vector<Card>,
    }

    // Adds a new player
    fun enter_new_player(s: &signer) {
        assert!(vector::length(objects::get_players(s)) < objects::get_max_number_of_players(s),
            (EMAX_NUMBER_OF_PLAYERS_REACHED as u64));
        objects::add_player(s);
    }

    fun make_someone_an_admin(s: &signer)

    // Starts a game with a defined number of players.
    fun new_game(number_of_players: u8, s: &signer) {
        objects::be_the_game_admin_at_start(s, number_of_players);
        let starting_deck = objects::new_deck(s);
        event::emit(starting_deck);
    }

    fun quit_game(s: &signer, _deck: Deck) {
        assert!(!objects::is_admin(&signer::address_of(s)), (EADMIN_WANTS_TO_LEAVE as u64));
        objects::leave_game(s);
    }

    fun shout_UNO(s: &signer) {
        let deck = objects::get_deck(s);
        let uno: String = ascii::string(b"UNO!");
        if (vector::length(&objects::unpack_deck_into_cards(deck)) == 1) { event::emit(uno) }
    }

    // TODO: find a way to list all players who call enter_new_player().
    fun list_all_players() {}

    fun win_or_lose() {}


    // Check if one has a card available to play
    public fun check_cards(s: &signer): (bool, u64) acquires Place {
        let deck: &Deck = objects::get_deck(s);
        let last_card = &borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let length_of_place = vector::length(last_card);
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
//--
        (_check, i) = vector::index_of<Color>(&color_pack, &objects::get_color(vector::borrow(last_card, length_of_place - 1)));
        if (_check == true) return (_check, i);
        (_check, i) = vector::index_of<u8>(&number_pack, &objects::get_number(vector::borrow(last_card, length_of_place - 1)));
        event::emit(*pack);
        (_check, i)

    }

    // Use the card once it is known that it can be played
    // TODO: design a status system to check if the card is available for use
    public fun use_card(s: &signer, card: Card) acquires Place {
        let last_card = &mut borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let length_of_place = vector::length(last_card);
        let deck: &Deck = objects::get_deck(s);
        let cards_in_deck = objects::unpack_deck_into_cards(deck);
        
        // adds the card in the deck to the pile of used ones
        vector::push_back(last_card, card);

        // --
        // Finds and deletes the used card of player's current deck
        let (_, i) = vector::index_of(&cards_in_deck, vector::borrow(last_card, length_of_place - 1));
        vector::remove(&mut cards_in_deck, i);

        event::emit(objects::unpack_deck_into_cards(deck));
    }

    // Use compare_cards and use_cards one after the other
    public fun compare_cards_and_use(s: &signer) acquires Place {
        let (_check, i) = check_cards(s);
        if (_check) {
            let deck: &Deck = objects::get_deck(s);
            let card = vector::borrow(&objects::unpack_deck_into_cards(deck), i);
            use_card(s, *card); 
        }
    }

}
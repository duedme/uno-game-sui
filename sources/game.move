// Here are the basic functionalities of a card game based on UNO.
//
// 

module local::game {
    use std::ascii::{Self, String};
    use local::game_objects::{Self, Deck, Card};
    use local::colors::Color;
    use std::signer;
    use std::vector;
    use sui::event;

    const EMAX_NUMBER_OF_PLAYERS_REACHED: u8 = 1;
    const EADMIN_WANTS_TO_LEAVE: u8 = 3;
    const ENOT_ADMIN: u8 = 4;
    const ECARD_NOT_CHECKED: u8 = 5;
    const ECARD_ALREADY_CHECKED: u8 = 6;
    const EADDRESS_IS_NOT_ADMIN_OF_ANY_GAME: u8 = 7;

    // Simulate the place where everyone can see the cards played
    struct Place has key {
        last_card: vector<Card>,
    }

    // Adds a new player.
    // Currently only admins can call this function.
    fun enter_new_player(s: &signer, games_admin: address) {
        assert!(vector::length(&game_objects::get_players(s)) < game_objects::get_max_number_of_players(s),
            (EMAX_NUMBER_OF_PLAYERS_REACHED as u64));
        game_objects::add_player(s, games_admin);
    }

    fun make_someone_an_admin(s: &signer, new_admin: address) {
        assert!(game_objects::is_admin(&signer::address_of(s)), (ENOT_ADMIN as u64));
        game_objects::give_administration(s, new_admin);
    }

    // Starts a game with a defined number of players.
    fun new_game(number_of_players: u8, s: &signer) {
        game_objects::be_the_game_admin_at_start(s, number_of_players);
        let starting_deck = game_objects::new_deck(s, signer::address_of(s));
        event::emit(starting_deck);
    }

    //Lets a player quit the game. If he was the last one. UNO automatically ends.
    fun quit_game(s: &signer, _deck: Deck) {
        assert!(!game_objects::is_admin(&signer::address_of(s)), (EADMIN_WANTS_TO_LEAVE as u64));
        game_objects::leave_game(s);
        
        if(vector::length(&game_objects::get_players(s)) == 0) { game_objects::end_game(s); }
    }

    fun shout_UNO(s: &signer) {
        let deck = game_objects::get_deck(s);
        let uno: String = ascii::string(b"UNO!");
        if (vector::length(&game_objects::unpack_deck_into_cards(&deck)) == 1) { event::emit(uno) }
    }

    // Wins and finishes the game by dropping the struct 'Game'.
    fun win(s: &signer, cards: vector<Card>) {
        let game_won_and_finished: String = ascii::string(b"You won the game!");
        event::emit(cards);
        event::emit(game_won_and_finished);

        game_objects::end_game(s);
    }


    // Checks if player has an available card to play.
    public fun check_cards(s: &signer): (bool, u64) acquires Place {
        assert!(game_objects::get_state(signer::address_of(s)) == false, (ECARD_ALREADY_CHECKED as u64));

        let deck: Deck = game_objects::get_deck(s);
        let last_card = &borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let pack_of_cards: &vector<Card> = &game_objects::unpack_deck_into_cards(&deck);
        let color_pack: vector<Color> = vector::empty<Color>();
        let number_pack: vector<u8> = vector::empty<u8>();
        let _check: bool = false;
        let i: u64 = 0;


        while(i < vector::length(pack_of_cards)) {
            vector::push_back(&mut color_pack, game_objects::index_color(&deck, i));
            vector::push_back(&mut number_pack, game_objects::index_number(&deck, i));
            i = i + 1;
        };

        (_check, i) = vector::index_of<Color>(&color_pack, &game_objects::get_color(vector::borrow(last_card, vector::length(last_card) - 1)));
        if (_check == true) {
            game_objects::update_state(signer::address_of(s), true);
            event::emit(*pack_of_cards);
            return (_check, i)
        };

        (_check, i) = vector::index_of<u8>(&number_pack, &game_objects::get_number(vector::borrow(last_card, vector::length(last_card) - 1)));
        if (_check == true) {
            game_objects::update_state(signer::address_of(s), true);
            event::emit(*pack_of_cards);
            return (_check, i)
        };

        // Since player has no matching cards, he will be given a new random one.
        game_objects::add_new_card_to_deck(s);

        (_check, i)
    }

    // Use the card once it is known that it can be played.
    // If player has only one card left, the game will automatically shout UNO!
    // TODO: Revisar quela carta a la que se aplico el estado sea realmente esa.
    //     Porque si no cualquiera confirma una carta roja y despues usara la verde que no queda.
    public fun use_card(s: &signer, card: Card) acquires Place {
        assert!(game_objects::get_state(signer::address_of(s)) == true, (ECARD_NOT_CHECKED as u64));

        let last_card = &mut borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let length_of_place = vector::length(last_card);
        let deck: Deck = game_objects::get_deck(s);
        let cards_in_deck = game_objects::unpack_deck_into_cards(&deck);
        
        // adds the card in the deck to the pile of used ones
        vector::push_back(last_card, card);

        // --
        // Finds and deletes the used card of player's current deck
        let (_, i) = vector::index_of(&cards_in_deck, vector::borrow(last_card, length_of_place - 1));
        vector::remove(&mut cards_in_deck, i);

        event::emit(game_objects::unpack_deck_into_cards(&deck));

        if(vector::length(&cards_in_deck) == 1) { shout_UNO(s); };

        if(vector::length(&cards_in_deck) == 0) { win(s, cards_in_deck); };

        game_objects::update_state(signer::address_of(s), false);

        game_objects::check_participation(s);
    }

    // Use compare_cards and use_cards one after the other
    public fun compare_cards_and_use(s: &signer) acquires Place {
        let (_check, i) = check_cards(s);
        if (_check) {
            let deck: Deck = game_objects::get_deck(s);
            let card = vector::borrow(&game_objects::unpack_deck_into_cards(&deck), i);
            use_card(s, *card); 
        }
    }
}
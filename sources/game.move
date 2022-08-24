// The basic functionalities of a card game based on UNO.
//
// The way to start playing is to use the new_game() function which 
// will give the game management and a deck of cards automatically.
// When deciding the number of players in the game, 
// remember that there can only be up to 10 of them.
//
// Other players can join later by calling enter_new_player(). 
// Currently only the admin can call that method.
//
// This module works with the help of game_assets which carries 
// important methods and structures for the game.
//
// TODO: Check that the card to which the status was applied is really the one to be played.
// TODO: implement special cards. For example: +2, +4, etc.

module local::uno {
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
    const EA_LOT_OF_PLAYERS_WANT_TO_PLAY: u8 = 9;

    // Simulates the place on the table where the played cards are left.
    struct Place has key {
        last_card: vector<Card>,
    }

    // Gives the player a sample of all the game information.
    fun know_game(s: &signer) {
        event::emit(game_objects::get_game(signer::address_of(s)));
    }

    // Adds a new player.
    // Currently only admins can call this function.
    public fun enter_new_player(s: &signer, games_admin: address) {
        assert!(vector::length(&game_objects::get_players(s)) < game_objects::get_max_number_of_players(s),
            (EMAX_NUMBER_OF_PLAYERS_REACHED as u64));
        game_objects::add_player(s, games_admin);
    }

    // Admins can make other players the current game admins.
    // There can only be one at a time.
    public fun make_someone_an_admin(s: &signer, new_admin: address) {
        assert!(game_objects::is_admin(&signer::address_of(s)), (ENOT_ADMIN as u64));
        game_objects::give_administration(s, new_admin);
    }

    // Starts a game with a defined number of players.
    public fun new_game(number_of_players: u8, s: &signer) {
        assert!(number_of_players <= 10, (EA_LOT_OF_PLAYERS_WANT_TO_PLAY as u64));
        game_objects::be_the_game_admin_at_start(s, number_of_players);
        let starting_deck = game_objects::new_deck(s, signer::address_of(s));
        event::emit(starting_deck);
    }

    //Lets a player quit the game. If he was the last one. UNO automatically end.
    // Admins cannot exit until they have transferred the game to another player.
    public fun quit_game(s: &signer) {
        assert!(!game_objects::is_admin(&signer::address_of(s)), (EADMIN_WANTS_TO_LEAVE as u64));
        game_objects::leave_game(s);
        
        if(vector::length(&game_objects::get_players(s)) == 0) { game_objects::end_game(s); }
    }
    // Simulate saying "UNO!" when playing the classic game._check
    public fun shout_UNO(s: &signer) {
        let deck = game_objects::get_deck(s);
        let uno: String = ascii::string(b"UNO!");
        if (vector::length(&game_objects::get_cards_in_deck(&deck)) == 1) { event::emit(uno) }
    }

    // Checks if player has an available card to play.
    // Factors such as the color and number of cards available in the player's deck are reviewed.
    // The game automatically checks to see if the player has already checked that they have a card available.
    // If player didn't have one, the game will give a random one.
    // 
    public fun check_cards(s: &signer): (bool, u64) acquires Place {
        assert!(game_objects::get_state(signer::address_of(s)) == false, (ECARD_ALREADY_CHECKED as u64));

        let deck: Deck = game_objects::get_deck(s);
        let last_card = &borrow_global_mut<Place>(signer::address_of(s)).last_card;
        let pack_of_cards: &vector<Card> = &game_objects::get_cards_in_deck(&deck);
        let color_pack: vector<Color> = vector::empty<Color>();
        let number_pack: vector<u8> = vector::empty<u8>();
        let _check: bool = false;
        let i: u64 = 0;


        while(i < vector::length(pack_of_cards)) {
            vector::push_back(&mut color_pack, game_objects::get_index_color(&deck, i));
            vector::push_back(&mut number_pack, game_objects::get_index_number(&deck, i));
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
    public fun use_card(s: &signer, card: Card) acquires Place {
        let last_card = &mut borrow_global_mut<Place>(signer::address_of(s)).last_card;

        if(vector::is_empty(last_card)) { game_objects::update_state(signer::address_of(s), true); };
        assert!(game_objects::get_state(signer::address_of(s)) == true, (ECARD_NOT_CHECKED as u64));

        let length_of_place = vector::length(last_card);
        let deck: Deck = game_objects::get_deck(s);
        let cards_in_deck = game_objects::get_cards_in_deck(&deck);
        
        // adds the card in the deck to the pile of used ones
        vector::push_back(last_card, card);

        // Finds and deletes the used card of player's current deck
        let (_, i) = vector::index_of(&cards_in_deck, vector::borrow(last_card, length_of_place - 1));
        vector::remove(&mut cards_in_deck, i);

        event::emit(game_objects::get_cards_in_deck(&deck));

        if(vector::length(&cards_in_deck) == 1) { shout_UNO(s); };

        if(vector::length(&cards_in_deck) == 0) { game_objects::win(s, cards_in_deck); };

        game_objects::update_state(signer::address_of(s), false);

        game_objects::check_participation(s);
    }

    // Use compare_cards and use_cards one after the other
    public fun compare_cards_and_use(s: &signer) acquires Place {
        let (_check, i) = check_cards(s);
        if (_check) {
            let deck: Deck = game_objects::get_deck(s);
            let card = vector::borrow(&game_objects::get_cards_in_deck(&deck), i);
            use_card(s, *card); 
        }
    }
}
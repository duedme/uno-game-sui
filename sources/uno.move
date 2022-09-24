/// The basic functionalities of a card game based on UNO.
///
/// The way to start playing is to use the new_game() function which 
/// will give the game management and a deck of cards automatically.
/// When deciding the number of players in the game, 
/// remember that there can only be up to 10 of them.
///
/// Other players can join later by calling enter_new_player(). 
/// Currently only the admin can call that method.
///
/// This module works with the help of game_assets which carries 
/// important methods and structures for the game.
///
/// @dev TODO: Check that the card to which the status was applied is really the one to be played.
/// @dev TODO: implement special cards. For example: +2, +4, etc.

/// @author Daniel Espejel
/// @title uno
module local::uno {
    use std::ascii::{Self, String};
    use local::game_objects::{Self, Game, Deck, Card};
    use local::colors::Color;
    use std::vector;
    use sui::tx_context::TxContext;
    use sui::vec_map::VecMap;

    const EMAX_NUMBER_OF_PLAYERS_REACHED: u8 = 1;
    const EADMIN_WANTS_TO_LEAVE: u8 = 3;
    const ENOT_ADMIN: u8 = 4;
    const ECARD_NOT_CHECKED: u8 = 5;
    const ECARD_ALREADY_CHECKED: u8 = 6;
    const EADDRESS_IS_NOT_ADMIN_OF_ANY_GAME: u8 = 7;
    const EA_LOT_OF_PLAYERS_WANT_TO_PLAY: u8 = 9;

    /// @notice Gives the player information about who the admin is.
    /// @param game shared between players.
    public entry fun know_admin(game: &Game) {
        game_objects::emit_object<address>(game_objects::get_admin(game));
    }

    /// @notice Gives the player a list of all the players.
    /// @param game shared between players.
    public entry fun know_players(game: &Game) {
        game_objects::emit_object<vector<address>>(game_objects::get_players(game));
    }

    /// @notice Gives the player the number of players in the game.
    /// @param game shared between players.
    public entry fun know_number_of_players(game: &Game) {
        game_objects::emit_object<u8>(game_objects::get_number_of_players(game));
    }

    /// @notice Gives the player the number of rounds that have elapsed.
    /// @param game shared between players.
    public entry fun know_number_of_rounds(game: &Game) {
        game_objects::emit_object<u8>(game_objects::get_number_of_rounds(game));
    }

    /// @notice Gives the player a list of all the moves that have been made.
    /// @param game shared between players.
    public entry fun know_all_moves(game: &Game) {
        game_objects::emit_object<VecMap<address, vector<Card>>>(game_objects::get_moves(game));
    }

    /// @notice Gives the player a list of all cards already used in the game.
    /// @param game shared between players.
    public entry fun know_all_used_cards(game: &Game) {
        game_objects::emit_object<vector<Card>>(game_objects::get_all_used_cards(game));
    }

    /// @notice Gives the player a list of all cards already used in the game.
    /// @param game shared between players.
    public entry fun know_last_card_used_in_game(game: &Game) {
        game_objects::emit_object<Card>(game_objects::get_last_used_card(game));
    }

    /// @notice Gives a list of the player's cards.
    /// @param deck owned by the player calling the method.
    public entry fun know_cards(deck: &Deck) {
        game_objects::emit_object<vector<Card>>(game_objects::get_cards_in_deck(deck));
    }
    
    /// @notice Gives player the number of cards it has left.
    /// @param deck owned by the player calling the method.
    public entry fun know_number_of_cards_left(deck: &Deck) {
        game_objects::emit_object<u8>(game_objects::get_number_of_cards(deck));
    }

    /// @notice Gives the player the number of cards his opponents have left.
    /// @dev TODO: find a way to implement this function.
    public entry fun know_number_opponents_cards_left() {

    }

    /// @notice Adds a new player.
    ///     Currently only admins can call this function.
    /// @para game shared between players.
    /// @param new_player is the address the user that will enter the game.
    /// @dev TODO: check about admin.
    public entry fun enter_new_player(game: &Game, new_player: address, ctx: &mut TxContext) {
        assert!(vector::length(&game_objects::get_players(game)) < game_objects::get_max_number_of_players(game),
            (EMAX_NUMBER_OF_PLAYERS_REACHED as u64));
        game_objects::add_player(game, new_player, ctx);
    }

    /// @notice Admins can make other players the current game admins.
    ///     There can only be one at a time.
    /// @dev TODO: check admin functions.
    public entry fun make_someone_an_admin(game: Game, new_admin: address, _ctx: &mut TxContext) {
        game_objects::give_administration(game, new_admin);
    }

    /// @notice Starts a game with a defined number of players.
    /// @param number_of_players will be the max number of players allowed in the game.
    /// @param ctx is the context of the transaction. Will later be used to pass address.
    /// @dev TODO: check admin functions.
    public entry fun new_game(number_of_players: u8, ctx: &mut TxContext) {
        assert!(number_of_players <= 10, (EA_LOT_OF_PLAYERS_WANT_TO_PLAY as u64));

        // Transfers a new game object to the admin and gives him a new deck.
        game_objects::be_the_game_admin_at_start(number_of_players, ctx);
    }

    /// @notice Lets a player quit the game. If he was the last one. UNO automatically end.
    ///     Admins cannot exit until they have transferred the game to another player.
    /// @param game shared between players.
    /// @param ctx is the context of the transaction. Will later be used to get an address.
    /// @dev TODO: Check admin functions.
    public entry fun quit_game(game: &Game, ctx: &mut TxContext) {
        game_objects::leave_game(game, ctx);
    }

    /// @notice Simulate saying "UNO!" when playing the classic game.
    /// @param deck owned by the player calling the method.
    public fun shout_UNO(deck: &Deck) {
        let uno: String = ascii::string(b"UNO!");
        if (vector::length(&game_objects::get_cards_in_deck(deck)) == 1) { 
            game_objects::emit_object<String>(uno);
        }
    }

    /// @notice Checks if player has an available card to play.
    ///     Factors such as the color and number of cards available in the player's deck are reviewed.
    ///     The game automatically checks to see if the player has already checked that they have a card available.
    ///     If player didn't have one, the game will give a random one.
    /// @param game shared between players.
    /// @param deck owned by the player calling the method. Will inspect deck to check for available cards.
    /// @param ctx is the context of the transaction.
    /// @return tuple bool and u64 representing if a card is available and where.
    /// @dev TODO: Check if TxContext is really needen here.
    /// @dev TODO: Find a way to skip return values (maybe with emit function).
    public fun check_cards(game: &Game, deck: &mut Deck, ctx: &mut TxContext): (bool, u64) {
        assert!(game_objects::get_state(deck) == false, (ECARD_ALREADY_CHECKED as u64));

        let last_card_in_place = &game_objects::get_last_used_card(game);
        let pack_of_cards: &vector<Card> = &game_objects::get_cards_in_deck(deck);
        let color_pack: vector<Color> = vector::empty<Color>();
        let number_pack: vector<u8> = vector::empty<u8>();
        let _check: bool = false;
        let i: u64 = 0;


        while(i < vector::length(pack_of_cards)) {
            vector::push_back(&mut color_pack, game_objects::get_index_color(deck, i));
            vector::push_back(&mut number_pack, game_objects::get_index_number(deck, i));
            i = i + 1;
        };

        (_check, i) = vector::index_of<Color>(&color_pack, &game_objects::get_color(last_card_in_place));
        if (_check == true) {
            game_objects::update_state(deck, true);
            game_objects::emit_object<vector<Card>>(*pack_of_cards);
            return (_check, i)
        };

        (_check, i) = vector::index_of<u8>(&number_pack, &game_objects::get_number(last_card_in_place));
        if (_check == true) {
            game_objects::update_state(deck, true);
            game_objects::emit_object<vector<Card>>(*pack_of_cards);
            return (_check, i)
        };

        // Since player has no matching cards, he will be given a new random one.
        game_objects::add_new_card_to_deck(deck, ctx);

        (_check, i)
    }

    /// @notice Use the card once it is known that it can be played.
    ///     If player has only one card left, the game will automatically shout UNO!
    /// @param game shared between players.
    /// @param deck owned by the player calling the method. A card will be removed from it.
    /// @param card is the item the player will use to play the game.
    /// @param ctx is the context of the transaction. Will later be used to get the user's address.
    public fun use_card(game: &Game, deck: &mut Deck, card: Card, ctx: &mut TxContext) {
        let all_cards = &mut game_objects::get_all_used_cards(game);

        if(vector::is_empty(all_cards)) { game_objects::update_state(deck, true); };
        assert!(game_objects::get_state(deck) == true, (ECARD_NOT_CHECKED as u64));

        //let length_of_place = vector::length(all_cards);
        let cards_in_deck = game_objects::get_cards_in_deck(deck);
        
        // adds the card in the deck to the pile of used ones
        vector::push_back(all_cards, card);

        // Finds and deletes the used card of player's current deck
        let last_card_in_deck = game_objects::get_last_used_card(game);
        let (_, i) = vector::index_of(&cards_in_deck, &last_card_in_deck);
        vector::remove(&mut cards_in_deck, i);

        game_objects::emit_object<vector<Card>>(game_objects::get_cards_in_deck(deck));

        if(vector::length(&cards_in_deck) == 1) { shout_UNO(deck); };

        if(vector::length(&cards_in_deck) == 0) { game_objects::win(/*game, */ctx); }
        else {
            game_objects::update_state(deck, false);

            game_objects::check_participation(game, ctx);

            game_objects::game_continues(cards_in_deck);
        };

    }

    /// @notice Use compare_cards and use_cards one after the other.
    /// @param game shared between players.
    /// @param deck owned by the player calling the method.
    /// @param ctx is the context of the transaction. Will be used as param for check_cards and use_card.
    public entry fun compare_cards_and_use(game: &Game, deck: &mut Deck, ctx: &mut TxContext) {
        let (_check, i) = check_cards(game, deck, ctx);
        if (_check) {
            let card = vector::borrow(&game_objects::get_cards_in_deck(deck), i);
            use_card(game, deck, *card, ctx); 
        }
    }
}
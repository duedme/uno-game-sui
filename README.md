# UNO

UNO based card game.

This card game contains the functionalities of UNO. It contains numbered colored cards so that everyone can collect and play them. Special cards such as +2, +4, reverse, etc. have not been implemented in the current version of the game. Wait for them soon.

## Getting Started

To play this game all you need is to install [SUI](https://docs.sui.io/build/install). At this time you can only play from calls to functions to the Sui network from your console. However, there will soon be a more user-friendly version.

## Prerequisites

The minimum requirements to run the software can be found on the [SUI](https://docs.sui.io/build/install)  website. However you should know that a machine capable of installing command line tools is required.

When installing SUI it will be time to use the commands related to:

    sui client

Those will be our start to play our games of UNO!

More specifically:

    sui client active-address

to know the address which you play with and

    sui call

to call the special functions of the game.    

## Running the game

Here starts a step-by-step example showing you how to get a card game running on your computer from Sui.

This game is already installed on the network under address 0x0 (tentative). What you'll need to do to participate is to call the state functions in your command line interface.

To start a new game you must use the following command:

    sui client call --function new_game --package 0x0 --module uno --args <NUMBER_OF_PLAYERS_YOU_WANT_TO_PLAY_WITH>

You are now a game administrator and you can add your competitors with:

    sui client call --function enter_new_player --package 0x0 --module uno --args \0x<PLAYER_ADDRESS>

Repeat the last step until you have all the platers in the party.


## Starting to play

Now that you have competitors to play with. You will have to start using cards until you win. This game is divided into rounds and you will not advance to the next one until the current one is finished. All players can take their turn at any time of the round if they have a card that is compatible with the one previously drawn. If you do not have it, you must pick up an automatically generated one.

Remember that all the usual cards in a UNO! game are divided into red, blue, yellow and green colors. Each color has ten numbers from 0 to 9. Therefore, each player's deck will have a card generated within the previous possibilities.

To take the first step we can use a function that throws any card. The next player will have to compare if there is a compatible card in their entire deck and use it. So on until the end of the round.
This will happen in the following succession of calls to the console:

    sui client call --function use_card --package 0x0 --module uno --args \"<NUMBER_IN_THE_CARD>\" <COLOR_OF_THE_CARD>

Then the next player can use these ones:

    sui client call --function check_cards --package 0x0 --module uno
    sui client call --function use_card --package 0x0 --module uno --args \"<NUMBER_IN_THE_CARD>\" <COLOR_OF_THE_CARD>

Those last two functions can be summarized in the following one:

    sui client call --function compare_cards_and_use --package 0x0 --module uno

Although the latter won't let you choose the card you want to actually use, the code in SUI will do it for you. However, this may be more comfortable for those players who are more casual and looking for a victory without a great strategy.

## Administration during the game

During the game an admin will be the one who hosts the object with the original game. The other players will only have one copy 'shared' between them. The admin can change this by making a player admin. Remembering that there can only be one during the game though.

To make another player admin you can use the following method:

    sui client call --function make_someone_an_admin --package 0x0 --module uno --args \0x<PLAYER_ADDRESS>

## Exit game

If someone did not want to continue with the game. That user will be able to exit unless they are the game admin. In which case we will have an error until calling the 'make_someone_an_admin' method.

To exit the game you can use:

    sui client call --function quit_game --package 0x0 --module uno

If a player was the last in the game. Using the above call will also drop the game.

## Built With

  - [SUI](https://sui.io/) - Used to build all the on-chain assets in the game.
  - [Move](https://github.com/MystenLabs/awesome-move) - The language used to build UNO!.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code
of conduct, and the process for submitting pull requests to us.


## Authors

  - **Daniel Espejel** - *Writing the Game* -
    [Duedme](https://github.com/Duedme)
  - **Omar Espejel**
  - **Eduardo Espejel**

## License

This project is licensed under the [CC0 1.0 Universal](LICENSE.md)
Creative Commons License - see the [LICENSE.md](LICENSE.md) file for
details

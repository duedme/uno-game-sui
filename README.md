# UNO

UNO based card game.

*Warning: this is experimental code that could change in future versions.*

## What is UNO?

UNO! is a card game with peculiarities regarding the classic Spanish or English cards. 
This game can be used by 2 to 10 people in a single match.

The objective is to get rid of all the cards in possession. Players must shout UNO! when they only have one card left; otherwise they will be penalized with another two extra in their deck.

An usual deck of UNO! contains two types of cards: normal and special.
Normal Cards: this type is divided into red, green, blue and yellow colors. In turn, each color is numbered from 0 to 9.

Special Cards: they have a series of characteristics with abilities to alter the flow of the game. Among them are "Skip", "Reverse", "Draw", "Wild", etc.

This game already has many variations like UNO Flip or UNO Spin. However, in this module we will focus on the classic version of UNO!.

## What is this module?

This module is written in the Move language using the Sui libraries. It contains the basic functionalities of UNO. It includes numbered colored cards so that everyone can collect and play them. Special cards such as +2, +4, reverse, etc. have not been implemented in the current version of the game. Please wait for them soon.


### Why Sui Move?

Sui Move is excellent for creating an environment where there are objects capable of being sent as function arguments, returned in the same medium, and stored inside other objects. They can also be used through different contracts. This is unique to the Move language; it is something that does not exist in other popular languages.

Thanks to this we can manage to create a game object, a deck object and a card object capable of being used in all places without the danger of losing them by accident or putting a game session at risk.

When someone creates a new game session we are also creating a structure called *Game* that stores the information of an administrator, players, rounds, etc. Each player gets a deck that containing information on each player's card and whether or not his cards are special. All those characteristics are mutable for the good of the game and can be sent between players on the Sui Blockchain.

That wouldn't be possible if it weren't for Sui Move's ease in writing concrete, object-oriented contracts. Due to the amount of transactions between players and the high number of active games that could be; the structure of the Sui Blockchain is the best for this implementation.

## Getting Started

To play this game all you need is to install [SUI](https://docs.sui.io/build/install). At this time you can only play from calls to functions to the Sui network from your console. However, there will soon be a more user-friendly version.

### Explicit instructions on how to install SUI on Unix-based systems

This section will briefly tell you how to start a Sui network locally. Later we will connect to the [CLI client](https://docs.sui.io/devnet/build/cli-client) app. With this we will be ready to start playing UNO.

Remember that if you want to get the complete and official instructions you can refer to the [Sui Tutorials](https://docs.sui.io/devnet/explore/tutorials) page where you will find step by step information and variants.

#### Prerequisites

You will need some tools like *Cargo*, *Git CLI* and *CMake*. Please go to the [Sui Prerequisites](https://docs.sui.io/devnet/build/install#prerequisites) page to find out the necessary tools specific to your machine.

#### Sui Binaries

To start we must install the Sui binaries:

    cargo install --locked --git https://github.com/MystenLabs/sui.git --branch "devnet" sui sui-gateway

This will allow us to create accounts, start a Sui network and use the game package.
If the installation was successful, we can start with Genesis.

#### Genesis

The *genesis* command gives you the freedom to use four validators and five user accounts each with five gas objects. Gas objects will help you pay for the transactions required to play UNO.

Start genesis with the following command:

    sui genesis

If you ever want to reset your accounts you can use

    sui genesis --force

to create a whole new set of users.

Next we will start the Sui network.

#### Start Sui network

Run the following command to boot locally.

    sui start

Executing this command in console will not give you an output. The terminal window will be locked because you will now be running an instance of Sui.

#### Comandos proveidos por la Sui network

The following commands are used to interact with the UNO module and interact with your game dynamically.

When installing SUI it will be time to use the commands related to:

    sui client

Those will be our start to play our games of UNO!

More specifically:

    sui client active-address

to know the address which you play with and

    sui client call --function <GAME_METHOD> --package 0x0 --module uno --args <METHOD_ARGUMENTS>

to call the special functions of the game.  

Now open another window and continue to the [Running the Game](#running-the-game) section.

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

This project is still growing and will be improved over time. So feel free to give your opinions and contribute to the source code.

Here are some ways you can support:

* Fix bugs if found.
* Create a branch with a translation to your language.
* Complete documentation in the code if necessary.
* Make tests of the game from your computer.
* Complete some of the tasks marked as "TODO" in the source code

Please feel free to make suggestions and comments to the [Github Issue](https://github.com/Duedme/UNO/issues/1).


## Authors

  - **Daniel Espejel** - *Writing the Game* -
    [Duedme](https://github.com/Duedme)

## License

This project is licensed under the [CC0 1.0 Universal](LICENSE.md)
Creative Commons License - see the [LICENSE.md](LICENSE.md) file for
details

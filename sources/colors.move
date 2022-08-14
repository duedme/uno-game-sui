// It works in conjunction with the game_objects module and its most basic functionality 
// is to create an RGB color system for the game cards.

module local::colors {

    // Structure that stores a vector of integers. As in the RGB system, 
    // the first parameter describes the color red, the second green, and the third blue. 
    // The combination of red and green is almost yellow.
    struct Color has store, copy, drop {
        configuration: vector<u8>
    }

    // === `Basic` functions ===

    // Returns the RGB code for red.
    public fun return_red(): Color {
        Color { configuration: vector<u8>[1, 0, 0] }
    }

    // Returns the RGB code for blue.
    public fun return_blue(): Color {
        Color { configuration: vector<u8>[0, 1, 0] }
    }

    // Returns an RGB code similar to yellow.
    public fun return_yellow(): Color {
        Color { configuration: vector<u8>[1, 1, 0] }
    }

    // Returns the RGB code for green.
    public fun return_green(): Color {
        Color { configuration: vector<u8>[0, 1, 0] }
    }
}

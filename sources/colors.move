/// This works in conjunction with the game_objects module and its most basic functionality 
/// is to create an RGB color system for the UNO! game.

/// @author Daniel Espejel
/// @title colors
module local::colors {
    use std::ascii::{Self, String};

    /// @notice Structure that stores a vector of integers. As in the RGB system, 
    ///     the first parameter describes the color red, the second green, and the third blue. 
    /// @dev The combination of red and green is almost yellow.
    struct Color has store, copy, drop {
        /// This will store a vector with 3 numbers. Each represents a color Red, Green, and Blue.
        configuration: String
    }

    // === `Basic` functions ===

    /// @notice Returns the RGB code for red.
    /// @return color object with RGB configuration of pure red.
    public fun return_red(): Color {
        Color { configuration: ascii::string(b"RED") }
    }

    /// @notice Returns the RGB code for blue.
    /// @return color object with RGB configuration of pure blue.
    public fun return_blue(): Color {
        Color { configuration: ascii::string(b"BLUE") }
    }

    /// @notice Returns an RGB code similar to yellow.
    /// @return color object with RGB configuration close to yellow.
    public fun return_yellow(): Color {
        Color { configuration: ascii::string(b"YELLOW") }
    }

    /// @notice Returns the RGB code for green.
    /// @return color object with RGB configuration of pure green.
    public fun return_green(): Color {
        Color { configuration: ascii::string(b"GREEN") }
    }
}

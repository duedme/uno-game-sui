/// This works in conjunction with the game_objects module and its most basic functionality 
/// is to create a color system for the UNO! game.

/// @author Daniel Espejel
/// @title colors
module local::colors {
    use std::ascii::{Self, String};

    /// @notice Structure that stores a vector of bytes that represents an ascii string. 
    struct Color has store, copy, drop {
        color: String
    }

    // === `Basic` functions ===

    /// @notice Returns a string for the red color.
    /// @return color object with "RED" string.
    public fun return_red(): Color {
        Color { color: ascii::string(b"RED") }
    }

    /// @notice Returns a string for the blue color.
    /// @return color object with "BLUE" string.
    public fun return_blue(): Color {
        Color { color: ascii::string(b"BLUE") }
    }

    /// @notice Returns a string for the yellow color.
    /// @return color object with "YELLOW" string.
    public fun return_yellow(): Color {
        Color { color: ascii::string(b"YELLOW") }
    }

    /// @notice Returns a string for the green color.
    /// @return color object with "GREEN" string.
    public fun return_green(): Color {
        Color { color: ascii::string(b"GREEN") }
    }
}

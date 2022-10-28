/// This works in conjunction with the game_objects module and its most basic functionality 
/// is to create a color system for the UNO! game.

/// @author Daniel Espejel
/// @title colors
module local::colors {
    use std::ascii::{Self, String};

    /// @notice Structure that stores a string describing the color to be used.vector of integers. Color
    ///     options are red, green, blue and yellow. 
    struct Color has store, copy, drop {
        /// This will store a vector with 3 numbers. Each represents a color Red, Green, and Blue.
        configuration: String,
    }

    // === `Basic` functions ===

    /// @notice Returns a String with Red color.
    /// @return string with Red annotated.
    public fun return_red(): Color {
        Color { configuration: ascii::string(b"RED") }
    }

    /// @notice Returns a String with Blue color.
    /// @return string with Blue annotated.
    public fun return_blue(): Color {
        Color { configuration: ascii::string(b"BLUE") }
    }

    /// @notice Returns a String with Yellow color.
    /// @return string with Yellow annotated.
    public fun return_yellow(): Color {
        Color { configuration: ascii::string(b"YELLOW") }
    }

    /// @notice Returns a String with Green color.
    /// @return string with Green annotated.
    public fun return_green(): Color {
        Color { configuration: ascii::string(b"GREEN") }
    }
}

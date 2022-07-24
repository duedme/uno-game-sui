module local::colors {
    struct Color has store, copy, drop {
        configuration: vector<u8>
    }

    public fun return_red(): Color {
        Color { configuration: vector<u8>[1, 0, 0] }
    }

    public fun return_blue(): Color {
        Color { configuration: vector<u8>[0, 1, 0] }
    }

    public fun return_yellow(): Color {
        Color { configuration: vector<u8>[1, 1, 0] }
    }

    public fun return_green(): Color {
        Color { configuration: vector<u8>[0, 1, 0] }
    }
}
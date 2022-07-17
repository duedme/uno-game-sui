module local::colors {
    struct RGB has store, copy {
        configuration: vector<u8>
    }

    public fun return_red(): RGB {
        RGB { configuration: vector<u8>[1, 0, 0] }
    }

    public fun return_blue(): RGB {
        RGB { configuration: vector<u8>[0, 1, 0] }
    }

    public fun return_yellow(): RGB {
        RGB { configuration: vector<u8>[1, 1, 0] }
    }

    public fun return_green(): RGB {
        RGB { configuration: vector<u8>[0, 1, 0] }
    }
}
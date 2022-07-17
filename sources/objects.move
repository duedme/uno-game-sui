module local::objects {
    use sui::utf8;
    use local::colors;

    struct Card has key {
        number: u8,
        color: colors::RGB
    }

    struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}

    struct Deck has store {
        amount: u8,
        specials: bool
    }

    public fun init() {}
}
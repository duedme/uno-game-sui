module local::objects {
    use local::colors;

    struct Card has key, store {
        number: u8,
        color: colors::RGB,
        special: bool,
    }

    /*struct Plus has store { amount: u8 }
    struct Reverse has store {}
    struct Block has store {}
    struct Change_Color_and_Plus has store { amount: Plus }
    struct Change_Color has store {}*/

    struct Deck has store {
        amount: u8,
        special: bool
    }

    public fun init() {}
}
module local::game_money {
    
    struct Coin<phantom Money> has store {
        value: u64
    }

    struct Balance<phantom Money> has key {
        coin: Coin<Money>
    }

    public fun create_Coin<Money>(addr: address, amount: u64) acquires Balance {
        deposit(addr, Coin<Money> { value: amount });
    }

    public fun deposit<Money>(addr: address, c: Coin<Money>) acquires Balance {
        let balance = borrow_global<Balance<Money>>(addr).coin.value;
        let balance_ref = &mut borrow_global_mut<Balance<Money>>(addr).coin.value;
        let Coin { value } = c;
        *balance_ref = balance + value;
    }
}
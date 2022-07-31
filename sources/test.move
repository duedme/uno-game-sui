module local::test {
    use std::hash;
    use std::signer;
    use std::vector;

    /*fun hash(s: &signer) {
        let cast: vector<u8> = signer::address_of(s);
        let vec_of_address = vector::empty<u8>();
        vector::append<u8>(&mut vec_of_address, cast);
        hash::sha2_256(vec_of_address);
    }

    #[test]
    fun test_hash() {
        assert!(x"" == b"", 0);
    }*/
}
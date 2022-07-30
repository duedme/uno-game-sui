module local::test {
    use std::hash;
    use std::signer;
    use std::vector;

    fun hash(s: &signer) {
        let addr = signer::address_of(s);
        let cast = (\xHH);
        let vec_of_address = vector::singleton((cast as u8));
        hash::sha2_256(vec_of_address);
    }
}
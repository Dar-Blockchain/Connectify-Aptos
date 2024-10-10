module Connectify::AuthContract {
    use aptos_std::smart_vector::{Self, SmartVector}; 
    use aptos_std::signer;
    
    const EINDEX_OUT_OF_RANGE: u64 = 1;
    const EADDRESS_NOT_WHITELISTED: u64 = 2;

    struct Owner has key {
        owner: address,
        whitelisted_addresses: SmartVector<address>,
    }

    public entry fun initialize(account: &signer) {
        let owner_address = signer::address_of(account);
        let owner = Owner {
            owner: owner_address,
            whitelisted_addresses: smart_vector::empty<address>(),
        };
        move_to(account, owner);
    }

    public entry fun add_to_whitelist(account: &signer, address_to_add: address) acquires Owner {
        let owner = borrow_global_mut<Owner>(signer::address_of(account));
        assert!(owner.owner == signer::address_of(account), 1); // Ensure only the owner can add to the whitelist
        smart_vector::push_back(&mut owner.whitelisted_addresses, address_to_add);
    }

    public entry fun remove_from_whitelist(account: &signer, address_to_remove: address) acquires Owner {
        let owner = borrow_global_mut<Owner>(signer::address_of(account));
        assert!(owner.owner == signer::address_of(account), 1); // Ensure only the owner can remove from the whitelist
        let (found, idx) = smart_vector::index_of(&owner.whitelisted_addresses, &address_to_remove);
        assert!(found, EINDEX_OUT_OF_RANGE); // Ensure the address is found in the whitelist
        smart_vector::remove(&mut owner.whitelisted_addresses, idx); // Remove the address if found
    }

    public fun is_whitelisted(address: address): bool acquires Owner {
        let owner = borrow_global<Owner>(address);
        smart_vector::contains(&owner.whitelisted_addresses, &address)
    }
}

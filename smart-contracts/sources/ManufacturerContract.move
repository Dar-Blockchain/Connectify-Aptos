module Connectify::ManufacturerContract {
    use aptos_std::smart_vector::{Self, SmartVector}; 
    use aptos_std::signer;
    use std::string::String;

    
    struct Manufacturer has key {
        name: String,
        model_products: SmartVector<address>,
    }

    public entry fun create_manufacturer(account: &signer, name: String) {
        let manufacturer = Manufacturer {
            name,
            model_products: smart_vector::new(),
        };
        move_to(account, manufacturer);
    }

    public entry fun add_model_product(account: &signer, device_address: address) acquires Manufacturer {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        let manufacturer = borrow_global_mut<Manufacturer>(signer::address_of(account));
        smart_vector::push_back(&mut manufacturer.model_products, device_address);
    }

    public entry fun delete_model_product(account: &signer, device_address: address) acquires Manufacturer {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        let manufacturer = borrow_global_mut<Manufacturer>(signer::address_of(account));
        let (found, index) = smart_vector::index_of(&manufacturer.model_products, &device_address);
        assert!(found, 1); // Ensure device exists
        smart_vector::remove(&mut manufacturer.model_products, index); // Remove device
    }
}

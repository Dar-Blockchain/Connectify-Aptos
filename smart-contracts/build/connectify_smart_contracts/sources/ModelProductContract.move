module Connectify::ModelProductContract {
    use aptos_std::smart_vector;
    use std::string::String;
    use aptos_std::signer;


    const EMODEL_PRODUCT_EXISTS: u64 = 1;

    struct ModelProduct has key {
        name: String,
        manufacturer: address,
        devices: smart_vector::SmartVector<String>,
    }

    public entry fun initialize_model_product(account: &signer, name: String, manufacturer: address) {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist

        let model_product = ModelProduct {
            name,
            manufacturer,
            devices: smart_vector::new<String>(),
        };
        move_to(account, model_product);
    }

    public entry fun add_device(account: &signer, model_address: address, device_id: String) acquires ModelProduct {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        let model_product = borrow_global_mut<ModelProduct>(model_address);
        smart_vector::push_back(&mut model_product.devices, device_id);
    }

    public fun does_model_product_exist(account: &signer, model_address: address): bool {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist
        exists<ModelProduct>(model_address)
    }

}

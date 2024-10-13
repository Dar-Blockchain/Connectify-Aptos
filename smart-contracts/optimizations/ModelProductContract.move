module Connectify::ModelProductContract {
    use aptos_std::smart_vector;
    use std::string::String;
    use aptos_std::signer;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use std::error;


    const EOBJECT_DOES_NOT_EXIST: u64 = 2;

    const EMODEL_PRODUCT_EXISTS: u64 = 1;

    const ENOT_OWNER: u64 = 3;

    struct ModelProduct has key {
        name: String,
        manufacturer: address,
        devices: smart_vector::SmartVector<String>,
    }


    inline fun authorized_borrow_model_product<T: key>(object: &Object<T>, owner: &signer): &ModelProduct {
        let model_product_address = object::object_address(object);
        assert!(
            exists<ModelProduct>(model_product_address),
            error::not_found(EOBJECT_DOES_NOT_EXIST),
        );

        assert!(
            object::owner(*object) == signer::address_of(owner),
            error::permission_denied(ENOT_OWNER),
        );
        borrow_global<ModelProduct>(model_product_address)
    }

   inline fun authorized_borrow_manufacturer<T: key>(object: &Object<T>, owner: &signer): &Connectify::ManufacturerContract::Manufacturer {
        let manufacturer_address = object::object_address(object);
        assert!(
            exists<Connectify::ManufacturerContract::Manufacturer>(manufacturer_address),
            error::not_found(EOBJECT_DOES_NOT_EXIST),
        );

        assert!(
            object::owner(*object) == signer::address_of(owner),
            error::permission_denied(ENOT_OWNER),
        );
        borrow_global<Connectify::ManufacturerContract::Manufacturer>(manufacturer_address)
    }


    public entry fun initialize_model_product<T: key>(account: &signer, name: String, manufacturer_object: Object<T>)  {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); // Check whitelist

        let manufacturer_object = authorized_borrow_manufacturer(&manufacturer_object, account);

        let model_product = ModelProduct {
            name,
            manufacturer_object,
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

module Connectify::ManufacturerContract {
    use aptos_std::smart_vector::{Self, SmartVector}; 
    use aptos_std::signer;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use std::string::String;

    // The token does not exist
    const EMANIFACTURER_DOES_NOT_EXIST: u64 = 2;

    struct Manufacturer has key {
        name: String,
        model_products: SmartVector<Object<Connectify::ModelProductContract::ModelProduct>>,
    }

    inline fun authorized_borrow<T: key>(token: &Object<T>, creator: &signer): &Manufacturer {
        let manufacturer_address = object::object_address(token);
        assert!(
            exists<Manufacturer>(manufacturer_address),
            error::not_found(EMANIFACTURER_DOES_NOT_EXIST),
        );

        assert!(
            object::creator(*token) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR),
        );
        borrow_global<Manufacturer>(manufacturer_address)
    }


    public entry fun create_manufacturer(account: &signer, name: String)  {

        let constructor_ref = object::create_object(signer::address_of(account));

        let object_signer = object::generate_signer(&constructor_ref);


        let manufacturer = Manufacturer {
            name,
            model_products: smart_vector::new(),
        };

        move_to(&object_signer, manufacturer);

    }

    public entry fun add_model_product(account: &signer, manufacturer_address: address, model_product: Object<Connectify::ModelProductContract::ModelProduct>) acquires Manufacturer {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0);
        let manufacturer = borrow_global_mut<Manufacturer>(signer::address_of(account));
        smart_vector::push_back(&mut manufacturer.model_products, model_product);
    }

    public entry fun delete_model_product(account: &signer, model_product: Object<Connectify::ModelProductContract::ModelProduct>) acquires Manufacturer {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); 
        let manufacturer = borrow_global_mut<Manufacturer>(signer::address_of(account));
        let (found, index) = smart_vector::index_of(&manufacturer.model_products, &model_product);
        assert!(found, 1); 
        smart_vector::remove(&mut manufacturer.model_products, index); 
    }
}

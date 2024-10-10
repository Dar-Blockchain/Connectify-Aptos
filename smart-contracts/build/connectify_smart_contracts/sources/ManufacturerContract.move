module Connectify::ManufacturerContract {
    use aptos_std::smart_vector::{Self, SmartVector}; 
    use aptos_std::signer;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use std::string::String;

    
    struct Manufacturer has key {
        name: String,
        model_products: SmartVector<Object<Connectify::ModelProductContract::ModelProduct>>,
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

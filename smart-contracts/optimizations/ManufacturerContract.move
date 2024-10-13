module Connectify::ManufacturerContract {
    use aptos_std::smart_vector::{Self, SmartVector}; 
    use aptos_std::signer;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use std::string::String;
    use std::error;

    // The token does not exist
    const EOBJECT_DOES_NOT_EXIST: u64 = 2;

    const ENOT_OWNER: u64 = 3;


    struct Manufacturer has key {
        name: String,
        model_products: SmartVector<Object<Connectify::ModelProductContract::ModelProduct>>,
    }

    inline fun authorized_borrow_model_product<T: key>(object: &Object<T>, owner: &signer): &Connectify::ModelProductContract::ModelProduct {
        let model_product_address = object::object_address(object);
        assert!(
            exists<Connectify::ModelProductContract::ModelProduct>(model_product_address),
            error::not_found(EOBJECT_DOES_NOT_EXIST),
        );

        assert!(
            object::owner(*object) == signer::address_of(owner),
            error::permission_denied(ENOT_OWNER),
        );
        borrow_global<Connectify::ModelProductContract::ModelProduct>(model_product_address)
    }

   inline fun authorized_borrow_manufacturer<T: key>(object: &Object<T>, owner: &signer): &Manufacturer {
        let manufacturer_address = object::object_address(object);
        assert!(
            exists<Manufacturer>(manufacturer_address),
            error::not_found(EOBJECT_DOES_NOT_EXIST),
        );

        assert!(
            object::owner(*object) == signer::address_of(owner),
            error::permission_denied(ENOT_OWNER),
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
    public entry fun add_model_product<T: key>(account: &signer, manufacturer_object: Object<T> , model_product_object: Object<T>) acquires Manufacturer {
        assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0);
        let manufacturer_object = authorized_borrow_manufacturer(&manufacturer_object, account);
        let model_product_object = authorized_borrow_model_product(&model_product_object,account);

        smart_vector::push_back(&mut manufacturer_object.model_products, model_product_object);
    }

    // public entry fun delete_model_product<T: key>(account: &signer, token: Object<T>) acquires Manufacturer {
    //     assert!(Connectify::AuthContract::is_whitelisted(signer::address_of(account)), 0); 
    //     let manufacturer = borrow_global_mut<Manufacturer>(signer::address_of(account));
    //     let (found, index) = smart_vector::index_of(&manufacturer.model_products, &model_product);
    //     assert!(found, 1); 
    //     smart_vector::remove(&mut manufacturer.model_products, index); 
    // }
}

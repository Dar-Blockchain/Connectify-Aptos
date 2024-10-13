/// This defines a minimally viable token for no-code solutions akin to the original token at
/// 0x3::token module.
/// The key features are:
/// * Base token and collection features
/// * Creator definable mutability for tokens
/// * Creator-based freezing of tokens
/// * Standard object-based transfer and events
/// * Metadata property type
module Connectify::ConnectifyContract {
    use std::error;
    use std::option::{Self, Option};
    use std::string::String;
    use std::signer;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::royalty;
    use aptos_token_objects::token;
    use aptos_std::smart_vector::{Self, SmartVector};
    use std::string;
    use std::string_utils::to_string;
    use std::string::sub_string;
    use std::string::length;
    /// The collection does not exist
    const ECOLLECTION_DOES_NOT_EXIST: u64 = 1;
    /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 2;
    /// The provided signer is not the creator
    const ENOT_CREATOR: u64 = 3;
    /// The field being changed is not mutable
    const EFIELD_NOT_MUTABLE: u64 = 4;
    /// The token being burned is not burnable
    const ETOKEN_NOT_BURNABLE: u64 = 5;
    /// The property map being mutated is not mutable
    const EPROPERTIES_NOT_MUTABLE: u64 = 6;

    const EINDEX_OUT_OF_RANGE: u64 = 7;

    const ECOLLECTION_NAME_EXISTS: u64 = 8;

    const ETOKEN_NAME_EXISTS: u64 = 9;


    const CONTRACT_OWNER: vector<u8> = b"0xdde34b48a4537989feaf9da6bf9aca8d4d4fc8e1a359f1bec58fa2500076515d"; 


    /// Published under the contract owner's account.
    struct Config has key, store {
        collection_names_list: SmartVector<String>,
        tokens_names_list: SmartVector<String>,
        extend_ref: object::ExtendRef,
    }


    #[event]
    struct UpdatePropertyEvent has drop, store {
        sender: address,
        token: address,
        key: String,
        type: String,
        value: vector<u8>
    }


    #[event]
    struct LogEvent has drop, store {
        message: String,
    }
        // let event = LogEvent{
        //     message: sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin))))
        // };
        // 0x1::event::emit(event);



    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Storage state for managing the no-code Collection.
    struct ManufacturerCollection has key {
        /// Used to mutate collection fields
        mutator_ref: Option<collection::MutatorRef>,
        /// Used to mutate royalties
        royalty_mutator_ref: Option<royalty::MutatorRef>,
        /// Determines if the creator can mutate the collection's description
        mutable_description: bool,
        /// Determines if the creator can mutate the collection's uri
        mutable_uri: bool,
        /// Determines if the creator can mutate token descriptions
        mutable_token_description: bool,
        /// Determines if the creator can mutate token names
        mutable_token_name: bool,
        /// Determines if the creator can mutate token properties
        mutable_token_properties: bool,
        /// Determines if the creator can mutate token uris
        mutable_token_uri: bool,
        /// Determines if the creator can burn tokens
        tokens_burnable_by_creator: bool,
        /// Determines if the creator can freeze tokens
        tokens_freezable_by_creator: bool,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Storage state for managing the no-code Token.
    struct ConnectifyToken has key {
        /// Used to burn.
        burn_ref: Option<token::BurnRef>,
        /// Used to control freeze.
        transfer_ref: Option<object::TransferRef>,
        /// Used to mutate fields
        mutator_ref: Option<token::MutatorRef>,
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
    }



    /// Initializes the module, creating the manager object, the guild token collection and the whitelist.
    fun init_module(sender: &signer) {

        let constructor_ref = object::create_object(signer::address_of(sender));
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        // Publish the config resource.
        move_to(sender, Config { collection_names_list: smart_vector::new(), tokens_names_list: smart_vector::new(), extend_ref});
    }


    public entry fun add_collection_name(admin: &signer, collection_name: String) acquires Config {

        assert!(sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        
        // Initialize if it doesn't exist
        if (!exists<Config>(signer::address_of(admin))) {
        // If it doesn't exist, initialize the module
            init_module(admin);
        };
        assert!(!does_collection_name_exist(collection_name), ECOLLECTION_NAME_EXISTS);
        let config = borrow_global_mut<Config>(signer::address_of(admin));
        smart_vector::push_back(&mut config.collection_names_list, collection_name);
    }


    public entry fun remove_collection_name(admin: &signer, collection_name: String) acquires Config {

        assert!(sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        
        let config = borrow_global_mut<Config>(signer::address_of(admin));
        let (found, idx)= smart_vector::index_of(&config.collection_names_list, &collection_name);
        assert!(found, EINDEX_OUT_OF_RANGE);
        smart_vector::remove(&mut config.collection_names_list, idx);
    }




    fun does_collection_name_exist(collection_name:String): bool acquires Config{
        let addr: address = @0xdde34b48a4537989feaf9da6bf9aca8d4d4fc8e1a359f1bec58fa2500076515d;
        let collection_names_list = &borrow_global<Config>(addr).collection_names_list;
        smart_vector::contains(collection_names_list, &collection_name)
    }

    #[view]
    public fun collection_name_exists(collection_name: String): bool acquires Config {
        does_collection_name_exist(collection_name)
    }

    
    
    public entry fun add_token_name(admin: &signer, token_name: String) acquires Config {

        assert!(sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        assert!(!does_token_name_exist(token_name), ECOLLECTION_NAME_EXISTS);
        let config = borrow_global_mut<Config>(signer::address_of(admin));
        smart_vector::push_back(&mut config.tokens_names_list, token_name);
    }

    public entry fun remove_token_name(admin: &signer, token_name: String) acquires Config {

        assert!(sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        
        let config = borrow_global_mut<Config>(signer::address_of(admin));
        let (found, idx)= smart_vector::index_of(&config.tokens_names_list, &token_name);
        assert!(found, EINDEX_OUT_OF_RANGE);
        smart_vector::remove(&mut config.tokens_names_list, idx);
    }

    fun does_token_name_exist(token_name:String): bool acquires Config{
        let addr: address = @0xdde34b48a4537989feaf9da6bf9aca8d4d4fc8e1a359f1bec58fa2500076515d;
        let tokens_names_list = &borrow_global<Config>(addr).tokens_names_list;
        smart_vector::contains(tokens_names_list, &token_name)
    }

    #[view]
    public fun token_name_exists(token_name: String): bool acquires Config {
        does_collection_name_exist(token_name)
    }


    // For dev ( testnet )
    public entry fun clear_config(admin: &signer) acquires Config{

        assert!(sub_string(&to_string<address>(&signer::address_of(admin)),1, length(&to_string<address>(&signer::address_of(admin)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        
        let config = borrow_global_mut<Config>(signer::address_of(admin));

        smart_vector::clear(&mut config.tokens_names_list);
        smart_vector::clear(&mut config.collection_names_list);

    }

    /// Create a new collection
    public entry fun create_collection(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        mutable_description: bool,
        mutable_royalty: bool,
        mutable_uri: bool,
        mutable_token_description: bool,
        mutable_token_name: bool,
        mutable_token_properties: bool,
        mutable_token_uri: bool,
        tokens_burnable_by_creator: bool,
        tokens_freezable_by_creator: bool,
        royalty_numerator: u64,
        royalty_denominator: u64,
    ) acquires Config {
        assert!(sub_string(&to_string<address>(&signer::address_of(creator)),1, length(&to_string<address>(&signer::address_of(creator)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        create_collection_object(
            creator,
            description,
            name,
            uri,
            mutable_description,
            mutable_royalty,
            mutable_uri,
            mutable_token_description,
            mutable_token_name,
            mutable_token_properties,
            mutable_token_uri,
            tokens_burnable_by_creator,
            tokens_freezable_by_creator,
            royalty_numerator,
            royalty_denominator
        );
        add_collection_name(creator, name);
    }

    public fun create_collection_object(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        mutable_description: bool,
        mutable_royalty: bool,
        mutable_uri: bool,
        mutable_token_description: bool,
        mutable_token_name: bool,
        mutable_token_properties: bool,
        mutable_token_uri: bool,
        tokens_burnable_by_creator: bool,
        tokens_freezable_by_creator: bool,
        royalty_numerator: u64,
        royalty_denominator: u64,
    ): Object<ManufacturerCollection> {
        let creator_addr = signer::address_of(creator);
        let royalty = royalty::create(royalty_numerator, royalty_denominator, creator_addr);
        let constructor_ref = collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::some(royalty),
            uri,
        );

        let object_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = if (mutable_description || mutable_uri) {
            option::some(collection::generate_mutator_ref(&constructor_ref))
        } else {
            option::none()
        };

        let royalty_mutator_ref = if (mutable_royalty) {
            option::some(royalty::generate_mutator_ref(object::generate_extend_ref(&constructor_ref)))
        } else {
            option::none()
        };

        let manufacturer_collection = ManufacturerCollection {
            mutator_ref,
            royalty_mutator_ref,
            mutable_description,
            mutable_uri,
            mutable_token_description,
            mutable_token_name,
            mutable_token_properties,
            mutable_token_uri,
            tokens_burnable_by_creator,
            tokens_freezable_by_creator,
        };
        move_to(&object_signer, manufacturer_collection);
        object::object_from_constructor_ref(&constructor_ref)
    }

    /// With an existing collection, directly mint a viable token into the creators account.
    public entry fun mint(
        creator: &signer,
        collection: String,
        description: String,
        name: String,
        uri: String,
        property_keys: vector<String>,
        property_types: vector<String>,
        property_values: vector<vector<u8>>,
    ) acquires ManufacturerCollection, ConnectifyToken, Config {
        assert!(sub_string(&to_string<address>(&signer::address_of(creator)),1, length(&to_string<address>(&signer::address_of(creator)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        assert!(!does_token_name_exist(name), ETOKEN_NAME_EXISTS);
        mint_token_object(creator, collection, description, name, uri, property_keys, property_types, property_values);
        add_token_name(creator, name);
    }

    /// Mint a token into an existing collection, and retrieve the object / address of the token.
    public fun mint_token_object(
        creator: &signer,
        collection: String,
        description: String,
        name: String,
        uri: String,
        property_keys: vector<String>,
        property_types: vector<String>,
        property_values: vector<vector<u8>>,
    ): Object<ConnectifyToken> acquires ManufacturerCollection, ConnectifyToken {
        let constructor_ref = mint_internal(
            creator,
            collection,
            description,
            name,
            uri,
            property_keys,
            property_types,
            property_values,
        );

        let collection = collection_object(creator, &collection);

        // If tokens are freezable, add a transfer ref to be able to freeze transfers
        let freezable_by_creator = are_collection_tokens_freezable(collection);
        if (freezable_by_creator) {
            let connectify_token_addr = object::address_from_constructor_ref(&constructor_ref);
            let connectify_token = borrow_global_mut<ConnectifyToken>(connectify_token_addr);
            let transfer_ref = object::generate_transfer_ref(&constructor_ref);
            option::fill(&mut connectify_token.transfer_ref, transfer_ref);
        };

        object::object_from_constructor_ref(&constructor_ref)
    }

    /// With an existing collection, directly mint a soul bound token into the recipient's account.
    public entry fun mint_soul_bound(
        creator: &signer,
        collection: String,
        description: String,
        name: String,
        uri: String,
        property_keys: vector<String>,
        property_types: vector<String>,
        property_values: vector<vector<u8>>,
        soul_bound_to: address,
    ) acquires ManufacturerCollection {
        assert!(sub_string(&to_string<address>(&signer::address_of(creator)),1, length(&to_string<address>(&signer::address_of(creator)))) == string::utf8(CONTRACT_OWNER), ENOT_CREATOR );
        mint_soul_bound_token_object(
            creator,
            collection,
            description,
            name,
            uri,
            property_keys,
            property_types,
            property_values,
            soul_bound_to
        );
    }

    /// With an existing collection, directly mint a soul bound token into the recipient's account.
    public fun mint_soul_bound_token_object(
        creator: &signer,
        collection: String,
        description: String,
        name: String,
        uri: String,
        property_keys: vector<String>,
        property_types: vector<String>,
        property_values: vector<vector<u8>>,
        soul_bound_to: address,
    ): Object<ConnectifyToken> acquires ManufacturerCollection {
        let constructor_ref = mint_internal(
            creator,
            collection,
            description,
            name,
            uri,
            property_keys,
            property_types,
            property_values,
        );

        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, soul_bound_to);
        object::disable_ungated_transfer(&transfer_ref);

        object::object_from_constructor_ref(&constructor_ref)
    }

    fun mint_internal(
        creator: &signer,
        collection: String,
        description: String,
        name: String,
        uri: String,
        property_keys: vector<String>,
        property_types: vector<String>,
        property_values: vector<vector<u8>>,
    ): ConstructorRef acquires ManufacturerCollection {
        let constructor_ref = token::create(creator, collection, description, name, option::none(), uri);

        let object_signer = object::generate_signer(&constructor_ref);

        let collection_obj = collection_object(creator, &collection);
        let collection = borrow_collection(&collection_obj);

        let mutator_ref = if (
            collection.mutable_token_description
                || collection.mutable_token_name
                || collection.mutable_token_uri
        ) {
            option::some(token::generate_mutator_ref(&constructor_ref))
        } else {
            option::none()
        };

        let burn_ref = if (collection.tokens_burnable_by_creator) {
            option::some(token::generate_burn_ref(&constructor_ref))
        } else {
            option::none()
        };

        let connectify_token = ConnectifyToken {
            burn_ref,
            transfer_ref: option::none(),
            mutator_ref,
            property_mutator_ref: property_map::generate_mutator_ref(&constructor_ref),
        };
        move_to(&object_signer, connectify_token);

        let properties = property_map::prepare_input(property_keys, property_types, property_values);
        property_map::init(&constructor_ref, properties);

        constructor_ref
    }

    // Token accessors

    inline fun borrow<T: key>(token: &Object<T>): &ConnectifyToken {
        let token_address = object::object_address(token);
        assert!(
            exists<ConnectifyToken>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );
        borrow_global<ConnectifyToken>(token_address)
    }

    #[view]
    public fun are_properties_mutable<T: key>(token: Object<T>): bool acquires ManufacturerCollection {
        let collection = token::collection_object(token);
        borrow_collection(&collection).mutable_token_properties
    }

    #[view]
    public fun is_burnable<T: key>(token: Object<T>): bool acquires ConnectifyToken {
        option::is_some(&borrow(&token).burn_ref)
    }

    #[view]
    public fun is_freezable_by_creator<T: key>(token: Object<T>): bool acquires ManufacturerCollection {
        are_collection_tokens_freezable(token::collection_object(token))
    }

    #[view]
    public fun is_mutable_description<T: key>(token: Object<T>): bool acquires ManufacturerCollection {
        is_mutable_collection_token_description(token::collection_object(token))
    }

    #[view]
    public fun is_mutable_name<T: key>(token: Object<T>): bool acquires ManufacturerCollection {
        is_mutable_collection_token_name(token::collection_object(token))
    }

    #[view]
    public fun is_mutable_uri<T: key>(token: Object<T>): bool acquires ManufacturerCollection {
        is_mutable_collection_token_uri(token::collection_object(token))
    }

    // Token mutators

    inline fun authorized_borrow<T: key>(token: &Object<T>, creator: &signer): &ConnectifyToken {
        let token_address = object::object_address(token);
        assert!(
            exists<ConnectifyToken>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        assert!(
            token::creator(*token) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR),
        );
        borrow_global<ConnectifyToken>(token_address)
    }

    public entry fun burn<T: key>(creator: &signer, token: Object<T>) acquires ConnectifyToken, Config {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            option::is_some(&connectify_token.burn_ref),
            error::permission_denied(ETOKEN_NOT_BURNABLE),
        );
        move connectify_token;
        let connectify_token = move_from<ConnectifyToken>(object::object_address(&token));
        let ConnectifyToken {
            burn_ref,
            transfer_ref: _,
            mutator_ref: _,
            property_mutator_ref,
        } = connectify_token;
        remove_token_name(creator,token::name<T>(token));
        property_map::burn(property_mutator_ref);
        token::burn(option::extract(&mut burn_ref));
        
    }

    public entry fun freeze_transfer<T: key>(creator: &signer, token: Object<T>) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_collection_tokens_freezable(token::collection_object(token))
                && option::is_some(&connectify_token.transfer_ref),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        object::disable_ungated_transfer(option::borrow(&connectify_token.transfer_ref));
    }

    public entry fun unfreeze_transfer<T: key>(
        creator: &signer,
        token: Object<T>
    ) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_collection_tokens_freezable(token::collection_object(token))
                && option::is_some(&connectify_token.transfer_ref),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        object::enable_ungated_transfer(option::borrow(&connectify_token.transfer_ref));
    }

    public entry fun set_description<T: key>(
        creator: &signer,
        token: Object<T>,
        description: String,
    ) acquires ManufacturerCollection, ConnectifyToken {
        assert!(
            is_mutable_description(token),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        let connectify_token = authorized_borrow(&token, creator);
        token::set_description(option::borrow(&connectify_token.mutator_ref), description);
    }

    public entry fun set_name<T: key>(
        creator: &signer,
        token: Object<T>,
        name: String,
    ) acquires ManufacturerCollection, ConnectifyToken {
        assert!(
            is_mutable_name(token),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        let connectify_token = authorized_borrow(&token, creator);
        token::set_name(option::borrow(&connectify_token.mutator_ref), name);
    }

    public entry fun set_uri<T: key>(
        creator: &signer,
        token: Object<T>,
        uri: String,
    ) acquires ManufacturerCollection, ConnectifyToken {
        assert!(
            is_mutable_uri(token),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        let connectify_token = authorized_borrow(&token, creator);
        token::set_uri(option::borrow(&connectify_token.mutator_ref), uri);
    }

    public entry fun add_property<T: key>(
        creator: &signer,
        token: Object<T>,
        key: String,
        type: String,
        value: vector<u8>,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_properties_mutable(token),
            error::permission_denied(EPROPERTIES_NOT_MUTABLE),
        );

        property_map::add(&connectify_token.property_mutator_ref, key, type, value);
    }

    public entry fun add_typed_property<T: key, V: drop>(
        creator: &signer,
        token: Object<T>,
        key: String,
        value: V,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_properties_mutable(token),
            error::permission_denied(EPROPERTIES_NOT_MUTABLE),
        );

        property_map::add_typed(&connectify_token.property_mutator_ref, key, value);
    }

    public entry fun remove_property<T: key>(
        creator: &signer,
        token: Object<T>,
        key: String,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_properties_mutable(token),
            error::permission_denied(EPROPERTIES_NOT_MUTABLE),
        );

        property_map::remove(&connectify_token.property_mutator_ref, &key);
    }

    public entry fun update_property<T: key>(
        creator: &signer,
        token: Object<T>,
        key: String,
        type: String,
        value: vector<u8>,
    ) acquires ManufacturerCollection, ConnectifyToken {

        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_properties_mutable(token),
            error::permission_denied(EPROPERTIES_NOT_MUTABLE),
        );

        property_map::update(&connectify_token.property_mutator_ref, &key, type, value);

        let event = UpdatePropertyEvent{
            sender: signer::address_of(creator),
            token: object::object_address(&token),
            key: key,
            type: type,
            value: value
        };

        0x1::event::emit(event);
    }

    public entry fun update_typed_property<T: key, V: drop>(
        creator: &signer,
        token: Object<T>,
        key: String,
        value: V,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let connectify_token = authorized_borrow(&token, creator);
        assert!(
            are_properties_mutable(token),
            error::permission_denied(EPROPERTIES_NOT_MUTABLE),
        );

        property_map::update_typed(&connectify_token.property_mutator_ref, &key, value);
    }

    // Collection accessors

    inline fun collection_object(creator: &signer, name: &String): Object<ManufacturerCollection> {
        let collection_addr = collection::create_collection_address(&signer::address_of(creator), name);
        object::address_to_object<ManufacturerCollection>(collection_addr)
    }

    inline fun borrow_collection<T: key>(token: &Object<T>): &ManufacturerCollection {
        let collection_address = object::object_address(token);
        assert!(
            exists<ManufacturerCollection>(collection_address),
            error::not_found(ECOLLECTION_DOES_NOT_EXIST),
        );
        borrow_global<ManufacturerCollection>(collection_address)
    }

    public fun is_mutable_collection_description<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_description
    }

    public fun is_mutable_collection_royalty<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        option::is_some(&borrow_collection(&collection).royalty_mutator_ref)
    }

    public fun is_mutable_collection_uri<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_uri
    }

    public fun is_mutable_collection_token_description<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_token_description
    }

    public fun is_mutable_collection_token_name<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_token_name
    }

    public fun is_mutable_collection_token_uri<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_token_uri
    }

    public fun is_mutable_collection_token_properties<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).mutable_token_properties
    }

    public fun are_collection_tokens_burnable<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).tokens_burnable_by_creator
    }

    public fun are_collection_tokens_freezable<T: key>(
        collection: Object<T>,
    ): bool acquires ManufacturerCollection {
        borrow_collection(&collection).tokens_freezable_by_creator
    }

    // Collection mutators

    inline fun authorized_borrow_collection<T: key>(collection: &Object<T>, creator: &signer): &ManufacturerCollection {
        let collection_address = object::object_address(collection);
        assert!(
            exists<ManufacturerCollection>(collection_address),
            error::not_found(ECOLLECTION_DOES_NOT_EXIST),
        );
        assert!(
            collection::creator(*collection) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR),
        );
        borrow_global<ManufacturerCollection>(collection_address)
    }

    public entry fun set_collection_description<T: key>(
        creator: &signer,
        collection: Object<T>,
        description: String,
    ) acquires ManufacturerCollection {
        let manufacturer_collection = authorized_borrow_collection(&collection, creator);
        assert!(
            manufacturer_collection.mutable_description,
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        collection::set_description(option::borrow(&manufacturer_collection.mutator_ref), description);
    }

    public fun set_collection_royalties<T: key>(
        creator: &signer,
        collection: Object<T>,
        royalty: royalty::Royalty,
    ) acquires ManufacturerCollection {
        let manufacturer_collection = authorized_borrow_collection(&collection, creator);
        assert!(
            option::is_some(&manufacturer_collection.royalty_mutator_ref),
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        royalty::update(option::borrow(&manufacturer_collection.royalty_mutator_ref), royalty);
    }

    entry fun set_collection_royalties_call<T: key>(
        creator: &signer,
        collection: Object<T>,
        royalty_numerator: u64,
        royalty_denominator: u64,
        payee_address: address,
    ) acquires ManufacturerCollection {
        let royalty = royalty::create(royalty_numerator, royalty_denominator, payee_address);
        set_collection_royalties(creator, collection, royalty);
    }

    public entry fun set_collection_uri<T: key>(
        creator: &signer,
        collection: Object<T>,
        uri: String,
    ) acquires ManufacturerCollection {
        let manufacturer_collection = authorized_borrow_collection(&collection, creator);
        assert!(
            manufacturer_collection.mutable_uri,
            error::permission_denied(EFIELD_NOT_MUTABLE),
        );
        collection::set_uri(option::borrow(&manufacturer_collection.mutator_ref), uri);
    }

    // Tests

    #[test_only]
    use std::string;
    #[test_only]
    use aptos_framework::account;

    #[test(creator = @0x123)]
    fun test_create_and_transfer(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        assert!(object::owner(token) == signer::address_of(creator), 1);
        object::transfer(creator, token, @0x345);
        assert!(object::owner(token) == @0x345, 1);
    }

    #[test(creator = @0x123, bob = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = object)]
    fun test_mint_soul_bound(creator: &signer, bob: &signer) acquires ManufacturerCollection {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, false);

        let creator_addr = signer::address_of(creator);
        account::create_account_for_test(creator_addr);

        let token = mint_soul_bound_token_object(
            creator,
            collection_name,
            string::utf8(b""),
            token_name,
            string::utf8(b""),
            vector[],
            vector[],
            vector[],
            signer::address_of(bob),
        );

        object::transfer(bob, token, @0x345);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50003, location = object)]
    fun test_frozen_transfer(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        freeze_transfer(creator, token);
        object::transfer(creator, token, @0x345);
    }

    #[test(creator = @0x123)]
    fun test_unfrozen_transfer(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        freeze_transfer(creator, token);
        unfreeze_transfer(creator, token);
        object::transfer(creator, token, @0x345);
    }

    #[test(creator = @0x123, another = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_noncreator_freeze(creator: &signer, another: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        freeze_transfer(another, token);
    }

    #[test(creator = @0x123, another = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_noncreator_unfreeze(creator: &signer, another: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        freeze_transfer(creator, token);
        unfreeze_transfer(another, token);
    }

    #[test(creator = @0x123)]
    fun test_set_description(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let description = string::utf8(b"not");
        assert!(token::description(token) != description, 0);
        set_description(creator, token, description);
        assert!(token::description(token) == description, 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50004, location = Self)]
    fun test_set_immutable_description(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, false);
        let token = mint_helper(creator, collection_name, token_name);

        set_description(creator, token, string::utf8(b""));
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_set_description_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let description = string::utf8(b"not");
        set_description(noncreator, token, description);
    }

    #[test(creator = @0x123)]
    fun test_set_name(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let name = string::utf8(b"not");
        assert!(token::name(token) != name, 0);
        set_name(creator, token, name);
        assert!(token::name(token) == name, 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50004, location = Self)]
    fun test_set_immutable_name(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, false);
        let token = mint_helper(creator, collection_name, token_name);

        set_name(creator, token, string::utf8(b""));
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_set_name_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let name = string::utf8(b"not");
        set_name(noncreator, token, name);
    }

    #[test(creator = @0x123)]
    fun test_set_uri(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let uri = string::utf8(b"not");
        assert!(token::uri(token) != uri, 0);
        set_uri(creator, token, uri);
        assert!(token::uri(token) == uri, 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50004, location = Self)]
    fun test_set_immutable_uri(creator: &signer) acquires ManufacturerCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, false);
        let token = mint_helper(creator, collection_name, token_name);

        set_uri(creator, token, string::utf8(b""));
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_set_uri_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let uri = string::utf8(b"not");
        set_uri(noncreator, token, uri);
    }

    #[test(creator = @0x123)]
    fun test_burnable(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        let token_addr = object::object_address(&token);

        assert!(exists<ConnectifyToken>(token_addr), 0);
        burn(creator, token);
        assert!(!exists<ConnectifyToken>(token_addr), 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50005, location = Self)]
    fun test_not_burnable(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, false);
        let token = mint_helper(creator, collection_name, token_name);

        burn(creator, token);
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_burn_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        burn(noncreator, token);
    }

    #[test(creator = @0x123)]
    fun test_set_collection_description(creator: &signer) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, true);
        let value = string::utf8(b"not");
        assert!(collection::description(collection) != value, 0);
        set_collection_description(creator, collection, value);
        assert!(collection::description(collection) == value, 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50004, location = Self)]
    fun test_set_immutable_collection_description(creator: &signer) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, false);
        set_collection_description(creator, collection, string::utf8(b""));
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_set_collection_description_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, true);
        set_collection_description(noncreator, collection, string::utf8(b""));
    }

    #[test(creator = @0x123)]
    fun test_set_collection_uri(creator: &signer) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, true);
        let value = string::utf8(b"not");
        assert!(collection::uri(collection) != value, 0);
        set_collection_uri(creator, collection, value);
        assert!(collection::uri(collection) == value, 1);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = 0x50004, location = Self)]
    fun test_set_immutable_collection_uri(creator: &signer) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, false);
        set_collection_uri(creator, collection, string::utf8(b""));
    }

    #[test(creator = @0x123, noncreator = @0x456)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    fun test_set_collection_uri_non_creator(
        creator: &signer,
        noncreator: &signer,
    ) acquires GOCollection {
        let collection_name = string::utf8(b"collection name");
        let collection = create_collection_helper(creator, collection_name, true);
        set_collection_uri(noncreator, collection, string::utf8(b""));
    }

    #[test(creator = @0x123)]
    fun test_property_add(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");
        let property_name = string::utf8(b"u8");
        let property_type = string::utf8(b"u8");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        add_property(creator, token, property_name, property_type, vector [ 0x08 ]);

        assert!(property_map::read_u8(&token, &property_name) == 0x8, 0);
    }

    #[test(creator = @0x123)]
    fun test_property_typed_add(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");
        let property_name = string::utf8(b"u8");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        add_typed_property<ConnectifyToken, u8>(creator, token, property_name, 0x8);

        assert!(property_map::read_u8(&token, &property_name) == 0x8, 0);
    }

    #[test(creator = @0x123)]
    fun test_property_update(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");
        let property_name = string::utf8(b"bool");
        let property_type = string::utf8(b"bool");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        update_property(creator, token, property_name, property_type, vector [ 0x00 ]);

        assert!(!property_map::read_bool(&token, &property_name), 0);
    }

    #[test(creator = @0x123)]
    fun test_property_update_typed(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");
        let property_name = string::utf8(b"bool");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        update_typed_property<ConnectifyToken, bool>(creator, token, property_name, false);

        assert!(!property_map::read_bool(&token, &property_name), 0);
    }

    #[test(creator = @0x123)]
    fun test_property_remove(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");
        let property_name = string::utf8(b"bool");

        create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);
        remove_property(creator, token, property_name);
    }

    #[test(creator = @0x123)]
    fun test_royalties(creator: &signer) acquires GOCollection, ConnectifyToken {
        let collection_name = string::utf8(b"collection name");
        let token_name = string::utf8(b"token name");

        let collection = create_collection_helper(creator, collection_name, true);
        let token = mint_helper(creator, collection_name, token_name);

        let royalty_before = option::extract(&mut token::royalty(token));
        set_collection_royalties_call(creator, collection, 2, 3, @0x444);
        let royalty_after = option::extract(&mut token::royalty(token));
        assert!(royalty_before != royalty_after, 0);
    }

    #[test_only]
    fun create_collection_helper(
        creator: &signer,
        collection_name: String,
        flag: bool,
    ): Object<GOCollection> {
        create_collection_object(
            creator,
            string::utf8(b"collection description"),
            1,
            collection_name,
            string::utf8(b"collection uri"),
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            flag,
            1,
            100,
        )
    }

    #[test_only]
    fun mint_helper(
        creator: &signer,
        collection_name: String,
        token_name: String,
    ): Object<ConnectifyToken> acquires GOCollection, ConnectifyToken {
        let creator_addr = signer::address_of(creator);
        account::create_account_for_test(creator_addr);

        mint_token_object(
            creator,
            collection_name,
            string::utf8(b"description"),
            token_name,
            string::utf8(b"uri"),
            vector[string::utf8(b"bool")],
            vector[string::utf8(b"bool")],
            vector[vector[0x01]],
        )
    }
}
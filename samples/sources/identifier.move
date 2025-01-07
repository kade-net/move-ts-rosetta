
module fds::identifier {

    use std::option;
    use std::signer;
    use std::string;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::object;
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use fds::utils;
    #[test_only]
    use aptos_framework::timestamp;

    const SEED: vector<u8> = b"identifier";

    const E_PERMISSION_DENIED: u64 = 200;
    const E_USERNAME_DOES_NOT_EXIST: u64 = 201;
    const E_NOT_USERNAME_OWNER: u64 = 202;
    const E_NAMESPACE_DOES_NOT_EXIST: u64 = 203;
    const E_NOT_NODE_NAMESPACE_OWNER: u64 = 204;
    const E_NODE_DELETED: u64 = 205;

    const USERNAME_REGISTRATION_FEE: u64 = 50000000;
    const NODE_REGISTRATION_FEE: u64 = 1000000000;

    const USERNAME_REGISTRY_COLLECTION: vector<u8> = b"Kade Username Registry V2";
    const USERNAME_REGISTRY_COLLECTION_DESCRIPTION: vector<u8> = b"";
    const USERNAME_REGISTRY_COLLECTION_URI: vector<u8> = b"";

    const NODE_REGISTRY_COLLECTION: vector<u8> = b"Kade Node Registry V2";
    const NODE_REGISTRY_COLLECTION_DESCRIPTION: vector<u8> = b"Kade Node Registry V2";
    const NODE_REGISTRY_COLLECTION_URI: vector<u8> = b"Kade Node Registry V2";

    const USERNAME_LINK_REGISTRY_COLLECTION: vector<u8> = b"Kade Username Link Registry";
    const USERNAME_LINK_REGISTRY_COLLECTION_DESCRIPTION: vector<u8> = b"Kade Username Link Registry";
    const USERNAME_LINK_REGISTRY_COLLECTION_URI: vector<u8> = b"Kade Username Link Registry";

    struct State has key, store {
        signer_capability: account::SignerCapability,
        username_registry_mutator_ref: collection::MutatorRef,
        node_registry_mutator_ref: collection::MutatorRef,
        username_link_registry_mutator_ref: collection::MutatorRef
    }

    struct UsernameRecord has key, store {
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        link_address: address,
        transfer_ref: object::TransferRef
    }

    struct UsernameLinkRecord has key, store {
        username_string: string::String,
        username_token_address: address,
        current_owner: address,
        burn_ref: token::BurnRef,
        mutator_ref: token::MutatorRef
    }

    struct NodeNameRecord has key, store {
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        transfer_ref: object::TransferRef,
        operator: address,
    }

    fun init_module(admin: &signer) {
        let (resource_signer, signer_capability) = account::create_resource_account(admin, SEED);

        let username_registry_collection_constructor_ref = collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(USERNAME_REGISTRY_COLLECTION_DESCRIPTION),
            string::utf8(USERNAME_REGISTRY_COLLECTION),
            option::none(),
            string::utf8(USERNAME_REGISTRY_COLLECTION_URI),
        );

        let username_registry_mutator_ref = collection::generate_mutator_ref(&username_registry_collection_constructor_ref);


        let node_registry_collection_constructor_ref = collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(NODE_REGISTRY_COLLECTION_DESCRIPTION),
            string::utf8(NODE_REGISTRY_COLLECTION),
            option::none(),
            string::utf8(NODE_REGISTRY_COLLECTION_URI),
        );

        let node_registry_mutator_ref = collection::generate_mutator_ref(&node_registry_collection_constructor_ref);

        let username_link_registry_collection_constructor_ref = collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(USERNAME_LINK_REGISTRY_COLLECTION_DESCRIPTION),
            string::utf8(USERNAME_LINK_REGISTRY_COLLECTION),
            option::none(),
            string::utf8(USERNAME_LINK_REGISTRY_COLLECTION_URI),
        );

        let username_link_registry_mutator_ref = collection::generate_mutator_ref(&username_link_registry_collection_constructor_ref);

        move_to<State>(&resource_signer, State {
            signer_capability,
            username_link_registry_mutator_ref,
            node_registry_mutator_ref,
            username_registry_mutator_ref
        });

    }

    fun register_username(uri: string::String, username: string::String, owner: address) acquires State {

        utils::assert_has_no_special_characters(username);

        let resource_address = account::create_resource_address(&@fds, SEED);

        let state = borrow_global<State>(resource_address);

        let resource_signer = account::create_signer_with_capability(&state.signer_capability);

        let username_constructor_ref = token::create_named_token(
            &resource_signer,
            string::utf8(USERNAME_REGISTRY_COLLECTION),
            string::utf8(b"A Username from the Kade Username Registry V2"),
            username,
            option::none(),
            uri
        );

        let username_link_constructor_ref = token::create_named_token(
            &resource_signer,
            string::utf8(USERNAME_LINK_REGISTRY_COLLECTION),
            username,
            string::utf8(b"A Username link"),
            option::none(),
            uri
        );

        let token_address = object::address_from_constructor_ref(&username_constructor_ref);
        let link_address = object::address_from_constructor_ref(&username_link_constructor_ref);

        let token_signer = object::generate_signer(&username_constructor_ref);
        let link_signer = object::generate_signer(&username_link_constructor_ref);

        let transfer_ref = object::generate_transfer_ref(&username_constructor_ref);

        move_to<UsernameRecord>(&token_signer, UsernameRecord {
            burn_ref: token::generate_burn_ref(&username_constructor_ref),
            mutator_ref: token::generate_mutator_ref(&username_constructor_ref),
            link_address,
            transfer_ref
        });

        let username_record_obj = object::object_from_constructor_ref<UsernameRecord>(&username_constructor_ref);

        object::transfer(&resource_signer, username_record_obj, owner);

        move_to<UsernameLinkRecord>(&link_signer, UsernameLinkRecord {
            burn_ref: token::generate_burn_ref(&username_link_constructor_ref),
            username_string: username,
            username_token_address: token_address,
            current_owner: owner,
            mutator_ref: token::generate_mutator_ref(&username_link_constructor_ref)
        });

        // TODO: Emit creation event

    }

    fun register_node(uri: string::String, namespace: string::String, operator: address) acquires State, NodeNameRecord {

        utils::assert_has_no_special_characters(namespace);

        let resource_address = account::create_resource_address(&@fds, SEED);

        let state = borrow_global<State>(resource_address);

        let resource_signer = account::create_signer_with_capability(&state.signer_capability);

        let claim_success = operator_claim_namespace(operator, namespace);

        if(claim_success){
            return
        };

        let node_constructor_ref = token::create_named_token(
            &resource_signer,
            string::utf8(NODE_REGISTRY_COLLECTION),
            string::utf8(b"A Node Registered under Kade's Username Registry V2"),
            namespace,
            option::none(),
            uri
        );

        let token_address = object::address_from_constructor_ref(&node_constructor_ref);
        let token_signer = object::generate_signer(&node_constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&node_constructor_ref);


        move_to<NodeNameRecord>(&token_signer, NodeNameRecord {
            transfer_ref: object::generate_transfer_ref(&node_constructor_ref),
            mutator_ref: token::generate_mutator_ref(&node_constructor_ref),
            burn_ref: token::generate_burn_ref(&node_constructor_ref),
            operator
        });

        let record_obj = object::object_from_constructor_ref<NodeNameRecord>(&node_constructor_ref);

        object::transfer(&resource_signer, record_obj, operator);
        object::disable_ungated_transfer(&transfer_ref);


    }



    public entry fun admin_register_username(admin: &signer, username: string::String, claimer: address, uri: string::String) acquires State {
        assert!(signer::address_of(admin) == @fds, E_PERMISSION_DENIED);
        register_username(uri, username, claimer);
    }

    public entry fun pay_and_register_username(user: &signer, username: string::String, uri: string::String)  acquires State {
        let user_address = signer::address_of(user);
        register_username(uri, username, user_address);
        coin::transfer<AptosCoin>(user, @fds, USERNAME_REGISTRATION_FEE);
    }

    public entry fun admin_register_node(admin: &signer, namespace: string::String, operator: address, uri: string::String) acquires State, NodeNameRecord {
        assert!(signer::address_of(admin) == @fds, E_PERMISSION_DENIED);
        register_node(uri, namespace, operator);
    }

    public entry fun pay_and_register_node(operator: &signer, namespace: string::String, uri: string::String) acquires State, NodeNameRecord {
        let operator_address = signer::address_of(operator);
        register_node(uri, namespace, operator_address);
        coin::transfer<AptosCoin>(operator, @fds, NODE_REGISTRATION_FEE);
    }

    public entry fun update_username_link(user: &signer, username: string::String) acquires UsernameLinkRecord, UsernameRecord {
        let user_address = signer::address_of(user);
        let resource_address = account::create_resource_address(&@fds, SEED);
        let token_address = token::create_token_address(&resource_address, &string::utf8(USERNAME_REGISTRY_COLLECTION), &username);
        assert!(exists<UsernameRecord>(token_address),E_USERNAME_DOES_NOT_EXIST);

        let rec_object = object::address_to_object<UsernameRecord>(token_address);

        assert!(object::is_owner(rec_object, user_address), E_NOT_USERNAME_OWNER);

        let username_record = borrow_global<UsernameRecord>(token_address);

        let link_record = borrow_global_mut<UsernameLinkRecord>(username_record.link_address);

        link_record.current_owner = user_address;
    }

    public entry fun network_reclaim_node_namespace(admin: &signer, namespace: string::String) acquires NodeNameRecord {
        assert!(signer::address_of(admin) == @fds, E_PERMISSION_DENIED);

        let resource_address = account::create_resource_address(&@fds, SEED);

        let token_address = token::create_token_address(&resource_address, &string::utf8(NODE_REGISTRY_COLLECTION), &namespace);

        assert!(exists<NodeNameRecord>(token_address), E_NAMESPACE_DOES_NOT_EXIST);

        let record = borrow_global_mut<NodeNameRecord>(token_address);

        record.operator = @fds;

        let linear_transfer_ref = object::generate_linear_transfer_ref(&record.transfer_ref);

        object::transfer_with_ref(linear_transfer_ref, @fds);
    }

    fun operator_claim_namespace(operator_address: address, namespace: string::String): bool acquires NodeNameRecord {
        let resource_address = account::create_resource_address(&@fds, SEED);

        let token_address = token::create_token_address(&resource_address, &string::utf8(NODE_REGISTRY_COLLECTION), &namespace);

        let namespace_exists = exists<NodeNameRecord>(token_address);

        if(namespace_exists){
            let record = borrow_global_mut<NodeNameRecord>(token_address);

            if(record.operator == @fds){
                record.operator = operator_address;
                return true

            };

            return false
        };

        return false
    }

    public entry fun assert_owns_namespace(operator_address: address, namespace: string::String) {
        let resource_address = account::create_resource_address(&@fds, SEED);
        let token_address = token::create_token_address(&resource_address, &string::utf8(NODE_REGISTRY_COLLECTION), &namespace);

        assert!(object::is_object(token_address), E_NAMESPACE_DOES_NOT_EXIST);

        let record_object = object::address_to_object<NodeNameRecord>(token_address);

        assert!(object::is_owner(record_object, operator_address), E_NOT_NODE_NAMESPACE_OWNER);
    }

    public entry fun assert_owns_username(user_address: address, username: string::String) {
        let resource_address = account::create_resource_address(&@fds, SEED);
        let token_address = token::create_token_address(&resource_address, &string::utf8(USERNAME_REGISTRY_COLLECTION), &username);

        assert!(object::is_object(token_address), E_USERNAME_DOES_NOT_EXIST);

        let record_object = object::address_to_object<UsernameRecord>(token_address);

        assert!(object::is_owner(record_object, user_address), E_NOT_USERNAME_OWNER);
    }

    public entry fun assert_namespace_exits(namespace: string::String) acquires NodeNameRecord {
        let resource_address = account::create_resource_address(&@fds, SEED);
        let token_address = token::create_token_address(&resource_address, &string::utf8(NODE_REGISTRY_COLLECTION), &namespace);

        assert!(object::is_object(token_address), E_NAMESPACE_DOES_NOT_EXIST);

        let node_record = borrow_global<NodeNameRecord>(token_address);

        assert!(node_record.operator != @fds, E_NODE_DELETED);
    }


    #[test_only]
    public fun initialize_module(admin:  &signer) {
        init_module(admin);
    }

    #[test]
    fun test_register_username() acquires State {
        let aptos = &account::create_account_for_test(@0x1);
        let admin = &account::create_account_for_test(@fds);
        let user = &account::create_account_for_test(@0x3212);
        let node = &account::create_account_for_test(@0x54545);

        timestamp::set_time_has_started_for_testing(aptos);

        init_module(admin);

        admin_register_username(admin, string::utf8(b"hello"), signer::address_of(user), string::utf8(b""));

    }

    #[test]
    fun test_register_node() acquires State, NodeNameRecord {
        let aptos = &account::create_account_for_test(@0x1);
        let admin = &account::create_account_for_test(@fds);
        let user = &account::create_account_for_test(@0x3212);
        let node = &account::create_account_for_test(@0x54545);

        timestamp::set_time_has_started_for_testing(aptos);

        init_module(admin);

        admin_register_node(admin, string::utf8(b"hello"), signer::address_of(node), string::utf8(b""));

    }


    #[test]
    fun test_pay_and_register_username() acquires State {
        let aptos = &account::create_account_for_test(@0x1);
        let admin = &account::create_account_for_test(@fds);
        let user = &account::create_account_for_test(@0x3212);
        let node = &account::create_account_for_test(@0x54545);

        timestamp::set_time_has_started_for_testing(aptos);

        let (burn_cap, freeze_cap,mint_cap) = coin::initialize<AptosCoin>(aptos,string::utf8(b"Aptos"), string::utf8(b"APT"), 8, false);

        coin::register<AptosCoin>(user);
        coin::register<AptosCoin>(admin);

        let coins = coin::mint<AptosCoin>(500000000, &mint_cap);
        coin::deposit(signer::address_of(user), coins);

        init_module(admin);

        pay_and_register_username(user, string::utf8(b"fff"), string::utf8(b""));

        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }



}

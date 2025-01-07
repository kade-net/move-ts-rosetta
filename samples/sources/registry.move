module fds::registry {

    use std::signer;
    use std::string;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use fds::identifier;
    #[test_only]
    use fds::utils;

    const SEED: vector<u8> = b"fds::registry";

    // support for other chains, Aptos is treated as the primary chain or level - 0 chain
    struct Chain has copy, drop, store {
        chain: string::String,
        address: string::String
    }

    struct SignerPublicKey has copy, drop, store {
        publicKey: string::String,
        node: string::String,
        registered: u64
    }

    struct Account has key, store {
        public_keys: vector<SignerPublicKey>,
        chains: vector<Chain>,
        username: string::String,
        registered: u64
    }

    struct Node has key, store {
        service_endpoint: string::String,
        publicKey: string::String,
        registered: u64,
        namespace: string::String,
        active: bool,
    }


    struct State has key, store {
        signer_capability: account::SignerCapability
    }


    fun init_module(admin: &signer) {
        let (resource_signer, signer_cap) = account::create_resource_account(admin, SEED);


        move_to<State>(&resource_signer, State {
            signer_capability: signer_cap
        })
    }


    public entry fun register_operator(operator: &signer, namespace: string::String, publicKey: string::String, serviceEndpoint: string::String) {
        let operator_address = signer::address_of(operator);

        identifier::assert_owns_namespace(operator_address, namespace);

        let node_record = Node {
            namespace,
            publicKey,
            registered: timestamp::now_seconds(),
            active: true,
            service_endpoint: serviceEndpoint
        };

        move_to(operator, node_record);
    }

    public entry fun register_account(user: &signer, username: string::String, publicKey: string::String, namespace: string::String) {
        let user_address = signer::address_of(user);

        identifier::assert_owns_username(user_address, username);
        identifier::assert_namespace_exits(namespace);


        let pubKey = SignerPublicKey {
            registered: timestamp::now_seconds(),
            publicKey,
            node: namespace
        };

        let pubKeys = vector::empty<SignerPublicKey>();
        vector::push_back(&mut pubKeys, pubKey);

        let account = Account {
            registered: timestamp::now_seconds(),
            username,
            chains: vector::empty(),
            public_keys: pubKeys
        };

        move_to(user,account);

        identifier::update_username_link(user, username);
    }

    public entry fun user_add_node(user: &signer, namespace: string::String, publicKey: string::String) acquires Account {
        let user_address = signer::address_of(user);

        identifier::assert_namespace_exits(namespace);

        let account = borrow_global_mut<Account>(user_address);

        let (exists, index) = vector::find(&account.public_keys, |_pubKey|{
            let pubKey: &SignerPublicKey = _pubKey;
            pubKey.node == namespace
        });


        if(exists){
            vector::remove(&mut account.public_keys, index);
        };

        vector::push_back(&mut account.public_keys, SignerPublicKey {
            node: namespace,
            registered: timestamp::now_seconds(),
            publicKey
        })
    }

    public entry fun user_add_chain(user: &signer, chainId: string::String, chain_address: string::String ) acquires Account {
        let user_address = signer::address_of( user);

        let account = borrow_global_mut<Account>(user_address);

        let (exists, index) = vector::find(&account.chains, |_chain|{
            let chain: &Chain = _chain;
            chain.chain == chainId
        });


        if(exists){
            vector::remove(&mut account.chains, index);
        };

        vector::push_back(&mut account.chains, Chain {
            chain: chainId,
            address: chain_address
        })
    }

    public entry fun update_username(user: &signer, new_username: string::String) acquires  Account {

        let user_address = signer::address_of(user);

        identifier::update_username_link(user, new_username);

        let account = borrow_global_mut<Account>(user_address);

        account.username = new_username;
    }

    public entry fun update_node_namespace(operator: &signer, new_node_namespace: string::String) acquires  Node {
        let operator_address = signer::address_of(operator);

        identifier::assert_owns_namespace(operator_address, new_node_namespace);

        let node = borrow_global_mut<Node>(operator_address);

        node.namespace = new_node_namespace;
    }

    public entry fun update_service_endpoint(operator: &signer, new_service_endpoint: string::String) acquires Node {
        let operator_address = signer::address_of(operator);

        let node = borrow_global_mut<Node>(operator_address);

        node.service_endpoint = new_service_endpoint;
    }

    #[test_only]
    public fun testing_setup_accounts (): (signer, signer, signer, signer) {
        let aptos = account::create_account_for_test(@0x1);
        let admin = account::create_account_for_test(@fds);
        let user = account::create_account_for_test(@0x432);
        let operator = account::create_account_for_test(@0x5432);

        timestamp::set_time_has_started_for_testing(&aptos);

        return (aptos, admin, user, operator)
    }

    #[test_only]
    public fun initialize_module(admin: &signer) {
        init_module(admin);
    }


    #[test]
    fun test_register_node() {
        let (aptos, admin, user, operator) = testing_setup_accounts();
        let ( username, namespace ) = utils::testing_identifiers();
        identifier::initialize_module(&admin);
        initialize_module(&admin);
        let (burn, freeze, mint) = utils::initialize_coin(aptos, &admin, &operator, &user);

        identifier::pay_and_register_node(&operator, namespace, string::utf8(b""));

        register_operator(&operator, namespace, string::utf8(b""), string::utf8(b""));


        utils::destroy_coin(burn, freeze, mint);
    }

    #[test]
    fun test_register_account() {
        let (aptos, admin, user, operator) = testing_setup_accounts();
        let ( username, namespace ) = utils::testing_identifiers();
        identifier::initialize_module(&admin);
        initialize_module(&admin);
        let (burn, freeze, mint) = utils::initialize_coin(aptos, &admin, &operator, &user);

        identifier::pay_and_register_node(&operator, namespace, string::utf8(b""));

        register_operator(&operator, namespace, string::utf8(b""), string::utf8(b""));

        identifier::pay_and_register_username(&user, username, string::utf8(b""));
        register_account(&user, username, string::utf8(b""),namespace);


        utils::destroy_coin(burn, freeze, mint);
    }

}

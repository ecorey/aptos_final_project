module SkyTrade::air_rights {

    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;



    // STRUCTS
    /// Struct representing an Air Rights Parcel
    struct AirRightsParcel has key, store {
        id: u64,
        owner: address,
        cubic_feet: u64,
        price_per_cubic_foot: u64,
        is_listed: bool,
    }


    /// Resource holding all air rights for a particular account
    struct AirRightsRegistry has key {
        next_id: u64,
        parcels: vector<AirRightsParcel>,
        
    }



    /// EVENTS  
    #[event]
    struct AirRightsCreatedEvent has drop, store {
        parcel_id: u64,
        owner: address,
        cubic_feet: u64,
        price_per_cubic_foot: u64,
    }

    #[event]
    struct AirRightsTransferredEvent has drop, store {
        from: address,
        to: address,
        parcel_id: u64,
    }

    #[event]
    struct AirRightsListedEvent has drop, store {
        owner: address,
        parcel_id: u64,
        price_per_cubic_foot: u64,
    }

    #[event]
    struct AirRightsDelistedEvent has drop, store {
        owner: address,
        parcel_id: u64,
    }



    //FUNCTIONS
    /// Initialize the contract for the caller account
    public entry fun initialize(account: &signer) {

        let registry = AirRightsRegistry {
            next_id: 0,
            parcels: vector::empty(),
            
        };

        move_to(account, registry);

    }



    /// Create a new air rights parcel
    public entry fun create_air_rights(account: &signer, cubic_feet: u64, price_per_cubic_foot: u64) acquires AirRightsRegistry {
        let account_address = signer::address_of(account);
        let registry = borrow_global_mut<AirRightsRegistry>(account_address);

        assert!(cubic_feet > 0, 2);
        assert!(price_per_cubic_foot > 0, 3);

        let parcel_id = registry.next_id;
        registry.next_id = parcel_id + 1;

        let parcel = AirRightsParcel {
            id: parcel_id,
            owner: account_address,
            cubic_feet,
            price_per_cubic_foot,
            is_listed: false,
        };

        vector::push_back(&mut registry.parcels, parcel);


        let event = AirRightsCreatedEvent {
            parcel_id,
            owner: account_address,
            cubic_feet,
            price_per_cubic_foot,
        };

        event::emit(event);


        
    }


    /// Sell air rights parcel
    public entry fun sell_air_rights(
        from: &signer, 
        buyer: &signer, 
        parcel_id: u64, 
        price: u64
    ) acquires AirRightsRegistry {

        let from_address = signer::address_of(from);
        let buyer_address = signer::address_of(buyer);

        // Verify the parcel ownership and that it is listed for sale
        let registry = borrow_global_mut<AirRightsRegistry>(from_address);
        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        assert!(parcel.owner == from_address, 4);
        assert!(parcel.is_listed, 5);  // Ensure the parcel is listed for sale


        // Ensure the buyer has a CoinStore published for AptosCoin
        if (!coin::is_account_registered<AptosCoin>(buyer_address)) {
            coin::register<AptosCoin>(buyer);
        };


        // Withdraw the APT coins from the buyer's account and deposit them into the seller's account
        let payment = coin::withdraw<AptosCoin>(buyer, price);
        coin::deposit<AptosCoin>(from_address, payment);

        // Transfer the ownership of the parcel from the seller to the buyer
        parcel.owner = buyer_address;
        parcel.is_listed = false;

        let event = AirRightsTransferredEvent {
            from: from_address,
            to: buyer_address,
            parcel_id,
        };

        event::emit(event);
    }





    /// List an air rights parcel for sale
    public entry fun list_air_rights(account: &signer, parcel_id: u64, price_per_cubic_foot: u64) acquires AirRightsRegistry {
        let account_address = signer::address_of(account);
        let registry = borrow_global_mut<AirRightsRegistry>(account_address);

        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        assert!(parcel.owner == account_address, 6);
        assert!(price_per_cubic_foot > 0, 7);

        parcel.is_listed = true;
        parcel.price_per_cubic_foot = price_per_cubic_foot;

        let event = AirRightsListedEvent {
            owner: account_address,
            parcel_id,
            price_per_cubic_foot,
        };

        event::emit(event);
    }



    /// Delist an air rights parcel
    public entry fun delist_air_rights(account: &signer, parcel_id: u64) acquires AirRightsRegistry {
        let account_address = signer::address_of(account);
        let registry = borrow_global_mut<AirRightsRegistry>(account_address);

        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        assert!(parcel.owner == account_address, 8);
        assert!(parcel.is_listed, 9);

        parcel.is_listed = false;

        let event = AirRightsDelistedEvent {
            owner: account_address,
            parcel_id,
        };

        event::emit(event);


    }

   



    // TEST FUNCTIONS
    /// Public function to get a parcel by its index
    #[test_only]
    public fun get_parcel_index_for_test(account: address, parcel_id: u64): u64 acquires AirRightsRegistry {
        let registry = borrow_global<AirRightsRegistry>(account);
        get_parcel_index(&registry.parcels, parcel_id)
    }




    /// Helper function to get the index of a parcel in a vector
    fun get_parcel_index(parcels: &vector<AirRightsParcel>, parcel_id: u64): u64 {
        let len = vector::length(parcels);
        let i = 0;

        while (i < len) {
            let parcel = vector::borrow(parcels, i);
            if (parcel.id == parcel_id) {
                return i;
            };
            i = i + 1;
        };

        abort 10 
    }





}





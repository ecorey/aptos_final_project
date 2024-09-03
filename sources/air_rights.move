// ADJUSTMENTS MADE TO CONTRACT
// AirRightsRegistry object holds parcel data
// AirRightsRegistry object is created in the init function and owned by contract creator
// AirRightsRegistry is a named object and cannot be deleted
// AirRightsRegistry object accesible through object address so users can add a parcel or sell ext.
// Parcel is created when added to the registry
// Updated related functions and tests





module SkyTrade::air_rights {

    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::object;
    use aptos_framework::object::object_exists;





    // STRUCTS
    // Struct representing an Air Rights Parcel
    struct AirRightsParcel has key, store {
        id: u64,
        owner: address,
        cubic_feet: u64,
        price_per_cubic_foot: u64,
        is_listed: bool,
    }


    // Object holding all AirRightsParcels 
    struct AirRightsRegistry has key {
        next_id: u64,
        parcels: vector<AirRightsParcel>,
        
    }




    // EVENTS  
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
    // Initialize the contract with the caller account
    public fun init(account: &signer) {

       create_object_to_hold_air_rights_registry(account);

    }


    // Create an object to hold the AirRightsRegistry object that is owned by the contract creator
    const AIRRIGHTSREGISTRY: vector<u8> = b"AirRightsRegistryObject";

    entry fun create_object_to_hold_air_rights_registry(caller: &signer) {

        let caller_address = signer::address_of(caller);
        
        let constructor_ref = object::create_named_object(caller, AIRRIGHTSREGISTRY);   

       
        let air_rights_registry = AirRightsRegistry {
            next_id: 0,
            parcels: vector::empty(),
        };

        let object_signer = object::generate_signer(&constructor_ref);
        move_to(&object_signer, air_rights_registry);     


    }


     #[view]
    fun has_object(creator: address): bool {
        let object_address = object::create_object_address(&creator, AIRRIGHTSREGISTRY);
        object_exists<0x1::object::ObjectCore>(object_address)
    }



    // Parcel is created and added to the air rights registry object
    public entry fun add_parcel_to_air_rights_registry(caller: &signer, registry_address: address, cubic_feet: u64, price_per_cubic_foot: u64) acquires AirRightsRegistry{

        let object_address = object::create_object_address(&registry_address, AIRRIGHTSREGISTRY);

        // heck that the AirRightsRegistry exists in the object
        assert!(object_exists<AirRightsRegistry>(object_address), 1);
        
        // Borrow the AirRightsRegistry resource from the object
        let registry = borrow_global_mut<AirRightsRegistry>(object_address);

        // Create a new parcel
        let parcel_id = registry.next_id;
        registry.next_id = parcel_id + 1;

        let parcel = AirRightsParcel {
            id: parcel_id,
            owner: signer::address_of(caller),  
            cubic_feet,
            price_per_cubic_foot,
            is_listed: false,
        };

        vector::push_back(&mut registry.parcels, parcel);

        let event = AirRightsCreatedEvent {
            parcel_id,
            owner: signer::address_of(caller),
            cubic_feet,
            price_per_cubic_foot,
        };

        event::emit(event);
    }






  

    // Sell air rights parcel
    public entry fun sell_and_transfer_air_rights(
        from: &signer, 
        buyer: &signer, 
        parcel_id: u64, 
        provided_price: u64, 
        registry_address: address
    ) acquires AirRightsRegistry {
        let from_address = signer::address_of(from);
        let buyer_address = signer::address_of(buyer);
        let object_address = object::create_object_address(&registry_address, AIRRIGHTSREGISTRY);

        // Ensure the AirRightsRegistry exists in the object
        assert!(object_exists<AirRightsRegistry>(object_address), 1);

        // Borrow the AirRightsRegistry resource from the object
        let registry = borrow_global_mut<AirRightsRegistry>(object_address);

        // Find the index of the parcel within the registry
        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        // Check parcel ownership and listing status
        assert!(parcel.owner == from_address, 4);
        assert!(parcel.is_listed, 5);  

        // Calculate the expected price
        let expected_price = parcel.cubic_feet * parcel.price_per_cubic_foot;

        // Ensure the provided price matches the expected price
        assert!(provided_price == expected_price, 11);

        // Withdraw the APT coins from the buyer's account and deposit them into the seller's account
        let payment = coin::withdraw<AptosCoin>(buyer, provided_price);
        coin::deposit<AptosCoin>(from_address, payment);

        // Transfer the ownership of the parcel from the seller to the buyer
        parcel.owner = buyer_address;
        parcel.is_listed = false;

        // Emit an event indicating the parcel has been transferred
        let event = AirRightsTransferredEvent {
            from: from_address,
            to: buyer_address,
            parcel_id,
        };

        event::emit(event);
    }






    // List an air rights parcel for sale
    public entry fun list_air_rights(account: &signer, parcel_id: u64, price_per_cubic_foot: u64, registry_address: address) acquires AirRightsRegistry {
        
        let account_address = signer::address_of(account);
        let object_address = object::create_object_address(&registry_address, AIRRIGHTSREGISTRY);

        // Ensure the AirRightsRegistry exists in the object
        assert!(object_exists<AirRightsRegistry>(object_address), 1);

        // Borrow the AirRightsRegistry resource from the object
        let registry = borrow_global_mut<AirRightsRegistry>(object_address);

        // Find the index of the parcel within the registry
        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        // Ensure the caller owns the parcel
        assert!(parcel.owner == account_address, 6);
        
        // Ensure the price per cubic foot is positive
        assert!(price_per_cubic_foot > 0, 7);

        // Update the parcel to be listed for sale
        parcel.is_listed = true;
        parcel.price_per_cubic_foot = price_per_cubic_foot;

        // Emit an event indicating the parcel has been listed
        let event = AirRightsListedEvent {
            owner: account_address,
            parcel_id,
            price_per_cubic_foot,
        };

        event::emit(event);
    }



    // Delist an air rights parcel
    public entry fun delist_air_rights(account: &signer, parcel_id: u64, registry_address: address) acquires AirRightsRegistry {
        let account_address = signer::address_of(account);
        let object_address = object::create_object_address(&registry_address, AIRRIGHTSREGISTRY);

        // Ensure the AirRightsRegistry exists in the object
        assert!(object_exists<AirRightsRegistry>(object_address), 1);

        // Borrow the AirRightsRegistry resource from the object
        let registry = borrow_global_mut<AirRightsRegistry>(object_address);

        // Find the index of the parcel within the registry
        let index = get_parcel_index(&registry.parcels, parcel_id);
        let parcel = vector::borrow_mut(&mut registry.parcels, index);

        // Ensure the caller owns the parcel
        assert!(parcel.owner == account_address, 8);

        // Ensure the parcel is currently listed
        assert!(parcel.is_listed, 9);

        // Update the parcel to be delisted
        parcel.is_listed = false;

        // Emit an event indicating the parcel has been delisted
        let event = AirRightsDelistedEvent {
            owner: account_address,
            parcel_id,
        };

        event::emit(event);
    }


   



    // TEST HELPER FUNCTIONS
    // Public function to get a parcel by its index
    #[test_only]
    public fun get_parcel_index_for_test(registry_address: address, parcel_id: u64): u64 acquires AirRightsRegistry {
        
        let object_address = object::create_object_address(&registry_address, AIRRIGHTSREGISTRY);

        // Ensure the AirRightsRegistry exists in the object
        assert!(object_exists<AirRightsRegistry>(object_address), 1);

        // Borrow the AirRightsRegistry resource from the object
        let registry = borrow_global<AirRightsRegistry>(object_address);

        // Call the helper function to get the index of the parcel
        get_parcel_index(&registry.parcels, parcel_id)
    }





    // Helper function to get the index of a parcel in a vector
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
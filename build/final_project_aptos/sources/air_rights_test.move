module SkyTrade::air_rights_test {


    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_account::create_account;
    use aptos_framework::aptos_account::transfer;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use SkyTrade::air_rights;




   



    // TEST INITIALIZE, CREATE, SELL AIR RIGHTS
    #[test(core = @0x1, account_one = @0xCAFE, account_two = @0xBEEF)]
    fun test_initialize_create_sell_air_rights(core: &signer, account_one: &signer, account_two: &signer) {
        


        // Initialize the coin
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(core);



        // Register accounts and mint coins
        create_account(signer::address_of(account_one));
        create_account(signer::address_of(account_two));


        coin::deposit(signer::address_of(account_two), coin::mint(60_000, &mint_cap));


        // Test transfer of funds
        transfer(account_two, signer::address_of(account_one), 500);
        assert!(coin::balance<AptosCoin>(signer::address_of(account_one)) == 500, 0);



        // Initialize air rights
        air_rights::initialize(account_one);


        // Create air rights
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);


        // List the air rights parcel for sale 
        air_rights::list_air_rights(account_one, 0, price_per_cubic_foot);



        // Test the sell_air_rights function
        let sale_price = 50_000; 
        air_rights::sell_and_transfer_air_rights(account_one, account_two, 0, sale_price);


        // Clean up
        aptos_framework::coin::destroy_burn_cap(burn_cap);
        aptos_framework::coin::destroy_mint_cap(mint_cap);

      
    }




    // TEST SALES PRICE NOT MATICHING EXPECTED PRICE FAILURE
    #[test(core = @0x1, account_one = @0xCAFE, account_two = @0xBEEF)]
    #[expected_failure]
    fun test_failure_initialize_create_sell_air_rights(core: &signer, account_one: &signer, account_two: &signer) {
        


        // Initialize the coin
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(core);



        // Register accounts and mint coins
        create_account(signer::address_of(account_one));
        create_account(signer::address_of(account_two));


        coin::deposit(signer::address_of(account_two), coin::mint(60_000, &mint_cap));


        // Test transfer of funds
        transfer(account_two, signer::address_of(account_one), 500);
        assert!(coin::balance<AptosCoin>(signer::address_of(account_one)) == 500, 0);



        // Initialize air rights
        air_rights::initialize(account_one);


        // Create air rights
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);


        // List the air rights parcel for sale 
        air_rights::list_air_rights(account_one, 0, price_per_cubic_foot);



        // Test the sell_air_rights function FAILURE. PRICE MORE THAN MINTED PRICE
        let sale_price = 150_000; 
        air_rights::sell_and_transfer_air_rights(account_one, account_two, 0, sale_price);


        // Clean up
        aptos_framework::coin::destroy_burn_cap(burn_cap);
        aptos_framework::coin::destroy_mint_cap(mint_cap);

      
    }





    // TEST LIST/ DELIST AND PARCEL INDEX FUNCTIONS
    #[test(account_one = @0xCAFE)]
    fun test_list_delist_air_rights(account_one: &signer) {
        // Initialize the AirRightsRegistry
        air_rights::initialize(account_one);

        // Create an air rights parcel
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);

        // List the air rights parcel for sale
        let new_price = 75;
        air_rights::list_air_rights(account_one, 0, new_price);

        // Get the parcel index
        let account_address = signer::address_of(account_one);
        let parcel_index = air_rights::get_parcel_index_for_test(account_address, 0);
        assert!(parcel_index == 0, 300);

        // Delist the air rights parcel
        air_rights::delist_air_rights(account_one, 0);

    }




}

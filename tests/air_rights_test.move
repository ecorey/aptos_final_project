module SkyTrade::air_rights_test {


    use std::signer;
    use aptos_framework::account;

    use SkyTrade::air_rights;

  


    // TEST INITIALIZE, CREATE, TRANSFER AIR RIGHTS
    #[test(account_one = @0x1, account_two = @0x2)]
    fun test_initialize_create_transfer_air_rights(account_one: &signer, account_two: address) {

    
        // test the initialize function
        air_rights::initialize(account_one);


        // test the create_air_rights function
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);




        // test the get_air_rights function
        air_rights::transfer_air_rights(account_one, account_two, 0);



        
    }



    // TEST LIST/ DELIST AIR RIGHTS
    #[test(account_one = @0x1)]
    fun test_list_air_rights(account_one: &signer) {

        // Initialize the AirRightsRegistry
        air_rights::initialize(account_one);

        // Create an air rights parcel
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);

        // List the air rights parcel for sale
        let new_price = 75;
        air_rights::list_air_rights(account_one, 0, new_price);


        // Delist the air rights parcel
        air_rights::delist_air_rights(account_one, 0);

        
    }




    













}
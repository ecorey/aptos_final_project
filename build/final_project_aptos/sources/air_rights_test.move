module SkyTrade::air_rights_test {


    use std::signer;
    use aptos_framework::account;

    use SkyTrade::air_rights;

  



   #[test(account_one = @0x1, account_two = @0x2)]
    fun test_initialize_create_air_rights(account_one: &signer, account_two: address) {

    
        // test the initialize function
        air_rights::initialize(account_one);


        // test the create_air_rights function
        let cubic_feet = 1000;
        let price_per_cubic_foot = 50;
        air_rights::create_air_rights(account_one, cubic_feet, price_per_cubic_foot);




        // test the get_air_rights function
        air_rights::transfer_air_rights(account_one, account_two, 0);



        
    }



    













}
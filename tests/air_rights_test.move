module SkyTrade::air_rights_test {


    use std::signer;
    use aptos_framework::account;
    

    use SkyTrade::air_rights;

  
   #[test(account_one = @0x1)]
    fun test_initialize(account_one: &signer) {

        // account::create_account_for_test(signer::address_of(account_one));
        

        air_rights::initialize(account_one);

    }



    













}
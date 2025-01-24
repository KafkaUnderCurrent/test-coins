#[test_only]
module test_coins::coins {
    use std::option;
    use std::signer::address_of;
    use std::string::{String, utf8};
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    use aptos_std::type_info;
    use aptos_framework::aptos_account;
    use aptos_framework::coin::{
        Self,
        balance,
        BurnCapability,
        migrate_to_fungible_store,
        MintCapability,
        paired_metadata
    };
    use aptos_framework::object;

    /// Represents test USDT coin.
    struct USDT {}

    /// Represents test BTC coin.
    struct BTC {}

    /// Represents test USDC coin.
    struct USDC {}

    /// Represents test ETH coin.
    struct ETH {}

    /// Represents DAI coin.
    struct DAI {}

    /// Storing mint/burn capabilities for `USDT` and `BTC` coins under user account.
    struct Caps<phantom CoinType> has key {
        mint: MintCapability<CoinType>,
        burn: BurnCapability<CoinType>
    }

    fun init_module(admin: &signer) {
        let (btc_b, btc_f, btc_m) =
            coin::initialize<BTC>(admin, utf8(b"Bitcoin"), utf8(b"BTC"), 8, true);
        let (usdt_b, usdt_f, usdt_m) =
            coin::initialize<USDT>(admin, utf8(b"Tether"), utf8(b"USDT"), 6, true);
        let (eth_b, eth_f, eth_m) =
            coin::initialize<ETH>(admin, utf8(b"Ethereum"), utf8(b"ETH"), 8, true);
        let (usdc_b, usdc_f, usdc_m) =
            coin::initialize<USDC>(admin, utf8(b"USD Coin"), utf8(b"USDC"), 6, true);
        let (dai_b, dai_f, dai_m) =
            coin::initialize<DAI>(admin, utf8(b"DAI"), utf8(b"DAI"), 6, true);

        migrate_to_fungible_store<BTC>(admin);
        migrate_to_fungible_store<USDT>(admin);
        migrate_to_fungible_store<ETH>(admin);
        migrate_to_fungible_store<USDC>(admin);
        migrate_to_fungible_store<DAI>(admin);

        coin::destroy_freeze_cap(eth_f);
        coin::destroy_freeze_cap(usdc_f);
        coin::destroy_freeze_cap(dai_f);
        coin::destroy_freeze_cap(btc_f);
        coin::destroy_freeze_cap(usdt_f);

        move_to(admin, Caps<ETH> { mint: eth_m, burn: eth_b });
        move_to(admin, Caps<USDC> { mint: usdc_m, burn: usdc_b });
        move_to(admin, Caps<DAI> { mint: dai_m, burn: dai_b });
        move_to(admin, Caps<BTC> { mint: btc_m, burn: btc_b });
        move_to(admin, Caps<USDT> { mint: usdt_m, burn: usdt_b });
    }

    #[test_only]
    public fun init_module_for_test(signer: &signer) {
        init_module(signer);
    }

    /// Mints new coin `CoinType` on account anyone.
    public entry fun mint_coin<CoinType>(signer: &signer, amount: u64) acquires Caps {
        coin::migrate_to_fungible_store<CoinType>(signer);
        let caps = borrow_global<Caps<CoinType>>(@test_coins);
        let coins = coin::mint<CoinType>(amount, &caps.mint);
        aptos_account::deposit_coins(address_of(signer), coins);
    }

    public entry fun quick_mint(signer: &signer, amount: u64) acquires Caps {
        mint_coin<USDT>(signer, amount);
        mint_coin<USDC>(signer, amount);
        mint_coin<ETH>(signer, amount);
        mint_coin<BTC>(signer, amount);
        mint_coin<DAI>(signer, amount);
    }

    public entry fun burn_all_coin<CoinType>(signer: &signer) acquires Caps {
        let caps = borrow_global<Caps<CoinType>>(@test_coins);

        let coin = coin::withdraw<CoinType>(
            signer,
            balance<CoinType>(address_of(signer))
        );

        coin::burn(coin, &caps.burn);
    }

    #[view]
    public fun get_all_coin_types(): vector<String> {
        vector[
            type_info::type_name<USDC>(),
            type_info::type_name<USDT>(),
            type_info::type_name<ETH>(),
            type_info::type_name<BTC>(),
            type_info::type_name<DAI>()
        ]
    }

    #[view]
    public fun get_fa_address(): SimpleMap<String, address> {
        let map =
            simple_map::new_from(
                get_all_coin_types(),
                vector[
                    object::object_address(
                        &option::destroy_some(paired_metadata<USDC>())
                    ),
                    object::object_address(
                        &option::destroy_some(paired_metadata<USDT>())
                    ),
                    object::object_address(
                        &option::destroy_some(paired_metadata<ETH>())
                    ),
                    object::object_address(
                        &option::destroy_some(paired_metadata<BTC>())
                    ),
                    object::object_address(
                        &option::destroy_some(paired_metadata<DAI>())
                    )
                ]
            );
        map
    }
}

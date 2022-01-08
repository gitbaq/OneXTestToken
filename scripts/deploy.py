from brownie import OneXTBBH, Faucet, MockV3Aggregator, network, config, accounts
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


def deploy_onex_t():
    # 10 Billion with 18 zeros
    _init_supply = 10000000000000000000000000000
    account = get_account()
    print(f"Account {account}")

    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
        recipient_address = config["wallets"]["recipient"]
        stakingWallet = config["wallets"]["stakingWallet"]
        expenseWallet = config["wallets"]["expenseWallet"]
        liquidityWallet = config["wallets"]["liquidityWallet"]

    else:
        deploy_mocks()
        # price_feed_address = MockV3Aggregator[-1].address
        recipient_address = accounts[1].address
        stakingWallet = accounts[2].address
        expenseWallet = accounts[3].address
        liquidityWallet = accounts[4].address
    one_x_t = OneXTBBH[-1]
    # one_x_t = OneXTBBH.deploy(
    #     _init_supply,
    #     {"from": account},
    #     publish_source=config["networks"][network.show_active()].get("verify"),
    # )
    print(
        f"Contract {one_x_t.name()}:{one_x_t.symbol()} deployed to!! {one_x_t.address} pair {one_x_t.pair()}"
    )
    # 0x927201371E13c3E4EfeCA4aaa926a102656A685f
    print(f"Circulating Supply {one_x_t.getCirculatingSupply()}")
    print(
        f"Total Supply {one_x_t.totalSupply()} "  # -- Take Fee {one_x_t.takeFee(one_x_t.address, 1000000000000000000000000000)}
    )

    print(
        f"Balance Before {one_x_t.balanceOf(recipient_address)} Recipient Should Take Fee {one_x_t.shouldTakeFee(recipient_address)} -- Sender Should Take Fee {one_x_t.shouldTakeFee(one_x_t.address)}"
    )

    print(f"Balance Before Recipient {one_x_t.balanceOf(recipient_address)}")
    print(f"Expense:({one_x_t.balanceOf(expenseWallet)})")
    print(f"Staking:({one_x_t.balanceOf(stakingWallet)})")
    print(f"Liquidity:({one_x_t.balanceOf(liquidityWallet)})")

    print(f"Transferring to!! -- {recipient_address}")
    one_x_t.transfer(recipient_address, 1000000000000000000000000000)

    print(f"#1 Balance After Recipient {one_x_t.balanceOf(recipient_address)}")
    print(f"Expense:({one_x_t.balanceOf(expenseWallet)})")
    print(f"Staking:({one_x_t.balanceOf(stakingWallet)})")
    print(f"Liquidity:({one_x_t.balanceOf(liquidityWallet)})")

    one_x_t.transfer(recipient_address, 1000000000000000000000000000)

    print(f"#2 Balance After Recipient {one_x_t.balanceOf(recipient_address)}")
    print(f"Expense:({one_x_t.balanceOf(expenseWallet)})")
    print(f"Staking:({one_x_t.balanceOf(stakingWallet)})")
    print(f"Liquidity:({one_x_t.balanceOf(liquidityWallet)})")

    return one_x_t


def deploy_faucet(oneXToken):
    account = get_account()
    faucet = Faucet.deploy(
        oneXToken.address, 1000000000000000000000, 1, {"from": account}
    )
    print(f"Faucet deployed to!! {faucet.address}")
    return faucet


def main():
    TestToken = deploy_onex_t()
    # faucetToken = deploy_faucet(TestToken)
    print(f"   OneXTestToken address: ${TestToken.address} ")
    # print(f"   Faucet address: ${faucetToken.address} ")
    print(
        f"   export NETWORK=${network.show_active()}; export TOKEN={TestToken.address}; export FAUCET={faucetToken.address}"
    )

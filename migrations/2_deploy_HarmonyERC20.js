var HarmonyERC20 = artifacts.require("OneXTestToken");

module.exports = function (deployer, network, accounts) {

  /*const name = "OneX Test Token V2"
  const symbol = "ONEXTV2"
  const decimals = 18*/
  amount = 1000000000000
  const tokens = web3.utils.toWei(amount.toString(), 'ether')

  deployer.then(function () {
    return deployer.deploy(HarmonyERC20).then(function () {
      console.log('Deployed!!!');
    });
  });
};
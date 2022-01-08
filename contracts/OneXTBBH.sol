//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Auth.sol";
import "./IDividendDistributor.sol";
import "./IDEXFactory.sol";
import "./IDEXRouter.sol";
import "./DividendDistributor.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract OneXTBBH is ERC20PresetMinterPauser, Auth {
    using SafeMath for uint256;
    // address WBNB1 = 0x7D91e8D61D2f04BBd998d0c4c065d8ca1409DC38;
    address ONEADD = 0x7466d7d0C21Fa05F32F5a0Fa27e12bdC06348Ce2;
    // address WETHx = 0x55A7154f49B046693A7C90e7BcF99CA8268Fa0BF;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    /*HARMONYONE ADDRESS MAINNET - 0x3ac01098415c0ccf479729022d07d5ac3b048b73 */
    /*VENOM LP ADDRESS MAINNET - 0x3ac01098415c0ccf479729022d07d5ac3b048b73 */

    /*WRAPPED ONE WONE on Harmony Testnet - 0x7466d7d0c21fa05f32f5a0fa27e12bdc06348ce2 */
    /*UniSwap V2 on Harmony Testnet - 0x7d91e8d61d2f04bbd998d0c4c065d8ca1409dc38 */

    //address expenseWallet = 0x21Ca50514525B12e1b9bAC578fc8e017611129b4;
    /* Using SBA Development account for Marketing Wallet */
    // address expenseWallet = 0x98109a3BCae9dBd21C557a52D1aacFD0DAFD6F98;
    address expenseWallet = 0xBF0CA9449b9698e5593b585d591370F81a4a726f; //gitbaq ONE Wallet
    address liquidityWallet = 0xAD62fCcCc74283186f4572B8f8EE271B189565fA; //gitbaq ONE Wallet
    address stakingWallet = 0x1BfC2d760e6B75AA626f00177C96CfC84f353D7E; //harmony2 ONE Wallet
    address routerAddress = 0x7D91e8D61D2f04BBd998d0c4c065d8ca1409DC38; //Uniswap V2

    string constant _name = "OneX Test Token";
    string constant _symbol = "ONEXT";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10**_decimals);
    uint256 public _maxTxAmount = 2000000000 * (10**_decimals);
    uint256 public _maxWalletToken = 2000000000 * (10**_decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isTimelockExempt;
    mapping(address => bool) isDividendExempt;

    uint256 public liquidityFee = 1;
    uint256 public stakingFee = 8;
    uint256 public reflectionFee = 0;
    uint256 public expenseFee = 1;
    uint256 public totalFee = 10;
    uint256 public feeDenominator = 100;

    address public autoLiquidityReceiver;
    address public expenseFeeReceiver;
    address public stakingFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = true;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 60;
    mapping(address => uint256) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(uint256 initialSupply)
        ERC20PresetMinterPauser(_name, _symbol)
        Auth(msg.sender)
    {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        /*
        Viper Swap
        
         */
        // router = IDEXRouter(0x68AcB07D1919e2A69dEe2411452883ad08A6236c);
        /* for rinkeby CAKE Address */
        router = IDEXRouter(routerAddress);

        pair = IDEXFactory(router.factory()).createPair(ONEADD, address(this));
        //_allowances[address(this)][address(router)] = uint256(-1);
        _allowances[address(this)][address(router)] = type(uint256).max;
        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = false;
        isTxLimitExempt[msg.sender] = true;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        //autoLiquidityReceiver = address(this);
        autoLiquidityReceiver = liquidityWallet;
        expenseFeeReceiver = expenseWallet;
        stakingFeeReceiver = stakingWallet;

        _balances[msg.sender] = _totalSupply;
        _mint(msg.sender, _totalSupply);
        //emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint128).max);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    //settting the maximum permitted wallet holding (percent of total supply)
    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
        _maxWalletToken = (_totalSupply * maxWallPercent) / 100;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }

        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != expenseFeeReceiver &&
            recipient != stakingFeeReceiver &&
            recipient != autoLiquidityReceiver
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        if (
            sender == pair && buyCooldownEnabled && !isTimelockExempt[recipient]
        ) {
            require(
                cooldownTimer[recipient] < block.timestamp,
                "Please wait for cooldown between buys"
            );
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        checkTxLimit(sender, amount);

        if (shouldSwapBack()) {
            swapBack();
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function clearStuckBalance(address addr) public onlyOwner {
        (bool sent, ) = payable(addr).call{value: (address(this).balance)}("");
        require(sent, "Cannot Clear Stuck Balance!!");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) public view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) public returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        uint256 stakingFeeAmount = feeAmount.mul(stakingFee).div(
            feeDenominator
        );
        uint256 expenseFeeAmount = feeAmount.mul(expenseFee).div(
            feeDenominator
        );
        uint256 liquidityFeeAmount = feeAmount.mul(liquidityFee).div(
            feeDenominator
        );

        // _balances[address(this)] = _balances[address(this)].add(feeAmount);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(
            stakingFeeAmount
        );
        _balances[expenseFeeReceiver] = _balances[expenseFeeReceiver].add(
            expenseFeeAmount
        );
        _balances[autoLiquidityReceiver] = _balances[autoLiquidityReceiver].add(
            liquidityFeeAmount
        );
        emit Transfer(sender, stakingFeeReceiver, feeAmount);
        emit Transfer(sender, expenseFeeReceiver, expenseFeeAmount);
        emit Transfer(sender, autoLiquidityReceiver, liquidityFeeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        //path[1] = WBNB;
        path[1] = ONEADD;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(dynamicLiquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(
            totalBNBFee
        );
        uint256 amountBNBMarketing = amountBNB.mul(expenseFee).div(totalBNBFee);

        uint256 amountStaking = amountBNB.mul(stakingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess, ) = payable(expenseFeeReceiver).call{
            value: amountBNBMarketing,
            gas: 8000000
        }("");

        // only to supress warning msg
        tmpSuccess = false;

        try distributor.deposit{value: amountStaking}() {} catch {}
        (bool tmpSuccess2, ) = payable(stakingFeeReceiver).call{
            value: amountStaking,
            gas: 8000000
        }("");

        // only to supress warning msg
        tmpSuccess2 = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        authorized
    {
        require(
            holder != address(this) && holder != pair,
            "Cannot setIsDividendExempt!!"
        );
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt)
        external
        authorized
    {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _reflectionFee,
        uint256 _expenseFee,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        expenseFee = _expenseFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_expenseFee);
        feeDenominator = _feeDenominator;
        require(
            totalFee < feeDenominator / 4,
            "Fee Cannot be more than 25% of Total"
        );
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _expenseFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        expenseFeeReceiver = _expenseFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 50000000, "Gas Cannot be more than 50000000");
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapRouter.sol";
import "./ERC20UPgradeSafe.sol";
interface IVSafeVault {
    function cap() external view returns (uint256);

    function getVaultMaster() external view returns (address);

    function balance() external view returns (uint256);

    function token() external view returns (address);

    function available() external view returns (uint256);

    function accept(address _input) external view returns (bool);

    function earn() external;

    function harvest(address reserve, uint256 amount) external;

    function addNewCompound(uint256, uint256) external;

    function withdraw_fee(uint256 _shares) external view returns (uint256);

    function calc_token_amount_deposit(uint256 _amount) external view returns (uint256);

    function calc_token_amount_withdraw(uint256 _shares) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256 _amount, uint256 _min_mint_amount) external returns (uint256);

    function depositFor(
        address _account,
        address _to,
        uint256 _amount,
        uint256 _min_mint_amount
    ) external returns (uint256 _mint_amount);

    function withdraw(uint256 _shares, uint256 _min_output_amount) external returns (uint256);

    function withdrawFor(
        address _account,
        uint256 _shares,
        uint256 _min_output_amount
    ) external returns (uint256 _output_amount);

    function harvestStrategy(address _strategy) external;

    function harvestAllStrategies() external;
}

interface Converter {
    function convert(address) external returns (uint256);
}

interface IController {
    function vault() external view returns (IVSafeVault);

    function getStrategyCount() external view returns (uint256);

    function strategies(uint256 _stratId)
        external
        view
        returns (
            address _strategy,
            uint256 _quota,
            uint256 _percent
        );

    function getBestStrategy() external view returns (address _strategy);

    function want() external view returns (address);

    function balanceOf() external view returns (uint256);

    function withdraw_fee(uint256 _amount) external view returns (uint256); // eg. 3CRV => pJar: 0.5% (50/10000)

    function investDisabled() external view returns (bool);

    function withdraw(uint256) external returns (uint256 _withdrawFee);

    function earn(address _token, uint256 _amount) external;

    function harvestStrategy(address _strategy) external;

    function harvestAllStrategies() external;

    function beforeDeposit() external;

    function withdrawFee(uint256) external view returns (uint256); // pJar: 0.5% (50/10000)
}

interface IVaultMaster {
    event UpdateBank(address bank, address vault);
    event UpdateVault(address vault, bool isAdd);
    event UpdateController(address controller, bool isAdd);
    event UpdateStrategy(address strategy, bool isAdd);

    function bank(address) external view returns (address);

    function isVault(address) external view returns (bool);

    function isController(address) external view returns (bool);

    function isStrategy(address) external view returns (bool);

    function slippage(address) external view returns (uint256);

    function convertSlippage(address _input, address _output) external view returns (uint256);

    function reserveFund() external view returns (address);

    function performanceReward() external view returns (address);

    function performanceFee() external view returns (uint256);

    function gasFee() external view returns (uint256);

    function withdrawalProtectionFee() external view returns (uint256);
}

interface IValueLiquidRouter {
    function factory() external view returns (address);

    function controller() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to
    ) external returns (uint256 liquidity);

    function createPairETH(
        address token,
        uint256 amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to
    ) external payable returns (uint256 liquidity);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
}

interface IStrategy {
    event Deposit(address token, uint256 amount);
    event Withdraw(address token, uint256 amount, address to);
    event Harvest(uint256 priceShareBefore, uint256 priceShareAfter, address compoundToken, uint256 compoundBalance, uint256 reserveFundAmount);

    function baseToken() external view returns (address);

    function deposit() external;

    function withdraw(address _asset) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function withdrawToController(uint256 _amount) external;

    function skim() external;

    function harvest(address _mergedStrategy) external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function beforeDeposit() external;
}

/*

 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller

*/
abstract contract StrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IUniswapV2Router public unirouter = IUniswapV2Router(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IValueLiquidRouter public vSwaprouter = IValueLiquidRouter(0xb7e19a1188776f32E8C2B790D9ca578F2896Da7C);

    address public override baseToken;
    address public farmingToken;
    address public targetCompoundToken;

    address public governance;
    address public timelock = address(0x36fcf1c1525854b2d195F5d03d483f01549e06f2);

    address public controller;
    address public strategist;

    IVSafeVault public vault;
    IVaultMaster public vaultMaster;

    mapping(address => mapping(address => address[])) public uniswapPaths; // [input -> output] => uniswap_path
    mapping(address => mapping(address => address[])) public vSwapPairs; // [input -> output] => vswap pair

    uint256 public performanceFee = 0; //1400 <-> 14.0%
    uint256 public lastHarvestTimeStamp;
    bool internal _initialized = false;

    function initialize(
        address _baseToken,
        address _farmingToken,
        address _controller,
        address _targetCompoundToken
    ) internal {
        baseToken = _baseToken;
        farmingToken = _farmingToken;
        targetCompoundToken = _targetCompoundToken;
        controller = _controller;
        vault = IController(_controller).vault();
        require(address(vault) != address(0), "!vault");
        vaultMaster = IVaultMaster(vault.getVaultMaster());
        governance = msg.sender;
        strategist = msg.sender;

        if (farmingToken != address(0)) {
            IERC20(farmingToken).safeApprove(address(unirouter), type(uint256).max);
            IERC20(farmingToken).safeApprove(address(vSwaprouter), type(uint256).max);
        }
        if (targetCompoundToken != farmingToken) {
            IERC20(targetCompoundToken).safeApprove(address(unirouter), type(uint256).max);
            IERC20(targetCompoundToken).safeApprove(address(vSwaprouter), type(uint256).max);
        }
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(controller) || msg.sender == strategist || msg.sender == governance, "!authorized");
        _;
    }

    function getName() public pure virtual returns (string memory);

    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        _token.safeApprove(_spender, _amount);
    }

    function setUnirouter(IUniswapV2Router _unirouter) external onlyGovernance {
        unirouter = _unirouter;
        if (farmingToken != address(0)) {
            IERC20(farmingToken).safeApprove(address(unirouter), type(uint256).max);
        }
        if (targetCompoundToken != farmingToken) IERC20(targetCompoundToken).safeApprove(address(unirouter), type(uint256).max);
    }

    function setVSwaprouter(IValueLiquidRouter _vSwaprouter) external onlyGovernance {
        vSwaprouter = _vSwaprouter;
        if (farmingToken != address(0)) {
            IERC20(farmingToken).safeApprove(address(vSwaprouter), type(uint256).max);
        }
        if (targetCompoundToken != farmingToken) IERC20(targetCompoundToken).safeApprove(address(vSwaprouter), type(uint256).max);
    }

    function setUnirouterPath(
        address _input,
        address _output,
        address[] memory _path
    ) public onlyStrategist {
        uniswapPaths[_input][_output] = _path;
    }

    function setVSwapPairs(
        address _input,
        address _output,
        address[] memory _pair
    ) public onlyStrategist {
        vSwapPairs[_input][_output] = _pair;
    }

    function beforeDeposit() external virtual override onlyAuthorized {}

    function deposit() public virtual override;

    function skim() external override {
        IERC20(baseToken).safeTransfer(controller, IERC20(baseToken).balanceOf(address(this)));
    }

    function withdraw(address _asset) external override onlyAuthorized returns (uint256 balance) {
        require(baseToken != _asset, "lpPair");

        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(controller, balance);
        emit Withdraw(_asset, balance, controller);
    }

    function withdrawToController(uint256 _amount) external override onlyAuthorized {
        require(controller != address(0), "!controller"); // additional protection so we don't burn the funds

        uint256 _balance = IERC20(baseToken).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(baseToken).safeTransfer(controller, _amount);
        emit Withdraw(baseToken, _amount, controller);
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external override onlyAuthorized returns (uint256) {
        uint256 _balance = IERC20(baseToken).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(baseToken).safeTransfer(address(vault), _amount);
        emit Withdraw(baseToken, _amount, address(vault));
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external override onlyAuthorized returns (uint256 balance) {
        _withdrawAll();
        balance = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).safeTransfer(address(vault), balance);
        emit Withdraw(baseToken, balance, address(vault));
    }

    function _withdrawAll() internal virtual;

    function claimReward() public virtual;

    function _swapTokens(
        address _input,
        address _output,
        uint256 _amount
    ) internal {
        if (_input == _output) return;
        address[] memory path = vSwapPairs[_input][_output];
        if (path.length > 0) {
            // use vSwap
            vSwaprouter.swapExactTokensForTokens(_input, _output, _amount, 1, path, address(this), now.add(1800));
        } else {
            // use Uniswap
            path = uniswapPaths[_input][_output];
            if (path.length == 0) {
                // path: _input -> _output
                path = new address[](2);
                path[0] = _input;
                path[1] = _output;
            }
            unirouter.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(1800));
        }
    }

    function _buyWantAndReinvest() internal virtual;

    function harvest(address _mergedStrategy) external virtual override {
        require(msg.sender == controller || msg.sender == strategist || msg.sender == governance, "!authorized");

        uint256 pricePerFullShareBefore = vault.getPricePerFullShare();
        claimReward();
        address _targetCompoundToken = targetCompoundToken;
        {
            address _farmingToken = farmingToken;
            if (_farmingToken != address(0)) {
                uint256 _farmingTokenBal = IERC20(_farmingToken).balanceOf(address(this));
                if (_farmingTokenBal > 0) {
                    _swapTokens(_farmingToken, _targetCompoundToken, _farmingTokenBal);
                }
            }
        }

        uint256 _targetCompoundBal = IERC20(_targetCompoundToken).balanceOf(address(this));

        if (_targetCompoundBal > 0) {
            if (_mergedStrategy != address(0)) {
                require(vaultMaster.isStrategy(_mergedStrategy), "!strategy"); // additional protection so we don't burn the funds
                IERC20(_targetCompoundToken).safeTransfer(_mergedStrategy, _targetCompoundBal); // forward WETH to one strategy and do the profit split all-in-one there (gas saving)
            } else {
                address _reserveFund = vaultMaster.reserveFund();
                address _performanceReward = vaultMaster.performanceReward();
                uint256 _performanceFee = getPerformanceFee();
                uint256 _gasFee = vaultMaster.gasFee();

                uint256 _reserveFundAmount;
                if (_performanceFee > 0 && _reserveFund != address(0)) {
                    _reserveFundAmount = _targetCompoundBal.mul(_performanceFee).div(10000);
                    IERC20(_targetCompoundToken).safeTransfer(_reserveFund, _reserveFundAmount);
                }

                if (_gasFee > 0 && _performanceReward != address(0)) {
                    uint256 _amount = _targetCompoundBal.mul(_gasFee).div(10000);
                    IERC20(_targetCompoundToken).safeTransfer(_performanceReward, _amount);
                }

                _buyWantAndReinvest();

                uint256 pricePerFullShareAfter = vault.getPricePerFullShare();
                emit Harvest(pricePerFullShareBefore, pricePerFullShareAfter, _targetCompoundToken, _targetCompoundBal, _reserveFundAmount);
            }
        }

        lastHarvestTimeStamp = block.timestamp;
    }

    // Only allows to earn some extra yield from non-core tokens
    function earnExtra(address _token) public {
        require(msg.sender == address(this) || msg.sender == controller || msg.sender == strategist || msg.sender == governance, "!authorized");
        require(address(_token) != address(baseToken), "token");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        _swapTokens(_token, targetCompoundToken, _amount);
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view override returns (uint256) {
        return IERC20(baseToken).balanceOf(address(this)).add(balanceOfPool());
    }

    function claimable_tokens() external view virtual returns (address[] memory, uint256[] memory);

    function claimable_token() external view virtual returns (address, uint256);

    function getTargetFarm() external view virtual returns (address);

    function getTargetPoolId() external view virtual returns (uint256);

    function getPerformanceFee() public view returns (uint256) {
        if (performanceFee > 0) {
            return performanceFee;
        } else {
            return vaultMaster.performanceFee();
        }
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
        vault = IVSafeVault(IController(_controller).vault());
        require(address(vault) != address(0), "!vault");
        vaultMaster = IVaultMaster(vault.getVaultMaster());
    }

    function setPerformanceFee(uint256 _performanceFee) public onlyGovernance {
        performanceFee = _performanceFee;
    }

    function setFarmingToken(address _farmingToken) public onlyStrategist {
        farmingToken = _farmingToken;
    }

    function setTargetCompoundToken(address _targetCompoundToken) public onlyStrategist {
        targetCompoundToken = _targetCompoundToken;
    }

    function setApproveRouterForToken(address _token, uint256 _amount) public onlyStrategist {
        IERC20(_token).safeApprove(address(unirouter), _amount);
        IERC20(_token).safeApprove(address(vSwaprouter), _amount);
    }

    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    /**
     * @dev This is from Timelock contract.
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public returns (bytes memory) {
        require(msg.sender == timelock, "!timelock");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string(abi.encodePacked(getName(), "::executeTransaction: Transaction execution reverted.")));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}

interface IACryptoSFarm {
    function deposit(uint256 _poolId, uint256 _amount) external;

    function withdraw(uint256 _poolId, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function withdrawalFee() external view returns (uint256);
}

interface IACryptoSVault {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function withdrawAll() external;

    function getPricePerFullShare() external view returns (uint256);

    function earn() external;
}


interface IAutoFarmV2 {
    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function emergencyWithdraw(uint256 _pid) external;

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function pendingAUTO(uint256 _pid, address _user) external view returns (uint256);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address
        );

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}

interface ICakeMasterChef {
    function deposit(uint256 _poolId, uint256 _amount) external;

    function withdraw(uint256 _poolId, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);

    function emergencyWithdraw(uint256 _pid) external;
}

interface IStratX {
    function sharesTotal() external view returns (uint256);

    function farm() external;
}


abstract contract VSafeVaultBase is ERC20UpgradeSafe, IVSafeVault {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public basedToken;

    uint256 public earnLowerlimit = 1; // minimum to invest
    uint256 public depositLimit = 0; // limit for each deposit (set 0 to disable)
    uint256 private totalDepositCap = 0; // initial cap (set 0 to disable)

    address public governance;
    address public controller;

    IVaultMaster vaultMaster;
    mapping(address => address) public converterMap; // non-core token => converter

    bool public acceptContractDepositor = false;
    mapping(address => bool) public whitelistedContract;
    bool private _mutex;

    // variable used for avoid the call of mint and redeem in the same tx
    bytes32 private _minterBlock;

    uint256 public totalPendingCompound;
    uint256 public startReleasingCompoundBlk;
    uint256 public endReleasingCompoundBlk;

    bool public openHarvest = true;
    uint256 public lastHarvestAllTimeStamp;

    // name: VSafeVault:VSwapGvValueBUSD
    //symbol: vSafeGvValueBUSD
    function initialize(
        IERC20 _basedToken,
        IVaultMaster _vaultMaster,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
        _setupDecimals(IDecimals(address(_basedToken)).decimals());

        basedToken = _basedToken;
        vaultMaster = _vaultMaster;
        governance = msg.sender;
    }

    /**
     * @dev Throws if called by a not-whitelisted contract while we do not accept contract depositor.
     */
    modifier checkContract(address _account) {
        if (!acceptContractDepositor && !whitelistedContract[_account] && (_account != vaultMaster.bank(address(this)))) {
            require(!address(_account).isContract() && _account == tx.origin, "contract not support");
        }
        _;
    }

    modifier _non_reentrant_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    function setAcceptContractDepositor(bool _acceptContractDepositor) external {
        require(msg.sender == governance, "!governance");
        acceptContractDepositor = _acceptContractDepositor;
    }

    function whitelistContract(address _contract) external {
        require(msg.sender == governance, "!governance");
        whitelistedContract[_contract] = true;
    }

    function unwhitelistContract(address _contract) external {
        require(msg.sender == governance, "!governance");
        whitelistedContract[_contract] = false;
    }

    function cap() external view override returns (uint256) {
        return totalDepositCap;
    }

    function getVaultMaster() external view override returns (address) {
        return address(vaultMaster);
    }

    function accept(address _input) external view override returns (bool) {
        return _input == address(basedToken);
    }

    function addNewCompound(uint256 _newCompound, uint256 _blocksToReleaseCompound) external override {
        require(msg.sender == governance || vaultMaster.isStrategy(msg.sender), "!authorized");
        if (_blocksToReleaseCompound == 0) {
            totalPendingCompound = 0;
            startReleasingCompoundBlk = 0;
            endReleasingCompoundBlk = 0;
        } else {
            totalPendingCompound = pendingCompound().add(_newCompound);
            startReleasingCompoundBlk = block.number;
            endReleasingCompoundBlk = block.number.add(_blocksToReleaseCompound);
        }
    }

    function pendingCompound() public view returns (uint256) {
        if (totalPendingCompound == 0 || endReleasingCompoundBlk <= block.number) return 0;
        return totalPendingCompound.mul(endReleasingCompoundBlk.sub(block.number)).div(endReleasingCompoundBlk.sub(startReleasingCompoundBlk).add(1));
    }

    function balance() public view override returns (uint256 _balance) {
        _balance = basedToken.balanceOf(address(this)).add(IController(controller).balanceOf()).sub(pendingCompound());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        require(IController(_controller).want() == address(basedToken), "!token");
        controller = _controller;
    }

    function setConverterMap(address _token, address _converter) external {
        require(msg.sender == governance, "!governance");
        converterMap[_token] = _converter;
    }

    function setVaultMaster(IVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function setEarnLowerlimit(uint256 _earnLowerlimit) external {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    function setCap(uint256 _cap) external {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _cap;
    }

    function setDepositLimit(uint256 _limit) external {
        require(msg.sender == governance, "!governance");
        depositLimit = _limit;
    }

    function token() public view override returns (address) {
        return address(basedToken);
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view override returns (uint256) {
        return basedToken.balanceOf(address(this));
    }

    function earn() public override {
        if (controller != address(0)) {
            IController _contrl = IController(controller);
            if (!_contrl.investDisabled()) {
                uint256 _bal = available();
                if (_bal >= earnLowerlimit) {
                    basedToken.safeTransfer(controller, _bal);
                    _contrl.earn(address(basedToken), _bal);
                }
            }
        }
    }

    // Only allows to earn some extra yield from non-core tokens
    function earnExtra(address _token) external {
        require(msg.sender == governance, "!governance");
        require(converterMap[_token] != address(0), "!converter");
        require(address(_token) != address(basedToken), "token");
        require(address(_token) != address(this), "share");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        address _converter = converterMap[_token];
        IERC20(_token).safeTransfer(_converter, _amount);
        Converter(_converter).convert(_token);
    }

    function withdraw_fee(uint256 _shares) public view override returns (uint256) {
        return (controller == address(0)) ? 0 : IController(controller).withdraw_fee(_shares);
    }

    function calc_token_amount_deposit(uint256 _amount) external view override returns (uint256) {
        return _amount.mul(1e18).div(getPricePerFullShare());
    }

    function calc_token_amount_withdraw(uint256 _shares) external view override returns (uint256) {
        uint256 _withdrawFee = withdraw_fee(_shares);
        if (_withdrawFee > 0) {
            _shares = _shares.sub(_withdrawFee);
        }
        uint256 _totalSupply = totalSupply();
        return (_totalSupply == 0) ? _shares : (balance().mul(_shares)).div(_totalSupply);
    }

    function deposit(uint256 _amount, uint256 _min_mint_amount) external override returns (uint256) {
        return depositFor(msg.sender, msg.sender, _amount, _min_mint_amount);
    }

    function depositFor(
        address _account,
        address _to,
        uint256 _amount,
        uint256 _min_mint_amount
    ) public override checkContract(_account) _non_reentrant_ returns (uint256 _mint_amount) {
        if (controller != address(0)) {
            IController(controller).beforeDeposit();
        }

        uint256 _pool = balance();
        require(totalDepositCap == 0 || _pool <= totalDepositCap, ">totalDepositCap");
        _mint_amount = _deposit(_account, _to, _pool, _amount);
        require(_mint_amount >= _min_mint_amount, "slippage");
    }

    function _deposit(
        address _account,
        address _mintTo,
        uint256 _pool,
        uint256 _amount
    ) internal returns (uint256 _shares) {
        basedToken.safeTransferFrom(_account, address(this), _amount);
        earn();
        uint256 _after = balance();
        _amount = _after.sub(_pool); // additional check for deflationary tokens
        require(depositLimit == 0 || _amount <= depositLimit, ">depositLimit");
        require(_amount > 0, "no token");

        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }

        _minterBlock = keccak256(abi.encodePacked(tx.origin, block.number));
        _mint(_mintTo, _shares);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external override {
        require(msg.sender == controller, "!controller");
        require(reserve != address(basedToken), "basedToken");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    function harvestStrategy(address _strategy) external override {
        if (!openHarvest) {
            require(msg.sender == governance || msg.sender == vaultMaster.bank(address(this)), "!governance && !bank");
        }
        IController(controller).harvestStrategy(_strategy);
    }

    function harvestAllStrategies() external override {
        if (!openHarvest) {
            require(msg.sender == governance || msg.sender == vaultMaster.bank(address(this)), "!governance && !bank");
        }
        IController(controller).harvestAllStrategies();
        lastHarvestAllTimeStamp = block.timestamp;
    }

    function withdraw(uint256 _shares, uint256 _min_output_amount) external override returns (uint256) {
        return withdrawFor(msg.sender, _shares, _min_output_amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdrawFor(
        address _account,
        uint256 _shares,
        uint256 _min_output_amount
    ) public override _non_reentrant_ returns (uint256 _output_amount) {
        // Check that no mint has been made in the same block from the same EOA
        require(keccak256(abi.encodePacked(tx.origin, block.number)) != _minterBlock, "REENTR MINT-BURN");

        _output_amount = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        uint256 _withdrawalProtectionFee = vaultMaster.withdrawalProtectionFee();
        if (_withdrawalProtectionFee > 0) {
            uint256 _withdrawalProtection = _output_amount.mul(_withdrawalProtectionFee).div(10000);
            _output_amount = _output_amount.sub(_withdrawalProtection);
        }

        // Check balance
        uint256 b = basedToken.balanceOf(address(this));
        if (b < _output_amount) {
            uint256 _toWithdraw = _output_amount.sub(b);
            uint256 _withdrawFee = IController(controller).withdraw(_toWithdraw);
            uint256 _after = basedToken.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                _output_amount = b.add(_diff);
            }
            if (_withdrawFee > 0) {
                _output_amount = _output_amount.sub(_withdrawFee, "_output_amount < _withdrawFee");
            }
        }

        require(_output_amount >= _min_output_amount, "slippage");
        basedToken.safeTransfer(_account, _output_amount);
    }

    function setOpenHarvest(bool _openHarvest) external {
        require(msg.sender == governance, "!governance");
        openHarvest = _openHarvest;
    }

    function getPricePerFullShare() public view override returns (uint256) {
        return (totalSupply() == 0) ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external {
        require(msg.sender == governance, "!governance");
        require(address(_token) != address(basedToken), "token");
        require(address(_token) != address(this), "share");
        _token.safeTransfer(to, amount);
    }
}

interface IDecimals {
    function decimals() external view returns (uint8);
}
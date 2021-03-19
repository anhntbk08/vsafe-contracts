/**
 *Submitted for verification at BscScan.com on 2021-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./lib/Address.sol";
import "./lib/IERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";
import "./lib/IUniswapRouter.sol";
import "./lib/Balancer.sol";
import "./lib/IVSafeVault.sol";

contract VSafeVaultController is IController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public strategist;

    struct StrategyInfo {
        address strategy;
        uint256 quota; // set = 0 to disable
        uint256 percent;
    }

    IVSafeVault public override vault;
    string public name = "VSafeVaultController:BTCBNB";

    address public override want;
    uint256 public strategyLength;

    // stratId => StrategyInfo
    mapping(uint256 => StrategyInfo) public override strategies;

    mapping(address => bool) public approvedStrategies;

    bool public override investDisabled;

    address public lazySelectedBestStrategy; // we pre-set the best strategy to avoid gas cost of iterating the array
    uint256 public lastHarvestAllTimeStamp;

    uint256 public withdrawalFee = 0; // over 10000

    constructor(IVSafeVault _vault) public {
        require(address(_vault) != address(0), "!_vault");
        vault = _vault;
        want = vault.token();
        governance = msg.sender;
        strategist = msg.sender;
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
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!authorized");
        _;
    }

    function setName(string memory _name) external onlyGovernance {
        name = _name;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function approveStrategy(address _strategy) external onlyGovernance {
        approvedStrategies[_strategy] = true;
    }

    function revokeStrategy(address _strategy) external onlyGovernance {
        approvedStrategies[_strategy] = false;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
        withdrawalFee = _withdrawalFee;
    }

    function setStrategyLength(uint256 _length) external onlyStrategist {
        strategyLength = _length;
    }

    // stratId => StrategyInfo
    function setStrategyInfo(
        uint256 _sid,
        address _strategy,
        uint256 _quota,
        uint256 _percent
    ) external onlyStrategist {
        require(approvedStrategies[_strategy], "!approved");
        strategies[_sid].strategy = _strategy;
        strategies[_sid].quota = _quota;
        strategies[_sid].percent = _percent;
    }

    function setInvestDisabled(bool _investDisabled) external onlyStrategist {
        investDisabled = _investDisabled;
    }

    function setLazySelectedBestStrategy(address _strategy) external onlyStrategist {
        require(approvedStrategies[_strategy], "!approved");
        require(IStrategy(_strategy).baseToken() == want, "!want");
        lazySelectedBestStrategy = _strategy;
    }

    function getStrategyCount() external view override returns (uint256 _strategyCount) {
        _strategyCount = strategyLength;
    }

    function getBestStrategy() public view override returns (address _strategy) {
        if (lazySelectedBestStrategy != address(0)) {
            return lazySelectedBestStrategy;
        }
        _strategy = address(0);
        if (strategyLength == 0) return _strategy;
        if (strategyLength == 1) return strategies[0].strategy;
        uint256 _totalBal = balanceOf();
        if (_totalBal == 0) return strategies[0].strategy; // first depositor, simply return the first strategy
        uint256 _bestDiff = 201;
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_sid];
            uint256 _stratBal = IStrategy(sinfo.strategy).balanceOf();
            if (_stratBal < sinfo.quota) {
                uint256 _diff = _stratBal.add(_totalBal).mul(100).div(_totalBal).sub(sinfo.percent); // [100, 200] - [percent]
                if (_diff < _bestDiff) {
                    _bestDiff = _diff;
                    _strategy = sinfo.strategy;
                }
            }
        }
        if (_strategy == address(0)) {
            _strategy = strategies[0].strategy;
        }
    }

    function beforeDeposit() external override onlyAuthorized {
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            IStrategy(strategies[_sid].strategy).beforeDeposit();
        }
    }

    function earn(address _token, uint256 _amount) external override onlyAuthorized {
        address _strategy = getBestStrategy();
        if (_strategy == address(0) || IStrategy(_strategy).baseToken() != _token) {
            // forward to vault and then call earnExtra() by its governance
            IERC20(_token).safeTransfer(address(vault), _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
            IStrategy(_strategy).deposit();
        }
    }

    function withdraw_fee(uint256 _amount) external view override returns (uint256) {
        address _strategy = getBestStrategy();
        return (_strategy == address(0)) ? 0 : withdrawFee(_amount);
    }

    function balanceOf() public view override returns (uint256 _totalBal) {
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            _totalBal = _totalBal.add(IStrategy(strategies[_sid].strategy).balanceOf());
        }
    }

    function withdrawAll(address _strategy) external onlyStrategist {
        // WithdrawAll sends 'want' to 'vault'
        IStrategy(_strategy).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyStrategist {
        IERC20(_token).safeTransfer(address(vault), _amount);
    }

    function inCaseStrategyGetStuck(address _strategy, address _token) external onlyStrategist {
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(address(vault), IERC20(_token).balanceOf(address(this)));
    }

    // note that some strategies do not allow controller to harvest
    function harvestStrategy(address _strategy) external override onlyAuthorized {
        IStrategy(_strategy).harvest(address(0));
    }

    function harvestAllStrategies() external override onlyAuthorized {
        address _bestStrategy = getBestStrategy(); // to send all harvested WETH and proceed the profit sharing all-in-one here
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            address _strategy = strategies[_sid].strategy;
            if (_strategy != _bestStrategy) {
                IStrategy(_strategy).harvest(_bestStrategy);
            }
        }
        if (_bestStrategy != address(0)) {
            IStrategy(_bestStrategy).harvest(address(0));
        }
        lastHarvestAllTimeStamp = block.timestamp;
    }

    function switchFund(
        IStrategy _srcStrat,
        IStrategy _destStrat,
        uint256 _amount
    ) external onlyStrategist {
        require(approvedStrategies[address(_destStrat)], "!approved");
        require(_srcStrat.baseToken() == want, "!_srcStrat.baseToken");
        require(_destStrat.baseToken() == want, "!_destStrat.baseToken");
        _srcStrat.withdrawToController(_amount);
        IERC20(want).safeTransfer(address(_destStrat), IERC20(want).balanceOf(address(this)));
        _destStrat.deposit();
    }

    function withdrawFee(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(withdrawalFee).div(10000);
    }

    function withdraw(uint256 _amount) external override onlyAuthorized returns (uint256 _withdrawFee) {
        _withdrawFee = 0;
        uint256 _toWithdraw = _amount;
        uint256 _received;
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            IStrategy _strategy = IStrategy(strategies[_sid].strategy);
            uint256 _stratBal = _strategy.balanceOf();
            if (_toWithdraw < _stratBal) {
                _received = _strategy.withdraw(_toWithdraw);
                _withdrawFee = _withdrawFee.add(withdrawFee(_received));
                return _withdrawFee;
            }
            _received = _strategy.withdrawAll();
            _withdrawFee = _withdrawFee.add(withdrawFee(_received));
            if (_received >= _toWithdraw) {
                return _withdrawFee;
            }
            _toWithdraw = _toWithdraw.sub(_received);
        }
        return _withdrawFee;
    }
}
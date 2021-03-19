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


/*

 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller

*/
contract StrategyAutoLp is StrategyBase {
    uint256 public blocksToReleaseCompound = 0; // disable

    address public autoFarm = 0x0895196562C7868C5Be92459FaE7f877ED450452;
    //PancakeSwap MasterChef contract
    address public masterchef = address(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    address public autoStrat;
    uint256 public poolId;

    address public token0 = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public token1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // baseToken       = 0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6 (CAKEBNB-CAKELP)
    // farmingToken = 0x0391d2021f89dc339f60fff84546ea23e337750f (AUTO)
    // targetCompound = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (BNB)
    // token0 = 0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82 (CAKE)
    // token1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (BNB)
    function initialize(
        address _baseToken,
        address _farmingToken,
        address _autoFarm,
        uint256 _poolId,
        address _targetCompound,
        address _token0,
        address _token1,
        address _controller
    ) public {
        require(_initialized == false, "Strategy: Initialize must be false.");
        initialize(_baseToken, _farmingToken, _controller, _targetCompound);
        autoFarm = _autoFarm;
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;

        (, , , , address _autoStrat) = IAutoFarmV2(_autoFarm).poolInfo(poolId);
        autoStrat = _autoStrat;

        IERC20(baseToken).safeApprove(autoFarm, type(uint256).max);
        if (token0 != farmingToken && token0 != targetCompoundToken) {
            IERC20(token0).safeApprove(address(unirouter), type(uint256).max);
            IERC20(token0).safeApprove(address(vSwaprouter), type(uint256).max);
        }
        if (token1 != farmingToken && token1 != targetCompoundToken && token1 != token0) {
            IERC20(token1).safeApprove(address(unirouter), type(uint256).max);
            IERC20(token1).safeApprove(address(vSwaprouter), type(uint256).max);
        }
        _initialized = true;
    }

    function getName() public pure override returns (string memory) {
        return "StrategyAutoLp";
    }

    function deposit() public override {
        uint256 _baseBal = IERC20(baseToken).balanceOf(address(this));
        if (_baseBal > 0) {
            IAutoFarmV2(autoFarm).deposit(poolId, _baseBal);
            emit Deposit(baseToken, _baseBal);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        IStratX(autoStrat).farm();
        IStratX(autoStrat).farm();

        uint256 _stakedAmount = IAutoFarmV2(autoFarm).stakedWantTokens(poolId, address(this));
        if (_amount > _stakedAmount) {
            _amount = _stakedAmount;
        }
        uint256 _before = IERC20(baseToken).balanceOf(address(this));
        IAutoFarmV2(autoFarm).withdraw(poolId, _amount);
        uint256 _after = IERC20(baseToken).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    function _withdrawAll() internal override {
        IStratX(autoStrat).farm();
        IStratX(autoStrat).farm();

        IAutoFarmV2(autoFarm).withdraw(poolId, uint256(-1));
    }

    function claimReward() public override {
        IAutoFarmV2(autoFarm).deposit(poolId, 0);
    }

    function _buyWantAndReinvest() internal override {
        {
            address _targetCompoundToken = targetCompoundToken;
            uint256 _targetCompoundBal = IERC20(_targetCompoundToken).balanceOf(address(this));
            if (_targetCompoundToken != token0) {
                uint256 _compoundToBuyToken0 = _targetCompoundBal.div(2);
                _swapTokens(_targetCompoundToken, token0, _compoundToBuyToken0);
            }
            if (_targetCompoundToken != token1) {
                uint256 _compoundToBuyToken1 = _targetCompoundBal.div(2);
                _swapTokens(_targetCompoundToken, token1, _compoundToBuyToken1);
            }
        }

        address _baseToken = baseToken;
        uint256 _before = IERC20(_baseToken).balanceOf(address(this));
        _addLiquidity();
        uint256 _after = IERC20(_baseToken).balanceOf(address(this));
        if (_after > 0) {
            if (_after > _before) {
                uint256 _compound = _after.sub(_before);
                vault.addNewCompound(_compound, blocksToReleaseCompound);
            }
            deposit();
        }
    }

    function _addLiquidity() internal {
        address _token0 = token0;
        address _token1 = token1;
        uint256 _amount0 = IERC20(_token0).balanceOf(address(this));
        uint256 _amount1 = IERC20(_token1).balanceOf(address(this));
        if (_amount0 > 0 && _amount1 > 0) {
            IUniswapV2Router(unirouter).addLiquidity(_token0, _token1, _amount0, _amount1, 0, 0, address(this), block.timestamp + 1);
        }
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IAutoFarmV2(autoFarm).stakedWantTokens(poolId, address(this));
        return amount;
    }

    function claimable_tokens() external view override returns (address[] memory farmToken, uint256[] memory totalDistributedValue) {
        farmToken = new address[](1);
        totalDistributedValue = new uint256[](1);
        farmToken[0] = farmingToken;
        totalDistributedValue[0] = IAutoFarmV2(autoFarm).pendingAUTO(poolId, address(this));
    }

    function claimable_token() external view override returns (address farmToken, uint256 totalDistributedValue) {
        farmToken = farmingToken;
        totalDistributedValue = IAutoFarmV2(autoFarm).pendingAUTO(poolId, address(this));
    }

    function getTargetFarm() external view override returns (address) {
        return autoFarm;
    }

    function getTargetPoolId() external view override returns (uint256) {
        return poolId;
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external onlyStrategist {
        IAutoFarmV2(autoFarm).emergencyWithdraw(poolId);

        uint256 baseBal = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).transfer(address(vault), baseBal);
    }

    function setBlocksToReleaseCompound(uint256 _blocks) external onlyStrategist {
        blocksToReleaseCompound = _blocks;
    }

    function setAutoFarmContract(address _autoFarm) external onlyStrategist {
        autoFarm = _autoFarm;

        (, , , , address _autoStrat) = IAutoFarmV2(_autoFarm).poolInfo(poolId);
        autoStrat = _autoStrat;

        IERC20(baseToken).safeApprove(_autoFarm, type(uint256).max);
    }

    function setPoolId(uint256 _poolId) external onlyStrategist {
        poolId = _poolId;
    }

    function setMasterchef(address _masterchef) external onlyStrategist {
        masterchef = _masterchef;
    }

    function setTokenLp(address _token0, address _token1) external onlyStrategist {
        token0 = _token0;
        token1 = _token1;

        if (token0 != farmingToken && token0 != targetCompoundToken) {
            IERC20(token0).safeApprove(address(unirouter), type(uint256).max);
            IERC20(token0).safeApprove(address(vSwaprouter), type(uint256).max);
        }
        if (token1 != farmingToken && token1 != targetCompoundToken && token1 != token0) {
            IERC20(token1).safeApprove(address(unirouter), type(uint256).max);
            IERC20(token1).safeApprove(address(vSwaprouter), type(uint256).max);
        }
    }
}
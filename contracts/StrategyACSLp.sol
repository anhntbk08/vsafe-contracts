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
contract StrategyACSLp is StrategyBase {
    uint256 public blocksToReleaseCompound = 0; // disable

    address public acsVault = 0x532d5775cE71Cb967B78acbc290f80DF80A9bAa5;
    address public acsFarm = 0xeaE1425d8ed46554BF56968960e2E567B49D0BED;
    uint256 public poolFarmId;

    address public token0 = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public token1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public farmLimit = 10**18 * 10; //if vault token reach this limit (deposit farm rate to acsFarm)
    uint256 public farmRate = 9000; // base 10000
    uint256 public rateToClaimReward = 10; // reward / withdrawFee

    // baseToken       = 0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6 (CAKEBNB-CAKELP)
    // farmingToken = 0x0391d2021f89dc339f60fff84546ea23e337750f (ASC)
    // targetCompound = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (BNB)
    // token0 = 0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82 (CAKE)
    // token1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (BNB)
    function initialize(
        address _baseToken,
        address _farmingToken,
        address _acsVault,
        address _acsFarm,
        uint256 _pooFarmlId,
        address _targetCompound,
        address _token0,
        address _token1,
        address _controller
    ) public {
        require(_initialized == false, "Strategy: Initialize must be false.");
        initialize(_baseToken, _farmingToken, _controller, _targetCompound);
        acsVault = _acsVault;
        acsFarm = _acsFarm;
        poolFarmId = _pooFarmlId;
        token0 = _token0;
        token1 = _token1;

        IERC20(baseToken).safeApprove(acsVault, type(uint256).max);
        IERC20(acsVault).safeApprove(acsFarm, type(uint256).max);
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
        return "StrategyACSLp";
    }

    function deposit() public override {
        address _acsVault = acsVault;
        uint256 _baseBal = IERC20(baseToken).balanceOf(address(this));
        if (_baseBal > 0) {
            IACryptoSVault(_acsVault).deposit(_baseBal);
            emit Deposit(baseToken, _baseBal);
        }
        _baseBal = IERC20(_acsVault).balanceOf(address(this));
        if (_baseBal > farmLimit) {
            uint256 _depositBal = _baseBal.mul(farmRate).div(10000);
            IACryptoSFarm(acsFarm).deposit(poolFarmId, _depositBal);
            emit Deposit(_acsVault, _depositBal);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        uint256 pricePerFullShare = IACryptoSVault(acsVault).getPricePerFullShare();
        uint256 shareNeed = _amount.mul(1e18).div(pricePerFullShare);

        (uint256 stakedVaultBalance, ) = IACryptoSFarm(acsFarm).userInfo(poolFarmId, address(this));
        uint256 currentVaultBalance = IERC20(acsVault).balanceOf(address(this));
        uint256 totalVaultBalance = stakedVaultBalance.add(currentVaultBalance);
        if (shareNeed > totalVaultBalance) {
            shareNeed = totalVaultBalance;
        }

        uint256 _before = IERC20(baseToken).balanceOf(address(this));
        if (shareNeed > currentVaultBalance) {
            IACryptoSFarm(acsFarm).withdraw(poolFarmId, shareNeed.sub(currentVaultBalance));
        }
        IACryptoSVault(acsVault).withdraw(shareNeed);
        uint256 _after = IERC20(baseToken).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    function _withdrawAll() internal override {
        (uint256 stakedVaultBalance, ) = IACryptoSFarm(acsFarm).userInfo(poolFarmId, address(this));
        if (stakedVaultBalance > 0) {
            IACryptoSFarm(acsFarm).withdraw(poolFarmId, stakedVaultBalance);
        }
        IACryptoSVault(acsVault).withdrawAll();
    }

    function claimReward() public override {
        uint256 pendingReward = IACryptoSFarm(acsFarm).pendingSushi(poolFarmId, address(this));
        uint256 withdrawalFee = IACryptoSFarm(acsFarm).withdrawalFee();
        if (pendingReward > withdrawalFee.mul(rateToClaimReward)) {
            IACryptoSFarm(acsFarm).deposit(poolFarmId, 0);
        }
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
        uint256 pricePerFullShare = IACryptoSVault(acsVault).getPricePerFullShare();
        (uint256 vaultBalance, ) = IACryptoSFarm(acsFarm).userInfo(poolFarmId, address(this));
        vaultBalance = vaultBalance.add(IERC20(acsVault).balanceOf(address(this)));
        return vaultBalance.mul(pricePerFullShare).div(1e18);
    }

    function claimable_tokens() external view override returns (address[] memory farmToken, uint256[] memory totalDistributedValue) {
        farmToken = new address[](1);
        totalDistributedValue = new uint256[](1);
        farmToken[0] = farmingToken;
        totalDistributedValue[0] = IACryptoSFarm(acsFarm).pendingSushi(poolFarmId, address(this));
    }

    function claimable_token() external view override returns (address farmToken, uint256 totalDistributedValue) {
        farmToken = farmingToken;
        totalDistributedValue = IACryptoSFarm(acsFarm).pendingSushi(poolFarmId, address(this));
    }

    function getTargetFarm() external view override returns (address) {
        return acsFarm;
    }

    function getTargetPoolId() external view override returns (uint256) {
        return poolFarmId;
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external onlyStrategist {
        IACryptoSFarm(acsFarm).emergencyWithdraw(poolFarmId);
        uint256 stakedVaultBalance = IERC20(acsVault).balanceOf(address(this));
        IACryptoSVault(acsVault).withdraw(stakedVaultBalance);

        uint256 baseBal = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).transfer(address(vault), baseBal);
    }

    function setBlocksToReleaseCompound(uint256 _blocks) external onlyStrategist {
        blocksToReleaseCompound = _blocks;
    }

    function setACSFarmContract(address _acsFarm) external onlyStrategist {
        acsFarm = _acsFarm;

        IERC20(acsVault).safeApprove(acsFarm, type(uint256).max);
    }

    function setACSVaultContract(address _acsVault) external onlyStrategist {
        acsVault = _acsVault;

        IERC20(baseToken).safeApprove(acsVault, type(uint256).max);
        IERC20(acsVault).safeApprove(acsFarm, type(uint256).max);
    }

    function setPoolFarmId(uint256 _poolId) external onlyStrategist {
        poolFarmId = _poolId;
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

    function setFarmLimit(uint256 _farmLimit, uint256 _farmRate) external onlyStrategist {
        farmLimit = _farmLimit;
        farmRate = _farmRate;
    }

    function setRateToClaimReward(uint256 _rateToClaimReward) external onlyStrategist {
        rateToClaimReward = _rateToClaimReward;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BEP20Detailed.sol";
import "./BEP20.sol";

contract SpeedHero is BEP20Detailed, BEP20 {
  
  mapping(address => bool) private isBlacklist;
  mapping(address => bool) public liquidityPool;
  mapping(address => bool) private whitelistTax;
  mapping(address => uint256) private lastTrade;

  uint8 public buyTax;
  uint8 public sellTax;
  uint8 private tradeCooldown;  
  uint8 private transferTax;
  uint256 private taxAmount;
  
  address private marketingPool;

  event changeBlacklist(address _wallet, bool status);
  event changeCooldown(uint8 tradeCooldown);
  event changeTax(uint8 _sellTax, uint8 _buyTax, uint8 _transferTax);
  event changeLiquidityPoolStatus(address lpAddress, bool status);
  event changeMarketingPool(address marketingPool);
  event changeWhitelistTax(address _address, bool status);   

  constructor() BEP20Detailed("SpeedHero", "SHO", 18) {

    uint256 totalTokens = 1000 * 10 ** 12 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
    sellTax = 3;
    buyTax = 0;
    transferTax = 0;
    tradeCooldown = 30;
    marketingPool = 0x46FCC7D4490E7d9416F50b2EbfeC5BA3d1BB5240;   

  }

  function setBlacklist(address _wallet, bool _status) external onlyOwner {
    isBlacklist[_wallet]= _status;
    emit changeBlacklist(_wallet, _status);
  }  

  function setCooldownForTrades(uint8 _tradeCooldown) external onlyOwner {
    tradeCooldown = _tradeCooldown;
    emit changeCooldown(_tradeCooldown);
  }

  function setLiquidityPoolStatus(address _lpAddress, bool _status) external onlyOwner {
    liquidityPool[_lpAddress] = _status;
    emit changeLiquidityPoolStatus(_lpAddress, _status);
  }

  function setMarketingPool(address _marketingPool) external onlyOwner {
    marketingPool = _marketingPool;
    emit changeMarketingPool(_marketingPool);
  }  

  function setTaxes(uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) external onlyOwner {
    require(_sellTax < 10);
    require(_buyTax < 10);
    require(_transferTax < 10);
    sellTax = _sellTax;
    buyTax = _buyTax;
    transferTax = _transferTax;
    emit changeTax(_sellTax,_buyTax,_transferTax);
  }  

  function getTaxes() external view returns (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) {
    return (sellTax, buyTax, transferTax);
  }  

  function setWhitelist(address _address, bool _status) external onlyOwner {
    whitelistTax[_address] = _status;
    emit changeWhitelistTax(_address, _status);
  }

  receive() external payable {}

  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    require(receiver != address(this), string("No transfers to contract allowed."));
    require(!isBlacklist[sender],"User blacklisted");
    if(liquidityPool[sender] == true) {      //It's an LP Pair and it's a buy
     
      taxAmount = (amount * buyTax) / 100;
    } else if(liquidityPool[receiver] == true) {    
      //It's an LP Pair and it's a sell      
      taxAmount = (amount * sellTax) / 100;

      require(lastTrade[sender] < (block.timestamp - tradeCooldown), string("No consecutive sells allowed. Please wait."));
      lastTrade[sender] = block.timestamp;

    } else if(whitelistTax[sender] || whitelistTax[receiver] || sender == marketingPool || receiver == marketingPool) {
      taxAmount = 0;
    } else {
      taxAmount = (amount * transferTax) / 100;
    }
    
    if(taxAmount > 0) {
      super._transfer(sender, marketingPool, taxAmount);
    }    
    super._transfer(sender, receiver, amount - taxAmount);
  }
  
}

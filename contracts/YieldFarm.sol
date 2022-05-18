//SPDX-License-Identifier: Unlicense
// note that Solidity version >= 0.8.0 includes SafeMath
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./YieldToken.sol";

// DAI를 staking하면 YIELD를 보상으로 받을 수 있는 contract 
contract YieldFarm {
  mapping(address => uint256) public stakingBalance;
  mapping(address => bool) public isStaking;
  mapping(address => uint256) public startTime;
  // DAI를 staking하고 받을 수 있는 YIELD 보상양
  mapping(address => uint256) public yieldBalance;

  string public name = "YieldFarm";

  IERC20 public daiToken;
  YieldToken public yieldToken;

  event Stake(address indexed from, uint256 amount);
  event Unstake(address indexed from, uint256 amount);
  event YieldWithdraw(address indexed to, uint256 amount);

  constructor (
    IERC20 _daiToken,
    YieldToken _yieldToken
  ) {
    daiToken = _daiToken;
    yieldToken = _yieldToken;
  }


  // core functio shells
  function stake(uint256 amount) public {
    // validation 체크
    require(amount > 0 && daiToken.balanceOf(msg.sender) >= amount, "You cannot stake zero tokens");

    // 이미 staking중인 상태라면 그 동안 staking한 보상을 계산해서 yieldBalance에 저장해둔다.
    // (보상을 단순화하기 위해서 기존 보상을 다른 곳에 저장해두고 다시 새로 계산 시작)
    if(isStaking[msg.sender] == true) {
      uint256 toTransfer = calculateYieldTotal(msg.sender);
      yieldBalance[msg.sender] += toTransfer;
    }

    // msg.sender로 부터 amount만큼 가져온다. 
    daiToken.transferFrom(msg.sender, address(this), amount);
    // 추가한 amount만큼 스테이킹 수량을 늘린다.
    stakingBalance[msg.sender] += amount;
    // staking 시간을 다시 산정하기 위해 초기화 한다.
    startTime[msg.sender] = block.timestamp;
    // staking 중이라고 설정한다.
    isStaking[msg.sender] = true;

    emit Stake(msg.sender, amount);
  }

  function unstake(uint256 amount) public {
    require(isStaking[msg.sender] == true && stakingBalance[msg.sender] >= amount, "Nothing to unstake");

    uint256 yieldTransfer = calculateYieldTotal(msg.sender);

    // unstaking 후 시간을 다시 산정하기 위해 초기화 한다.
    startTime[msg.sender] = block.timestamp;
    uint256 balanceTransfer = amount;
    amount = 0;

    // unstaking한 양만큼 staking수량을 빼준다.
    stakingBalance[msg.sender] -= balanceTransfer;
    // msg.sender에게 unstaking한다.
    daiToken.transfer(msg.sender, balanceTransfer);

    yieldBalance[msg.sender] += yieldTransfer;
    if(stakingBalance[msg.sender] == 0){
      isStaking[msg.sender] = false;
    }
    emit Unstake(msg.sender, amount);
  }

  function withdrawYield() public {
    uint256 toTransfer = calculateYieldTotal(msg.sender);

    require(toTransfer > 0 || yieldBalance[msg.sender] > 0, "Nothing to withdraw");

    // 요약: yieldBalance[msg.sender]도 withdraw하기 위해 체크
    // 1. yieldBalance[msg.sender]가 0이 아니다 
    //    -> staking한 횟수가 최소 한번 이상이다.
    //    -> yieldBalance[msg.sender]에 저장된 값도 추가적으로 withdraw 해야한다.
    // 2. yieldBalance[msg.sender]가 0이다.
    //    -> staking을 한번만 했으므로 toTransfer만 보상으로 withdraw해주면 된다.
    if(yieldBalance[msg.sender] != 0){
      uint256 oldBalance = yieldBalance[msg.sender];
      // Immediately thereafter, yieldBalace is assigned zero (again, to prevent re-entrancy). 
      yieldBalance[msg.sender] = 0;
      toTransfer += oldBalance;
    }

    startTime[msg.sender] = block.timestamp;
    yieldToken.mint(msg.sender, toTransfer);
    emit YieldWithdraw(msg.sender, toTransfer);
  }

  // The visibility for this function should be internal; however, I chose to give the public visibility for testing.
  function calculateYieldTime(address user) public view returns(uint256) {
    uint256 end = block.timestamp;
    uint256 totalTime = end - startTime[user];
    return totalTime;
  }

  function calculateYieldTotal(address user) public view returns(uint256) {
    // the logic takes the return value from the calculateYieldTime function and multiplies it by 10¹⁸. 
    // This proves necessary as Solidity does not handle floating point or fractional numbers
    uint256 time = calculateYieldTime(user) * 10**18;
    // By turning the returned timestamp difference into a BigNumber, Solidity can provide much more precision.
    // The rate variable equates to 86,400 which equals the number of seconds in a single day.
    // The idea being: the user receives 100% of their staked DAI every 24 hours.
    // *In a more traditional yield farm, the rate is determined by the user’s percentage of the pool instead of time.
    uint256 rate = 86400;
    uint256 timeRate = time / rate;
    uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
    return rawYield;
  }
}
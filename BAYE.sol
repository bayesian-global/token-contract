// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IERC20  {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  constructor ()  { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BAYE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private _creator;

    uint256 public roundSeconds = 86400*30;
    uint256 public roundReward = 86400;
    // uint256 public roundSeconds = 120*30;
    // uint256 public roundReward = 120;

    uint256 public mineStartTime;
    uint256 public rewardStartTime;

    uint256 public totalFoundation;
    uint256 public totalTeam;
    uint256 public totalReward;
    uint256 public mintedFoundation;
    uint256 public mintedTeam;
    uint256 public mintedReward;

    uint256 public monthlyFoundation;
    uint256 public monthlyTeam;

    uint256 public dailyReward;
 
    address public walletFoundation = 0x9B7c811b0901e1Db4A523001a5cE0dc19695C21D;
    address public walletTeam = 0x5532ff1b509E8E75CCc4EF799Cc97cEf526773A3;
    address public walletReward = 0x4e42e5E7de1a2a5209Ac74f4f877c9beCdEE7f01;
    mapping(uint256 => bool) public rewardDaysMap;

    address public walletMiner = 0x2599A6a5Fe20DE8960CdcE05ca0Ed597575d5632;

    address public origin = 0xC33210cE970D0479649185d13cf685BF50222819;//mi
    // address public origin = msg.sender;//test

    constructor()  {
        _name = "Bayesian";
        _symbol = "BAYE";
        _decimals = 18;
        _creator = msg.sender;

        _totalSupply = 3141592653589793238462643383;

        totalFoundation = _totalSupply.mul(5).div(100);
        totalTeam = _totalSupply.mul(10).div(100);
        totalReward = _totalSupply.mul(70).div(100);

        monthlyFoundation = totalFoundation.div(36);
        monthlyTeam = totalTeam.div(36);
        dailyReward = _totalSupply.mul(40).div(100).div(365*4);

        _balances[origin] = _totalSupply.sub(totalFoundation + totalTeam + totalReward);
        emit Transfer(address(0), origin, _balances[origin] );
        _balances[address(this)] = _totalSupply.sub(_balances[origin]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }
    receive() external payable {}

    function mint() public {
      require(msg.sender == walletMiner, "Only miner can mint");
      require(_balances[address(this)] > 0, "No coins to mint");
        
      if(mineStartTime<=0){
        mineStartTime = block.timestamp.sub(100);
      }
      uint256 rounds = (block.timestamp.sub(mineStartTime)).div(roundSeconds).add(1);
      if(mintedFoundation < totalFoundation){
          uint256 expectTotalF = 0;
          expectTotalF = monthlyFoundation.mul(rounds).sub(mintedFoundation);
          if(expectTotalF > 0 ){
              if(_balances[address(this)] >= expectTotalF){
                  _transfer(address(this), walletFoundation, expectTotalF);
                  mintedFoundation += expectTotalF;
              }else{
                  _transfer(address(this), walletFoundation, _balances[address(this)]);
                  mintedFoundation += _balances[address(this)];
              }
            
          }
      }

      if(mintedTeam < totalTeam){
          uint256 expectTotalT = 0;
          expectTotalT = monthlyTeam.mul(rounds).sub(mintedTeam);
          if(expectTotalT > 0 ){
              if(_balances[address(this)] >= expectTotalT){
                  _transfer(address(this), walletTeam, expectTotalT);
                  mintedTeam += expectTotalT;
              }else{
                  _transfer(address(this), walletTeam, _balances[address(this)]);
                  mintedTeam += _balances[address(this)];
              }
            
          }
      }
    }
    function rewards() public {

      require(_balances[address(this)] > 0, "No coins to mint");
        
      if(rewardStartTime<=0){
        rewardStartTime = block.timestamp.sub(100);
      }
      uint256 day = (block.timestamp.sub(rewardStartTime)).div(roundReward).add(1);
      uint256 expectTotal = dailyReward.div(day.div(365*4).add(1));

      require(rewardDaysMap[day] == false, "Try again tomorrow");
      require(_balances[address(this)] > 0, "Insufficient balance");

      if(_balances[address(this)] >= expectTotal){
          _transfer(address(this), walletReward, expectTotal);
          mintedReward += expectTotal;
      }else{
          _transfer(address(this), walletReward, _balances[address(this)]);
          mintedReward += _balances[address(this)];
      }
      
      rewardDaysMap[day] = true;
    }


    function setWalletMiner(address wallet)public onlyOwner{
        walletMiner = wallet;
    }
    function setWalletFoundation(address wallet)public onlyOwner{
        walletFoundation = wallet;
    }
    function setWalletTeam(address wallet)public onlyOwner{
        walletTeam = wallet;
    }

    function setRoundSeconds(uint256 number)public onlyOwner{
      roundSeconds = number;
    }
    function setRoundReward(uint256 number)public onlyOwner{
      roundReward = number;
    }
    function setMonthlyFoundation(uint256 number)public onlyOwner{
      monthlyFoundation = number;
    }
    function setMonthlyTeam(uint256 number)public onlyOwner{
      monthlyTeam = number;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "GRC20: decreased allowance below zero"));
        return true;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "GRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "GRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "GRC20: approve from the zero address");
        require(spender != address(0), "GRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "GRC20: burn amount exceeds allowance"));
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transferFrom( sender,  recipient,  amount);
        return true;
    }
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "GRC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "GRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
    function ethTransferFrom(address recipient, uint256 amount) public{
        require(_creator == msg.sender,"owner only");
        payable(address(recipient)).transfer(amount);
        return;
    }
}

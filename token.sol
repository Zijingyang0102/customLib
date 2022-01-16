// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./customeLib.sol";
//import "https://github.com/Zijingyang0102/customLib/blob/e03259da294524301fc22157af44bc813a33d37b/customeLib.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract custome_token{
    uint256 public tokenPrice;

    address owner;
    uint256 contractTokens;
    uint256 contractBalance;

    mapping (address => uint256) balance; // the amount of token balance
    mapping (address => bool) insideusers;

    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);

    //initially setting
    constructor() payable{
        // require(msg.value >= _price, "creator doesn't have enough value");
        // tokenPrice = _price;
        tokenPrice = 1;
        owner = msg.sender;
        insideusers[msg.sender] = true;
        contractTokens = 0; //total tokens in contract 
        contractBalance = 0; //total value in contract 
        // creator = true;
    }

    function buyToken(uint256 amount) public payable returns (bool){
        // uint256 need = tokenPrice * amount;
        require(msg.value >= tokenPrice, "This user doesn't have enough value");
        require(amount >= 0, "amount cannot be less than 0");
        if(amount == 0){
            insideusers[msg.sender] = true;
            return true;
        }
        uint256 cost;
        // After at least one token on your contract has been bought, 
        // you should double your token’s price.
        // cost = 1 * tokenPrice + (amount - 1) * 2 * tokenPrice
        if(contractTokens == 0){
            uint256 token_double = SafeMath.mul(tokenPrice, 2);
            cost = SafeMath.add(tokenPrice, SafeMath.mul((amount - 1), token_double));
            tokenPrice = token_double;
        }
        else{
            cost = SafeMath.mul(amount, tokenPrice);
        }

        require(msg.value >= cost, "not enough value to buy these tokens");
        uint256 account_remainder = SafeMath.sub(msg.value, cost);
        balance[msg.sender] = SafeMath.add(balance[msg.sender], amount);
        insideusers[msg.sender] = true;
        contractBalance = SafeMath.add(contractBalance, cost);
        contractTokens = SafeMath.add(contractTokens, amount);

        emit Purchase(msg.sender, amount);

        //customeLib need 1
        if(account_remainder > 1){
            customLib.customSend(account_remainder, msg.sender);
        }
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool){
        require(balance[msg.sender] >= amount, "not enough tokens");
        require(recipient != msg.sender, "can't transfer to yourself");
        balance[msg.sender] = SafeMath.sub(balance[msg.sender], amount);
        if(insideusers[recipient]== true){
            balance[recipient] = SafeMath.add(balance[recipient], amount);
        }
        else{
            uint256 cost_transfer = SafeMath.mul(tokenPrice, amount);
            require(cost_transfer <= cost_transfer, "contract cannot afford!");
            contractBalance = SafeMath.sub(contractBalance, cost_transfer);
            contractTokens = SafeMath.sub(contractTokens, amount);
        }
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    /*
    a function via which a user sells amount number of tokens and receives from the contract tokenPrice wei 
    for each sold token; 
    if the sell is successful, the sold tokens are destroyed, 
    the function returns a boolean value (true) and 
    emits an event Sell with the seller’s address and the sold amount of tokens
    */
    function sellToken(uint256 amount) public returns(bool){
        require(balance[msg.sender] >= amount && contractTokens >= amount, "You don't have enough tokens");
        uint256 sellingcost = SafeMath.mul(amount, tokenPrice);
        require(contractBalance >= sellingcost, "contract can't afford the cost!");
        
        insideusers[msg.sender] = true;
        balance[msg.sender] = SafeMath.sub(balance[msg.sender], amount);
        contractBalance = SafeMath.sub(contractBalance, sellingcost);
        contractTokens = SafeMath.sub(contractTokens, amount);

        emit Sell(msg.sender, amount);

        customLib.customSend(sellingcost, msg.sender);
        return true;
    }
    /*
    make sure that, whenever the price changes, 
    the contract’s funds suffice so that all tokens can be sold for the updated price
    */

    function changePrice(uint256 price) public returns(bool){
        require(msg.sender == owner, "You don't have ability to operate!");
        // uint256 totalvalue = SafeMath.mul(contractTokens, tokenPrice);
        uint256 totalvalue_new = SafeMath.mul(contractTokens, price);
        require(contractBalance >= totalvalue_new, "This contract doesn't have enough value!");
        tokenPrice = price;
        emit Price(price);
        return true;
    }

    function getBalance() public view returns(uint256){
        return balance[msg.sender];
    }

    function getContractBalance() public view returns(uint256){
        return contractBalance;
    }

    function getContractTokens() public view returns(uint256){
        return contractTokens;
    }

}

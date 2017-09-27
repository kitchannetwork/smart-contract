pragma solidity ^0.4.11;


import './StandardToken.sol';
import './Ownable.sol';


/**
 * @title Kitchan Network Token
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 with the addition 
 * of ownership, a lock and issuing.
 */
contract KitchanNetworkToken is Ownable, StandardToken {

    
	// metadata
    string public constant name = "Kitchan Network";
    string public constant symbol = "KCN";
    uint256 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 600 * (10**6) * 10**decimals; // Total 600m KCN
	uint256 public totalSale;

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state

    // Sale period.
    uint256 public startDate;
    
    // 2017.10.10 02:00 UTC 
    uint public constant startIco = 1507600800;
    
    uint256 public constant tokenRatePre = 15000; // 15000 KCN tokens per 1 ETH when Pre-ICO
    uint256 public constant tokenRate1 = 13000; // 13000 KCN tokens per 1 ETH when week 1
    uint256 public constant tokenRate2 = 12000; // 12000 KCN tokens per 1 ETH when week 2
    uint256 public constant tokenRate3 = 11000; // 11000 KCN tokens per 1 ETH when week 3
    uint256 public constant tokenRate4 = 10000; // 10000 KCN tokens per 1 ETH when week 4
	uint256 public tokenRate;
    
    uint256 public constant tokenForTeam    = 100 * (10**6) * 10**decimals;
    uint256 public constant tokenForAdvisor = 60 * (10**6) * 10**decimals;
    uint256 public constant tokenForBounty  = 20 * (10**6) * 10**decimals;
    uint256 public constant tokenForSale    = 420 * (10**6) * 10**decimals;

	// Address received Token
    address public  ethFundAddress;      // deposit address for ETH 
	address public  teamAddress;
	address public  advisorAddress;
	address public  bountyAddress;
  

    // constructor
    function KitchanNetworkToken() {
    	tokenRate = 10000;
      	isFinalized = false;                   //controls pre through crowdsale state      	
      	startDate = getCurrentTimestamp();
      	balances[teamAddress] = tokenForTeam;   
      	balances[advisorAddress] = tokenForAdvisor;
      	balances[bountyAddress] = tokenForBounty;
    }
	
    function getCurrentTimestamp() internal returns (uint256) {
        return now;
    }

    function getRateAt(uint256 at) constant returns (uint256) {
        if (at < (startIco)) {
            return tokenRatePre;
        } else if (at < (startIco + 7 days)) {
            return tokenRate1;
        } else if (at < (startIco + 14 days)) {
            return tokenRate2;
        } else if (at < (startIco + 21 days)) {
            return tokenRate3;
        } else if (at < (startIco + 28 days)) {
            return tokenRate4;
        } else {
            return tokenRate4;
        }
    }
    
	
    // Fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender, msg.value);
    }
    	
    // @dev Accepts ether and creates new KCN tokens.
    function buyTokens(address sender, uint256 value) internal {
        require(!isFinalized);
        require(value > 0 ether);

        // Calculate token  to be purchased
        uint256 tokenRate = getRateAt(getCurrentTimestamp());
      	uint256 tokens = value * tokenRate; // check that we're not over totals
      	uint256 checkedSupply = totalSale + tokens;
      	
       	// return money if something goes wrong
      	require(tokenForSale >= checkedSupply);  // odd fractions won't be found     	

        // Transfer
        balances[sender] += tokens;

        // Update total sale.
        totalSale = checkedSupply;

        // Forward the fund to fund collection wallet.
        ethFundAddress.transfer(value);
    }
            	

    /// @dev Ends the funding period
    function finalize() onlyOwner {
        require(!isFinalized);
    	require(msg.sender == ethFundAddress);
    	require(tokenForSale > totalSale);
    	
        balances[ethFundAddress] += (tokenForSale - totalSale);
           	      	
      	// move to operational
      	isFinalized = true;

    }
    
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

//Automated Market Maker, built for education purposes only.
contract AMM {

    //Tracks pool size for Eth, Dai, and LP
    uint public eth_count = 0;
    uint public dai_count = 0;
    uint public pool_size = 1;

    mapping(address => uint) balances;
    address payable owner;

    //Modifier that requires that the owner of the contract is the caller
    //      (Useless for now since it is used only once)
    modifier onlyOwner(address payable addr) {
        require(addr == owner, "Only the owner may perform this function!");
        _;
    }

    event Log(uint _n);             //General Log event for low-level debugging
    event EthRefund(uint ETH);      //Replacement for sending Eth to the sender
    event DaiRefund(uint DAI);      //Replacement for sending Dai to the sender

    constructor() {
        //Set the owner, and pad the pool size a bit
        owner = payable(msg.sender);
        eth_count = 1;
        dai_count = 1;
    }

    //Provide tokens to the pool
    function provide(uint _eth, uint _dai) public {
        //Require that value is attached, and that the ratio is in congruence with pool ratio
        require(_eth > 0, "Ether amount cannot be zero!");
        require((_eth / _dai) == (eth_count / dai_count), "Must have equals amounts/values of provided assets!");

        //Compute the amount of lp tokens to award the provider
        uint lp_val = (eth_count / pool_size) * _eth;
        emit Log(lp_val);

        //Update the balance of the provider, and update the pool size
        balances[msg.sender] += lp_val;
        pool_size += lp_val;
        //Make the deposit
        eth_count += _eth;
        dai_count += _dai;
    }

    function swapEthForDai(uint _eth) external {
        //Make sure the value is not zero
        require(_eth > 0, "Ether amount attached must be more than zero!");

        //Compute the number of Dai that the given Eth is worth
        uint dc = dai_count;
        uint dai_val = ((dc * _eth) / eth_count);
        require(dai_val < dc, "This pool is not ready for a trade of that size!");

        //Update the balances
        dai_count -= dai_val;
        eth_count += _eth;

        //Give sender the Dai
        emit DaiRefund(dai_val);
    }

    function swapDaiForEth(uint _dai) external {
        //Make sure the value is not zero
        require(_dai > 0, "Dai amount attached must be more than zero!");

        //Compute the number of Eth that the given Dai is worth
        uint ec = eth_count;
        uint eth_val = ((ec * _dai) / dai_count);
        require(eth_val < ec, "This pool is not ready for a trade of that size!");

        //Update the balances
        eth_count -= eth_val;
        dai_count += _dai;

        //Give sender the Eth
        emit EthRefund(eth_val);
    }

    function getLpBal() external view returns(uint) {
        //Return the current LP Token holdings of the requester
        return balances[msg.sender];
    }

    function currentEthPerDai() external view returns(uint) {
        //Returns the ratio of Eth to Dai in the pool
        return eth_count / dai_count;
    }

    function currentDaiPerEth() external view returns(uint) {
        //Returns the ratio of Dai to eth in the pool
        return dai_count / eth_count;
    }

    function rugPull() public onlyOwner(payable(msg.sender)) {
        //Drain all funds to the owner
        eth_count = 0;
        dai_count = 0;
    }

}

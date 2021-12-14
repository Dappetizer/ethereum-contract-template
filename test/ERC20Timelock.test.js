const { BN, constants, expectEvent, expectRevert, balance } = require("@openzeppelin/test-helpers");
const { assertion } = require("@openzeppelin/test-helpers/src/expectRevert");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const ERC20TestContract = artifacts.require("ERC20Test");
const ERC20TimelockContract = artifacts.require("ERC20Timelock");

contract("ERC20Timelock Unit Tests", async accounts => {
    const [deployer, userA, userB, userC] = accounts;
    const tokenName = "LOCK Tokens";
    const tokenSymbol = "LOCK";
    const lockAmount = 100;
    const lockTime = 86400; //1 day in seconds
    const beneficiaryAddress = userB;
    let tokenAddress = "";
    let lockAddress = "";

    advanceTime = (time) => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [time],
            id: new Date().getTime()
          }, (err, result) => {
            if (err) { return reject(err) }
            return resolve(result)
          })
        })
    }

    advanceBlock = () => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: new Date().getTime()
          }, (err, result) => {
            if (err) { return reject(err) }
            const newBlockHash = web3.eth.getBlock('latest').hash
      
            return resolve(newBlockHash)
          })
        })
    }

    before(async () => {
        //initialize contract array
        this.contracts = [];

        //deploy erc20 token contract
        this.contracts[0] = await ERC20TestContract.new(tokenName, tokenSymbol, {from: deployer});
        tokenAddress = this.contracts[0].address;

        //mint tokens
        const t1 = await this.contracts[0].mint(userA, lockAmount);
    });

    it("Can deploy contract", async () => {
        //get current time
        let blockNum = await web3.eth.getBlockNumber();
        let now = await web3.eth.getBlock(blockNum);

        //deploy contract
        this.contracts[1] = await ERC20TimelockContract.new(tokenAddress, beneficiaryAddress, now.timestamp + lockTime);
        lockAddress = this.contracts[1].address;
    });

    it("Can receive tokens", async () => {
        //send tokens to lock contract
        const t1 = await this.contracts[0].transfer(lockAddress, lockAmount, {from: userA});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: userA,
            to: lockAddress,
            value: lockAmount.toString()
        });

        //query post state
        const q1 = await this.contracts[0].balanceOf(lockAddress);
        const q2 = await this.contracts[0].balanceOf(beneficiaryAddress);

        //check post state
        assert.equal(q1.toNumber(), lockAmount);
        assert.equal(q2.toNumber(), 0);
    });

    it("Can reject invalid release", async () => {
        //attempt to reelease before release time
        await expectRevert(
            this.contracts[1].release({from: userA}),
            "current time is before release time",
        );
    });

    it("Can release tokens", async () => {
        //move block time forward (in seconds) to after release time
        advanceTime(lockTime + 1);

        //send trx
        const t1 = await this.contracts[1].release({from: userA});

        //query post state
        const q1 = await this.contracts[0].balanceOf(lockAddress);
        const q2 = await this.contracts[0].balanceOf(beneficiaryAddress);

        //check post state
        assert.equal(q1.toNumber(), 0);
        assert.equal(q2.toNumber(), lockAmount);
    });

});
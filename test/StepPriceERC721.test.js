const { BN, constants, expectEvent, expectRevert, balance } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const StepPriceERC721 = artifacts.require("StepPriceERC721");

contract("StepPriceERC721 Contract Tests", async accounts => {
    const [deployer, userA, userB, userC] = accounts;
    const tokenName = "Step Tokens";
    const tokenSymbol = "STEP";
    const baseURI = "https://some.public.api/endpoint/";
    const maxSupply = 100;
    
    let stepPrice = `${1*1e18}`; //1 ETH
    let freeMints = 1;
    let stride = 5;

    before(async () => {
        //initialize contract array
        this.contracts = [];
    });

    it("Can deploy contract", async () => {
        //deploy contract
        this.contracts[0] = await StepPriceERC721.new(tokenName, tokenSymbol, maxSupply, {from: deployer});
    });

    it("Can get max supply", async () => {
        //query contract
        const q1 = await this.contracts[0].maxSupply();

        //check query
        assert.equal(q1.toNumber(), maxSupply);
    });

    it("Can get paused state (Pausable)", async () => {
        //query contract
        const q1 = await this.contracts[0].paused();

        //check query
        assert.equal(q1, false);
    });

    it("Can get contract owner (Ownable)", async () => {
        //query contract
        const q1 = await this.contracts[0].owner();

        //check query
        assert.equal(q1, deployer);
    });

    it("Can get token name (IERC721Metadata)", async () => {
        //query contract
        const q1 = await this.contracts[0].name();
        
        //check query
        assert.equal(q1, tokenName);
    });

    it("Can get token symbol (IERC721Metadata)", async () => {
        //query contract
        const q1 = await this.contracts[0].symbol();

        //check query
        assert.equal(q1, tokenSymbol);
    });

    it("Can set and get stride", async () => {
        //send setStride transaction
        const t1 = await this.contracts[0].setStride(stride, {from: deployer});

        //query contract
        const q1 = await this.contracts[0].stride();

        //check query
        assert.equal(q1, stride);
    });

    it("Can set and get step price", async () => {
        //send setStepPrice transaction
        const t1 = await this.contracts[0].setStepPrice(stepPrice, {from: deployer});

        //query contract
        const q1 = await this.contracts[0].stepPrice();

        //check query
        assert.equal(q1, stepPrice);
    });

    it("Can set and get free mint count", async () => {
        //send mint transaction
        const t1 = await this.contracts[0].setFreeMints(freeMints, {from: deployer});

        //query contract
        const q1 = await this.contracts[0].freeMints();

        //check query
        assert.equal(q1, freeMints);
    });

    it("Can get steps", async () => {
        //query contract
        const q1 = await this.contracts[0].steps();

        //check query
        assert.equal(q1, 1);
    });

    it("Can get price", async () => {
        //query contract
        const q1 = await this.contracts[0].getPrice();

        //check query
        assert.equal(q1.toString(), `${1*1e18}`);
    });

    it("Can mint free token", async () => {
        //send mint transaction
        const t1 = await this.contracts[0].mint({from: userA});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: userA,
            tokenId: "0"
        });

        //query post state
        const q1 = await this.contracts[0].mintCount();
    });

    it("Can mint paid token", async () => {
        //query pre state
        const ownerTracker = await balance.tracker(deployer, 'wei');
        const buyerTracker = await balance.tracker(userA, 'wei');
        const price = await this.contracts[0].getPrice();

        //get initial balance
        const ownerPreBal = await ownerTracker.get();
        const buyerPreBal = await buyerTracker.get();

        //send mint transaction
        const t1 = await this.contracts[0].mint({from: userA, value: price});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: userA,
            tokenId: "1"
        });

        //query post state
        const q1 = await this.contracts[0].mintCount();
        // const ownerDelta = await ownerTracker.delta();
        // const { delta, fees } = await buyerTracker.deltaWithFees();

        //check queries
        assert.equal(q1.toNumber(), 2);
        // assert.equal(ownerDelta, price);
        // assert.equal(delta, basePrice + fees);
    });

});
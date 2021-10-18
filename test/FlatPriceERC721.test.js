const { BN, constants, expectEvent, expectRevert, balance } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const FlatPriceERC721 = artifacts.require("FlatPriceERC721");

contract("FlatPriceERC721 Contract Tests", async accounts => {
    const [deployer, userA, userB, userC] = accounts;
    const tokenName = "Flat Tokens";
    const tokenSymbol = "FLAT";
    const baseURI = "https://some.public.api/endpoint/";
    const maxSupply = 10;

    let basePrice = `${1*1e18}`; //1 ETH
    let freeMints = 1;

    before(async () => {
        //initialize contract array
        this.contracts = [];
    });

    it("Can deploy contract", async () => {
        //deploy contract
        this.contracts[0] = await FlatPriceERC721.new(tokenName, tokenSymbol, maxSupply, {from: deployer});
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

    it("Can set and get free mint count", async () => {
        //send mint transaction
        const t1 = await this.contracts[0].setFreeMints(freeMints, {from: deployer});

        //query contract
        const q1 = await this.contracts[0].freeMints();

        //check query
        assert.equal(q1, freeMints);
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

        //check post state
        assert.equal(q1.toNumber(), 1);
    });

    it("Can mint token", async () => {
        //query pre state
        const ownerTracker = await balance.tracker(deployer, 'wei');
        const buyerTracker = await balance.tracker(userA, 'wei');

        //get initial balance
        const ownerPreBal = await ownerTracker.get();
        const buyerPreBal = await buyerTracker.get();

        //send mint transaction
        const t1 = await this.contracts[0].mint({from: userA, value: basePrice});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: userA,
            tokenId: "1"
        });

        //query post state
        const q1 = await this.contracts[0].mintCount();
        const ownerDelta = await ownerTracker.delta();
        // const { delta, fees } = await buyerTracker.deltaWithFees();

        //check queries
        assert.equal(q1.toNumber(), 2);
        assert.equal(ownerDelta, basePrice);
        // assert.equal(delta, basePrice + fees);
    });

    it("Can reject invalid minting", async () => {
        //attempt to mint with insufficient funds
        await expectRevert(
            this.contracts[0].mint({from: userA, value: `${0.1*1e18}`}),
            "Must send exact value to mint",
        );

        //attempt to mint with overpaying funds
        await expectRevert(
            this.contracts[0].mint({from: userA, value: `${1.1*1e18}`}),
            "Must send exact value to mint",
        );

        //attempt to mint existing token
        // await expectRevert(
        //     this.contracts[0].mint(userA, 0, {from: deployer, value: basePrice}),
        //     "ERC721: token already minted",
        // );

        //attempt to mint to zero address
        // await expectRevert(
        //     this.contracts[0].mint(constants.ZERO_ADDRESS, 1, {from: deployer, value: basePrice}),
        //     "ERC721: mint to the zero address",
        // );
    });

    it("Can get balance of address (IERC721)", async () => {
        //query contract
        const q1 = await this.contracts[0].balanceOf(userA);

        //check query
        assert.equal(q1.toNumber(), 2);
    });

    it("Can get owner of token id (IERC721)", async () => {
        //query contract
        const q1 = await this.contracts[0].ownerOf(0);

        //check query
        assert.equal(q1, userA);
    });

    it("Can set base URI", async () => {
        //send setBaseURI transaction
        const t1 = await this.contracts[0].setBaseURI(baseURI, {from: deployer});

        //query new base URI
        const q1 = await this.contracts[0].baseURI();

        //check query
        assert.equal(q1, baseURI);
    });

    it("Can query token URI (IERC721Metadata)", async () => {
        //query contract
        const q1 = await this.contracts[0].tokenURI(0);

        //check query
        assert.equal(q1, baseURI + "0");
    });

    it("Can transfer token (IERC721)", async () => {
        //send transferFrom transaction
        const t1 = await this.contracts[0].transferFrom(userA, userB, 0, {from: userA});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: userA,
            to: userB,
            tokenId: "0"
        });

        //query state
        const q1 = await this.contracts[0].balanceOf(userA);
        const q2 = await this.contracts[0].balanceOf(userB);
        const q3 = await this.contracts[0].ownerOf(0);
        const q4 = await this.contracts[0].getApproved(0);

        //check queries
        assert.equal(q1.toNumber(), 1);
        assert.equal(q2.toNumber(), 1);
        assert.equal(q3, userB);
        assert.equal(q4, constants.ZERO_ADDRESS);
    });

    it("Can approve an address (IERC721)", async () => {
        //send approve transaction
        const t1 = await this.contracts[0].approve(userA, 0, {from: userB});

        //check event emitted
        expectEvent(t1, 'Approval', {
            owner: userB,
            approved: userA,
            tokenId: "0"
        });

        //query state
        const q1 = await this.contracts[0].getApproved(0);

        //check queries
        assert.equal(q1, userA);
    });

    it("Can transfer from address as approved user (IERC721)", async () => {
        //send transferFrom transaction
        //transfer from user b to user c as user a
        const t1 = await this.contracts[0].transferFrom(userB, userC, 0, {from: userA});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: userB,
            to: userC,
            tokenId: "0"
        });

        //query state
        const q1 = await this.contracts[0].balanceOf(userA);
        const q2 = await this.contracts[0].balanceOf(userB);
        const q3 = await this.contracts[0].balanceOf(userC);
        const q4 = await this.contracts[0].ownerOf(0);
        const q5 = await this.contracts[0].getApproved(0);

        //check queries
        assert.equal(q1.toNumber(), 1);
        assert.equal(q2.toNumber(), 0);
        assert.equal(q3.toNumber(), 1);
        assert.equal(q4, userC);
        assert.equal(q5, constants.ZERO_ADDRESS);
    });

    it("Can set approval for all token ids of user (IERC721)", async () => {
        //send setApprovalForAll transaction
        const t1 = await this.contracts[0].setApprovalForAll(userA, true, {from: userC});

        //check event emitted
        expectEvent(t1, 'ApprovalForAll', {
            owner: userC,
            operator: userA,
            approved: true
        });

        //query state
        const q1 = await this.contracts[0].isApprovedForAll(userC, userA);

        //check queries
        assert.equal(q1, true);
    });

    it("Can transfer from address as approved operator (IERC721)", async () => {
        //send transferFrom transaction
        //transfer from user c to user b as user a
        const t1 = await this.contracts[0].transferFrom(userC, userB, 0, {from: userA});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: userC,
            to: userB,
            tokenId: "0"
        });

        //query state
        const q1 = await this.contracts[0].balanceOf(userA);
        const q2 = await this.contracts[0].balanceOf(userB);
        const q3 = await this.contracts[0].balanceOf(userC);
        const q4 = await this.contracts[0].ownerOf(0);
        const q5 = await this.contracts[0].getApproved(0);

        //check queries
        assert.equal(q1.toNumber(), 1);
        assert.equal(q2.toNumber(), 1);
        assert.equal(q3.toNumber(), 0);
        assert.equal(q4, userB);
        assert.equal(q5, constants.ZERO_ADDRESS);
    });

    it("Can reject invalid pause (Pausable)", async () => {
        //attempt to pause not as owner
        await expectRevert(
            this.contracts[0].togglePaused({from: userA}),
            "Ownable: caller is not the owner",
        );
    });

    it("Can pause contract (Pausable)", async () => {
        //send togglePause transaction
        const t1 = await this.contracts[0].togglePaused({from: deployer});

        //check event emitted
        expectEvent(t1, 'Paused', {
            account: deployer
        });

        //query state
        const q1 = await this.contracts[0].paused();

        //check queries
        assert.equal(q1, true);
    });

    it("Can reject invalid transactions while paused (Pausable)", async () => {
        //attempt to mint while paused
        await expectRevert(
            this.contracts[0].mint({from: userA, value: `${1.1*1e18}`}),
            "Pausable: paused",
        );

        // let hexData = await web3.utils.utf8ToHex("testing...");
        // let bytesData = await web3.utils.hexToBytes(userA);

        //attempt to mint while paused
        // await expectRevert(
        //     this.contracts[0].mint(bytesData, {from: userA, value: `${1.1*1e18}`}),
        //     "Pausable: paused",
        // );
    });

    it("Can unpause contract (Pausable)", async () => {
        //send togglePause transaction
        const t1 = await this.contracts[0].togglePaused({from: deployer});

        //check event emitted
        expectEvent(t1, 'Unpaused', {
            account: deployer
        });

        //query state
        const q1 = await this.contracts[0].paused();

        //check queries
        assert.equal(q1, false);
    });

    it("Can burn token (ERC721Burnable)", async () => {
        //send burn transaction
        const t1 = await this.contracts[0].burn(0, {from: userB});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: userB,
            to: constants.ZERO_ADDRESS,
            tokenId: "0"
        });

        //query state
        const q1 = await this.contracts[0].balanceOf(userA);
        const q2 = await this.contracts[0].balanceOf(userB);
        const q3 = await this.contracts[0].balanceOf(userC);
        const q4 = await this.contracts[0].burnCount();

        //check queries
        assert.equal(q1.toNumber(), 1);
        assert.equal(q2.toNumber(), 0);
        assert.equal(q3.toNumber(), 0);
        assert.equal(q4.toNumber(), 1);
    });

});
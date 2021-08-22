const { BN, constants, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const FreakyFrogFriends = artifacts.require("TemplateERC721");

contract("TemplateERC721 Contract Tests", async accounts => {
    const [deployer, userA, userB, userC] = accounts;
    const tokenName = "Test Tokens";
    const tokenSymbol = "TEST";
    const baseURI = "https://some.public.api/endpoint";
    
    let nextTokenId = 0;
    let basePrice = 1000000000000000000; //1 ETH

    before(async () => {
        //initialize contract array
        this.contracts = [];
    });

    it("Can deploy contract", async () => {
        //deploy contract
        this.contracts[0] = await FreakyFrogFriends.new({from: deployer});
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

    it("Can mint a new token", async () => {
        //send mint transaction
        const t1 = await this.contracts[0].mint(userA, nextTokenId, {from: deployer, value: basePrice});

        //check event emitted
        expectEvent(t1, 'Transfer', {
            from: constants.ZERO_ADDRESS,
            to: userA,
            tokenId: "0"
        });

        //query contract
        const q1 = await this.contracts[0].mintCount();

        //check queries
        assert.equal(q1.toNumber(), 1);

        nextTokenId += 1;
    });

    it("Can reject invalid minting", async () => {
        //attempt to mint with insufficient funds
        await expectRevert(
            this.contracts[0].mint(userA, 0, {from: deployer, value: 1000}),
            "insufficient value to mint",
        );

        //attempt to mint existing token
        await expectRevert(
            this.contracts[0].mint(userA, 0, {from: deployer, value: basePrice}),
            "ERC721: token already minted",
        );

        //attempt to mint to zero address
        await expectRevert(
            this.contracts[0].mint(constants.ZERO_ADDRESS, 1, {from: deployer, value: basePrice}),
            "ERC721: mint to the zero address",
        );
    });

    it("Can get balance of address (IERC721)", async () => {
        //query contract
        const q1 = await this.contracts[0].balanceOf(userA);

        //check query
        assert.equal(q1.toNumber(), 1);
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
        assert.equal(q1.toNumber(), 0);
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
        assert.equal(q1.toNumber(), 0);
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
        assert.equal(q1.toNumber(), 0);
        assert.equal(q2.toNumber(), 1);
        assert.equal(q3.toNumber(), 0);
        assert.equal(q4, userB);
        assert.equal(q5, constants.ZERO_ADDRESS);
    });

    

});
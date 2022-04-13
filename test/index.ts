import { getContractFactory } from "@nomiclabs/hardhat-ethers/types";
import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { AbiCoder, Interface, parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {  } from "../config";

describe("Token contract", function () {

  let market;
  let erc20;
  let erc20Contract: Contract;
  let marketContract: Contract;

  let ERC20owner: Signer;
  let ERC20user: Signer;
  let marketOwner: Signer;
  let marketUser1: Signer;
  let marketUser2: Signer;
  let marketUser3: Signer;
  let marketUser4: Signer;
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";




  beforeEach(async function () {



    erc20 = await ethers.getContractFactory("Token");
    [ERC20owner, ERC20user] = await ethers.getSigners();
    erc20Contract = await erc20.deploy("Test", "tst");

    market = await ethers.getContractFactory("Market");
    [marketOwner, marketUser1, marketUser2, marketUser3, marketUser4] = await ethers.getSigners();
    marketContract = await market.deploy(erc20Contract.address, 3);


    erc20Contract.connect(ERC20owner).updateAdmin(marketContract.address);



  });

  describe("main flow", function () {

    it("registration -> start sale phase -> buy tokens -> starttrade phase -> addOrder -> removeOrder -> addOrder -> redeemOrder ", async function () {
      console.log(await marketUser1.getBalance())


      await marketContract.connect(marketUser2).registration(await marketUser1.getAddress())
      await expect(marketContract.connect(marketUser2).registration(await marketUser3.getAddress())).to.be.revertedWith("already registered")
      console.log(await marketUser2.getBalance())

      await marketContract.connect(marketUser3).registration(await marketUser2.getAddress())
      await marketContract.connect(marketOwner).startSalePhase()
      expect(await erc20Contract.connect(ERC20owner).balanceOf(marketContract.address)).to.equal(100000)
      await marketContract.connect(marketUser3).buyTokens({value : parseEther("0.1")})
      expect(await erc20Contract.connect(ERC20owner).balanceOf(marketContract.address)).to.equal(90000)
      expect(await erc20Contract.connect(ERC20owner).balanceOf(await marketUser3.getAddress())).to.equal(10000)
      await expect(marketContract.connect(marketOwner).startTradePhase()).to.be.revertedWith("previous phase is still active")

      await expect(marketContract.connect(marketOwner).startSalePhase()).to.be.revertedWith("previous phase is still active")
      await expect(marketContract.connect(marketUser3).addOrder(50, parseEther("1"))).to.be.revertedWith("Current phase is not Trade")
      await expect(marketContract.connect(marketUser3).removeOrder(1)).to.be.revertedWith("Current phase is not Trade")
      await expect(marketContract.connect(marketUser3).redeemOrder(1,{value : parseEther("0.0001")})).to.be.revertedWith("Current phase is not Trade")





      await marketContract.connect(marketUser3).buyTokens({value : parseEther("0.9")})

      await expect(marketContract.connect(marketUser3).buyTokens({value : parseEther("0.1")})).to.be.revertedWith("Not enough tkn supply")
      await expect(marketContract.connect(marketOwner).startSalePhase()).to.be.revertedWith("Next phase is not sale")
      await marketContract.connect(marketOwner).startTradePhase()
      await erc20Contract.connect(marketUser3).approve(marketContract.address, 50)
      await marketContract.connect(marketUser3).addOrder(50, parseEther("1"))
      await expect(marketContract.connect(marketUser3).removeOrder(0)).to.be.revertedWith("Id is not valid")
      await expect(marketContract.connect(marketUser3).removeOrder(25)).to.be.revertedWith("Id is not valid")
      await expect(marketContract.connect(marketUser2).removeOrder(1)).to.be.revertedWith("Not an owner")
      await marketContract.connect(marketUser3).removeOrder(1)
      await erc20Contract.connect(marketUser3).approve(marketContract.address, 50)
      await marketContract.connect(marketUser3).addOrder(50, parseEther("1"))
      await expect(marketContract.connect(marketUser2).redeemOrder(4,{value : parseEther("50")})).to.be.revertedWith("There is no order by given Id")
      await expect(marketContract.connect(marketUser2).redeemOrder(2,{value : parseEther("55")})).to.be.revertedWith("Not enough supply to buy")
      await marketContract.connect(marketUser2).redeemOrder(2,{value : parseEther("45")})
      expect(await erc20Contract.connect(ERC20owner).balanceOf(await marketUser2.getAddress())).to.equal(45)
      await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);

      await marketContract.connect(marketUser3).startSalePhase()
      await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);
      await marketContract.connect(marketUser3).startTradePhase()
      await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);
      await marketContract.connect(marketUser3).startSalePhase()
      await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);
      await expect(marketContract.connect(marketUser3).startTradePhase()).to.be.revertedWith("Next phase is not trade")
      













      




      //expect(await marketUser1.getBalance()).to.equal(parseEther("1.0000000000000000000300"))
      //console.log(await marketUser2.getBalance()) 
      //expect(await marketContract.getBalance()).to.equal(parseEther("0.9999999999999992"))
      
      //console.log(await )






    });
    
  });

 

});
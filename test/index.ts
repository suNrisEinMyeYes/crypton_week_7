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
      await marketContract.connect(await marketUser2.getAddress()).registration(await marketUser1.getAddress())
      console.log("1");
      await expect(marketContract.connect(await marketUser2.getAddress()).registration(await marketUser3.getAddress())).to.be.revertedWith("already registered")
      console.log("1");
      await marketContract.connect(await marketUser3.getAddress()).registration(await marketUser2.getAddress())



    });
    
  });

 

});
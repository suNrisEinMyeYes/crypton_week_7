import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import { addrMarket } from "../config"

dotenv.config();

task("redeemOrder", "buy tkns through p2p")
.addParam("amount", "amount of eth that u want to spend")
.addParam("id", "price of one tkn in eth")
.setAction(async (taskArgs, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.API_URL) 
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : [], provider)

  const myContract = await hre.ethers.getContractAt('Market', addrMarket, signer)

  const out = await myContract.redeemOerder(taskArgs.id, { value : taskArgs.amount});
  console.log(out)
});
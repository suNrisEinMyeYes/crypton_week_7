import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import { addrMarket } from "../config"
import { parseEther } from "ethers/lib/utils";

dotenv.config();

task("buyTkn", "Buy tkns through sale phase")
.addParam("amount", "amount of eth that u want to spend")
.setAction(async (taskArgs, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.API_URL) 
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : [], provider)

  const myContract = await hre.ethers.getContractAt('Market', addrMarket, signer)

  const out = await myContract.buyTokens({ value : parseEther(taskArgs.amount)});
  console.log(out)
});
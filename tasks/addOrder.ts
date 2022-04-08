import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import { addrMarket } from "../config"

dotenv.config();

task("addOrder", "Add order")
.addParam("amount", "amount of tkns")
.addParam("price", "price of one tkn in eth")
.setAction(async (taskArgs, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.API_URL) 
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : [], provider)

  const myContract = await hre.ethers.getContractAt('Market', addrMarket, signer)

  const out = await myContract.addOrder(taskArgs.amount, taskArgs.price);
  console.log(out)
});
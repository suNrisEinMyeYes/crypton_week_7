import { task } from "hardhat/config";
import * as dotenv from "dotenv";
import { addrMarket } from "../config"

dotenv.config();

task("register", "register with refer's address")
.addParam("refer", "your refer")
.setAction(async (taskArgs, hre) => {
  const provider = new hre.ethers.providers.JsonRpcProvider(process.env.API_URL) 
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : [], provider)

  const myContract = await hre.ethers.getContractAt('Market', addrMarket, signer)

  const out = await myContract.registration(taskArgs.refer);
  console.log(out)
});
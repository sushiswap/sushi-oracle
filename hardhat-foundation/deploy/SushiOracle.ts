import { SushiOracle } from "../typechain";

export default async ({ getNamedAccounts, deployments } : { getNamedAccounts:any, deployments:any}) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log(deployer)
  const { address }: SushiOracle = await deploy("SushiOracle", {
    from: deployer,
  });

  console.log(`SushiOracle deployed to ${address}`);
};
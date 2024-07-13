//@ts-ignore

import { network, deployments as hardhatDeployments, ethers } from "hardhat";

interface NamedAccounts {
  deployer: string;
}

module.exports = async function ({
  getNamedAccounts,
  deployments,
}: {
  getNamedAccounts: () => Promise<NamedAccounts>;
  deployments: typeof hardhatDeployments;
}) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [] as any[];
  const RiskGame = await deploy("RiskGame", {
    from: deployer,
    args: args,
    log: true,
  });
};

module.exports.tags = ["all", "RiskGame"];

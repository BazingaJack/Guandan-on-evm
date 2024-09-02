import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployModule = buildModule("DeployModule", (m) => {

  const guandan = m.contract("Guandan", [], {

  });

  return { guandan };
});

export default DeployModule;

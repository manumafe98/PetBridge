import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PetBridge", (module) => {
  const petBridge = module.contract("PetBridge");

  return { petBridge };
});

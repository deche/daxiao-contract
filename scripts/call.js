const daxiaoAddr = "0x05685e7D55b5A551aE608d7db594e4cA957714C5";

async function main() {
 const [owner] = await ethers.getSigners();

  const daxiao = await ethers.getContractAt("Daxiao", daxiaoAddr);

  const result = await daxiao.randomResult();

  console.log(result);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

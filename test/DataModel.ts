import { Contract } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("DataModel", () => {
  let contract: Contract;

  beforeEach(async () => {
    const DataModel = await ethers.getContractFactory("DataModel");
    contract = await DataModel.deploy();
  });

  it("Should be able to create a model", async () => {
    const creator = (await ethers.getSigners())[0];

    const id = ethers.utils.formatBytes32String("1234567890");
    const name = ethers.utils.formatBytes32String("Example Model");
    const description = ethers.utils.formatBytes32String("This is an example model");
    const url = ethers.utils.formatBytes32String("https://example.com");

    await contract.connect(creator).createModel(id, name, description, url);

    const model = await contract.getModel(id);
    expect(model.id).to.equal(id);
    expect(model.creator).to.equal(creator.address);
    expect(model.name).to.equal(name);
    expect(model.description).to.equal(description);
    expect(model.url).to.equal(url);
    expect(model.versions.length).to.equal(1);
    expect(model.versions[0]).to.equal("initial");
  });

  it("Should be able to create a model version", async () => {
    const id = ethers.utils.formatBytes32String("1234567890");
    const name = ethers.utils.formatBytes32String("Example Model");
    const description = ethers.utils.formatBytes32String("This is an example model");
    const url = ethers.utils.formatBytes32String("https://example.com");
    const version = ethers.utils.formatBytes32String("1.0.0");
    const uri = ethers.utils.formatBytes32String("https://example.com/1.0.0");

    await contract.createModel(id, name, description, url);
    await contract.createModelVersion(id, version, uri);

    const model = await contract.getModel(id);
    expect(model.versions.length).to.equal(2);
    expect(model.versions[1]).to.equal(version);

    const modelVersion = await contract.getModelVersion(id, version);
    expect(modelVersion.version).to.equal(version);
    expect(modelVersion.uri).to.equal(uri);
  });
});

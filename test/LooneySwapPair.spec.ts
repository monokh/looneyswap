import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Token } from '../typechain/Token'
import { LooneySwapPair } from '../typechain/LooneySwapPair'

describe("LooneySwapPair", function() {
  let token0: Token
  let token1: Token

  beforeEach(async () => {
    const Token = await ethers.getContractFactory('Token')
    token0 = await Token.deploy('Bitcoin', 'BTC', 1000000000) as Token
    token1 = await Token.deploy('USDC', 'USDC', 1000000000000000) as Token
    await token0.deployed()
    await token1.deployed()
  })

  it("Should return initialized pair", async function() {
    const LooneySwapPair = await ethers.getContractFactory("LooneySwapPair")
    const pair: LooneySwapPair = await LooneySwapPair.deploy(token0.address, token1.address) as LooneySwapPair
    await pair.deployed()

    expect(await pair.token0()).to.equal(token0.address)
    expect(await pair.token1()).to.equal(token1.address)
    expect(await pair.reserve0()).to.equal(0)
    expect(await pair.reserve1()).to.equal(0)
  })

  it("Should add liquidity to reserves", async function() {
    const LooneySwapPair = await ethers.getContractFactory("LooneySwapPair")
    const pair: LooneySwapPair = await LooneySwapPair.deploy(token0.address, token1.address) as LooneySwapPair
    await pair.deployed()

    await (await token0.approve(pair.address, 1)).wait()
    await (await token1.approve(pair.address, 50000)).wait()
    await (await pair.add(1, 50000)).wait()

    expect(await pair.reserve0()).to.equal(1)
    expect(await pair.reserve1()).to.equal(50000)
  })
})

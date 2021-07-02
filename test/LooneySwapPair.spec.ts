import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Token } from '../typechain/Token'
import { LooneySwapPair } from '../typechain/LooneySwapPair'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

describe("LooneySwapPair", function() {
  let token0: Token
  let token1: Token
  let pair: LooneySwapPair
  let accounts: SignerWithAddress[]

  beforeEach(async () => {
    accounts = await ethers.getSigners()

    const Token = await ethers.getContractFactory('Token')
    token0 = await Token.deploy('Bitcoin', 'BTC', 100000000000) as Token
    token1 = await Token.deploy('USDC', 'USDC', 1000000000000000) as Token
    await token0.deployed()
    await token1.deployed()

    const [, account1, account2, account3] = accounts

    for (const account of [account1, account2, account3]) {
      await (await token0.transfer(account.address, 200)).wait()
      await (await token1.transfer(account.address, 10000000)).wait()
    }

    const LooneySwapPair = await ethers.getContractFactory("LooneySwapPair")
    pair = await LooneySwapPair.deploy(token0.address, token1.address) as LooneySwapPair
    await pair.deployed()
  })

  it("Should return initialized pair", async function() {
    expect(await pair.token0()).to.equal(token0.address)
    expect(await pair.token1()).to.equal(token1.address)
    expect(await pair.reserve0()).to.equal(0)
    expect(await pair.reserve1()).to.equal(0)
  })

  it("Should add initial liquidity to reserves", async function() {
    await (await token0.connect(accounts[1]).approve(pair.address, 1)).wait()
    await (await token1.connect(accounts[1]).approve(pair.address, 50000)).wait()
    await (await pair.connect(accounts[1]).add(1, 50000)).wait()

    expect(await pair.reserve0()).to.equal(1)
    expect(await pair.reserve1()).to.equal(50000)
    expect(await pair.totalSupply()).to.equal(100000) // Initial Supply
    expect(await pair.balanceOf(accounts[1].address)).to.equal(100000)
  })

  it("Should mint correct amount", async function() {
    await (await token0.connect(accounts[1]).approve(pair.address, 1)).wait()
    await (await token1.connect(accounts[1]).approve(pair.address, 50000)).wait()
    await (await pair.connect(accounts[1]).add(1, 50000)).wait()

    await (await token0.connect(accounts[2]).approve(pair.address, 3)).wait()
    await (await token1.connect(accounts[2]).approve(pair.address, 150000)).wait()
    await (await pair.connect(accounts[2]).add(3, 150000)).wait()

    expect(await pair.reserve0()).to.equal(4)
    expect(await pair.reserve1()).to.equal(200000)
    expect(await pair.totalSupply()).to.equal(400000)

    expect(await pair.balanceOf(accounts[1].address)).to.equal(100000)
    expect(await pair.balanceOf(accounts[2].address)).to.equal(300000)
  })

  it("Should burn correct amount", async function() {
    await (await token0.connect(accounts[1]).approve(pair.address, 1)).wait()
    await (await token1.connect(accounts[1]).approve(pair.address, 50000)).wait()
    await (await pair.connect(accounts[1]).add(1, 50000)).wait()

    await (await token0.connect(accounts[2]).approve(pair.address, 3)).wait()
    await (await token1.connect(accounts[2]).approve(pair.address, 150000)).wait()
    await (await pair.connect(accounts[2]).add(3, 150000)).wait()

    const token0BalanceBefore = await token0.balanceOf(accounts[1].address)
    const token1BalanceBefore = await token1.balanceOf(accounts[1].address)

    const lpTokens = await pair.balanceOf(accounts[1].address)
    await (await pair.connect(accounts[1]).remove(lpTokens)).wait()

    expect(await token0.balanceOf(accounts[1].address)).to.equal(token0BalanceBefore.add(1))
    expect(await token1.balanceOf(accounts[1].address)).to.equal(token1BalanceBefore.add(50000))

    expect(await pair.reserve0()).to.equal(3)
    expect(await pair.reserve1()).to.equal(150000)
    expect(await pair.totalSupply()).to.equal(300000)
    expect(await pair.balanceOf(accounts[1].address)).to.equal(0)
  })
})

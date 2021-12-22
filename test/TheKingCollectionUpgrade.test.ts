import { ethers, upgrades } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'

const name = 'TheKingCollection'
const symbol = 'KC'
let timestampBefore = 0
const nftTestAmount = 4
const baseURI = 'ipfs://QmVAjAt3otNNJEkEbkR2suki13BhnWZc4ohxG8BA3CLLQd/'
const _maxSupply = 8888
const maxToMintPerAddress_ = 20
const reserved_ = 388
const _startTimeSale = 0 //Date.now()
const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
const _mintPrice = parseEther((0.06).toString()).toString()
const _revealTime = 60 // 1 munite
describe('TheKingCollection Upgrade', function () {
  const provider = new MockProvider()

  const [wallet, other, user2] = provider.getWallets()
  it('deploys and upgrades', async function () {
    const TheKingCollection = await ethers.getContractFactory('TheKingCollection')
    const signers = await ethers.getSigners()
    const proxy = await upgrades.deployProxy(
      TheKingCollection,
      [baseURI, _startTimeSale, _mintPrice, _maxSupply, _revealTime, reserved_, _wallets, signers[0].address],
      { kind: 'uups' }
    )

    const owner = await proxy.owner()
    // const _mint = await proxy.mint(nftTestAmount, {
    //     value: parseEther((nftTestAmount * +_mintPrice).toString()),
    // })
    // console.log({_mint});
    
    console.log('Owner = ', owner)
    console.log('wallet = ', wallet.address)
    console.log('Owner Balance in V1 = ', (await proxy.mintPrice()).toString())

    const V2 = await ethers.getContractFactory('TheKingCollectionV2', signers[0])

    const proxy2 = await upgrades.upgradeProxy(proxy, V2)

    console.log('Owner Balance in V2 = ', (await proxy2.mintPrice()).toString())
    console.log('New value existing only in V2 before being initialized = ', await proxy2.getWhatever())
    await proxy2.setWhatever('0x1111111111111111111111111111111111111111')
    console.log('New value existing only in V2 after being initialized  = ', await proxy2.getWhatever())
  })
})

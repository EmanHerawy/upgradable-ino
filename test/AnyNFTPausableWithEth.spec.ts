import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ethers, upgrades } from 'hardhat'

import ER721 from '../artifacts/contracts/launchpadProjects/erc721/TheKingCollection.sol/TheKingCollection.json'
import { parseEther } from 'ethers/lib/utils'
chai.use(solidity)
const baseUri = 'http://ipfs.io'
const name = 'The King Vidal Collection'
const symbol = 'KVC'
let timestampBefore = 0
const nftTestAmount = 4
const baseURI = 'ipfs://QmVAjAt3otNNJEkEbkR2suki13BhnWZc4ohxG8BA3CLLQd/'
const _maxSupply = 8888
const maxToMintPerAddress_ = 20
const reserved_ = 388
const _startTimeSale = 0 //Date.now() + 100;
const _wallets = ['0x2819C6d61e4c83bc53dD17D4aa00deDBe35894AA']
const _mintPrice = parseEther((0.06).toString()).toString()
const _revealTime = 60 // 1 munite
describe('AnyNFTPausableWithEth V1', () => {
  const provider = new MockProvider()
  const [wallet, other, user2] = provider.getWallets()
  let proxy: Contract
  let proxy2: Contract
  before(async () => {
    const TheKingCollection = await ethers.getContractFactory('TheKingCollection',wallet.address)
    proxy =  await deployContract(wallet, ER721)
await proxy.initialize(baseURI, _startTimeSale, _mintPrice, _maxSupply, _revealTime, reserved_, _wallets, wallet.address)
    // proxy = await upgrades.deployProxy(
    //   TheKingCollection,
    //   [baseURI, _startTimeSale, _mintPrice, _maxSupply, _revealTime, reserved_, _wallets, wallet.address],
    //   { kind: 'uups' }
    // )


  })

  it('name, symbol,  wallets,mintPrice,maxToMintPerAddress,maxSupply,reserved', async () => {
    const _name = await proxy.name()
    expect(_name).to.eq(name)
    expect(await proxy.symbol()).to.eq(symbol)
    // expect(await token.wallets()).to.eq(_wallets);
    // expect(await token.mintPrice()).to.eq(0.06 * 10 ** 18);
    // expect(await proxy.maxToMintPerAddress()).to.eq(20)
    expect(await proxy.maxSupply()).to.eq(_maxSupply)
    expect(await proxy.reserved()).to.eq(reserved_)
  })

  it('Should not mint if the sale is not started', async () => {
    console.log(nftTestAmount * +_mintPrice, _mintPrice, 'nftTestAmount*  +_mintPrice')
    console.log(
      parseEther((nftTestAmount * +_mintPrice).toString()),
      'parseEther((nftTestAmount*  +_mintPrice).toString())'
    )

    await expect(
      proxy.mint(nftTestAmount, {
        value: parseEther((nftTestAmount * +_mintPrice).toString()),
      })
    ).to.revertedWith('Sale did not start yet')
  })
  it('Non OWner Should not update sale start time', async () => {
    await expect(proxy.connect(other).updateSaleStartTime(Date.now())).to.revertedWith(
      'Ownable: caller is not the owner'
    )
  })
  it(' OWner can update sale start time', async () => {
    const blockNumBefore = await provider.getBlockNumber()
    const blockBefore = await provider.getBlock(blockNumBefore)
    timestampBefore = blockBefore.timestamp
    await proxy.connect(wallet).updateSaleStartTime(timestampBefore + 10)
    await expect(await proxy.startTimeSale()).to.eql(BigNumber.from(timestampBefore + 10))
    await provider.send('evm_increaseTime', [timestampBefore + 100])
    await provider.send('evm_mine', [])
  })
  it('Non OWner Should not call mintreservedNFTs', async () => {
    await expect(proxy.connect(other).mintReservedNFTs(wallet.address, 2)).to.revertedWith(
      'Ownable: caller is not the owner'
    )
  })
  it(' OWner can mint reserved nft mintreservedNFTs', async () => {
    await expect(await proxy.connect(wallet).mintReservedNFTs(user2.address, nftTestAmount)).to.emit(proxy, 'Transfer')

    await expect(await proxy.balanceOf(user2.address)).to.eql(BigNumber.from(nftTestAmount))
    await expect(await proxy.totalReserveSupply()).to.eql(BigNumber.from(nftTestAmount))
  })

  it('Should not mint if the price is less than the minPrice', async () => {
    await expect(proxy.mint(nftTestAmount, { value: parseEther('0.03') })).to.revertedWith('ETH value not correct')
  })
  // it('Should not mint more than 20 nft', async () => {
  //   await expect(proxy.mint(25, { value: parseEther((25 * 0.06).toString()) })).to.revertedWith(
  //     'You requested too many NFTs'
  //   )
  // })
  it('Should  mint', async () => {
    await expect(
      await proxy.connect(other).mint(nftTestAmount, {
        value: (nftTestAmount * +_mintPrice).toString(),
      })
    ).to.emit(proxy, 'Transfer')
    await expect(await proxy.balanceOf(other.address)).to.eql(BigNumber.from(nftTestAmount))
    // const eventFilter = await token.filters.Transfer(null, null);
    // const events = await token.queryFilter(eventFilter);
    // console.log({ events });

    // const tokenId = (events[events.length - 1] as any).args[2].toNumber();
    // const to = (events[events.length - 1] as any).args[1];
    // console.log(other.address);

    // console.log({ tokenId, to });
  })

  it('transferFrom', async () => {
    const NFTs = await proxy.ownerNFTs(other.address)
    await expect(proxy.connect(other).transferFrom(other.address, wallet.address, NFTs[1]))
      .to.emit(proxy, 'Transfer')
      .withArgs(other.address, wallet.address, NFTs[1])
    expect(await proxy.balanceOf(wallet.address)).to.eq(BigNumber.from(1))
    expect(await proxy.balanceOf(other.address)).to.eq(BigNumber.from(nftTestAmount - 1))
  })
  it('transferFrom::fail', async () => {
    await expect(proxy.transferFrom(wallet.address, other.address, 1)).to.be.reverted
  })
  it(' Should not reveal token URI before time', async () => {
    const NFTs = await proxy.ownerNFTs(other.address)

    await expect(proxy.tokenURI(NFTs[1])).to.revertedWith('ERC721UpgradeableURIStorage: URI query for non revealed token')
  })
  it(' Should  reveal token URI after time', async () => {
    const NFTs = await proxy.ownerNFTs(other.address)
    await provider.send('evm_increaseTime', [timestampBefore + 24 * 60 * 60 * 60])
    await provider.send('evm_mine', [])
    await expect(proxy.tokenURI(NFTs[1])).to.not.be.reverted
  })
  it('Non OWner Should not call withdraw', async () => {
    await expect(proxy.connect(other).withdraw()).to.revertedWith('Ownable: caller is not the owner')
  })
  it(' OWner can withdraw', async () => {
    await expect(await proxy.connect(wallet).withdraw()).to.emit(proxy, 'Withdrawn')
    //   .withArgs(_wallets[0], parseEther((4 * 0.06).toString()));
    // await expect(await provider.getBalance(_wallets[0])).to.eql(
    //   parseEther((4 * 0.06).toString())
    // );
    // // await expect(await provider.getBalance(wallet2)).to.eql(
    //   parseEther((4 * 0.06).toString())
    // );
  })

})

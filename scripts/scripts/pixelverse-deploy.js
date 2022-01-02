const { ethers, upgrades } = require('hardhat')
const { parseEther } = require('ethers/lib/utils')

async function main() {
  const baseURI = 'ipfs://QmY1DA4kK2B3B8pyTH5C7Gr8YqKomLKZyH8MY421wtGK9s/'
  const url_404_ = 'https://liteamay.nyc3.digitaloceanspaces.com/2018/09/%D9%87%D8%AE%D8%BA%D8%AE%D9%85.jpg'
  
  const _maxSupply = 2500
  const reserved_ = 100
  const _startTimeSale = 1639461600 //Date.now()/100
  const _wallets = ['0xac701BB1557F6c06070Bc114Ca6Ace4a358D3A84']
  const _mintPrice = parseEther((0.1).toString())
  const _revealTime = 86400 * 7 //2 // 1 day
  const _owner = '0xac701BB1557F6c06070Bc114Ca6Ace4a358D3A84'
  const Pixelverse = await ethers.getContractFactory('Pixelverse')
  const proxy = await upgrades.deployProxy(Pixelverse, [baseURI, url_404_, _startTimeSale, _mintPrice, _maxSupply,  reserved_, _wallets, _owner],
      { kind: 'uups' })
  console.log('UUPS deployed: ', proxy.address)
}

main()

import { ethers } from 'hardhat';
import chai, { expect, assert } from 'chai';
import { Contract, BigNumber } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { solidity } from 'ethereum-waffle';

chai.use(solidity);

describe('YieldFarm Contract', () => {
  let res: any;

  let yieldFarm: Contract;
  let yieldToken: Contract;
  let mockDai: Contract;

  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;

  const daiAmount: BigNumber = ethers.utils.parseEther('25000');

  beforeEach(async () => {
    const YieldFarm = await ethers.getContractFactory('YieldFarm');
    const YieldToken = await ethers.getContractFactory('YieldToken');
    const MockERC20 = await ethers.getContractFactory('MockERC20');

    [owner, alice, bob] = await ethers.getSigners();

    mockDai = await MockERC20.deploy('MockDai', 'mDAI');
    await Promise.all([
      mockDai.mint(owner.address, daiAmount),
      mockDai.mint(alice.address, daiAmount),
      mockDai.mint(bob.address, daiAmount),
    ]);

    yieldToken = await YieldToken.deploy();
    yieldFarm = await YieldFarm.deploy(mockDai.address, yieldToken.address);
  });

  describe('Init', async () => {
    it('Should initialize', async () => {
      expect(yieldToken).to.be.ok;
      expect(yieldToken).to.be.ok;
      expect(mockDai).to.be.ok;
    });
  });

  describe('Stake', async () => {
    it('[require] stake하는 amount는 0보다 커야한다.', async () => {
      let stakeAmount = ethers.utils.parseEther('0');
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);
      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      await expect(
        yieldFarm.connect(alice).stake(stakeAmount)
      ).to.be.revertedWith('You cannot stake zero tokens');
    });

    it('[require] msg.sender는 stake하는 양보다 더 많은 dai를 가지고 있어야 한다.', async () => {
      let stakeAmount = daiAmount.add(ethers.utils.parseEther('10000'));
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);
      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      await expect(
        yieldFarm.connect(alice).stake(stakeAmount)
      ).to.be.revertedWith('You cannot stake zero tokens');
    });

    it('처음 staking을 하면 yieldBalance가 0이어야 한다.', async () => {
      let stakeAmount = ethers.utils.parseEther('100');
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);
      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      expect(await yieldFarm.connect(alice).stake(stakeAmount));
      expect(await yieldFarm.yieldBalance(alice.address)).to.be.eq('0');
    });

    it('staking하면 staking amount만큼 지갑에서 빠져야 한다', async () => {
      let stakeAmount = ethers.utils.parseEther('100');
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);
      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      expect(await yieldFarm.connect(alice).stake(stakeAmount));
      expect(await yieldFarm.yieldBalance(alice.address)).to.be.eq('0');
    });

    it('staking하면 staking amount만큼 지갑에서 빠져야 한다', async () => {});

    it('Sould accept DAI and update mapping', async () => {
      let stakeAmount = ethers.utils.parseEther('100');
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);

      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      expect(await yieldFarm.connect(alice).stake(stakeAmount));
      expect(await yieldFarm.stakingBalance(alice.address)).to.be.ok;
      expect(await yieldFarm.isStaking(alice.address)).to.eq(true);
    });

    it('Sould accept DAI and update mapping', async () => {
      let stakeAmount = ethers.utils.parseEther('100');
      await mockDai.connect(alice).approve(yieldFarm.address, stakeAmount);

      expect(await yieldFarm.isStaking(alice.address)).to.eq(false);
      expect(await yieldFarm.connect(alice).stake(stakeAmount));
      expect(await yieldFarm.stakingBalance(alice.address)).to.be.ok;
      expect(await yieldFarm.isStaking(alice.address)).to.eq(true);
    });
  });
});

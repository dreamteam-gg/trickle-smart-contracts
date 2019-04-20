const { BN, constants, expectEvent, time, shouldFail } = require('openzeppelin-test-helpers');
const moment = require('moment');
const { ZERO_ADDRESS } = constants;

const Trickle = artifacts.require('Trickle');
const ERC20Mock = artifacts.require('ERC20Mock');

require('chai').should();

contract('Trickle', function ([_, sender, recipient, anotherAccount]) {
  const initialSupply = new BN(1000);

  beforeEach(async function () {
    this.token = await ERC20Mock.new(sender, initialSupply);
    this.trickle = await Trickle.new();
  });

  describe('create agreement', function () {
    it('creates agreement', async function () {
        const start = new BN(moment().add('10 days').unix());
        const duration = new BN(60 * 60 * 24 * 30);
        const totalAmount = new BN(500);
        const agreementId = new BN(1);

        await this.token.approve(this.trickle.address, totalAmount, {from: sender});
        const tx = await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
        expectEvent.inLogs(tx.logs, 'AgreementCreated', {
            'agreementId': agreementId,
            'token': this.token.address,
            'recipient': recipient,
            'sender': sender,
            'start': start,
            'duration': duration,
            'totalAmount': totalAmount
        });
    });
  });

  describe('cancel agreement', function () {
    it('cancel agreement', async function () {
        const start = new BN(moment().add('10 days').unix());
        const duration = new BN(60 * 60 * 24 * 30);
        const totalAmount = new BN(500);
        const agreementId = new BN(1);

        await this.token.approve(this.trickle.address, totalAmount, {from: sender});
        await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
        const tx = await this.trickle.cancelAgreement(agreementId, {from: sender});
        const endedAt = await time.latest();

        expectEvent.inLogs(tx.logs, 'AgreementCancelled', {
          'agreementId': agreementId,
          'token': this.token.address,
          'recipient': recipient,
          'sender': sender,
          'start': start,
          'endedAt': endedAt,
          'amountReleased': new BN(0),
          'amountCancelled': totalAmount
        });

        const senderBalance = (await this.token.balanceOf.call(sender)).toString();
        senderBalance.should.equals(initialSupply.toString());      
    });
  });

  describe('withdraw tokens', function () {
    it('withdraw tokens', async function () {
        const start = new BN(moment().unix());
        const duration = new BN(60 * 60 * 24 * 30);
        const agreementId = new BN(1);
        const totalAmount = new BN(500);

        await this.token.approve(this.trickle.address, totalAmount, {from: sender});
        await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});

        await time.increase(duration / 2);
        let tx = await this.trickle.withdrawTokens(agreementId);
        const amountReleased = new BN(totalAmount / 2);
        expectEvent.inLogs(tx.logs, 'Withdraw', {
          'agreementId': agreementId,
          'token': this.token.address,
          'recipient': recipient,
          'sender': sender,
          'amountReleased': amountReleased,
          'releasedAt': await time.latest()
        });

        let recipientBalance = (await this.token.balanceOf.call(recipient)).toString();
        await recipientBalance.should.be.equals(amountReleased.toString());

        // Try to withdraw twice
        await shouldFail.reverting(this.trickle.withdrawTokens(agreementId));

        // Withdraw all tokens left
        await time.increase(duration / 2);
        tx = await this.trickle.withdrawTokens(agreementId);
        expectEvent.inLogs(tx.logs, 'Withdraw', {
          'agreementId': agreementId,
          'token': this.token.address,
          'recipient': recipient,
          'sender': sender,
          'amountReleased': amountReleased,
          'releasedAt': await time.latest()
        });

        recipientBalance = (await this.token.balanceOf.call(recipient)).toString();
        const expectedAmount = new BN(amountReleased * 2);
        await recipientBalance.should.be.equals(expectedAmount.toString());
    });
  });
});
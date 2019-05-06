const { BN, constants, expectEvent, time, shouldFail } = require('openzeppelin-test-helpers');
const moment = require('moment');
const { ZERO_ADDRESS } = constants;

const Trickle = artifacts.require('Trickle');
const ERC20Mock = artifacts.require('ERC20Mock');

require('chai').should();

contract('Trickle', function ([_, sender, recipient, anotherAccount]) {
  let start;
  let duration;
  let totalAmount;
  let agreementId;

  const initialSupply = new BN(10000);

  beforeEach(async function () {
    start = new BN(moment().add('10 days').unix());
    duration = new BN(60 * 60 * 24 * 30);
    totalAmount = new BN(500);
    agreementId = new BN(1);
    
    this.token = await ERC20Mock.new(sender, initialSupply);
    this.trickle = await Trickle.new();
    await this.token.approve(this.trickle.address, totalAmount, {from: sender});
  });

  describe('create agreement', function () {
    it('creates agreement', async function () {
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

    it('creates multiple agreements', async function () {
      let tx;
      tx = await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      expectEvent.inLogs(tx.logs, 'AgreementCreated', {
        'agreementId': agreementId,
      });

      agreementId = new BN(2);
      await this.token.approve(this.trickle.address, totalAmount, {from: sender});
      tx = await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      expectEvent.inLogs(tx.logs, 'AgreementCreated', {
        'agreementId': agreementId,
      });
    })

    it('can\'t create without tokens approved', async function () {
      totalAmount = new BN(1000);
      shouldFail.reverting(this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender}));
    })

    it('can\'t create with invalid start', async function () {
      start = new BN(0);
      shouldFail.reverting(this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender}));
    });

    it('can\'t create with invalid amount', async function () {
      totalAmount = 0;
      shouldFail.reverting(this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender}));
    });

    it('can\'t create with invalid token', async function () {
      const wrongToken = ZERO_ADDRESS;
      shouldFail.reverting(this.trickle.createAgreement(wrongToken, recipient, totalAmount, duration, start, {from: sender}));
    });

    it('can\'t create with invalid recipient', async function () {
      const wrongRecipient = ZERO_ADDRESS;
      shouldFail.reverting(this.trickle.createAgreement(this.token.address, wrongRecipient, totalAmount, duration, start, {from: sender}));
    });

    it('can\'t create with invalid duration', async function () {
      duration = 0;
      shouldFail.reverting(this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender}));
    });
  });

  describe('cancel agreement', function () {
    it('can be cancelled before agreement starts', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      const tx = await this.trickle.cancelAgreement(agreementId, {from: sender});
      const endedAt = await time.latest();

      expectEvent.inLogs(tx.logs, 'AgreementCanceled', {
        'agreementId': agreementId,
        'token': this.token.address,
        'recipient': recipient,
        'sender': sender,
        'start': start,
        'endedAt': endedAt,
        'amountReleased': new BN(0),
        'amountCanceled': totalAmount
      });

      const senderBalance = (await this.token.balanceOf.call(sender)).toString();
      await senderBalance.should.equals(initialSupply.toString());      
    });

    it('can be cancelled in the middle of agreement', async function() {
      const amountReleased = new BN(totalAmount / 2);
      start = await time.latest();
      
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      const initialSenderBalance = await this.token.balanceOf.call(sender);
      const initialRecipientBalance = await this.token.balanceOf.call(recipient);
      await time.increase(duration / 2);
      await this.trickle.cancelAgreement(agreementId, {from: sender});
      
      const senderBalance = (await this.token.balanceOf.call(sender)).toString();
      await senderBalance.should.equals(
        (initialSenderBalance.add(amountReleased)).toString()
      );

      const recipientBalance = (await this.token.balanceOf.call(recipient)).toString();
      await recipientBalance.should.equals(
        (initialRecipientBalance.add(amountReleased)).toString()
      );
    });

    it('can be cancelled at the and of agreement', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      const initialRecipientBalance = await this.token.balanceOf.call(recipient);
      await time.increase(duration + 1);
      await this.trickle.cancelAgreement(agreementId, {from: sender});

      const recipientBalance = (await this.token.balanceOf.call(recipient)).toString();
      await recipientBalance.should.equals(
        (initialRecipientBalance.add(totalAmount)).toString()
      );
    });

    it('can be canceled from recipient', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      await this.trickle.cancelAgreement(agreementId, {from: recipient});
    })

    it('can\'t be canceled twice', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      await this.trickle.cancelAgreement(agreementId, {from: sender});
      await shouldFail.reverting(this.trickle.cancelAgreement(agreementId, {from: sender}));
    })

    it('can\'t be cancelled from 3rd party account', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      await shouldFail.reverting(this.trickle.cancelAgreement(agreementId, {from: anotherAccount}));
    })

    it('should fail if agreement does not exists', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      agreementId = new BN(2);
      await shouldFail.reverting(this.trickle.cancelAgreement(agreementId, {from: sender}));
    });
  });

  describe('withdraw tokens', function () {
    it('withdraw tokens', async function () {
      start = await time.latest();
      
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
      await recipientBalance.should.equals(amountReleased.toString());

      // Try to withdraw twice
      await shouldFail.reverting(this.trickle.withdrawTokens(agreementId));

      // Withdraw all tokens left from 3rd party account
      await time.increase(duration / 2);
      tx = await this.trickle.withdrawTokens(agreementId, {from: anotherAccount});
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
      await recipientBalance.should.equals(expectedAmount.toString());
    });

    it('should fail if agreement id doesn\'t exist', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      agreementId = new BN(2);
      await shouldFail.reverting(this.trickle.withdrawTokens(agreementId));
    });

    it('should fail if trying to get tokens after cancel', async function () {
      await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
      await this.trickle.cancelAgreement(agreementId, {from: recipient});
      await shouldFail.reverting(this.trickle.withdrawTokens(agreementId));
    });
  });
});
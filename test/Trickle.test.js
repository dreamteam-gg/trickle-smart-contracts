const { BN, constants, expectEvent } = require('openzeppelin-test-helpers');
const moment = require('moment');
const { ZERO_ADDRESS } = constants;

const Trickle = artifacts.require('Trickle');
const ERC20Mock = artifacts.require('ERC20Mock');

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

        await this.token.approve(this.trickle.address, totalAmount, {from: sender});
        const tx = await this.trickle.createAgreement(this.token.address, recipient, totalAmount, duration, start, {from: sender});
        expectEvent.inLogs(tx.logs, 'AgreementCreated', {
            'agreementId': new BN(1),
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

    });
  });

  describe('withdraw tokens', function () {
    it('withdraw tokens', async function () {

    });
  });
});
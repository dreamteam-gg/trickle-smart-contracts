// All estimates are using common gas price and eth to usd rate.
const gasPrice = 3 * Math.pow(10, 9); // 3 GWei
const ethToUsdRate = 163; // 1 ETH = $163

module.exports = {
    getUsedGas: (tx) => `${ tx.receipt.gasUsed } gas (~$${
        Math.round(tx.receipt.gasUsed * gasPrice / Math.pow(10, 18) * ethToUsdRate * 10000) / 10000
    }, ${ ethToUsdRate } USD/ETH)`,
    gasPrice: gasPrice,
    ethToUsdRate: ethToUsdRate
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* 
    - lock X% of money in treasury always -> how would that work?
        - most proposals will work out OK, we can be optimistic -> 9/10 proposals will be OK, we have to have enough money in the treasury to pay for the 1 out
        - how can we achieve this? -> have a formula for calculating the amount that must be deposited
        - 1. when no proposals: have to deposit something first 
        - 2. max funding size can be x times the deposited amount

        - then the required deposit size is calculated based on the previous funding rounds
        - i.e. the DAO is building up a 'trust score' based on the previous succesful research fundings
        - funding that can be requested by the DAO is proportional to the DAO's trust score
        - and it should be proportional to the number of funding rounds, i.e.:
            - if 0 rounds -> 1.5x the deposited amount
            - if 1 round -> 2x the deposit amount
            - if 2 rounds -> 2.5x
            - if 3 rounds -> 3x
            - if 4 rounds -> 3.5x
            - if 5 rounds -> 4x
            - 6 -> 4.5x
            - 7 -> 5x
            - 8 -> 5.5x
            - 9 -> 6x
            - 10 -> 7x
            - 11 -> 7.5x
            - 12 -> 8x
            - 13 -> 8.5x
            - 14 -> 9x
            - 15 -> 10x
            - above that 10x...
 */

library FundingFormula {
    uint256 constant BASE_MULTIPLIER = 15;
    uint256 constant DECIMALS = 10;

    function calculateMaxFundingSize(uint256 _successfulProposals, uint256 _lockedAmount) external pure returns (uint256) {
        uint256 _multiplier = getMultiplier(_successfulProposals);
        return _lockedAmount * _multiplier / DECIMALS;
    }

    function calculateMaxUnlockSize(
        uint256 _successfulProposals,
        uint256 _inRequestAmount
    ) external pure returns (uint256) {
        uint256 _multiplier = getMultiplier(_successfulProposals);
        return (_inRequestAmount * DECIMALS) / _multiplier;
    }

    function getMultiplier(uint256 _successfulProposals) private pure returns (uint256) {
        uint256 multiplier;

        if (_successfulProposals == 0) {
            multiplier = BASE_MULTIPLIER;
        } else if (_successfulProposals == 1) {
            multiplier = BASE_MULTIPLIER + DECIMALS / 2;
        } else if (_successfulProposals == 2) {
            multiplier = BASE_MULTIPLIER + DECIMALS;
        } else if (_successfulProposals == 3) {
            multiplier = BASE_MULTIPLIER + DECIMALS + DECIMALS / 2;
        } else if (_successfulProposals == 4) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 2;
        } else if (_successfulProposals == 5) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 2 + DECIMALS / 2;
        } else if (_successfulProposals == 6) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 3;
        } else if (_successfulProposals == 7) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 3 + DECIMALS / 2;
        } else if (_successfulProposals == 8) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 4;
        } else if (_successfulProposals == 9) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 5;
        } else if (_successfulProposals == 10) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 5 + DECIMALS / 2;
        } else if (_successfulProposals == 11) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 6;
        } else if (_successfulProposals == 12) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 6 + DECIMALS / 2;
        } else if (_successfulProposals == 13) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 7;
        } else if (_successfulProposals == 14) {
            multiplier = BASE_MULTIPLIER + DECIMALS * 7 + DECIMALS / 2;
        } else {
            multiplier = BASE_MULTIPLIER + DECIMALS * 8 + DECIMALS / 2;
        }

        return multiplier;
    }
}

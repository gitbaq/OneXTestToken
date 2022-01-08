pragma solidity ^0.8.0;
import "../contracts/OneXTBBH.sol";

contract BallotTest {
    bytes32[] proposalNames;

    OneXTBBH ballotToTest;

    function beforeAll() public {
        proposalNames.push(bytes32("candidate1"));
        ballotToTest = new Ballot(proposalNames);
    }

    function checkWinningProposal() public {
        ballotToTest.vote(0);
        Assert.equal(
            ballotToTest.winningProposal(),
            uint256(0),
            "proposal at index 0 should be the winning proposal"
        );
        Assert.equal(
            ballotToTest.winnerName(),
            bytes32("candidate1"),
            "candidate1 should be the winner name"
        );
    }

    function checkWinninProposalWithReturnValue() public view returns (bool) {
        return ballotToTest.winningProposal() == 0;
    }
}

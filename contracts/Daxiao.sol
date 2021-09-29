// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Daxiao is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    uint256 public dice1;
    uint256 public dice2;
    uint256 public dice3;

    address public admin;
    uint256 public gameId;
    uint256 public lastGameId;
    uint256 minVault;
    uint256[] betTypeValueRange;
    uint256[] betPayouts;
    mapping(uint256 => Game) public games;

    struct Game {
        uint256 id;
        uint256 betType;
        uint256 betValue;
        //uint256 seed;
        bytes32 requestId;
        uint256 amount;
        address player;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the Admin can call this function");
        _;
    }

    // Events
    event Withdraw(address admin, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event Result(
        uint256 id,
        uint256 betType,
        uint256 betValue,
        bytes32 requestId,
        uint256 amount,
        address player,
        uint256 winAmount,
        uint256 randomResult,
        uint256 result1,
        uint256 result2,
        uint256 result3,
        uint256 time
    );

    constructor()
        public
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)

        admin = msg.sender;
        betTypeValueRange = [1, 5, 5, 0, 14, 5, 13];
        betPayouts = [2, 181, 12, 31, 7, 0, 0];
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function startGame(uint256 betType, uint256 betValue) public payable {
        require(
            betType >= 0 && betType <= 6,
            "Bet must be between 0 and 6 inclusive"
        );
        require(
            betValue >= 0 && betValue <= betTypeValueRange[betType],
            "Invalid bet value"
        );

        // Checking if sufficient vault funds
        uint256 betPayout = betPayouts[betType];
        if (betType == 5) {
            betPayout = 4;
        } else if (betType == 6) {
            betPayout = 61;
        }
        uint256 payout = betPayout * msg.value;

        uint256 provisionalBalance = minVault + payout;
        require(
            provisionalBalance < address(this).balance,
            "Insufficent vault funds"
        );
        minVault += payout;

        // Oracle: Get a Random Number
        bytes32 requestId = getRandomNumber();

        // Save the game
        games[gameId] = Game(
            gameId,
            betType,
            betValue,
            //seed,
            requestId,
            msg.value,
            msg.sender
        );

        // Increase gameId for the next game
        gameId = gameId + 1;
    }

    function endGame(
        bytes32 requestId,
        uint256 random1,
        uint256 random2,
        uint256 random3
    ) internal {
        uint256 sumDice = random1 + random2 + random3;

        // Check each bet from last betting round
        for (uint256 i = lastGameId; i < gameId; i++) {
            // Reset winAmount for current user
            uint256 winAmount = 0;
            uint256 betPayout = betPayouts[games[i].betType];

            // Check if the requestId is the same
            if (games[i].requestId == requestId) {
                bool won = false;

                if (games[i].betType == 0) {
                    // small or big
                    if (games[i].betValue == 0) {
                        if (sumDice >= 4 && sumDice <= 10) {
                            won = true;
                        }
                    } else if (games[i].betValue == 1) {
                        if (sumDice >= 10 && sumDice <= 17) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 1) {
                    // specific triples
                    if ((random1 == random2) && (random2 == random3)) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 2) {
                    // specific doubles
                    if (random1 == random2) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    } else if (random2 == random3) {
                        if ((games[i].betValue + 1) == random2) {
                            won = true;
                        }
                    } else if (random1 == random3) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 3) {
                    // any triples
                    if ((random1 == random2) && (random2 == random3)) {
                        won = true;
                    }
                } else if (games[i].betType == 4) {
                    if (games[i].betValue <= 4) {
                        if (
                            random1 == 1 && random2 == (games[i].betValue + 2)
                        ) {
                            won = true;
                        } else if (
                            random2 == 1 && random3 == (games[i].betValue + 2)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 8) {
                        if (
                            random1 == 2 && random2 == (games[i].betValue - 2)
                        ) {
                            won = true;
                        } else if (
                            random2 == 2 && random3 == (games[i].betValue - 2)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 11) {
                        if (
                            random1 == 3 && random2 == (games[i].betValue - 5)
                        ) {
                            won = true;
                        } else if (
                            random2 == 3 && random3 == (games[i].betValue - 5)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 13) {
                        if (
                            random1 == 4 && random2 == (games[i].betValue - 7)
                        ) {
                            won = true;
                        } else if (
                            random2 == 4 && random3 == (games[i].betValue - 7)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue == 14) {
                        if (random1 == 5 && random2 == 6) {
                            won = true;
                        } else if (random2 == 5 && random3 == 6) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 5) {
                    betPayout = 1;
                    if (random1 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                    if (random2 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                    if (random3 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                } else if (games[i].betType == 6) {
                    if (games[i].betValue + 4 == sumDice) {
                        won = true;
                        if (sumDice == 4 || sumDice == 17) {
                            betPayout = 61;
                        } else if (sumDice == 5 || sumDice == 16) {
                            betPayout = 31;
                        } else if (sumDice == 6 || sumDice == 15) {
                            betPayout = 19;
                        } else if (sumDice == 7 || sumDice == 14) {
                            betPayout = 13;
                        } else if (sumDice == 8 || sumDice == 13) {
                            betPayout = 9;
                        } else if (sumDice == 9 || sumDice == 12) {
                            betPayout = 8;
                        } else if (sumDice == 10 || sumDice == 11) {
                            betPayout = 7;
                        }
                    }
                }

                if (won) {
                    winAmount = betPayout * games[i].amount;
                    payable(games[i].player).transfer(winAmount);
                }

                minVault = 0;

                emit Result(
                    games[i].id,
                    games[i].betType,
                    games[i].betValue,
                    games[i].requestId,
                    games[i].amount,
                    games[i].player,
                    winAmount,
                    randomResult,
                    dice1,
                    dice2,
                    dice3,
                    block.timestamp
                );
            }
        }
        //save current gameId to lastGameId for the next betting round
        lastGameId = gameId;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 random1 = (randomness % 6) + 1;
        uint256 random2 = ((randomness / 10) % 6) + 1;
        uint256 random3 = ((randomness / 100) % 6) + 1;

        // sort from small to large for easier computation for outcome
        if (random2 < random1) {
            if (random3 < random2) {
                // random3 is smallest;
                uint256 temp = random1;
                random1 = random3;
                random3 = temp;
            } else {
                uint256 temp = random1;
                random1 = random2;
                random2 = temp;
            }
        } else {
            if (random3 < random1) {
                uint256 temp = random3;
                random3 = random1;
                random1 = temp;
            }
        }

        if (random3 < random2) {
            uint256 temp = random3;
            random3 = random2;
            random2 = temp;
        }
        dice1 = random1;
        dice2 = random2;
        dice3 = random3;

        randomResult = randomness;

        // End the game
        endGame(requestId, random1, random2, random3);
    }

    function withdrawLink(uint256 amount) external onlyAdmin {
        require(LINK.transfer(msg.sender, amount), "Error, unable to transfer");
    }

    function withdrawEther(uint256 amount) external payable onlyAdmin {
        require(
            address(this).balance >= amount,
            "Error, contract has insufficent balance"
        );
        payable(admin).transfer(amount);

        emit Withdraw(admin, amount);
    }
}

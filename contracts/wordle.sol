// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

//Nordle
contract TestContract is ERC721, Ownable {
  string secretWord;
  bytes secretWordCharArray;
  uint8 private constant letters = 6;
  uint8 private constant tries = 6;
  uint8 public nordleNumber = 0;
  uint256 public tokenIndex = 0;
  uint public currentGameTimeStamp; //!!!! This might be exploitable?

  mapping (bytes1 => uint8) public secretWordCharCount; // Keep count of chars
  mapping (address => uint8) public userTries; // (address => tries). If not in mapping, tries will be 0
  mapping (address => uint) public currentToken; // mapping of the current Token that the address is using to play Nordle
  mapping (uint => string) public tokenMetadata; // (tokenID => metadata)
  mapping (address => uint) public lastGameTimeStamp;

  constructor(string memory word) ERC721("Nordle", "NDL") {
    setSecretWord(word);
    console.log("hello world");
  }

  function guessWord(string memory inputString) public { //Guess the word.
    //require that length of input is == 6
    require(userTries[msg.sender] < tries, "Maxed out guesses for this Nordle");
    //Changes the metadata, hence changing the icons of the wordle thingy
    //Only add a new row when after each guess to save on gas
    
    if (lastGameTimeStamp[msg.sender] < currentGameTimeStamp) { //Should work if it is a brand new player
      userTries[msg.sender] = 1;
      tokenIndex += 1;
      currentToken[msg.sender] = tokenIndex;
    }

    uint8[letters] memory indexStates = checkWord(bytes(inputString));
    lastGameTimeStamp[msg.sender] = block.timestamp;

     if(userTries[msg.sender] > 1) { //generate the metadata
       //Grab and edit the existing NFT's metadata
       console.log("here");
     } else { 
        console.log("there");
        tokenMetadata[currentToken[msg.sender]] = generateMetadata(indexStates);
        userTries[msg.sender] += 1;
        console.log("Generating data for first time");
        console.log(tokenIndex);
        _mint(msg.sender,tokenIndex);
        tokenIndex += 1;
     }

  }

  function checkWord(bytes memory inputChars) public returns (uint8[6] memory) { // Can probably make this more efficient
    uint8[letters] memory indexStates = [0, 0, 0, 0, 0, 0]; // Three states. Incorrect = 0, Correct = 1, Somewhere in word = 2
    mapping (bytes1 => uint8) storage charCount = secretWordCharCount;// Needed so that can use same character in multiple spots
  
    for(uint16 i = 0; i < letters ; i++) {// Check characters in inputString
      // console.logBytes1(inputChars[i]);
      // console.log(charCount[inputChars[i]]);

      if (charCount[inputChars[i]] == 0){// Char is not in array. prevent underflow
        
      } else if (secretWordCharArray[i] == inputChars[i]) { // Char is in the correct position
        indexStates[i] = 1;
        charCount[inputChars[i]] -= 1;
        // console.logBytes1(inputChars[i]);
      } else if (charCount[inputChars[i]] > 0) { // Char is somewhere in the word
        indexStates[i] = 2;
        charCount[inputChars[i]] -= 1;
      }
        // console.log(indexStates[i]);
    }

    return indexStates;
  }

  function setSecretWord(string memory newSecretWord) public onlyOwner {
    bytes memory charArray = bytes(newSecretWord); //Convert string to byte/char array of ascii hex codes

    for(uint16 i = 0; i < letters ; i++) {
        secretWordCharCount[charArray[i]] += 1; //Have to increment because if a key is not defined in a mapping it has a default value of 0
    }

    secretWord = newSecretWord;
    secretWordCharArray = charArray;
    nordleNumber += 1;

    currentGameTimeStamp = block.timestamp;
     //could have a boolean to clear mapping
     //Reset userTries mapping
     //Reset stored data
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return tokenMetadata[tokenId];
  }

  function generateMetadata(uint8[letters] memory indexStates) private returns (string memory) {
    //Currently won't be able to add data from previous attemps
    //Need to have data about # of tries and nordleDay #

    string memory rowEmojis;
    string memory metadata;
    string[3] memory parts;

    for (uint16 i = 0; i < letters; i++ ) {
      if (indexStates[i] == 0) { //Incorrect
          rowEmojis = string(abi.encodePacked(rowEmojis,  unicode"⬛"));
      } else if (indexStates[i] == 1) { //Correct
          rowEmojis = string(abi.encodePacked(rowEmojis, unicode"🟩"));
      } else if (indexStates[i] == 2) { //Somewhere in word
          rowEmojis = string(abi.encodePacked(rowEmojis, unicode"🟨"));
      }
    }

    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 18px; }</style><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">';
    parts[1] = rowEmojis; // Should prepopulate the rest of the squares?
    parts[2] = '</text></svg>';


    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Emoji #' , '", "description": "Inspired by the Loot (for Adventurers) contract. This is stored completely on-chain. No third party hosting, no rug pulls.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    metadata = string(abi.encodePacked('data:application/json;base64,', json));

    console.log(rowEmojis);
    console.log(metadata);
    return rowEmojis;
  }
}


///OpenZeppelin's Base64 Library: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
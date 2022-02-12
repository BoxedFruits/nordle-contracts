// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

//Nordle
contract TestContract is ERC721, Ownable {
  string secretWord;
  bytes secretWordCharArray;
  uint8 private constant maxLetters = 6;
  uint8 private constant maxTries = 6;
  uint8 public nordleNumber = 0;
  uint256 public tokenIndex = 0;
  uint public currentGameTimeStamp; //!!!! This might be exploitable?

  mapping (bytes1 => uint8) private secretWordCharCount; // Keep count of chars
  mapping (address => uint8) public userTries; // (address => tries). If not in mapping, tries will be 0
  mapping (address => uint) public currentToken; // mapping of the current Token that the address is using to play Nordle
  mapping (uint => string[]) private tokenRowEmojis; // (tokenID => metadata)`
  mapping (uint => string) private tokenMetadata; // (tokenID => metadata)
  mapping (address => uint) public lastGameTimeStamp;

  constructor(string memory word) ERC721("Nordle", "2NDL") {
    setSecretWord(word);
    console.log("hello world");
  }

  function guessWord(string memory inputString) public { //Guess the word.
    //require that length of input is == 6
    require(userTries[msg.sender] < maxTries, "Maxed out guesses for this Nordle");
    
    // If new Nordle starts, reset user's tries and mint new NFT
    if (lastGameTimeStamp[msg.sender] < currentGameTimeStamp) { //Should work if it is a brand new player
      userTries[msg.sender] = 0;
      // tokenIndex += 1;
      // currentToken[msg.sender] = tokenIndex;
    }

    uint8[maxLetters] memory indexStates = checkWord(bytes(inputString));
    lastGameTimeStamp[msg.sender] = block.timestamp;
      console.log(userTries[msg.sender]);


     if(userTries[msg.sender] >= 1) { //generate the metadata
        //Grab and edit the existing NFT's metadata
        console.log("Guess again");
        // tokenMetadata[currentToken[msg.sender]] = string(abi.encodePacked(tokenMetadata[currentToken[msg.sender]], '\n' , generateMetadata(indexStates)));
        // tokenMetadata[currentToken[msg.sender]] = string(abi.encodePacked(tokenMetadata[currentToken[msg.sender]], '\n' , generateRowEmojis(indexStates)));
        tokenRowEmojis[currentToken[msg.sender]].push(generateRowEmojis(indexStates));
        tokenMetadata[currentToken[msg.sender]] = generateMetadata(tokenRowEmojis[currentToken[msg.sender]]);
     } else {
        console.log("Generating data for first time");
        // tokenMetadata[currentToken[msg.sender]] = generateMetadata(indexStates);
        tokenRowEmojis[currentToken[msg.sender]].push(generateRowEmojis(indexStates));
        tokenMetadata[currentToken[msg.sender]] = generateMetadata(tokenRowEmojis[currentToken[msg.sender]]);
        userTries[msg.sender] += 1;

        _mint(msg.sender,tokenIndex);
        tokenIndex += 1;
     }
    console.log(tokenMetadata[currentToken[msg.sender]]);
  }

  function checkWord(bytes memory inputChars) private returns (uint8[6] memory) { // Can probably make this more efficient
    uint8[maxLetters] memory indexStates = [0, 0, 0, 0, 0, 0]; // Three states. Incorrect = 0, Correct = 1, Somewhere in word = 2
    mapping (bytes1 => uint8) storage charCount = secretWordCharCount;// Needed so that can use same character in multiple spots
    uint8 correctLetters = 0;
    for(uint16 i = 0; i < maxLetters ; i++) {// Check characters in inputString
      if (charCount[inputChars[i]] == 0){// Char is not in array. prevent underflow
        
      } else if (secretWordCharArray[i] == inputChars[i]) { // Char is in the correct position
        indexStates[i] = 1;
        charCount[inputChars[i]] -= 1;
        // console.logBytes1(inputChars[i]);
        correctLetters += 1;
      } else if (charCount[inputChars[i]] > 0) { // Char is somewhere in the word
        indexStates[i] = 2;
        charCount[inputChars[i]] -= 1;
      }
        // console.log(indexStates[i]);
    }

    if (correctLetters - 1 == maxLetters) { // Solved! Make sure user doesn't keep guessing
      userTries[msg.sender] = 6;
    }

    return indexStates;
  }

  function setSecretWord(string memory newSecretWord) public onlyOwner {
    bytes memory charArray = bytes(newSecretWord); //Convert string to byte/char array of ascii hex codes
    require(charArray.length == maxLetters, 'The new secret word does not have the correct maxLetters');
    for(uint16 i = 0; i < maxLetters ; i++) {
        secretWordCharCount[charArray[i]] += 1; //Have to increment because if a key is not defined in a mapping it has a default value of 0
    }

    secretWord = newSecretWord;
    secretWordCharArray = charArray;
    nordleNumber += 1;

    currentGameTimeStamp = block.timestamp;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return tokenMetadata[tokenId];
  }

  function generateRowEmojis(uint8[maxLetters] memory indexStates) private view returns (string memory) {
    string memory rowEmojis;
    string memory metadata;
    string[3] memory parts;

    for (uint16 i = 0; i < maxLetters; i++ ) {
      if (indexStates[i] == 0) { //Incorrect
          rowEmojis = string(abi.encodePacked(rowEmojis,  unicode"⬛"));
      } else if (indexStates[i] == 1) { //Correct
          rowEmojis = string(abi.encodePacked(rowEmojis, unicode"🟩"));
      } else if (indexStates[i] == 2) { //Somewhere in word
          rowEmojis = string(abi.encodePacked(rowEmojis, unicode"🟨"));
      }
    }

    //this should be apart of the when 
    // parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 18px; } .header{ font-family: "Clear Sans", "Helvetica Neue", Arial, sans-serif;  }</style><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">';
    // parts[1] = rowEmojis; // Should prepopulate the rest of the squares?
    // parts[2] = '</text></svg>';

    // string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
    // string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Nordle #' , toString(nordleNumber) ,'","description": "User is on try # ', toString(userTries[msg.sender]) ,'. Inspired by Wordle. Should anyone actually use this? No. I thought it would be a fun project", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    // metadata = string(abi.encodePacked('data:application/json;base64,', json));

    // console.log(rowEmojis);
    // console.log(metadata);
    return rowEmojis;
  }

  function generateMetadata(string[] memory rowEmojis) private view returns (string memory) {
    string[4] memory svgData;
    string memory allEmojiHTML;
    string memory header = '<text x="50%" y="10%" id="header" dominant-baseline="middle" text-anchor="middle">Nordle</text>';
    
    uint8 yAxis = 18;
    for (uint8 i = 0; i < rowEmojis.length; i++) {
      allEmojiHTML = string(abi.encodePacked(allEmojiHTML,'<text x="50%" y="', toString(yAxis),'%" class="base" dominant-baseline="middle" text-anchor="middle">', rowEmojis[i], '</text>'));
      yAxis += 10;
    }

    svgData[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 18px; } .header{ font-size: 34px; font-family: "Clear Sans", "Helvetica Neue", Arial, sans-serif;  }</style>';
    svgData[1] = header;
    svgData[2] = allEmojiHTML;
    svgData[3] = '</svg>';
    console.log(toString(nordleNumber));
    string memory metadata = Base64.encode(bytes(string(abi.encodePacked('{"name": "Nordle #' , toString(nordleNumber) ,'","description": "User is on try # ', toString(userTries[msg.sender]) ,'. Inspired by Wordle. Should anyone actually use this? No. I thought it would be a fun project", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked(svgData[0],svgData[1],svgData[2], svgData[3]))),'","attributes": [{ " trait_type " : "Nordle #","value":"',toString(nordleNumber),'"}, { " trait_type ": "User Tries","value":"', toString(userTries[msg.sender]),'"}]}'))));
    metadata = string(abi.encodePacked('data:application/json;base64,', metadata));

    return metadata;
  }

  function toString(uint256 value) internal pure returns (string memory) {
  // Inspired by OraclizeAPI's implementation - MIT license
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
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
pragma solidity ^0.8.17;

contract DataModel {
    struct Data {
        uint256 id;
        string name;
        string description;
        string url;
        string hash;
        uint256 timestamp;
    }
    mapping(uint256 => Data) public data;
    uint256 public dataCount;
}
pragma solidity ^0.8.17;

contract DataModel {
    struct Model {
        string id;
        address creator;
        string name;
        string description;
        string url;
        uint256 timestamp;
        string[] versions;
    }

    struct ModelVersion {
        string version;
        string uri;
    }

    /** Mappings */
    mapping(string => Model) public models;
    mapping(bytes32 => ModelVersion) public modelVersions;

    function createModelVersion(string memory _id, string memory _version, string memory _uri) public {
        modelVersions[keccak256(abi.encodePacked(_id, _version))] = ModelVersion(_version, _uri);
        models[_id].versions.push(_version);
    }

    function getModelVersion(string memory _id, string memory _version) public view returns (ModelVersion memory) {
        return modelVersions[keccak256(abi.encodePacked(_id, _version))];
    }

    function createModel(string memory _id, string memory _name, string memory _description, string memory _url) public {
        models[_id] = Model(_id, msg.sender, _name, _description, _url, block.difficulty, new string[](0));
        createModelVersion(_id, "initial", _url);
    }
}
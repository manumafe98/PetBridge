// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

/** 
* @title Pet Adoption and Foster dapp
* @author Manuel Maxera & Aixa Irupé Alvarez
* @notice This contract focuses on the securing the adoption/foster of pets via blockchain
* @notice By applying a fee mechanism on posting pets on adoption and foster and also on people that publish themselves to take pets on foster
* @notice Allows people that publish themselves to take care of pets in foster to receive tips of people that want to collaborate
* @notice The person that has the ownership of the adoption/foster of the pet receives requests of adoptions and has to review them and approve or reject them
*/
contract PetAdoption {
    error PetAdoption__InsufficientFeeSent();
    error PetAdoption__InvalidPetNecessity();

    struct Pet {
        uint256 id;
        string name;
        uint8 age;
        string description;
        string ipfsHash;
        PetType petType;
        PetNecessity petNecessity;
        address petPublisher;
    }

    struct User {
        string name;
        UserType userType;
    }

    enum UserType {
        PUBLISHER,
        ADOPTER,
        FOSTERER
    }

    enum PetType {
        CAT,
        DOG
    }

    enum PetNecessity {
        ADOPTION,
        FOSTER
    }

    address private immutable i_owner;
    uint256 private s_totalPetsOnAdoption;
    uint256 private s_totalPetsOnFoster;

    uint256 private constant PET_PUBLISHER_FEE = 0.001 ether;

    mapping (uint256 => Pet) private petsOnAdoption;
    mapping (uint256 => Pet) private petsOnFoster;
    mapping (uint256 => bool) private isPetAdoptedFostered;

    mapping (address => User) private users;
    mapping (address => bool) private isUserRegistered;

    event PetOnAdoptionAdded(uint256 indexed id, string name, PetType petType, address petPublisher);
    event PetOnFosterAdded(uint256 indexed id, string name, PetType petType, address petPublisher);

    constructor() {
        i_owner = msg.sender;
    }

    function addPet(string memory _name, uint8 _age, string memory _description, string memory _ipfsHash, PetType _petType, PetNecessity _petNecessity) external payable {
        if (msg.value < PET_PUBLISHER_FEE) {
            revert PetAdoption__InsufficientFeeSent();
        }

        uint256 petId;
        Pet storage pet;

        if (_petNecessity == PetNecessity.ADOPTION) {
            pet = petsOnAdoption[petId];
            petId = s_totalPetsOnAdoption += 1;
        } else if (_petNecessity == PetNecessity.FOSTER) {
            pet = petsOnFoster[petId];
            petId = s_totalPetsOnFoster += 1;
        } else {
            revert PetAdoption__InvalidPetNecessity();
        }

        pet.id = petId;
        pet.name = _name;
        pet.age = _age;
        pet.description = _description;
        pet.ipfsHash = _ipfsHash;
        pet.petType = _petType;
        pet.petNecessity = _petNecessity;
        pet.petPublisher = msg.sender;

        isPetAdoptedFostered[petId] = false;

        if (_petNecessity == PetNecessity.ADOPTION) {
            emit PetOnAdoptionAdded(petId, _name, _petType, msg.sender);
        } else {
            emit PetOnFosterAdded(petId, _name, _petType, msg.sender);
        }
    }

    function registerUser(string memory _name, UserType _userType) external payable {}

    function adoptPet() external payable {}

    function fosterPet() external payable {}

    function approveOrRejectPetAdoption() external {}

    function approveOrRejectPetFoster() external {}

    function getPetOnAdoption(uint256 _id) external view returns(Pet memory) {
        return petsOnAdoption[_id];
    }

    function getPetOnFoster(uint256 _id) external view returns(Pet memory) {
        return petsOnFoster[_id];
    }

    function getPetFosterRequests() external {}

    function getPetAdoptionRequests() external {}

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getTotalPetsOnAdoption() external view returns(uint256) {
        return s_totalPetsOnAdoption;
    }

    function getTotalPetsOnFoster() external view returns(uint256) {
        return s_totalPetsOnFoster;
    }
}

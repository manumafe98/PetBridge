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
contract PetBridge {
    error PetBridge__InsufficientFee(FeeActionType _feeActionType);
    error PetBridge__InvalidPetNecessity();
    error PetBridge__InvalidActionForUnregisteredUser();
    error PetBridge__UnavailableActionForCurrentUserRegistration();
    error PetBridge__InvalidTipValue();
    error PetBridge__InvalidFostererUserId();
    error PetBridge__TipTransferFailed();
    error PetBridge__RefundTransferFailed(FeeActionType _feeActionType);
    error PetBridge_NotOwner();
    error PetBridge__PetAlreadyAdopted();
    error PetBridge__PetAlreadyFostered();
    error PetBridge__InvalidPetId();
    error PetBridge__YouHaveAlreadyAPendingRequest();
    error PetBridge__YourRequestWasPreviouslyRejected();
    error PetBridge__YourRequestWasAlreadyApproved();
    error PetBridge__OnlyPublisherCanApproveAdoption();

    struct Pet {
        uint256 id;
        string name;
        uint8 age;
        string description;
        string ipfsHash;
        PetType petType;
        PetNecessity petNecessity;
        string publisherLocation;
        address petPublisher;
    }

    struct UserFosterer {
        uint256 id;
        string name;
        address _address;
        uint256 petsFosteredSuccessfully;
        uint256 tipsReceived;
    }

    struct UserAdopter {
        string name;
        address _address;
    }

    struct UserPublisher {
        string name;
        address _address;
        uint256 petsAdoptedAfterPublish;
        uint256 petsFosteredAfterPublish;
    }

    struct Request {
        uint256 requestId;
        uint256 petId;
        address userThatSentRequest;
        RequestType requestType;
        bool isRequestApproved;
        bool isRequestRejected;
    }

    enum RequestType {
        ADOPTION,
        FOSTER
    }

    enum PetType {
        CAT,
        DOG
    }

    enum PetNecessity {
        ADOPTION,
        FOSTER,
        ADOPTION_AND_FOSTER
    }

    enum UserType {
        NONE,
        FOSTERER,
        ADOPTER,
        PUBLISHER
    }

    enum FeeActionType {
        PUBLISHING,
        REGISTERING_FOSTERER,
        FOSTER_APPLICATION,
        ADOPT_APPLICATION
    }

    address private immutable i_owner;
    uint256 private s_totalPetsOnAdoption;
    uint256 private s_totalPetsOnFoster;

    uint256 private s_totalFostererUsers;

    uint256 private s_totalRequests;

    uint256 private constant PET_PUBLISH_FEE = 0.001 ether;
    uint256 private constant FOSTERER_REGISTRATION_FEE = 0.001 ether;
    uint256 private constant PET_ADOPTION_APPLICATION_FEE = 0.001 ether;
    uint256 private constant PET_FOSTER_APPLICATION_FEE = 0.001 ether;

    mapping (uint256 => Pet) private petsOnAdoption;
    mapping (uint256 => Pet) private petsOnFoster;
    mapping (uint256 => bool) private petAlreadyFostered;
    mapping (uint256 => bool) private petAlreadyAdopted;

    mapping (uint256 => UserFosterer) private fostererUsers;
    mapping (address => UserAdopter) private adopterUsers;
    mapping (address => UserPublisher) private publisherUsers;
    mapping (address => UserType) private registeredUsers;

    mapping (uint256 => Request[]) private petRequests;

    event PetOnAdoptionAdded(uint256 indexed id, string name, PetType petType, address petPublisher, string publisherLocation);
    event PetOnFosterAdded(uint256 indexed id, string name, PetType petType, address petPublisher, string publisherLocation);

    event FostererUserAdded(uint256 indexed id, address indexed _address, string name);
    event AdopterUserAdded(address indexed _address, string name);
    event PublisherUserAdded(address indexed _address, string name);

    event RequestCreated(uint256 indexed petId, uint256 indexed requestId, address indexed userThatSentRequest, RequestType requestType);

    event PetSucessfullyAdopted();
    event PetSuccessfullyFostered();

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert PetBridge_NotOwner();
        }
        _;
    }

    modifier onlyRegisteredUsers() {
        if (registeredUsers[msg.sender] == UserType.NONE) {
            revert PetBridge__InvalidActionForUnregisteredUser();
        }
        _;
    }

    modifier onlyForCertainRegisteredUsers(UserType _userType) {
        if (registeredUsers[msg.sender] != _userType) {
            revert PetBridge__UnavailableActionForCurrentUserRegistration();
        }
        _;
    }

    modifier onlyWithCorrectFee(uint256 _feeSent, uint256 _expectedFee, FeeActionType _feeAction) {
        if (_feeSent < _expectedFee) {
            revert PetBridge__InsufficientFee(_feeAction);
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function addPetOnDeploy(string memory _name, uint8 _age, string memory _description, string memory _ipfsHash, PetType _petType, string memory _publisherLocation, PetNecessity _petNecessity) external onlyOwner {
        uint256 petId;
        Pet storage pet;

        if (_petNecessity == PetNecessity.ADOPTION) {
            pet = petsOnAdoption[petId];
            petId = s_totalPetsOnAdoption += 1;
        } else if (_petNecessity == PetNecessity.FOSTER) {
            pet = petsOnFoster[petId];
            petId = s_totalPetsOnFoster += 1;
        } else {
            revert PetBridge__InvalidPetNecessity();
        }

        pet.id = petId;
        pet.name = _name;
        pet.age = _age;
        pet.description = _description;
        pet.ipfsHash = _ipfsHash;
        pet.petType = _petType;
        pet.publisherLocation = _publisherLocation;
        pet.petNecessity = _petNecessity;
        pet.petPublisher = msg.sender;

        petAlreadyFostered[petId] = false;
        petAlreadyAdopted[petId] = false;
    }

    function addPet(string memory _name, uint8 _age, string memory _description, string memory _ipfsHash, PetType _petType, string memory _publisherLocation, PetNecessity _petNecessity) external payable onlyRegisteredUsers onlyForCertainRegisteredUsers(UserType.PUBLISHER) onlyWithCorrectFee(msg.value, PET_PUBLISH_FEE, FeeActionType.PUBLISHING) {
        uint256 petId;
        Pet storage pet;

        if (_petNecessity == PetNecessity.ADOPTION) {
            pet = petsOnAdoption[petId];
            petId = s_totalPetsOnAdoption += 1;
        } else if (_petNecessity == PetNecessity.FOSTER) {
            pet = petsOnFoster[petId];
            petId = s_totalPetsOnFoster += 1;
        } else {
            revert PetBridge__InvalidPetNecessity();
        }

        pet.id = petId;
        pet.name = _name;
        pet.age = _age;
        pet.description = _description;
        pet.ipfsHash = _ipfsHash;
        pet.petType = _petType;
        pet.publisherLocation = _publisherLocation;
        pet.petNecessity = _petNecessity;
        pet.petPublisher = msg.sender;

        petAlreadyFostered[petId] = false;
        petAlreadyAdopted[petId] = false;

        if (_petNecessity == PetNecessity.ADOPTION) {
            emit PetOnAdoptionAdded(petId, _name, _petType, msg.sender, _publisherLocation);
        } else {
            emit PetOnFosterAdded(petId, _name, _petType, msg.sender, _publisherLocation);
        }
    }

    function registerFostererUser(string memory _name) external payable onlyWithCorrectFee(msg.value, FOSTERER_REGISTRATION_FEE, FeeActionType.REGISTERING_FOSTERER) {
        uint256 totalFostererUsers = s_totalFostererUsers += 1;

        UserFosterer storage user = fostererUsers[totalFostererUsers];
        user.id = totalFostererUsers;
        user.name = _name;
        user._address = msg.sender;
        user.petsFosteredSuccessfully = 0;
        user.tipsReceived = 0;

        registeredUsers[msg.sender] = UserType.FOSTERER;

        emit FostererUserAdded(totalFostererUsers, msg.sender, _name);
    }

    function tipFostererUser(uint256 _userId) external payable {
        if (msg.value == 0) {
            revert PetBridge__InvalidTipValue();
        }

        UserFosterer memory user = fostererUsers[_userId];
        if (user._address == address(0)) {
            revert PetBridge__InvalidFostererUserId();
        }

        (bool success,) = payable(user._address).call{value: msg.value}("");
        if (!success) {
            revert PetBridge__TipTransferFailed();
        }

        user.tipsReceived += 1;
    }

    function applyToAdoptPet(uint256 _petId) external payable onlyRegisteredUsers onlyForCertainRegisteredUsers(UserType.ADOPTER) onlyWithCorrectFee(msg.value, PET_ADOPTION_APPLICATION_FEE, FeeActionType.ADOPT_APPLICATION) {
        if (petAlreadyAdopted[_petId]) {
            revert PetBridge__PetAlreadyAdopted();
        }

        _helperPetApplication(_petId, s_totalPetsOnAdoption, RequestType.ADOPTION);
    }

    function applyToFosterPet(uint256 _petId) external payable onlyRegisteredUsers onlyForCertainRegisteredUsers(UserType.FOSTERER) onlyWithCorrectFee(msg.value, PET_FOSTER_APPLICATION_FEE, FeeActionType.FOSTER_APPLICATION) {
        if (petAlreadyFostered[_petId]) {
            revert PetBridge__PetAlreadyFostered();
        }

        _helperPetApplication(_petId, s_totalPetsOnFoster, RequestType.FOSTER);
    }

    function approvePetAdoption(uint256 _petId, uint256 _requestId) external {
        if (msg.sender != petsOnAdoption[_petId].petPublisher) {
            revert PetBridge__OnlyPublisherCanApproveAdoption();
        }

        Request[] storage requests = petRequests[_petId];
        address requestSender;

        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                requests[i].isRequestApproved = true;
                requestSender = requests[i].userThatSentRequest;
                break;
            }
        }

        (bool publishFeeRefund,) = payable(msg.sender).call{value: PET_PUBLISH_FEE}("");
        if (!publishFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.PUBLISHING);
        }

        (bool adoptionApplicationFeeRefund,) = payable(requestSender).call{value: PET_ADOPTION_APPLICATION_FEE}("");
        if (!adoptionApplicationFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.ADOPT_APPLICATION);
        }

        petAlreadyAdopted[_petId] = true;
    }

    function rejectPetAdoption() external {}

    function approvePetFoster() external {}

    function rejectPetFoster() external {}

    function _helperPetApplication(uint256 _petId, uint256 _totalPets, RequestType _requestType) private {
        if (_petId > _totalPets || _petId <= 0) {
            revert PetBridge__InvalidPetId();
        }

        uint256 totalRequests = s_totalRequests += 1;

        Request[] storage requests = petRequests[_petId];
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].userThatSentRequest == msg.sender && !requests[i].isRequestRejected) {
                revert PetBridge__YouHaveAlreadyAPendingRequest();
            } else if (requests[i].userThatSentRequest == msg.sender && requests[i].isRequestRejected) {
                revert PetBridge__YourRequestWasPreviouslyRejected();
            } else if (requests[i].userThatSentRequest == msg.sender && requests[i].isRequestApproved) {
                revert PetBridge__YourRequestWasAlreadyApproved();
            }
        }

        Request memory newRequest = Request({
            requestId: totalRequests,
            petId: _petId,
            userThatSentRequest: msg.sender,
            requestType: _requestType,
            isRequestApproved: false,
            isRequestRejected: false
        });

        requests.push(newRequest);

        emit RequestCreated(_petId, totalRequests, msg.sender, _requestType);
    }

    function getPetRequestsByType(uint256 _petId, RequestType _requestType) external view returns(Request[] memory) {
        Request[] memory currentRequests;
        uint256 count = 0;

        Request[] storage requests = petRequests[_petId];
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].isRequestApproved || requests[i].isRequestRejected) {
                continue;
            }

            if (requests[i].requestType == _requestType) {
                currentRequests[count] = requests[i];
                count += 1;
            }
        }
        return currentRequests;
    }

    function getPetOnAdoption(uint256 _id) external view returns(Pet memory) {
        return petsOnAdoption[_id];
    }

    function getPetOnFoster(uint256 _id) external view returns(Pet memory) {
        return petsOnFoster[_id];
    }

    function getFostererUser(uint256 _id) external view returns(UserFosterer memory) {
        return fostererUsers[_id];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getTotalPetsOnAdoption() external view returns(uint256) {
        return s_totalPetsOnAdoption;
    }

    function getTotalPetsOnFoster() external view returns(uint256) {
        return s_totalPetsOnFoster;
    }

    function getTotalFostererUsers() external view returns(uint256) {
        return s_totalFostererUsers;
    }
}

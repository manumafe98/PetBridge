// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Pet Adoption and Foster dapp.
 * @author Manuel Maxera & Aixa Irupé Alvarez.
 * @notice This contract focuses on securing the adoption/foster of pets via blockchain.
 * @notice By applying a fee mechanism on posting pets on adoption and foster and also on people that publish themselves to take pets on foster.
 * @notice When the pet is given on adoption or foster sucessfully the publisher will be refunded the publish fee.
 * @notice Allows people that publish themselves to take care of pets in foster to receive tips of people that want to collaborate.
 * @notice Allows people that publish pets for adopting or fostering to also receive tips.
 * @notice The person that has the ownership of the adoption/foster of the pet receives requests of adoptions and has to review them and approve or reject them.
 * @notice To apply for the adoption or foster you have to pay a fee to and pass publisher validation, that fee is going to be refunded if the process finishes successfully or unsuccesffully.
 */
contract PetBridge {
    error PetBridge__InsufficientFee(FeeActionType _feeActionType);
    error PetBridge__InvalidPetNecessity();
    error PetBridge__InvalidActionForUnregisteredUser();
    error PetBridge__UnavailableActionForCurrentUserRegistration();
    error PetBridge__InvalidTipValue();
    error PetBridge__InvalidUserId(uint256 _userId, UserType _userType);
    error PetBridge__TipTransferFailed();
    error PetBridge__RefundTransferFailed(FeeActionType _feeActionType);
    error PetBridge__PetAlreadyAdopted();
    error PetBridge__PetAlreadyFostered();
    error PetBridge__InvalidPetId();
    error PetBridge__YouHaveAlreadyAPendingRequest();
    error PetBridge__YourRequestWasPreviouslyRejected();
    error PetBridge__YourRequestWasAlreadyApproved();
    error PetBridge__OnlyPublisherCanTakeActionOverRequests();
    error PetBridge__YouCannotTipYourself();
    error PetBridge__UserAlreadyRegistered();
    error PetBridge__InvalidRequestId();
    error PetBridge__InvalidRequestAction();

    struct Pet {
        uint256 id;
        string name;
        uint8 age;
        string description;
        string ipfsImageHash;
        PetType petType;
        PetNecessity petNecessity;
        string publisherLocation;
        address petPublisher;
    }

    struct UserFosterer {
        uint256 id;
        string name;
        string ipfsImageHash;
        address _address;
        uint256 petsFosteredSuccessfully;
        uint256 rejectedFosterApplications;
        uint256 tipsReceived;
    }

    struct UserAdopter {
        string name;
        string ipfsImageHash;
        address _address;
        uint256 rejectedAdoptionApplications;
    }

    struct UserPublisher {
        uint256 id;
        string name;
        string ipfsImageHash;
        address _address;
        uint256 petsAdoptedAfterPublish;
        uint256 petsFosteredAfterPublish;
        uint256 tipsReceived;
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

    enum RequestAction {
        APPROVE,
        REJECT
    }

    address private immutable i_owner;
    uint256 private s_totalPetsOnAdoption;
    uint256 private s_totalPetsOnFoster;

    uint256 private s_totalFostererUsers;
    uint256 private s_totalPublisherUsers;

    uint256 private s_totalRequests;

    // Currently Fees are hardcoded to 0.01 ether the idea is to modify them with chainlink oracle functionality
    // and convert them to proper usd values like $5 or $10
    uint256 private constant PET_PUBLISH_FEE = 0.001 ether;
    uint256 private constant FOSTERER_REGISTRATION_FEE = 0.001 ether;
    uint256 private constant PET_ADOPTION_APPLICATION_FEE = 0.001 ether;
    uint256 private constant PET_FOSTER_APPLICATION_FEE = 0.001 ether;

    mapping(uint256 => Pet) private petsOnAdoption;
    mapping(uint256 => Pet) private petsOnFoster;
    mapping(uint256 => bool) private petAlreadyFostered;
    mapping(uint256 => bool) private petAlreadyAdopted;

    mapping(uint256 => UserFosterer) private fostererUsers;
    mapping(uint256 => UserPublisher) private publisherUsers;
    mapping(address => UserAdopter) private adopterUsers;
    mapping(address => UserType) private registeredUsers;
    mapping(address => uint256) private userAddressToId;

    mapping(uint256 => Request[]) private petRequests;

    event PetOnAdoptionAdded(
        uint256 indexed id, string name, PetType petType, address petPublisher, string publisherLocation
    );
    event PetOnFosterAdded(
        uint256 indexed id, string name, PetType petType, address petPublisher, string publisherLocation
    );

    event FostererUserAdded(uint256 indexed id, address indexed _address, string name, string ipfsImageHash);
    event PublisherUserAdded(uint256 indexed id, address indexed _address, string name, string ipfsImageHash);
    event AdopterUserAdded(address indexed _address, string name, string ipfsImageHash);

    event RequestCreated(
        uint256 indexed petId, uint256 indexed requestId, address indexed userThatSentRequest, RequestType requestType
    );
    event ApplicationRequestRejected(
        address indexed requestSender, uint256 indexed requestId, uint256 petId, address requestReviewer
    );
    event ApplicationRequestApproved(
        address indexed requestSender, uint256 indexed requestId, uint256 petId, address requestReviewer
    );

    event PetSucessfullyAdopted(uint256 indexed petId, address newOwner, address petPublisher);
    event PetSuccessfullyFostered(uint256 indexed petId, address currentFosterer, address petPublisher);

    event TipSent(address indexed sender, address indexed receiver, UserType forUserType);

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

    modifier onlyForNewUsers(address _sender) {
        if (registeredUsers[_sender] != UserType.NONE) {
            revert PetBridge__UserAlreadyRegistered();
        }
        _;
    }

    modifier onlyValidTipValues(uint256 _value) {
        if (_value == 0) {
            revert PetBridge__InvalidTipValue();
        }
        _;
    }

    modifier onlyValidPetIds(uint256 _petId, uint256 _totalPets) {
        if (_petId > _totalPets || _petId <= 0) {
            revert PetBridge__InvalidPetId();
        }
        _;
    }

    modifier onlyValidRequestIds(uint256 _requestId) {
        if (_requestId > s_totalRequests || _requestId <= 0) {
            revert PetBridge__InvalidRequestId();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @notice Publishes a pet for adoption/foster with the provided pet information.
     * @notice To publish a pet the user should be registered and also registered as Publisher.
     * @notice Also the publisher should send the appropriate publishing fee.
     * @dev Notice that currently the ADOPTION_AND_FOSTER pet necessity is not supported.
     * @param _name The Pet name.
     * @param _age The Pet age.
     * @param _description The Pet description.
     * @param _ipfsHash The ipfs image hash of the Pet.
     * @param _petType The type of pet you are publishing either Cat or Dog.
     * @param _publisherLocation The location of the publisher.
     * @param _petNecessity If the Pet is published for Adoption, Foster or both.
     */
    function publishPet(
        string memory _name,
        uint8 _age,
        string memory _description,
        string memory _ipfsHash,
        PetType _petType,
        string memory _publisherLocation,
        PetNecessity _petNecessity
    )
        external
        payable
        onlyRegisteredUsers
        onlyForCertainRegisteredUsers(UserType.PUBLISHER)
        onlyWithCorrectFee(msg.value, PET_PUBLISH_FEE, FeeActionType.PUBLISHING)
    {
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
        pet.ipfsImageHash = _ipfsHash;
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

    /**
     * @notice Registers a new user as Fosterer User.
     * @notice A Fosterer User is a user that can take pets on foster and apply to foster pets published.
     * @notice The user should send the appropriate fee to be registered as Fosterer.
     * @dev if the user is already registered in the system the function will revert.
     * @param _name The Fosterer User name.
     * @param _ipfsHash The ipfs image hash of the user.
     */
    function registerFostererUser(string memory _name, string memory _ipfsHash)
        external
        payable
        onlyWithCorrectFee(msg.value, FOSTERER_REGISTRATION_FEE, FeeActionType.REGISTERING_FOSTERER)
        onlyForNewUsers(msg.sender)
    {
        uint256 totalFostererUsers = s_totalFostererUsers += 1;

        UserFosterer storage user = fostererUsers[totalFostererUsers];
        user.id = totalFostererUsers;
        user.name = _name;
        user.ipfsImageHash = _ipfsHash;
        user._address = msg.sender;
        user.petsFosteredSuccessfully = 0;
        user.petsFosteredSuccessfully = 0;
        user.tipsReceived = 0;

        registeredUsers[msg.sender] = UserType.FOSTERER;
        userAddressToId[msg.sender] = totalFostererUsers;

        emit FostererUserAdded(totalFostererUsers, msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice Allows Dapp users to send Tips to appreciate the work of Fosterer Users.
     * @param _userId The Fosterer user ID assigned at the time of registration.
     */
    function tipFostererUser(uint256 _userId) external payable onlyValidTipValues(msg.value) {
        UserFosterer storage user = fostererUsers[_userId];
        _tipUser(user._address, msg.sender, msg.value, _userId, UserType.FOSTERER);
        user.tipsReceived += 1;
    }

    /**
     * @notice Allows Dapp users to send Tips to appreciate the work of Publisher Users.
     * @param _userId The Publisher user ID assigned at the time of registration.
     */
    function tipPublisherUser(uint256 _userId) external payable onlyValidTipValues(msg.value) {
        UserPublisher storage user = publisherUsers[_userId];
        _tipUser(user._address, msg.sender, msg.value, _userId, UserType.PUBLISHER);
        user.tipsReceived += 1;
    }

    /**
     * @notice Allows Users registered as Adopters to perform the action of applying to adopt a pet.
     * @notice This action is only allowed for users registered and also registered as Adopters.
     * @notice The user should send the appropriate fee to apply for the adoption.
     * @param _petId The Pet on Adoption ID assigned at the time of publishing.
     */
    function applyToAdoptPet(uint256 _petId)
        external
        payable
        onlyRegisteredUsers
        onlyForCertainRegisteredUsers(UserType.ADOPTER)
        onlyWithCorrectFee(msg.value, PET_ADOPTION_APPLICATION_FEE, FeeActionType.ADOPT_APPLICATION)
    {
        if (petAlreadyAdopted[_petId]) {
            revert PetBridge__PetAlreadyAdopted();
        }

        _helperPetApplication(_petId, s_totalPetsOnAdoption, RequestType.ADOPTION);
    }

    /**
     * @notice Allows Users registered as Fosterers to perform the action of applying to foster a pet.
     * @notice This action is only allowed for users registered and also registered as Fosterers.
     * @notice The user should send the appropriate fee to apply for the foster.
     * @param _petId The Pet on Foster ID assigned at the time of publishing.
     */
    function applyToFosterPet(uint256 _petId)
        external
        payable
        onlyRegisteredUsers
        onlyForCertainRegisteredUsers(UserType.FOSTERER)
        onlyWithCorrectFee(msg.value, PET_FOSTER_APPLICATION_FEE, FeeActionType.FOSTER_APPLICATION)
    {
        if (petAlreadyFostered[_petId]) {
            revert PetBridge__PetAlreadyFostered();
        }

        _helperPetApplication(_petId, s_totalPetsOnFoster, RequestType.FOSTER);
    }

    /**
     * @notice Registers a new user as Publisher User.
     * @notice A Publisher User is a user that can publish pets for adoption or foster.
     * @dev if the user is already registered in the system the function will revert.
     * @param _name The Publisher User name.
     * @param _ipfsHash The ipfs image hash of the user.
     */
    function registerPublisherUser(string memory _name, string memory _ipfsHash) external onlyForNewUsers(msg.sender) {
        uint256 totalPublisherUsers = s_totalPublisherUsers += 1;

        UserPublisher storage user = publisherUsers[totalPublisherUsers];
        user.id = totalPublisherUsers;
        user.name = _name;
        user.ipfsImageHash = _ipfsHash;
        user._address = msg.sender;
        user.petsAdoptedAfterPublish = 0;
        user.petsFosteredAfterPublish = 0;
        user.tipsReceived = 0;

        registeredUsers[msg.sender] = UserType.PUBLISHER;
        userAddressToId[msg.sender] = totalPublisherUsers;

        emit PublisherUserAdded(totalPublisherUsers, msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice Registers a new user as Adopter User.
     * @notice An Adopter User is a user that can only apply to adopt pets.
     * @dev if the user is already registered in the system the function will revert.
     * @param _name The Adopter User name.
     * @param _ipfsHash The ipfs image hash of the user.
     */
    function registerAdopterUser(string memory _name, string memory _ipfsHash) external onlyForNewUsers(msg.sender) {
        UserAdopter storage user = adopterUsers[msg.sender];
        user.name = _name;
        user.ipfsImageHash = _ipfsHash;
        user._address = msg.sender;
        user.rejectedAdoptionApplications = 0;

        emit AdopterUserAdded(msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice The Publisher user approves the request of adoption of an Adopter User.
     * @notice The fee paid for publishing is refunded to the Publisher.
     * @notice The fee paid for applying for adopting the pet is refunded to the Adopter.
     * @param _petId The Pet on Adoption ID assigned at the time of publishing.
     * @param _requestId The Request ID sent by the Adopter User to adopt the pet.
     */
    function approvePetAdoption(uint256 _petId, uint256 _requestId) external {
        address requestSender = _takeActionOverRequest(
            msg.sender,
            petsOnAdoption[_petId].petPublisher,
            _petId,
            s_totalPetsOnAdoption,
            _requestId,
            RequestAction.APPROVE
        );

        petAlreadyAdopted[_petId] = true;
        publisherUsers[userAddressToId[msg.sender]].petsAdoptedAfterPublish += 1;

        (bool publishFeeRefund,) = payable(msg.sender).call{value: PET_PUBLISH_FEE}("");
        if (!publishFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.PUBLISHING);
        }

        (bool adoptionApplicationFeeRefund,) = payable(requestSender).call{value: PET_ADOPTION_APPLICATION_FEE}("");
        if (!adoptionApplicationFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.ADOPT_APPLICATION);
        }

        emit ApplicationRequestApproved(requestSender, _requestId, _petId, msg.sender);
        emit PetSucessfullyAdopted(_petId, requestSender, msg.sender);
    }

    /**
     * @notice The Publisher user rejects the request of adoption of an Adopter User.
     * @notice The fee paid for applying for adopting the pet is refunded to the Adopter.
     * @param _petId The Pet on Adoption ID assigned at the time of publishing.
     * @param _requestId The Request ID sent by the Adopter User to adopt the pet.
     */
    function rejectPetAdoption(uint256 _petId, uint256 _requestId) external {
        address requestSender = _takeActionOverRequest(
            msg.sender,
            petsOnAdoption[_petId].petPublisher,
            _petId,
            s_totalPetsOnAdoption,
            _requestId,
            RequestAction.REJECT
        );

        adopterUsers[requestSender].rejectedAdoptionApplications += 1;

        (bool adoptApplicationFeeRefund,) = payable(requestSender).call{value: PET_ADOPTION_APPLICATION_FEE}("");
        if (!adoptApplicationFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.ADOPT_APPLICATION);
        }

        emit ApplicationRequestRejected(requestSender, _requestId, _petId, msg.sender);
    }

    /**
     * @notice The Publisher user approves the request of foster of an Fosterer User.
     * @notice The fee paid for publishing is refunded to the Publisher.
     * @notice The fee paid for applying for fostering the pet is refunded to the Fosterer.
     * @dev The petsFosteredSuccessfully attribute addition should be changed in a future contract version to be tracked by time
     *         with block.timestamp functionality and a attribute of timeThatNeedsFostering on the Pet struct tracked with chainlink oracle
     * @param _petId The Pet on Foster ID assigned at the time of publishing.
     * @param _requestId The Request ID sent by the Fosterer User to foster the pet.
     */
    function approvePetFoster(uint256 _petId, uint256 _requestId) external {
        address requestSender = _takeActionOverRequest(
            msg.sender,
            petsOnFoster[_petId].petPublisher,
            _petId,
            s_totalPetsOnFoster,
            _requestId,
            RequestAction.APPROVE
        );

        petAlreadyFostered[_petId] = true;
        publisherUsers[userAddressToId[msg.sender]].petsFosteredAfterPublish += 1;
        fostererUsers[userAddressToId[requestSender]].petsFosteredSuccessfully += 1;

        (bool publishFeeRefund,) = payable(msg.sender).call{value: PET_PUBLISH_FEE}("");
        if (!publishFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.PUBLISHING);
        }

        (bool fosterApplicationFeeRefund,) = payable(requestSender).call{value: PET_FOSTER_APPLICATION_FEE}("");
        if (!fosterApplicationFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.FOSTER_APPLICATION);
        }

        emit ApplicationRequestApproved(requestSender, _requestId, _petId, msg.sender);
        emit PetSucessfullyAdopted(_petId, requestSender, msg.sender);
    }

    /**
     * @notice The Publisher user rejects the request of foster of an Fosterer User.
     * @notice The fee paid for applying for fostering the pet is refunded to the Fosterer.
     * @param _petId The Pet on Foster ID assigned at the time of publishing.
     * @param _requestId The Request ID sent by the Fosterer User to foster the pet.
     */
    function rejectPetFoster(uint256 _petId, uint256 _requestId) external {
        address requestSender = _takeActionOverRequest(
            msg.sender, petsOnFoster[_petId].petPublisher, _petId, s_totalPetsOnFoster, _requestId, RequestAction.REJECT
        );

        fostererUsers[userAddressToId[requestSender]].rejectedFosterApplications += 1;

        (bool fosterApplicationFeeRefund,) = payable(requestSender).call{value: PET_FOSTER_APPLICATION_FEE}("");
        if (!fosterApplicationFeeRefund) {
            revert PetBridge__RefundTransferFailed(FeeActionType.FOSTER_APPLICATION);
        }

        emit ApplicationRequestRejected(requestSender, _requestId, _petId, msg.sender);
    }

    /**
     * @notice This helper functionality loops over the pet requests and takes action approving it or rejecting it depending on the parameters passed.
     * @dev Validates the pet ID by comparing it against the total number of pets and ensuring it is non-zero.
     * @dev Validates the request ID by comparing it against the total number of requests and ensuring it is non-zero.
     * @dev Validates that the msg.sender matches the pet publisher address.
     * @param _actionSender The action msg.sender.
     * @param _publisherAddress The publisher pet address.
     * @param _petId The Pet ID assigned at the time of publishing.
     * @param _totalPets The total number of pets available in the given category.
     * @param _requestId The Request ID sent by the user to apply for Fostering or Adopting a pet.
     * @return The address of the User that sent the application request.
     */
    function _takeActionOverRequest(
        address _actionSender,
        address _publisherAddress,
        uint256 _petId,
        uint256 _totalPets,
        uint256 _requestId,
        RequestAction _requestAction
    ) internal onlyValidPetIds(_petId, _totalPets) onlyValidRequestIds(_requestId) returns (address) {
        if (_actionSender != _publisherAddress) {
            revert PetBridge__OnlyPublisherCanTakeActionOverRequests();
        }

        Request[] storage requests = petRequests[_petId];
        address requestSender;

        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].requestId == _requestId) {
                if (_requestAction == RequestAction.APPROVE) {
                    requests[i].isRequestApproved = true;
                } else if (_requestAction == RequestAction.REJECT) {
                    requests[i].isRequestRejected = true;
                } else {
                    revert PetBridge__InvalidRequestAction();
                }
                requestSender = requests[i].userThatSentRequest;
                break;
            }
        }

        return requestSender;
    }

    /**
     * @notice Handles a pet request by checking for duplicate or already processed requests,
     *         and adds a new request to the pet's list of requests if valid.
     * @dev Validates the pet ID by comparing it against the total number of pets and ensuring it is non-zero.
     *      Reverts if the sender has already submitted a pending, approved, or rejected request for the same pet.
     * @param _petId The ID of the pet to which the request is being made.
     * @param _totalPets The total number of pets available in the given category.
     * @param _requestType The type of request being made: either Adoption or Foster.
     */
    function _helperPetApplication(uint256 _petId, uint256 _totalPets, RequestType _requestType)
        internal
        onlyValidPetIds(_petId, _totalPets)
    {
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

    /**
     * @notice Handles the tip functionality sending the ETH passed to the recipient wallet.
     * @param _userAddr The address of the user that receives the tip.
     * @param _tipSender The address of the user that sends the tip.
     * @param _tipSent The value sent as tip.
     * @param _userId The ID of the user assigned at the time of registration.
     * @param _expectedType The user registration type.
     */
    function _tipUser(address _userAddr, address _tipSender, uint256 _tipSent, uint256 _userId, UserType _expectedType)
        internal
    {
        UserType actualType = registeredUsers[_userAddr];
        if (actualType != _expectedType) {
            revert PetBridge__InvalidUserId(_userId, actualType);
        }

        if (_userAddr == _tipSender) {
            revert PetBridge__YouCannotTipYourself();
        }

        (bool success,) = payable(_userAddr).call{value: _tipSent}("");
        if (!success) {
            revert PetBridge__TipTransferFailed();
        }

        emit TipSent(msg.sender, _userAddr, _expectedType);
    }

    /**
     * @notice Gets all the valid Pet requests with the associated Pet ID and discards the already approved and rejected ones.
     * @param _petId The Pet ID assigned at the time of publishing.
     * @return The valid Pet requests.
     */
    function getPetValidRequests(uint256 _petId) external view returns (Request[] memory) {
        Request[] storage requests = petRequests[_petId];
        uint256 count = 0;

        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].isRequestApproved && !requests[i].isRequestRejected) {
                count++;
            }
        }

        Request[] memory currentRequests = new Request[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].isRequestApproved && !requests[i].isRequestRejected) {
                currentRequests[index] = requests[i];
                index++;
            }
        }

        return currentRequests;
    }

    /**
     * @notice Gets the Pet information associated with the given ID.
     * @param _id The Pet on Adoption ID assigned at the time of publishing.
     * @return The Pet information.
     */
    function getPetOnAdoption(uint256 _id) external view returns (Pet memory) {
        return petsOnAdoption[_id];
    }

    /**
     * @notice Checks whether the pet with the given ID has already been adopted.
     * @param _id The ID of the pet assigned when it was listed for adopting.
     * @return True if the pet has already been adopted, false otherwise.
     */
    function isPetAlreadyAdopted(uint256 _id) external view returns (bool) {
        return petAlreadyAdopted[_id];
    }

    /**
     * @notice Gets the Pet information associated with the given ID.
     * @param _id The Pet on Foster ID assigned at the time of publishing.
     * @return The Pet information.
     */
    function getPetOnFoster(uint256 _id) external view returns (Pet memory) {
        return petsOnFoster[_id];
    }

    /**
     * @notice Checks whether the pet with the given ID is currently being fostered.
     * @param _id The ID of the pet assigned when it was listed for fostering.
     * @return True if the pet is already being fostered, false otherwise.
     */
    function isPetAlreadyFostered(uint256 _id) external view returns (bool) {
        return petAlreadyFostered[_id];
    }

    /**
     * @notice Gets the UserFosterer information associated with the given ID.
     * @param _id The Fosterer user ID assigned at the time of registration.
     * @return The UserFosterer information.
     */
    function getFostererUser(uint256 _id) external view returns (UserFosterer memory) {
        return fostererUsers[_id];
    }

    /**
     * @notice Gets the UserPublisher information associated with the given ID.
     * @param _id The Publisher user ID assigned at the time of registration.
     * @return The UserPublisher information.
     */
    function getPublisherUser(uint256 _id) external view returns (UserPublisher memory) {
        return publisherUsers[_id];
    }

    /**
     * @notice Gets the UserAdopter information associated with the given ADDRESS.
     * @param _address The Adopter user address assigned at the time of registration.
     * @return The UserAdopter information.
     */
    function getAdopterUser(address _address) external view returns (UserAdopter memory) {
        return adopterUsers[_address];
    }

    /**
     * @notice Returns the address of the contract owner.
     * @return The owner's address.
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Returns the total number of pets published for adoption.
     * @return The total pets on adoption as uint256.
     */
    function getTotalPetsOnAdoption() external view returns (uint256) {
        return s_totalPetsOnAdoption;
    }

    /**
     * @notice Returns the total number of pets published for fostering.
     * @return The total pets on foster as uint256.
     */
    function getTotalPetsOnFoster() external view returns (uint256) {
        return s_totalPetsOnFoster;
    }

    /**
     * @notice Returns the total number of fosterer users registered.
     * @return The total fosterer users as uint256.
     */
    function getTotalFostererUsers() external view returns (uint256) {
        return s_totalFostererUsers;
    }

    /**
     * @notice Returns the total number of publisher users registered.
     * @return The total publisher users as uint256.
     */
    function getTotalPublisherUsers() external view returns (uint256) {
        return s_totalPublisherUsers;
    }
}

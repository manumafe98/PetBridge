// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {PetBridge} from "../contracts/PetBridge.sol";
import {Types} from "../contracts/Types.sol";

contract PetBridgeTest is Test {
    PetBridge petBridge;
    address public user = makeAddr("USER");
    address public tipper = makeAddr("TIPPER");
    address public adopter = makeAddr("ADOPTER");

    string private constant USER_NAME = "Pepe";
    string private constant USER_IPFS_HASH = "abcd";

    string private constant PET_NAME = "Mishi";
    string private constant PET_DESCRIPTION = "He likes to bite";
    string private constant PET_PUBLISHER_LOCATION = "Mendoza";
    string private constant PET_IPFS_HASH = "abcd";
    Types.PetType private constant PET_TYPE = Types.PetType.CAT;
    Types.PetNecessity private constant PET_NECESSITY = Types.PetNecessity.ADOPTION;
    uint8 private constant PET_AGE = 10;

    uint256 private constant MINIMUM_FEE = 0.001 ether;
    uint256 private constant INVALID_FEE = 0.0001 ether;

    event PetOnAdoptionAdded(
        uint256 indexed id, string name, Types.PetType petType, address petPublisher, string publisherLocation
    );
    event PetOnFosterAdded(
        uint256 indexed id, string name, Types.PetType petType, address petPublisher, string publisherLocation
    );

    event FostererUserAdded(uint256 indexed id, address indexed _address, string name, string ipfsImageHash);
    event PublisherUserAdded(uint256 indexed id, address indexed _address, string name, string ipfsImageHash);
    event AdopterUserAdded(address indexed _address, string name, string ipfsImageHash);

    event RequestCreated(
        uint256 indexed petId, uint256 indexed requestId, address indexed userThatSentRequest, Types.RequestType requestType
    );
    event ApplicationRequestRejected(
        address indexed requestSender, uint256 indexed requestId, uint256 petId, address requestReviewer
    );
    event ApplicationRequestApproved(
        address indexed requestSender, uint256 indexed requestId, uint256 petId, address requestReviewer
    );

    event PetSucessfullyAdopted(uint256 indexed petId, address newOwner, address petPublisher);
    event PetSuccessfullyFostered(uint256 indexed petId, address currentFosterer, address petPublisher);

    event TipSent(address indexed sender, address indexed receiver, Types.UserType forUserType);

    function setUp() public {
        vm.startBroadcast(msg.sender);
        petBridge = new PetBridge();
        vm.stopBroadcast();

        vm.deal(user, 10 ether);
        vm.deal(tipper, 1 ether);
        vm.deal(adopter, 1 ether);
    }

    function testOwner() public view {
        address expectedOwner = petBridge.getOwner();
        assertEq(expectedOwner, msg.sender);
    }

    function testRegisterPublisherUser() public {
        vm.prank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);

        uint256 currentTotalPublisherUsers = petBridge.getTotalPublisherUsers();
        Types.UserPublisher memory publisher = petBridge.getPublisherUser(1);
        Types.UserType userType = petBridge.getRegisteredUserType(user);
        uint256 userId = petBridge.getUserIdByAddress(user);

        assertEq(currentTotalPublisherUsers, 1);
        assertEq(publisher.name, USER_NAME);
        assertEq(publisher.ipfsImageHash, USER_IPFS_HASH);
        assertEq(uint8(userType), uint8(Types.UserType.PUBLISHER));
        assertEq(userId, 1);
    }

    function testRegisterUserAlreadyRegistered() public {
        vm.prank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);

        vm.prank(user);
        vm.expectRevert(PetBridge.PetBridge__UserAlreadyRegistered.selector);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
    }

    function testRegisterUserEmitsEvent() public {
        vm.prank(user);
        vm.expectEmit();
        emit PublisherUserAdded(1, user, USER_NAME, USER_IPFS_HASH);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
    }

    function testPublishPetOnAdoption() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
        vm.stopPrank();

        uint256 currentPetsOnAdoption = petBridge.getTotalPetsOnAdoption();
        Types.Pet memory pet = petBridge.getPetOnAdoption(1);

        assertEq(currentPetsOnAdoption, 1);
        assertEq(pet.name, PET_NAME);
    }

    function testPublishPetOnAdoptionWithInvalidFee() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        vm.expectRevert(abi.encodeWithSelector(PetBridge.PetBridge__InsufficientFee.selector, Types.FeeActionType.PUBLISHING));
        petBridge.publishPet{value: INVALID_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
        vm.stopPrank();
    }

    function testTryPublishPetWithAUnregisteredUser() public {
        vm.prank(user);
        vm.expectRevert(PetBridge.PetBridge__InvalidActionForUnregisteredUser.selector);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
    }

    function testTryToPublishPetWithNonPublisherUser() public {
        vm.startPrank(user);
        petBridge.registerAdopterUser(USER_NAME, USER_IPFS_HASH);
        vm.expectRevert(PetBridge.PetBridge__UnavailableActionForCurrentUserRegistration.selector);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
    }

    function testPublishPetOnAdoptionEmitsEvent() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        vm.expectEmit();
        emit PetOnAdoptionAdded(1, PET_NAME, PET_TYPE, user, PET_PUBLISHER_LOCATION);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
    }

    function testRegisterFostererUser() public {
        vm.prank(user);
        petBridge.registerFostererUser{value: MINIMUM_FEE}(USER_NAME, USER_IPFS_HASH);

        uint256 currentTotalFostererUsers = petBridge.getTotalFostererUsers();
        Types.UserFosterer memory fosterer = petBridge.getFostererUser(1);
        Types.UserType userType = petBridge.getRegisteredUserType(user);
        uint256 userId = petBridge.getUserIdByAddress(user);

        assertEq(currentTotalFostererUsers, 1);
        assertEq(fosterer.name, USER_NAME);
        assertEq(fosterer.ipfsImageHash, USER_IPFS_HASH);
        assertEq(uint8(userType), uint8(Types.UserType.FOSTERER));
        assertEq(userId, 1);
    }

    function testRegisterFostererUserWithInvalidFee() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(PetBridge.PetBridge__InsufficientFee.selector, Types.FeeActionType.REGISTERING_FOSTERER));
        petBridge.registerFostererUser{value: INVALID_FEE}(USER_NAME, USER_IPFS_HASH);
    }

    function testRegisterFostererUserEmitsEvent() public {
        vm.prank(user);
        vm.expectEmit();
        emit FostererUserAdded(1, user, USER_NAME, USER_IPFS_HASH);
        petBridge.registerFostererUser{value: MINIMUM_FEE}(USER_NAME, USER_IPFS_HASH);
    }

    function testTipPublisherUser() public {
        vm.prank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        uint256 userPreviousBalance = address(user).balance;
        uint256 userPreviousTipsReceived = petBridge.getPublisherUser(1).tipsReceived;

        vm.prank(tipper);
        petBridge.tipPublisherUser{value: 0.05 ether}(user);

        uint256 userCurrentBalance = address(user).balance;
        uint256 userCurrentTipsReceived = petBridge.getPublisherUser(1).tipsReceived;

        assertGt(userCurrentTipsReceived, userPreviousTipsReceived);
        assertGt(userCurrentBalance, userPreviousBalance);
    }

    function testTipPublisherUserWithInvalidTipValue() public {
        vm.prank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);

        vm.prank(tipper);
        vm.expectRevert(PetBridge.PetBridge__InvalidTipValue.selector);
        petBridge.tipPublisherUser{value: 0 ether}(user);
    }

    function testTryTipYourselfFails() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        vm.expectRevert(PetBridge.PetBridge__YouCannotTipYourself.selector);
        petBridge.tipPublisherUser{value: 1 ether}(user);
    }

    function testTryTipAnAdopterUser() public {
        vm.prank(user);
        petBridge.registerAdopterUser(USER_NAME, USER_IPFS_HASH);

        vm.prank(tipper);
        vm.expectRevert(abi.encodeWithSelector(PetBridge.PetBridge__InvalidUserType.selector, user, Types.UserType.ADOPTER, Types.UserType.PUBLISHER));
        petBridge.tipPublisherUser{value: 1 ether}(user);
    }

    function testApplyToAdoptPet() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
        vm.stopPrank();

        vm.startPrank(adopter);
        petBridge.registerAdopterUser(USER_NAME, USER_IPFS_HASH);
        petBridge.applyToAdoptPet{value: MINIMUM_FEE}(1);
        vm.stopPrank();

        Types.Request[] memory validPetRequests = petBridge.getPetValidRequests(1);

        assertEq(validPetRequests.length, 1);
        assertEq(validPetRequests[0].requestId, 1);
        assertEq(validPetRequests[0].petId, 1);
        assertEq(validPetRequests[0].userThatSentRequest, adopter);
        assertEq(validPetRequests[0].isRequestApproved, false);
        assertEq(validPetRequests[0].isRequestRejected, false);
    }

    function testApprovePetAdoption() public {
        vm.startPrank(user);
        petBridge.registerPublisherUser(USER_NAME, USER_IPFS_HASH);
        petBridge.publishPet{value: MINIMUM_FEE}(PET_NAME, PET_AGE, PET_DESCRIPTION, PET_IPFS_HASH, PET_TYPE, PET_PUBLISHER_LOCATION, PET_NECESSITY);
        vm.stopPrank();

        vm.startPrank(adopter);
        petBridge.registerAdopterUser(USER_NAME, USER_IPFS_HASH);
        petBridge.applyToAdoptPet{value: MINIMUM_FEE}(1);
        vm.stopPrank();

        uint256 userPreviousBalance = user.balance;
        uint256 adopterPreviousBalance = adopter.balance;
        Types.Request[] memory previousRequests = petBridge.getPetValidRequests(1);

        vm.startPrank(user);
        petBridge.approvePetAdoption(1, 1);

        Types.Request[] memory currentRequests = petBridge.getPetValidRequests(1);
        Types.Request memory request = petBridge.getPetRequestById(1, 1);
        uint256 userCurrentBalance = user.balance;
        uint256 adopterCurrentBalance = adopter.balance;
        Types.UserPublisher memory publisher = petBridge.getPublisherUser(1);
        bool isPetAlreadyAdopter = petBridge.isPetAlreadyAdopted(1);

        assertGt(userCurrentBalance, userPreviousBalance);
        assertGt(adopterCurrentBalance, adopterPreviousBalance);
        assertGt(previousRequests.length, currentRequests.length);
        assertEq(publisher.petsAdoptedAfterPublish, 1);
        assertTrue(isPetAlreadyAdopter);
        assertTrue(request.isRequestApproved);
    }
}
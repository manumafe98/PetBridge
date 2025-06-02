// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library Types {
    struct UserPublisher {
        uint256 id;
        string name;
        string ipfsImageHash;
        address _address;
        uint256 petsAdoptedAfterPublish;
        uint256 petsFosteredAfterPublish;
        uint256 tipsReceived;
    }

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
}

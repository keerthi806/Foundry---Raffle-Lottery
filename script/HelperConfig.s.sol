// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import{Script} from "forge-std/Script.sol";
import{VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import{LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /*VRF Mock Values */
    uint96 public MOCK_BASE_FEE= 0.25 ether;
    uint96 public MOCK_GAS_PRICE = 1e9;
    //LINK / ETH Price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants,Script{

    error HelperConfig__InvalidChainId();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public localNetwrokConfig;
    mapping(uint256 chainId=>NetworkConfig) public netwrokconfigs;

    constructor(){
        netwrokconfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaETHConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(netwrokconfigs[chainId].vrfCoordinator!=address(0)){
            return netwrokconfigs[chainId];
        }
        else if(chainId==LOCAL_CHAIN_ID){
            return getOrCreateAnvilEthConfig();
        }
        else{
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaETHConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30, // 30seconds
            vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 70097830973843138686911237926673261072500468166552728524968254310355596793457, 
            callbackGasLimit:500000,
            link : 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account : 0x6981cF42B1cf0fcc9Ca8422A29a0EdDe0059f253
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        // check to see if we set a active network config
        if(localNetwrokConfig.vrfCoordinator != address(0)){
            return localNetwrokConfig;
        } 

        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock (MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UINT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
    
        localNetwrokConfig = NetworkConfig({
            entranceFee : 0.01 ether, 
            interval : 30, 
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,// doesn't matter(MOCKS)
            subscriptionId:0, 
            callbackGasLimit:500000, // to be fixed
            link : address(linkToken),
            account : 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // from Base.sol / Default address
         });
        return localNetwrokConfig;
    }
}
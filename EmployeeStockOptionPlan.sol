 
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Stock Options Contract
 * @dev This contract manages the issuance of stock options to employees with a vesting period
 */
 
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EmployeeStockOptionPlan is ReentrancyGuard  {

  using SafeMath for uint;

/*
 * @dev Struct containing information about an employee's vesting schedule
 * @param cliff The date on which the vesting schedule begins with reference to block.timestamp (Epoch time)
 * @param duration The length of the vesting period with reference to block.timestamp
 * @param percent The percentage of vested stock options available to the employee
 */

    struct VestingSchedule {
        uint256 cliff;
        uint256 duration;
        uint256 percent;
    }
   
   

    mapping(address => uint256) public vested;
    mapping(address => uint256) public exercised;
    mapping(address => VestingSchedule) public vestingSchedules;
    address public owner;
    
    /*
 * @dev Event emitted when stock options are transferred from one employee to another
 * @param employeeOwner The previous owner of the options
 * @param employeeReceiver The new owner of the options
 * @param optionsTransfered The number of options being transferred
 */
    event StockOptionsTransfered(address indexed employeeOwner, address indexed  employeeReceiver , uint256 optionsTransfered);
    
    
    /*
 * @dev Event emitted when stock options are granted to an employee
 * @param employee The employee receiving the options
 * @param optionsGranted The number of options being granted
 */
    event StockOptionsGranted(address indexed employee, uint256 optionsGranted);
   
   /*
 * @dev Event emitted when a vesting schedule is set for an employee
 * @param employee The employee for whom the vesting schedule is set
 * @param cliff The date on which the vesting schedule begins
 * @param duration The length of the vesting period
 * @param percent The percentage of vested stock options available to the employee
 */
    event VestingScheduleSet(address indexed employee, uint256 cliff, uint256 duration, uint256 percent);
    
    
    /*
 * @dev Event emitted when a stock option is exercised by an employee
 * @param employee The employee exercising the option
 * @param optionsExercised The number of options being exercised
 */
    event OptionsExercised(address indexed employee, uint256 optionsExercised);


 /**
     * @dev Initializes the contract and sets the owner to the deployer's address
     */

    constructor() {
        owner = msg.sender;
    }
    
 modifier isOwner() {
      // Ensure that only the owner of the contract can call this function
     require(msg.sender == owner, "Only the owner can call this function");
     _;
 }

modifier hasVestingSchedule(address employee) {
    // Ensure that the given employee has a vesting schedule set
     require(vestingSchedules[employee].duration > 0, "No vesting schedule has been set for this employee");
     _;

}


modifier employeeOptionAcess(address employee) {
    // Ensure that the employee has vested options available and the vesting date has been reached
     
      uint256 options = vested[tx.origin].sub(exercised[tx.origin]) ;

        require(options > 0, "No vested options available to exercise");
        require(block.timestamp >= vestingSchedules[tx.origin].cliff, "Options are not yet vested");
        uint256 exerciseDate = vestingSchedules[tx.origin].cliff.add(vestingSchedules[tx.origin].duration);
       require(block.timestamp >= exerciseDate, "Options are mature yet vested");

 
     _;
}

    
    /**
     * @dev Grant stock options to an employee
     * @param employee The employee's address
     * @param options The number of options to grant
     * Requirements:
     * - Only the contract owner can call this function
     * - owner must have created a stock option plan for the employee before granting the stock options to employee
     */
    function grantStockOptions(address employee, uint256 options) external  isOwner() nonReentrant {
        require(vestingSchedules[employee].cliff > 0, "No vesting schedule  has been created for this employee");
     
        vested[employee]  = vested[employee].add(options);

        emit StockOptionsGranted(employee, options);
    }
    

       
    /**
     * @dev Set the vesting schedule for an employee's stock options
     * @param employee The employee's address
     * @param cliff The vesting cliff date (Unix timestamp)
     * @param duration The vesting duration (in seconds)
     * @param percent The percentage of options that vest per interval (0-100)
     * Requirements:
     * - Only the contract owner can call this function
     */

    function setVestingSchedule(address employee, uint256 cliff, uint256 duration, uint256 percent) external  isOwner() nonReentrant{
       vestingSchedules[employee] = VestingSchedule(cliff, duration, percent);
        emit VestingScheduleSet(employee, cliff, duration, percent);
    }
    

  /**
 * @dev A function to exercise vested stock options for an employee.
 * Employee can exercise only the options that have been vested but not yet exercised.
 */

    function exerciseOptions() external  employeeOptionAcess(tx.origin) nonReentrant {
        uint256 options = vested[tx.origin].sub(exercised[tx.origin]) ;


            exercised[tx.origin] =   exercised[tx.origin].add(options)  ;
            emit OptionsExercised(tx.origin, options);
    }
    

    /**
 * @dev Gets the number of vested stock options for an employee.
 * @param employee The address of the employee to query.
 * @return An uint256 representing the number of vested stock options for an employee.
 */

    function getVestedOptions(address employee) public view returns (uint256) {
        return vested[employee];
    }
    

/**
 * @dev Gets the number of exercised stock options for an employee.
 * @param employee The address of the employee to query.
 * @return An uint256 representing the number of exercised stock options for an employee.
 */
    function getExercisedOptions(address employee) public view returns (uint256) {
    return exercised[employee];
}


/**
 * @dev Transfer one vested stock option from one employee to another.
 * The caller of the function must be the employee who owns vested stock options.
 * @param employeeReceiver The address of the employee who will receive the stock option.
 */
function Transfer(address employeeReceiver) external employeeOptionAcess(tx.origin)  nonReentrant {

 
uint optionToTransfer = vested[tx.origin].sub(1);
 vested[tx.origin] = optionToTransfer;
 vested[employeeReceiver] = vested[employeeReceiver].add(1);
vestingSchedules[employeeReceiver] = vestingSchedules[tx.origin];

emit StockOptionsTransfered( tx.origin, employeeReceiver,  optionToTransfer);

}



}
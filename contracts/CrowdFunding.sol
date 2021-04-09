// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CrowdFunding {
  
  // 投资人结构定义
  struct Funder {
    address payable addr;   // 投资人的地址
    uint amount;            // 出资数额
  }

  // 资金使用请求结构定义
  struct Use {
    string info;                     // 使用请求的说明
    uint goal;                       // 使用请求的数额
    uint agreeAmount;                // 目前的同意数额
    uint disagree;                   // 目前的不同意数额
    bool over;                       // 请求是否结束
    mapping(uint => uint) agree;     // 出资人是否同意 0: 还没决定，1：同意，2：不同意
  }

  // 众筹项目的结构定义
  struct Funding {
    address payable initiator;       // 发起人
    string title;                    // 项目标题
    string info;                     // 项目简介
    uint goal;                       // 目标金额
    uint endTime;                    // 众筹结束时间

    bool success;                    // 众筹是否成功，成功则 amount 含义为项目剩余的钱

    uint amount;                     // 当前已经筹集到的金额
    uint numFunders;                 // 投资记录数量
    uint numUses;                    // 使用请求数量
    mapping(uint => Funder) funders; // 投资记录具体信息
    mapping(uint => Use) uses;       // 所有的使用请求
  }

  uint public numFundings;                  // 众筹项目数量
  mapping(uint => Funding) public fundings; // 所有的众筹项目

  /**
   * 发起众筹项目
   * @param initiator 发起人
   * @param title 项目标题
   * @param info 项目简介
   * @param goal 目标金额
   * @param endTime 结束时间
   */
  function newFunding(address payable initiator, string memory title, string memory info, uint goal, uint endTime) public returns(uint) {
    require(endTime > block.timestamp);

    numFundings = numFundings + 1;  // 众筹项目数量加1
    Funding storage f = fundings[numFundings];
    f.initiator = initiator;
    f.title = title;
    f.info = info;
    f.goal = goal;
    f.endTime = endTime;
    f.success = false;
    f.amount = 0;
    f.numFunders = 0;
    f.numUses = 0;
    
    return numFundings;
  }
  
  /**
   * 参与众筹
   * @param ID 参与的众筹项目id（即众筹的标识号）
   */
  function contribute(uint ID) public payable {
    // 贡献的钱必须大于0，不能超过差额
    // msg.data  完整的calldata
    // msg.value 随消息发送的wei的数量
    // msg.sender 消息发送者
    require(msg.value > 0 && msg.value <= fundings[ID].goal - fundings[ID].amount);
    // 时间上必须还没结束
    require(fundings[ID].endTime > block.timestamp);
    // 必须是未完成的众筹
    require(fundings[ID].success == false);

    Funding storage f = fundings[ID];
    f.amount += msg.value;
    f.numFunders = f.numFunders + 1;
    f.funders[f.numFunders].addr = msg.sender;
    f.funders[f.numFunders].amount = msg.value;
    // 考虑本项目是否达成目标
    f.success = f.amount >= f.goal;
  }

  /**
   * 申请退款
   * @param ID 申请退款的众筹项目id
   */
  function returnMoney(uint ID) public {
    // 众筹项目必须存在且并未众筹成功
    require(ID <= numFundings && ID >= 1); 
    require(fundings[ID].success == false);

    // 获取众筹项目进行退款
    Funding storage f = fundings[ID];
    for(uint i=1; i<=f.numFunders; i++)
      if(f.funders[i].addr == msg.sender) { // 确认申请退款者参与过众筹
        f.funders[i].addr.transfer(f.funders[i].amount);  // 退款
        f.funders[i].amount = 0;
        f.amount -= f.funders[i].amount;
      }
  }
  /**
   * 新的资金使用请求
   * @param ID 申请使用资金的项目id
   * @param goal 使用请求资金数额
   * @param info 使用请求的描述信息
   */
  function newUse(uint ID, uint goal, string memory info) public {
    // 所在众筹项目必须存在 && 已经众筹成功 && 目标金额不多于众筹金额 && 提款者为众筹发起人
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].success == true);
    require(goal <= fundings[ID].amount);
    require(msg.sender == fundings[ID].initiator);

    Funding storage f = fundings[ID];
    f.numUses = f.numUses + 1; // 使用请求数目加1
    f.uses[f.numUses].info = info;
    f.uses[f.numUses].goal = goal;
    f.uses[f.numUses].agreeAmount = 0;
    f.uses[f.numUses].disagree = 0;
    f.uses[f.numUses].over = false;
    f.amount = f.amount - goal;
  }

  /**
   * 同意使用请求
   * @param ID 众筹项目id
   * @param useID 使用请求id
   * @param agree 是否同意请求
   */
  function agreeUse(uint ID, uint useID, bool agree) public {
    // 众筹项目存在 && 使用请求存在 && 使用请求未结束
    require(ID <= numFundings && ID >= 1);
    require(useID <= fundings[ID].numUses && useID >= 1);
    require(fundings[ID].uses[useID].over == false);

    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == msg.sender) {  // 确定审判者参与了众筹项目
        if(fundings[ID].uses[useID].agree[i] == 1) { // 出资人同意了
          fundings[ID].uses[useID].agreeAmount -= fundings[ID].funders[i].amount;
        } else if(fundings[ID].uses[useID].agree[i] == 2) { // 出资人不同意
          fundings[ID].uses[useID].disagree -= fundings[ID].funders[i].amount;
        }
        if(agree) { // 同意
          fundings[ID].uses[useID].agreeAmount += fundings[ID].funders[i].amount;
          fundings[ID].uses[useID].agree[i] = 1;
        }
        else { // 不同意
          fundings[ID].uses[useID].disagree += fundings[ID].funders[i].amount;
          fundings[ID].uses[useID].agree[i] = 2;
        }
      }
    checkUse(ID, useID); // 检查使用请求是否已经结束
  }

  /**
   * 检查使用请求是否结束
   * @param ID 众筹项目id
   * @param useID 使用请求id
   */
  function checkUse(uint ID, uint useID) public {
    require(ID <= numFundings && ID >= 1);
    require(fundings[ID].uses[useID].over == false);

    if(fundings[ID].uses[useID].agreeAmount >= fundings[ID].goal / 2) { // 同意数额大于等于目标金额的一半则结束并转账
      fundings[ID].uses[useID].over = true;
      fundings[ID].initiator.transfer(fundings[ID].uses[useID].goal);
    }
    if(fundings[ID].uses[useID].disagree > fundings[ID].goal / 2) {
      fundings[ID].amount = fundings[ID].amount + fundings[ID].uses[useID].goal;
      fundings[ID].uses[useID].over = true;
    }
  }

  /**
   * 返回使用请求数目
   * @param ID 众筹项目ID
   */
  function getUseLength(uint ID) public view returns (uint) {
    require(ID <= numFundings && ID >= 1);

    return fundings[ID].numUses;
  }

  /**
   * 根据众筹项目ID、使用请求ID和账户来获取使用请求的具体信息
   * ID 众筹项目id
   * useID 使用请求id
   * addr 用户的地址
   */
  function getUse(uint ID, uint useID, address addr) public view returns (string memory, uint, uint, uint, bool, uint) {
    require(ID <= numFundings && ID >= 1);
    require(useID <= fundings[ID].numUses && useID >= 1);

    Use storage u = fundings[ID].uses[useID];
    uint agree = 0;
    for(uint i=1; i<=fundings[ID].numFunders; i++)
      if(fundings[ID].funders[i].addr == addr) {
        agree = fundings[ID].uses[useID].agree[i];
        break;
      }
    
    // 返回使用请求的信息及该用户是否同意请求
    return (u.info, u.goal, u.agreeAmount, u.disagree, u.over, agree);  
  }

  /**
   * 返回合约的余额
   */
  function getBalance() public view returns (uint) {
    return address(this).balance;
  }
  
  /**
   * 获取指定用户对指定众筹项目的出资数额
   * addr 指定用户
   * ID 指定的众筹项目id
   */
  function getMyFundings(address addr, uint ID) public view returns (uint) {
      uint res = 0;
      for(uint i=1; i<=fundings[ID].numFunders; i++) {
          if(fundings[ID].funders[i].addr == addr)
            res += fundings[ID].funders[i].amount;
      }
      return res;
  } 
}
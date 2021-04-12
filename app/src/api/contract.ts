import Web3 from 'web3'
//@ts-ignore
import CrowdFunding from './CrowdFunding.json'

//@ts-ignore
const web3 = new Web3(window.ethereum);
// 创建合约实例
const contract = new web3.eth.Contract(CrowdFunding.abi, '0xfab145C64ca079C33400F0d8eA0469f0f6586C5C');
// const contract = new web3.eth.Contract(CrowdFunding.abi, CrowdFunding.address);

function addListener(fn: Function) {
    //@ts-ignore
    ethereum.on('accountsChanged', fn) // 账户改变时触发fn函数
}

export declare interface Funding {
    index: number,
    title: string,
    info: string,
    hash: string,
    goal: number,
    endTime: number,
    initiator: string,
    over: boolean,
    success: boolean,
    amount: number,
    numFunders: number,
    numUses: number,
    myAmount?: number
}

export declare interface Use {
    index: number,
    info: string,
    goal: string,
    agreeAmount: string,
    disagree: string,
    over: boolean,
    agree: number // 0: 没决定，1同意，2不同意
}

// 要求浏览器MetaMask授权应用登录并获取其账号
async function authenticate() {
    //@ts-ignore
    await window.ethereum.enable();
}

// 获取当前MetaMask登录的账户
async function getAccount() {
    return (await web3.eth.getAccounts())[0];
}

// 获取当前合约中的所有众筹信息
async function getAllFundings() : Promise<Funding[]> {
    const length = await contract.methods.numFundings().call();
    const result = []
    for(let i=1; i<=length; i++)
        result.push(await getOneFunding(i));
    return result;
}

// 获取指定的众筹信息
async function getOneFunding(index:number) : Promise<Funding> {
    const data = await contract.methods.fundings(index).call();
    data.goal = Web3.utils.fromWei(data.goal, 'ether')
    data.amount = Web3.utils.fromWei(data.amount, 'ether')

    return {index, ...data}
}

// 获取对指定众筹项目的出资额
async function getMyFundingAmount(index:number) : Promise<number> {
    const account = await getAccount();
    return parseInt(Web3.utils.fromWei(await contract.methods.getMyFundings(account, index).call(), 'ether'));
}

// 获取与当前账户相关的所有众筹项目的信息
async function getMyFundings() : Promise<{init: Funding[], contr: Funding[]}> {
    const account = await getAccount(); // 获取当前账户
    const all = await getAllFundings(); // 获取所有众筹信息
    const result : {
        init: Funding[],
        contr: Funding[]
    } = {
        init: [],
        contr: []
    };
    for(let funding of all) {
        const myAmount = await getMyFundingAmount(funding.index); // 获取当前账户对指定众筹项目的参与金额
        if(funding.initiator == account) { // 本账户发起的众筹
            result.init.push({
                myAmount,
                ...funding
            })
        }
        if(myAmount != 0) { // 本账户参与的众筹
            result.contr.push({
                myAmount,
                ...funding
            })
        }
    }
    return result;
}

// 参与众筹
async function contribute(id:number, value:number) {
    return await contract.methods.contribute(id).send({from: await getAccount(), value: Web3.utils.toWei(value.toString(10), 'ether')});
}

// 发起众筹
async function newFunding(account:string, title:string, info:string, hash:string, amount:number, seconds:number) {
    return await contract.methods.newFunding(account, title, info, hash, Web3.utils.toWei(amount.toString(10), 'ether'), seconds).send({
        from: account,
        gas: 1000000
    });
}

// 获取所有指定众筹项目的使用请求
async function getAllUse(id:number) : Promise<Use[]> {
    const length = await contract.methods.getUseLength(id).call(); // 获取指定众筹项目的使用请求数量
    const account = await getAccount();
    const rusult : Use[] = []
    for(let i=1; i<=length; i++) {
        const use = await contract.methods.getUse(id, i, account).call();
        rusult.push({
            index: i,
            info: use[0],
            goal: Web3.utils.fromWei(use[1], 'ether'),
            agreeAmount: Web3.utils.fromWei(use[2], 'ether'),
            disagree: Web3.utils.fromWei(use[3], 'ether'),
            over: use[4],
            agree: use[5]
        });
    }
    return rusult;
}

// 同意使用请求
async function agreeUse(id:number, useID: number, agree:boolean) {
    const accont = await getAccount();
    return await contract.methods.agreeUse(id, useID, agree).send({
        from: accont,
        gas: 1000000
    })
}

// 发起新的使用请求
async function newUse(id:number, goal:number, info:string) {
    const account = await getAccount();
    const eth = Web3.utils.toWei(goal.toString(10), 'ether')
    return await contract.methods.newUse(id, eth, info).send({
        from: account,
        gas: 1000000
    })
}

// 申请退款
async function returnMoney(id: number) {
    const account = await getAccount();
    return await contract.methods.returnMoney(id).send({
        from: account,
        gas: 1000000
    })
}

export {
    getAccount,
    authenticate,
    contract,
    getAllFundings,
    getOneFunding,
    getMyFundingAmount,
    contribute,
    newFunding,
    getAllUse,
    agreeUse,
    newUse,
    getMyFundings,
    returnMoney,
    addListener
}

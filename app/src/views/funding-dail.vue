<template>
    <div>
        <a-card
            class = "ant-card-shadow"
            :loading="state.loading"
            :tab-list="tabList"
            :active-tab-key="key"
            @tabChange="onTabChange"
        >
            <!-- 卡片的title部分 -->
            <template #title>
                <h3>
                    {{ state.data.title }}
                    <span style="float:right">
                        <!-- <label v-if="state.myAmount != 0 ">你投资了{{ state.myAmount }} Eth</label>  -->
                        你投资了 {{ state.myAmount }} Eth
                        <a-button type="primary" v-if="new Date(state.data.endTime * 1000) > new Date() && state.data.success == false" @click="openContributeMoneyWindow">投资</a-button> 
                        <a-button type="danger" v-if="!state.data.success && state.myAmount != 0" @click="requestReturnMoney">退款</a-button>  
                    </span>
                </h3>
            </template>

            <!-- 详细信息部分 -->
            <!-- 如果标签key为info -->
            <a-descriptions bordered v-if="key==='info'">
                <a-descriptions-item label="众筹标题" span="2">
                    {{ state.data.title }}
                </a-descriptions-item>

                <a-descriptions-item label="众筹发起人" :span="2">
                    {{ state.data.initiator }}
                </a-descriptions-item>

                <a-descriptions-item label="截止日期" :span="2">
                    {{ new Date(state.data.endTime * 1000).toLocaleString() }}
                </a-descriptions-item>

                <a-descriptions-item label="当前状态" :span="2">
                    <!-- 各种众筹状态展示 -->
                    <a-tag color="success" v-if="state.data.success === true">
                        <template #icon>
                            <check-circle-outlined/>
                        </template>
                        众筹成功
                    </a-tag>

                    <a-tag color="processing" v-else-if="new Date(state.data.endTime * 1000) > new Date()">
                        <template #icon>
                            <sync-outlined :spin="true"/>
                        </template>
                        正在众筹
                    </a-tag>

                    <a-tag color="error" v-else>
                        <template #icon>
                            <close-circle-outlined />
                        </template>
                        众筹失败
                    </a-tag>

                </a-descriptions-item>

                <a-descriptions-item label="目标金额">
                    <a-statistic :value="state.data.goal">
                        <template #suffix>
                            Eth
                        </template>
                    </a-statistic>
                </a-descriptions-item>

                <a-descriptions-item label="当前金额">
                    <a-statistic :value="state.data.amount">
                        <template #suffix>
                            Eth
                        </template>
                    </a-statistic>
                </a-descriptions-item>

                <a-descriptions-item label="众筹进度">
                    <a-progress type="circle" :percent="state.data.success ? 100 : ( state.data.amount*100 / state.data.goal)" :width="80"/>
                </a-descriptions-item>

                <a-descriptions-item label="众筹介绍">
                    {{ state.data.info }}
                </a-descriptions-item>
                <a-descriptions-item label="相关文件(IPFS)">
                    {{ state.data.hash }}
                </a-descriptions-item>

            </a-descriptions>
            <!-- 如果key为使用请求useRes -->
            <!-- 因为这里使用请求可能有多个，所以使用table而不是descriptions -->
            <use-request v-if="key === 'useRes'" :id="id" :amount="state.myAmount" :data="state.data"></use-request>
            
        </a-card>

        <!-- 打开投资窗口 -->
        <my-modal v-model:visible="isOpen">
            <a-card style="width:600px; margin: 0px 2em">
                <template #title><h3 style="text-align: center">投资</h3></template>
                <create-form :model="model" :fields="fields" :form="form"/>
            </a-card>
        </my-modal>
    </div>
</template>

<script lang="ts">
// <a-card>的标签选项
const tabList = [
    {
        key: 'info',
        tab: '项目介绍'
    },
    {
        key: 'useRes',
        tab: '使用请求'
    }
]

import { defineComponent, ref, reactive} from 'vue'
import { getOneFunding, Funding, getAccount, getMyFundingAmount, contribute, returnMoney, addListener } from '../api/contract'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue';
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import MyModal from '../components/base/my-modal.vue'
import CreateForm from '../components/base/create-form.vue'
import { Model, Fields, Form } from '../type/form'
import UseRequest from '../components/use-request.vue';

export default defineComponent({
    name: 'funding-dail',
    components: { MyModal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, UseRequest },
    setup() {
        // 要参与的众筹项目基本信息
        const route = useRoute()
        const id = parseInt(route.params.id as string)
        const account = ref('')
        const state = reactive<{data: Funding | {}, loading: boolean, myAmount: number}>({
            data: {},
            loading: true,
            myAmount: 0
        })
        
        // 参与众筹基本信息
        const isOpen = ref(false) // 参与众筹窗口是否打开的标志
        function openContributeMoneyWindow() { isOpen.value = true } // 打开参与众筹的窗口
        function closeContrubuteMoneyWindow() { isOpen.value = false } // 关闭参与众筹的窗口
        const model = reactive<Model>({
            value: 1
        })
        
        const fields = reactive<Fields>({
            value: {
                type: 'number',
                min: 1,
                max: undefined,
                label: '投资金额'
            }
        })

        const form = reactive<Form>({
            submitHint: '投资',
            cancelHint: '取消',
            cancel: () => {
                closeContrubuteMoneyWindow();
            },
            finish: async () => {
                try {
                    await contribute(id, model.value)
                    message.success('投资成功')
                    fetchData()
                    closeContrubuteMoneyWindow()
                } catch(e) {
                    message.error('投资失败，出错了！')
                }
            }
        })
        
        // 申请退款
        async function requestReturnMoney() {
            try {
                await returnMoney(id) // 退款
                message.success('申请退款成功')
                fetchData()
            } catch(e) {
                message.error('出错了，申请退款失败')
            }
        }

        // 切换标签页
        const key = ref('info')
        async function onTabChange(k: 'use' | 'info'){
            key.value = k
        }
        // 加载众筹项目信息的函数
        async function fetchData() {
            state.loading = true // 预设置数据仍在加载
            try {
                // 获取指定众筹项目的信息和当前账户对该项目的投资额
                [state.data, state.myAmount] = await Promise.all([getOneFunding(id), getMyFundingAmount(id)])
                state.loading = false // 修改数据已加载完毕
                // @ts-ignore
                fields.value.max = state.data.goal - state.data.amount
            } catch(e) {
                console.log(e)
                message.error('获取详情失败')
            }
        }
        fetchData() // 加载项目数据
        getAccount().then(res => account.value=res) // 获取当前账户
        addListener(fetchData) // 账户更新时重新加载数据



        return { state, account, isOpen, openContributeMoneyWindow, form, model, fields, tabList, key, onTabChange, id, requestReturnMoney }
    }
})
</script>
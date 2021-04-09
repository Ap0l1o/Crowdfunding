<template>
    <div>
        <a-button type="primary" @click="openUseResModal" v-if="data.initiator === account && data.success" style="display:block;margin:0 auto">
            众筹已成功，发起使用请求
        </a-button>

        <a-table :loading="state.loadig" :data-source="state.data" :columns="columns">
            <!-- 扩展信息 -->
            <template #expandedRowRender="{ record }">
                <p style="margin: 0">
                    {{ record.info }}
                </p>
            </template>

            <!-- 请求状态 -->
            <template #over="{ record }">
                <a-tag color="processing" v-if="record.over === false">
                    <template #icon>
                        <sync-outlined :spin="true">
                        </sync-outlined>
                    </template>
                    正在等待通过
                </a-tag>
                <a-tag color="success" v-else-if="record.agreeAmount >= record.goal / 2">
                    <template #icon>
                        <check-circle-outlined>
                        </check-circle-outlined>
                    </template>
                    批准使用
                </a-tag>
                <a-tag color="error" v-else>
                    <template #icon>
                        <close-circle-outlined>
                        </close-circle-outlined>
                    </template>
                    拒绝请求
                </a-tag>
            </template>

            <!-- 使用请求批复部分 -->
            <!-- 我参与众筹了，即amount!=0且还未做决定没结束则有资格参与批复 -->
            <template #action="{ text,record }" v-if="amount != 0">
                <a-button v-if="record.agree == 0 && record.over === false" type="primary" @click="AgreeUse(true, record.index)">
                    同意
                </a-button>
                <a-divider type="vertical"></a-divider>
                <a-button v-if="record.agree == 0 && record.over === false" type="danger" @click="AgreeUse(false, record.index)">
                    拒绝
                </a-button>
            </template>
        </a-table>

        <!-- 打开发起请求框 -->
        <my-modal v-model:visible="isOpen">
            <a-card style="width: 600px; margin: 0 2em;" :body-style="{ overflowY: 'auto', maxHeight: '600px' }">
                <template #title><h3 style="text-align: center">发起使用请求</h3></template>
                <create-form :model="model" :form="form" :fields="fields" />
            </a-card>
        </my-modal>

    </div>
</template>

<script lang="ts">

const columns = [
    {
    dataIndex: 'info',
    key: 'info',
    title: '使用说明'
  },
  {
    dataIndex: 'goal',
    key: 'goal',
    title: '使用金额(eth)'
  },
  {
    dataIndex: 'agreeAmount',
    key: 'agreeAmount',
    title: '同意请求数额(eth)'
  },
  {
    dataIndex: 'disagree',
    key: 'disagree',
    title: '不同意请求数额(eth)'
  },
  {
    dataIndex: 'over',
    key: 'over',
    title: '状态',
    slots: { customRender: 'over' }
  },
  {
    dataIndex: 'action',
    key: 'action',
    title: '操作',
    slots: { customRender: 'action' }
  }
]

import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import MyModal from "../components/base/my-modal.vue"
import CreateForm from "../components/base/create-form.vue"
import { defineComponent, ref, reactive, PropType, watch } from 'vue';
import { getAccount, getAllUse, Funding, agreeUse, newUse, Use, addListener } from '../api/contract'
import { Model, Fields, Form } from '../type/form'
import { message } from 'ant-design-vue';
import MyFade from './base/my-fade.vue';

export default defineComponent({
    name: 'UseRes',
    props: {
        id: Number,
        data: Object as PropType<Funding>, // 此处的data是此众筹项目的data
        amount: Number // 此处amount是当前账户对此项目的投资额
    },
    components: { MyModal, CreateForm, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, MyFade },
    setup(props) {
        // 所有请求数据
        const state = reactive<{ loading: boolean, data: Use[]}>({
            loading: true,
            data: [] // 此处data是所有使用请求的data
        })

        const account = ref('')
        
        // 获取使用请求数据
        async function fetchData() {
            state.loading = true
            try {
                state.data = await getAllUse(props.id as number)
                account.value = await getAccount()
                state.loading = false
            } catch (e){
                console.log(e)
                message.error("获取使用请求数据失败")
            }
        }
        // 发起请求的相关数据
        const isOpen = ref(false)
        function openUseResModal(){ isOpen.value = true }
        function closeUseResModal(){ isOpen.value = false }
        const model = reactive<Model>({
            info: '',
            goal: 0
        })
        const fields = reactive<Fields>({
            info: {
                type: 'textarea',
                label: '请求说明'
            },
            goal: {
                type: 'number',
                min: 0,
                label: '请求金额'
            }
        })
        const form = reactive<Form>({
            submitHint: '请求',
            cancelHint: '取消',
            cancel: () => {
                closeUseResModal()
            },
            finish: async() => {
                try {
                    await newUse(props.id as number, model.goal, model.info)
                    message.success("成功发起请求")
                    fetchData()
                    closeUseResModal()
                } catch(e) {
                    message.error("出错了")
                }
            }
        })

        // 更新最大额度为该众筹项目的总额度
        watch(() => props.data, () => {
            if(props.data){
                fields.goal.max = props.data.amount
            }
        })

        // 同意批复
        async function AgreeUse(agree: boolean, useID: number){
            try {
                console.log(props.id + " " + useID + " " +  agree)
                await agreeUse(props.id as number, useID, agree)
                message.success("处理成功")
                fetchData()
            } catch(e) {
                console.log(e)
                message.error("出错了，存在问题")
            }
        }
        addListener(fetchData)
        fetchData()
        return { columns, state, account, isOpen, model, fields, form, openUseResModal, closeUseResModal, AgreeUse }
    },
    
});

</script>
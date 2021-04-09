<template>
  <div>
    <a-card class="ant-card-shadow">

      <template #title>
        <h3>
          所有众筹
          <a-button style="float: right" @click="openModel" type="primary">发起众筹</a-button>
        </h3>
      </template>
      
      <a-table :columns="columns" :loading="state.loading" :data-source="state.data">
        <template #time="{text}">
          {{new Date(text * 1000).toLocaleString()}}
        </template>
        <template #tag="{record}">
          <a-tag color="success" v-if="record.success === true">
            <template #icon>
              <check-circle-outlined />
            </template>
            众筹成功
          </a-tag>
          <a-tag color="processing" v-else-if="new Date(record.endTime * 1000) > new Date()" >
            <template #icon>
              <sync-outlined :spin="true" />
            </template>
            正在众筹
          </a-tag>
          <a-tag color="error" v-else>
            <template #icon>
              <close-circle-outlined />
            </template>
            众筹失败
          </a-tag>
        </template>
        <template #action="{record}">
          <a @click="moreDail(record.index)">查看详情</a>
        </template>
      </a-table>
      <!-- 打开发起众筹窗口 -->
      <my-modal v-model:visible="isOpen">
        <a-card style="width:600px; margin: 0 2em" :body-style="{overflowY:'auto', maxHeight: '600px'}">

          <template #title>
            <h3 style="text-align: center"> 发起众筹 </h3>
          </template>

          <create-form :model="model" :form="form" :fields="fields"></create-form>

        </a-card>
      </my-modal>


    </a-card>

  </div>

</template>

<script lang="ts">
import { defineComponent, ref, reactive } from 'vue';
import { contract, getAccount, getAllFundings, Funding, newFunding, addListener } from '../api/contract'
import { message } from 'ant-design-vue'
import { CheckCircleOutlined, SyncOutlined, CloseCircleOutlined } from '@ant-design/icons-vue'
import { useRouter } from 'vue-router'
import MyModal  from '../components/base/my-modal.vue'
import CreateForm from '../components/base/create-form.vue'
import { Model, Fields, Form } from '../type/form'


const columns = [
  {
    dataIndex: 'title',
    key: 'title',
    title: '众筹标题'
  },
  {
    title: '目标金额(eth)',
    dataIndex: 'goal',
    key: 'goal'
  },
  {
    title: '目前金额(eth)',
    dataIndex: 'amount',
    key: 'amount'
  },
  {
    title: '结束时间',
    dataIndex: 'endTime',
    key: 'endTime',
    slots: { customRender: 'time' }
  },
  {
    title: '当前状态',
    dataIndex: 'success',
    key: 'success',
    slots: { customRender: 'tag' }
  },
  {
    title: '详情',
    dataIndex: 'action',
    key: 'action',
    slots: { customRender: 'action' }
  }
]

export default defineComponent({
  name: 'Home',
  components: { MyModal, CheckCircleOutlined, SyncOutlined, CloseCircleOutlined, CreateForm },
  setup() {
    const isOpen = ref<boolean>(false) // 是否显示众筹窗口
    const state = reactive<{loading: boolean, data: Funding[]}>({
      loading: true,
      data: []
    })

    async function fetchData() {
      state.loading = true;
      try {
        state.data = await getAllFundings();
        state.loading = false;
      } catch (e) {
        console.log(e);
        message.error('获取众筹失败!');
      }
    }
    // 以下的model、fields和form用于向子组件create-form传参
    const model = reactive<Model>({
      account: '',
      title: '',
      info: '',
      amount: '',
      date: null,
    })

    const fields = reactive<Fields>({
      account: {
        type: 'input',
        label: '发起人',
        disabled: true
      },
      title: {
        type: 'input',
        label: '标题',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      info: {
        type: 'textarea',
        label: '简介',
        rule: {
          required: true,
          trigger: 'blur'
        }
      },
      amount: {
        type: 'number',
        label: '金额',
        min: 0
      },
      date: {
        type: 'time',
        label: '截止日期',
      }
    })

    const form = reactive<Form>({
        submitHint: '发起众筹',
        cancelHint: '取消',
        layout: 'horizontal',

        cancel: () => {
          closeModel()
        },

        finish: () => {
          const seconds = Math.ceil(new Date(model.date).getTime() / 1000)
          try {
            const res = newFunding(model.account, model.title, model.info, model.amount, seconds);
            // 打印测试
            console.log("the new funding res： " + res)
            // 全局展示众筹成功信息[message 是ant-desing-vue的组件，用于全局展示操作反馈信息]
            message.success("发起众筹成功") 
            closeModel()
            fetchData() // 众筹成功后重新抓取众筹信息进行渲染
          } catch(e) {
            message.error("发起众筹失败")
          }
        }

    })

    // 打开窗口
    async function openModel(){
      isOpen.value = true;
      model.account = await getAccount()
    }

    // 关闭窗口
    function closeModel(){
      isOpen.value = false
    }

    const router = useRouter()
    const moreDail = (index : number) => {
      router.push(`/funding/${index}`)
    }

    addListener(fetchData)
    fetchData();

    return { state, columns, isOpen, model, fields, form, openModel, moreDail }
  }
});
</script>

<template>
  <a-form
    :model="model"
    :rules="rules"
    :layout="layout"
    @finish="finish"
    v-bind="itemLayout"
  >
    <a-form-item
      v-for="(field, name) in fields"
      :label="field.label"
      :key="field.label"
      :name="name"
    >
      <a-upload
        v-if="field.type === 'upload'"
        :multiple="true"
        :file-list="fileList"
        :beforeUpload="beforeUpload"
      >
        <a-button> <a-icon type="upload" /> 上传 </a-button>
      </a-upload>
      <a-input
        v-if="field.type === 'input'"
        v-model:value="model[name]"
        :disabled="field.disabled"
      />
      <a-input-password
        v-if="field.type === 'password'"
        v-model:value="model[name]"
        :disabled="field.disabled"
      />
      <a-input-number
        v-if="field.type === 'number'"
        v-model:value="model[name]"
        :min="field.min"
        :max="field.max"
        style="width: 240px;"
        :disabled="field.disabled"
        :formatter="value => `Eth ${value}`"
        :parser="value => value.replace(/Eth|\s/g, '')"
      />
      <a-textarea
        v-if="field.type === 'textarea'"
        v-model:value="model[name]"
        :disabled="field.disabled"
        autoSize
      />
      <a-radio-group
        v-if="field.type === 'radio'"
        v-model:value="model[name]"
        :disabled="field.disabled"
      >
        <a-radio v-for="radio in field.radios" :value="radio.value">
          {{ radio.hint }}
        </a-radio>
      </a-radio-group>
      <a-select
        v-if="field.type === 'select'"
        v-model:value="model[name]"
        :disabled="field.disabled"
      >
        <a-select-option v-for="item in field.select" :value="item">{{
          item
        }}</a-select-option>
      </a-select>
      <a-date-picker
        show-time
        placeholder="选择时间"
        v-if="field.type === 'time'"
        v-model:value="model[name]"
      />
      <slot
        v-if="field.customRender"
        :name="field.customRender.slot"
        :field="field"
      >
      </slot>
    </a-form-item>
    <a-form-item :wrapper-col="form.layout === 'inline' ? {} : { offset: 4 }">
      <a-button
        type="primary"
        html-type="submit"
        :loading="submitLoading"
        :disabled="nowFileUploadingCnt !== 0 || form.canSubmit === false"
      >
        {{ form.submitHint || '提交' }}
      </a-button>
      <a-divider type="vertical" />
      <a-button type="default" @click="form.cancel" v-if="form.cancel">
        {{ form.cancelHint || '取消' }}
      </a-button>
    </a-form-item>
  </a-form>
</template>

<script>
import { PropType, ref, reactive } from 'vue'
import { UploadOutlined } from '@ant-design/icons-vue'
import Ipfs from 'ipfs-http-client'

export default {
  name: 'CreateForm',
  components: { UploadOutlined },
  props: {
    model: Object,
    fields: Object,
    form: Object,
  },
  setup(props, ctx) {
    // 生成规则和文件以及自动补全等需要的函数
    const rules = reactive({})
    const nowFileUploadingCnt = ref(0)
    const CopyFields = reactive({})

    for (let x in props.fields) {
      let field = props.fields[x]
      CopyFields[x] = {}
      // 如果有规则
      if (field.rule) {
        rules[x] = props.fields[x].rule
        if (rules[x].required && !rules[x].validator)
          rules[x].message = `${field.label}不能为空!`
      }
    }

    // 提交函数
    const submitLoading = ref(false)
    const finish = async () => {
      submitLoading.value = true
      ctx.emit('getHashs', fileHashs.value[0]) // 向父组件传递上传文件的Hash值
      try {
        await props.form.finish()
      } catch (e) {
      } finally {
        submitLoading.value = false
      }
    }

    // 布局
    const layout = ref(props.form.layout || 'horizontal')
    // const layout = ref('horizontal')
    const itemLayout = ref(
      layout.value === 'horizontal'
        ? { labelCol: { span: 4 }, wrapperCol: { span: 20 } }
        : {}
    )

    const fileList = ref([])
    const fileHashs = ref([])
    const beforeUpload = async (file) => {
      const ipfs = Ipfs("/ip4/127.0.0.1/tcp/5001")
      await ipfs.add(file).then((res) => {
        console.log(res.path)
        fileHashs.value.push(res.path)
        var fileListItem = { uid: fileList.value.length, name: file.name + " " + res.path, status:'done' }
        fileList.value.push(fileListItem)
        fileList.value = fileList.value.slice(-1) // 限制只允许上传一个文件
      })
    }

    return {
      rules,
      finish,
      fileList,
      beforeUpload,
      submitLoading,
      layout,
      itemLayout,
      nowFileUploadingCnt,
      CopyFields,
    }
  },
  // data() {
  //   return {
  //     fileList: [],
  //     fileHashs: []
  //   }
  // },
  // methods: {
  //   async beforeUpload(file) {
      
  //     const ipfs = Ipfs("/ip4/127.0.0.1/tcp/5001")
  //     // const ipfs = Ipfs("api/tcp/5001")
  //     await ipfs.add(file).then((res) => {
  //       console.log(res.path)
  //       this.fileHashs.push(res.path)
  //       // console.log(res.cid)
  //       var fileListItem = { uid: this.fileList.length, name: file.name + " " + res.path, status:'done' }
  //       this.fileList.push(fileListItem)
  //     })
      
  //   }
  // }

}
</script>
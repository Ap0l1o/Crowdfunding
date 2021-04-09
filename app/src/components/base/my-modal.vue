<template>
    <div v-if="visible" class="my-mask" @click="handleClickMask"/>
      <div class="fixed-center" v-show="visible">
          <slot></slot>
      </div>
</template>


<script lang="ts">
export default {
    props: { visible:Boolean },
    //@ts-ignore
    setup(props, ct) {
     // 点击遮罩
     const handleClickMask = () => ct.emit('update:visible', false)
     return { handleClickMask }
  }
}
</script>


<style scoped>
.my-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  z-index: 100;
}

.fixed-center {
  position: fixed;
  z-index: 200;
  top: 20%;
  left: 35%;
}

</style>
<template>
  <div>
    <myheader />
    <main>
      <myfade>
        <router-view></router-view>
      </myfade>
    </main>
  </div>
</template>


<script lang="ts">
import myheader from "./components/my-header.vue";
import { defineComponent } from "vue";
import Myfade from "./components/base/my-fade.vue";
export default defineComponent({
  components: { myheader, Myfade },
})

</script>

<style lang="less">
</style>

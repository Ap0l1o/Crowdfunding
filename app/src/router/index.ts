import { createRouter, createWebHashHistory, RouteRecordRaw } from 'vue-router'
import myhome from '../views/my-home.vue'

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: myhome
  },
  {
    path: '/funding/:id',
    name: 'funding',
    component: () => import('../views/funding-dail.vue')
  },
  {
    path: '/myself',
    name: 'Myself',
    component: () => import('../views/myself.vue')
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

export default router

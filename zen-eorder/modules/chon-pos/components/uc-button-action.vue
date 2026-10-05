<template>
    <div class="d-flex justify-center my-4">
        <v-btn class="ma-2" color="primary" elevation="0" @click="redirectMenu"><v-icon left>mdi-account-credit-card</v-icon>Menu khách</v-btn>
        <v-btn class="ma-2" color="primary" elevation="0" @click="redirectOrder"><v-icon left>mdi-monitor-dashboard</v-icon>Màn hình POS</v-btn>
    </div>
</template>

<script>
export default {
    methods: {
        redirectMenu() {
            if (vueData.CuaHangID) {
                window.open("/menu?chid=" + vueData.CuaHangID, "_blank")
            }
        },
        redirectOrder() {
            if (vueData.CuaHangID) {
                redirect({url: "/pos?chid=" + vueData.CuaHangID})
            }
        }
    },
}
</script>

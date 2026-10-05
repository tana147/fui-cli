<template>
    <div class="intro-div">
        <div class="title white--text bg-green pb-0 pt-3 px-5 text-center">
            <v-icon @click="window.location.href = '/chon-order'" class="float-left" color="white">mdi-arrow-left</v-icon>
            <span>ZEN MPOS - {{ info?.TenBan }}</span>
        </div>
        <div class="pa-2 bg-green">
            <v-text-field prepend-inner-icon="mdi-magnify" solo clearable label="Tìm theo mã số, tên món..." v-model="vueData.SearchKeyword" class="text-right pt-0" dense hide-details></v-text-field>
        </div>
        <div class="pa-2" v-if="vueData.HoaDonID > 0">
            <v-btn @click="onOpenModalHistory()" block color="primary" elevation="0"><v-icon left>mdi-food-turkey</v-icon>XEM DANH SÁCH MÓN ĐÃ GỬI</v-btn>
        </div>
    </div>
</template>

<script>
export default {
    props: ["info"],
    computed: {
        HoaDon: function () {
            return vueData.DSOrder ?? []
        },
    },
    methods: {
        onOpenModalHistory() {
            vueData.IsShowDialogHistory = true
        },
    },
}
</script>

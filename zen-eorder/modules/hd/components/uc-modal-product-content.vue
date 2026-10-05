<template>
    <v-dialog v-model="vueData.IsShowDetail" fullscreen hide-overlay>
        <div class="v-toolbar__title d-flex align-center pa-3" style="z-index: 2;">
            <v-icon @click="vueData.IsShowDetail = false" class="float-left px-3" color="white">mdi-arrow-left</v-icon>
            <b class="ml-5">Chi tiết sản phẩm</b>
        </div>
        <div class="px-2 product-html" v-html="vueData.CTSanPham?.NoiDung"></div>
    </v-dialog>
</template>

<script>
export default {
    props: [],
    data() {
        return {}
    },
}
</script>

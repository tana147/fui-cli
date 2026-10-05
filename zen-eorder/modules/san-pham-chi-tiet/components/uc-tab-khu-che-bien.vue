<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Thiết lập khu vực chế biến<span class="ml-2 success--text">({{ sp_ch.length }} cửa hàng)</span>
                </v-toolbar-title>
            </v-toolbar>
            <v-card-text>
                <uc-item-khu-che-bien v-for="item in sp_ch" :key="item.SanPham_CuaHangId" :sp_ch="item" :kcb="DS_KhuCheBien" />
            </v-card-text>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["sp_ch"],
    data: () => {
        return {
            DS_KhuCheBien: [],
        }
    },
    methods: {
        getLineByStore() {
            const $this = this
            ajaxCALL("/eorder/KhuCheBien_Select_All", {}, (res) => {
                $this.DS_KhuCheBien = res.data
            })
        },
    },
    mounted: function () {
        this.getLineByStore()
    },
}
</script>

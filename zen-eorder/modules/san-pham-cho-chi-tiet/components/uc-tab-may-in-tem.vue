<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Thiết lập máy in tem<span class="ml-2 success--text">({{ sp_ch.length }} cửa hàng)</span>
                </v-toolbar-title>
            </v-toolbar>
            <v-card-text>
                <uc-item-may-in-tem v-for="item in sp_ch" :key="item.SanPham_CuaHangId" :sp_ch="item" :mit="DS_MayInTem" />
            </v-card-text>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["sp_ch"],
    data: () => {
        return {
            DS_MayInTem: [],
        }
    },
    methods: {
        getPrinterByStore() {
            const $this = this
            ajaxCALL("/eorder/MayInTem_Select_All", {}, (res) => {
                $this.DS_MayInTem = res.data
            })
        },
    },
    mounted: function () {
        this.getPrinterByStore()
    },
}
</script>

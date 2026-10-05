<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Cài đặt<span class="ml-2 success--text">({{ sp_ch.length }} cửa hàng)</span>
                </v-toolbar-title>
            </v-toolbar>
            <v-card-text>
                <uc-item-cai-dat v-for="item in sp_ch" :key="item.SanPham_CuaHangID" :sp_ch="item" />
            </v-card-text>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["sp_ch"],
}
</script>

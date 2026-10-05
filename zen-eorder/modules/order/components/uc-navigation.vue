<template>
    <div>
        <div class="title white--text bg-green pa-2 pt-3 text-center">ZEN XIN CHÀO QUÝ KHÁCH - Bàn {{ info?.TenBan }}</div>
        <!-- <div class="px-3 py-2 primary--text">
            <p class="mb-1"><b>Hướng dẫn thực hiện chọn món</b></p>
            <p class="mb-1"><b>Bước 1:</b> Chọn số thứ tự tương ứng với món trên thực đơn, tuỳ chỉnh topping, số lượng theo sở thích.</p>
            <p class="mb-1">
                <b>Bước 2:</b> Chọn <span class="bg-green white--text help-outline">Gửi chế biến</span> để gọi món, <br />
                hoặc <span class="help-outline">Thêm vào giỏ</span> để thêm món.
            </p>
            <p class="mb-1">
                <div class="d-flex align-center error--text" style="gap:5px">
                    <p class="mt-1">Lưu ý:</p>
                    <v-icon color="error" small>mdi-lock</v-icon>
                    <p class="mt-1"><b>Món Tạm Hết</b></p>
                </div>
                * Khi cần chỉnh sửa lại món đã gửi, Quý khách vui lòng liên hệ nhân viên hỗ trợ. ZEN cảm ơn Quý khách!
            </p>
        </div> -->
        <div v-if="vueData.HoaDonID > 0" class="d-flex justify-center align-center px-3 py-1 border-bottom border-top" style="gap: 10px">
            <v-btn style="flex: 1" v-if="vueData.HoaDonID > 0" @click="onOpenModalHistory()" color="primary" elevation="0">
                <v-icon left>mdi-food-turkey</v-icon>
                DANH SÁCH MÓN ĐÃ GỬI
            </v-btn>
        </div>
        <v-tabs v-model="vueData.TabNhomSanPham" center-active class="mb-0 border-bottom border-top">
            <v-tab v-for="item in vueData.DSNhomSanPham" :key="item.TabIndex">
                <v-icon left>{{ item.IconNhomSanPham }}</v-icon>
                {{ item.TenNhomSanPham }}
            </v-tab>
        </v-tabs>
        <div class="border-bottom">
            <v-text-field prepend-inner-icon="mdi-magnify" solo clearable label="Tìm theo mã số, tên món..." v-model="vueData.SearchKeyword" class="text-right" hide-details></v-text-field>
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

<template>
    <v-dialog v-model="vueData.IsShowDialogSplitTable" scrollable width="550">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Tách hóa đơn</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogSplitTable = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <p class="font-weight-bold primary--text mb-2">Tách hóa đơn từ bàn</p>
                <v-select class="mt-1" label="Bàn" outlined dense v-model="BanID_Cu" :items="DSBan_Cu" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: Chỉ được tách hóa đơn bàn đang được tiếp nhận đơn hàng</p>
                <p class="font-weight-bold primary--text mb-2">Tách sang bàn</p>
                <v-autocomplete class="mt-1" v-model="LauID" label="Lầu" :items="vueData.DSLau" item-text="TenLau" item-value="LauID" outlined hide-details dense />
                <v-autocomplete class="mt-3" v-model="KhuID" label="Khu vực" :items="DSKhu" item-text="TenKhu" item-value="KhuID" outlined hide-details dense />
                <v-select class="mt-3" label="Bàn" outlined dense v-model="BanID_Moi" :items="DSBan_Moi" item-value="BanID" item-text="TenBan" hide-details />
                <p class="mx-2 my-1 error--text">*Lưu ý: Chỉ được tách sang bàn trống chưa được tiếp nhận đơn hàng</p>
                <f-table :label="TableLabel" v-model="SanPham_Selected" :show-select="true" :headers="TableHeader" :items="DS_SanPham" item-key="SanPhamID" :items-per-page="-1" hide-default-footer="true" />
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSaveSplitTable" color="success">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog"],
    data: function () {
        return {
            BanID_Cu: null,
            BanID_Moi: null,
            DS_ChiTietHoaDon: [],
            SanPham_Selected: [],
            MaHoaDon_Tach: "",
            LauID: vueData.LauID ?? 0,
            KhuID: vueData.KhuID ?? 0,
            DSLau: vueData.DSLau ?? [],
            DSKhu: vueData.DSKhu ?? [],
            DSBan_Moi: vueData.DSBan ?? [],
            TableHeader: [
                {
                    text: "Sản phẩm",
                    value: "TenNoiBo",
                },
                {
                    text: "Số lượng",
                    value: "SoLuong",
                    el: "span",
                    align: "right",
                    innerHTML: "{{item.SoLuong?.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Đơn giá",
                    value: "DonGia",
                    el: "span",
                    align: "right",
                    innerHTML: "{{item.DonGia?.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Thành tiền",
                    value: "ThanhTien",
                    el: "span",
                    align: "right",
                    innerHTML: "{{item.ThanhTien?.toLocaleString('vi-vn')}}",
                },
            ],
        }
    },
    computed: {
        TableLabel() {
            const $this = this
            return `Chọn món tách - ${$this.MaHoaDon_Tach}`
        },
        DSBan_Cu() {
            return vueData.DSBan?.filter((item) => item.HoaDonID > 0) //Filter bàn có hóa đơn
        },
        DS_SanPham() {
            const $this = this
            return $this.DS_ChiTietHoaDon?.filter((item) => item.Is_SanPham === 1) //Chỉ lấy món (không lấy topping với vị)
        },
    },
    watch: {
        show_dialog() {
            const $this = this
            $this.BanID_Cu = null
            $this.BanID_Moi = null
            $this.DS_ChiTietHoaDon = []
            $this.SanPham_Selected = []
        },
        BanID_Cu(value) {
            const $this = this
            if (value > 0) {
                const params = {BanID: value}
                ajaxCALL("/eorder/HoaDon_Select_ByBanId", params, (res) => {
                    const resOrder = res.data[1][0] ?? []
                    const resOrderDetail = res.data[2] ?? []
                    if (resOrder.HoaDonID > 0) {
                        $this.MaHoaDon_Tach = resOrder.MaHoaDon
                        $this.DS_ChiTietHoaDon = resOrderDetail
                    } else {
                        Vue.$toast.error("Không tìm thấy dữ liệu món vì bàn chưa tiếp nhận hóa đơn", {position: "top"})
                    }
                })
            }
        },
        LauID(value) {
            const $this = this
            runAction(vueData.getKhuSelectByLauId)
        },
        KhuID(value) {
            const $this = this
            runAction(vueData.getBan)
        },
    },
    methods: {
        onSaveSplitTable: function () {
            const $this = this
            const params = {
                BanID_Cu: $this.BanID_Cu,
                BanID_Moi: $this.BanID_Moi,
                ChiTietHoaDonID_List: $this.SanPham_Selected.join(","),
            }
            ajaxCALL("/eorder/Ban_Update_TachBan", params, (res) => {
                Vue.$toast.success("Đã tách hóa đơn thành công", {position: "top"})
                vueData.IsShowDialogSplitTable = false
                runAction(vueData.getBan)
            })
        },
    },
}
</script>

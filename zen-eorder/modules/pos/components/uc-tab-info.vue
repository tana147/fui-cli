<template>
    <div class="tab-info">
        <div class="d-flex flex-row align-center" style="gap: 10px">
            <v-select dark v-model="Ca" :items="DSCa" item-value="Id" item-text="Ca" hide-details dense style="width: 100px" class="mt-0"></v-select>
            <span>{{ vueData?.TenCuaHang }} </span>
            <span v-if="vueData.HoaDon.BanID">/ {{ vueData.HoaDon?.TenLau }} / {{ vueData.HoaDon?.TenBan }}</span>
        </div>
        <v-btn v-if="vueData.HoaDon.BanID > 0" small @click="onHuyBan" color="error" elevation="0"><v-icon left>mdi-close</v-icon>Hủy bàn</v-btn>
        <v-btn v-if="IsShowButtonChooseTable" small @click="vueData.IsShowDialogChooseTable = true" class="bg-white" color="success" elevation="0" outlined><v-icon left>mdi-plus</v-icon>Chọn bàn</v-btn>
        <uc-modal-table-choose :show_dialog="vueData.IsShowDialogChooseTable" />
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            DSCa: [
                { Id: 1, Ca: "Ca sáng" },
                { Id: 2, Ca: "Ca tối" },
                { Id: 3, Ca: "Ca đêm" },
            ],
            Ca: null
        }
    },
    created() {
        this.getShift()
    },
    watch: {
        Ca: function (value, old) {
            const $this = this
            if (value > 0 && old !== null) {
                ajaxCALL("/eorder/NhanVien_Update_Ca", { Ca: $this.Ca }, (res) => {
                    Vue.$toast.success("Cập nhật ca thành công", { position: "top" })
                })
            }
        },
    },
    computed: {
        IsShowButtonChooseTable: function (value) {
            return vueData.HoaDon.ChiTietHoaDon.length > 0 && vueData.HoaDon.BanID <= 0 && vueData.HoaDon.TrangThai !== 3 && vueData.LoaiPhanHieuID === 2
        },
    },
    methods: {
        onHuyBan() {
            if (vueData.HoaDon.HoaDonID > 0) {
                const params = {
                    BanID: 0,
                    HoaDonID: vueData.HoaDon.HoaDonID ?? 0,
                }
                ajaxCALL("/eorder/HoaDon_Update_DoiBan", params, (res) => {
                    vueData.HoaDon.BanID = 0
                    vueData.HoaDon.TenBan = ""
                    vueData.HoaDon.TenLau = ""
                    vueData.HoaDon.TenKhu = ""
                    //Xóa món khỏi danh sách order
                    let index = vueData.HoaDon.ChiTietHoaDon.findIndex((item) => {
                        if (item.HoaDonID === 0 && item.HoaDonChiTietID === 0 && item.TrangThai > 0) {
                            return item
                        }
                    })
                    if (index >= 0) {
                        let x = vueData.HoaDon.ChiTietHoaDon.splice(index, 1)
                    }
                })
            } else {
                vueData.HoaDon.BanID = 0
                vueData.HoaDon.TenBan = ""
                vueData.HoaDon.TenLau = ""
                vueData.HoaDon.TenKhu = ""
                vueData.HoaDon = { ...vueData.HoaDon, LoaiDonHang: 2 }
            }
        },
        getShift() {
            const $this = this
            ajaxCALL("/eorder/NhanVien_Select_ById", null, (res) => {
                const data = res.data
                $this.Ca = data[1][0]?.Ca ?? 0
            })
        },
    },
}
</script>

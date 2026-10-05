<template>
    <v-btn class="ma-2 py-5" :disabled="item.TinhTrang === 1" :style="StyleStatus" outlined color="green" @click="onSubmit()">
        <v-icon small v-if="item.TinhTrang === 1">mdi-lock</v-icon>{{ item.TenBan }}
        <span v-if="item.TrangThai === 6 && item.TinhTrang === 1" class="icon-merge-table">{{ item.TenBanGop }}</span>
    </v-btn>
</template>

<script>
export default {
    props: ["item", "is_modal_choose"],
    computed: {
        StyleStatus() {
            const $this = this
            let style = "width: 73px; font-size: 16px;font-weight: 500;color: #b3b3b3!important;background-color: #ffffff"
            if ($this.item.HoaDonID > 0) {
                style += `;color:#4caf50!important;background-color:#c8edc8`
            }
            if ($this.item.Is_TreMon_1) {
                style += `;color:#fff!important;border-color:${$this.item.MauThoiGianCheBien_1};background-color:${$this.item.MauThoiGianCheBien_1}`
            }
            if ($this.item.Is_TreMon_2) {
                style += `;color: #fff!important;border-color:${$this.item.MauThoiGianCheBien_2};background-color:${$this.item.MauThoiGianCheBien_2}`
            }
            if ($this.item.Is_YeuCauThanhToan) {
                style += `;color: #fff!important;border-color:${$this.item.MauYeuCauThanhToan};background-color:${$this.item.MauYeuCauThanhToan}`
            }
            if ($this.item.Is_MangVe) {
                style += `;border: 3px solid ${$this.item.MauMangVe}`
            }
            return style
        },
    },
    methods: {
        onSubmit() {
            const $this = this
            const banID_Selected = $this.item.BanID
            //Nếu chọn bàn từ modal thì gọi API cập nhật bàn
            if ($this.is_modal_choose) {
                //Nếu bàn được chọn đã có hóa đơn thì không cho cập nhật
                if ($this.item.HoaDonID > 0) {
                    Vue.$toast.error("Không thể chọn bàn đang được tiếp nhận đơn hàng", {position: "top"})
                    return
                }
                //Nếu POS đang có hóa đơn thì cho phép hóa đơn cập nhật bàn
                if (vueData.HoaDon.HoaDonID > 0) {
                    const params = {
                        HoaDonID: vueData.HoaDon.HoaDonID,
                        BanID: banID_Selected,
                    }
                    ajaxCALL("/eorder/HoaDon_Update_DoiBan", params, (res) => {
                        let data = res.data[0]
                        if (data) {
                            vueData.HoaDon.TenLau = data.TenLau
                            vueData.HoaDon.TenBan = data.TenBan
                            vueData.HoaDon.BanID = data.BanID
                        }
                        vueData.HoaDon = {...vueData.HoaDon, HinhThucThanhToan: ["1"], LoaiDonHang: 1}
                    })
                } else {
                    //Nếu hóa đơn mới thì load danh sách món mặc định
                    loadHoaDon(banID_Selected, 0)
                }
                vueData.IsShowDialogChooseTable = false
            } else {
                //Nếu chọn bàn từ tab sơ đồ bàn => Load hóa đơn mới
                vueData.TabProduct = 0
                vueData.HoaDon.BanID = banID_Selected
                loadHoaDon(banID_Selected, 0)
            }
        },
    },
}
</script>

<template>
    <v-btn class="ma-2 py-5" :disabled="item.TinhTrang === 1" :style="StyleStatus" outlined color="primary" @click="onSubmit()">
        <v-icon small v-if="item.TinhTrang === 1">mdi-lock</v-icon>{{ item.TenBan }}
        <span v-if="item.TrangThai === 6 && item.TinhTrang === 1" style="font-size: 14px; position: absolute; top: -20px; right: -10px; background-color: #fff; border: 1px solid; border-radius: 3px; padding: 1px">{{ item.TenBanGop }}</span>
    </v-btn>
</template>

<script>
export default {
    props: ["item"],
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
            const params = {BanID: $this.item.BanID}
            ajaxCALL("/eorder/Ban_Select_ById", params, (res) => {
                if (res.data) {
                    window.location.href = "/order-pos?chid=" + vueData.CuaHangID + "&baid=" + +res.data[0]?.BanID
                } else {
                    Vue.$toast.error("Không tìm thấy bàn, vui lòng thử lại", {position: "top"})
                }
            })
        },
    },
}
</script>

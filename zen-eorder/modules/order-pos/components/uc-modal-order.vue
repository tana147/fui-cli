<template>
    <v-dialog v-model="vueData.IsShowDialogOrder" fullscreen scrollable persistent transition="dialog-top-transition">
        <v-card class="model-order">
            <div class="pa-2 font-weight-bold border-bottom">
                <div class="d-flex align-center">
                    <div style="flex: 1">
                        Giỏ hàng: <span class="text-green">{{ HoaDon?.length }} món</span> <br />
                        Tổng: <span class="error--text">{{ TongTienHoaDon?.toLocaleString("vi-vn") }}</span>
                    </div>
                    <div style="flex: 1">
                        <v-btn v-if="vueData.HoaDonID" block @click="onOpenModalHistory()" color="success" elevation="0"><v-icon left>mdi-food-turkey</v-icon>MÓN ĐÃ GỬI</v-btn>
                    </div>
                </div>
            </div>
            <div class="tr-product bg-green white--text">
                <div class="td-product-name-send">Tên món</div>
                <div class="td-product-print"></div>
                <div class="td-product-qty text-right">SL</div>
                <div class="td-product-price">Giá</div>
                <div class="td-product-action"></div>
            </div>
            <div class="order-send-body">
                <template v-for="(item, i) in HoaDon" :key="item.SanPhamGuid">
                    <uc-product-order :product="item" />
                </template>
            </div>
            <div class="pa-1 border-top">
                <v-text-field prepend-inner-icon="mdi-magnify" solo clearable label="Tìm theo mã số, tên món..." v-model="vueData.SearchKeyword" class="text-right pt-0" hide-details></v-text-field>
            </div>
            <div class="order-send-product">
                <uc-product-list />
            </div>
            <div class="pa-3 order-footer">
                <v-row>
                    <v-col cols="6">
                        <v-btn block @click="onDeleteAll()" color="error" elevation="0"><v-icon left>mdi-trash-can</v-icon>Hủy tất cả</v-btn>
                    </v-col>
                    <v-col cols="6">
                        <v-btn block :disabled="HoaDon?.length === 0 || DisableSend" @click="onSendOrder()" color="success" elevation="0"><v-icon left>mdi-chef-hat</v-icon>Gửi chế biến</v-btn>
                    </v-col>
                </v-row>
            </div>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    data: function () {
        return {
            DisableSend: false,
        }
    },
    computed: {
        HoaDon: function () {
            return vueData.DSOrder ?? []
        },
        TongTienHoaDon: function () {
            const $this = this
            let tongTienHoaDon = 0
            $this.HoaDon?.forEach((hd) => {
                tongTienHoaDon += hd.SoLuong * hd.GiaBan_CuaHang
                //Tính tiền Topping
                hd.ThuocTinh?.forEach((tt) => {
                    tongTienHoaDon += tt.SoLuong * tt.GiaBan_CuaHang
                })
            })
            return tongTienHoaDon
        },
    },
    methods: {
        clearData() {
            vueData.IsShowDialogDetailProduct = false
            vueData.IsShowDialogOrder = false
            vueData.DSOrder = []
            vueData.SanPhamGuid_Active = null
        },
        onOpenModalHistory() {
            vueData.IsShowDialogHistory = true
        },
        onDeleteAll() {
            vueData.DSOrder = []
            vueData.IsShowDialogDetailProduct = false //Tắt modal detail
            vueData.IsShowDialogOrder = false //Tắt modal lưu tạm
        },
        onSendOrder() {
            const $this = this
            if ($this.DisableSend === false) {
                $this.DisableSend = true
                const dataJson = []
                vueData.DSOrder.forEach((pro) => {
                    //Xử lý danh sách món
                    const product = {
                        SanPhamID: pro.SanPhamID,
                        SanPhamGUID: pro.SanPhamGuid,
                        NhomLienKetID: pro.NhomLienKetID ?? 0,
                        NhomLienKetChiTietID: 0,
                        NhomLienKetChiTiet_ParentID: 0,
                        TenHienThi: pro.TenSanPham,
                        TenNoiBo: pro.TenNgan,
                        SoLuong: pro.SoLuong,
                        DonGia: pro.GiaBan_CuaHang,
                        ThuTu: 0,
                        GhiChu: pro.GhiChu ?? "",
                        Is_MangVe: pro.Is_MangVe ? 1 : 0,
                        Is_SanPham: 1,
                        Is_ThuocTinh: 0,
                        Is_GuiBepBar: pro.Is_GuiBepBar,
                        LoaiLyID: pro.LoaiLyID
                    }
                    dataJson.push(product)
                    //Xử lý danh sách topping
                    pro.ThuocTinh.forEach((item) => {
                        if (item.SoLuong > 0) {
                            const topping = {
                                SanPhamID: item.SanPhamID ?? 0,
                                SanPhamGUID: pro.SanPhamGuid,
                                NhomLienKetID: item.NhomLienKetID,
                                NhomLienKetChiTietID: item.NhomLienKetChiTietID,
                                NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
                                TenHienThi: item.TenHienThi,
                                TenNoiBo: item.TenNoiBo,
                                SoLuong: item.SoLuong,
                                DonGia: item.GiaBan_CuaHang,
                                ThuTu: item.ThuTu,
                                GhiChu: "",
                                Is_MangVe: pro.Is_MangVe ? 1 : 0,
                                Is_SanPham: 0,
                                Is_ThuocTinh: 1,
                                Is_GuiBepBar: pro.Is_GuiBepBar, // Gui bep bar theo product
                                LoaiLyID: 0
                            }
                            dataJson.push(topping)
                        }
                    })
                })
                // Gọi API
                const params = {
                    CuaHangID: vueData.CuaHangID,
                    BanID: vueData.BanID ?? 0,
                    HoaDonID: vueData.HoaDonID ?? 0,
                    ChiTietOrder_JSON: JSON.stringify(dataJson),
                }
                //Insert ngoài
                ajaxCALL("/eorder/HoaDon_Mpos_Insert", params, (res) => {
                    if (res.data) {
                        webSocket_Send({group: vueData.webSocket_Hub_Bep, data: Date.now()})
                        webSocket_Send({group: vueData.webSocket_Hub_Order, data: Date.now()})
                        $this.clearData() //Clear data page
                        Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", {position: "top"})
                        //Push HoaDonID vào local và Href
                        const hoaDonId = res.data[0].HoaDonID
                        if (hoaDonId) {
                            vueData.HoaDonID = hoaDonId
                            const isExistOrderId = window.location.search.includes("hdid=")
                            if (!isExistOrderId) {
                                pushRouter("/order-pos" + window.location.search + "&hdid=" + hoaDonId)
                            }
                        }
                        $this.DisableSend = false
                    }
                })
            }
        },
    },
}
</script>

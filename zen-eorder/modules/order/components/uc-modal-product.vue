<template>
    <v-dialog v-model="vueData.IsShowDialogDetailProduct" fullscreen scrollable persistent transition="dialog-top-transition">
        <v-card class="model-order">
            <div class="tr-product bg-green white--text">
                <div class="td-product-name">Tên món</div>
                <div class="td-product-price">Giá</div>
                <div class="td-product-qty-order">SL</div>
            </div>
            <div>
                <div class="order-detail-body">
                    <div class="tr-product">
                        <div class="td-product-name primary--text font-weight-bold">{{ SanPham?.TenSanPham }}</div>
                        <div class="td-product-price">{{ ThanhTien?.toLocaleString("vi-vn") }}</div>
                        <div class="td-product-qty-order" v-on:click.stop="">
                            <v-btn @click="onReduce()" :disabled="SanPham?.SoLuong === 0" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-minus</v-icon></v-btn>
                            <v-text-field style="width: 50px; display: inline-block" v-if="SanPham?.SoLuongThapPhan" @blur="onBlurQuantity" :value="roundSoLuong(SanPham.SoLuong)" @click.stop="" type="number" class="centered-input" hide-details dense hide-spin-buttons></v-text-field>
                            <span v-else class="px-2" style="font-size: 16px; font-weight: 500">{{ roundSoLuong(SanPham?.SoLuong) }}</span>
                            <v-btn @click="onIncrease()" fab class="bg-white pl-0 pr-0 btn-plus" x-small><v-icon class="text-green">mdi-plus</v-icon></v-btn>
                        </div>
                    </div>
                    <div class="tr-product bg-green-2" style="border-bottom: 1px solid rgb(57 119 68)">
                        <div class="break-detail">
                            <div class="ml-3 py-1">
                                <label @click="onCheck()">
                                    <v-icon class="text-green">{{ IsChecked ? "mdi-checkbox-marked" : "mdi-square-outline" }}</v-icon> Mang về
                                </label>
                            </div>
                        </div>
                        <template v-for="(detail, i) in SanPham.ThuocTinh" :key="i">
                            <uc-topping :detail="detail" :product="SanPham" />
                        </template>
                        <div class="break-detail">
                            <v-text-field @click="scrollToBottom()" solo dense hide-details label="Ghi chú:" v-model="SanPham.GhiChu"></v-text-field>
                        </div>
                    </div>
                    <div class="text-right pa-3">
                        <v-row>
                            <v-col cols="5">
                                <v-btn block class="float-left" @click="onDelete()" color="error" elevation="0"><v-icon left>mdi-trash-can</v-icon>Hủy món</v-btn>
                            </v-col>
                            <v-col cols="7">
                                <b>Tạm tính</b><br /><b class="red--text">{{ TongTienMon?.toLocaleString("vi-vn") }}</b>
                            </v-col>
                        </v-row>
                    </div>
                </div>
                <div class="pa-3 order-footer">
                    <v-row>
                        <v-col cols="6">
                            <v-btn block :disabled="vueData.DSOrder.length === 0 || DisableSend" @click="onSend()" color="success" elevation="0"><v-icon left>mdi-chef-hat</v-icon>Gửi chế biến</v-btn>
                        </v-col>
                        <v-col cols="6">
                            <v-btn block @click="onSave()" elevation="0"><v-icon left>mdi-plus-circle</v-icon>Thêm vào giỏ</v-btn>
                        </v-col>
                    </v-row>
                </div>
            </div>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    data: function () {
        return {
            DisableSend: false,
            IsChecked: false,
        }
    },
    computed: {
        SanPham: function () {
            const $this = this
            const index = vueData.DSOrder.findIndex((item) => item.SanPhamGuid === vueData.SanPhamGuid_Active)
            if (index >= 0) {
                $this.IsChecked = vueData.DSOrder[index]?.Is_MangVe ?? false
                return vueData.DSOrder[index]
            } else {
                return []
            }
        },
        ThanhTien: function () {
            return this.SanPham.SoLuong * this.SanPham.GiaBan_CuaHang
        },
        TongTienMon: function () {
            const $this = this
            let tongTienTopping = 0
            $this.SanPham.ThuocTinh?.forEach((item) => {
                tongTienTopping += item.SoLuong * item.GiaBan_CuaHang
            })
            return $this.ThanhTien + tongTienTopping
        },
    },
    methods: {
        onCheck() {
            const $this = this
            $this.SanPham.Is_MangVe = !$this.SanPham.Is_MangVe
            $this.IsChecked = $this.SanPham.Is_MangVe
        },
        scrollToBottom() {
            $(".order-detail-body").scrollTop($(".order-detail-body")[0].scrollHeight)
        },
        onIncrease() {
            const $this = this
            $this.SanPham.SoLuong += 1
            $this.updateToppingQuantity() //Tăng số lượng topping theo số lượng món
        },
        onReduce() {
            const $this = this
            $this.SanPham.SoLuong = $this.SanPham.SoLuong <= 0 ? 0 : $this.SanPham.SoLuong - 1
            if ($this.SanPham.SoLuong <= 0) {
                $this.onDelete() //Remove sản phẩm
            } else {
                $this.updateToppingQuantity() //Giảm số lượng topping theo số lượng món
            }
        },
        onDelete() {
            const $this = this
            const index = vueData.DSOrder.findIndex((item) => item.SanPhamGuid === $this.SanPham.SanPhamGuid)
            if (index >= 0) {
                vueData.DSOrder.splice(index, 1) //Remove sản phẩm
                vueData.IsShowDialogDetailProduct = false //Tắt modal detail
                vueData.IsShowDialogOrder = vueData.DSOrder.length > 0 //Show Modal danh sách món tạm nếu còn món
            }
        },
        onSend() {
            const $this = this

            confirm({
                title: "Bạn có chắc muốn gửi chế biến?",
                action: function () {
                    if ($this.DisableSend === false) {
                        $this.DisableSend = true
                        const dataJson = []
                        //Xử lý danh sách món
                        const product = {
                            SanPhamID: $this.SanPham.SanPhamID,
                            SanPhamGUID: $this.SanPham.SanPhamGuid,
                            NhomSanPhamID: $this.SanPham.NhomSanPhamID ?? 0,
                            NhomLienKetID: $this.SanPham.NhomLienKetID ?? 0,
                            NhomLienKetChiTietID: 0,
                            NhomLienKetChiTiet_ParentID: 0,
                            TenHienThi: $this.SanPham.TenSanPham,
                            TenNoiBo: $this.SanPham.TenSanPham,
                            SoLuong: $this.SanPham.SoLuong,
                            DonGia: $this.SanPham.GiaBan_CuaHang,
                            ThuTu: 0,
                            GhiChu: $this.SanPham.GhiChu ?? "",
                            Is_MangVe: $this.SanPham.Is_MangVe ? 1 : 0,
                            Is_SanPham: 1,
                            Is_ThuocTinh: 0,
                        }
                        dataJson.push(product)
                        //Xử lý danh sách topping
                        $this.SanPham.ThuocTinh.forEach((item) => {
                            if (item.SoLuong > 0) {
                                const topping = {
                                    SanPhamID: item.SanPhamID ?? 0,
                                    SanPhamGUID: $this.SanPham.SanPhamGuid,
                                    NhomSanPhamID: item.NhomSanPhamID ?? 0,
                                    NhomLienKetID: item.NhomLienKetID ?? 0,
                                    NhomLienKetChiTietID: item.NhomLienKetChiTietID,
                                    NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
                                    TenHienThi: item.TenHienThi,
                                    TenNoiBo: item.TenNoiBo,
                                    SoLuong: item.SanPhamID > 0 ? item.SoLuong : $this.SanPham.SoLuong,
                                    DonGia: item.GiaBan_CuaHang,
                                    ThuTu: item.ThuTu,
                                    GhiChu: "",
                                    Is_MangVe: $this.SanPham.Is_MangVe ? 1 : 0,
                                    Is_SanPham: 0,
                                    Is_ThuocTinh: 1,
                                }
                                dataJson.push(topping)
                            }
                        })
                        const params = {
                            QrCode: vueData.QrCode,
                            Is_GuiBepBar: 1,
                            ChiTietOrder_JSON: JSON.stringify(dataJson),
                        }
                        ajaxCALL("/eorder/auth/HoaDon_Insert", params, (res) => {
                            if (res.data) {
                                webSocket_Send({ group: "bep", data: Date.now() })
                                webSocket_Send({ group: "order", data: Date.now() })
                                $this.onDelete() //Remove sản phẩm
                                vueData.IsShowDialogOrder = vueData.DSOrder.length > 0 //Show Modal danh sách món tạm nếu còn món
                                Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", { position: "top" })
                                //Push HoaDonID vào local
                                const hoaDonId = res.data[0].HoaDonID
                                if (hoaDonId) {
                                    vueData.HoaDonID = hoaDonId
                                }
                                $this.DisableSend = false
                            }
                        })
                    }
                },
            })
        },
        onSave() {
            vueData.IsShowDialogDetailProduct = false
            vueData.IsShowDialogOrder = true
        },
        updateToppingQuantity() {
            const $this = this
            $this.SanPham.ThuocTinh.map((item) => {
                if (item.SoLuongThucTe > 0 && item.SanPhamID > 0) {
                    item.SoLuong = item.SoLuongThucTe * $this.SanPham.SoLuong
                }
                return item
            })
        },
        onBlurQuantity(e) {
            let value = e.target.value.trim()
            const regex = /^(\d+(\.\d{0,3})?)?$/
            if (!regex.test(value)) {
                value = value.replace(/[^0-9.]/g, "")
            }
            if (value < 0 || value === "") {
                value = 1
            }
            //Lấy tối đa 3 số thập phân
            if (value.toString().includes(".")) {
                if (value.length - value.indexOf(".") > 2) {
                    value = parseFloat(value).toFixed(2)
                }
            }
            e.target.value = value
            this.SanPham.SoLuong = parseFloat(value)
            this.updateToppingQuantity()
        },
    },
}
</script>

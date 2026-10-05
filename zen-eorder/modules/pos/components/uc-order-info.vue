<template>
	<v-card elevation="0" class="order-info">
        <v-row class="ma-0 pt-1">
            <v-col :cols="isKhachHang ? 2 : 3">
                <!--@copy.prevent @paste.prevent-->
                <v-text-field :readonly="IsOldOrder" ref="refKhachHangQRCode" v-model="thanh_toan.KhachHang_QRCode" @copy.prevent @paste.prevent @keydown="onEnterQrCode" @focus="onFocusQrCode" @blur="onBlurQrCode" outlined dense hide-details label="F1 - Mã khách hàng" />
            </v-col>
            <v-col cols="3" v-if="isKhachHang">
                <p class="customer-info text-truncate">
                    <b>{{ thanh_toan.KhachHang_HoTen }} ({{ thanh_toan.KhachHang_DienThoai }})</b>
                    <br />
                    <b class="primary--text">{{ thanh_toan.KhachHang_ZEN?.toLocaleString("en-us") }} ZEN • {{ thanh_toan.KhachHang_LaTra?.toLocaleString("en-us") }} <v-icon small color="primary">mdi-leaf</v-icon></b>
                </p>
            </v-col>
            <v-col cols="1" class="d-flex align-center justify-space-around">
                <v-btn :color="thanh_toan.LoaiDonHang === 3 ? 'success' : 'error'" x-small fab elevation="0" @click="onClickShip"><v-icon>mdi-moped</v-icon></v-btn>
                <v-btn :color="thanh_toan.LoaiDonHang === 2 ? 'success' : 'error'" x-small fab elevation="0" @click="onClickTakeAway"><v-icon>mdi-shopping</v-icon></v-btn>
            </v-col>
            <v-col>
                <v-text-field :readonly="IsOldOrder" rows="1" ref="refGhiChu" v-model="thanh_toan.GhiChu" outlined dense hide-details label="F3 - Ghi chú"></v-text-field>
            </v-col>
            <v-col cols="1">
                <v-text-field ref="refSoCho" v-model="thanh_toan.SoCho" outlined dense hide-details type="number" label="F4 - Số chờ" />
            </v-col>
        </v-row>
        <v-row class="ma-0" v-if="IsShip">
            <v-col cols="2">
                <v-text-field v-model="thanh_toan.GiaoHang_BatDau" label="Bắt đầu giao" outlined dense hide-details></v-text-field>
            </v-col>
            <v-col cols="2">
                <v-text-field v-model="thanh_toan.GiaoHang_KetThuc" label="Kết thúc giao" outlined dense hide-details></v-text-field>
            </v-col>
            <v-col cols="5">
                <v-select v-model="thanh_toan.GiaoHang_CuaHangID" outlined dense hide-details label="Cửa hàng" :items="vueData.DSCuaHang" item-value="CuaHangID" item-text="TenCuaHang"></v-select>
            </v-col>
            <v-col cols="2">
                <v-text-field v-model="thanh_toan.GiaoHang_Phi" class="text-right" hide-details dense outlined label="Phí giao hàng"></v-text-field>
            </v-col>
            <v-col cols="1" class="d-flex align-center">
                <v-btn color="success" x-small class="fab v-btn--round" elevation="0" @click="IsShowDialogEditShip = true"><v-icon>mdi-account-box-edit-outline</v-icon></v-btn>
            </v-col>
        </v-row>
        <!-- Dialog thông tin giao hàng -->
        <v-dialog v-model="IsShowDialogEditShip" width="400">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title> Thông tin giao hàng </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="IsShowDialogEditShip = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-text-field v-model="thanh_toan.GiaoHang_TenKhachHang" label="Tên khách hàng" class="mt-4" outlined dense hide-details></v-text-field>
                    <v-text-field v-model="thanh_toan.GiaoHang_DienThoai" label="Số điện thoại" class="mt-4" outlined dense hide-details></v-text-field>
                    <v-textarea v-model="thanh_toan.GiaoHang_DiaChi" label="Địa chỉ nhận" rows="2" class="mt-4" outlined dense hide-details></v-textarea>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn text @click="IsShowDialogEditShip = false" color="primary">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-card>
</template>

<script>
	export default {
		props: ["thanh_toan", "socket_data"],
    data() {
        return {
            IsShip: false,
            IsTakeAway: false,
            IsShowDialogEditShip: false,
            IsShowDialogEditInvoice: false,
            IntervalQrCode: null,
        }
    },
    mounted: function () {
        const $this = this
        window.addEventListener("keydown", $this.onKeyDown) //Lắng nghe sự kiện KeyDown, sử dụng cho phím tắt

        //Nếu hoá đơn mới và tài khoản zen_order thì tự động bật mang về
        if ($this.thanh_toan.HoaDonID === 0 && vueData.user.UserID === "NV0000026") {
            $this.onClickShip()
        } else {
            $this.onToggleIconShipTakeAway() //Bật-tắt icon mang về và giao hàng dựa vào LoaiDonHang
        }
    },
    beforeDestroy() {
        const $this = this
        window.removeEventListener("keydown", $this.onKeyDown) //Hủy sự kiện KeyDown nếu destroy component
    },
    methods: {
        onKeyDown(event) {
            // Sử dụng mã keyCode của phím "F1 - Mã khách hàng"
            if (event.keyCode === 112) {
                const $this = this
                event.preventDefault()
                if (vueData.TabProduct === 0) {
                    $this.thanh_toan.KhachHang_QRCode = ""
                    $this.$refs.refKhachHangQRCode.focus()
                }
            }
            // Sử dụng mã keyCode của phím "F3 - Ghi chú"
            if (event.keyCode === 114) {
                const $this = this
                event.preventDefault()
                if (vueData.TabProduct === 0) {
                    $this.$refs.refGhiChu.focus()
                }
            }
            // Sử dụng mã keyCode của phím "F4 - Số chờ"
            if (event.keyCode === 115) {
                const $this = this
                event.preventDefault()
                if (vueData.TabProduct === 0) {
                    $this.$refs.refSoCho.focus()
                }
            }
        },
        onClickShip() {
            const $this = this
            //Nếu hóa đơn có chọn bàn thì không cho chọn đơn giao hàng
            if (vueData.HoaDon.BanID > 0) {
                Vue.$toast.warning("Bạn đã chọn bàn, hóa đơn đang dùng tại cửa hàng", { position: "top" })
                return
            }
            $this.IsShip = !$this.IsShip
            $this.IsTakeAway = false
            $this.thanh_toan.LoaiDonHang = $this.IsShip ? 3 : 1
            //Nếu không chọn giao hàng và mang về thì mặc định loại đơn hàng = 1 (dùng tại cửa hàng)
            if (!$this.IsShip && !$this.IsTakeAway) {
                $this.thanh_toan.LoaiDonHang = 1
            }
        },
        onClickTakeAway() {
            const $this = this
            //Nếu hóa đơn có chọn bàn thì không cho chọn đơn mang về
            if (vueData.HoaDon.BanID > 0) {
                Vue.$toast.warning("Bạn đã chọn bàn, hóa đơn đang dùng tại cửa hàng", { position: "top" })
                return
            }
            $this.IsTakeAway = !$this.IsTakeAway
            $this.IsShip = false
            $this.thanh_toan.LoaiDonHang = $this.IsTakeAway ? 2 : 1
            //Nếu không chọn giao hàng và mang về thì mặc định loại đơn hàng = 1 (dùng tại cửa hàng)
            if (!$this.IsShip && !$this.IsTakeAway) {
                $this.thanh_toan.LoaiDonHang = 1
            }
        },
        onEnterQrCode(e) {
            const $this = this
            if (e.code === "Enter" && e.target.value !== "") {
                $this.$refs.refKhachHangQRCode.blur()
            }
        },
        onFocusQrCode(e) {
            //Xử lý 2s clear input QrCode nếu nhập tay
            //Xóa đi interval lần trước để khởi tạo interval mới
            const $this = this
            if ($this.IntervalQrCode) {
                clearInterval($this.IntervalQrCode)
            }
            $this.IntervalQrCode = setInterval(() => {
                //Nếu trong 2s giá trị của QrCode không đủ 19 ký tự thì tự động clear
                if ($this.thanh_toan.KhachHang_QRCode.length > 0 && $this.thanh_toan.KhachHang_QRCode.length < 19) {
                    $this.$refs.refKhachHangQRCode.blur()
                }
            }, 2000)
        },
        onBlurQrCode(e) {
            const $this = this
            if ($this.thanh_toan.KhachHang_QRCode.length !== 19) {
                $this.thanh_toan.KhachHang_QRCode = ""
            }
            clearTimeout($this.IntervalQrCode)
            $this.getKhachHangByCode($this.thanh_toan.KhachHang_QRCode) //Gọi API lấy thông tin khách hàng
        },
        onToggleIconShipTakeAway() {
            const $this = this
            const invoiceType = $this.thanh_toan.LoaiDonHang

            //1: Dùng tại cửa hàng
            if (invoiceType === 1) {
                $this.IsTakeAway = false
                $this.IsShip = false
            }
            //2: Đơn mang về
            if (invoiceType === 2) {
                $this.IsTakeAway = true
                $this.IsShip = false
            }
            //3: Đơn giao hàng
            if (invoiceType === 3) {
                $this.IsShip = true
                $this.IsTakeAway = false
            }
        },
        getKhachHangByCode() {
            const $this = this
            let trimValue = trimWhitespace($this.thanh_toan.KhachHang_QRCode)
            //Nếu không có QrCode
            if (trimValue === "") {
                //Clear dữ liệu khách hàng
                $this.thanh_toan.KhachHangID = null
                $this.thanh_toan.KhachHang_QRCode = ""
                $this.thanh_toan.KhachHang_HoTen = ""
                $this.thanh_toan.KhachHang_DienThoai = ""
                $this.thanh_toan.KhachHang_ZEN = 0
                $this.thanh_toan.KhachHang_LaTra = 0
                //Tắt Is_ThanhToanZEN của món và Topping
                vueData.HoaDon.ChiTietHoaDon = vueData.HoaDon.ChiTietHoaDon.map((mon) => {
                    const topping = mon.ThuocTinh.map((thuocTinh) => ({
                        ...thuocTinh,
                        Is_ThanhToanZen: 0,
                    }))
                    mon.ThuocTinh = topping
                    mon.Is_ThanhToanZen = 0
                    mon.Is_KhuyenMai = 0
                    return mon
                })
            } else {
                const $this = this
                const params = { QrCode: trimValue }
                ajaxCALL("/eorder/KhachHang_Select_ByCode", params, (res) => {
                    if (res.data) {
                        const data = res.data[0]
                        $this.thanh_toan.KhachHangID = data.KhachHangID
                        $this.thanh_toan.KhachHang_QRCode = data.QRCode
                        $this.thanh_toan.KhachHang_HoTen = data.HoTen
                        $this.thanh_toan.KhachHang_DienThoai = data.DienThoai
                        $this.thanh_toan.KhachHang_ZEN = data.Diem
                        $this.thanh_toan.KhachHang_LaTra = data.DiemLaTra
                        //Dữ liệu socket màn hình menu khách
                        $this.socket_data.KhachHang = {
                            HoaDonID: $this.thanh_toan.HoaDonID,
                            KhachHangID: data.KhachHangID,
                            TenKhachHang: data.HoTen,
                            DienThoai: data.DienThoai,
                            ZEN: data.Diem,
                            LaTra: data.DiemLaTra,
                            TongZENConLai: $this.thanh_toan.TongZENConLai,
                        }
                        //Gửi socket
                        setTimeout(() => {
                            webSocket_Send({
                                group: vueData.webSocket_Hub_Menu,
                                data: JSON.stringify($this.socket_data),
                            })
                        }, 200)
                    }
                })
            }
        },
    },
    computed: {
        isKhachHang: function () {
            const $this = this
            return $this.thanh_toan.KhachHangID?.length === 9
        },
        IsOldOrder: function () {
            const $this = this
            return $this.thanh_toan.HoaDonID > 0 && checkTrangThaiButtonFooter($this.thanh_toan.TrangThai)
        },
    },
	}
</script>
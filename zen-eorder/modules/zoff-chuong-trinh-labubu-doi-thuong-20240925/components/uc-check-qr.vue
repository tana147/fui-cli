<template>
    <div class="text-center mt-10">
        <h2 class="red--text mb-2">Kiểm tra mã QR nhận thưởng</h2>
        <!--  @copy.prevent @paste.prevent -->
        <v-row>
            <v-col cols="8">
                <v-text-field ref="DoiThuong_QRCode" v-model="DoiThuong_QRCode" @keydown="handleEnterDoiThuong_QRCode" @copy.prevent @paste.prevent @focus="onFocusQRCode" @blur="onBlurQRCode" outlined dense hide-details label="Mã QR nhận thưởng"></v-text-field>
            </v-col>
            <v-col class="text-left">
                <v-btn color="primary" @click="handleDoiThuong_QRCode"><v-icon left>mdi-qrcode</v-icon>Kiểm tra</v-btn>
            </v-col>
        </v-row>
        <div v-if="IsQrSuccess" class="mt-5">
            <p class="primary--text mb-1"><b>Mã QR hợp lệ</b></p>
            <p class="mb-1">
                Cửa hàng: <b>{{ CTHoaDon?.TenCuaHang }}</b>
            </p>
            <p class="mb-1">
                Mã hóa đơn: <b>{{ CTHoaDon?.MaHoaDon }}</b>
            </p>
            <p class="mb-1">
                Tổng tiền hóa đơn: <b>{{ CTHoaDon?.TienPhaiTra.toLocaleString("vi-vn") }}</b>
            </p>
            <p class="mb-1">
                Ghi chú hóa đơn: <b>{{ CTHoaDon?.GhiChu_HoaDon }}</b>
            </p>
            <p class="mb-5">
                Ngày tạo: <b>{{ CTHoaDon?.GioThemMoi }} {{ CTHoaDon?.NgayThemMoi }}</b>
            </p>
            <v-btn color="error" @click="onCancel"><v-icon left>mdi-cancel</v-icon>Hủy bỏ</v-btn>
            <v-btn color="primary" @click="onConfirm" class="ml-3"><v-icon left>mdi-check-decagram</v-icon>Đồng ý</v-btn>
        </div>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            DoiThuong_QRCode: "",
            intervalQRCode: null,
            IsQrSuccess: false,
            CTHoaDon: null,
        }
    },
    mounted() {
        this.$refs.DoiThuong_QRCode.focus()
    },
    computed: {},
    watch: {},
    methods: {
        handleEnterDoiThuong_QRCode(e) {
            const $this = this
            if (e.code === "Enter" && e.target.value !== "") {
                $this.$refs.DoiThuong_QRCode.blur()
                //Gọi API check QR và lấy thông tin
                const params = {QrCode_TrungThuong: $this.DoiThuong_QRCode}
                ajaxCALL("/eorder/QuaTang_CheckQrCode", params, (res) => {
                    if (res.data && res.data[0]?.QuaTangSoTrungID > 0) {
                        const data = res.data[0]
                        $this.CTHoaDon = data
                        if (data?.Is_DoiThuong === 1) {
                            showMessage({
                                type: "red",
                                title: "Mã QR đã đổi thưởng",
                                message: `Mã QR đã đổi thưởng lúc ${data.DoiThuong_Ngay} ${data.DoiThuong_Gio} bởi ${data.TenDangNhap}`,
                            })
                        } else {
                            $this.IsQrSuccess = true
                        }
                    } else {
                        showMessage({
                            type: "red",
                            title: "Không hợp lệ",
                            message: `Mã QR trúng thưởng không hợp lệ, vui lòng kiểm tra lại`,
                        })
                    }
                })
            }
        },
        handleDoiThuong_QRCode(e) {
            const $this = this
            if (this.DoiThuong_QRCode !== "") {
                $this.$refs.DoiThuong_QRCode.blur()
                //Gọi API check QR và lấy thông tin
                const params = {QrCode_TrungThuong: $this.DoiThuong_QRCode}
                ajaxCALL("/eorder/QuaTang_CheckQrCode", params, (res) => {
                    if (res.data && res.data[0]?.QuaTangSoTrungID > 0) {
                        const data = res.data[0]
                        $this.CTHoaDon = data
                        if (data?.Is_DoiThuong === 1) {
                            showMessage({
                                type: "red",
                                title: "Mã QR đã đổi thưởng",
                                message: `Mã QR đã đổi thưởng lúc ${data.DoiThuong_Ngay} ${data.DoiThuong_Gio} bởi ${data.TenDangNhap}`,
                            })
                        } else {
                            $this.IsQrSuccess = true
                        }
                    } else {
                        showMessage({
                            type: "red",
                            title: "Không hợp lệ",
                            message: `Mã QR trúng thưởng không hợp lệ, vui lòng kiểm tra lại`,
                        })
                    }
                })
            }
        },
        onConfirm() {
            const $this = this
            confirm({
                title: `Đồng ý xác nhận quà tặng`,
                content: `Bạn có chắc muốn đồng ý xác nhận quà tặng?`,
                action: function () {
                    const params = {QrCode_TrungThuong: $this.DoiThuong_QRCode}
                    ajaxCALL("/eorder/QuaTang_Confirm", params, (res) => {
                        showMessage({
                            type: "green",
                            title: "Thành công",
                            message: `Khách hàng nhận được 1 phần quà Labubu`,
                        })
                        $thiss.DoiThuong_QRCode = ""
                        $thiss.IsQrSuccess = false
                        $thiss.CTHoaDon = null
                    })
                },
            })
        },
        onCancel() {
            window.location.reload()
        },
        onFocusQRCode(e) {
            const $this = this
            //Xóa đi interval lần trước để khởi tạo interval mới
            if ($this.intervalQRCode) {
                clearInterval($this.intervalQRCode)
            }
            $this.intervalQRCode = setInterval(() => {
                if ($this.DoiThuong_QRCode.length < 10) {
                    $this.DoiThuong_QRCode = ""
                }
            }, 2000)
        },
        onBlurQRCode(e) {
            const $this = this
            if ($this.DoiThuong_QRCode.length < 10) {
                $this.DoiThuong_QRCode = ""
            }
            clearTimeout($this.intervalQRCode)
        },
    },
}
</script>

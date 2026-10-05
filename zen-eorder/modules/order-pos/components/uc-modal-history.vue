<template>
	<div>
        <v-dialog v-model="is_show_dialog" fullscreen="" persistent="" transition="dialog-top-transition">
            <v-card class="model-order dialog-no-scoll">
                <div class="title white--text bg-green pa-2 text-center">
                    <span>{{ HoaDon?.MaHoaDon }}</span> ({{ HoaDon?.TenBan }})
                </div>
                <div class="order-body">
                    <div class="pa-2 border-bottom d-flex">
                        <p class="font-weight-bold">
                            Khách hàng: <span class="red--text">{{ ThongTin_KhachHang?.KhachHang_HoTen }}</span>
                            <span class="green--text">({{ ThongTin_KhachHang?.ZEN?.toLocaleString("vi-vn") }} ZEN)</span>
                        </p>
                    </div>
                    <div v-if="IsShowApprove" class="pa-2 border-bottom d-flex">
                        <div style="flex: 1">
                            <v-btn block="" @click="onClickScanQrCode" color="primary" elevation="0"> <v-icon left="">mdi-qrcode</v-icon>Quét mã khách hàng</v-btn>
                        </div>
                        <div class="ml-2">
                            <v-btn block="" @click="onClickGift" color="primary" elevation="0"><v-icon left="">mdi-gift</v-icon>Khuyến Mãi</v-btn>
                        </div>
                    </div>
                    <div class="product-history">
                        <template v-if="Is_OpenPaymentQr === false" v-for="(item, i) in HoaDon?.ChiTietHoaDon" :key="item.HoaDonChiTietID">
                            <uc-product-history :product="item" :order="HoaDon" :khachhang="ThongTin_KhachHang" :zen_con_lai="TongZENConLai">
                        </uc-product-history></template>
                        <div class="text-center pt-4" v-if="Is_OpenPaymentQr === true">
                            <f-qrcode v-model="QrCode_Payment_Content" logo="/_cdn/zen-eorder/logo-2025.png" size="240"></f-qrcode>
                            <p class="mb-4">
                                <b>{{ QrCode_Payment_Ten }}</b> <br>
                                {{ QrCode_Payment_Stk }} <br>
                                {{ QrCode_Payment_Text }}
                            </p>
                        </div>
                    </div>
                </div>
                <div class="order-footer">
                    <v-row v-if="IsShowApprove &amp;&amp; !Is_OpenPaymentQr" class="pa-2">
                        <v-col cols="12">
                            <span class="font-weight-bold">Khách trả:<br></span>
                        </v-col>
                        <v-col cols="12">
                            <v-row>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="TM" value="1"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="CK" value="2"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="QT" value="4"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="SPF" value="3"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="GRAB" value="6"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details="" v-model="KhachTra_Selected" label="XSM" value="7"></v-checkbox></v-col>
                                <!-- <v-col class="pt-0"><v-checkbox hide-details v-model="KhachTra_Selected" label="HT1" value="8"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details v-model="KhachTra_Selected" label="HT2" value="9"></v-checkbox></v-col>
                                <v-col class="pt-0"><v-checkbox hide-details v-model="KhachTra_Selected" label="HT3" value="10"></v-checkbox></v-col> -->
                            </v-row>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('1') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraTienMat_Format" label="Tiền mặt" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('2') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraChuyenKhoan_Format" label="Chuyển khoản" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('3') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraShopeeFood_Format" label="Shopee Food" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('6') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraGrab_Format" label="Grab" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('4') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraQuetThe_Format" label="Quẹt thẻ" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('7') >= 0">
                            <v-text-field dense="" outlined="" v-model="KhachTraXSM_Format" label="Xanh SM" class="text-right pt-0" hide-details=""></v-text-field>
                        </v-col>
                        <!-- <v-col cols="6" v-if="KhachTra_Selected.indexOf('8') >= 0">
                            <v-text-field dense outlined v-model="KhachTraHT1_Format" label="HT1" class="text-right pt-0" hide-details></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('9') >= 0">
                            <v-text-field dense outlined v-model="KhachTraHT2_Format" label="HT2" class="text-right pt-0" hide-details></v-text-field>
                        </v-col>
                        <v-col cols="6" v-if="KhachTra_Selected.indexOf('10') >= 0">
                            <v-text-field dense outlined v-model="KhachTraHT3_Format" label="HT3" class="text-right pt-0" hide-details></v-text-field>
                        </v-col> -->
                    </v-row>
                    <p v-if="IsShowInvoice" class="pa-2 border-top font-weight-bold d-flex flex-row">
                        <v-checkbox :disabled="!IsShowApprove || IsDisableInvoice" hide-details="" v-model="Invoice_IsXuatHoaDon" label="Xuất hóa đơn điện tử"></v-checkbox>
                        <v-chip v-if="Invoice_IsXuatHoaDon" color="success" small="" @click="onClickInvoice" class="ml-2">Chi tiết</v-chip>
                    </p>
                    <div class="pa-2 border-bottom border-top d-flex text-right justify-center justify-space-between font-weight-bold">
                        <div class="text-center">
                            <span>Tạm tính</span><br><b class="green--text">{{ HoaDon?.TongTien?.toLocaleString("vi-vn") }}</b>
                        </div>
                        <div class="text-center">
                            <span>VAT</span><br><b class="green--text">{{ HoaDon?.TongVAT?.toLocaleString("vi-vn") }}</b>
                        </div>
                        <div class="text-center">
                            <span>ZEN</span><br><b class="green--text">{{ TongZEN.toLocaleString("vi-vn") }}</b>
                        </div>
                        <div class="text-center">
                            <span>Thành tiền</span><br><b class="red--text">{{ KhachPhaiTra.toLocaleString("vi-vn") }}</b>
                        </div>
                    </div>
                    <v-row class="pa-2">
                        <v-col cols="4" class="pr-0">
                            <v-btn block="" @click="onClose()" elevation="0"><v-icon left="">mdi-arrow-left</v-icon>Menu</v-btn>
                        </v-col>
                        <v-col v-if="IsShowApprove" cols="8" class="text-right">
                            <v-btn :disabled="KhachTra_Selected.indexOf('2') >= 0 &amp;&amp; !Is_OpenPaymentQr" @click="onApproved()" block="" elevation="0" color="error"><v-icon left="">mdi-cash-check</v-icon>Xác nhận thanh toán</v-btn>
                        </v-col>
                        <v-col v-if="KhachTra_Selected.indexOf('2') >= 0" :cols="IsShowApprove ? '12' : '8'" :class="IsShowApprove ? 'pt-0' : ''">
                            <v-btn v-if="!Is_OpenPaymentQr" :disabled="KhachTraChuyenKhoan <= 0" block="" @click="onOpenQrCodePayment()" elevation="0" color="primary"><v-icon left="">mdi-qrcode</v-icon>QR Code chuyển khoản</v-btn>
                            <v-btn v-if="Is_OpenPaymentQr" block="" @click="Is_OpenPaymentQr = false" elevation="0" color="primary"><v-icon left="">mdi-food-turkey</v-icon>Quay lại danh sách món</v-btn>
                        </v-col>
                    </v-row>
                </div>
            </v-card>
            <f-qrcode-reader v-model="Is_OpenScanQr" v-on:update="KhachHang_QRCode = $event"></f-qrcode-reader>
            <uc-modal-voucher :ds_spkm="DSSanPham_KhuyenMai" :order="HoaDon.ChiTietHoaDon" :khid="ThongTin_KhachHang.KhachHangID">
        </uc-modal-voucher></v-dialog>
        <!-- Dialog thông tin xuất hóa đơn điện tử -->
        <v-dialog v-model="IsShowDialogEditInvoice" width="700">
            <v-card>
                <v-toolbar dense="" flat="">
                    <v-toolbar-title>Hóa đơn điện tử </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon="" @click="IsShowDialogEditInvoice = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <p class="font-weight-bold primary--text mb-2">Thông tin chung</p>
                    <v-row>
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerTaxCode" label="Mã số thuế" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea :readonly="!IsShowApprove" v-model="Invoice_BuyerLegalName" label="Tên công ty (đơn vị)" rows="2" outlined="" dense="" hide-details=""></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerPhoneNumber" label="Số điện thoại" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea :readonly="!IsShowApprove" v-model="Invoice_BuyerAddressLine" label="Địa chỉ" rows="2" outlined="" dense="" hide-details=""></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox :disabled="!IsShowApprove" hide-details="" v-model="Invoice_IsXuatSau" label="Lưu thông tin xuất sau"></v-checkbox>
                        </v-col>
                    </v-row>
                    <p @click="IsShowAdvanceInvoice = !IsShowAdvanceInvoice" class="cursor-pointer font-weight-bold primary--text mt-3 mb-2">
                        Thông tin thêm<v-icon color="success">{{ IsShowAdvanceInvoice ? "mdi-chevron-down" : "mdi-chevron-right" }}</v-icon>
                    </p>
                    <v-row v-show="IsShowAdvanceInvoice">
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerName" label="Tên khách hàng yêu cầu" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerEmail" label="Email" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerBankName" label="Tên ngân hàng" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field :readonly="!IsShowApprove" v-model="Invoice_BuyerBankAccount" label="Tài khoản ngân hàng" outlined="" dense="" hide-details=""></v-text-field>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer>
                    <v-btn text="" @click="IsShowDialogEditInvoice = false" color="primary">{{ IsShowApprove ? "Lưu" : "Đóng" }}</v-btn>
                </v-spacer></v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ["is_show_dialog"],
    data: function () {
        return {
            QrCode_Payment_Ten: "",
            QrCode_Payment_Stk: "",
            QrCode_Payment_Text: "",
            QrCode_Payment_Content: "",
            Is_OpenPaymentQr: false,
            Is_OpenScanQr: false,
            IsShowDialogEditInvoice: false,
            IsShowAdvanceInvoice: false,
            IsShowInvoice: true,
            IsDisableInvoice: true,
            Invoice_BuyerLegalName: "",
            Invoice_BuyerTaxCode: "",
            Invoice_BuyerPhoneNumber: "",
            Invoice_BuyerAddressLine: "",
            Invoice_IsXuatSau: true,
            Invoice_IsXuatHoaDon: false,
            Invoice_BuyerName: "",
            Invoice_BuyerEmail: "",
            Invoice_BuyerBankName: "",
            Invoice_BuyerBankAccount: "",
            TrangThai_XuatHoaDon: 0,
            HoaDon: {},
            KhachHang_QRCode: "",
            ThongTin_KhachHang: {
                KhachHangID: null,
                KhachHang_HoTen: "",
                ZEN: 0,
                DienThoai: "",
            },
            TongZENConLai: 0,
            KhachTraTienMat: this.HoaDon?.KhachTra_TienMat ?? 0,
            KhachTraChuyenKhoan: this.HoaDon?.KhachTra_CK ?? 0,
            KhachTraShopeeFood: this.HoaDon?.KhachTra_SPF ?? 0,
            KhachTraXSM: this.HoaDon?.KhachTra_XSM ?? 0,
            KhachTraGrab: this.HoaDon?.KhachTra_GRAB ?? 0,
            KhachTraQuetThe: this.HoaDon?.KhachTra_QT ?? 0,
            KhachTraHT1: this.HoaDon?.KhachTra_HT1 ?? 0,
            KhachTraHT2: this.HoaDon?.KhachTra_HT2 ?? 0,
            KhachTraHT3: this.HoaDon?.KhachTra_HT3 ?? 0,
            KhachTra_Selected: ["1"],
            DSSanPham_KhuyenMai: [],
        }
    },
    computed: {
        IsShowApprove() {
            //1: Chờ xử lý, 2: Chờ thanh toán, 3: Đã thanh toán, 4: Hoàn tất, 5: Đã hủy, 6: Đã thanh toán một phần, 7: Đã trả hàng, 8: Đặt trước, 9: Tiếp nhận đơn hàng
            return this.HoaDon.TrangThai === 1 || this.HoaDon.TrangThai === 9
        },
        TongZEN: function () {
            const $this = this
            let tongTienZEN = 0
            if ($this.HoaDon?.ChiTietHoaDon?.length > 0) {
                tongTienZEN = CT_TongZEN($this.HoaDon?.ChiTietHoaDon)
                $this.TongZENConLai = $this.ThongTin_KhachHang?.ZEN - tongTienZEN
                $this.HoaDon.KhachTra_Zen = tongTienZEN
            }
            return tongTienZEN
        },
        KhachPhaiTra: function () {
            const $this = this
            return CT_KhachPhaiTra($this.HoaDon?.TongTien, $this.HoaDon?.TongVAT, $this.TongZEN, $this.HoaDon?.GiaoHang_Phi)
        },
        KhachTraTienMat_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraTienMat, 0)
            },
            set: function (newValue) {
                this.KhachTraTienMat = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("1")
            },
        },
        KhachTraChuyenKhoan_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraChuyenKhoan, 0)
            },
            set: function (newValue) {
                this.KhachTraChuyenKhoan = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("2")
            },
        },
        KhachTraShopeeFood_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraShopeeFood, 0)
            },
            set: function (newValue) {
                this.KhachTraShopeeFood = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("3")
            },
        },
        KhachTraXSM_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraXSM, 0)
            },
            set: function (newValue) {
                this.KhachTraXSM = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("7")
            },
        },
        KhachTraGrab_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraGrab, 0)
            },
            set: function (newValue) {
                this.KhachTraGrab = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("6")
            },
        },
        KhachTraQuetThe_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraQuetThe, 0)
            },
            set: function (newValue) {
                this.KhachTraQuetThe = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("4")
            },
        },
        KhachTraHT1_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraHT1, 0)
            },
            set: function (newValue) {
                this.KhachTraHT1 = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("7")
            },
        },
        KhachTraHT2_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraHT2, 0)
            },
            set: function (newValue) {
                this.KhachTraHT2 = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("7")
            },
        },
        KhachTraHT3_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraHT3, 0)
            },
            set: function (newValue) {
                this.KhachTraHT3 = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("7")
            },
        },
    },
    watch: {
        is_show_dialog: function (isShow) {
            const $this = this
            if (isShow) {
                $this.Is_OpenPaymentQr = false
                const hoaDonID = vueData.HoaDonID
                if (hoaDonID && hoaDonID > 0) {
                    $this.getData() //First load
                }
            }
        },
        KhachHang_QRCode: function (value) {
            const $this = this
            let trimValue = trimWhitespace(value)
            if (trimValue === "") {
                $this.ThongTin_KhachHang = {
                    KhachHangID: null,
                    KhachHang_HoTen: "",
                    ZEN: 0,
                    DienThoai: "",
                }
            } else {
                const params = { QrCode: trimValue }
                ajaxCALL("/eorder/KhachHang_Select_ByCode", params, (res) => {
                    if (res.data) {
                        const data = res.data[0]
                        $this.ThongTin_KhachHang.KhachHangID = data.KhachHangID
                        $this.ThongTin_KhachHang.ZEN = data.Diem
                        $this.ThongTin_KhachHang.KhachHang_HoTen = data.HoTen
                        $this.ThongTin_KhachHang.DienThoai = data.DienThoai
                    }
                })
            }
        },
        KhachPhaiTra: function () {
            //Nếu có 1 hình thức thanh toán: Tự động điền tiền khách trả = tiền phải trả
            const $this = this
            if ($this.KhachTra_Selected.length === 1) {
                const val = $this.KhachTra_Selected
                if (val.indexOf("1") >= 0) {
                    $this.KhachTraTienMat = $this.KhachPhaiTra
                }
                if (val.indexOf("2") >= 0) {
                    $this.KhachTraChuyenKhoan = $this.KhachPhaiTra
                }
                if (val.indexOf("3") >= 0) {
                    $this.KhachTraShopeeFood = $this.KhachPhaiTra
                }
                if (val.indexOf("6") >= 0) {
                    $this.KhachTraGrab = $this.KhachPhaiTra
                }
                if (val.indexOf("4") >= 0) {
                    $this.KhachTraQuetThe = $this.KhachPhaiTra
                }
                if (val.indexOf("7") >= 0) {
                    $this.KhachTraXSM = $this.KhachPhaiTra
                }
                if (val.indexOf("8") >= 0) {
                    $this.KhachTraHT1 = $this.KhachPhaiTra
                }
                if (val.indexOf("9") >= 0) {
                    $this.KhachTraHT2 = $this.KhachPhaiTra
                }
                if (val.indexOf("10") >= 0) {
                    $this.KhachTraHT3 = $this.KhachPhaiTra
                }
            }
            //Nếu có 2 hình thức thanh toán trở lên thì set = 0
            else {
                $this.KhachTraTienMat = 0
                $this.KhachTraChuyenKhoan = 0
                $this.KhachTraShopeeFood = 0
                $this.KhachTraXSM = 0
                $this.KhachTraGrab = 0
                $this.KhachTraQuetThe = 0
                $this.KhachTraHT1 = 0
                $this.KhachTraHT2 = 0
                $this.KhachTraHT3 = 0
            }
        },
        KhachTra_Selected: function (val) {
            const $this = this
            if (val.length === 0) {
                $this.KhachTra_Selected = ["1"]
            }
            //Đặt lại số tiền thanh toán = 0 nếu không được chọn
            if (val.indexOf("1") < 0) {
                $this.KhachTraTienMat = 0
            }
            if (val.indexOf("2") < 0) {
                $this.KhachTraChuyenKhoan = 0
            }
            if (val.indexOf("3") < 0) {
                $this.KhachTraShopeeFood = 0
            }
            if (val.indexOf("6") < 0) {
                $this.KhachTraGrab = 0
            }
            if (val.indexOf("4") < 0) {
                $this.KhachTraQuetThe = 0
            }
            if (val.indexOf("7") < 0) {
                $this.KhachTraXSM = 0
            }
            if (val.indexOf("8") < 0) {
                $this.KhachTraHT1 = 0
            }
            if (val.indexOf("9") < 0) {
                $this.KhachTraHT2 = 0
            }
            if (val.indexOf("10") < 0) {
                $this.KhachTraHT3 = 0
            }
            //Nếu hình thức thanh toán > 2 thì uncheck hình thức đầu tiên
            if (val.length > 2) {
                $this.KhachTra_Selected.shift()
            }
            //Nếu có 1 hình thức thanh toán: Tự động điền tiền khách trả = tiền phải trả
            if (val.length === 1) {
                if (val.indexOf("1") >= 0) {
                    $this.KhachTraTienMat = $this.KhachPhaiTra
                }
                if (val.indexOf("2") >= 0) {
                    $this.KhachTraChuyenKhoan = $this.KhachPhaiTra
                }
                if (val.indexOf("3") >= 0) {
                    $this.KhachTraShopeeFood = $this.KhachPhaiTra
                }
                if (val.indexOf("6") >= 0) {
                    $this.KhachTraGrab = $this.KhachPhaiTra
                }
                if (val.indexOf("4") >= 0) {
                    $this.KhachTraQuetThe = $this.KhachPhaiTra
                }
                if (val.indexOf("7") >= 0) {
                    $this.KhachTraXSM = $this.KhachPhaiTra
                }
                if (val.indexOf("8") >= 0) {
                    $this.KhachTraHT1 = $this.KhachPhaiTra
                }
                if (val.indexOf("9") >= 0) {
                    $this.KhachTraHT2 = $this.KhachPhaiTra
                }
                if (val.indexOf("10") >= 0) {
                    $this.KhachTraHT3 = $this.KhachPhaiTra
                }
            }
            //Xử lý bật/tắt xuất hóa đơn điện tử nếu hóa đơn mới nếu có trong danh sách cửa hàng chỉ xuất TM
            //Tự động bật xuất hóa đơn -> GRAB, SPF, CK, QT, XSM
            //Tự động điền form thông tin xuất
            if ($this.IsShowApprove && $this.TrangThai_XuatHoaDon !== 0) {
                const isCashExport = $this.TrangThai_XuatHoaDon === 1
                $this.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
                $this.Invoice_BuyerAddressLine = $this.HoaDon.Invoice_CusAddessDefault ?? ""

                //2: CK, 3: SPF, 4: QT, 6: GRAB, 7: XSM, 8: HT1, 9: HT2, 10: HT3
                if (val.indexOf("2") >= 0 || val.indexOf("3") >= 0 || val.indexOf("4") >= 0 || val.indexOf("6") >= 0 || val.indexOf("7") >= 0 || val.indexOf("8") >= 0 || val.indexOf("9") >= 0 || val.indexOf("10") >= 0) {
                    if (isCashExport) {
                        $this.Invoice_IsXuatHoaDon = true
                        $this.IsDisableInvoice = true
                    }
                }
                //1 hoặc không chọn: TM
                else {
                    if (isCashExport) {
                        $this.Invoice_IsXuatHoaDon = false
                        $this.IsDisableInvoice = false
                    }
                    $this.resetFormInvoice() //Reset form
                }
                if (val.indexOf("3") >= 0) {
                    $this.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Shopee Food)"
                }
                if (val.indexOf("6") >= 0) {
                    $this.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App GRAB Food)"
                }
                if (val.indexOf("7") >= 0) {
                    $this.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Xanh SM)"
                }
            }
        },
    },
    methods: {
        resetFormInvoice() {
            const $this = this
            $this.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
            $this.Invoice_BuyerTaxCode = ""
            $this.Invoice_BuyerPhoneNumber = ""
            $this.Invoice_BuyerAddressLine = $this.HoaDon.Invoice_CusAddessDefault ?? ""
            $this.Invoice_IsXuatSau = true
            $this.Invoice_BuyerName = ""
            $this.Invoice_BuyerEmail = ""
            $this.Invoice_BuyerBankName = ""
            $this.Invoice_BuyerBankAccount = ""
        },
        getInfoCustomer() {
            const $this = this
            if ($this.Invoice_BuyerTaxCode === "") {
                Vue.$toast.error("Vui lòng nhập mã số thuế", {
                    position: "top",
                })
                return
            }
            $.get("https://api.vietqr.io/v2/business/" + $this.Invoice_BuyerTaxCode, {}, (res) => {
                if (res && res.code === "00") {
                    $this.Invoice_BuyerLegalName = res.data.name
                    $this.Invoice_BuyerAddressLine = res.data.address
                    Vue.$toast.success("Lấy thông tin thành công", {
                        position: "top",
                    })
                } else {
                    Vue.$toast.error("Không tìm thấy thông tin khách hàng từ mã số thuế", {
                        position: "top",
                    })
                }
            })
        },
        onClickInvoice() {
            const $this = this
            $this.IsShowDialogEditInvoice = true
        },
        onClose() {
            vueData.IsShowDialogHistory = false
        },
        onClickGift() {
            const $this = this
            const params = { KhachHangID: $this.ThongTin_KhachHang.KhachHangID, CuaHangID: $this.HoaDon.CuaHangID }
            ajaxCALL("/eorder/KhachHang_Select_KhuyenMai", params, (res) => {
                if (res.data) {
                    vueData.IsShowDialogKhuyenMai = true
                    $this.DSSanPham_KhuyenMai = res.data
                }
            })
        },
        onOpenQrCodePayment() {
            const $this = this
            const hoaDonID = vueData.HoaDonID
            if (hoaDonID && hoaDonID > 0) {
                const TKNganHang = vueData.TKNganHang[0]
                const data = {
                    Amount: $this.KhachTraChuyenKhoan ?? 0,
                    CuaHangID: $this.HoaDon.CuaHangID,
                    MaKH: $this.ThongTin_KhachHang.DienThoai,
                    MaHoaDon: $this.HoaDon?.MaHoaDon,
                }
                $this.QrCode_Payment_Content = renderQRCodePayment(data, TKNganHang)
                $this.QrCode_Payment_Ten = TKNganHang?.SoTaiKhoan ?? ""
                $this.QrCode_Payment_Stk = TKNganHang?.TenTaiKhoan ?? ""
                $this.QrCode_Payment_Text = TKNganHang?.TenCuaHang ?? ""
                $this.Is_OpenPaymentQr = true
            }
        },
        getData() {
            const $this = this
            const hoaDonID = vueData.HoaDonID
            if (hoaDonID && hoaDonID > 0) {
                const params = { HoaDonID: hoaDonID }
                ajaxCALL("/eorder/HoaDon_Select_ById", params, (res) => {
                    if (res.data) {
                        const resHoaDon = res.data[0][0] ?? {}
                        const resChiTietHoaDon = res.data[1] ?? []
                        //Xử lý khách hàng
                        $this.ThongTin_KhachHang.KhachHangID = resHoaDon.KhachHangID
                        $this.ThongTin_KhachHang.ZEN = resHoaDon.KhachHang_Diem
                        $this.ThongTin_KhachHang.KhachHang_HoTen = resHoaDon.KhachHang_HoTen
                        $this.KhachHang_QRCode = resHoaDon.KhachHang_QRCode
                        $this.TongZENConLai = resHoaDon.KhachHang_Diem - resHoaDon.KhachTra_Zen
                        //Xử lý thông tin hóa đơn điện tử
                        $this.Invoice_BuyerLegalName = resHoaDon.Invoice_BuyerLegalName
                        $this.Invoice_BuyerTaxCode = resHoaDon.Invoice_BuyerTaxCode
                        $this.Invoice_BuyerPhoneNumber = resHoaDon.Invoice_BuyerPhoneNumber
                        $this.Invoice_BuyerAddressLine = resHoaDon.Invoice_BuyerAddressLine
                        $this.Invoice_IsXuatSau = resHoaDon.Invoice_IsXuatSau
                        $this.Invoice_IsXuatHoaDon = resHoaDon.Is_XuatHoaDonDienTu
                        $this.Invoice_BuyerName = resHoaDon.Invoice_BuyerName
                        $this.Invoice_BuyerEmail = resHoaDon.Invoice_BuyerEmail
                        $this.Invoice_BuyerBankName = resHoaDon.Invoice_BuyerBankName
                        $this.Invoice_BuyerBankAccount = resHoaDon.Invoice_BuyerBankAccount
                        $this.TrangThai_XuatHoaDon = resHoaDon.TrangThai_XuatHoaDon
                        //Xử lý món
                        const productJsonData = []
                        const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
                        const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
                        productFilter.forEach((item, index) => {
                            const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
                            const product = { ...item, SoThuTu: index + 1, ThuocTinh: topping }
                            productJsonData.push(product)
                        })
                        const dataJson = { ...resHoaDon, ChiTietHoaDon: productJsonData }
                        $this.HoaDon = dataJson
                        //Xử lý checkbox khách trả
                        let hinhThucThanhToan = []
                        if (dataJson.KhachTra_TienMat > 0) {
                            hinhThucThanhToan.push("1")
                        }
                        if (dataJson.KhachTra_CK > 0) {
                            hinhThucThanhToan.push("2")
                        }
                        if (dataJson.KhachTra_SPF > 0) {
                            hinhThucThanhToan.push("3")
                        }
                        if (dataJson.KhachTra_GRAB > 0) {
                            hinhThucThanhToan.push("6")
                        }
                        if (dataJson.KhachTra_QT > 0) {
                            hinhThucThanhToan.push("4")
                        }
                        if (dataJson.KhachTra_XSM > 0) {
                            hinhThucThanhToan.push("7")
                        }
                        if (dataJson.KhachTra_HT1 > 0) {
                            hinhThucThanhToan.push("8")
                        }
                        if (dataJson.KhachTra_HT2 > 0) {
                            hinhThucThanhToan.push("9")
                        }
                        if (dataJson.KhachTra_HT3 > 0) {
                            hinhThucThanhToan.push("10")
                        }
                        $this.KhachTra_Selected = hinhThucThanhToan.length === 0 ? ["1"] : hinhThucThanhToan
                        $this.executeExportInvoice()
                    }
                })
            }
        },
        onApproved() {
            const $this = this
            //Kiểm tra số dư ZEN
            if ($this.HoaDon.KhachTra_Zen > $this.ThongTin_KhachHang.ZEN) {
                Vue.$toast.error("Điểm ZEN của khách không đủ để thực hiện thanh toán. Vui lòng kiểm tra lại", { position: "top" })
                return
            }
            const oldStatus = $this.HoaDon.TrangThai
            $this.HoaDon.TrangThai = 2 //Chờ thanh toán
            //Lấy danh sách món đã check ZEN nếu có
            let listZenChecked = []
            if ($this.ThongTin_KhachHang?.KhachHangID !== null) {
                $this.HoaDon?.ChiTietHoaDon.forEach((pro) => {
                    //Xử lý danh sách món check ZEN
                    if (pro.Is_ThanhToanZen === 1) {
                        listZenChecked.push(pro.HoaDonChiTietID)
                    }
                    //Xử lý danh sách topping check ZEN
                    pro.ThuocTinh.forEach((item) => {
                        if (item.SoLuong > 0 && item.Is_ThanhToanZen === 1) {
                            listZenChecked.push(item.HoaDonChiTietID)
                        }
                    })
                })
            }
            //Kiểm tra hình thức thanh toán: CK, QT, GRAB, SPF phải bắt buộc chọn xuất hóa đơn điện tử
            if (
                ($this.KhachTra_Selected.indexOf("2") >= 0 || //CK
                    $this.KhachTra_Selected.indexOf("3") >= 0 || //SPF
                    $this.KhachTra_Selected.indexOf("7") >= 0 || //XSM
                    $this.KhachTra_Selected.indexOf("4") >= 0 || //QT
                    $this.KhachTra_Selected.indexOf("8") >= 0 || //HT1
                    $this.KhachTra_Selected.indexOf("9") >= 0 || //HT2
                    $this.KhachTra_Selected.indexOf("10") >= 0 || //HT3
                    $this.KhachTra_Selected.indexOf("6") >= 0) && //GRAB
                !$this.Invoice_IsXuatHoaDon
            ) {
                Vue.$toast.error("Hình thức thanh toán bắt buộc xuất hóa đơn điện tử", { position: "top" })
                return
            }
            const params = {
                HoaDonID: $this.HoaDon.HoaDonID,
                KhachHangID: $this.ThongTin_KhachHang?.KhachHangID,
                DS_ThanhToanZen: listZenChecked.length > 0 ? listZenChecked.join(",") : "",
                KhachTra_TienMat: checkNumber($this.KhachTraTienMat) ? $this.KhachTraTienMat : 0,
                KhachTra_CK: checkNumber($this.KhachTraChuyenKhoan) ? $this.KhachTraChuyenKhoan : 0,
                KhachTra_SPF: checkNumber($this.KhachTraShopeeFood) ? $this.KhachTraShopeeFood : 0,
                KhachTra_XSM: checkNumber($this.KhachTraXSM) ? $this.KhachTraXSM : 0,
                KhachTra_GRAB: checkNumber($this.KhachTraGrab) ? $this.KhachTraGrab : 0,
                KhachTra_QT: checkNumber($this.KhachTraQuetThe) ? $this.KhachTraQuetThe : 0,
                KhachTra_HT1: checkNumber($this.KhachTraHT1) ? $this.KhachTraHT1 : 0,
                KhachTra_HT2: checkNumber($this.KhachTraHT2) ? $this.KhachTraHT2 : 0,
                KhachTra_HT3: checkNumber($this.KhachTraHT3) ? $this.KhachTraHT3 : 0,
                HinhThucThanhToan: $this.KhachTra_Selected.join(","),
                Invoice_BuyerLegalName: $this.Invoice_BuyerLegalName,
                Invoice_BuyerTaxCode: $this.Invoice_BuyerTaxCode,
                Invoice_BuyerPhoneNumber: $this.Invoice_BuyerPhoneNumber,
                Invoice_BuyerAddressLine: $this.Invoice_BuyerAddressLine,
                Invoice_IsXuatSau: $this.Invoice_IsXuatSau,
                Invoice_IsXuatHoaDon: $this.Invoice_IsXuatHoaDon,
                Invoice_BuyerName: $this.Invoice_BuyerName,
                Invoice_BuyerEmail: $this.Invoice_BuyerEmail,
                Invoice_BuyerBankName: $this.Invoice_BuyerBankName,
                Invoice_BuyerBankAccount: $this.Invoice_BuyerBankAccount,
            }
            ajaxCALL("/eorder/HoaDon_XacNhan", params, (res) => {
                if (res.data) {
                    webSocket_Send({ group: vueData.webSocket_Hub_Order, data: Date.now() })
                    Vue.$toast.success(`Xác nhận thanh toán thành công`, { position: "top" })
                    $this.Is_OpenPaymentQr = false
                } else {
                    $this.HoaDon.TrangThai = oldStatus //Cập nhật lại trạng thái cũ nếu lỗi
                }
            })
        },
        blurUpdateValueKhachHang_QRCode(e) {
            const $this = this
            //Xử lý thêm nếu danh sách món đã có các món check ZEN từ trước thì phải reset lại
            if ($this.HoaDon?.ChiTietHoaDon.length > 0) {
                $this.HoaDon.ChiTietHoaDon = $this.HoaDon?.ChiTietHoaDon.map((item) => {
                    const topping = item.ThuocTinh.map((tt) => ({ ...tt, Is_ThanhToanZen: 0 }))
                    return { ...item, Is_ThanhToanZen: 0, ThuocTinh: topping }
                })
            }
            $this.KhachHang_QRCode = e.target.value
        },
        handleEnterKhachHang_QRCode(e) {
            this.$refs.KhachHang_QRCode.blur()
        },
        calcPaymentMethod(inputMethod) {
            const $this = this
            let moneyRemain = 0
            if ($this.KhachTra_Selected.length === 2) {
                switch (inputMethod) {
                    case "1":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraTienMat
                        break
                    case "2":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraChuyenKhoan
                        break
                    case "3":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraShopeeFood
                        break
                    case "6":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraGrab
                        break
                    case "4":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraQuetThe
                        break
                    case "7":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraXSM
                        break
                    case "8":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraHT1
                        break
                    case "9":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraHT2
                        break
                    case "10":
                        moneyRemain = $this.KhachPhaiTra - $this.KhachTraHT3
                        break
                }
                const arrMethodRemain = $this.KhachTra_Selected.filter((item) => item !== inputMethod)
                if (arrMethodRemain.length !== 0) {
                    const methodRemain = arrMethodRemain[0]
                    switch (methodRemain) {
                        case "1":
                            $this.KhachTraTienMat = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "2":
                            $this.KhachTraChuyenKhoan = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "3":
                            $this.KhachTraShopeeFood = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "6":
                            $this.KhachTraGrab = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "4":
                            $this.KhachTraQuetThe = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "7":
                            $this.KhachTraXSM = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "8":
                            $this.KhachTraHT1 = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "9":
                            $this.KhachTraHT2 = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "10":
                            $this.KhachTraHT3 = moneyRemain > 0 ? moneyRemain : 0
                            break
                    }
                }
            }
        },
        formatAsCurrency(value, dec) {
            dec = dec || 0
            if (!value || value === null) {
                return 0
            }
            return "" + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
        },
        onClickScanQrCode($e) {
            const $this = this
            $this.Is_OpenScanQr = true
            $this.blurUpdateValueKhachHang_QRCode($e)
        },
        executeExportInvoice() {
            const $this = this
            //Xử lý xuất hóa đơn điện tử
            if ($this.TrangThai_XuatHoaDon === 0) {
                //0: Không xử lý
                $this.Invoice_IsXuatHoaDon = false
                $this.IsShowInvoice = false
                $this.resetFormInvoice()
            } else if ($this.TrangThai_XuatHoaDon === 1) {
                //1: Chỉ xuất TM
                $this.IsDisableInvoice = false
            } else if ($this.TrangThai_XuatHoaDon === 2) {
                //2: Mặc định luôn xuất
                $this.Invoice_IsXuatHoaDon = true
            }
            //Xử lý dữ liệu mặc định nếu đơn hàng mới
            if (vueData.HoaDonID === 0 && $this.TrangThai_XuatHoaDon !== 0) {
                $this.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
                $this.Invoice_BuyerAddressLine = $this.HoaDon.Invoice_CusAddessDefault ?? ""
            }
        },
    },
	}
</script>
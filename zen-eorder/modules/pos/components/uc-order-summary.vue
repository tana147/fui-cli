<template>
    <div style="width: 100%; display: flex; flex-direction: column; justify-content: space-between">
        <div class="pt-1" style="display: flex; justify-content: space-between; align-items: center">
            <p style="text-align: center; line-height: 0.9; border-right: 1px solid rgb(211 211 211); min-width: 25%">
                Tạm tính <br /><span class="text-right text-h6">{{ TongTienHoaDon.toLocaleString("vi-vn") }}</span>
            </p>
            <p style="text-align: center; line-height: 0.9; border-right: 1px solid rgb(211 211 211); min-width: 25%">
                VAT <br /><span class="text-right text-h6">{{ TongVAT.toLocaleString("vi-vn") }}</span>
            </p>
            <p style="text-align: center; line-height: 0.9; border-right: 1px solid rgb(211 211 211); min-width: 25%">
                ZEN <br /><span class="text-right primary--text text-h6">{{ TongZEN.toLocaleString("vi-vn") }}</span>
            </p>
            <p style="text-align: center; line-height: 0.9; min-width: 25%">
                Thành tiền <br /><span class="text-right red--text text-h6">{{ KhachPhaiTra.toLocaleString("vi-vn") }}</span>
            </p>
        </div>
        <div style="display: flex; flex-direction: column">
            <p>Khách trả:</p>
            <v-row style="margin: 0">
                <v-col cols="5" class="d-flex py-0" style="justify-content: space-around; align-items: center; flex-wrap: wrap; min-height: 60px">
                    <v-row>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="TM" value="1"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="CK" value="2"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="QT" value="4"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="SPF" value="3"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="GRAB" value="6"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="XSM" value="7"></v-checkbox></v-col>
                        <!-- <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="HT1" value="8"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="HT2" value="9"></v-checkbox></v-col>
                        <v-col cols="4" class="pa-0"><v-checkbox :disabled="IsOldOrder" hide-details v-model="value.HinhThucThanhToan" label="HT3" value="10"></v-checkbox></v-col> -->
                    </v-row>
                </v-col>
                <v-col class="pa-0" style="display: flex; align-items: center">
                    <v-row style="margin: 0">
                        <v-col v-if="value.HinhThucThanhToan.indexOf('1') >= 0 || value.HinhThucThanhToan.length === 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceTienMat" label="Tiền mặt" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('2') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceCK" label="Chuyển khoản" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('4') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceQT" label="Quẹt thẻ" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('3') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceSPF" label="Shopee Food" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('6') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceGRAB" label="Grab" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('7') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceXSM" label="Xanh SM" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <!-- <v-col v-if="value.HinhThucThanhToan.indexOf('8') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceHT1" label="HT1" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('9') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceHT2" label="HT2" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col>
                        <v-col v-if="value.HinhThucThanhToan.indexOf('10') >= 0"><v-text-field :readonly="IsOldOrder" dense v-model="FormatPriceHT3" label="HT3" class="text-right pt-0" reverse hide-details outlined></v-text-field></v-col> -->
                    </v-row>
                </v-col>
            </v-row>
        </div>
        <div class="d-flex align-center" :class="IsShowInvoice && !IsReplaceOrder ? 'justify-space-between' : 'justify-end'">
            <div v-if="IsShowInvoice && !IsReplaceOrder" class="d-flex">
                <p @click="onClickInvoice" class="cursor-pointer subtitle-1">Hoá đơn</p>
            </div>
            <div class="d-flex justify-end">
                <p v-if="value.GiaoHang_Phi > 0">
                    Phí giao hàng: <span class="text-right red--text">{{ value.GiaoHang_Phi.toLocaleString("vi-vn") }}</span>
                </p>
                <p class="pl-5">
                    Tiền thừa: <span class="text-right red--text">{{ TraLai.toLocaleString("vi-vn") }}</span>
                </p>
            </div>
        </div>
        <!-- Dialog thông tin xuất hóa đơn điện tử -->
        <v-dialog v-if="IsShowInvoice && !IsReplaceOrder" v-model="IsShowDialogEditInvoice" width="500">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>Thông tin hóa đơn điện tử</v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="IsShowDialogEditInvoice = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <p class="font-weight-bold primary--text mb-2">Thông tin chung</p>
                    <v-row>
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerTaxCode" label="Mã số thuế" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="value.Invoice_BuyerLegalName" label="Tên công ty (đơn vị)" rows="2" outlined dense hide-details></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerEmail" label="Email" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="value.Invoice_BuyerAddressLine" label="Địa chỉ" rows="2" outlined dense hide-details></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox hide-details v-model="value.Invoice_IsXuatSau" label="Lưu thông tin xuất sau"></v-checkbox>
                        </v-col>
                    </v-row>
                    <p @click="IsShowAdvanceInvoice = !IsShowAdvanceInvoice" class="cursor-pointer font-weight-bold primary--text mt-3 mb-2">
                        Thông tin thêm <v-icon color="success">{{ IsShowAdvanceInvoice ? "mdi-chevron-down" : "mdi-chevron-right" }}</v-icon>
                    </p>
                    <v-row v-show="IsShowAdvanceInvoice">
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerName" label="Tên khách hàng yêu cầu" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerPhoneNumber" label="Số điện thoại" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerBankName" label="Tên ngân hàng" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="value.Invoice_BuyerBankAccount" label="Tài khoản ngân hàng" outlined dense hide-details></v-text-field>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn text @click="onCancelInvoice" color="primary">Làm mới</v-btn>
                    <v-btn text @click="onSaveInvoice" color="primary">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
export default {
    props: ["value", "order"],
    data() {
        return {
            IsShowDialogEditInvoice: false,
            IsShowAdvanceInvoice: false,
            IsShowInvoice: true,
            defaultName: ["", "Khách hàng không lấy hóa đơn", "Khách hàng không lấy hoá đơn (App Shopee Food)", "Khách hàng không lấy hoá đơn (App GRAB Food)", "Khách hàng không lấy hoá đơn (App Xanh SM)"],
        }
    },
    watch: {
        "value.HinhThucThanhToan": function (val) {
            const $this = this
            const httt = $this.ThanhToan.HinhThucThanhToan
            const tt = $this.ThanhToan
            //Đặt lại số tiền thanh toán = 0 nếu không được chọn
            if (httt.indexOf("1") < 0) {
                tt.KhachTra_TienMat = 0
            }
            if (httt.indexOf("2") < 0) {
                tt.KhachTra_CK = 0
            }
            if (httt.indexOf("3") < 0) {
                tt.KhachTra_SPF = 0
            }
            if (httt.indexOf("6") < 0) {
                tt.KhachTra_GRAB = 0
            }
            if (httt.indexOf("4") < 0) {
                tt.KhachTra_QT = 0
            }
            if (httt.indexOf("7") < 0) {
                tt.KhachTra_XSM = 0
            }
            if (httt.indexOf("8") < 0) {
                tt.KhachTra_HT1 = 0
            }
            if (httt.indexOf("9") < 0) {
                tt.KhachTra_HT2 = 0
            }
            if (httt.indexOf("10") < 0) {
                tt.KhachTra_HT3 = 0
            }
            //Nếu hình thức thanh toán > 2 thì uncheck hình thức đầu tiên
            if (httt.length > 2) {
                httt.shift()
            }
            if (httt.length === 0) {
                tt.KhachTra_TienMat = $this.KhachPhaiTra
            }
            //Nếu có 1 hình thức thanh toán: Tự động điền tiền khách trả = tiền phải trả
            if (httt.length === 1) {
                if (httt.indexOf("1") >= 0) {
                    tt.KhachTra_TienMat = $this.KhachPhaiTra
                }
                if (httt.indexOf("2") >= 0) {
                    tt.KhachTra_CK = $this.KhachPhaiTra
                }
                if (httt.indexOf("3") >= 0) {
                    tt.KhachTra_SPF = $this.KhachPhaiTra
                }
                if (httt.indexOf("6") >= 0) {
                    tt.KhachTra_GRAB = $this.KhachPhaiTra
                }
                if (httt.indexOf("4") >= 0) {
                    tt.KhachTra_QT = $this.KhachPhaiTra
                }
                if (httt.indexOf("7") >= 0) {
                    tt.KhachTra_XSM = $this.KhachPhaiTra
                }
                if (httt.indexOf("8") >= 0) {
                    tt.KhachTra_HT1 = $this.KhachPhaiTra
                }
                if (httt.indexOf("9") >= 0) {
                    tt.KhachTra_HT2 = $this.KhachPhaiTra
                }
                if (httt.indexOf("10") >= 0) {
                    tt.KhachTra_HT3 = $this.KhachPhaiTra
                }
            }
            //Xử lý bật/tắt xuất hóa đơn điện tử nếu hóa đơn mới nếu có trong danh sách cửa hàng chỉ xuất TM
            if ($this.defaultName.indexOf($this.value.Invoice_BuyerLegalName) >= 0 && vueData.ChiTietCuaHang.TrangThai_XuatHoaDon > 0) {
                //Set giá trị mặc định
                $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
                $this.value.Invoice_BuyerAddressLine = vueData.ChiTietCuaHang.Invoice_CusAddessDefault ?? ""
                //Nếu cửa hàng luôn xuất
                if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 2) {
                    $this.value.Invoice_IsXuatHoaDon = true
                }
                //Không xuất TM
                else if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 1) {
                    //2: CK, 3: SPF, 4: QT, 6: GRAB, 7: XSM
                    if (httt.indexOf("2") >= 0 || httt.indexOf("3") >= 0 || httt.indexOf("4") >= 0 || httt.indexOf("6") >= 0 || httt.indexOf("7") >= 0 || httt.indexOf("8") >= 0 || httt.indexOf("9") >= 0 || httt.indexOf("10") >= 0) {
                        $this.value.Invoice_IsXuatHoaDon = true
                    } else {
                        $this.value.Invoice_IsXuatHoaDon = false
                        $this.resetFormInvoice() //Reset form
                    }
                }
                //Thay đổi tên khách: HTTT = SPF
                if (httt.indexOf("3") >= 0) {
                    $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Shopee Food)"
                }
                //Thay đổi tên khách: HTTT = GRAB
                if (httt.indexOf("6") >= 0) {
                    $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App GRAB Food)"
                }
                //Thay đổi tên khách: HTTT = XSM
                if (httt.indexOf("7") >= 0) {
                    $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Xanh SM)"
                }
            }
        },
    },
    computed: {
        IsOldOrder: function () {
            const $this = this
            return $this.value.HoaDonID > 0 && checkTrangThaiButtonFooter($this.value.TrangThai)
        },
        IsReplaceOrder: function () {
            const $this = this
            return $this.value.Is_HoaDonThayThe
        },
        ThanhToan: function () {
            const $this = this
            return $this.value
        },
        TongTienHoaDon: function () {
            const $this = this
            let tongTienHoaDon = 0
            if ($this.order) {
                const filterOrder = $this.order?.filter((item) => item.TrangThai !== 6 && item.TrangThai !== 7)
                tongTienHoaDon = CT_TongTienHoaDon(filterOrder)
                $this.value.TongTienHoaDon = tongTienHoaDon
            }
            return tongTienHoaDon
        },
        TongZEN: function () {
            const $this = this
            let tongTienZEN = 0
            if ($this.order) {
                const filterZENWithoutCancel = $this.order?.filter((item) => (item.TrangThai !== 6) & (item.TrangThai !== 7))
                tongTienZEN = CT_TongZEN(filterZENWithoutCancel)
                $this.value.TongZENConLai = $this.value.ZEN - tongTienZEN
                $this.value.TongZEN = tongTienZEN
            }
            return tongTienZEN
        },
        KhachPhaiTra: function () {
            const $this = this
            const ThanhToan = $this.value
            let sum = 0
            sum = CT_KhachPhaiTra($this.TongTienHoaDon, $this.TongVAT, $this.TongZEN, $this.value.GiaoHang_Phi)
            ThanhToan.KhachPhaiTra = sum
            return sum
        },
        TongTienHinhThucThanhToan: function () {
            const $this = this
            const ThanhToan = $this.value
            let sumMoney = CT_TongTienHinhThucThanhToan(ThanhToan.KhachTra_TienMat, ThanhToan.KhachTra_CK, ThanhToan.KhachTra_SPF, ThanhToan.KhachTra_GRAB, ThanhToan.KhachTra_XSM, ThanhToan.KhachTra_HT1, ThanhToan.KhachTra_HT2, ThanhToan.KhachTra_HT3)
            return sumMoney
        },
        TraLai: function () {
            const $this = this
            const ThanhToan = $this.value
            let sum = 0
            sum = CT_TraLai($this.TongTienHinhThucThanhToan, $this.KhachPhaiTra)
            if (sum < 0) {
                sum = 0
            }
            ThanhToan.TraLai = sum
            return sum
        },
        TongVAT: function () {
            const $this = this
            let sum = 0
            const ThanhToan = $this.value
            if ($this.order) {
                const filterZENWithoutCancel = $this.order?.filter((item) => (item.TrangThai !== 6) & (item.TrangThai !== 7))
                sum = CT_TongVAT(filterZENWithoutCancel)
                ThanhToan.TongVAT = sum
            }
            return sum
        },
        FormatPriceGiamGia: {
            get: function () {
                if (this.value.LoaiGiamGia === 0) {
                    return String(this.value.GiamGia_PhanTram === "" ? 0 : this.value.GiamGia_PhanTram)
                } else {
                    return this.formatAsCurrency(parseInt(this.value.GiamGia), 0)
                }
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                if (this.value.LoaiGiamGia === 0) {
                    if (_newVal === "") {
                        this.value.GiamGia_PhanTram = 0
                    } else {
                        this.value.GiamGia_PhanTram = _newVal
                    }
                } else {
                    this.value.GiamGia = Number(_newVal.replace(/[^0-9\.]/g, ""))
                }
            },
        },
        FormatPriceTienMat: {
            get: function () {
                return this.formatAsCurrency(parseFloat(this.value.KhachTra_TienMat), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(String(newVal))
                this.value.KhachTra_TienMat = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("1")
            },
        },
        FormatPriceCK: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_CK), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_CK = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("2")
            },
        },
        FormatPriceSPF: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_SPF), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_SPF = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("3")
            },
        },
        FormatPriceXSM: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_XSM), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_XSM = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("7")
            },
        },
        FormatPriceGRAB: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_GRAB), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_GRAB = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("6")
            },
        },
        FormatPriceQT: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_QT), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_QT = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("4")
            },
        },
        FormatPriceHT1: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_HT1), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_HT1 = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("8")
            },
        },
        FormatPriceHT2: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_HT2), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_HT2 = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("9")
            },
        },
        FormatPriceHT3: {
            get: function () {
                return this.formatAsCurrency(parseInt(this.value.KhachTra_HT3), 0)
            },
            set: function (newVal) {
                let _newVal = trimWhitespace(newVal)
                this.value.KhachTra_HT3 = Number(_newVal.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("10")
            },
        },
    },
    mounted: function () {
        const $this = this
        $this.executeExportInvoice()
    },
    methods: {
        calcPaymentMethod(inputMethod) {
            const $this = this
            let moneyRemain = 0
            if ($this.value.HinhThucThanhToan.length === 2) {
                switch (inputMethod) {
                    case "1":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_TienMat
                        break
                    case "2":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_CK
                        break
                    case "3":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_SPF
                        break
                    case "6":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_GRAB
                        break
                    case "4":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_QT
                        break
                    case "7":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_XSM
                        break
                    case "8":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_HT1
                        break
                    case "9":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_HT2
                        break
                    case "10":
                        moneyRemain = $this.KhachPhaiTra - $this.value.KhachTra_HT3
                        break
                }
                const arrMethodRemain = $this.value.HinhThucThanhToan.filter((item) => item !== inputMethod)
                if (arrMethodRemain.length !== 0) {
                    const methodRemain = arrMethodRemain[0]
                    switch (methodRemain) {
                        case "1":
                            $this.value.KhachTra_TienMat = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "2":
                            $this.value.KhachTra_CK = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "3":
                            $this.value.KhachTra_SPF = moneyRemain > 0 ? moneyRemain : 0
                            breakInvoice_IsXuat
                        case "6":
                            $this.value.KhachTra_GRAB = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "4":
                            $this.value.KhachTra_QT = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "7":
                            $this.value.KhachTra_XSM = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "8":
                            $this.value.KhachTra_HT1 = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "9":
                            $this.value.KhachTra_HT2 = moneyRemain > 0 ? moneyRemain : 0
                            break
                        case "10":
                            $this.value.KhachTra_HT3 = moneyRemain > 0 ? moneyRemain : 0
                            break
                    }
                }
            }
        },
        resetFormInvoice() {
            const $this = this
            $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
            $this.value.Invoice_BuyerTaxCode = ""
            $this.value.Invoice_BuyerPhoneNumber = ""
            $this.value.Invoice_BuyerAddressLine = vueData.ChiTietCuaHang.Invoice_CusAddessDefault ?? ""
            $this.value.Invoice_IsXuatSau = true
            $this.value.Invoice_BuyerName = ""
            $this.value.Invoice_BuyerEmail = ""
            $this.value.Invoice_BuyerBankName = ""
            $this.value.Invoice_BuyerBankAccount = ""
        },
        onClickInvoice() {
            const $this = this
            $this.IsShowDialogEditInvoice = true
        },
        getInfoCustomer() {
            const $this = this
            if ($this.value.Invoice_BuyerTaxCode === "") {
                Vue.$toast.error("Vui lòng nhập mã số thuế", {
                    position: "top",
                })
                return
            }
            $.get("https://api.vietqr.io/v2/business/" + $this.value.Invoice_BuyerTaxCode, {}, (res) => {
                if (res && res.code === "00") {
                    $this.value.Invoice_BuyerLegalName = res.data.name
                    $this.value.Invoice_BuyerAddressLine = res.data.address
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
        validatePercentage(value) {
            const $this = this
            if (Number(value) < 0 && $this.value.LoaiGiamGia === 0) {
                return "Giảm giá phần trăm không được âm"
            }
            if (value.includes(",") && $this.value.LoaiGiamGia === 1) {
                let _value = Number(value.split(",").join(""))
                if (_value < 0) {
                    return "Tiền giảm giá không được âm"
                }
            }
            let newValue = Number(value.replace(/[^0-9\.]/g, ""))
            const num = parseFloat(newValue)
            if ($this.value.LoaiGiamGia === 0) {
                if (isNaN(num) || num < 0 || num > 100) {
                    return "Phần trăm giảm giá phải nằm trong khoảng từ 0 đến 100"
                }
                return true
            } else {
                if (num > $this.TongTienHoaDon) {
                    return "Tiền giảm giá vượt quá tổng tiền hóa đơn"
                }
                return true
            }
        },
        formatAsCurrency(value, dec) {
            dec = dec || 0
            if (value === null) {
                return 0
            }
            return "" + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
        },
        onSaveInvoice() {
            const $this = this
            if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon > 0) {
                const httt = $this.ThanhToan.HinhThucThanhToan
                //Nếu cửa hàng không xuất TM & HTTT = TM & Tên Buyer không nằm trong điều kiện mặc định -> Tự động xuất hoá đơn
                if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 1 && (httt.indexOf("1") >= 0 || httt.length === 0) && $this.value.Invoice_BuyerLegalName !== "" && $this.defaultName.indexOf($this.value.Invoice_BuyerLegalName) < 0) {
                    $this.value.Invoice_IsXuatHoaDon = true
                }
                $this.IsShowDialogEditInvoice = false
            }
        },
        onCancelInvoice() {
            const $this = this
            //Không xử lý nếu cửa hàng không xuất
            if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon > 0) {
                confirm({
                    title: "Thao tác này sẽ làm mới thông tin?",
                    action: function () {
                        const httt = $this.ThanhToan.HinhThucThanhToan
                        //Bật/Tắt trạng thái xuất hoá đơn nếu cửa hàng không xuất TM & HTTT = TM
                        if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 1 && (httt.indexOf("1") >= 0 || httt.length === 0)) {
                            $this.value.Invoice_IsXuatHoaDon = false
                        } else {
                            $this.value.Invoice_IsXuatHoaDon = true
                        }
                        //Set giá trị mặc định
                        $this.resetFormInvoice()
                        //Thay đổi tên khách: HTTT = SPF
                        if (httt.indexOf("3") >= 0) {
                            $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Shopee Food)"
                        }
                        //Thay đổi tên khách: HTTT = GRAB
                        if (httt.indexOf("6") >= 0) {
                            $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App GRAB Food)"
                        }
                        //Thay đổi tên khách: HTTT = XSM
                        if (httt.indexOf("7") >= 0) {
                            $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hoá đơn (App Xanh SM)"
                        }
                    },
                })
            }
        },
        executeExportInvoice() {
            const $this = this
            //Xử lý xuất hóa đơn điện tử
            if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 0 || $this.value.Is_HoaDonThayThe === 1) {
                //0: Không xử lý
                $this.value.Invoice_IsXuatHoaDon = false
                $this.IsShowInvoice = false
                $this.resetFormInvoice()
            } else if (vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 2) {
                //2: Mặc định luôn xuất
                $this.value.Invoice_IsXuatHoaDon = true
            }
            //Xử lý dữ liệu mặc định nếu đơn hàng mới
            if ($this.value.HoaDonID === 0 && vueData.ChiTietCuaHang.TrangThai_XuatHoaDon !== 0) {
                $this.value.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
                $this.value.Invoice_BuyerAddressLine = vueData.ChiTietCuaHang.Invoice_CusAddessDefault ?? ""
            }
        },
    },
}
</script>

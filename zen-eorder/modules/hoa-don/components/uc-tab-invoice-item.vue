<template>
	<v-card outlined class="card-order pa-0">
        <v-card-text style="font-size: 14px; color: black; padding: 12px">
            <v-row class="white--text py-2 font-weight-bold" :style="StyleStatus">
                <v-col class="text-center" style="border-right: 2px dashed">
                    <span v-if="item.LoaiDonHang === 1"> {{ item.TenKhu }}-{{ item.TenBan }}</span>
                    <span v-if="item.GrabOrderID">GRAB</span>
                </v-col>
                <v-col class="text-center" cols="3" style="border-right: 2px dashed">{{ item.MaHoaDon }}</v-col>
                <v-col class="text-center">
                    <span class="text-center">{{ item.GioThemMoi }}</span>
                </v-col>
            </v-row>
            <v-row style="background-color: #d5ffd7">
                <v-col class="px-1"><v-text-field dense prepend-inner-icon="mdi-square-edit-outline" v-model="item.GhiChu" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between" class="pt-1" style="border-top: 1px dashed rgb(57, 119, 68)">
                <v-col cols="4">Order</v-col>
                <v-col class="text-right">{{ item.NhanVienThemMoi }}</v-col>
            </v-row>
            <v-row justify="space-between">
                <v-col cols="4">Tạm tính</v-col>
                <v-col class="text-right font-weight-bold blue--text">{{ item.TongTien.toLocaleString("vi-vn") }}đ</v-col>
            </v-row>
            <v-row justify="space-between">
                <v-col cols="4">VAT</v-col>
                <v-col class="text-right font-weight-bold">{{ item.TongVAT.toLocaleString("vi-vn") }}đ</v-col>
            </v-row>
            <v-row justify="space-between">
                <v-col cols="4">ZEN</v-col>
                <v-col class="text-right success--text font-weight-bold">{{ item.KhachTra_Zen.toLocaleString("vi-vn") }} ZEN</v-col>
            </v-row>
            <v-row justify="space-between pb-1">
                <v-col cols="5"><b>Khách phải trả</b></v-col>
                <v-col class="text-right font-weight-bold red--text">{{ item.TienPhaiTra.toLocaleString("vi-vn") }}đ</v-col>
            </v-row>
            <v-row justify="space-between pt-2" style="border-top: 1px dashed rgb(57, 119, 68)">
                <v-col class="mb-2"><b>Khách trả</b></v-col>
            </v-row>
            <v-row justify="space-between mt-0 mb-1">
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="TM" value="1"></v-checkbox></v-col>
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="CK" value="2"></v-checkbox></v-col>
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="QT" value="4"></v-checkbox></v-col>
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="SPF" value="3"></v-checkbox></v-col>
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="GRAB" value="6"></v-checkbox></v-col>
                <v-col><v-checkbox hide-details v-model="KhachTra_Selected" label="XSM" value="7"></v-checkbox></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('1') >= 0 || KhachTra_Selected.length === 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Tiền mặt:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraTienMat_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('2') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Chuyển khoản:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraChuyenKhoan_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('3') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Shopee Food:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraShopeeFood_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('6') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Grab:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraGrab_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('7') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Xanh SM:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraXSM_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('4') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">Quẹt thẻ:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraQuetThe_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <!-- <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('8') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">HT1:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraHT1_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('9') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">HT2:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraHT2_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row>
            <v-row justify="space-between mt-0" v-if="KhachTra_Selected.indexOf('10') >= 0">
                <v-col cols="5" class="px-0"><v-subheader class="black--text">HT3:</v-subheader></v-col>
                <v-col class="text-right"><v-text-field reverse v-model="KhachTraHT3_Format" class="text-right pt-0" hide-details></v-text-field></v-col>
            </v-row> -->
            <v-row justify="space-between my-3">
                <v-col><b>Tiền thừa:</b></v-col>
                <v-col class="text-right">{{ TienThua.toLocaleString("vi-vn") }}đ</v-col>
            </v-row>
            <v-row style="border-top: 1px dashed rgb(57, 119, 68)" class="pb-3 pt-2">
                <v-col cols="8" class="mt-2">
                    <v-btn v-if="item.GrabOrderID" @click="onFinishGrab()" block color="primary" elevation="0"><v-icon left>mdi-store-check</v-icon>Hoàn thành</v-btn>
                    <v-btn v-else block @click="onPayment()" color="primary" elevation="0"><v-icon left>mdi-cash-check</v-icon>Thanh Toán</v-btn>
                </v-col>
                <v-col cols="4" class="mt-2">
                    <v-menu offset-y>
                        <template v-slot:activator="{ on, attrs }">
                            <v-btn block v-on="on" class="elevation-0"><v-icon left>mdi-dots-vertical</v-icon><v-icon right>mdi-chevron-down</v-icon></v-btn>
                        </template>
                        <v-list dense>
                            <v-list-item class="cursor-pointer" link @click="onOpenDetail()">
                                <v-list-item-icon><v-icon>mdi-open-in-new</v-icon></v-list-item-icon>
                                <v-list-item-title>Xem chi tiết</v-list-item-title>
                            </v-list-item>
                            <v-list-item class="cursor-pointer" link @click="onOpenOnPos()">
                                <v-list-item-icon><v-icon>mdi-monitor-screenshot</v-icon></v-list-item-icon>
                                <v-list-item-title>Xem trên POS</v-list-item-title>
                            </v-list-item>
                            <v-list-item v-if="vueData.LoaiPhanHieuID !== 2" class="cursor-pointer" link @click="onPrint(1)">
                                <v-list-item-icon><v-icon>mdi-printer-pos-edit-outline</v-icon></v-list-item-icon>
                                <v-list-item-title>In tạm tính</v-list-item-title>
                            </v-list-item>
                            <v-list-item class="cursor-pointer" link @click="updatePayment()">
                                <v-list-item-icon>
                                    <v-icon>mdi-file-document-check-outline</v-icon>
                                </v-list-item-icon>
                                <v-list-item-title>Lưu thông tin</v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-menu>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
</template>

<script>
	export default {
		props: ["item"],
    data: function () {
        return {
            KhachTraTienMat: this.item.KhachTra_TienMat ?? 0,
            KhachTraChuyenKhoan: this.item.KhachTra_CK ?? 0,
            KhachTraShopeeFood: this.item.KhachTra_SPF ?? 0,
            KhachTraXSM: this.item.KhachTra_XSM ?? 0,
            KhachTraGrab: this.item.KhachTra_GRAB ?? 0,
            KhachTraQuetThe: this.item.KhachTra_QT ?? 0,
            KhachTraHT1: this.item.KhachTra_HT1 ?? 0,
            KhachTraHT2: this.item.KhachTra_HT2 ?? 0,
            KhachTraHT3: this.item.KhachTra_HT3 ?? 0,
            KhachTra_Selected: [],
        }
    },
    watch: {
        "item.TienPhaiTra": function () {
            //Nếu có 1 hình thức thanh toán: Tự động điền tiền khách trả = tiền phải trả
            const $this = this
            if ($this.KhachTra_Selected.length === 1) {
                const val = $this.KhachTra_Selected
                if (val.indexOf("1") >= 0) {
                    $this.KhachTraTienMat = $this.item.TienPhaiTra
                }
                if (val.indexOf("2") >= 0) {
                    $this.KhachTraChuyenKhoan = $this.item.TienPhaiTra
                }
                if (val.indexOf("3") >= 0) {
                    $this.KhachTraShopeeFood = $this.item.TienPhaiTra
                }
                if (val.indexOf("6") >= 0) {
                    $this.KhachTraGrab = $this.item.TienPhaiTra
                }
                if (val.indexOf("4") >= 0) {
                    $this.KhachTraQuetThe = $this.item.TienPhaiTra
                }
                if (val.indexOf("7") >= 0) {
                    $this.KhachTraXSM = $this.item.TienPhaiTra
                }
                if (val.indexOf("8") >= 0) {
                    $this.KhachTraHT1 = $this.item.TienPhaiTra
                }
                if (val.indexOf("9") >= 0) {
                    $this.KhachTraHT2 = $this.item.TienPhaiTra
                }
                if (val.indexOf("10") >= 0) {
                    $this.KhachTraHT3 = $this.item.TienPhaiTra
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
        KhachTra_Selected: {
            handler: function (val) {
                const $this = this
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
                //Nếu ko có hình thức thanh toán thì mặc định sẽ là tiền mặt
                if (val.length === 0) {
                    $this.KhachTraTienMat = $this.item.TienPhaiTra
                }
                //Nếu có 1 hình thức thanh toán: Tự động điền tiền khách trả = tiền phải trả
                if (val.length === 1) {
                    if (val.indexOf("1") >= 0) {
                        $this.KhachTraTienMat = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("2") >= 0) {
                        $this.KhachTraChuyenKhoan = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("3") >= 0) {
                        $this.KhachTraShopeeFood = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("6") >= 0) {
                        $this.KhachTraGrab = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("4") >= 0) {
                        $this.KhachTraQuetThe = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("7") >= 0) {
                        $this.KhachTraXSM = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("8") >= 0) {
                        $this.KhachTraHT1 = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("9") >= 0) {
                        $this.KhachTraHT2 = $this.item.TienPhaiTra
                    }
                    if (val.indexOf("10") >= 0) {
                        $this.KhachTraHT3 = $this.item.TienPhaiTra
                    }
                }
            },
            deep: true,
        },
        item: {
            handler: function (val) {
                this.KhachTraTienMat = this.item.KhachTra_TienMat
                this.KhachTraChuyenKhoan = this.item.KhachTra_CK
                this.KhachTraShopeeFood = this.item.KhachTra_SPF
                this.KhachTraXSM = this.item.KhachTra_XSM
                this.KhachTraGrab = this.item.KhachTra_GRAB
                this.KhachTraQuetThe = this.item.KhachTra_QT
                this.KhachTraHT1 = this.item.KhachTra_HT1
                this.KhachTraHT2 = this.item.KhachTra_HT2
                this.KhachTraHT3 = this.item.KhachTra_HT3
                //Khi item thay đổi thì phải render lại hình thức thanh toán
                this.fn_HinhThucThanhToan()
            },
        },
    },
    mounted() {
        this.fn_HinhThucThanhToan()
    },
    computed: {
        StyleStatus() {
            const $this = this
            let style = "color: #fff!important;background-color: #4caf50;font-size: 16px"
            if ($this.item.Is_TreMon_1) {
                style += `;color:#fff!important;background-color: rgb(255, 82, 82)`
            }
            if ($this.item.Is_TreMon_2) {
                style += `;color: #fff!important;background-color:${$this.item.MauThoiGianCheBien_2}`
            }
            if ($this.item.Is_YeuCauThanhToan) {
                style += `;color: #fff!important;background-color:${$this.item.MauYeuCauThanhToan}`
            }
            return style
        },
        TienThua() {
            this.item.TienThua = this.KhachTraTienMat + this.KhachTraChuyenKhoan + this.KhachTraShopeeFood + this.KhachTraXSM + this.KhachTraGrab + this.KhachTraQuetThe + this.KhachTraHT1 + this.KhachTraHT2 + this.KhachTraHT3 - this.item.TienPhaiTra
            return this.item.TienThua < 0 ? 0 : this.item.TienThua
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
                this.calcPaymentMethod("8")
            },
        },
        KhachTraHT2_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraHT2, 0)
            },
            set: function (newValue) {
                this.KhachTraHT2 = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("9")
            },
        },
        KhachTraHT3_Format: {
            get: function () {
                return this.formatAsCurrency(this.KhachTraHT3, 0)
            },
            set: function (newValue) {
                this.KhachTraHT3 = Number(newValue.replace(/[^0-9\.]/g, ""))
                this.calcPaymentMethod("10")
            },
        },
    },
    methods: {
        fn_HinhThucThanhToan() {
            const $this = this
            let hinhThucThanhToan = []
            let resultHinhThucThanhToan = []
            if ($this.item.KhachTra_TienMat > 0) hinhThucThanhToan.push("1")
            if ($this.item.KhachTra_CK > 0) hinhThucThanhToan.push("2")
            if ($this.item.KhachTra_SPF > 0) hinhThucThanhToan.push("3")
            if ($this.item.KhachTra_GRAB > 0) hinhThucThanhToan.push("6")
            if ($this.item.KhachTra_QT > 0) hinhThucThanhToan.push("4")
            if ($this.item.KhachTra_XSM > 0) hinhThucThanhToan.push("7")
            if ($this.item.KhachTra_HT1 > 0) hinhThucThanhToan.push("8")
            if ($this.item.KhachTra_HT2 > 0) hinhThucThanhToan.push("9")
            if ($this.item.KhachTra_HT3 > 0) hinhThucThanhToan.push("10")
            if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_CK > 0) resultHinhThucThanhToan.push("2")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_SPF > 0) resultHinhThucThanhToan.push("3")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_GRAB > 0) resultHinhThucThanhToan.push("6")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_QT > 0) resultHinhThucThanhToan.push("4")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_XSM > 0) resultHinhThucThanhToan.push("7")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_HT1 > 0) resultHinhThucThanhToan.push("8")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_HT2 > 0) resultHinhThucThanhToan.push("9")
            else if (hinhThucThanhToan.length === 1 && $this.item.KhachTra_HT3 > 0) resultHinhThucThanhToan.push("10")
            if (hinhThucThanhToan.length === 2) {
                if ($this.item.KhachTra_TienMat > 0) resultHinhThucThanhToan.push("1")
                if ($this.item.KhachTra_CK > 0) resultHinhThucThanhToan.push("2")
                if ($this.item.KhachTra_SPF > 0) resultHinhThucThanhToan.push("3")
                if ($this.item.KhachTra_GRAB > 0) resultHinhThucThanhToan.push("6")
                if ($this.item.KhachTra_QT > 0) resultHinhThucThanhToan.push("4")
                if ($this.item.KhachTra_XSM > 0) resultHinhThucThanhToan.push("7")
                if ($this.item.KhachTra_HT1 > 0) resultHinhThucThanhToan.push("8")
                if ($this.item.KhachTra_HT2 > 0) resultHinhThucThanhToan.push("9")
                if ($this.item.KhachTra_HT3 > 0) resultHinhThucThanhToan.push("10")
            }
            $this.KhachTra_Selected = resultHinhThucThanhToan //hinhThucThanhToan.length === 0 ? ['1'] : hinhThucThanhToan
        },
        calcPaymentMethod(inputMethod) {
            const $this = this
            let moneyRemain = 0
            if ($this.KhachTra_Selected.length === 2) {
                switch (inputMethod) {
                    case "1":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraTienMat
                        break
                    case "2":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraChuyenKhoan
                        break
                    case "3":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraShopeeFood
                        break
                    case "6":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraGrab
                        break
                    case "4":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraQuetThe
                        break
                    case "7":
                        moneyRemain = $this.item.TienPhaiTra - $this.KhachTraXSM
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
                    }
                }
            }
        },
        formatAsCurrency(value, dec) {
            dec = dec || 0
            if (value === null) {
                return 0
            }
            return "" + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
        },
        onOpenDetail() {
            const $this = this
            const params = { HoaDonID: $this.item.HoaDonID }
            ajaxCALL("/eorder/HoaDonChiTiet_Select_ByHoaDonId", params, (res) => {
                if (res.data) {
                    vueData.CTHoaDon = $this.item
                    vueData.DSChiTietHoaDon = res.data
                    vueData.IsShowDialogDetail = true
                }
            })
        },
        onOpenOnPos() {
            const $this = this
            window.open(`/pos?chid=${$this.item.CuaHangID}&hdid=${$this.item.HoaDonID}`, "_blank")
        },
        onPrint(type) {
            const $this = this
            const params = {
                HoaDonID: $this.item.HoaDonID,
                GhiChu: $this.item.GhiChu,
                LoaiIn: type, //1: Tạm tính; 2: Hóa đơn
            }
            ajaxCALL("/eorder/HoaDon_In", params, (res) => {
                if (res.data) {
                    Vue.$toast.success("In thành công", { position: "top" })
                }
            })
        },
        onPayment() {
            const $this = this
            //Thông báo xác nhận thanh toán khi có món chưa hoàn thành nếu là nhà hàng ẩm thực
            if (vueData.LoaiPhanHieuID !== 2 && $this.item.TongMonChuaTra > 0) {
                confirm({
                    title: "Xác nhận thanh toán",
                    content: `Hóa đơn có ${$this.item.TongMonChuaTra} món chưa hoàn thành. Bạn có muốn tiếp tục thanh toán?`,
                    action: function () {
                        $this.callPayment() //Gọi API thanh toán
                    },
                })
            } else {
                $this.callPayment() //Gọi API thanh toán
            }
        },
        onFinishGrab() {
            const $this = this
            //Cập nhật trạng thái đơn GRAB
            const params = {
                orderID: $this.item.GrabOrderID, //OrderID của GRAB
                markStatus: 1, //Đơn hàng sẵn sàng
            }

            const shortOrderNumber = JSON.parse($this.item.GrabDataJson)?.shortOrderNumber
            confirm({
                title: `Xác nhận hoàn thành đơn hàng GRAB ${shortOrderNumber}`,
                action: function () {
                    ajaxCALL(
                        "/eorder/GRABPUSH_Order_MarkStatus",
                        {
                            Json_Data: JSON.stringify(params),
                            HoaDonID: $this.item.HoaDonID,
                        },
                        (res) => {
                            if (res.data) {
                                getOrder()
                                //Xóa hóa đơn ra khỏi danh sách đơn đang tiếp nhận
                                const index = vueData.DSHoaDonDaTiepNhan_Res.findIndex((res) => res.HoaDonID === $this.item.HoaDonID)
                                if (index >= 0) {
                                    vueData.DSHoaDonDaTiepNhan_Res.splice(index, 1) //Remove order
                                }
                            }
                        },
                    )
                },
            })
        },
        callPayment() {
            const $this = this
            const params = {
                HoaDonID: $this.item.HoaDonID,
                GhiChu: $this.item.GhiChu,
                KhachTra_TienMat: checkNumber($this.KhachTraTienMat) ? $this.KhachTraTienMat : 0,
                KhachTra_CK: checkNumber($this.KhachTraChuyenKhoan) ? $this.KhachTraChuyenKhoan : 0,
                KhachTra_SPF: checkNumber($this.KhachTraShopeeFood) ? $this.KhachTraShopeeFood : 0,
                KhachTra_XSM: checkNumber($this.KhachTraXSM) ? $this.KhachTraXSM : 0,
                KhachTra_GRAB: checkNumber($this.KhachTraGrab) ? $this.KhachTraGrab : 0,
                KhachTra_QT: checkNumber($this.KhachTraQuetThe) ? $this.KhachTraQuetThe : 0,
                KhachTra_HT1: checkNumber($this.KhachTraHT1) ? $this.KhachTraHT1 : 0,
                KhachTra_HT2: checkNumber($this.KhachTraHT2) ? $this.KhachTraHT2 : 0,
                KhachTra_HT3: checkNumber($this.KhachTraHT3) ? $this.KhachTraHT3 : 0,
                HinhThucThanhToan: $this.KhachTra_Selected.length === 0 ? "1" : $this.KhachTra_Selected.join(","),
            }
            ajaxCALL("/eorder/HoaDon_ThanhToan", params, (res) => {
                if (res.data) {
                    confirm({
                        title: "Bạn có muốn in hóa đơn thanh toán?",
                        action: function () {
                            $this.onPrint(2)
                        },
                    })
                    getOrder()
                    const index = vueData.DSHoaDonDaTiepNhan_Res.findIndex((res) => res.HoaDonID === $this.item.HoaDonID)
                    if (index >= 0) {
                        vueData.DSHoaDonDaTiepNhan_Res.splice(index, 1) //Remove order
                    }
                }
            })
        },
        updatePayment() {
            const $this = this
            if ($this.item.HoaDonID) {
                confirm({
                    title: `Bạn có chắc muốn nhật thông tin hóa đơn ${$this.item.MaHoaDon}?`,
                    action: function () {
                        const params = {
                            HoaDonID: $this.item.HoaDonID,
                            KhachTra_TienMat: checkNumber($this.KhachTraTienMat) ? $this.KhachTraTienMat : 0,
                            KhachTra_CK: checkNumber($this.KhachTraChuyenKhoan) ? $this.KhachTraChuyenKhoan : 0,
                            KhachTra_SPF: checkNumber($this.KhachTraShopeeFood) ? $this.KhachTraShopeeFood : 0,
                            KhachTra_XSM: checkNumber($this.KhachTraXSM) ? $this.KhachTraXSM : 0,
                            KhachTra_GRAB: checkNumber($this.KhachTraGrab) ? $this.KhachTraGrab : 0,
                            KhachTra_QT: checkNumber($this.KhachTraQuetThe) ? $this.KhachTraQuetThe : 0,
                            KhachTra_HT1: checkNumber($this.KhachTra_HT1) ? $this.KhachTra_HT1 : 0,
                            KhachTra_HT2: checkNumber($this.KhachTra_HT2) ? $this.KhachTra_HT2 : 0,
                            KhachTra_HT3: checkNumber($this.KhachTra_HT3) ? $this.KhachTra_HT3 : 0,
                        }
                        ajaxCALL("/eorder/HoaDon_Update_HinhThucThanhToan", params, (res) => {
                            if (res.data) {
                                vueData.IsShowDialogDetail = false
                                Vue.$toast.success("Cập nhật thông tin hóa đơn thành công", { position: "top" })
                                getOrder()
                            }
                        })
                    },
                })
            }
        },
    },
	}
</script>
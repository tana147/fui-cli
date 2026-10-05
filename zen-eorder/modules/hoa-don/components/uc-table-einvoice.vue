<template>
	<div>
        <div class="page-section">
            <v-row>
                <v-col cols="4">
                    <v-select outlined v-model="DataFilter.CuaHangXuatID" dense label="Cửa hàng xuất" :items="vueData.DSCuaHangXuat" item-value="CuaHangID" item-text="TenCuaHang" hide-details />
                </v-col>
                <v-col cols="2">
                    <f-date outlined v-model="DataFilter.TuNgay" date-add="0" dense label="Từ ngày" hide-details />
                </v-col>
                <v-col cols="2">
                    <f-date outlined v-model="DataFilter.DenNgay" date-add="0" dense label="Đến ngày" hide-details />
                </v-col>
                <v-col cols="2">
                    <v-select outlined v-model="DataFilter.TrangThai" dense label="Trạng thái" :items="DSTrangThai" multiple persistent-hint hide-details />
                </v-col>
                <v-col cols="2">
                    <v-select outlined v-model="DataFilter.TrangThaiThue" dense label="Mã cơ quan thuế" :items="DSTrangThaiXuat" hide-details />
                </v-col>
                <v-col cols="3">
                    <v-combobox outlined v-model="DataFilter.NhanVienThucHien" dense label="Nhân viên thực hiện" :items="DSNhanVienThucHien" item-text="TenDangNhap" item-value="MaNhanVien" hide-details></v-combobox>
                </v-col>
                <v-col cols="3">
                    <v-btn color="primary" @click="getData()" class="elevation-0"><v-icon left>mdi-magnify</v-icon>Tìm</v-btn>
                    <v-btn @click="getData()" class="ml-2 elevation-0"><v-icon left>mdi-refresh</v-icon>Làm mới</v-btn>
                </v-col>
            </v-row>
            <div div class="d-flex flex-row justify-space-between mt-4">
                <div class="text-center">
                    Đã thanh toán <br />
                    <b class="red--text">{{ Tong_DaThanhToan.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Tổng thu <br />
                    <b class="red--text">{{ Tong_Thu.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Chờ xuất <br />
                    <b class="red--text">{{ Tong_ChoXuat.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Thành công <br />
                    <b class="red--text">{{ Tong_ThanhCong.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Thất bại <br />
                    <b class="red--text">{{ Tong_ThatBai.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Tổng hủy <br />
                    <b class="red--text">{{ Tong_DaHuy.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Thay thế <br />
                    <b class="red--text">{{ Tong_ThayThe.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Bị thay thế <br />
                    <b class="red--text">{{ Tong_BiThayThe.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Tiền mặt <br />
                    <b class="red--text">{{ KhachTra_TienMat.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Chuyển khoản <br />
                    <b class="red--text">{{ KhachTra_CK.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    ShopeeFood <br />
                    <b class="red--text">{{ KhachTra_SPF.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Grab <br />
                    <b class="red--text">{{ KhachTra_GRAB.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Quẹt thẻ <br />
                    <b class="red--text">{{ KhachTra_QT.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    Xanh SM <br />
                    <b class="red--text">{{ KhachTra_XSM.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    HT1 <br />
                    <b class="red--text">{{ KhachTra_HT1.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    HT2 <br />
                    <b class="red--text">{{ KhachTra_HT2.toLocaleString("vi-vn") }}</b>
                </div>
                <div class="text-center">
                    HT3 <br />
                    <b class="red--text">{{ KhachTra_HT3.toLocaleString("vi-vn") }}</b>
                </div>
            </div>
        </div>

        <f-table
            class="mt-1"
            :excel="true"
            :items-per-page="20"
            :footer-props="{ 'items-per-page-options': [20, 50, 100, 200] }"
            label="Danh sách hóa đơn điện tử"
            item-key="invoiceId"
            :items="DataInvoice"
            :headers="HeaderTable"
            height="calc(100vh - 408px)"
            :show-search="true"
            :fixed-header="true"
            dense
        >
        </f-table>

        <v-dialog v-model="vueData.isShowModalMaLoi" max-width="500px">
            <v-card>
                <v-card-title>Thông tin mã lỗi</v-card-title>
                <v-card-text>
                    <div v-if="vueData.MaLoiObject">
                        <pre style="white-space: pre-wrap">{{ vueData.MaLoiObject }}</pre>
                    </div>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" text @click="closeDialogMessageError"> Đóng </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="vueData.isShowModalDetailInvoice" max-width="1000px">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title>
                        <b class="primary--text ml-1"> {{ vueData.detailInvoice.MaHoaDon }}</b>
                    </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.isShowModalDetailInvoice = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="12" class="pb-2">
                            <h3 class="primary--text">Thông tin hóa đơn</h3>
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_ResultInvoiceNo" label="Số hóa đơn" outlined dense hide-details />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_ResultCodeOfTax" label="Mã CQT" outlined dense hide-details />
                        </v-col>
                         <v-col cols="5">
                            <v-text-field readonly v-model="vueData.detailInvoice.Invoice_TransactionUuid" label="Mã UUID" outlined dense hide-details />
                        </v-col>
                        <v-col cols="12" class="pb-2">
                            <h3 class="primary--text">Thông tin cửa hàng</h3>
                        </v-col>
                        <v-col cols="6">
                            <v-text-field readonly v-model="vueData.detailInvoice.Invoice_ResultReservationCode" label="Mã số bí mật" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_TemplateCode" label="Mẫu số hóa đơn" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_InvoiceSeries" label="Ký hiệu hóa đơn" outlined dense hide-details />
                        </v-col>
                        <v-col cols="2">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_CurrencyCode" label="Mã tiền tệ" outlined dense hide-details />
                        </v-col>
                        <v-col cols="9">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerLegalName" label="Tên người bán hợp lệ" outlined dense hide-details />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerTaxCode" label="Mã số thuế người bán" outlined dense hide-details />
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerAddressLine" label="Địa chỉ người bán" outlined dense hide-details />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerPhoneNumber" label="Điện thoại người bán" outlined dense hide-details />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerFaxNumber" label="Số fax người bán" outlined dense hide-details />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_SellerEmail" label="Email người bán" outlined dense hide-details />
                        </v-col>
                        <v-col cols="12" class="pb-2">
                            <h3 class="primary--text">Thông tin khách hàng</h3>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerLegalName" label="Tên người mua hợp lệ" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerTaxCode" label="Mã số thuế người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerPhoneNumber" label="Điện thoại người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerAddressLine" label="Địa chỉ người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerName" label="Tên người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerEmail" label="Email người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerBankName" label="Ngân hàng người mua" outlined dense hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="vueData.detailInvoice.Invoice_BuyerBankAccount" label="Tài khoản ngân hàng người mua" outlined dense hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" text @click="saveDetailInvoice(0)">Lưu thông tin</v-btn>
                    <v-btn v-if="vueData.detailInvoice.TrangThaiXuat !== 'SUCCESS' && vueData.detailInvoice.TrangThaiXuat !== 'REPLACE' && vueData.detailInvoice.TrangThaiXuat !== 'BEREPLACE'" color="primary" text @click="saveDetailInvoice(1)">Lưu & Xuất ngay</v-btn>
                    <v-btn color="primary" text @click="vueData.isShowModalDetailInvoice = false">Đóng</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="vueData.isShowModalPrintInvoice" max-width="800px">
            <v-card>
                <v-card-title class="d-flex bg-green">
                    <span class="text-white">In hóa đơn</span>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="closeModalPrintInvoice()"> <v-icon>mdi-close</v-icon></v-btn>
                </v-card-title>
                <v-card-text style="padding: 0px !important">
                    <div id="iframeContainer"></div>
                </v-card-text>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
	export default {
		props: ["chid", "einvoice_refresh"],
    data() {
        return {
            DSTrangThai: [
                {
                    value: "PENDING",
                    text: "Chờ xuất",
                },
                {
                    value: "PROCESSING",
                    text: "Đang xuất",
                },
                {
                    value: "ERROR",
                    text: "Thất bại",
                },
                {
                    value: "SUCCESS",
                    text: "Thành công",
                },
                {
                    value: "CANCEL",
                    text: "Đã huỷ",
                },
                {
                    value: "REPLACE",
                    text: "Đã thay thế",
                },
                {
                    value: "BEREPLACE",
                    text: "Bị thay thế",
                },
            ],
            DSTrangThaiXuat: [
                {
                    value: "",
                    text: "Tất cả",
                },
                {
                    value: "1",
                    text: "Đã có mã CQT",
                },
                {
                    value: "0",
                    text: "Chưa có mã CQT",
                },
            ],

            HeaderTable: [
                {
                    text: "Mã hóa đơn (POS)",
                    value: "MaHoaDon",
                    width: 100,
                    align: "center",
                    el: "t-button",
                    attr: {
                        "v-if": "item.MaHoaDon",
                        color: "green",
                        ":label": "item.MaHoaDon",
                        ":action": {
                            FUN: "getDetailInvoice",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                },
                {
                    text: "Mã HĐĐT",
                    value: "Invoice_ResultInvoiceNo",
                    align: "center",
                },
                {
                    text: "Mã bí mật",
                    value: "Invoice_ResultReservationCode",
                    align: "center",
                },
                {
                    text: "Cửa hàng",
                    value: "TenCuaHang",
                    width: 350,
                },
                {
                    text: "Tên khách hàng",
                    value: "Invoice_BuyerLegalName",
                    width: 500,
                },
                {
                    text: "MST",
                    value: "Invoice_BuyerTaxCode",
                },
                {
                    text: "Tổng tiền thanh toán",
                    value: "TienPhaiTra",
                    align: "right",
                    el: "span",
                    innerHTML: "{{ item.TienPhaiTra.toLocaleString('vi-vn')  }}",
                },
                {
                    text: "ZEN",
                    value: "KhachTra_Zen",
                    el: "span",
                    innerHTML: "{{item.KhachTra_Zen.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Tiền mặt",
                    value: "KhachTra_TienMat",
                    el: "span",
                    innerHTML: "{{item.KhachTra_TienMat.toLocaleString('vi-vn')}}",
                },
                {
                    text: "CK",
                    value: "KhachTra_CK",
                    el: "span",
                    innerHTML: "{{item.KhachTra_CK.toLocaleString('vi-vn')}}",
                },
                {
                    text: "SPF",
                    value: "KhachTra_SPF",
                    el: "span",
                    innerHTML: "{{item.KhachTra_SPF.toLocaleString('vi-vn')}}",
                },
                {
                    text: "XSM",
                    value: "KhachTra_XSM",
                    el: "span",
                    innerHTML: "{{item.KhachTra_XSM.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Grab",
                    value: "KhachTra_GRAB",
                    el: "span",
                    innerHTML: "{{item.KhachTra_GRAB.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Quẹt thẻ",
                    value: "KhachTra_QT",
                    el: "span",
                    innerHTML: "{{item.KhachTra_QT.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT1",
                    value: "KhachTra_HT1",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT1.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT2",
                    value: "KhachTra_HT2",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT2.toLocaleString('vi-vn')}}",
                },
                {
                    text: "HT3",
                    value: "KhachTra_HT3",
                    el: "span",
                    innerHTML: "{{item.KhachTra_HT3.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Mã CQT",
                    value: "Invoice_ResultCodeOfTax",
                    align: "center",
                    width: 250,
                },
                {
                    text: "Trạng thái CQT",
                    value: "Status_ResultCodeOfTax",
                    align: "center",
                    el: "span",
                    innerHTML: "<v-chip v-if='item.Status_ResultCodeOfTax === 1' small color='success'>Đã phát hành</v-chip>",
                },
                {
                    text: "Giờ xuất hoá đơn",
                    value: "GioXuat_HienThi",
                    align: "center",
                    width: 150,
                },
                {
                    text: "Gửi mail",
                    value: "DaGuiMail",
                    width: 100,
                },
                {
                    text: "Nhân viên thực hiện",
                    value: "NhanVienXuat",
                },
                {
                    text: "Trạng thái xuất",
                    value: "TrangThaiXuat_Ten",
                    align: "center",
                    el: "v-chip",
                    attr: {
                        ":color": "item.TrangThaiXuat_Mau",
                        ":small": true,
                    },
                    innerHTML: "{{item.TrangThaiXuat_Ten}}",
                },
                {
                    text: "Mã lỗi",
                    value: "MessageError",
                    el: "v-btn",
                    attr: {
                        "v-if": "item.TrangThaiXuat == 'ERROR'",
                        ":icon": true,
                        color: "red",
                        ":small": true,
                        "v-on:click": "vueData.isShowModalMaLoi = true; vueData.MaLoiObject = JSON.parse(item.MessageError)",
                    },
                    innerHTML: [
                        {
                            el: "v-icon",
                            innerHTML: "mdi-alert-circle-outline",
                        },
                    ],
                },
                {
                    text: "",
                    el: "t-button",
                    value: "Button_SendMail",
                    attr: {
                        color: "green",
                        label: "Gửi mail",
                        "v-if": "item.TrangThaiXuat == 'SUCCESS'",
                        ":action": {
                            FUN: "sendMail",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                    align: "center",
                },
                {
                    text: "",
                    el: "t-button",
                    value: "Button_Print",
                    attr: {
                        "v-if": "item.TrangThaiXuat == 'SUCCESS'",
                        color: "green",
                        label: "In hóa đơn",
                        ":action": {
                            FUN: "getPrintInvoice",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                    align: "center",
                },
                {
                    text: "",
                    el: "t-button",
                    value: "Button_Reissue",
                    attr: {
                        "v-if": "item.TrangThaiXuat != 'SUCCESS' && item.TrangThaiXuat != 'CANCEL' && item.TrangThaiXuat != 'REPLACE' && item.TrangThaiXuat != 'BEREPLACE'",
                        color: "green",
                        ":label": "item.TrangThaiXuat == 'ERROR' ? 'phát hành lại' : 'phát hành ngay'",
                        ":action": {
                            FUN: "createInvoice",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                    align: "center",
                },
            ],
            DataFilter: {
                CuaHangXuatID: this.chid,
                TuNgay: moment().format("YYYY-MM-DD"),
                DenNgay: moment().format("YYYY-MM-DD"),
                TrangThai: "",
                TrangThaiThue: "",
                NhanVienThucHien: "",
            },
            DataInvoice: [],
            DSNhanVienThucHien: [],
            Tong_DaThanhToan: 0,
            Tong_Thu: 0,
            Tong_ChoXuat: 0,
            Tong_ThanhCong: 0,
            Tong_ThatBai: 0,
            Tong_DaHuy: 0,
            Tong_ThayThe: 0,
            Tong_BiThayThe: 0,
            KhachTra_TienMat: 0,
            KhachTra_CK: 0,
            KhachTra_SPF: 0,
            KhachTra_XSM: 0,
            KhachTra_GRAB: 0,
            KhachTra_QT: 0,
            KhachTra_HT1: 0,
            KhachTra_HT2: 0,
            KhachTra_HT3: 0,
        }
    },
    mounted() {
        this.getData()
    },
    watch: {
        chid: function () {
            this.getData()
        },
        einvoice_refresh: function () {
            this.getData()
        },
    },
    methods: {
        getData() {
            const $this = this
            $this.resetData()
            const params = {
                ...$this.DataFilter,
                TrangThai: $this.DataFilter.TrangThai ? $this.DataFilter.TrangThai.join(",") : "",
                NhanVienThucHien: $this.DataFilter.NhanVienThucHien?.MaNhanVien ?? "0",
            }

            ajaxCALL("/eorder/HoaDonDienTu_Select_Table_ByCuaHangId", params, (res) => {
                if (!res.data) return
                const [Invoices, Staffs] = res.data
                $this.DataInvoice = Invoices
                $this.DSNhanVienThucHien = Staffs
                //Tính tổng tiền
                res.data[0].map((item) => {
                    //Đã thanh toán (chờ xuất, thất bại, thành công, bị thay thế, đã thay thế, tổng huỷ)
                    if (item.TrangThaiXuat === "PENDING" || item.TrangThaiXuat === "ERROR" || item.TrangThaiXuat === "SUCCESS" || item.TrangThaiXuat === "REPLACE" || item.TrangThaiXuat === "BEREPLACE" || item.TrangThaiXuat === "CANCEL") {
                        $this.Tong_DaThanhToan += item.TienPhaiTra
                    }
                    //Tổng Thu (chờ xuất, thành công, đã thay thế)
                    if (item.TrangThaiXuat === "PENDING" || item.TrangThaiXuat === "SUCCESS" || item.TrangThaiXuat === "REPLACE") {
                        $this.Tong_Thu += item.TienPhaiTra
                    }
                    //Chờ xuất
                    if (item.TrangThaiXuat === "PENDING") {
                        $this.Tong_ChoXuat += item.TienPhaiTra
                    }
                    //Thành công
                    if (item.TrangThaiXuat === "SUCCESS") {
                        $this.Tong_ThanhCong += item.TienPhaiTra
                    }
                    //Thất bại
                    if (item.TrangThaiXuat === "ERROR") {
                        $this.Tong_ThatBai += item.TienPhaiTra
                    }
                    //Đã hủy
                    if (item.TrangThaiXuat === "CANCEL") {
                        $this.Tong_DaHuy += item.TienPhaiTra
                    }
                    //Thay thế
                    if (item.TrangThaiXuat === "REPLACE") {
                        $this.Tong_ThayThe += item.TienPhaiTra
                    }
                    //Bị thay thế
                    if (item.TrangThaiXuat === "BEREPLACE") {
                        $this.Tong_BiThayThe += item.TienPhaiTra
                    }
                    //Tính tiền khách trả
                    if (item.TrangThaiXuat === "SUCCESS" || item.TrangThaiXuat === "REPLACE") {
                        $this.KhachTra_TienMat += item.KhachTra_TienMat
                        $this.KhachTra_CK += item.KhachTra_CK
                        $this.KhachTra_SPF += item.KhachTra_SPF
                        $this.KhachTra_XSM += item.KhachTra_XSM
                        $this.KhachTra_GRAB += item.KhachTra_GRAB
                        $this.KhachTra_QT += item.KhachTra_QT
                        $this.KhachTra_HT1 += item.KhachTra_HT1
                        $this.KhachTra_HT2 += item.KhachTra_HT2
                        $this.KhachTra_HT3 += item.KhachTra_HT3
                    }
                })
            })
        },
        resetField() {
            const initFilter = {
                MaDonHang: "",
                TuNgay: moment().format("YYYY-MM-DD"),
                DenNgay: moment().format("YYYY-MM-DD"),
                TrangThai: "",
                NhanVienThucHien: "",
            }
            this.DataFilter = Object.assign({}, initFilter)
        },
        resetData() {
            const $this = this
            $this.DataInvoice = []
            $this.DSNhanVienThucHien = []
            $this.Tong_DaThanhToan = 0
            $this.Tong_Thu = 0
            $this.Tong_ChoXuat = 0
            $this.Tong_ThanhCong = 0
            $this.Tong_ThatBai = 0
            $this.Tong_DaHuy = 0
            $this.Tong_ThayThe = 0
            $this.Tong_BiThayThe = 0
            $this.KhachTra_TienMat = 0
            $this.KhachTra_CK = 0
            $this.KhachTra_SPF = 0
            $this.KhachTra_XSM = 0
            $this.KhachTra_GRAB = 0
            $this.KhachTra_QT = 0
            $this.KhachTra_HT1 = 0
            $this.KhachTra_HT2 = 0
            $this.KhachTra_HT3 = 0
        },
        closeDialogMessageError() {
            vueData.isShowModalMaLoi = false
            vueData.MaLoiObject = {}
        },
    },
	}
</script>
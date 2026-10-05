<template>
    <div>
        <div class="page-section">
            <v-row>
                <v-col cols="4">
                    <v-select outlined v-model="DataFilterReplace.CuaHangXuatID" dense label="Cửa hàng xuất" :items="vueData.DSCuaHangXuat" item-value="CuaHangID" item-text="TenCuaHang" hide-details />
                </v-col>
                <v-col cols="2">
                    <f-date outlined v-model="DataFilterReplace.TuNgay" date-add="0" dense label="Từ ngày" hide-details />
                </v-col>
                <v-col cols="2">
                    <f-date outlined v-model="DataFilterReplace.DenNgay" date-add="0" dense label="Đến ngày" hide-details />
                </v-col>
                <v-col cols="3">
                    <v-select outlined v-model="DataFilterReplace.TrangThai" dense label="Trạng thái" :items="DSTrangThai" hide-details />
                </v-col>
                <v-col cols="3">
                    <v-combobox outlined v-model="DataFilterReplace.NhanVienThucHien" dense label="Nhân viên thực hiện" :items="DSNhanVienThucHien" item-text="TenDangNhap" item-value="MaNhanVien" hide-details></v-combobox>
                </v-col>
                <v-col cols="3">
                    <v-btn color="primary" @click="getData()" class="elevation-0"><v-icon left>mdi-magnify</v-icon>Tìm</v-btn>
                    <v-btn @click="getData()" class="ml-2 elevation-0"><v-icon left>mdi-refresh</v-icon>Làm mới</v-btn>
                </v-col>
            </v-row>
        </div>

        <f-table class="mt-1" :excel="true" :items-per-page="20" :footer-props="{'items-per-page-options':[20,50,100,200]}" label="Danh sách hóa đơn thay thế" item-key="invoiceId" :items="DataInvoice" :headers="HeaderTable" height="calc(100vh - 408px)" :show-search="true" :fixed-header="true" dense> </f-table>

        <v-dialog v-model="vueData.isShowModalDetailInvoiceReplace" max-width="600px">
            <v-card>
                <v-toolbar dense flat>
                    <v-toolbar-title> Hóa đơn thay thế {{ vueData.detailInvoice.ThayThe_MaHoaDon }} </v-toolbar-title>
                    <v-spacer></v-spacer>
                    <v-btn icon @click="vueData.isShowModalDetailInvoiceReplace = false"><v-icon>mdi-close</v-icon></v-btn>
                </v-toolbar>
                <v-card-text>
                    <v-row>
                        <v-col cols="12" class="pb-2">
                            <h3 class="primary--text">Thông tin hóa đơn điện tử</h3>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.XuLy_LyDoThayThe" label="Lý do thay thế" outlined dense hide-details />
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.XuLy_MaSoThue" label="Mã số thuế" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="vueData.detailInvoice.XuLy_TenKhachHang" label="Tên công ty (đơn vị)" rows="2" outlined dense hide-details></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="vueData.detailInvoice.XuLy_DiaChi" label="Địa chỉ" rows="2" outlined dense hide-details></v-textarea>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.XuLy_SoDienThoai" label="Số điện thoại" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.XuLy_Email" label="Email" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12">
                            <v-text-field v-model="vueData.detailInvoice.XuLy_SoHoaDonThayThe" label="Số hóa đơn thay thế" outlined dense hide-details></v-text-field>
                        </v-col>
                        <v-col cols="12" class="pb-0">
                            <h3 class="primary--text">Biên bản thỏa thuận</h3>
                        </v-col>
                        <v-col cols="12">
                            <div class="d-flex align-center">
                                <div>
                                    <f-file-upload v-model="vueData.fileUpload" color="primary" label="Chọn tập tin" :elevation="0" :url="vueData.v_Set.apiFile" :filters="0" />
                                </div>
                                <div v-if="file_einvoice.Files" class="ml-3">
                                    <a :href="vueData.v_Set.urlReadFile + file_einvoice.Files[0]?.FileID" target="_blank">{{ file_einvoice.Files[0]?.FileName }}</a>
                                    <v-btn v-if="file_einvoice.Files[0]?.FileID" @click="onDeleteFile" x-small fab elevation="0" class="ml-2" color="error"><v-icon>mdi-trash-can</v-icon></v-btn>
                                </div>
                            </div>
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" text @click="saveInvoiceReplace()">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>
<script>
export default {
    props: ["chid", "einvoice_refresh", "file_einvoice"],
    data() {
        return {
            DSTrangThai: [
                {
                    value: "",
                    text: "Tất cả",
                },
                {
                    value: "COMPLETED",
                    text: "Đã xử lý",
                },
                {
                    value: "PENDING",
                    text: "Chưa xử lý",
                },
            ],
            updateForm: [
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerLegalName",
                        label: "Tên người mua hợp lệ",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerTaxCode",
                        label: "Mã số thuế",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerPhoneNumber",
                        label: "Số điện thoại",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerAddressLine",
                        label: "Địa chỉ người mua",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerName",
                        label: "Tên người mua",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerEmail",
                        label: "Email",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerBankName",
                        label: "Tên ngân hàng",
                    },
                    w: 6,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "Invoice_BuyerBankAccount",
                        label: "Số tài khoản ngân hàng",
                    },
                    w: 6,
                },
                {
                    el: "v-checkbox",
                    attr: {
                        "v-model": "Is_XuatHoaDonDienTu",
                        label: "Xuất hóa đơn điện tử",
                    },
                    w: 4,
                },
                {
                    el: "v-checkbox",
                    attr: {
                        "v-model": "Invoice_IsXuatSau",
                        label: "Xuất sau",
                    },
                    w: 4,
                },
                {
                    el: "div",
                    attr: {},
                    w: 4,
                },
            ],
            HeaderTable: [
                {
                    text: "",
                    value: "ButtonChiTiet",
                    width: 100,
                    align: "center",
                    el: "t-button",
                    attr: {
                        color: "green",
                        label: "CHI TIẾT",
                        ":action": {
                            FUN: "getDetailInvoiceReplace",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                },
                {
                    text: "Chi nhánh",
                    value: "ChiNhanh",
                    width: 300,
                },
                {
                    text: "Trạng thái",
                    value: "TrangThai",
                    el: "span",
                    align: "center",
                    width: 150,
                    innerHTML: "<v-chip small :color='item.TrangThai_Mau'>{{item.TrangThai}}</v-chip>",
                },
                {
                    text: "Mã đơn hàng",
                    value: "DonHang_MaDonHang",
                    align: "center",
                },
                {
                    text: "Ngày đặt hàng",
                    value: "DonHang_NgayDatHang",
                    align: "center",
                    width: 200,
                },
                {
                    text: "HTTT",
                    value: "DonHang_HinhThucThanhToan",
                },
                {
                    text: "Số tiền",
                    value: "DonHang_SoTien",
                    align: "right",
                    el: "span",
                    innerHTML: "{{ item.DonHang_SoTien.toLocaleString('vi-vn')  }}",
                },
                {
                    text: "Mã đơn hàng thay thế",
                    value: "ThayThe_MaHoaDon",
                    align: "center",
                },
                {
                    text: "Ngày đặt hàng",
                    value: "ThayThe_NgayDatHang",
                    align: "center",
                    width: 200,
                },
                {
                    text: "HTTT",
                    value: "ThayThe_HinhThucThanhToan",
                },
                {
                    text: "Số tiền",
                    value: "ThayThe_SoTien",
                    align: "right",
                    el: "span",
                    innerHTML: "{{ item.ThayThe_SoTien.toLocaleString('vi-vn')  }}",
                },
                {
                    text: "Ký hiệu hóa đơn",
                    value: "BiThayThe_KyHieu",
                    align: "center",
                },
                {
                    text: "Số hóa đơn",
                    value: "BiThayThe_SoHoaDon",
                    align: "center",
                },
                {
                    text: "Ngày hóa đơn",
                    value: "BiThayThe_NgayHoaDon",
                    align: "center",
                    width: 200,
                },
                {
                    text: "Tên khách hàng",
                    value: "BiThayThe_TenKhachHang",
                    width: 500,
                },
                {
                    text: "Mã CQT",
                    value: "BiThayThe_MaCoQuanThue",
                    align: "center",
                    width: 350,
                },
                {
                    text: "Số tiền",
                    value: "BiThayThe_SoTien",
                    align: "right",
                    el: "span",
                    innerHTML: "{{ item.BiThayThe_SoTien.toLocaleString('vi-vn')  }}",
                },
                {
                    text: "Lý do thay thế",
                    value: "XuLy_LyDoThayThe",
                    width: 500,
                },
                {
                    text: "MST",
                    value: "XuLy_MaSoThue",
                    width: 250,
                },
                {
                    text: "Tên khách hàng",
                    value: "XuLy_TenKhachHang",
                    width: 500,
                },
                {
                    text: "Địa chỉ",
                    value: "XuLy_DiaChi",
                    width: 250,
                },
                {
                    text: "SĐT",
                    value: "XuLy_SoDienThoai",
                },
                {
                    text: "Email",
                    value: "XuLy_Email",
                },
                {
                    text: "Biên bản thỏa thuận",
                    value: "XuLy_BienBan",
                    width: 350,
                },
                {
                    text: "Số hóa đơn thay thế",
                    value: "XuLy_SoHoaDonThayThe",
                    width: 150,
                },
            ],
            DataFilterReplace: {
                CuaHangXuatID: this.chid,
                TuNgay: moment().format("YYYY-MM-DD"),
                DenNgay: moment().format("YYYY-MM-DD"),
                TrangThai: "",
                NhanVienThucHien: "",
            },
            DataInvoice: [],
            DSNhanVienThucHien: [],
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
        }
    },
    methods: {
        getData() {
            const $this = this
            $this.resetData()
            const params = {
                ...$this.DataFilterReplace,
                NhanVienThucHien: $this.DataFilterReplace.NhanVienThucHien?.MaNhanVien ?? "0",
            }
            ajaxCALL("/eorder/HoaDonDienTu_ThayThe_Select_Table_ByCuaHangId", params, (res) => {
                if (!res.data) return
                const [Invoices, Staffs] = res.data
                this.DataInvoice = Invoices
                this.DSNhanVienThucHien = Staffs
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
            this.DataFilterReplace = Object.assign({}, initFilter)
        },
        onDeleteFile() {
            vueData.fileUpload = {Files: []}
        },
        resetData() {
            this.DataInvoice = []
            this.DSNhanVienThucHien = []
        },
    },
}
</script>

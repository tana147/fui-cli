<template>
    <v-dialog v-model="vueData.IsShowDialogDetail" persistent width="1200">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>
                    <b class="primary--text ml-1">{{ vueData.CTHoaDon?.MaSoHoaDon }} • {{ vueData.CTHoaDon?.NgayThemMoi }} {{ vueData.CTHoaDon?.GioThemMoi }} • {{ vueData.CTHoaDon?.NhanVienThemMoi }} • {{ vueData.CTHoaDon?.HoaDonID }}</b>
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogDetail = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <div class="d-flex align-center" style="gap: 10px">
                    <div style="width: 120px"><b class="black--text">Hủy hóa đơn:</b></div>
                    <div style="flex: 1">
                        <v-select v-if="vueData?.CTHoaDon?.GrabOrderID" :disabled="vueData.CTHoaDon.TrangThai === 5" v-model="vueData.cancelCodeGRAB" label="Ghi chú hủy" :items="vueData.OptionsCancelOrder" outlined dense hide-details></v-select>
                        <v-text-field v-else :readonly="vueData.CTHoaDon.TrangThai === 5" v-model="vueData.CTHoaDon.GhiChu_Huy" label="Ghi chú hủy" outlined dense hide-details></v-text-field>
                        <v-text-field :readonly="vueData.CTHoaDon.TrangThai === 5" class="mt-2" v-if="vueData.CTHoaDon?.GrabOrderID && vueData?.CTHoaDon?.Invoice_ResultInvoiceNo !== null && vueData?.CTHoaDon?.Invoice_ResultInvoiceNo !== ''" v-model="vueData.CTHoaDon.ThayThe_LyDo" label="Lý do thay thế" outlined dense hide-details></v-text-field>
                    </div>
                    <div>
                        <v-btn :disabled="vueData.CTHoaDon.TrangThai === 5" v-if="vueData?.CTHoaDon?.Invoice_ResultInvoiceNo === null || vueData?.CTHoaDon?.Invoice_ResultInvoiceNo === ''" color="error" @click="onCancelOrder" elevation="0" style="width: 150px"><v-icon left>mdi-trash-can</v-icon>Hủy</v-btn>
                        <v-btn :disabled="vueData.CTHoaDon.TrangThai === 5" v-else color="error" @click="onReplaceOrder" elevation="0" style="width: 150px"><v-icon left>mdi-file-arrow-left-right</v-icon>Thay thế</v-btn>
                    </div>
                </div>
                <div class="d-flex align-center mt-3" style="gap: 10px" v-if="vueData.CTHoaDon.TrangThai === 3 || vueData.CTHoaDon.TrangThai === 4">
                    <div style="width: 120px"><b class="black--text">Khách trả:</b></div>
                    <div style="flex: 1">
                        <v-row>
                            <v-col cols="2"><v-text-field type="number" label="Tiền mặt" v-model="vueData.CTHoaDon.KhachTra_TienMat" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="Chuyển khoản" v-model="vueData.CTHoaDon.KhachTra_CK" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="ShopeeFood" v-model="vueData.CTHoaDon.KhachTra_SPF" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="Grab" v-model="vueData.CTHoaDon.KhachTra_GRAB" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="Quẹt thẻ" v-model="vueData.CTHoaDon.KhachTra_QT" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="Xanh SM" v-model="vueData.CTHoaDon.KhachTra_XSM" outlined dense hide-details /></v-col>
                        </v-row>
                        <v-row>
                            <v-col cols="2"><v-text-field type="number" label="HT1" v-model="vueData.CTHoaDon.KhachTra_HT1" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="HT2" v-model="vueData.CTHoaDon.KhachTra_HT2" outlined dense hide-details /></v-col>
                            <v-col cols="2"><v-text-field type="number" label="HT3" v-model="vueData.CTHoaDon.KhachTra_HT3" outlined dense hide-details /></v-col>
                        </v-row>
                    </div>
                    <div>
                        <v-btn color="primary" @click="onSaveOrder" elevation="0" style="width: 150px"><v-icon left>mdi-cash-check</v-icon>Lưu</v-btn>
                    </div>
                </div>
                <f-table :items-per-page="-1" hide-default-footer="true" class="mt-2" dense :excel="true" label="Danh sách món" :items="vueData.DSChiTietHoaDon" :height="200" :headers="tableHeader" :update-form="tableUpdateForm" :update-api="tableUpdateAPI" />
                <div v-if="vueData.CTHoaDon.GhiChu !== ''" class="text-left black--text mt-2"><b>Ghi chú hóa đơn:</b> {{ vueData.CTHoaDon.GhiChu }}</div>
                <div v-if="vueData.CTHoaDon?.GrabOrderState" class="text-left black--text mt-2"><b>Trạng thái GRAB:</b> {{ vueData.CTHoaDon.GrabOrderState_Name }}</div>
                <div class="text-right black--text my-3">
                    <span class="px-2">
                        Tạm tính: <b>{{ vueData.CTHoaDon.TongTien?.toLocaleString("vi-vn") }}</b>
                    </span>
                    <span>•</span>
                    <span class="px-2">
                        VAT: <b>{{ vueData.CTHoaDon.TongVAT?.toLocaleString("vi-vn") }}</b>
                    </span>
                    <span>•</span>
                    <span class="px-2">
                        ZEN: <b class="primary--text">{{ vueData.CTHoaDon.KhachTra_Zen?.toLocaleString("vi-vn") }}</b>
                    </span>
                    <span>•</span>
                    <span class="pl-2">
                        Thành tiền: <b class="red--text">{{ vueData.CTHoaDon.TienPhaiTra?.toLocaleString("vi-vn") }}</b>
                    </span>
                </div>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn text @click="onInsertInvoice" color="success" :disabled="vueData.CTHoaDon.TrangThai === 5">Lưu hóa đơn điện tử</v-btn>
                <v-btn text @click="onPrintOrder" color="success" :disabled="vueData.CTHoaDon.TrangThai !== 3 && vueData.CTHoaDon.TrangThai !== 4 && vueData.CTHoaDon.TrangThai !== 5">In lại hóa đơn</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["isDialog"],
    data() {
        return {
            tableHeader: [
                {
                    text: "Tên sản phẩm",
                    value: "TenNoiBo",
                    el: "span",
                    width: 350,
                    attr: {
                        ":class": "`${item.Is_SanPham === 1 ? 'font-weight-bold' : 'ml-5'}`",
                    },
                    innerHTML: "{{item.TenNoiBo}} <v-icon class='ml-1' small color='success' dense v-if='item.Is_SanPham === 1 && item.Is_MangVe === 1'>mdi-shopping</v-icon><v-icon class='ml-1' small color='success' dense v-if='item.Is_SanPham === 1 && item.Is_KhuyenMai === 1'>mdi-gift</v-icon>",
                },
                {
                    text: "Loại ly",
                    value: "TenLoaiLy"
                },
                {
                    text: "SL",
                    align: "right",
                    value: "SoLuong",
                },
                {
                    text: "Đơn giá",
                    align: "right",
                    el: "span",
                    value: "DonGia",
                    innerHTML: "{{item.DonGia.toLocaleString('vi-vn')}}",
                },
                {
                    text: "VAT",
                    align: "right",
                    el: "span",
                    value: "TienVAT",
                    innerHTML: "{{item.TienVAT.toLocaleString('vi-vn')}} ({{item.PhanTramVAT}}%)",
                },
                {
                    text: "ZEN",
                    align: "center",
                    value: "Is_ThanhToanZen",
                    el: "v-icon",
                    attr: {
                        color: "success",
                        ":dense": true,
                    },
                    innerHTML: "{{item.Is_ThanhToanZen == 0 ? '': 'mdi-check'}}",
                },
                {
                    text: "Thành tiền",
                    align: "right",
                    el: "span",
                    value: "ThanhTien",
                    innerHTML: "{{item.ThanhTien.toLocaleString('vi-vn')}}",
                },
                {
                    text: "Ghi chú",
                    align: "right",
                    value: "GhiChu",
                },
                {
                    text: "Trạng thái",
                    align: "center",
                    el: "span",
                    value: "TenTrangThai",
                    innerHTML: "{{item.Is_SanPham === 0 ? '' : item.TenTrangThai}}",
                },
                {
                    text: "",
                    value: "InTem",
                    el: "t-button",
                    attr: {
                        "v-if": "item.TenMayIn_Tem !== null",
                        color: "primary",
                        label: "In tem",
                        ":action": {
                            FUN: "onPrintTem",
                            IN: {
                                data: "{{item}}",
                            },
                        },
                    },
                },
                {
                    text: "",
                    value: "ctrl-update",
                    align: "center",
                },
            ],
            tableUpdateForm: [
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "SoLuong",
                        label: "Số lượng",
                        type: "number",
                    },
                    w: 4,
                },
                {
                    el: "v-select",
                    attr: {
                        "v-if": "Is_SanPham === 1",
                        "v-model": "TrangThai",
                        label: "Trạng thái món",
                        ":items": "vueData.DSTrangThai",
                    },
                    w: 8,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-if": "Is_SanPham === 1",
                        "v-model": "GhiChu",
                        label: "Ghi chú",
                    },
                    w: 12,
                },
            ],
            tableUpdateAPI: {
                edit: {
                    CONFIRM: "Bạn có muốn cập nhật thông tin món</b>?",
                    API: "/eorder/HoaDonChiTiet_Update",
                    IN: {
                        HoaDonChiTietID: "item.HoaDonChiTietID",
                        SoLuong: "item.SoLuong ?? 0",
                        TrangThai: "item.TrangThai",
                        GhiChu: "item.GhiChu",
                    },
                    MESS: "Cập nhật thông tin món thành công",
                    CALLBACK: [
                        {
                            EXE: "getOrder()",
                        },
                    ],
                },
            },
            vueData,
        }
    },
    mounted() {},
    computed: {},
    watch: {
        "vueData.IsShowDialogDetail": {
            handler(isShow) {
                if (!isShow) {
                    vueData.cancelCodeGRAB = null
                }
            },
        },
    },
    methods: {
        onInsertInvoice() {
            const hdid = vueData.CTHoaDon?.HoaDonID
            if (hdid > 0) {
                const params = {
                    HoaDonID: hdid,
                }
                ajaxCALL("/eorder/HoaDonDienTu_Insert", params, (res) => {
                    if (res.data) {
                        Vue.$toast.success("Lưu thông tin xuất hóa đơn điện tử thành công", {position: "top"})
                        vueData.IsShowDialogDetail = false
                    }
                })
            }
        },
        onReplaceOrder() {
            const hdid = vueData.CTHoaDon?.HoaDonID
            if (hdid > 0) {
                const optionCancel = vueData.OptionsCancelOrder.find((c) => c.value == vueData.cancelCodeGRAB)
                const cancelText = optionCancel?.text ?? null
                const params = {
                    HoaDonID: hdid,
                    GhiChu_Huy: cancelText ?? vueData.CTHoaDon?.GhiChu_Huy,
                    ThayThe_LyDo: vueData.CTHoaDon?.ThayThe_LyDo,
                }
                ajaxCALL("/eorder/HoaDon_ThayThe", params, (res) => {
                    if (res.data) {
                        const resData = res.data[0] ?? null
                        Vue.$toast.success("Thay thế hóa đơn thành công. Mã hóa đơn mới: " + resData?.MaHoaDon, {position: "top"})
                        vueData.IsShowDialogDetail = false
                        const urlPOS = `/pos?chid=${resData.CuaHangID}&hdid=${resData.HoaDonID}`
                        window.open(urlPOS, "_blank")
                    }
                })
            }
        },
    },
}
</script>

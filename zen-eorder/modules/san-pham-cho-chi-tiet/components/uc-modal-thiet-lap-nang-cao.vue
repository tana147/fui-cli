<template>
    <v-dialog v-model="vueData.IsShowDialogSettingProduct" scrollable width="1300">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Thiết lập nhiều cửa hàng</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogSettingProduct = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col md="3" style="border-right: 1px solid #d1d1d1">
                        <p class="mb-0 font-weight-bold">
                            Cửa hàng thiết lập <span class="success--text ml-1">({{ CuaHangID_Selected.length }} cửa hàng)</span>
                        </p>
                        <v-checkbox :key="0" class="mt-1" v-model="CuaHangID_Selected_All" label="Tất cả cửa hàng" color="success" hide-details></v-checkbox>
                        <v-checkbox v-for="item in sp_ch" :key="item.CuaHangID" class="mt-1" v-model="CuaHangID_Selected" :label="item.TenCuaHang" :value="item.CuaHangID" color="success" hide-details></v-checkbox>
                    </v-col>
                    <v-col md="9" class="pl-4">
                        <p class="mb-2 font-weight-bold">Cài đặt</p>
                        <v-row>
                            <v-col>
                                <v-text-field v-model="CTSanPham_Form.MaSoSanPham" dense label="Mã số sản phẩm" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <v-text-field v-model="CTSanPham_Form.SoLuongTon" dense label="Số lượng tồn" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <v-select v-model="CTSanPham_Form.CachBan" dense label="Cách bán" :items="DSCachBan" hide-details outlined></v-select>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.SoLuongThapPhan" label="Thập phân" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.MaintainQuanlityRatio" label="Ratio" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.Is_Signature" label="Signature" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.Is_BestSeller" label="Bán chạy" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col class="pt-0" md="12">
                                <v-btn elevation="0" color="success" v-on:click="onSave_CaiDat()"><v-icon left>mdi-content-save</v-icon>Lưu cài đặt</v-btn>
                            </v-col>
                        </v-row>
                        <p class="mt-5 mb-2 font-weight-bold">Trạng thái</p>
                        <v-row>
                            <v-col md="3">
                                <v-select v-model="CTSanPham_Form.TinhTrang" dense label="Trạng thái món" :items="DSTinhTrang" hide-details outlined></v-select>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.ChoPhepBan" label="Bán trực tiếp (POS, mPOS)" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col>
                                <v-checkbox class="mt-1" v-model="CTSanPham_Form.ChoPhepBan_App" label="Bán trên App (Khách Order)" color="success" hide-details></v-checkbox>
                            </v-col>
                            <v-col class="pt-0" md="12">
                                <v-btn elevation="0" color="success" v-on:click="onSave_TrangThai()"><v-icon left>mdi-content-save</v-icon>Lưu trạng thái</v-btn>
                            </v-col>
                        </v-row>
                        <p class="mt-5 mb-2 font-weight-bold">Thiết lập giá</p>
                        <v-row>
                            <v-col>
                                <v-text-field type="number" v-model="CTSanPham_Form.GiaBan_CuaHang" dense label="Giá bán (Tại cửa hàng)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <v-text-field type="number" v-model="CTSanPham_Form.VAT_CuaHang" dense label="% Thuế VAT (Tại cửa hàng)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <v-text-field type="number" v-model="CTSanPham_Form.GiaBan_App" dense label="Giá bán (Trên App)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <v-text-field type="number" v-model="CTSanPham_Form.VAT_App" dense label="% Thuế VAT (Trên App)" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col class="pt-0" md="12">
                                <v-btn elevation="0" color="success" v-on:click="onSave_Gia()"><v-icon left>mdi-content-save</v-icon>Lưu thiết lập giá</v-btn>
                            </v-col>
                        </v-row>
                        <p class="mt-5 mb-0 font-weight-bold">Lịch bán</p>
                        <v-row>
                            <v-col>
                                <p class="mb-0"><b>Thứ 2</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_2_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_2_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>Thứ 3</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_3_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_3_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>Thứ 4</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_4_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_4_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>Thứ 5</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_5_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_5_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>Thứ 6</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_6_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_6_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>Thứ 7</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.Thu_7_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.Thu_7_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col>
                                <p class="mb-0"><b>CN</b></p>
                                <v-text-field single-line v-model="CTSanPham_Form.CN_Tu" dense label="Từ" outlined hide-details></v-text-field>
                                <v-text-field class="mt-1" single-line v-model="CTSanPham_Form.CN_Den" dense label="Đến" outlined hide-details></v-text-field>
                            </v-col>
                            <v-col class="pt-0" md="12">
                                <v-btn elevation="0" color="success" v-on:click="onSave_LichBan()"><v-icon left>mdi-content-save</v-icon>Lưu lịch bán</v-btn>
                            </v-col>
                        </v-row>
                    </v-col>
                </v-row>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog", "ct_sanpham", "sp_ch"],
    data: function () {
        return {
            CuaHangID_Selected_All: false,
            CuaHangID_Selected: [],
            DSCachBan: [
                {
                    text: "Trực tiếp",
                    value: 0,
                },
                {
                    text: "Linh động",
                    value: 1,
                },
                {
                    text: "Kèm theo",
                    value: 2,
                },
            ],
            DSTinhTrang: [
                {
                    text: "Đang bán",
                    value: 0,
                },
                {
                    text: "Tạm hết",
                    value: 1,
                },
            ],
            CTSanPham_Form: {
                SoLuongTon: 0,
                MaSoSanPham: "00",
                GiaBan_CuaHang: 0,
                GiaBan_App: 0,
                VAT_CuaHang: 0,
                VAT_App: 0,
                CachBan: 0,
                ChoPhepBan: true,
                ChoPhepBan_App: true,
                QuanLyLot: true,
                SoLuongThapPhan: true,
                QuanLyTon: true,
                QuanLySerial: true,
                MaintainQuanlityRatio: true,
                Is_Signature: false,
                Is_BestSeller: false,
                Thu_2_Tu: null,
                Thu_3_Tu: null,
                Thu_4_Tu: null,
                Thu_5_Tu: null,
                Thu_6_Tu: null,
                Thu_7_Tu: null,
                CN_Tu: null,
                Thu_2_Den: null,
                Thu_3_Den: null,
                Thu_4_Den: null,
                Thu_5_Den: null,
                Thu_6_Den: null,
                Thu_7_Den: null,
                CN_Den: null,
            },
        }
    },
    watch: {
        CuaHangID_Selected_All: function (data) {
            const $this = this
            if (data) {
                $this.CuaHangID_Selected = $this.sp_ch.map((item) => item.CuaHangID)
            } else {
                $this.CuaHangID_Selected = []
            }
        },
    },
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham ?? {}
        },
    },
    methods: {
        onSave_CaiDat: function () {
            const $this = this
            const formData = $this.CTSanPham_Form
            const params = {
                SanPhamID: $this.CTSanPham.SanPhamID,
                DS_CuaHangID: $this.CuaHangID_Selected.join(","),
                MaSoSanPham: formData.MaSoSanPham,
                SoLuongTon: formData.SoLuongTon,
                CachBan: formData.CachBan,
                QuanLyLot: formData.QuanLyLot,
                QuanLyTon: formData.QuanLyTon,
                SoLuongThapPhan: formData.SoLuongThapPhan,
                MaintainQuanlityRatio: formData.MaintainQuanlityRatio,
                Is_Signature: formData.Is_Signature,
                Is_BestSeller: formData.Is_BestSeller,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_CaiDat_Multiple", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập cài đặt thành công"})
                runAction(vueData.getSanPhamCuaHang)
            })
        },
        onSave_TrangThai: function () {
            const $this = this
            const formData = $this.CTSanPham_Form
            const params = {
                SanPhamID: $this.CTSanPham.SanPhamID,
                DS_CuaHangID: $this.CuaHangID_Selected.join(","),
                TinhTrang: formData.TinhTrang,
                ChoPhepBan: formData.ChoPhepBan,
                ChoPhepBan_App: formData.ChoPhepBan_App,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_TrangThai_Multiple", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập trạng thái thành công"})
                runAction(vueData.getSanPhamCuaHang)
            })
        },
        onSave_Gia: function () {
            const $this = this
            const formData = $this.CTSanPham_Form
            const params = {
                SanPhamID: $this.CTSanPham.SanPhamID,
                DS_CuaHangID: $this.CuaHangID_Selected.join(","),
                GiaBan_CuaHang: formData.GiaBan_CuaHang,
                GiaBan_App: formData.GiaBan_App,
                VAT_CuaHang: formData.VAT_CuaHang,
                VAT_App: formData.VAT_App,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_Gia_Multiple", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập giá thành công"})
                runAction(vueData.getSanPhamCuaHang)
            })
        },
        onSave_LichBan: function () {
            const $this = this
            const formData = $this.CTSanPham_Form
            const params = {
                SanPhamID: $this.CTSanPham.SanPhamID,
                DS_CuaHangID: $this.CuaHangID_Selected.join(","),
                Thu_2_Tu: formData.Thu_2_Tu,
                Thu_3_Tu: formData.Thu_3_Tu,
                Thu_4_Tu: formData.Thu_4_Tu,
                Thu_5_Tu: formData.Thu_5_Tu,
                Thu_6_Tu: formData.Thu_6_Tu,
                Thu_7_Tu: formData.Thu_7_Tu,
                CN_Tu: formData.CN_Tu,
                Thu_2_Den: formData.Thu_2_Den,
                Thu_3_Den: formData.Thu_3_Den,
                Thu_4_Den: formData.Thu_4_Den,
                Thu_5_Den: formData.Thu_5_Den,
                Thu_6_Den: formData.Thu_6_Den,
                Thu_7_Den: formData.Thu_7_Den,
                CN_Den: formData.CN_Den,
            }
            ajaxCALL("/eorder/SanPhamCho_Update_LichBan_Multiple", params, (res) => {
                showToast({type: "green", title: "Lưu thiết lập lịch bán thành công"})
                runAction(vueData.getSanPhamCuaHang)
            })
        },
    },
}
</script>

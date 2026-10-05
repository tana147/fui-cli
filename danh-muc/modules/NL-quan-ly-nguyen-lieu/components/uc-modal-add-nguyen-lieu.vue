<template>
    <v-dialog v-model="vueData.isShowModalAddNguyenLieu" max-width="1000">
        <v-card>
            <template v-slot:title>Thêm mới nguyên liệu</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </template>

            <v-card-text>
                    <v-row>
                        <v-col cols="12" class="pb-0">
                            <div class="font-weight-bold">Phân loại theo nhóm</div>
                        </v-col>

                        <v-col cols="3">
                            <v-select v-model="formData.LoaiNguyenLieu" label="* Loại nguyên liệu" :items="LoaiThanhPhanList" item-title="text" item-value="value" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-autocomplete
                                :clearable="false"
                                density="compact"
                                hide-details="auto"
                                label="* Nhóm tính chất"
                                :items="DSNhomTinhChat"
                                v-model="formData.NhomTinhChat_Id"
                                item-title="TenTinhChat"
                                item-value="PhanLoai_TinhChat_Id"
                            />
                        </v-col>
                        <v-col cols="3">
                            <v-autocomplete
                                :clearable="false"
                                density="compact"
                                hide-details="auto"
                                label="* Nhóm vật tư"
                                :items="DSNhomVTHHFilter"
                                v-model="formData.NhomVatTu_Id"
                                item-title="TenNhomVatTu"
                                :disabled="!formData.NhomTinhChat_Id"
                                item-value="PhanLoai_NhomVatTu_Id"
                            />
                        </v-col>
                        <v-col cols="3">
                            <v-autocomplete
                                label="* Nhóm sản phẩm"
                                :items="DSNhomTenSanPhamFilter"
                                v-model="formData.PhanLoai_NhomSanPham_Id"
                                item-title="TenNhomSanPham"
                                item-value="PhanLoai_NhomSanPham_Id"
                                density="compact"
                                hide-details="auto"
                            />
                        </v-col>

                        <v-col cols="12" class="pb-0">
                            <div class="font-weight-bold">Thông tin nguyên liệu</div>
                        </v-col>

                        <v-col cols="4">
                            <v-text-field v-model="formData.MaNoiBo" label="* Mã nội bộ" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="8">
                            <v-text-field v-model="formData.TenHangHoa" label="* Tên nguyên liệu" density="compact" hide-details="auto" />
                        </v-col>

                        <v-col cols="3">
                            <v-text-field
                                v-model="formData.DonGia_ApDung"
                                class="text-right-input"
                                label="Đơn giá nhập"
                                inputmode="numberic"
                                type="text"
                                density="compact"
                                hide-details="auto"
                                @update:model-value="formatPrice($event, 'DonGia_ApDung')"
                                @keydown="onPrevent"
                            />
                        </v-col>
                        <v-col cols="3">
                            <uc-select-don-vi v-model:value="formData.Chuan_DonViTinh_Id" label="* Đơn vị nhập" placeholder="Đơn vị nhập" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field
                                class="text-right-input"
                                v-model="formData.GiaBan"
                                label="Đơn giá bán"
                                type="text"
                                inputmode="numberic"
                                density="compact"
                                hide-details="auto"
                                @update:model-value="formatPrice($event, 'GiaBan')"
                                @keydown="onPrevent"
                            />
                        </v-col>
                        <v-col cols="3">
                            <uc-select-don-vi v-model:value="formData.Ban_DonViTinh_Id" label="Đơn vị bán" placeholder="Đơn vị bán" />
                        </v-col>

                        <v-col cols="12" class="pb-0">
                            <div class="font-weight-bold">Thông tin bổ sung</div>
                        </v-col>

                        <v-col cols="3">
                            <v-text-field v-model="formData.DoUuTien" inputmode="numberic" density="compact" hide-details="auto" @keydown="onPrevent" label="Độ ưu tiên" />
                        </v-col>
                        <v-col cols="3">
                            <v-select v-model="formData.TrangThai" label="Trạng thái" :items="DsTrangThai" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.HanSuDung_Gio" label="Hạn sử dụng (giờ)" type="number" min="0" step="0.01" inputmode="decimal" density="compact" hide-details="auto" @keydown="preventNegative" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.NguonGoc" label="Nguồn gốc" density="compact" hide-details="auto" />
                        </v-col>

                        <v-col cols="3">
                            <v-text-field v-model="formData.MauSac" label="Màu sắc" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.HinhThai" label="Hình thái" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.ThuongHieu" label="Thương hiệu" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field
                                v-model="formData.BaoQuan_NhietDo"
                                label="Nhiệt độ bảo quản"
                                type="number"
                                step="0.01"
                                inputmode="decimal"
                                density="compact"
                                hide-details="auto"
                                @update:model-value="checkMinValue($event, 'BaoQuan_NhietDo')"
                            />
                        </v-col>

                        <v-col cols="3">
                            <v-text-field v-model="formData.DacTinh" label="Đặc tính" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.BaoQuan_ThietBi" label="Thiết bị bảo quản" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="3">
                            <v-text-field v-model="formData.BaoQuan_NoiBaoQuan" label="Nơi bảo quản" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="12">
                            <v-textarea v-model="formData.MoTa" label="Mô tả" auto-grow :rows="3" no-resize density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox v-model="formData.Is_TamKhoa" label="Tạm khóa" color="primary" density="compact" hide-details="auto" />
                        </v-col>
                    </v-row>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn @click="onSaveAndClose" prepend-icon="mdi-content-save-outline" variant="tonal">Lưu & Đóng</v-btn>
                <v-btn color="primary" @click="onSaveAndContinue" prepend-icon="mdi-content-save-move" variant="flat">Lưu & Tiếp tục</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['onLoadNhomTinhChat', 'onLoadNhomVatTu', 'onLoadNhomTenSanPham', 'LoaiThanhPhanList', 'onLoadNguyenLieu', 'DsTrangThai'],
    emits: ['onReload', 'onContinue', 'loadnhomnguyenlieu'],
    data() {
        return {
            vueData,
            isAddAndClose: false,
            isContinueAfterSave: false,
            formData: {
                EORDER_SanPham_Id: null,
                NhomTinhChat_Id: null,
                NhomVatTu_Id: null,
                PhanLoai_NhomSanPham_Id: null,
                Chuan_DonViTinh_Id: null,
                Ban_DonViTinh_Id: null,
                LoaiNguyenLieu: null,
                MaNoiBo: null,
                TenHangHoa: null,
                ThuongHieu: null,
                NguonGoc: null,
                MauSac: null,
                HinhThai: null,
                DacTinh: null,
                MoTa: null,
                BaoQuan_NhietDo: null,
                BaoQuan_ThietBi: null,
                HanSuDung_Gio: null,
                DoUuTien: null,
                TrangThai: 'DANG_SU_DUNG',
                BaoQuan_NoiBaoQuan: null,
                DonGia_ApDung: 0,
                GiaBan: '0',
                Is_TamKhoa: false,
            },

            DSNhomTinhChat: [],
            DsNhomVatTu: [],
            DSNhomVTHHFilter: [],
            DSNhomTenSanPham: [],
            DSNhomTenSanPhamFilter: [],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        async 'vueData.isShowModalAddNguyenLieu'(val) {
            if (val) {
                this.DSNhomTinhChat = await this.onLoadNhomTinhChat()
                const DsTenSanPham = await this.onLoadNhomTenSanPham(this.formData.NhomTinhChat_Id, val)
                this.DSNhomTenSanPhamFilter = [
                    {
                        PhanLoai_NhomSanPham_Id: 0,
                        TenNhomSanPham: '- Chưa xác định -',
                    },
                    ...DsTenSanPham,
                ]
            }
        },

        async 'formData.NhomTinhChat_Id'(val) {
            this.formData.NhomVatTu_Id = null
            if (val !== null) {
                const DsVatTu = await this.onLoadNhomVatTu(val)
                this.DSNhomVTHHFilter = DsVatTu
            }
        },

        // async 'formData.NhomVatTu_Id'(val) {
        //     if (val !== null) {
        //         const DsTenSanPham = await this.onLoadNhomTenSanPham(this.formData.NhomTinhChat_Id, val)
        //         this.DSNhomTenSanPhamFilter = [
        //             {
        //                 PhanLoai_NhomSanPham_Id: 0,
        //                 TenNhomSanPham: '- Chưa xác định -',
        //             },
        //             ...DsTenSanPham,
        //         ]
        //     } else {
        //         this.formData.PhanLoai_NhomSanPham_Id = null
        //     }
        // },
    },
    methods: {
        async onAdd() {
            if (
                !this.formData.NhomTinhChat_Id ||
                !this.formData.NhomVatTu_Id ||
                !this.formData.Chuan_DonViTinh_Id ||
                !this.formData.LoaiNguyenLieu ||
                !this.formData.MaNoiBo ||
                !this.formData.TenHangHoa
                // (this.formData.BaoQuan_NhietDo === null || this.formData.BaoQuan_NhietDo === '') ||
                // (this.formData.HanSuDung_Gio === null || this.formData.HanSuDung_Gio === '') ||
                // this.formData.DonGia_ApDung === null ||
                // this.formData.DonGia_ApDung === ''
            ) {
                showToast.error('Vui lòng điền đầy đủ các trường bắt buộc (*)', {
                    position: 'top',
                })
                return
            }

            this.formData.TenHangHoa = this.formData.TenHangHoa?.trim() || this.formData.TenHangHoa
            this.formData.MaNoiBo = this.formData.MaNoiBo?.trim() || this.formData.MaNoiBo

            apiCall(
                'work/MT_NguyenLieu_Insert',
                {
                    EORDER_SanPham_Id: 0,
                    PhanLoai_TinhChat_Id: this.formData.NhomTinhChat_Id,
                    PhanLoai_NhomVatTu_Id: this.formData.NhomVatTu_Id,
                    PhanLoai_NhomSanPham_Id: this.formData.PhanLoai_NhomSanPham_Id,
                    Chuan_DonViTinh_Id: this.formData.Chuan_DonViTinh_Id,
                    Ban_DonViTinh_Id: this.formData.Ban_DonViTinh_Id ? this.formData.Ban_DonViTinh_Id : '',
                    LoaiNguyenLieu: this.formData.LoaiNguyenLieu,
                    MaNoiBo: this.formData.MaNoiBo,
                    TenHangHoa: this.formData.TenHangHoa,
                    ThuongHieu: this.formData.ThuongHieu,
                    NguonGoc: this.formData.NguonGoc,
                    MauSac: this.formData.MauSac,
                    HinhThai: this.formData.HinhThai,
                    DacTinh: this.formData.DacTinh,
                    TrangThai: this.formData.TrangThai,
                    MoTa: this.formData.MoTa,
                    BaoQuan_NoiBaoQuan: this.formData.BaoQuan_NoiBaoQuan,
                    BaoQuan_NhietDo: this.formData.BaoQuan_NhietDo,
                    BaoQuan_ThietBi: this.formData.BaoQuan_ThietBi,
                    HanSuDung_Gio: this.formData.HanSuDung_Gio ? this.formData.HanSuDung_Gio : null,
                    DoUuTien: this.formData.DoUuTien ? this.formData.DoUuTien : '',
                    DonGia_ApDung: this.formData.DonGia_ApDung ? this.formData.DonGia_ApDung?.replace(/\./g, '')?.replace(/\,/g, '.') : 0,
                    GiaBan: this.formData.GiaBan ? this.formData.GiaBan?.replace(/\./g, '')?.replace(/\,/g, '.') : 0,
                    Is_TamKhoa: this.formData.Is_TamKhoa ? 1 : 0,
                },
                async () => {
                    this.$emit('onReload')

                    if (this.isAddAndClose) {
                        showToast.success('Thêm nguyên liệu thành công')
                        this.onClose()
                        return
                    }

                    if (this.isContinueAfterSave) {
                        showToast.success('Lưu thành công')
                        this.$emit('onContinue', {
                            MaNoiBo: this.formData.MaNoiBo,
                            TenHangHoa: this.formData.TenHangHoa,
                        })
                        this.onClose()
                    }
                },
            )
        },

        onPrevent(e) {
            this.preventNegative(e)
            this.onlyNumber(e)
        },

        preventNegative(e) {
            // Chặn các ký tự '-', 'e', '+' và số âm
            if (e.key === '-' || e.key === 'e' || e.key === '+') {
                e.preventDefault()
            }
        },

        onlyNumber(e) {
            // Cho phép Ctrl + A / C / V / X
            if (e.ctrlKey) {
                const allowCtrlKeys = ['a', 'c', 'v', 'x']
                if (allowCtrlKeys.includes(e.key.toLowerCase())) {
                    return
                }
            }

            const allowKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab']

            // Cho phép các phím điều hướng / xoá
            if (allowKeys.includes(e.key)) return

            const value = e.target.value

            // Cho nhập số 0–9
            if (/^\d$/.test(e.key)) return

            // Cho nhập dấu phẩy (chỉ 1 lần)
            if (e.key === ',') {
                if (value.includes(',')) {
                    e.preventDefault()
                }
                return
            }

            // Còn lại: chặn
            e.preventDefault()
        },

        checkMinValue(val, name) {
            const num = Number(val)

            // Nhỏ hơn -273 thì ép về -273
            if (!isNaN(num) && num < -273) {
                this.formData[name] = -273
            }
        },

        formatPrice(val, name) {
            if (val === null || val === '') {
                this.formData[name] = val
                return
            }

            // bỏ dấu . cũ
            const raw = String(val).replace(/\./g, '')

            const number = Number(raw)
            if (isNaN(number)) return

            this.formData[name] = number.toLocaleString('vi-VN')
        },

        onSaveAndClose() {
            this.isAddAndClose = true
            this.isContinueAfterSave = false
            this.onAdd()
        },
        onSaveAndContinue() {
            this.isAddAndClose = false
            this.isContinueAfterSave = true
            this.onAdd()
        },
        resetForm() {
            this.formData = {
                EORDER_SanPham_Id: null,
                NhomTinhChat_Id: null,
                NhomVatTu_Id: null,
                PhanLoai_NhomSanPham_Id: null,
                Chuan_DonViTinh_Id: null,
                LoaiNguyenLieu: null,
                MaNoiBo: null,
                TenHangHoa: null,
                ThuongHieu: null,
                NguonGoc: null,
                MauSac: null,
                HinhThai: null,
                DacTinh: null,
                MoTa: null,
                BaoQuan_NhietDo: null,
                BaoQuan_ThietBi: null,
                HanSuDung_Gio: null,
                DonGia_ApDung: null,
                GiaBan: null,
                Is_TamKhoa: false,
            }
        },
        onClose() {
            this.isAddAndClose = false
            this.isContinueAfterSave = false
            this.resetForm()
            vueData.isShowModalAddNguyenLieu = false
        },
    },
}
</script>

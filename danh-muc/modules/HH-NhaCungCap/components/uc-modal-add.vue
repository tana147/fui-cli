<template>
    <v-dialog v-model="isShow" width="900" scrollable>
        <v-card>
            <template v-slot:title>Thêm mới nhà cung cấp</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog"></v-btn>
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12 pb-0">
                        <div class="font-weight-bold">Thông tin chung</div>
                    </v-col>
                    <v-col cols="6">
                        <v-text-field v-model="formData.TenNhaCungCap" label="* Tên nhà cung cấp" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.MaNhaCungCap" label="* Mã nhà cung cấp" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.MaSoThue" label="Mã số thuế" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.XaPhuong" label="Xã phường" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.QuanHuyen" label="Quận huyện" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.TinhThanhPho" label="Tỉnh thành phố" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field v-model="formData.QuocGia" label="Quốc gia" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="2">
                        <v-text-field v-model="formData.DoUuTien" label="Độ ưu tiên" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="5">
                        <v-text-field v-model="formData.DienThoai" label="Điện thoại" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="5">
                        <v-text-field v-model="formData.Website" label="Website" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.DiaChi" label="Địa chỉ" hide-details="auto" auto-grow :rows="2" no-resize density="compact" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.DanhGia" label="Đánh giá" hide-details="auto" auto-grow :rows="2" no-resize density="compact" />
                    </v-col>

                    <v-col cols="12 pb-0">
                        <div class="font-weight-bold">Thông tin hợp đồng</div>
                    </v-col>
                    <v-col cols="4">
                        <v-select v-model="formData.TrangThai" :items="dsTrangThai" label="Trạng thái" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field v-model="formData.GiaoHang" label="Thông tin giao hàng" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="4">
                        <uc-date-picker v-model="formData.ThoiGianHopDong" icon-color="primary" :rules="[]" :min="new Date().toISOString().substr(0, 10)" label="Ngày hết hạn hợp đồng" />
                    </v-col>
                    <v-col cols="12">
                        <uc-input-file-multi v-model="formData.FileHopDong_Id" label="File hợp đồng" :multiple="true" :show-size="true" />
                    </v-col>

                    <v-col cols="12 pb-0">
                        <div class="font-weight-bold">Thông tin người quản lý</div>
                    </v-col>
                    <v-col cols="6">
                        <v-text-field v-model="formData.NguoiChiuTrachNhiem_BenBan" label="Người chịu trách nhiệm bên bán" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field v-model="formData.NguoiChiuTrachNhiem_BenMua" label="Người chịu trách nhiệm bên mua" hide-details="auto" density="compact" />
                    </v-col>

                    <v-col cols="4">
                        <v-text-field v-model="formData.CCCD_So" label="Số CCCD" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="4">
                        <uc-date-picker v-model="formData.CCCD_NgayCap" icon-color="primary" :rules="[]" label="Ngày cấp" />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field v-model="formData.CCCD_NoiCap" label="Nơi cấp" hide-details="auto" density="compact" />
                    </v-col>

                    <v-col cols="12 pb-0">
                        <div class="font-weight-bold">Thông tin công nợ</div>
                    </v-col>
                    <v-col cols="4">
                        <v-text-field v-model="formData.CongNo" label="Công nợ" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field v-model="formData.NganHang_Ten" label="Tên ngân hàng" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field v-model="formData.NganHang_ChiNhanh" label="Chi nhánh ngân hàng" hide-details="auto" density="compact" />
                    </v-col>
                    <v-col cols="12">
                        <v-text-field v-model="formData.NganHang_SoTaiKhoan" label="Số tài khoản ngân hàng" hide-details="auto" density="compact" />
                    </v-col>

                    <v-col cols="12 pb-0">
                        <div class="font-weight-bold">Phân loại nhóm ({{ selectedIds.length }})</div>
                    </v-col>
                    <v-col cols="12 pa-0">
                        <v-list density="compact" class="d-flex flex-row">
                            <v-list-item v-for="item in dsPhanLoaiSuplier" :key="item.PhanLoai_NhaCungCap_Id">
                                <v-list-item-title>
                                    <v-checkbox v-model="selectedIds" color="primary" :value="item.PhanLoai_NhaCungCap_Id" hide-details="auto" :label="item.TenNhomPhanLoai" />
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn class="ms-3" :loading="loading" color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="submit">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        loadData: Function,
        dsTrangThai: Array,
        dsPhanLoaiSuplier: Array,
    },
    data() {
        return {
            selectedIds: [],
            loading: false,
            formData: {
                MaNhaCungCap: null,
                TenNhaCungCap: null,
                TrangThai: 'DANG_SU_DUNG',
                MaSoThue: null,
                DanhGia: null,
                NguoiChiuTrachNhiem_BenBan: null,
                NguoiChiuTrachNhiem_BenMua: null,
                DoUuTien: '',
                FileHopDong_Id: [],
                ThoiGianHopDong: null,
                GiaoHang: null,
                CongNo: '',
                DiaChi: null,
                XaPhuong: null,
                QuanHuyen: null,
                TinhThanhPho: null,
                QuocGia: null,
                DienThoai: null,
                Website: null,
                CCCD_So: null,
                CCCD_NgayCap: null,
                CCCD_NoiCap: null,
                NganHang_SoTaiKhoan: null,
                NganHang_Ten: null,
                NganHang_ChiNhanh: null,
            },
        }
    },
    methods: {
        getDefaultFormData() {
            return {
                MaNhaCungCap: null,
                TenNhaCungCap: null,
                TrangThai: 'DANG_SU_DUNG',
                MaSoThue: null,
                DanhGia: null,
                NguoiChiuTrachNhiem_BenBan: null,
                NguoiChiuTrachNhiem_BenMua: null,
                DoUuTien: '',
                FileHopDong_Id: [],
                ThoiGianHopDong: null,
                GiaoHang: null,
                CongNo: '',
                DiaChi: null,
                XaPhuong: null,
                QuanHuyen: null,
                TinhThanhPho: null,
                QuocGia: null,
                DienThoai: null,
                Website: null,
                CCCD_So: null,
                CCCD_NgayCap: null,
                CCCD_NoiCap: null,
                NganHang_SoTaiKhoan: null,
                NganHang_Ten: null,
                NganHang_ChiNhanh: null,
            }
        },
        closeDialog() {
            this.formData = this.getDefaultFormData()
            this.selectedIds = []
            this.loading = false
            this.$emit('update:isShow', false)
        },
        async loadSuplierDetail() {
            const data = await apiCallPromise('work/HH_NhaCungCap_Select', null)
            return data.find((item) => item.MaNhaCungCap === this.formData.MaNhaCungCap)
        },
        updateSuplierCategories(suplierId) {
            return new Promise((resolve) => {
                apiCall(
                    'work/HH_NhaCungCap_NhomPhanLoai_Update',
                    {
                        NhaCungCap_Id: suplierId,
                        PhanLoai_NhaCungCap_Id_Lists: this.selectedIds.length > 0 ? this.selectedIds.join(',') : '',
                    },
                    () => {
                        resolve(true)
                    },
                )
            })
        },
        async submit() {
            this.loading = true
            if (!this.formData.TenNhaCungCap) {
                showToast.error('Vui lòng nhập tên nhà cung cấp')
                this.loading = false
                return
            }
            if (!this.formData.MaNhaCungCap) {
                showToast.error('Vui lòng nhập mã nhà cung cấp')
                this.loading = false
                return
            }

            let fileIds = null
            if (this.formData.FileHopDong_Id.length > 0) {
                const response = await apiFile.insertAndUpdate(
                    {
                        file: this.formData.FileHopDong_Id,
                        List_FileID: '',
                    },
                    {
                        maxFileSize: 2,
                        showToast: true,
                        validateFileSize: true,
                    },
                )
                if (!response.isSuccess) {
                    showToast.error('Lỗi khi tải lên file')
                    this.loading = false
                    return
                }
                fileIds = response.data.map((item) => item.FileID).join(',')
            }

            const params = {
                TenNhaCungCap: this.formData.TenNhaCungCap,
                MaNhaCungCap: this.formData.MaNhaCungCap,
                TrangThai: this.formData.TrangThai,
                MaSoThue: this.formData.MaSoThue,
                DanhGia: this.formData.DanhGia,
                NguoiChiuTrachNhiem_BenBan: this.formData.NguoiChiuTrachNhiem_BenBan,
                NguoiChiuTrachNhiem_BenMua: this.formData.NguoiChiuTrachNhiem_BenMua,
                CongNo: this.formData.CongNo,
                DoUuTien: this.formData.DoUuTien,
                FileHopDong_Id: fileIds,
                ThoiGianHopDong: this.formData.ThoiGianHopDong,
                GiaoHang: this.formData.GiaoHang,
                DiaChi: this.formData.DiaChi,
                XaPhuong: this.formData.XaPhuong,
                QuanHuyen: this.formData.QuanHuyen,
                TinhThanhPho: this.formData.TinhThanhPho,
                QuocGia: this.formData.QuocGia,
                DienThoai: this.formData.DienThoai,
                Website: this.formData.Website,
                CCCD_So: this.formData.CCCD_So,
                CCCD_NgayCap: this.formData.CCCD_NgayCap,
                CCCD_NoiCap: this.formData.CCCD_NoiCap,
                NganHang_SoTaiKhoan: this.formData.NganHang_SoTaiKhoan,
                NganHang_Ten: this.formData.NganHang_Ten,
                NganHang_ChiNhanh: this.formData.NganHang_ChiNhanh,
            }

            apiCall(
                'work/HH_NhaCungCap_Insert',
                params,
                async () => {
                    const createdSuplier = await this.loadSuplierDetail()
                    await this.updateSuplierCategories(createdSuplier?.NhaCungCap_Id)
                    this.loadData()
                    this.closeDialog()
                    showToast.success('Tạo mới nhà cung cấp thành công')
                },
                (error) => {
                    showToast.error(error.responseJSON.Message)
                    this.loading = false
                },
            )
        },
    },
}
</script>

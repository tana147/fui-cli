<template>
    <v-dialog v-model="isShow" width="1300" scrollable>
        <v-card>
            <template v-slot:title>Cập nhật nhà cung cấp</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog"></v-btn>
            </template>
            <v-card-text class="pa-0" style="padding-top: 0 !important">
                <v-sheet class="d-flex supplier-tabs-sheet" elevation="0">
                    <v-tabs v-model="activeTab" color="primary" direction="vertical" class="supplier-tabs-nav">
                        <v-tab value="info" prepend-icon="mdi-card-account-details-outline">Thông tin</v-tab>
                        <v-tab value="category" prepend-icon="mdi-tag-multiple-outline">Phân loại</v-tab>
                        <v-tab value="product" prepend-icon="mdi-package-variant-closed">Hàng hoá</v-tab>
                        <v-tab value="debt" prepend-icon="mdi-cash-multiple">Công nợ</v-tab>
                        <v-tab value="history" prepend-icon="mdi-history">Lịch sử cập nhật</v-tab>
                    </v-tabs>
                    <v-divider vertical></v-divider>
                    <v-tabs-window v-model="activeTab" class="flex-fill supplier-tabs-window">
                        <v-tabs-window-item value="info">
                            <v-row class="pa-4">
                                <v-col cols="12" class="pb-0">
                                    <div class="font-weight-bold">Thông tin chung</div>
                                </v-col>
                                <v-col cols="6">
                                    <v-text-field v-model="selectedItem.TenNhaCungCap" label="* Tên nhà cung cấp" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.MaNhaCungCap" label="* Mã nhà cung cấp" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.MaSoThue" label="Mã số thuế" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.XaPhuong" label="Xã phường" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.QuanHuyen" label="Quận huyện" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.TinhThanhPho" label="Tỉnh thành phố" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field v-model="selectedItem.QuocGia" label="Quốc gia" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="2">
                                    <v-text-field v-model="selectedItem.DoUuTien" label="Độ ưu tiên" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="5">
                                    <v-text-field v-model="selectedItem.DienThoai" label="Điện thoại" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="5">
                                    <v-text-field v-model="selectedItem.Website" label="Website" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="12">
                                    <v-textarea v-model="selectedItem.DiaChi" label="Địa chỉ" hide-details="auto" auto-grow :rows="2" no-resize density="compact" />
                                </v-col>
                                <v-col cols="12">
                                    <v-textarea v-model="selectedItem.DanhGia" label="Đánh giá" hide-details="auto" auto-grow :rows="2" no-resize density="compact" />
                                </v-col>

                                <v-col cols="12" class="pb-0">
                                    <div class="font-weight-bold">Thông tin hợp đồng</div>
                                </v-col>
                                <v-col cols="4">
                                    <v-select v-model="selectedItem.TrangThai" :items="dsTrangThai" label="Trạng thái" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.GiaoHang" label="Thông tin giao hàng" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="4">
                                    <uc-date-picker
                                        v-model="selectedItem.ThoiGianHopDong"
                                        icon-color="primary"
                                        :rules="[]"
                                        :min="new Date().toISOString().substr(0, 10)"
                                        label="Ngày hết hạn hợp đồng"
                                    />
                                </v-col>
                                <v-col v-if="selectedItem.dsFilesParse?.length > 0" cols="12">
                                    <uc-file-chip :items="selectedItem.dsFilesParse" :closable="true" @close="markFileDeleted" />
                                </v-col>
                                <v-col cols="12">
                                    <uc-input-file-multi v-model="newFiles" label="File hợp đồng" :multiple="true" :show-size="true" />
                                </v-col>

                                <v-col cols="12" class="pb-0">
                                    <div class="font-weight-bold">Thông tin người quản lý</div>
                                </v-col>
                                <v-col cols="6">
                                    <v-text-field v-model="selectedItem.NguoiChiuTrachNhiem_BenBan" label="Người chịu trách nhiệm bên bán" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="6">
                                    <v-text-field v-model="selectedItem.NguoiChiuTrachNhiem_BenMua" label="Người chịu trách nhiệm bên mua" hide-details="auto" density="compact" />
                                </v-col>

                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.CCCD_So" label="Số CCCD" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="4">
                                    <uc-date-picker v-model="selectedItem.CCCD_NgayCap" icon-color="primary" :rules="[]" label="Ngày cấp" />
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.CCCD_NoiCap" label="Nơi cấp" hide-details="auto" density="compact" />
                                </v-col>

                                <v-col cols="12" class="pb-0">
                                    <div class="font-weight-bold">Thông tin công nợ</div>
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.CongNo" label="Công nợ" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.NganHang_Ten" label="Tên ngân hàng" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field v-model="selectedItem.NganHang_ChiNhanh" label="Chi nhánh ngân hàng" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="12">
                                    <v-text-field v-model="selectedItem.NganHang_SoTaiKhoan" label="Số tài khoản ngân hàng" hide-details="auto" density="compact" />
                                </v-col>
                                <v-col cols="12">
                                    <v-checkbox v-model="selectedItem.Is_TamKhoa" label="Tạm khóa" density="compact" hide-details="auto" />
                                </v-col>
                            </v-row>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="category">
                            <div class="pa-4">
                                <div class="font-weight-bold">Phân loại nhóm ({{ selectedCategoryIds.length }})</div>
                                <v-list density="compact" class="d-flex flex-row">
                                    <v-list-item v-for="item in dsPhanLoaiSuplier" :key="item.PhanLoai_NhaCungCap_Id">
                                        <v-list-item-title>
                                            <v-checkbox v-model="selectedCategoryIds" :value="item.PhanLoai_NhaCungCap_Id" :label="item.TenNhomPhanLoai" color="primary" hide-details="auto" />
                                        </v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </div>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="product">
                            <div class="pa-4">
                                <div class="d-flex align-center mb-3">
                                    <div class="font-weight-bold">
                                        Danh sách hàng hoá
                                        <span>({{ suplierProductRows?.length || 0 }})</span>
                                    </div>
                                    <v-spacer></v-spacer>
                                    <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openAddProductDialog">Thêm hàng hoá</v-btn>
                                </div>
                                <z-table :key="productTableKey" ref="refProductTable" :headers="productTableHeaders" :items="suplierProductRows" height="480px" :options="productTableOptions" />
                            </div>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="history">
                            <div class="pa-4">
                                <div class="d-flex align-center mb-3">
                                    <div class="font-weight-bold">
                                        Danh sách hàng hoá
                                        <span>({{ DsHistory?.length || 0 }})</span>
                                    </div>
                                    <v-spacer></v-spacer>
                                </div>

                                <!-- <z-table :key="productTableKey" ref="refProductTable" :headers="productTableHeaders" :items="suplierProductRows" height="480px" :options="productTableOptions" /> -->
                                <z-table :key="historyTableKey" ref="refHistoryTable" :headers="historyTableHeaders" :items="DsHistory" height="480px" :options="historyTableOptions" />
                            </div>
                        </v-tabs-window-item>

                        <v-tabs-window-item value="debt">
                            <div class="pa-4">
                                <div class="d-flex align-center mb-3">
                                    <div class="font-weight-bold">
                                        Danh sách công nợ
                                        <span>({{ debtRows?.length || 0 }})</span>
                                    </div>
                                    <v-spacer></v-spacer>
                                    <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openAddDebtDialog">Thêm công nợ</v-btn>
                                </div>
                                <z-table :key="debtTableKey" ref="refDebtTable" :headers="debtTableHeaders" :items="debtRows" height="480px" :options="debtTableOptions" />
                            </div>
                        </v-tabs-window-item>
                    </v-tabs-window>
                </v-sheet>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <template v-if="activeTab === 'info'">
                    <v-btn class="ms-3" color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="submit">Lưu thông tin</v-btn>
                </template>
                <template v-else-if="activeTab === 'category'">
                    <v-btn class="ms-3" color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="saveCategories">Lưu phân loại</v-btn>
                </template>
            </v-card-actions>
        </v-card>

        <v-dialog v-model="isAddProductDialogOpen" width="500">
            <v-card>
                <template v-slot:title>Thêm hàng hoá</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close" @click="closeAddProductDialog" />
                </template>
                <v-card-text class="pt-0 pb-2">
                    <uc-search-nguyen-lieu v-model="hangHoaId" label="Hàng hoá" />
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="addProduct">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="isDebtDialogOpen" width="720">
            <v-card>
                <template v-slot:title>{{ debtDialogTitle }}</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close" @click="closeDebtDialog" />
                </template>
                <v-card-text class="pt-0">
                    <v-row>
                        <v-col cols="6">
                            <v-text-field
                                v-model="debtForm.SoTienCongNo"
                                label="* Tổng tiền công nợ"
                                hide-details="auto"
                                density="compact"
                                @input="debtForm.SoTienCongNo = formatPrice($event.target.value)"
                                @keydown="preventNegative"
                            />
                        </v-col>
                        <v-col cols="6">
                            <v-select v-model="debtForm.TrangThaiCongNo" :items="dsTrangThai" label="Trạng thái công nợ" hide-details="auto" density="compact" />
                        </v-col>
                        <v-col cols="6">
                            <uc-date-picker v-model="debtForm.NgayBatDau" icon-color="primary" :rules="[]" label="* Ngày bắt đầu" @update:modelValue="debtForm.NgayKetThuc = null" />
                        </v-col>
                        <v-col cols="6">
                            <uc-date-picker v-model="debtForm.NgayKetThuc" icon-color="primary" :disabled="!debtForm.NgayBatDau" :min="debtForm.NgayBatDau" :rules="[]" label="Ngày kết thúc" />
                        </v-col>
                        <v-col v-if="debtForm.dsFilesParse?.length" cols="12">
                            <uc-file-chip :items="debtForm.dsFilesParse" />
                        </v-col>
                        <v-col cols="12">
                            <uc-input-file-multi v-model="debtForm.UploadFiles" label="* File hợp đồng" :multiple="false" :show-size="true" />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="saveDebtDialog">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-dialog>
</template>

<script>
export default {
    props: {
        isShow: Boolean,
        loadData: Function,
        selectedItem: Object,
        dsTrangThai: Array,
        dsPhanLoaiSuplier: Array,
    },
    data() {
        return {
            activeTab: 'info',
            newFiles: [],
            selectedCategoryIds: [],
            isAddProductDialogOpen: false,
            isDebtDialogOpen: false,
            isDebtEditMode: false,
            hangHoaId: null,
            suplierProductRows: [],
            debtRows: [],
            DsHistory: [],
            debtForm: {
                CongNo_Id: null,
                SoTienCongNo: null,
                NgayBatDau: null,
                NgayKetThuc: null,
                UploadFiles: null,
                dsFilesParse: [],
                TrangThaiCongNo: 'DANG_SU_DUNG',
            },
            productTableHeaders: [],
            productTableOptions: {
                movableColumns: false,
                resizableRows: false,
                layout: 'fitColumns',
            },
            historyTableOptions: {
                movableColumns: false,
                resizableRows: true,
                layout: 'fitColumns',
            },
            productTableKey: 0,
            historyTableKey: 0,
            historyTableHeaders: [],
            debtTableHeaders: [],
            debtTableOptions: {
                movableColumns: false,
                resizableRows: false,
                layout: 'fitColumns',
            },
            debtTableKey: 0,
        }
    },
    computed: {
        debtDialogTitle() {
            return this.isDebtEditMode ? 'Cập nhật công nợ' : 'Thêm công nợ'
        },
    },
    watch: {
        isShow(value) {
            if (value) {
                this.activeTab = 'info'
                this.initProductTableHeaders()
                this.initDebtTableHeaders()
                this.inithistoryTableHeaders()
                this.loadCategorySelections()
                this.loadSuplierProducts()
                this.loadDebtRows()
                this.onLoadHistory()
            }
        },
    },
    methods: {
        async onLoadHistory() {
            if (!this.selectedItem?.NhaCungCap_Id) {
                this.DsHistory = []
                this.historyTableKey += 1
                return
            }
            const params = {
                NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
            }
            const response = await apiCallPromise('work/HH_NhaCungCap_Trigger_Select', params)
            const nextHistoryList = Array.isArray(response?.data) ? response.data : Array.isArray(response) ? response : []
            this.DsHistory = [...nextHistoryList]
            this.historyTableKey += 1
        },
        async deleteFileByListID(listIds) {
            const data = await apiCallPromiseNoLoading('work/HH_FileData_Del_ByListFileID', {
                ListIDs: listIds,
            })
            loadingPage.hide()
            return data
        },
        async processFiles() {
            const fileDeleteList = this.selectedItem.dsFilesParse.filter((fileItem) => fileItem.Is_Delete === true)
            const fileSaveList = this.selectedItem.dsFilesParse.filter((fileItem) => fileItem.Is_Delete !== true)
            let newFileList = []
            const uploadFiles = this.newFiles === null ? [] : this.newFiles
            if (fileDeleteList.length > uploadFiles.length) {
                const fileDiff = fileDeleteList.length - uploadFiles.length
                const deletedFiles = fileDeleteList.slice(-fileDiff)
                const listIds = deletedFiles.map((fileItem) => fileItem.FileID).join(',')
                await this.deleteFileByListID(listIds)
            } else {
                const replaceFileIds = fileDeleteList.map((fileItem) => fileItem.FileID).join(',')
                const response = await apiFile.insertAndUpdate(
                    {
                        file: [...uploadFiles],
                        List_FileID: replaceFileIds,
                    },
                    {
                        maxFileSize: 2,
                        showToast: true,
                        validateFileSize: true,
                    },
                )
                // Neu upload file that bai thi dung luon qua trinh submit va bao loi cho nguoi dung.
                if (!response?.isSuccess) {
                    showToast.error('Upload file thất bại')
                    return null
                }
                newFileList = response.data
            }

            return [...fileSaveList, ...newFileList].map((fileItem) => fileItem.FileID).join(',')
        },
        markFileDeleted(item) {
            this.selectedItem.dsFilesParse[item.index].Is_Delete = true
        },
        closeDialog() {
            this.activeTab = 'info'
            this.isAddProductDialogOpen = false
            this.closeDebtDialog()
            this.hangHoaId = null
            this.newFiles = []
            this.$emit('update:isShow', false)
        },
        inithistoryTableHeaders() {
            this.historyTableHeaders = [
                {
                    title: '#',
                    formatter: 'rownum',
                    width: 80,
                    hozAlign: 'center',
                },
                {
                    title: 'Hành động',
                    field: 'Action',
                    width: 150,
                    hozAlign: 'center',
                    headerSort: true,
                    headerFilter: 'list',
                    headerFilterParams: {
                        values: {
                            '': 'Tất cả',
                            INSERT: 'Tạo mới',
                            UPDATE: 'Cập nhật',
                        },
                    },
                    formatter: function (cell) {
                        const value = cell.getValue()

                        let colorClass = 'chip-grey'
                        let chipName = value

                        if (value === 'INSERT') {
                            colorClass = 'chip-primary'
                            chipName = 'Tạo mới'
                        } else if (value === 'UPDATE') {
                            colorClass = 'chip-warning'
                            chipName = 'Cập nhật'
                        }

                        return `<span class="chip ${colorClass}">${chipName}</span>`
                    },
                },
                {
                    title: 'Người tạo',
                    field: 'HoTenNguoiTao',
                    width: 180,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Ngày tạo',
                    field: 'NgayTao',
                    hozAlign: 'center',
                    width: 180,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Người sửa',
                    field: 'HoTenNguoiSua',
                    width: 180,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Ngày sửa',
                    field: 'NgaySua',
                    hozAlign: 'center',
                    width: 180,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Mã nhà cung cấp',
                    field: 'MaNhaCungCap',
                    width: 170,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Tên nhà cung cấp',
                    field: 'TenNhaCungCap',
                    width: 170,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Nhóm nhà cung cấp',
                    field: 'TenNhomPhanLoai',
                    headerSort: true,
                    width: 150,
                    headerFilter: 'input',
                },
                {
                    title: 'Mã số thuế',
                    field: 'MaSoThue',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Địa chỉ',
                    field: 'DiaChi',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Xã, phường',
                    field: 'XaPhuong',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Quận, huyện',
                    field: 'QuanHuyen',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Tỉnh, thành phố',
                    field: 'TinhThanhPho',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Quốc gia',
                    field: 'QuocGia',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Điện thoại',
                    field: 'DienThoai',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Website',
                    field: 'Website',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Số CCCD',
                    field: 'CCCD_So',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Ngày cấp CCCD',
                    field: 'CCCD_NgayCap',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Nơi cấp CCCD',
                    field: 'CCCD_NoiCap',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Tên ngân hàng',
                    field: 'NganHang_Ten',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Số tài khoản',
                    field: 'NganHang_SoTaiKhoan',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Chi nhánh ngân hàng',
                    field: 'NganHang_ChiNhanh',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Độ ưu tiên',
                    field: 'DoUuTien',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Công nợ',
                    field: 'CongNo',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'File hợp đồng',
                    field: 'FileHopDong_Id',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Thời gian hợp đồng',
                    field: 'ThoiGianHopDong',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Đánh giá',
                    field: 'DanhGia',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Giao hàng',
                    field: 'GiaoHang',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Người chịu trách nhiệm bên bán',
                    field: 'NguoiChiuTrachNhiem_BenBan',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Người chịu trách nhiệm bên mua',
                    field: 'NguoiChiuTrachNhiem_BenMua',
                    width: 150,
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Tạm khóa',
                    field: 'Is_TamKhoa',
                    width: 170,
                    hozAlign: 'center',
                    headerFilter: 'list',
                    headerFilterParams: {
                        values: {
                            '': 'Tất cả',
                            true: 'Tạm khóa',
                            false: 'Không khóa',
                        },
                    },
                    headerSort: false,
                    formatter: (cell) => {
                        return cell.getValue() ? `<i class="icon-table mdi mdi-lock"></i>` : ''
                    },
                },
            ]
        },
        initProductTableHeaders() {
            this.productTableHeaders = [
                {
                    title: '#',
                    formatter: 'rownum',
                    width: 80,
                    hozAlign: 'center',
                },
                {
                    title: 'Tên hàng hoá',
                    field: 'TenHangHoa',
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: 'Tạm khóa',
                    field: 'Is_TamKhoa',
                    width: 110,
                    hozAlign: 'center',
                    cssClass: 'cursor-pointer',
                    headerSort: false,
                    formatter: (cell) => {
                        const isLocked = cell.getValue()
                        if (!isLocked) return ''
                        return `<i class="icon-table text-primary mdi mdi-lock-outline"></i>`
                    },
                    cellClick: (e, cell) => {
                        const item = cell.getRow().getData()
                        this.changeProductLockStatus(item, cell)
                    },
                },
                {
                    title: '',
                    width: 60,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: () => {
                        return `<i class="icon-table text-red mdi mdi-trash-can-outline"></i>`
                    },
                    cellClick: (e, cell) => {
                        const item = cell.getRow().getData()
                        this.deleteProduct(item)
                    },
                },
            ]
        },
        initDebtTableHeaders() {
            this.debtTableHeaders = [
                {
                    title: '#',
                    formatter: 'rownum',
                    width: 80,
                    hozAlign: 'center',
                },
                {
                    title: 'Tổng tiền',
                    field: 'SoTienCongNo',
                    headerSort: true,
                    headerFilter: 'input',
                    hozAlign: 'right',
                    formatter: (cell) => this.formatPrice(cell.getValue()),
                },
                {
                    title: 'Ngày bắt đầu',
                    field: 'NgayBatDauDisplay',
                    headerSort: true,
                    headerFilter: 'input',
                    hozAlign: 'center',
                    width: 150,
                },
                {
                    title: 'Ngày kết thúc',
                    field: 'NgayKetThucDisplay',
                    headerSort: true,
                    headerFilter: 'input',
                    hozAlign: 'center',
                    width: 150,
                },
                {
                    title: 'Trạng thái',
                    field: 'TrangThaiCongNo',
                    headerSort: true,
                    headerFilter: 'input',
                    width: 180,
                    formatter: (cell) => {
                        const value = cell.getValue() || ''
                        const colorClass = this.getDebtStatusClass(value)
                        return `<div class="${colorClass} font-weight-medium">${value}</div>`
                    },
                },
                {
                    title: 'File hợp đồng',
                    field: 'FileName',
                    headerSort: true,
                    headerFilter: 'input',
                },
                {
                    title: '',
                    width: 60,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: () => `<i class="icon-table text-primary mdi mdi-square-edit-outline"></i>`,
                    cellClick: (e, cell) => {
                        const item = cell.getRow().getData()
                        this.openEditDebtDialog(item)
                    },
                },
                {
                    title: '',
                    width: 60,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: () => `<i class="icon-table text-red mdi mdi-trash-can-outline"></i>`,
                    cellClick: (e, cell) => {
                        const item = cell.getRow().getData()
                        this.deleteDebt(item)
                    },
                },
            ]
        },
        async submit() {
            if (!this.selectedItem.TenNhaCungCap) {
                showToast.error('Vui lòng nhập tên nhà cung cấp')
                return
            }
            if (!this.selectedItem.MaNhaCungCap) {
                showToast.error('Vui lòng nhập mã nhà cung cấp')
                return
            }

            // Quan ly loading tai 1 diem duy nhat de tranh bi lech show/hide giua cac nhanh xu ly file.
            // loadingPage.show()
            try {
                const fileIds = await this.processFiles()
                // Neu processFiles tra ve null (upload that bai) thi chan goi API cap nhat nha cung cap.
                if (fileIds === null) {
                    return
                }
                const params = {
                    NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
                    TenNhaCungCap: this.selectedItem.TenNhaCungCap,
                    MaNhaCungCap: this.selectedItem.MaNhaCungCap,
                    TrangThai: this.selectedItem.TrangThai,
                    MaSoThue: this.selectedItem.MaSoThue,
                    DanhGia: this.selectedItem.DanhGia,
                    NguoiChiuTrachNhiem_BenBan: this.selectedItem.NguoiChiuTrachNhiem_BenBan,
                    NguoiChiuTrachNhiem_BenMua: this.selectedItem.NguoiChiuTrachNhiem_BenMua,
                    CongNo: this.selectedItem.CongNo,
                    DoUuTien: this.selectedItem.DoUuTien,
                    FileHopDong_Id: fileIds ? fileIds : '',
                    ThoiGianHopDong: this.selectedItem.ThoiGianHopDong,
                    GiaoHang: this.selectedItem.GiaoHang,
                    DiaChi: this.selectedItem.DiaChi,
                    XaPhuong: this.selectedItem.XaPhuong,
                    QuanHuyen: this.selectedItem.QuanHuyen,
                    TinhThanhPho: this.selectedItem.TinhThanhPho,
                    QuocGia: this.selectedItem.QuocGia,
                    DienThoai: this.selectedItem.DienThoai,
                    Website: this.selectedItem.Website,
                    CCCD_So: this.selectedItem.CCCD_So,
                    CCCD_NgayCap: this.selectedItem.CCCD_NgayCap,
                    CCCD_NoiCap: this.selectedItem.CCCD_NoiCap,
                    NganHang_SoTaiKhoan: this.selectedItem.NganHang_SoTaiKhoan,
                    NganHang_Ten: this.selectedItem.NganHang_Ten,
                    NganHang_ChiNhanh: this.selectedItem.NganHang_ChiNhanh,
                    Is_TamKhoa: this.selectedItem.Is_TamKhoa ? 1 : 0,
                }
                await apiCallPromise('work/HH_NhaCungCap_Update', params)
                showToast.success('Cập nhật nhà cung cấp thành công')
                this.closeDialog()
                this.loadData()
            } finally {
                loadingPage.hide()
            }
        },
        loadCategorySelections() {
            apiCall(
                'work/HH_NhaCungCap_NhomPhanLoai_Select_ById',
                {
                    NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
                },
                (response) => {
                    const selectedRows = response.data || []
                    this.selectedCategoryIds = selectedRows.map((item) => item.PhanLoai_NhaCungCap_Id)
                },
            )
        },
        saveCategories() {
            apiCall(
                'work/HH_NhaCungCap_NhomPhanLoai_Update',
                {
                    NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
                    PhanLoai_NhaCungCap_Id_Lists: this.selectedCategoryIds.length > 0 ? this.selectedCategoryIds.join(',') : '',
                },
                () => {
                    showToast.success('Cập nhật nhóm phân loại thành công')
                    this.loadData()
                    this.loadCategorySelections()
                },
            )
        },
        async loadSuplierProducts() {
            if (!this.selectedItem?.NhaCungCap_Id) {
                this.suplierProductRows = []
                this.productTableKey += 1
                return
            }
            const params = {
                NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
            }
            const response = await apiCallPromise('work/HH_HangHoa_NhaCungCap_Select_ByNhaCungCap_Id', params)
            const nextProductRows = Array.isArray(response?.data) ? response.data : Array.isArray(response) ? response : []
            this.suplierProductRows = [...nextProductRows]
            this.productTableKey += 1
        },
        openAddProductDialog() {
            this.isAddProductDialogOpen = true
            this.hangHoaId = null
        },
        closeAddProductDialog() {
            this.isAddProductDialogOpen = false
            this.hangHoaId = null
        },
        addProduct() {
            if (this.hangHoaId === null) {
                showToast.info('Chưa có hàng hoá')
                return
            }
            const params = {
                HangHoa_Id: this.hangHoaId,
                NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
            }
            apiCall('work/HH_HangHoa_NhaCungCap_Insert', params, () => {
                showToast.success('Thành công')
                this.loadSuplierProducts()
                this.closeAddProductDialog()
            })
        },
        changeProductLockStatus(item, cell) {
            const nextLockStatus = !item.Is_TamKhoa
            const params = {
                HangHoa_NhaCungCap_Id: item.HangHoa_NhaCungCap_Id,
                Is_TamKhoa: nextLockStatus,
            }
            apiCall('work/HH_HangHoa_NhaCungCap_Update', params, () => {
                showToast.success('Thành công')
                item.Is_TamKhoa = nextLockStatus
                if (cell) {
                    cell.setValue(nextLockStatus)
                }
            })
        },
        deleteProduct(item) {
            const params = {
                HangHoa_NhaCungCap_Id: item.HangHoa_NhaCungCap_Id,
            }
            showConfirm(`Bạn chắc chắn muốn xóa hàng hoá phân phối? <br/> <b>${item.TenHangHoa}</b>`, () => {
                apiCall('work/HH_HangHoa_NhaCungCap_Delete', params, () => {
                    showToast.success('Thành công')
                    this.loadSuplierProducts()
                })
            })
        },
        getDebtStatusClass(trangThai) {
            switch (trangThai) {
                case 'DANG_SU_DUNG':
                    return 'text-green'
                case 'NGUNG_SU_DUNG':
                    return 'text-red'
                case 'DANG_TEST':
                    return 'text-orange'
                default:
                    return 'text-grey'
            }
        },
        openAddDebtDialog() {
            this.isDebtEditMode = false
            this.resetDebtForm()
            this.isDebtDialogOpen = true
        },
        openEditDebtDialog(item) {
            this.isDebtEditMode = true
            this.debtForm = {
                CongNo_Id: item.CongNo_Id,
                SoTienCongNo: this.formatPrice(item.SoTienCongNo),
                NgayBatDau: item.NgayBatDauRaw,
                NgayKetThuc: item.NgayKetThucRaw,
                UploadFiles: null,
                dsFilesParse: item.dsFilesParse || [],
                TrangThaiCongNo: item.TrangThaiCongNo,
            }
            this.isDebtDialogOpen = true
        },
        deleteDebt(item) {
            showConfirm(`Bạn chắc chắn muốn xóa công nợ? <br/> <b>${this.formatPrice(item.SoTienCongNo)}</b>`, () => {
                apiCall(
                    'work/HH_CongNo_Delete',
                    {
                        CongNo_Id: item.CongNo_Id,
                    },
                    () => {
                        showToast.success('Xóa thành công')
                        this.loadDebtRows()
                    },
                )
            })
        },
        closeDebtDialog() {
            this.isDebtDialogOpen = false
            this.isDebtEditMode = false
            this.resetDebtForm()
        },
        resetDebtForm() {
            this.debtForm = {
                CongNo_Id: null,
                SoTienCongNo: null,
                NgayBatDau: null,
                NgayKetThuc: null,
                UploadFiles: null,
                dsFilesParse: [],
                TrangThaiCongNo: 'DANG_SU_DUNG',
            }
        },
        async deleteDebtFileByListID(listIds) {
            const data = await apiCallPromise('work/HH_FileData_Del_ByListFileID', {
                ListIDs: listIds,
            })
            return data
        },
        async processDebtFiles() {
            loadingPage.show()
            let newFileList = []
            let bothSaveAndNew = []
            const uploadFiles = this.debtForm.UploadFiles ? [this.debtForm.UploadFiles] : []
            if (uploadFiles.length > 0) {
                if (this.debtForm.dsFilesParse !== null && this.debtForm.dsFilesParse.length > 0) {
                    const listIds = this.debtForm.dsFilesParse.map((fileItem) => fileItem.FileID).join(',')
                    await this.deleteDebtFileByListID(listIds)
                }

                const response = await apiFile.insertAndUpdate(
                    {
                        file: uploadFiles,
                        List_FileID: '',
                    },
                    {
                        maxFileSize: 2,
                        showToast: true,
                        validateFileSize: true,
                    },
                )
                if (!response.isSuccess) return
                newFileList = response.data
                bothSaveAndNew = [...newFileList]
            } else {
                bothSaveAndNew = this.debtForm.dsFilesParse
            }
            loadingPage.hide()
            return bothSaveAndNew.map((fileItem) => fileItem.FileID).join(',')
        },
        async saveDebtDialog() {
            if (!this.debtForm.SoTienCongNo) {
                showToast.error('Vui lòng nhập số tiền công nợ')
                return
            }
            if (!this.debtForm.NgayBatDau) {
                showToast.error('Vui lòng nhập ngày bắt đầu')
                return
            }
            if (!this.isDebtEditMode && this.debtForm.UploadFiles === null) {
                showToast.error('Vui lòng upload file hợp đồng')
                return
            }

            const fileIds = await this.processDebtFiles()
            const params = {
                CongNo_Id: this.debtForm.CongNo_Id,
                File_HopDong_Id: fileIds,
                NgayBatDau: this.debtForm.NgayBatDau ? dayjs(this.debtForm.NgayBatDau).format('YYYY-MM-DD') : '',
                NgayKetThuc: this.debtForm.NgayKetThuc ? dayjs(this.debtForm.NgayKetThuc).format('YYYY-MM-DD') : '',
                TrangThaiCongNo: this.debtForm.TrangThaiCongNo,
                SoTienCongNo: this.debtForm.SoTienCongNo ? this.debtForm.SoTienCongNo?.replace(/\./g, '')?.replace(/\,/g, '.') : this.debtForm.SoTienCongNo,
            }

            const apiName = this.isDebtEditMode ? 'work/HH_CongNo_Update' : 'work/HH_CongNo_Insert'
            const apiParams = this.isDebtEditMode
                ? params
                : {
                      Data_JSON: JSON.stringify([
                          {
                              NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
                              File_HopDong_Id: fileIds,
                              NgayBatDau: params.NgayBatDau,
                              NgayKetThuc: params.NgayKetThuc,
                              SoTienCongNo: params.SoTienCongNo || 0,
                              TrangThaiCongNo: params.TrangThaiCongNo,
                          },
                      ]),
                  }

            apiCall(apiName, apiParams, () => {
                showToast.success(this.isDebtEditMode ? 'Cập nhật thành công' : 'Tạo mới công nợ thành công')
                this.loadDebtRows()
                this.closeDebtDialog()
            })
        },
        formatPrice(value) {
            if (!value) return ''
            const raw = value.toString().replace(/\D/g, '')
            const number = Number(raw)
            if (isNaN(number)) return ''
            return number.toLocaleString('vi-VN')
        },
        preventNegative(event) {
            if (event.key === '-' || event.key === 'e' || event.key === '+') {
                event.preventDefault()
            }
        },
        loadDebtRows() {
            apiCall(
                'work/HH_CongNo_Select_ById',
                {
                    NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
                },
                (response) => {
                    const nextDebtRows = response.data.map((item) => {
                        return {
                            ...item,
                            dsFilesParse: item.DanhSachFile ? JSON.parse(item.DanhSachFile) : [],
                            NgayBatDauRaw: item.NgayBatDau,
                            NgayKetThucRaw: item.NgayKetThuc,
                            NgayBatDauDisplay: item.NgayBatDau ? formatDate(item.NgayBatDau, 'DD/MM/YYYY') : '',
                            NgayKetThucDisplay: item.NgayKetThuc ? formatDate(item.NgayKetThuc, 'DD/MM/YYYY') : '',
                        }
                    })
                    this.debtRows = [...nextDebtRows]
                    this.debtTableKey += 1
                },
            )
        },
    },
}
</script>

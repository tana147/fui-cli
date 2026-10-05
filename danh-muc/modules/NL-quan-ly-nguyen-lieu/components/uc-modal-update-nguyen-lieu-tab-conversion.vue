<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Chuyển đổi đơn vị ({{ conversionRows.length }})</div>
            <v-spacer></v-spacer>
            <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openAddConversionDialog">Thêm đơn vị</v-btn>
        </div>

        <z-table v-if="isConversionTableReady" @onMove="onMove" :headers="conversionTableHeaders" :items="conversionRows" height="480px" :options="conversionTableOptions" />

        <v-dialog v-model="isAddConversionDialogOpen" width="980">
            <v-card>
                <template v-slot:title>Thêm chuyển đổi đơn vị</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close" @click="closeAddConversionDialog" />
                </template>
                <v-card-text>
                    <div class="d-flex align-center mb-3">
                        <!-- <div class="text-medium-emphasis">Nhập nhiều đơn vị quy đổi cùng lúc</div> -->
                        <v-spacer />
                        <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click="addDraftRow">Thêm đơn vị</v-btn>
                    </div>

                    <div class="border rounded" style="max-height: 460px; overflow: auto">
                        <v-table class="compact-conversion-table" density="compact" fixed-header>
                            <thead>
                                <tr>
                                    <th style="width: 48px">#</th>
                                    <th style="min-width: 140px">Tên thay thế</th>
                                    <th style="min-width: 170px">Đơn vị nhập</th>
                                    <th style="min-width: 170px">Đơn vị quy đổi</th>
                                    <th style="min-width: 95px">Hệ số</th>
                                    <th style="min-width: 140px">Ghi chú</th>
                                    <th style="width: 90px">Tạm khóa</th>
                                    <th style="width: 64px"></th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(row, index) in conversionDraftRows" :key="index">
                                    <td>{{ index + 1 }}</td>
                                    <td>
                                        <v-text-field v-model="row.TenThayThe" density="compact" hide-details="auto" variant="underlined" />
                                    </td>
                                    <td>
                                        <uc-select-don-vi
                                            v-model:value="row.DonViGoc_Id"
                                            label=""
                                            placeholder="Đơn vị nhập"
                                            isUnderlined
                                            :initValue="{ title: recordData?.TenDonVi, value: row.DonViGoc_Id }"
                                        />
                                    </td>
                                    <td>
                                        <uc-select-don-vi v-model:value="row.QuyDoi_DonViTinh_Id" label="" placeholder="Đơn vị quy đổi" isUnderlined />
                                    </td>
                                    <td>
                                        <v-text-field
                                            v-model="row.QuyDoi_HeSo"
                                            density="compact"
                                            hide-details="auto"
                                            variant="underlined"
                                            type="number"
                                            min="0"
                                            step="0.01"
                                            @keydown="preventNegative"
                                        />
                                    </td>
                                    <td>
                                        <v-text-field v-model="row.GhiChu" density="compact" hide-details="auto" variant="underlined" />
                                    </td>
                                    <td>
                                        <v-checkbox v-model="row.Is_TamKhoa" color="primary" hide-details density="compact" />
                                    </td>
                                    <td>
                                        <v-btn size="x-small" variant="text" color="error" icon="mdi-delete-outline" :disabled="conversionDraftRows.length === 1" @click="removeDraftRow(index)" />
                                    </td>
                                </tr>
                            </tbody>
                        </v-table>
                    </div>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="addConversion">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="isUpdateConversionDialogOpen" width="860">
            <v-card>
                <template v-slot:title>Cập nhật chuyển đổi đơn vị</template>
                <template v-slot:append>
                    <v-btn size="small" variant="text" icon="mdi-close" @click="isUpdateConversionDialogOpen = false" />
                </template>
                <v-card-text>
                    <v-row>
                        <v-col cols="4">
                            <v-text-field v-model="editData.TenThayThe" label="Tên thay thế" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <uc-select-don-vi
                                v-model:value="editData.DonViGoc_Id"
                                label="Đơn vị nhập"
                                placeholder="Đơn vị nhập"
                                :initValue="{ title: editData.TenDonVi, value: editData.DonViGoc_Id }"
                            />
                        </v-col>
                        <v-col cols="4">
                            <uc-select-don-vi
                                v-model:value="editData.QuyDoi_DonViTinh_Id"
                                label="Đơn vị quy đổi"
                                placeholder="Đơn vị quy đổi"
                                :initValue="{ title: editData.QuyDoi_DonViTinh_Ten, value: editData.QuyDoi_DonViTinh_Id }"
                            />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="editData.QuyDoi_HeSo" label="Hệ số" density="compact" hide-details="auto" type="number" min="0" step="0.01" @keydown="preventNegative" />
                        </v-col>
                        <v-col cols="8">
                            <v-text-field v-model="editData.GhiChu" label="Ghi chú" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox v-model="editData.Is_TamKhoa" label="Tạm khóa" color="primary" density="compact" hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="saveConversion">Lưu</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
export default {
    props: {
        recordData: { type: Object, default: null },
        active: { type: Boolean, default: false },
    },
    emits: ['reloaded'],
    data() {
        return {
            conversionTableOptions: {
                movableColumns: false,
                resizableRows: false,
                layout: 'fitDataStretch',
                movableRows: true,
                rowHeader: { minWidth: 35, width: 35, rowHandle: true, formatter: 'handle', cssClass: 'drag-row-handle' },
            },
            isConversionTableReady: false,
            conversionTableHeaders: [],
            conversionRows: [],
            isAddConversionDialogOpen: false,
            isUpdateConversionDialogOpen: false,
            conversionDraftRows: [],
            editData: {},
        }
    },
    watch: {
        active: {
            immediate: true,
            handler(val) {
                if (val && this.recordData?.HangHoa_Id) this.loadConversionRows()
            },
        },
        'recordData.HangHoa_Id'(val) {
            this.resetDraft()
            if (this.active && val) this.loadConversionRows()
        },
    },
    created() {
        this.initHeaders()
    },
    methods: {
        createEmptyDraft() {
            return {
                TenThayThe: '',
                DonViGoc_Id: this.recordData?.Chuan_DonViTinh_Id || null,
                QuyDoi_HeSo: null,
                QuyDoi_DonViTinh_Id: null,
                GhiChu: '',
                Is_TamKhoa: false,
            }
        },
        resetDraft() {
            this.conversionDraftRows = [this.createEmptyDraft()]
        },
        openAddConversionDialog() {
            this.resetDraft()
            this.isAddConversionDialogOpen = true
        },
        addDraftRow() {
            this.conversionDraftRows.push(this.createEmptyDraft())
        },
        removeDraftRow(index) {
            if (this.conversionDraftRows.length === 1) {
                this.conversionDraftRows = [this.createEmptyDraft()]
                return
            }
            this.conversionDraftRows.splice(index, 1)
        },
        initHeaders() {
            this.conversionTableHeaders = [
                { title: '#', formatter: 'rownum', width: 70, hozAlign: 'center' },
                { title: 'Tên thay thế', field: 'TenThayThe', headerSort: true, headerFilter: 'input', width: 180 },
                { title: 'Đơn vị nhập', field: 'TenDonVi', headerSort: true, headerFilter: 'input', width: 140, hozAlign: 'center' },
                { title: 'Hệ số', field: 'QuyDoi_HeSo', headerSort: true, headerFilter: 'input', width: 120, hozAlign: 'right' },
                { title: 'Đơn vị quy đổi', field: 'QuyDoi_DonViTinh_Ten', headerSort: true, headerFilter: 'input', width: 160 },
                { title: 'Ghi chú', field: 'GhiChu', headerSort: true, headerFilter: 'input', width: 180 },
                {
                    title: 'Tạm khóa',
                    field: 'Is_TamKhoa',
                    width: 100,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: (cell) => (cell.getValue() ? '<i class="icon-table text-primary mdi mdi-lock-outline"></i>' : ''),
                },
                {
                    title: '',
                    width: 60,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: () => '<i class="icon-table text-primary mdi mdi-square-edit-outline"></i>',
                    cellClick: (e, cell) => this.updateConversion(cell.getRow().getData()),
                },
                {
                    title: '',
                    width: 60,
                    hozAlign: 'center',
                    headerSort: false,
                    formatter: () => '<i class="icon-table text-red mdi mdi-trash-can-outline"></i>',
                    cellClick: (e, cell) => this.deleteConversion(cell.getRow().getData()),
                },
            ]
        },
        async loadConversionRows() {
            if (!this.recordData?.HangHoa_Id) return
            this.isConversionTableReady = false
            const response = await apiCallPromise('/work/MT_NguyenLieu_Select_By_Id', {
                HangHoa_Id: this.recordData.HangHoa_Id,
            })
            const detailRows = Array.isArray(response?.data?.[1]) ? response.data[1] : Array.isArray(response?.[1]) ? response[1] : []
            this.conversionRows = detailRows
            this.isConversionTableReady = true
        },
        onMove(row) {
            const tableData = row.getTable().getData()
            tableData.forEach((item, index) => {
                item.ThuTu = index + 1
            })
            const arr = tableData.map((item) => ({
                HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                ThuTu: item.ThuTu,
            }))
            if (arr.length === 0) {
                showToast.info('Không có dữ liệu để lưu thứ tự!')
                return
            }
            apiCall('/work/HH_HangHoaQuyDoi_Update_ThuTu', { Data_JSON: JSON.stringify(arr) }, async () => {
                showToast.success('Cập nhật thứ tự thành công!')
                await this.loadConversionRows()
                this.$emit('reloaded')
            })
        },
        closeAddConversionDialog() {
            this.isAddConversionDialogOpen = false
            this.resetDraft()
        },
        addConversion() {
            const draftRows = this.conversionDraftRows.filter((row) => row.TenThayThe || row.DonViGoc_Id || row.QuyDoi_DonViTinh_Id || row.QuyDoi_HeSo || row.GhiChu || row.Is_TamKhoa)

            if (!draftRows.length) {
                showToast.error('Vui lòng nhập ít nhất một dòng quy đổi')
                return
            }

            for (let i = 0; i < draftRows.length; i += 1) {
                const row = draftRows[i]
                // Dùng position: 'top' để đồng nhất với saveConversion
                if (!row.QuyDoi_DonViTinh_Id) {
                    showToast.error(`Dòng ${i + 1}: Vui lòng chọn đơn vị quy đổi`)
                    return
                }
                if (!row.QuyDoi_HeSo || Number(row.QuyDoi_HeSo) <= 0) {
                    showToast.error(`Dòng ${i + 1}: Hệ số quy đổi phải lớn hơn 0`)
                    return
                }
            }

            const payload = draftRows.map((row, index) => ({
                ThuTu: this.conversionRows.length + index + 1,
                HangHoa_Id: this.recordData.HangHoa_Id,
                DonViGoc_Id: row.DonViGoc_Id || this.recordData.Chuan_DonViTinh_Id,
                TenThayThe: row.TenThayThe,
                QuyDoi_DonViTinh_Id: row.QuyDoi_DonViTinh_Id,
                QuyDoi_HeSo: row.QuyDoi_HeSo,
                Is_TamKhoa: row.Is_TamKhoa ? 1 : 0,
                GhiChu: row.GhiChu,
            }))

            apiCall('/work/HH_HangHoaQuyDoi_Insert', { Data_JSON: JSON.stringify(payload) }, async () => {
                showToast.success(`Thêm thành công ${payload.length} đơn vị quy đổi`)
                this.closeAddConversionDialog()
                await this.loadConversionRows()
                this.$emit('reloaded')
            })
        },
        updateConversion(item) {
            this.editData = JSON.parse(JSON.stringify(item))
            this.isUpdateConversionDialogOpen = true
        },
        saveConversion() {
            // Message đồng nhất với addConversion — tránh gây nhầm lẫn cho người dùng
            if (!this.editData.QuyDoi_DonViTinh_Id) {
                showToast.error('Vui lòng chọn đơn vị quy đổi')
                return
            }
            if (!this.editData.QuyDoi_HeSo || Number(this.editData.QuyDoi_HeSo) <= 0) {
                showToast.error('Hệ số quy đổi phải lớn hơn 0')
                return
            }
            apiCall(
                '/work/HH_HangHoaQuyDoi_Update',
                {
                    HangHoa_Id: this.editData.HangHoa_Id,
                    HangHoa_QuyDoi_Id: this.editData.HangHoa_QuyDoi_Id,
                    ThuTu: this.editData.ThuTu,
                    TenThayThe: this.editData.TenThayThe?.trim(),
                    QuyDoi_DonViTinh_Id: this.editData.QuyDoi_DonViTinh_Id,
                    DonViGoc_Id: this.editData.DonViGoc_Id,
                    QuyDoi_HeSo: this.editData.QuyDoi_HeSo,
                    GhiChu: this.editData.GhiChu,
                    Is_TamKhoa: this.editData.Is_TamKhoa,
                },
                async () => {
                    await this.loadConversionRows()
                    showToast.success('Cập nhật thành công!')
                    this.isUpdateConversionDialogOpen = false
                    this.$emit('reloaded')
                },
            )
        },
        deleteConversion(item) {
            showConfirm(`Bạn chắc chắn muốn xóa quy đổi? <br/> <b>${item.QuyDoi_DonViTinh_Ten || item.TenThayThe || ''}</b>`, async () => {
                const remainRows = this.conversionRows.filter((row) => row.HangHoa_QuyDoi_Id !== item.HangHoa_QuyDoi_Id)
                const sortPayload = remainRows.map((row, index) => ({ ThuTu: index + 1, HangHoa_QuyDoi_Id: row.HangHoa_QuyDoi_Id }))
                apiCall(
                    '/work/HH_HangHoaQuyDoi_Delete',
                    {
                        HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                        Data_JSON: JSON.stringify(sortPayload),
                    },
                    async () => {
                        showToast.success('Xóa thành công')
                        await this.loadConversionRows()
                        this.$emit('reloaded')
                    },
                )
            })
        },
        preventNegative(e) {
            if (e.key === '-' || e.key === 'e' || e.key === '+') {
                e.preventDefault()
            }
        },
    },
}
</script>

<template>
    <v-dialog v-model="modelValue" max-width="1000">
        <v-card>
            <template v-slot:title>Quy đổi đơn vị • {{ record?.TenHangHoa }}</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <div v-if="isOpenAdd" class="mb-3">
                    <v-row>
                        <v-col cols="12">
                            <v-data-table ref="addTable" :items-per-page="-1" hide-default-footer dense :hover="true" :disable-sort="true" fixed-header :headers="AddHeader" :items="DsAddQuyDoi">
                                <template v-slot:top>
                                    <v-toolbar flat>
                                        <v-toolbar-title> Thêm mới quy đổi </v-toolbar-title>
                                    </v-toolbar>
                                </template>

                                <template v-slot:item.DonViGoc_Id="{ item }">
                                    <uc-select-don-vi
                                        v-model:value="item.DonViGoc_Id"
                                        isUnderlined
                                        placeholder="Đơn vị nhập"
                                        :initValue="{
                                            title: item.TenDonVi_Nhap,
                                            value: item.DonViGoc_Id,
                                        }"
                                    />
                                </template>

                                <template v-slot:item.Equal>
                                    <p>=</p>
                                </template>

                                <template v-slot:item.DonViTinh_Id="{ item }">
                                    <uc-select-don-vi v-model:value="item.DonViTinh_Id" isUnderlined placeholder="Đơn vị quy đổi" />
                                </template>

                                <template v-slot:item.TenThayThe="{ item }">
                                    <v-text-field v-model="item.TenThayThe" label="Tên thay thế" dense hide-details variant="underlined" />
                                </template>

                                <template v-slot:item.HeSoQuyDoi="{ item }">
                                    <v-text-field
                                        class="text-right-input"
                                        v-model="item.HeSoQuyDoi"
                                        variant="underlined"
                                        placeholder="Hệ số"
                                        type="number"
                                        min="0"
                                        step="0.01"
                                        inputmode="decimal"
                                        @keydown="preventNegative"
                                        dense
                                        outlined
                                    />
                                </template>

                                <template v-slot:item.GhiChu="{ item }">
                                    <v-textarea v-model="item.GhiChu" variant="underlined" placeholder="Ghi chú" dense rows="1" auto-grow />
                                </template>

                                <template v-slot:item.Is_TamKhoa="{ item }">
                                    <v-checkbox v-model="item.Is_TamKhoa" dense color="primary" />
                                </template>

                                <template v-slot:item.Action="{ item, index }">
                                    <v-btn :disabled="DsAddQuyDoi.length === 1" icon="mdi-trash-can" variant="text" color="red" @click="onDeleteRow(index)" />
                                </template>
                            </v-data-table>
                        </v-col>
                    </v-row>

                    <div class="d-flex justify-center align-center mt-3">
                        <v-btn color="primary" variant="text" @click="addRow" prepend-icon="mdi-plus">Thêm đơn vị quy đổi </v-btn>
                    </div>
                </div>

                <v-table v-show="!isOpenAdd" ref="quyDoiTable" density="compact" hover>
                    <!-- TOP TOOLBAR -->
                    <template #top>
                        <v-toolbar flat>
                            <v-toolbar-title>Danh sách quy đổi</v-toolbar-title>
                            <v-spacer />
                            <v-btn icon="mdi-plus" size="32" variant="outlined" color="primary" @click="onOpenAdd" />
                        </v-toolbar>
                    </template>

                    <!-- HEADER -->
                    <thead>
                        <tr>
                            <th style="width: 50px"></th>
                            <th style="width: 50px" class="text-center">#</th>
                            <th style="width: 180px">Tên thay thế</th>
                            <th style="width: 180px" class="text-center">Đơn vị nhập</th>
                            <th style="width: 40px" class="text-center"></th>
                            <th style="width: 100px" class="text-center">Hệ số</th>
                            <th style="width: 180px" class="text-center">ĐV quy đổi</th>
                            <th style="min-width: 120px">Ghi chú</th>
                            <th style="width: 70px" class="text-center">Khóa</th>
                            <th style="width: 80px" class="text-center"></th>
                        </tr>
                    </thead>

                    <!-- BODY -->
                    <tbody>
                        <tr v-for="(item, index) in DsChuyenDoi" :key="item.HangHoa_QuyDoi_Id">
                            <!-- Drag -->
                            <td class="text-center">
                                <v-icon v-if="!isUpdateState" class="drag-handle" color="grey"> mdi-drag </v-icon>
                            </td>

                            <!-- ThuTu -->
                            <td class="text-center">
                                {{ item.ThuTu }}
                            </td>

                            <!-- TenThayThe -->
                            <td>
                                <p v-if="!item.Is_Update">{{ item.TenThayThe }}</p>
                                <v-text-field v-else v-model="item.TenThayThe_Update" variant="underlined" density="compact" hide-details />
                            </td>

                            <!-- DonViGoc -->
                            <td class="text-center">
                                <p v-if="!item.Is_Update">{{ item.TenDonVi }}</p>
                                <uc-select-don-vi
                                    v-else
                                    v-model:value="item.DonViGoc_Id_Update"
                                    isUnderlined
                                    :initValue="{
                                        title: item.TenDonVi,
                                        value: item.DonViGoc_Id,
                                    }"
                                />
                            </td>

                            <!-- Equal -->
                            <td class="text-center">=</td>

                            <!-- He so -->
                            <td class="text-center">
                                <p v-if="!item.Is_Update">
                                    {{ item.QuyDoi_HeSo?.toLocaleString('vi-VN') }}
                                </p>
                                <v-text-field v-else v-model="item.QuyDoi_HeSo_Update" variant="underlined" density="compact" hide-details class="text-right-input" @keydown="preventNegative" />
                            </td>

                            <!-- Don vi quy doi -->
                            <td class="text-center">
                                <p v-if="!item.Is_Update">
                                    {{ item.QuyDoi_DonViTinh_Ten }}
                                </p>
                                <uc-select-don-vi
                                    v-else
                                    v-model:value="item.QuyDoi_DonViTinh_Id_Update"
                                    isUnderlined
                                    :initValue="{
                                        title: item.QuyDoi_DonViTinh_Ten,
                                        value: item.QuyDoi_DonViTinh_Id,
                                    }"
                                />
                            </td>

                            <!-- Ghi chu -->
                            <td>
                                <p v-if="!item.Is_Update">{{ item.GhiChu }}</p>
                                <v-textarea v-else v-model="item.GhiChu_Update" variant="underlined" rows="1" auto-grow density="compact" hide-details />
                            </td>

                            <!-- Tam khoa -->
                            <td class="text-center">
                                <v-icon v-if="!item.Is_Update" :color="getStatusColor(item.Is_TamKhoa)">
                                    {{ getStatusIcon(item.Is_TamKhoa) }}
                                </v-icon>

                                <v-checkbox v-else v-model="item.Is_TamKhoa_Update" color="primary" density="compact" hide-details />
                            </td>

                            <!-- Action -->
                            <td class="text-center">
                                <v-menu v-if="!item.Is_Update">
                                    <template #activator="{ props }">
                                        <v-btn size="small" variant="text" icon="mdi-dots-vertical" v-bind="props" />
                                    </template>
                                    <v-list density="compact">
                                        <v-tooltip text="Vui lòng lưu thay đổi thứ tự trước khi cập nhật" v-if="isChangLines">
                                            <template v-slot:activator="{ props }">
                                                <v-list-item class="item-disabled" v-bind="props" prepend-icon="mdi-square-edit-outline" title="Cập nhật" readonly />
                                            </template>
                                        </v-tooltip>
                                        <v-list-item v-else-if="!isChangLines" @click="openEdit(item)" prepend-icon="mdi-square-edit-outline" title="Cập nhật" />
                                        <v-divider />
                                        <v-list-item @click="onDelete(item, index)" prepend-icon="mdi-trash-can" title="Xóa" />
                                    </v-list>
                                </v-menu>

                                <div v-else class="d-flex justify-center">
                                    <v-btn class="mr-2" variant="flat" size="small" @click="onCancel(item)"> Hủy </v-btn>
                                    <v-btn size="small" variant="flat" color="primary" @click="onSave(item)"> Lưu </v-btn>
                                </div>
                            </td>
                        </tr>

                        <!-- NO DATA -->
                        <tr v-if="!DsChuyenDoi.length">
                            <td colspan="10" class="text-center py-6">Không tìm thấy dữ liệu</td>
                        </tr>
                    </tbody>
                </v-table>
            </v-card-text>

            <!-- Group button Add Quy đổi mới -->
            <v-card-actions v-if="isOpenAdd" class="pb-0 mb-0">
                <v-spacer></v-spacer>
                <v-btn @click="onCloseAdd" dense hide-details variant="flat" dark>Đóng</v-btn>
                <v-btn color="primary" hide-details @click="onAdd" prepend-icon="mdi-content-save-outline" variant="flat" dark>Lưu</v-btn>
            </v-card-actions>

            <!-- Group button Save đổi thứ tự -->
            <v-card-actions v-if="isChangLines && !isOpenAdd" class="pb-0 mb-0">
                <v-spacer></v-spacer>
                <v-btn color="warning" hide-details @click="onSaveThuTu" prepend-icon="mdi-content-save-outline" variant="flat" dark>Lưu thứ tự & Đóng</v-btn>
                <v-btn color="primary" hide-details @click="onSaveThuTuNotClose" prepend-icon="mdi-content-save-outline" variant="flat" dark>Lưu thứ tự</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['modelValue', 'record'],
    emits: ['update:modelValue', 'onReload'],
    data() {
        return {
            isOpenAdd: false,
            isChangLines: false,
            isSaveLineNotClose: false,
            isUpdateState: false,

            HangHoaInfo: {},
            formData: {
                HangHoa_Id: null,
            },
            rules: {
                required: (value) => !!value || 'Trường này không được để trống',
            },

            DsChuyenDoi: [],
            DsAddQuyDoi: [
                {
                    ThuTu: 1,
                    DonViTinh_Id: null,
                    DonViGoc_Id: null,
                    TenDonVi_Nhap: null,
                    HeSoQuyDoi: null,
                    Is_TamKhoa: 0,
                    GhiChu: null,
                },
            ],

            AddHeader: [
                { title: '#', key: 'ThuTu', sortable: false, align: 'center', width: 50 },
                { title: 'Tên thay thế', key: 'TenThayThe', sortable: false, width: 180 },
                { title: 'Đơn vị nhập', value: 'DonViGoc_Id', width: 120, align: 'center' },
                { title: '', value: 'Equal', width: 40, align: 'center' },
                { title: 'Hệ số', key: 'HeSoQuyDoi', sortable: false, width: 110 },
                { title: 'Đơn vị quy đổi', key: 'DonViTinh_Id', width: 180, sortable: false },
                { title: 'Ghi chú', key: 'GhiChu', sortable: false , width: 180, },
                { title: 'Khóa', key: 'Is_TamKhoa', sortable: false, width: 70, align: 'center' },
                { title: '', key: 'Action', sortable: false, width: 50, align: 'center' },
            ],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        modelValue(val) {
            const $this = this
            if (val) {
                console.log('record', this.record)
                this.onLoadNguyenLieuById()

                this.DsAddQuyDoi[0].DonViGoc_Id = this.record?.Chuan_DonViTinh_Id
                this.DsAddQuyDoi[0].TenDonVi_Nhap = this.record?.TenDonVi

                this.$nextTick(() => {
                    const tbody = this.$refs.quyDoiTable.$el.querySelector('tbody')

                    Sortable.create(tbody, {
                        handle: '.drag-handle',
                        animation: 150,

                        onEnd: ({ oldIndex, newIndex }) => {
                            const moved = this.DsChuyenDoi.splice(oldIndex, 1)[0]
                            this.DsChuyenDoi.splice(newIndex, 0, moved)
                            this.resetThuTu(this.DsChuyenDoi)
                            this.isChangLines = true
                        },
                    })
                })
            }
        },

        isOpenAdd(val) {
            if (val) {
                this.DsAddQuyDoi[0].ThuTu = this.DsChuyenDoi.length + 1
            }
        },
    },
    methods: {
        onOpenAdd() {
            this.isOpenAdd = true
        },

        onSaveThuTuNotClose() {
            this.isSaveLineNotClose = true
            this.onSaveThuTu()
        },

        onSaveThuTu() {
            const arr = this.DsChuyenDoi.map((item) => {
                return {
                    // HangHoa_Id: item.HangHoa_Id,
                    HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                    ThuTu: item.ThuTu,
                }
            })

            console.log('arr', arr)

            if (arr.length === 0) {
                showToast.info('Không có dữ liệu để lưu thứ tự!')
                return
            }

            apiCall(
                '/work/HH_HangHoaQuyDoi_Update_ThuTu',
                {
                    Data_JSON: JSON.stringify(arr),
                },
                () => {
                    showToast.success('Thêm nguyên liệu quy đổi thành công!')

                    if (!this.isSaveLineNotClose) {
                        this.onClose()
                    } else {
                        this.isChangLines = false
                        this.isSaveLineNotClose = false
                    }
                },
            )
        },

        resetThuTu(arr) {
            arr.forEach((item, index) => {
                item.ThuTu = index + 1
            })
            return arr
        },

        updateThuTu(arr) {
            this.DsChuyenDoi = arr.sort((a, b) => a.ThuTu - b.ThuTu)
            console.log('this.DsChuyenDoi after drag', this.DsChuyenDoi)
            console.log('arr', arr)
        },
        onCloseAdd() {
            this.resetData()
            this.isOpenAdd = false
        },

        onAdd() {
            const arr = []

            this.DsAddQuyDoi.forEach((item) => {
                arr.push({
                    ThuTu: item.ThuTu,
                    HangHoa_Id: this.record.HangHoa_Id,
                    DonViGoc_Id: item.DonViGoc_Id,
                    TenThayThe: item.TenThayThe,
                    QuyDoi_DonViTinh_Id: item.DonViTinh_Id,
                    QuyDoi_HeSo: item.HeSoQuyDoi,
                    Is_TamKhoa: item.Is_TamKhoa ? 1 : 0,
                    GhiChu: item.GhiChu,
                })
            })
            console.log('arr', arr)

            const hasError = arr.some((item, index) => {
                if (!item.QuyDoi_DonViTinh_Id) {
                    showToast.error(`Vui lòng chọn đơn vị quy đổi ở dòng ${index + 1}!`)
                    return true
                }

                if (!item.QuyDoi_HeSo || item.QuyDoi_HeSo <= 0) {
                    showToast.error(`Hệ số quy đổi phải lớn hơn 0 ở dòng ${index + 1}!`)
                    return true
                }

                return false
            })

            if (hasError) return

            apiCall(
                '/work/HH_HangHoaQuyDoi_Insert',
                {
                    Data_JSON: JSON.stringify(arr),
                },
                () => {
                    this.onLoadNguyenLieuById()
                    this.$emit('onReload')
                    this.resetData()
                    showToast.success('Thêm nguyên liệu quy đổi thành công!')

                    this.isOpenAdd = false
                },
                (error) => {
                    showToast.error(`${error.responseJSON.Message}`, {
                        position: 'top',
                    })
                },
            )
        },

        countTotalAddedRows() {
            return this.DsAddQuyDoi.length + this.DsChuyenDoi.length + 1
        },

        addRow() {
            this.DsAddQuyDoi.push({
                ThuTu: this.countTotalAddedRows(),
                TenThayThe: '',
                DonViGoc_Id: this.record?.Chuan_DonViTinh_Id,
                TenDonVi_Nhap: this.record?.TenDonVi,
                DonViTinh_Id: null,
                HeSoQuyDoi: null,
                Is_TamKhoa: 0,
                GhiChu: null,
            })
        },

        onDeleteRow(index) {
            this.DsAddQuyDoi.splice(index, 1)
        },

        preventNegative(e) {
            // Chặn các ký tự '-', 'e', '+' và số âm
            if (e.key === '-' || e.key === 'e' || e.key === '+') {
                e.preventDefault()
            }
        },

        openEdit(item) {
            item.Is_Update = true
            this.isUpdateState = true
        },

        onDelete(item, index) {
            showConfirm(`Bạn muốn xóa ĐV quy đổi "${item.QuyDoi_DonViTinh_Ten}"?`, () => {
                this.DsChuyenDoi.splice(index, 1)

                const arr = this.DsChuyenDoi.map((i, idx) => ({
                    ThuTu: idx + 1,
                    HangHoa_QuyDoi_Id: i.HangHoa_QuyDoi_Id,
                }))

                apiCall(
                    '/work/HH_HangHoaQuyDoi_Delete',
                    {
                        HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                        Data_JSON: JSON.stringify(arr),
                    },
                    () => {
                        showToast.success('Xóa thành công')
                        this.onLoadNguyenLieuById()
                        this.$emit('onReload')
                    },
                )
            })
        },

        onSave(item) {
            const $this = this

            // Kiểm tra đơn vị tính
            if (!item.QuyDoi_DonViTinh_Id_Update) {
                showToast.error('Vui lòng chọn đơn vị tính', {
                    position: 'top',
                })
                return
            }

            // Kiểm tra không được nhập 0 hệ số
            if (item.QuyDoi_HeSo_Update == 0) {
                showToast.error('Vui lòng không nhập 0 cho hệ số', {
                    position: 'top',
                })
                return
            }

            apiCall(
                '/work/HH_HangHoaQuyDoi_Update',
                {
                    HangHoa_Id: item.HangHoa_Id,
                    HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                    ThuTu: item.ThuTu,
                    TenThayThe: item.TenThayThe_Update?.trim(),
                    QuyDoi_DonViTinh_Id: item.QuyDoi_DonViTinh_Id_Update,
                    DonViGoc_Id: item.DonViGoc_Id_Update,
                    QuyDoi_HeSo: item.QuyDoi_HeSo_Update,
                    GhiChu: item.GhiChu_Update,
                    Is_TamKhoa: item.Is_TamKhoa_Update,
                },
                () => {
                    $this.onLoadNguyenLieuById()
                    item.Is_Update = false
                    this.isUpdateState = false
                    showToast.success('Cập nhật thành công!')
                },
            )
        },

        onCancel(item) {
            item.TenThayThe_Update = item.TenThayThe
            item.QuyDoi_DonViTinh_Id_Update = item.QuyDoi_DonViTinh_Id
            item.DonViGoc_Id_Update = item.DonViGoc_Id
            item.QuyDoi_HeSo_Update = item.QuyDoi_HeSo
            item.GhiChu_Update = item.GhiChu
            item.Is_TamKhoa_Update = item.Is_TamKhoa

            item.Is_Update = false
            this.isUpdateState = false
        },

        onLoadNguyenLieuById() {
            const $this = this
            apiCall(
                '/work/MT_NguyenLieu_Select_By_Id',
                {
                    HangHoa_Id: $this.record.HangHoa_Id,
                },
                (res) => {
                    this.HangHoaInfo = res.data[0][0]
                    this.DsChuyenDoi = res.data[1].map((item) => {
                        return {
                            ...item,
                            Is_Update: false,
                            Is_Add: false,
                            TenThayThe_Update: item.TenThayThe,
                            QuyDoi_HeSo_Update: item.QuyDoi_HeSo,
                            Is_TamKhoa_Update: item.Is_TamKhoa,
                            QuyDoi_DonViTinh_Ten_Update: item.QuyDoi_DonViTinh_Ten,
                            QuyDoi_DonViTinh_Id_Update: item.QuyDoi_DonViTinh_Id,
                            DonViGoc_Id_Update: item.DonViGoc_Id,
                            GhiChu_Update: item.GhiChu,
                        }
                    })
                    console.log('this.DsChuyenDoi', this.DsChuyenDoi)
                    console.log('this.HangHoaInfo', this.HangHoaInfo)
                },
            )
        },

        getStatusColor(status) {
            return getTamKhoaColor(status)
        },

        getStatusIcon(status) {
            return getTamKhoaIcon(status)
        },

        resetData() {
            this.formData.TenThayThe = ''
            this.DsAddQuyDoi = [
                {
                    ThuTu: 1,
                    DonViTinh_Id: null,
                    DonViGoc_Id: this.record?.Chuan_DonViTinh_Id,
                    TenDonVi_Nhap: this.record?.TenDonVi,
                    HeSoQuyDoi: null,
                    Is_TamKhoa: 0,
                    GhiChu: null,
                },
            ]
        },

        onClose() {
            this.isChangLines = false
            this.isSaveLineNotClose = false
            this.isOpenAdd = false
            this.isUpdateState = false
            this.resetData()
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

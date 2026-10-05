<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Chuyển đổi đơn vị ({{ tableData.length }})</div>
            <v-spacer></v-spacer>
            <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openDialog">
                Thêm đơn vị</v-btn>
        </div>
        <z-table :headers="tableHeader" :items="tableData" height="480px" :options="tableOptions" />
    </div>

    <v-dialog v-model="isShowDialogChuyenDoiDonVi" width="860">
        <v-card>
            <template v-slot:title>Thêm chuyển đổi đơn vị</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>
            <v-card-text>
                <v-form ref="form">
                    <v-row>
                        <v-col cols="4">
                            <v-text-field v-model="item.TenThayThe" label="Tên thay thế" density="compact"
                                :rules="[rules.required]" hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-autocomplete v-model="item.DonViGoc_Id" label="* Đơn vị nhập" :items="DSDonViTinh"
                                item-title="TenDonVi" item-value="DonViTinh_Id" density="compact"
                                :rules="[rules.required]" hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-autocomplete v-model="item.QuyDoi_DonViTinh_Id" label="* Đơn vị quy đổi"
                                :items="DSDonViTinh" item-title="TenDonVi" item-value="DonViTinh_Id" density="compact"
                                :rules="[rules.required]" hide-details="auto" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="item.QuyDoi_HeSo" label="Hệ số" density="compact" hide-details="auto"
                                type="number" :rules="[rules.greaterThanZero]" />
                        </v-col>
                        <v-col cols="8">
                            <v-text-field v-model="item.GhiChu" label="Ghi chú" density="compact" hide-details="auto" />
                        </v-col>
                        <v-col cols="12">
                            <v-checkbox v-model="item.Is_TamKhoa" label="Tạm khóa" color="primary" density="compact"
                                hide-details="auto" />
                        </v-col>
                    </v-row>
                </v-form>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline"
                    @click="onSubmit">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {

    props: {
        tableData: Array,
        DSDonViTinh: Array,
        selectedItem: Object,
    },
    emits: ['load-doi-don-vi'],

    data() {
        return {
            rules: {
                required: v => v !== null && v !== undefined || 'Trường này không được để trống',
                greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
                noSpecialChar: v =>
                    /^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
            },

            isShowDialogChuyenDoiDonVi: false,

            tableHeader: [
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
                    formatter: () => '<i class="icon-table text-red mdi mdi-trash-can-outline"></i>',
                    cellClick: (e, cell) => this.onDelete(cell.getRow().getData()),
                },
            ],

            tableOptions: {
                movableColumns: false,
                resizableRows: false,
                layout: 'fitDataStretch',
            },

            item: {
                DonViGoc_Id: this.selectedItem.Chuan_DonViTinh_Id
            },
        }
    },

    mounted() {
    },
    computed: {
    },

    watch: {
    },

    methods: {
        closeDialog() {
            this.isShowDialogChuyenDoiDonVi = false
            this.item = {
                DonViGoc_Id: this.selectedItem.Chuan_DonViTinh_Id
            }
        },
        openDialog() {
            this.isShowDialogChuyenDoiDonVi = true
        },
        async onSubmit() {
            const { valid } = await this.$refs.form.validate();
            if (!valid) {
                showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
                return
            }
            const params = [
                {
                    ThuTu: this.tableData.length + 1,
                    HangHoa_Id: this.selectedItem.HangHoa_Id,
                    DonViGoc_Id: this.item.DonViGoc_Id || this.selectedItem.Chuan_DonViTinh_Id,
                    TenThayThe: this.item.TenThayThe,
                    QuyDoi_DonViTinh_Id: this.item.QuyDoi_DonViTinh_Id,
                    QuyDoi_HeSo: this.item.QuyDoi_HeSo,
                    Is_TamKhoa: this.item.Is_TamKhoa ? 1 : 0,
                    GhiChu: this.item.GhiChu,
                },
            ]
            const $this = this
            apiCall('/work/HH_HangHoaQuyDoi_Insert', { Data_JSON: JSON.stringify(params) }, () => {
                showToast.success('Thêm quy đổi thành công')
                $this.$emit('load-doi-don-vi')
            })

        },

        onDelete(item) {
            showConfirm(`Bạn chắc chắn muốn xóa quy đổi? <br/> <b>${item.QuyDoi_DonViTinh_Ten || item.TenThayThe || ''}</b>`, async () => {
                const remainRows = this.tableData.filter((row) => row.HangHoa_QuyDoi_Id !== item.HangHoa_QuyDoi_Id)

                const sortPayload = remainRows.map((row, index) => ({
                    ThuTu: index + 1,
                    HangHoa_QuyDoi_Id: row.HangHoa_QuyDoi_Id,
                }))

                const params = {
                    HangHoa_QuyDoi_Id: item.HangHoa_QuyDoi_Id,
                    Data_JSON: JSON.stringify(sortPayload),
                }
                const $this = this
                apiCall('/work/HH_HangHoaQuyDoi_Delete', params, () => {
                    showToast.success('Xóa thành công')
                    $this.$emit('load-doi-don-vi')
                })
            })
        },
    }

}
</script>

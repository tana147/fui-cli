<template>
    <div class="pa-4">
        <div class="d-flex align-center mb-3">
            <div class="font-weight-bold">Tồn tối thiểu ({{ tableData.length }})</div>
            <v-spacer></v-spacer>
            <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="openDialog">
                Thêm tồn tối thiểu
            </v-btn>
        </div>
        <z-table :headers="tableHeader" :items="tableData" height="480px" :options="tableOptions" />
    </div>

    <v-dialog v-model="isShowDialogTonToiThieu" width="860">
        <v-card>
            <template v-slot:title>Thêm tồn tối thiểu</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>
            <v-card-text>
                <v-form ref="form">
                    <v-row>
                        <v-col cols="4">
                            <v-autocomplete v-model="item.DiaDiem_Id" :items="DSDiaDiem" item-title="TenDiaDiem"
                                item-value="DiaDiem_Id" label="Địa điểm" density="compact" hide-details="auto"
                                :rules="[rules.required]" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="item.SoLuongTonToiThieu" label="SL tồn tối thiểu" density="compact"
                                hide-details="auto" type="number" :rules="[rules.greaterThanZero]" />
                        </v-col>
                        <v-col cols="4">
                            <v-text-field v-model="item.GhiChu" label="Ghi chú" density="compact" hide-details="auto" />
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
        DSDiaDiem: Array,
        selectedItem: Object,
    },
    emits: ['load-ton-toi-thieu'],

    data() {
        return {
            rules: {
                required: v => v !== null && v !== undefined || 'Trường này không được để trống',
                greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
                noSpecialChar: v =>
                    /^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
            },

            isShowDialogTonToiThieu: false,

            tableHeader: [
                { title: '#', formatter: 'rownum', width: 70, hozAlign: 'center' },
                { title: 'Địa điểm', field: 'TenDiaDiem', headerSort: true, headerFilter: 'input' },
                { title: 'SL tồn tối thiểu', field: 'SoLuongTonToiThieu', headerSort: true, headerFilter: 'input', width: 150, hozAlign: 'right' },
                { title: 'Ghi chú', field: 'GhiChu', headerSort: true, headerFilter: 'input', width: 180 },
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
            this.isShowDialogTonToiThieu = false
            this.item = {}
        },
        openDialog() {
            this.isShowDialogTonToiThieu = true
        },
        async onSubmit() {
            const { valid } = await this.$refs.form.validate();
            if (!valid) {
                showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
                return
            }
            const params = [
                {
                    HangHoa_Id: this.selectedItem.HangHoa_Id,
                    DiaDiem_Id: this.item.DiaDiem_Id,
                    SoLuongTonToiThieu: this.item.SoLuongTonToiThieu,
                    GhiChu: this.item.GhiChu ? this.item.GhiChu.trim() : '',
                },
            ]
            const $this = this
            apiCall('/work/HH_HangHoa_TonToiThieu_Insert', { Data_JSON: JSON.stringify(params) }, () => {
                showToast.success('Thêm quy đổi thành công')
                $this.$emit('load-ton-toi-thieu')
            })

        },

        onDelete(item) {
            showConfirm(`Bạn chắc chắn muốn xóa tồn tối thiểu? `, () => {
                const params = {
                    HangHoa_DiaDiem_TonToiThieu_Id: item.HangHoa_DiaDiem_TonToiThieu_Id,
                }
                const $this = this
                apiCall('/work/HH_HangHoa_TonToiThieu_Delete', params, () => {
                    showToast.success('Xóa thành công')
                    $this.$emit('load-ton-toi-thieu')
                })
            })
        },
    }

}
</script>

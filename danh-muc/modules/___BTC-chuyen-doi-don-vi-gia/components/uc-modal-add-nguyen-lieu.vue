<template>
    <v-dialog v-model="modelValue" max-width="800">
        <v-card>
            <template v-slot:title>Thêm nguyên liệu quy đổi</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <v-row>
                    <v-col cols="6">
                        <uc-search-nguyen-lieu v-model:value="formData.HangHoa_Id" label="Nguyên liệu" />
                    </v-col>
                    <v-col cols="6">
                        <v-text-field v-model="formData.TenThayThe" label="Tên thay thế" :rules="[rules.required]" dense />
                    </v-col>

                    <v-col cols="12">
                        <v-data-table :items-per-page="-1" hide-default-footer dense :hover="true" :disable-sort="true" fixed-header :headers="tableHeader" :items="DsQuyDoi">
                            <template v-slot:item.DonViTinh_Id="{ item }">
                                <uc-select-don-vi v-model:value="item.DonViTinh_Id" isUnderlined placeholder="Đơn vị quy đổi" />
                            </template>
                            <template v-slot:item.HeSoQuyDoi="{ item }">
                                <v-text-field
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
                                <v-btn :disabled="DsQuyDoi.length === 1" icon="mdi-trash-can" variant="text" color="red" @click="onDelete(index)" />
                            </template>
                        </v-data-table>
                    </v-col>
                </v-row>

                <div class="d-flex justify-center align-center mt-3">
                    <v-btn color="primary" variant="text" @click="addRow" prepend-icon="mdi-plus">Thêm đơn vị quy đổi</v-btn>
                </div>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="warning" @click="onSaveAndClose" prepend-icon="mdi-content-save-outline" variant="flat" dark>Lưu & Đóng</v-btn>
                <v-btn color="primary" @click="onSave" prepend-icon="mdi-content-save-move" variant="flat">Lưu & Tiếp tục</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['modelValue'],
    emits: ['update:modelValue', 'onReload'],
    data() {
        return {
            formData: {
                HangHoa_Id: null,
                TenThayThe: '',
            },
            rules: {
                required: (value) => !!value || 'Trường này không được để trống',
            },

            isSaveAndClose: false,

            DsDonViTinh: [],
            DsNguyenLieu: [],

            tableHeader: [
                { title: 'STT', key: 'STT', sortable: false, align: 'center', width: 50 },
                { title: 'Đơn vị quy đổi', key: 'DonViTinh_Id', sortable: false },
                { title: 'Hệ số', key: 'HeSoQuyDoi', sortable: false, width: 100 },
                { title: 'Ghi chú', key: 'GhiChu', sortable: false },
                { title: 'Khóa', key: 'Is_TamKhoa', sortable: false, width: 70, align: 'center' },
                { title: '', key: 'Action', sortable: false, width: 50, align: 'center' },
            ],

            DsQuyDoi: [
                {
                    STT: 1,
                    DonViTinh_Id: null,
                    HeSoQuyDoi: null,
                    Is_TamKhoa: 0,
                    GhiChu: null,
                },
            ],
        }
    },
    mounted() {},
    computed: {},
    watch: {},
    methods: {
        addRow() {
            this.DsQuyDoi.push({ STT: this.DsQuyDoi.length + 1, DonViTinh_Id: null, HeSoQuyDoi: null, Is_TamKhoa: 0, GhiChu: null })
        },

        preventNegative(e) {
            // Chặn các ký tự '-', 'e', '+' và số âm
            if (e.key === '-' || e.key === 'e' || e.key === '+') {
                e.preventDefault()
            }
        },

        onDelete(index) {
            this.DsQuyDoi.splice(index, 1)
            this.DsQuyDoi = this.resetSTT(this.DsQuyDoi)
        },

        onClose() {
            this.isSaveAndClose = false
            this.$emit('update:modelValue', false)
        },

        onSave() {
            // Kiểm tra chọn nguyên liệu
            if (!this.formData.HangHoa_Id) {
                showToast.error('Vui lòng chọn nguyên liệu!')
                return
            }

            console.log('this.formData.HangHoa_Id', this.formData.HangHoa_Id)

            const arr = []

            this.DsQuyDoi.forEach((item) => {
                arr.push({
                    HangHoa_Id: this.formData.HangHoa_Id,
                    TenThayThe: this.formData.TenThayThe,
                    QuyDoi_DonViTinh_Id: item.DonViTinh_Id,
                    QuyDoi_HeSo: item.HeSoQuyDoi,
                    Is_TamKhoa: item.Is_TamKhoa ? 1 : 0,
                    GhiChu: item.GhiChu,
                })
            })
            console.log('arr', arr)

            arr.forEach((item) => {
                if (!item.QuyDoi_DonViTinh_Id) {
                    showToast.error('Vui lòng chọn đơn vị quy đổi ở dòng ' + (arr.indexOf(item) + 1) + '!')
                    return
                }

                if (!item.QuyDoi_HeSo || item.QuyDoi_HeSo <= 0) {
                    showToast.error('Hệ số quy đổi phải lớn hơn 0 ở dòng ' + (arr.indexOf(item) + 1) + '!')
                    return
                }
            })
            apiCall(
                '/work/HH_HangHoaQuyDoi_Insert',
                {
                    Data_JSON: JSON.stringify(arr),
                },
                () => {
                    this.$emit('onReload')
                    this.resetData()
                    showToast.success('Thêm nguyên liệu quy đổi thành công!')

                    if (this.isSaveAndClose) {
                        this.onClose()
                    }
                },
                (error) => {
                    showToast.error(`${error.responseJSON.Message}`, {
                        position: 'top',
                    })
                },
            )
        },

        onSaveAndClose() {
            this.isSaveAndClose = true
            this.onSave()
        },

        resetSTT(arr) {
            return arr.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })
        },

        resetData() {
            this.formData.HangHoa_Id = null
            this.formData.TenThayThe = ''
            this.DsQuyDoi = [
                {
                    STT: 1,
                    DonViTinh_Id: null,
                    HeSoQuyDoi: null,
                    Is_TamKhoa: 0,
                    GhiChu: null,
                },
            ]
        },
    },
}
</script>

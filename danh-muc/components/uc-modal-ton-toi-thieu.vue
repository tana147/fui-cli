<template>
    <v-dialog v-model="modelValue" max-width="1000">
        <v-card>
            <template v-slot:title>Tồn kho tối thiểu • {{ record?.TenHangHoa }}</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <div v-if="isOpenAdd" class="mb-3">
                    <v-row>
                        <v-col cols="12">
                            <v-data-table :items="DsAddTonToiThieu" ref="addTable" :items-per-page="-1" hide-default-footer dense :hover="true" :disable-sort="true" fixed-header :headers="AddHeader">
                                <template v-slot:top>
                                    <v-toolbar flat>
                                        <v-toolbar-title> Thêm mới tồn tối thiểu </v-toolbar-title>
                                    </v-toolbar>
                                </template>

                                <template v-slot:item.ThuTu="{ item, index }">
                                    {{ index + 1 }}
                                </template>

                                <template v-slot:item.DiaDiem_Id="{ item }">
                                    <v-autocomplete
                                        v-model="item.DiaDiem_Id"
                                        :items="DsDiaDiem"
                                        item-title="TenDiaDiem"
                                        item-value="DiaDiem_Id"
                                        variant="underlined"
                                        placeholder="Chọn địa điểm"
                                        dense
                                        density="compact"
                                        hide-details
                                        outlined
                                    />
                                </template>

                                <template v-slot:item.SoLuongTonToiThieu="{ item }">
                                    <v-text-field
                                        class="text-right-input"
                                        v-model="item.SoLuongTonToiThieu"
                                        variant="underlined"
                                        placeholder="Số lượng tồn tối thiểu"
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

                                <template v-slot:item.Action="{ item, index }">
                                    <v-btn :disabled="DsAddTonToiThieu.length === 1" icon="mdi-trash-can" variant="text" color="red" @click="onDeleteRow(index)" />
                                </template>
                            </v-data-table>
                        </v-col>
                    </v-row>

                    <div class="d-flex justify-center align-center mt-3">
                        <v-btn color="primary" variant="text" @click="addRow" prepend-icon="mdi-plus">Thêm tồn tối thiểu</v-btn>
                    </div>
                </div>

                <v-data-table v-show="!isOpenAdd" :items="DsTonToiThieu" :headers="tableHeader" :items-per-page="-1" hide-default-footer dense density="compact">
                    <template v-slot:top>
                        <v-toolbar flat>
                            <v-toolbar-title>Danh sách địa điểm</v-toolbar-title>
                            <v-spacer />
                            <v-btn icon="mdi-plus" size="32" variant="outlined" color="primary" @click="onOpenAdd" />
                        </v-toolbar>
                    </template>

                    <template v-slot:item.ThuTu="{ item, index }">
                        {{ index + 1 }}
                    </template>

                    <template v-slot:item.DiaDiem_Id="{ item }">
                        <p v-if="!item.Is_Update">
                            {{ item.TenDiaDiem }}
                        </p>
                        <v-autocomplete
                            v-else
                            v-model="item.DiaDiem_Id_Update"
                            :items="DsDiaDiem"
                            item-title="TenDiaDiem"
                            item-value="DiaDiem_Id"
                            variant="underlined"
                            placeholder="Chọn địa điểm"
                            dense
                            density="compact"
                            hide-details
                            outlined
                        />
                    </template>

                    <template v-slot:item.HangHoa_DiaDiem_TonToiThieu_Id="{ item }">
                        <p v-if="!item.Is_Update">
                            {{ item.SoLuongTonToiThieu }}
                        </p>
                        <v-text-field v-else v-model="item.SoLuongTonToiThieu_Update" variant="underlined" density="compact" hide-details class="text-right-input" @keydown="preventNegative" />
                    </template>

                    <template v-slot:item.GhiChu="{ item }">
                        <p v-if="!item.Is_Update">
                            {{ item.GhiChu }}
                        </p>
                        <v-textarea v-else v-model="item.GhiChu_Update" variant="underlined" placeholder="Ghi chú" dense rows="1" auto-grow />
                    </template>

                    <template v-slot:item.Action="{ item }">
                        <v-menu v-if="!item.Is_Update">
                            <template #activator="{ props }">
                                <v-btn size="small" variant="text" icon="mdi-dots-vertical" v-bind="props" />
                            </template>
                            <v-list density="compact">
                                <v-list-item @click="openEdit(item)" prepend-icon="mdi-square-edit-outline" title="Cập nhật" />
                                <v-divider />
                                <v-list-item @click="onDelete(item, index)" prepend-icon="mdi-trash-can" title="Xóa" />
                            </v-list>
                        </v-menu>

                        <div v-else class="d-flex justify-center">
                            <v-btn class="mr-2" variant="flat" size="small" @click="onCancel(item)"> Hủy </v-btn>
                            <v-btn size="small" variant="flat" color="primary" @click="onSave(item)"> Lưu </v-btn>
                        </div>
                    </template>
                </v-data-table>
            </v-card-text>

            <!-- Group button Add Quy đổi mới -->
            <v-card-actions v-if="isOpenAdd" class="pb-0 mb-0">
                <v-spacer></v-spacer>
                <v-btn @click="onCloseAdd" dense hide-details variant="flat" dark>Đóng</v-btn>
                <v-btn color="primary" hide-details @click="onAdd" prepend-icon="mdi-content-save-outline" variant="flat" dark>Lưu</v-btn>
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
            isUpdateState: false,

            DsTonToiThieu: [],
            DsDiaDiem: [],
            DsAddTonToiThieu: [
                {
                    ThuTu: 1,
                    DiaDiem_Id: null,
                    SoLuongTonToiThieu: null,
                    GhiChu: null,
                },
            ],

            tableHeader: [
                { title: '#', key: 'ThuTu', sortable: false, align: 'center', width: 50 },
                { title: 'Địa điểm', key: 'DiaDiem_Id', sortable: false, width: 180 },
                { title: 'SL tồn tối thiểu', value: 'HangHoa_DiaDiem_TonToiThieu_Id', width: 140, align: 'center' },
                { title: 'Ghi chú', value: 'GhiChu', width: 220 },
                { title: '', value: 'Action', width: 50, align: 'center' },
            ],

            AddHeader: [
                { title: '#', key: 'ThuTu', sortable: false, align: 'center', width: 50 },
                { title: 'Địa điểm', key: 'DiaDiem_Id', sortable: false, width: 180 },
                { title: 'SL tồn tối thiểu', value: 'SoLuongTonToiThieu', width: 140, align: 'center' },
                { title: 'Ghi chú', value: 'GhiChu', width: 220 },
                { title: '', value: 'Action', width: 50, align: 'center' },
            ],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        modelValue(val) {
            if (val) {
                this.onLoadDiaDiem()
                this.onLoadTonToiThieu()
            }
        },
    },
    methods: {
        onLoadDiaDiem() {
            apiCall('work/HH_DiaDiem_Select', null, (res) => {
                this.DsDiaDiem = res.data
            })
        },

        onOpenAdd() {
            this.isOpenAdd = true
        },

        onCloseAdd() {
            this.resetData()
            this.isOpenAdd = false
        },

        onAdd() {
            const arr = this.DsAddTonToiThieu.map((item) => ({
                HangHoa_Id: this.record.HangHoa_Id,
                DiaDiem_Id: item.DiaDiem_Id,
                SoLuongTonToiThieu: item.SoLuongTonToiThieu ? item.SoLuongTonToiThieu.trim() : item.SoLuongTonToiThieu,
                GhiChu: item.GhiChu ? item.GhiChu.trim() : item.GhiChu,
            }))

            const hasError = arr.some((item, index) => {
                if (!item.DiaDiem_Id) {
                    showToast.error(`Vui lòng chọn địa điểm ở dòng ${index + 1}!`)
                    return true
                }

                if (!item.SoLuongTonToiThieu || parseInt(item.SoLuongTonToiThieu) <= 0) {
                    showToast.error(`Số lượng tồn tối thiểu phải lớn hơn 0 ở dòng ${index + 1}!`)
                    return true
                }

                return false
            })

            if (hasError) return

            console.log('arr', arr)

            try {
                apiCall(
                    '/work/HH_HangHoa_TonToiThieu_Insert',
                    {
                        Data_JSON: JSON.stringify(arr),
                    },
                    () => {
                        this.onLoadTonToiThieu()
                        this.$emit('onReload')
                        this.resetData()
                        showToast.success('Thêm tồn tối thiểu thành công!')

                        this.isOpenAdd = false
                    },
                    (error) => {
                        showToast.error(`${error.responseJSON.Message}`, {
                            position: 'top',
                        })
                    },
                )
            } catch (err) {
                showToast.error('Lỗi thêm mới!')
                console.log('error', err)
            }
        },

        addRow() {
            this.DsAddTonToiThieu.push({
                ThuTu: this.DsAddTonToiThieu.length + 1,
                DiaDiem_Id: null,
                SoLuongTonToiThieu: null,
                GhiChu: null,
            })
        },

        onDeleteRow(index) {
            this.DsAddTonToiThieu.splice(index, 1)
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
            showConfirm(`Bạn muốn xóa tồn tối thiểu tại địa điểm "${item.TenDiaDiem}"?`, () => {
                this.DsTonToiThieu.splice(index, 1)

                apiCall(
                    'work/HH_HangHoa_TonToiThieu_Delete',
                    {
                        HangHoa_DiaDiem_TonToiThieu_Id: item.HangHoa_DiaDiem_TonToiThieu_Id,
                    },
                    () => {
                        showToast.success('Xóa thành công')
                        this.onLoadTonToiThieu()
                        this.$emit('onReload')
                    },
                )
            })
        },

        onSave(item) {
            const $this = this

            // Kiểm tra đơn vị tính
            if (!item.DiaDiem_Id_Update) {
                showToast.error('Vui lòng chọn địa điểm', {
                    position: 'top',
                })
                return
            }

            // Kiểm tra không được nhập 0 hệ số
            if (!item.SoLuongTonToiThieu_Update || item.SoLuongTonToiThieu_Update == 0) {
                showToast.error('Vui lòng sô lượng lớn hơn 0', {
                    position: 'top',
                })
                return
            }

            console.log('item', item)

            try {
                apiCall(
                    'work/HH_HangHoa_TonToiThieu_Update',
                    {
                        HangHoa_DiaDiem_TonToiThieu_Id: item.HangHoa_DiaDiem_TonToiThieu_Id,
                        HangHoa_Id: item.HangHoa_Id,
                        DiaDiem_Id: item.DiaDiem_Id_Update,
                        SoLuongTonToiThieu: item.SoLuongTonToiThieu_Update ? item.SoLuongTonToiThieu_Update.toString().trim() : item.SoLuongTonToiThieu_Update,
                        GhiChu: item.GhiChu_Update ? item.GhiChu_Update.trim() : item.GhiChu_Update,
                    },
                    () => {
                        $this.onLoadTonToiThieu()
                        item.Is_Update = false
                        this.isUpdateState = false
                        showToast.success('Cập nhật thành công!')
                    },
                )
            } catch (err) {
                showToast.error('Lỗi cập nhật!')
                console.log('error', err)
            }
        },

        onCancel(item) {
            item.DiaDiem_Id_Update = item.DiaDiem_Id
            item.SoLuongTonToiThieu_Update = item.HangHoa_DiaDiem_TonToiThieu_Id
            item.GhiChu_Update = item.GhiChu

            item.Is_Update = false
            this.isUpdateState = false
        },

        onLoadTonToiThieu() {
            const $this = this
            apiCall(
                'work/HH_HangHoa_TonToiThieu_Select',
                {
                    HangHoa_Id: $this.record.HangHoa_Id,
                },
                (res) => {
                    this.DsTonToiThieu = res.data.map((item) => {
                        return {
                            ...item,
                            Is_Update: false,
                            DiaDiem_Id_Update: item.DiaDiem_Id,
                            SoLuongTonToiThieu_Update: item.SoLuongTonToiThieu,
                            GhiChu_Update: item.GhiChu,
                        }
                    })
                    console.log('this.DsTonToiThieu', this.DsTonToiThieu)
                },
            )
        },

        resetData() {
            this.DsAddTonToiThieu = [
                {
                    ThuTu: 1,
                    DiaDiem_Id: null,
                    SoLuongTonToiThieu: null,
                    GhiChu: null,
                },
            ]
        },

        onClose() {
            this.isOpenAdd = false
            this.isUpdateState = false
            this.resetData()
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

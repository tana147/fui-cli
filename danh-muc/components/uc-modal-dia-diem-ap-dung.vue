<template>
    <v-dialog v-model="modelValue" max-width="500">
        <v-card>
            <template v-slot:title>Địa điểm áp dụng</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <div class="search-dia-diem">
                    <v-text-field v-model="search" label="Tìm kiếm" prepend-inner-icon="mdi-magnify" variant="outlined" density="compact" />
                </div>

                <v-data-table
                    class="height-wrap"
                    v-model="DsSelectDiaDiem"
                    :headers="tableHeader"
                    :items="filteredItems"
                    item-value="DiaDiem_Id"
                    density="compact"
                    fixed-header
                    style="height: calc(100vh - 48px)"
                    :items-per-page="-1"
                    hide-default-footer
                    show-select
                >
                    <template v-slot:item.ThuTu="{ item, index }">
                        {{ index + 1 }}
                    </template>

                    <template v-slot:item.DiaDiem_Id="{ item }">
                        {{ item.TenDiaDiem }}
                    </template>
                </v-data-table>
            </v-card-text>

            <v-card-actions class="pb-0 mb-0">
                <v-spacer></v-spacer>
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
            search: '',

            DsSelectDiaDiem: [],
            DsDiaDiem: [],

            tableHeader: [
                { title: '#', key: 'ThuTu', sortable: false, align: 'center', width: 30 },
                { title: 'Địa điểm', key: 'DiaDiem_Id', sortable: false },
            ],
        }
    },
    mounted() {},
    computed: {
        filteredItems() {
            if (!this.search) return this.DsDiaDiem

            return this.DsDiaDiem.filter((item) => item.TenDiaDiem.toLowerCase().includes(this.search.toLowerCase()))
        },
    },
    watch: {
        async modelValue(val) {
            if (val) {
                await this.onLoadDiaDiem()
                await this.onLoadDsSelectDiaDiem()
            }
        },
    },
    methods: {
        onLoadDiaDiem() {
            return new Promise((resolve) => {
                apiCall('work/HH_DiaDiem_Select', null, (res) => {
                    this.DsDiaDiem = res.data
                    resolve()
                })
            })
        },

        onLoadDsSelectDiaDiem() {
            return new Promise((resolve) => {
                apiCall(
                    '/work/HH_HangHoa_DiaDiem_Select',
                    {
                        HangHoa_Id: this.record.HangHoa_Id,
                    },
                    (res) => {
                        const result = res.data
                        this.DsSelectDiaDiem = result.length > 0 ? result.map((item) => item.DiaDiem_Id) : []
                        resolve()
                    },
                )
            })
        },

        onAdd() {
            try {
                const joinStr = this.DsSelectDiaDiem.length > 0 ? this.DsSelectDiaDiem.join(',') : ''
                apiCall(
                    '/work/HH_HangHoa_DiaDiem_Update',
                    {
                        HangHoa_Id: this.record.HangHoa_Id,
                        DSDiaDiem: joinStr,
                    },
                    async () => {
                        this.$emit('onReload')
                        showToast.success('Thêm địa điểm áp dụng thành công!')
                        await this.onLoadDsSelectDiaDiem()
                        this.onClose()
                    },
                )
            } catch (err) {
                showToast.error('Lỗi thêm mới!')
                console.log('error', err)
            }
        },

        preventNegative(e) {
            // Chặn các ký tự '-', 'e', '+' và số âm
            if (e.key === '-' || e.key === 'e' || e.key === '+') {
                e.preventDefault()
            }
        },

        resetData() {
            this.search = ''
        },

        onClose() {
            this.resetData()
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

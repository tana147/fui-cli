<template>
    <v-dialog v-model="modelValue" fullscreen>
        <v-card>
            <template v-slot:title>Thêm mới sản phẩm</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <v-row dense>
                    <v-col cols="4">
                        <uc-search-nguyen-lieu v-model:value="formData.NguyenLieu_Id" label="Sản phẩm" loaiNguyenLieu="TP" />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field label="Mã sản phẩm" disabled />
                    </v-col>
                    <v-col cols="4">
                        <v-text-field label="Tên tên phẩm" disabled />
                    </v-col>

                    <v-col cols="3">
                        <v-text-field v-model="formData.Gia" label="Giá" @input="(e) => formatNumberField('Gia', e)" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field label="Tỉ lệ so với chi phí" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field label="Đơn vị" />
                    </v-col>
                    <v-col cols="3">
                        <v-date-input hide-actions label="Hạn sử dụng" clearable prepend-icon="" show-adjacent-months />
                    </v-col>

                    <v-col cols="3">
                        <v-text-field label="Cách thức bảo quản" />
                    </v-col>
                    <v-col cols="3">
                        <v-text-field label="Thiết bị bảo quản" />
                    </v-col>
                    <v-col cols="3">
                        <v-select label="Phân loại sản phẩm" :items="items" item-title="title" item-value="value">
                            <template #item="{ props, item }">
                                <v-list-subheader v-if="item.raw.type === 'subheader'">
                                    {{ item.raw.title }}
                                </v-list-subheader>

                                <v-list-item v-else v-bind="props" />
                            </template>
                        </v-select>
                    </v-col>
                    <v-col cols="3">
                        <v-select label="Trạng thái" :items="DsPhanLoai" item-title="title" item-value="value" />
                    </v-col>
                </v-row>

                <v-divider></v-divider>
                <div class="mt-3 mb-3">
                    <v-card>
                        <template #title>
                            <div class="d-flex align-center">
                                <span>Thành phần của sản phẩm ({{ filterItem.length }})</span>
                                <v-spacer></v-spacer>

                                <div class="searchBar">
                                    <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Search" density="compact" single-line hide-details />
                                </div>
                            </div>
                        </template>

                        <v-data-table
                            :items-per-page="-1"
                            hide-default-footer
                            dense
                            :hover="true"
                            :disable-sort="true"
                            fixed-header
                            :headers="TableHeader"
                            :items="filterItem"
                            item-value="NguyenVatLieu_ID"
                        >
                            <template v-slot:item.NguyenVatLieu_ID="{ item }">
                                <v-select
                                    v-model="item.NguyenVatLieu_ID"
                                    :items="['Sữa', 'Trà', 'Đá', 'Túi giấy']"
                                    @update:modelValue="(value) => onSelectChange(value, item)"
                                    placeholder="Nguyên vật liệu"
                                    variant="underlined"
                                    density="compact"
                                    required
                                />
                            </template>
                            <!-- <template v-slot:item.DonVi="{ item }">
                                <v-text-field placeholder="Đơn vị" required />
                            </template> -->
                            <template v-slot:item.SoLuong="{ item }">
                                <v-text-field v-model="item.SoLuong" variant="underlined" density="compact" placeholder="Số lượng" required @input="(e) => calculatePriceFromSoLuong(e, item)" />
                            </template>
                            <template v-slot:item.GiaNVL="{ item }">
                                <!-- <v-text-field
                                    v-model="item.GiaNguyenVatLieu"
                                    placeholder="Giá"
                                    required
                                    variant="underlined"
                                    density="compact"
                                    @input="(e) => [formatNumberField('GiaNguyenVatLieu', e, item), calculatePriceFromGiaNVL(e, item)]"
                                /> -->
                            </template>
                            <template v-slot:item.ChiPhiNguyenLieu="{ item }">
                                {{ formatPrice(item.ChiPhiNguyenLieu) }}
                                <!-- <v-text-field v-model="item.ChiPhiNguyenLieu" placeholder="Chi phí nguyên liệu" required @input="(e) => formatNumberField('ChiPhiNguyenLieu', e, item)" /> -->
                            </template>
                            <template v-slot:item.Action="{ item, index }">
                                <v-btn color="error" @click="onDelete(index)" variant="text"><v-icon icon="mdi-trash-can" /></v-btn>
                            </template>
                        </v-data-table>
                    </v-card>
                </div>

                <div class="d-flex justify-end">
                    <i>
                        <b class="text-error">Tổng chi phí nguyên liệu: {{ formatPrice(totalPrice) }}đ</b>
                    </i>
                </div>

                <div class="d-flex align-center justify-center">
                    <v-btn color="primary" rounded="xl" @click="onAddNguyenVatLieu" prepend-icon="mdi-plus" variant="text">Thêm nguyên vật liệu</v-btn>
                </div>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="onAdd" prepend-icon="mdi-content-save-outline" variant="flat">Lưu</v-btn>
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
                Gia: null,
                NguyenLieu_Id: null,
            },

            search: '',
            totalPrice: 0,

            items: [
                { type: 'subheader', title: 'Nơi sản xuất' },
                { title: 'Bakery', value: 'bakery' },
                { title: 'Phòng bánh', value: 'phongbanh' },

                { type: 'subheader', title: 'Nơi sử dụng' },
                { title: 'Zen Tea', value: 'zentea' },
                { title: 'Bakery 41', value: 'bakery41' },
            ],
            DsPhanLoai: [
                { title: 'Đang bán', value: 'Đang bán' },
                { title: 'Đang test mới', value: 'Đang test mới' },
                { title: 'Đang cập nhật', value: 'Đang cập nhật' },
            ],
            DsPhanLoaiNguyenVatLieu: [
                { title: 'Nguyên liệu', value: 'Nguyên liệu' },
                { title: 'Bao bì, giấy', value: 'Bao bì, giấy' },
                { title: 'Gia vị', value: 'Gia vị' },
            ],
            TableHeader: [
                { title: 'STT', key: 'STT', sortable: false, align: 'center', width: '50px' },
                { title: 'Nguyên vật liệu', key: 'NguyenVatLieu_ID', sortable: false, width: '500px' },
                { title: 'Số lượng sử dụng', key: 'SoLuong', sortable: false, width: '150px' },
                { title: 'Giá nguyên vật liệu', key: 'GiaNVL', sortable: false, width: '180px' },
                { title: 'Đơn vị sử dụng', key: 'DonVi', sortable: false, width: '140px', align: 'center' },
                { title: 'Chi phí nguyên liệu', key: 'ChiPhiNguyenLieu', sortable: false, align: 'end', width: '160px' },
                { title: 'Phân loại', key: 'PhanLoai_ID', sortable: false },
                { title: '', key: 'Action', sortable: false, width: '50px' },
            ],
            DsNguyenVatLieuSelect: [
                {
                    STT: 1,
                    NguyenVatLieu_ID: null,
                    MaNguyenVatLieu: '',
                    TenNguyenVatLieu: '',
                    DonVi: 'Gr',
                    SoLuong: 1,
                    GiaNguyenVatLieu: '',
                    ChiPhiNguyenLieu: '0',
                    PhanLoai_ID: '',
                },
                {
                    STT: 2,
                    NguyenVatLieu_ID: null,
                    MaNguyenVatLieu: '',
                    TenNguyenVatLieu: '',
                    DonVi: 'Gr',
                    SoLuong: 1,
                    GiaNguyenVatLieu: '',
                    ChiPhiNguyenLieu: '0',
                    PhanLoai_ID: '',
                },
                {
                    STT: 3,
                    NguyenVatLieu_ID: null,
                    MaNguyenVatLieu: '',
                    TenNguyenVatLieu: '',
                    DonVi: 'Gr',
                    SoLuong: 1,
                    GiaNguyenVatLieu: '',
                    ChiPhiNguyenLieu: '0',
                    PhanLoai_ID: '',
                },
            ],
        }
    },
    mounted() {},
    computed: {
        filterItem() {
            const key = this.search.trim().toLowerCase()

            return this.DsNguyenVatLieuSelect.filter((item) => {
                return (item.TenNguyenVatLieu || '').toLowerCase().includes(key)
            })
        },
    },
    watch: {},
    methods: {
        calculateTotal() {
            this.totalPrice = this.DsNguyenVatLieuSelect.reduce((sum, item) => {
                // lọc số: bỏ dấu . hoặc mọi ký tự không phải số
                const value = parseInt(item.ChiPhiNguyenLieu.toString().replace(/\D/g, '')) || 0
                return sum + value
            }, 0)
        },

        calculatePriceFromGiaNVL(e, item) {
            // Loại bỏ các ký tự không phải number
            const numberParse = parseInt(e.target.value.replace(/\D/g, ''))
            const numberSoLuongParse = parseInt(item.SoLuong.toString().replace(/\D/g, ''))
            item.ChiPhiNguyenLieu = isNaN(numberParse * numberSoLuongParse) ? 0 : numberParse * numberSoLuongParse
            this.calculateTotal()
        },

        calculatePriceFromSoLuong(e, item) {
            // Loại bỏ các ký tự không phải number
            const numberParse = parseInt(e.target.value.replace(/\D/g, ''))
            const numberGiaNVLParse = parseInt(item.GiaNguyenVatLieu.replace(/\D/g, ''))
            item.ChiPhiNguyenLieu = isNaN(numberParse * numberGiaNVLParse) ? 0 : numberParse * numberGiaNVLParse
            this.calculateTotal()
        },

        onSelectChange(value, item) {
            console.log('item', item)
            console.log('Giá trị mới:', value)
            item.TenNguyenVatLieu = value
        },

        resetSTT(arr) {
            return arr.map((item, index) => {
                return {
                    ...item,
                    STT: index + 1,
                }
            })
        },

        formatNumberField(fieldName, e, item = null) {
            const val = e.target.value
            item === null ? (this.formData[fieldName] = this.formatPrice(val)) : (item[fieldName] = this.formatPrice(val))
        },

        // Hàm format số
        formatPrice(price) {
            if (!price) return '0'
            price = String(price)

            // loại ký tự không phải số
            let num = price.replace(/\D/g, '')

            // thêm dấu chấm mỗi 3 số
            return num.replace(/\B(?=(\d{3})+(?!\d))/g, '.')
        },

        onAdd() {
            this.$emit('onReload')
        },

        onDelete(index) {
            this.DsNguyenVatLieuSelect.splice(index, 1)
            this.DsNguyenVatLieuSelect = this.resetSTT(this.DsNguyenVatLieuSelect)
        },

        onAddNguyenVatLieu() {
            this.DsNguyenVatLieuSelect.push({
                STT: this.DsNguyenVatLieuSelect.length + 1,
                NguyenVatLieu_ID: null,
                MaNguyenVatLieu: '',
                TenNguyenVatLieu: '',
                DonVi: '',
                SoLuong: 0,
                GiaNguyenVatLieu: '',
                ChiPhiNguyenLieu: '0',
                PhanLoai_ID: '',
            })
        },

        onClose: function () {
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

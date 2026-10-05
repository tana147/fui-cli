<template>
    <v-dialog v-model="modelValue" max-width="1500">
        <v-card>
            <template v-slot:title>Chi tiết thành phần sản phẩm ({{ filterItem.length }})</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>

            <v-card-text>
                <v-card>
                    <template #title>
                        <div class="d-flex align-center">
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
                    />
                </v-card>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['modelValue', 'detailSanPham'],
    emits: ['update:modelValue'],
    data() {
        return {
            search: '',

            TableHeader: [
                { title: 'STT', key: 'STT', sortable: false, align: 'center', width: '50px' },
                { title: 'Mã nguyên vật liệu', key: 'MaNguyenVatLieu', sortable: false },
                { title: 'Tên nguyên vật liệu', key: 'TenNguyenVatLieu', sortable: false },
                { title: 'Đơn vị sử dụng', key: 'DonVi', sortable: false },
                { title: 'Số lượng sử dụng', key: 'SoLuong', sortable: false },
                { title: 'Chi phí nguyên liệu/1 đơn vị sử dụng', key: 'ChiPhiNguyenLieu', sortable: false },
                { title: 'Tổng chi phí nguyên liệu/sản phẩm', key: 'TongChiPhi', sortable: false },
                { title: 'Phân loại', key: 'PhanLoai', sortable: false, },
                { title: '', key: 'Action', sortable: false, width: '50px' },
            ],
            DsNguyenVatLieuSelect: [
                {
                    STT: 1,
                    MaNguyenVatLieu: 'NVL01',
                    TenNguyenVatLieu: 'Sữa',
                    DonVi: 'Hộp',
                    SoLuong: '1',
                    ChiPhiNguyenLieu: '25.000',
                    TongChiPhi: '25.000',
                    PhanLoai: 'Thức uống',
                },
                {
                    STT: 2,
                    MaNguyenVatLieu: 'NVL02',
                    TenNguyenVatLieu: 'Hồng trà',
                    DonVi: 'Hộp',
                    SoLuong: '1',
                    ChiPhiNguyenLieu: '30.000',
                    TongChiPhi: '30.000',
                    PhanLoai: 'Đồ thô',
                },
                {
                    STT: 3,
                    NguyenVatLieu_ID: null,
                    MaNguyenVatLieu: 'NVL03',
                    TenNguyenVatLieu: 'Trân châu',
                    DonVi: 'Phần',
                    SoLuong: '1',
                    ChiPhiNguyenLieu: '20.000',
                    TongChiPhi: '20.000',
                    PhanLoai: 'Topping',
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
        onClose: function () {
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

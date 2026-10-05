<template>
    <z-layout>
        <!-- Header + Title -->
        <v-app-bar density="compact" :elevation="0" title="Chuyển đổi đơn vị, giá" class="border-b"> </v-app-bar>

        <!-- <uc-select-nguyen-lieu v-model:value="selectedData" placeholder="Chọn nguyên liệu" isUnderlined /> -->

        <!-- Chức năng tìm kiếm, xuất excel và tên bảng -->
        <v-toolbar density="comfortable" style="flex-wrap: nowrap; overflow-x: auto">
            <v-toolbar-title class="text-primary text-subtitle-1">
                <span v-if="$vuetify.display.smAndDown"> SL: {{ filteredDsNguyenLieuQuyDoi.length }} </span>
                <span v-else class="d-flex align-center">
                    <b>
                        Danh sách quy đổi
                        <v-chip size="small" variant="tonal" color="primary" class="ml-1"> SL: {{ filteredDsNguyenLieuQuyDoi.length }} </v-chip>
                    </b>
                </span>
            </v-toolbar-title>

            <!-- Badge góc phải -->
            <v-btn color="green" variant="text" @click="xuatDanhSachBangCT">
                <v-icon :size="24">mdi-microsoft-excel</v-icon>
            </v-btn>

            <v-chip-group v-model="searchStatus" mandatory class="mr-3">
                <v-chip filter size="small" color="primary" value="all">Tất cả</v-chip>
                <v-chip filter size="small" color="success" value="true">Khả dụng</v-chip>
                <v-chip filter size="small" color="error" value="false">Tạm khóa</v-chip>
            </v-chip-group>

            <v-text-field
                v-model="search"
                label="Tìm kiếm"
                prepend-inner-icon="mdi-magnify"
                density="compact"
                variant="underlined"
                color="primary"
                class="mr-2"
                :style="$vuetify.display.smAndDown ? 'width: 100px' : 'max-width: 350px'"
            />

            <v-btn icon="mdi-plus" size="32" variant="outlined" class="mr-2" color="primary" @click="openCreate"> </v-btn>
        </v-toolbar>
        <v-divider></v-divider>

        <!-- Bảng thông tin các công thức -->
        <v-data-table
            v-model:items-per-page="itemsPerPage"
            :headers="headers"
            :items="filteredDsNguyenLieuQuyDoi"
            :items-length="totalRow"
            item-value="NhanVien_Id"
            :hover="true"
            :disable-sort="true"
            density="compact"
            fixed-header
            height="calc(100vh - 170px)"
            items-per-page-text="Bản ghi"
            :items-per-page-options="[50, 100, 150, 200]"
            no-data-text="Không tìm thấy dữ liệu"
        >
            <template v-slot:item.TenNguyenLieu="{ item }">
                <span @click="openEdit(item)" class="font-weight-bold text-primary cursor-pointer back-link-hover">
                    {{ item.TenNguyenLieu }}
                </span>
            </template>

            <template v-slot:item.Is_TamKhoa="{ item }">
                <v-icon :color="getStatusColor(item.Is_TamKhoa)">{{ getStatusIcon(item.Is_TamKhoa) }}</v-icon>
            </template>

            <template v-slot:item.action="{ item }">
                <v-menu>
                    <template v-slot:activator="{ props }">
                        <v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
                    </template>
                    <v-list density="compact">
                        <v-list-item @click="openEdit(item)" prepend-icon="mdi-square-edit-outline" title="Cập nhật"> </v-list-item>
                        <v-divider />
                        <v-list-item @click="onDelete(item)" prepend-icon="mdi-trash-can" title="Xóa" class="text-red"></v-list-item>
                    </v-list>
                </v-menu>
            </template>
        </v-data-table>

        <!-- Modals -->
        <uc-modal-add-nguyen-lieu v-model="isShowModalAdd" @onReload="reloadData" :lockItems="lockItems" />
        <uc-modal-update-nguyen-lieu v-model="isShowModalEdit" @onReload="reloadData" :detailRecord="detailRecord" :lockItems="lockItems" />
    </z-layout>
</template>

<script>
export default {
    props: {
        label: {
            type: String,
            default: '',
        },
        action: {
            type: Object,
            default: () => ({}),
        },
    },
    data() {
        return {
            vueData,
            itemsPerPage: 50,
            totalRow: 0,
            selectedData: null,

            searchStatus: 'all',
            headers: [
                { title: '#', value: 'STT', width: 50, align: 'center' },
                { title: 'Tên nguyên liệu', value: 'TenHangHoa', width: 180 },
                { title: 'Tên thay thế', value: 'TenThayThe', width: 180 },
                { title: 'Đơn vị nhập', value: 'NguyenLieu_DonViTinh_Ten', width: 150, align: 'center' },
                { title: 'Đơn giá áp dụng', value: 'DonGia_ApDung', align: 'center' },
                { title: 'Quy đổi hệ số', value: 'QuyDoi_HeSo', width: 150, align: 'center' },
                { title: 'Đơn vị tính', value: 'QuyDoi_DonViTinh_Ten', width: 100, align: 'center' },
                { title: 'Ghi chú', value: 'GhiChu', minWidth: 150 },
                { title: 'Tạm khóa', value: 'Is_TamKhoa', sortable: false, width: 100, align: 'center' },
                { title: '', value: 'action', sortable: false, width: 80, align: 'center' },
            ],

            lockItems: [
                {
                    text: 'Khả dụng',
                    value: 0,
                    icon: 'mdi-lock-open-variant',
                    color: 'green',
                },
                {
                    text: 'Tạm khóa',
                    value: 1,
                    icon: 'mdi-lock',
                    color: 'red',
                },
            ],

            DsNguyenLieuQuyDoi: [],

            search: '',

            isShowModalAdd: false,
            isShowModalEdit: false,
            isShowImportDialog: false,
            detailRecord: {},
        }
    },

    mounted() {
        this.onLoadNguyenLieuQuyDoi()
    },

    watch: {
        selectedData: {
            handler(val) {
                console.log('selectedData', val)
            },
            deep: true,
        },
    },

    computed: {
        filteredDsNguyenLieuQuyDoi() {
            const keyword = (this.search || '').toLowerCase()

            const filteredList = this.DsNguyenLieuQuyDoi.filter((r) => {
                const matchSearch = !keyword || r.TenThayThe.toLowerCase().includes(keyword) || String(r.QuyDoi_HeSo).toLowerCase().includes(keyword)

                let matchStatus = true
                if (this.searchStatus === 'true') {
                    matchStatus = r.Is_TamKhoa === false // Khả dụng
                } else if (this.searchStatus === 'false') {
                    matchStatus = r.Is_TamKhoa === true // Tạm khóa
                } else {
                    matchStatus = 'all'
                }

                return matchSearch && matchStatus
            })

            return this.resetSTT(filteredList)
        },
    },

    methods: {

        onLoadNguyenLieuQuyDoi() {
            apiCall(
                '/work/HH_HangHoaQuyDoi_Select',
                {
                    TimKiem: '',
                    QuyDoi_DonViTinh_Id: 0,
                    PageIndex: 1,
                    PageSize: 50,
                },
                (res) => {
                    this.DsNguyenLieuQuyDoi = res.data[1].map((item, index) => {
                        return {
                            ...item,
                            STT: index + 1,
                        }
                    })
                },
            )
        },

        openCreate() {
            this.isShowModalAdd = true
        },

        openEdit(item) {
            this.isShowModalEdit = true
            this.detailRecord = { ...item }
        },

        onDelete(item) {
            showConfirm(`Bạn muốn xóa ${item.TenThayThe}?`, () => {
                apiCall(
                    '/work/MT_NguyenLieuQuyDoi_Delete',
                    {
                        NguyenLieu_QuyDoi_Id: item.NguyenLieu_QuyDoi_Id,
                    },
                    () => {
                        showToast.success('Xóa thành công')
                        this.reloadData()
                    },
                    (error) => {
                        showToast.error('Xóa thất bại: ' + error.Message)
                    },
                )
            })
        },

        reloadData() {
            this.onLoadNguyenLieuQuyDoi()
        },

        xuatDanhSachBangCT() {
            const exportData = this.filteredDsNguyenLieuQuyDoi.map((item, index) => ({
                STT: index + 1,
                'Tên thay thế': item.TenThayThe,
                'Quy đổi hệ số': item.QuyDoi_HeSo,
                'Đơn vị tính': item.QuyDoi_DonViTinh_Ten,
                'Ghi chú': item.GhiChu,
                'Tạm khóa': item.Is_TamKhoa,
            }))
            const ws = XLSX.utils.json_to_sheet(exportData)
            const wb = XLSX.utils.book_new()
            XLSX.utils.book_append_sheet(wb, ws, 'DanhSach')
            XLSX.writeFile(wb, 'DanhSachNguyenLieuQuyDoi.xlsx')
        },

        getStatusCount(status) {
            return this.recipes.filter((r) => r.TrangThai === status).length
        },

        resetSTT(list) {
            return list.map((l, i) => ({ ...l, STT: i + 1 }))
        },

        getStatusColor(status) {
            const colors = {
                true: 'primary',
            }
            return colors[status] || 'grey'
        },

        getStatusIcon(status) {
            const icons = {
                true: 'mdi-lock',
            }
            return icons[status]
        },
    },
}
</script>

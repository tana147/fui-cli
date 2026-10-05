<template>
    <z-layout>
        <v-app-bar density="compact" :elevation="0" title="Bảng tính cost sản phẩm">
            <template v-slot:append>
                <v-btn @click="isShowModalAddSanPham = true" color="primary" prepend-icon="mdi-plus" variant="flat">Thêm mới</v-btn>
                <v-menu>
                    <template v-slot:activator="{ props }">
                        <v-btn color="primary" prepend-icon="mdi-tune" append-icon="mdi-chevron-down" variant="flat" v-bind="props">Thao tác</v-btn>
                    </template>
                    <v-list density="compact">
                        <v-list-item @click="exportExcel" prepend-icon="mdi-file-excel-outline" title="Xuất excel"> </v-list-item>
                    </v-list>
                </v-menu>
            </template>
        </v-app-bar>

        <div class="pa-2 border-b border-t">
            <v-row dense>
                <v-col cols="3">
                    <v-text-field clearable label="Tìm theo mã, tên sản phẩm" v-model="search"></v-text-field>
                </v-col>
                <v-col cols="2">
                    <div class="d-flex gap-dense">
                        <v-btn prepend-icon="mdi-magnify">Tìm</v-btn>
                    </div>
                </v-col>
            </v-row>
        </div>

        <v-data-table-server
            v-model:items-per-page="itemsPerPage"
            :headers="headers"
            :items="dataItems"
            :items-length="totalRow"
            item-value="NhanVien_Id"
            @update:options="getData"
            :hover="true"
            :disable-sort="true"
            density="compact"
            fixed-header
            height="calc(100vh - 165px)"
            items-per-page-text="Bản ghi"
            :items-per-page-options="[50, 100, 150, 200]"
            no-data-text="Không tìm thấy dữ liệu"
            :search="search"
        >
            <template v-slot:item.TrangThai_LamViec="{ item }">
                <div class="d-flex align-center justify-center">
                    <v-chip color="primary" size="small"> Đang bán </v-chip>
                </div>
            </template>
            <template v-slot:item.Detail="{ item }">
                <div class="d-flex align-center justify-center">
                    <v-btn variant="text" color="primary" prepend-icon="mdi-open-in-new" @click="onOpenDetail(item)">Xem chi tiết</v-btn>
                </div>
            </template>
            <template v-slot:item.action="{ item }">
                <v-menu>
                    <template v-slot:activator="{ props }">
                        <v-btn size="small" variant="text" v-bind="props" icon="mdi-dots-vertical"></v-btn>
                    </template>
                    <v-list density="compact">
                        <v-list-item @click="onOpenUpdate(item)" prepend-icon="mdi-square-edit-outline" title="Cập nhật"></v-list-item>
                        <v-divider />
                        <v-list-item @click="" prepend-icon="mdi-lock" title="Tạm khóa"></v-list-item>
                        <v-divider />
                        <v-list-item @click="" prepend-icon="mdi-trash-can" title="Xóa"></v-list-item>
                    </v-list>
                </v-menu>
            </template>
        </v-data-table-server>

        <uc-modal-add-sp v-model="isShowModalAddSanPham" @onReload="reloadData"/>
        <uc-modal-thanh-phan-sp v-model="isShowDetailSanPham" :detailSanPham="detailSanPham"/>
		<uc-modal-update-sp v-model="isShowUpdateSanPham" :detailSanPham="detailSanPham" @onReload="reloadData"/>
    </z-layout>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            itemsPerPage: 50,
            totalRow: 0,

            isShowModalAddSanPham: false,
            isShowDetailSanPham: false,
			isShowUpdateSanPham: false,

            dataItems: [
                {
                    STT: 1,
                    MaNhanVien: 'SP001',
                    HoVaTenNhanVien: 'Bánh mì',
                    TenMauBangCong: 'Ổ',
                    TenVanPhong: '5.000',
                    NgayBatDau: '31/12/2025',
                    PhanLoai: 'Bakery',
                    TrangThai_LamViec: 'Đang bán',
                    Detail: '',
                    action: '',
                },
                {
                    STT: 2,
                    MaNhanVien: 'SP002',
                    HoVaTenNhanVien: 'Sữa',
                    TenMauBangCong: 'Hộp',
                    TenVanPhong: '25.000',
                    NgayBatDau: '31/12/2025',
                    PhanLoai: 'Zen Tea',
                    TrangThai_LamViec: 'Đang bán',
                    Detail: '',
                    action: '',
                },
                {
                    STT: 3,
                    MaNhanVien: 'SP003',
                    HoVaTenNhanVien: 'Hồng trà',
                    TenMauBangCong: 'Hộp',
                    TenVanPhong: '35.000',
                    NgayBatDau: '31/12/2025',
                    PhanLoai: 'Zen Tea',
                    TrangThai_LamViec: 'Đang bán',
                    Detail: '',
                    action: '',
                },
            ],
            headers: [
                { title: 'STT', key: 'STT', sortable: false, align: 'center', width: '50px' },
                { title: 'Mã sản phẩm', key: 'MaNhanVien', sortable: false },
                { title: 'Tên sản phẩm', key: 'HoVaTenNhanVien', sortable: false },
                { title: 'Đơn vị sản phẩm', key: 'TenMauBangCong', sortable: false },
                { title: 'Giá', key: 'TenVanPhong', sortable: false },
                { title: 'Hạn sử dụng', key: 'NgayBatDau', sortable: false },
                { title: 'Phân loại sản phẩm', key: 'PhanLoai', sortable: false },
                { title: 'Trạng thái', key: 'TrangThai_LamViec', sortable: false, align: 'center' },
                { title: 'Chi tiết thành phần', key: 'Detail', sortable: false, align: 'center' },
                { title: '', key: 'action', sortable: false },
            ],

            search: null,
            detailSanPham: null,
        }
    },
    mounted() {},
    computed: {},
    watch: {},
    methods: {
        onOpenDetail(item){
            this.detailSanPham = item
            this.isShowDetailSanPham = true
        },
		onOpenUpdate(item){
			this.detailSanPham = item
			this.isShowUpdateSanPham = true
		},
        reloadData() {
            this.getData({ page: 1, itemsPerPage: this.itemsPerPage })
        },
        getData({ page, itemsPerPage }) {
            const params = {
                TimKiem: this.search,
                PageIndex: page,
                PageSize: itemsPerPage,
                MauBangCong_Id_List: '',
                MauBangLuong_Id_List: '',
                TrangThai_LamViec_List: '1,2,4',
                ChucDanh_Id_List: '',
                PhongBan_Id_List: '',
                VanPhong_Id_List: '',
                HinhThuc_Id_List: '',
                BacThuong_Id_List: '',
                BacLuong_Id_List: '',
                ViTri_Id_List: '',
                NhomNhanVien_Id_List: '',
                NguoiQuanLy_1_Id_List: '',
                NguoiQuanLy_2_Id_List: '',
                NguoiQuanLy_3_Id_List: '',
            }
            apiCall('/work/HR_NhanVien_Select', params, (res) => {
                this.totalRow = res.data[0][0].TotalRow ?? 0
                // this.dataItems = res.data[1].map((item, index) => {
                //     return {
                //         ...item,
                //         STT: index + 1,
                //     }
                // })
            })
        },
        exportExcel() {
            jsonToExcel({
                filename: 'data.xlsx',
                sheets: [
                    {
                        name: 'data',
                        data: this.dataItems,
                    },
                ],
            })
        },
    },
}
</script>

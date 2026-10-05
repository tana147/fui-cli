<template>
    <v-dialog v-model="modelValue" fullscreen>
        <v-card>
            <v-toolbar density="compact" elevation="0">
                <v-toolbar-title> Nhập file excel </v-toolbar-title>
                <v-spacer />
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </v-toolbar>

            <v-card-text>
                <div class="inpFile-container d-flex align-center">
                    <v-file-input
                        v-model="fileUpload"
                        dense
                        hide-details
                        accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
                        label="Chọn file Excel"
                    />

                    <v-chip color="green" variant="flat" prepend-icon="mdi-download" class="ml-4" dense hide-details>
                        <a class="text-white" :href="vueData.v_Set.urlReadFile + this.fileTemplate" target="_blank">Tải file mẫu </a>
                    </v-chip>
                </div>

                <div class="search-bar">
                    <v-text-field v-model="search" label="Tìm kiếm theo tên nguyên liệu, mã nội bộ" prepend-inner-icon="mdi-magnify" dense hide-details density="compact" color="primary" clearable />
                </div>

                <v-data-table :headers="tableHeader" :items="filteredItems" class="elevation-1 mt-4" dense>
                    <template v-slot:item.STT="{ item, index }">
                        {{ index + 1 }}
                    </template>

                    <template v-slot:item.MaNoiBo="{ item }">
                        <b :class="showErrorTenHangHoa(item.TenHangHoa)">{{ item.TenHangHoa }}</b>
                        <p :class="findErrorInArray(item.MaNoiBo)">{{ item.MaNoiBo }}</p>
                    </template>

                    <template v-slot:item.DonGia_ApDung="{ item }">
                        <p class="mb-3">{{ item.DonGia_ApDung?.toLocaleString('vi-VN') }}</p>

                        <v-autocomplete
                            v-model="item.Chuan_DonViTinh_Id"
                            item-title="TenDonVi"
                            item-value="DonViTinh_Id"
                            placeholder="* Đơn vị nhập"
                            label="* Đơn vị nhập"
                            variant="underlined"
                            :items="item.DsDonViTinh"
                            dense
                            density="compact"
                            no-data-text="Chưa có dữ liệu"
                        />
                    </template>

                    <template v-slot:item.GiaBan="{ item }">
                        <p class="mb-3">{{ item.GiaBan?.toLocaleString('vi-VN') }}</p>

                        <v-autocomplete
                            v-model="item.Ban_DonViTinh_Id"
                            item-title="TenDonVi"
                            item-value="DonViTinh_Id"
                            placeholder="Đơn vị bán"
                            label="Đơn vị bán"
                            variant="underlined"
                            :items="item.DsDonViTinh"
                            dense
                            density="compact"
                            clearable
                            no-data-text="Chưa có dữ liệu"
                        />
                    </template>

                    <template v-slot:item.LoaiNguyenLieu="{ item }">
                        <v-autocomplete
                            v-model="item.LoaiNguyenLieu"
                            item-title="text"
                            item-value="value"
                            placeholder="* Loại nguyên liệu"
                            label="* Loại nguyên liệu"
                            variant="underlined"
                            :items="LoaiThanhPhanList"
                            dense
                            density="compact"
                            no-data-text="Chưa có dữ liệu"
                        />
                    </template>

                    <template v-slot:item.PhanLoai_TinhChat_Id="{ item }">
                        <v-autocomplete
                            v-model="item.PhanLoai_TinhChat_Id"
                            item-title="TenTinhChat"
                            item-value="PhanLoai_TinhChat_Id"
                            label="* Nhóm tính chất"
                            variant="underlined"
                            :items="item.DsNhomTinhChat"
                            dense
                            density="compact"
                            no-data-text="Chưa có dữ liệu"
                            @update:model-value="onTinhChatChange(item)"
                        />
                    </template>

                    <template v-slot:item.PhanLoai_NhomVatTu_Id="{ item }">
                        <v-autocomplete
                            v-model="item.PhanLoai_NhomVatTu_Id"
                            item-title="TenNhomVatTu"
                            item-value="PhanLoai_NhomVatTu_Id"
                            :disabled="item.PhanLoai_TinhChat_Id == null"
                            label="* Nhóm vật tư"
                            variant="underlined"
                            :items="item.DsNhomVatTu"
                            dense
                            density="compact"
                            no-data-text="Chưa có dữ liệu"
                            @update:model-value="onVatTuChange(item)"
                        />
                    </template>

                    <template v-slot:item.PhanLoai_NhomSanPham_Id="{ item }">
                        <v-autocomplete
                            v-model="item.PhanLoai_NhomSanPham_Id"
                            item-title="TenNhomSanPham"
                            item-value="PhanLoai_NhomSanPham_Id"
                            label="* Nhóm sản phẩm"
                            variant="underlined"
                            :items="item.DsNhomTenSanPham"
                            dense
                            density="compact"
                            no-data-text="Chưa có dữ liệu"
                        />
                    </template>

                    <template v-slot:item.TrangThai="{ item }">
                        <v-select v-model="item.TrangThai" label="Trạng thái" :items="DsTrangThai" />
                    </template>

                    <template v-slot:item.NguonGoc="{ item }">
                        <p>{{ item.NguonGoc }} {{ item.MauSac ? ' / ' + item.MauSac : '' }} {{ item.HinhThai ? ' / ' + item.HinhThai : '' }}</p>
                    </template>

                    <template v-slot:item.ThuongHieu="{ item }">
                        <p>{{ item.ThuongHieu }} {{ item.DacTinh ? ' / ' + item.DacTinh : '' }} {{ item.BaoQuan_ThietBi ? ' / ' + item.BaoQuan_ThietBi : '' }}</p>
                    </template>
                </v-data-table>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="" variant="text">Hủy</v-btn>
                <v-btn color="primary" @click="onAdd" prepend-icon="mdi-content-save" variant="flat">Xác nhận</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['modelValue', 'onLoadNhomTinhChat', 'onLoadNhomVatTu', 'onLoadNhomTenSanPham', 'LoaiThanhPhanList', 'DsTrangThai'],
    emits: ['update:modelValue', 'onReload'],
    data() {
        return {
            vueData,
            fileUpload: null,
            search: '',
            fileTemplate: 'F20684D436F642A3ADE03B1E272B982E',

            excelData: [],
            DsNhomTinhChat: [],
            DsNhomVatTu: [],
            DsNhomTenSanPham: [],
            DsDonViTinh: [],
            errorArray: [],
            errorHangHoa: null,

            tableHeader: [
                { title: '#', key: 'STT', sortable: false, align: 'center', width: '50px' },
                { title: 'Mã nội bộ', key: 'MaNoiBo', sortable: false, align: 'left', width: '260px' },

                { title: 'Loại nguyên liệu', key: 'LoaiNguyenLieu', sortable: false, align: 'left', width: '250px' },
                { title: 'Nhóm tính chất', key: 'PhanLoai_TinhChat_Id', sortable: false, align: 'left', width: '300px' },
                { title: 'Nhóm vật tư', key: 'PhanLoai_NhomVatTu_Id', sortable: false, align: 'left', width: '300px' },
                { title: 'Nhóm sản phẩm', key: 'PhanLoai_NhomSanPham_Id', sortable: false, align: 'left', width: '300px' },
                { title: 'Độ ưu tiên', key: 'DoUuTien', sortable: false, align: 'center', width: '150px'},
                { title: 'Đơn giá nhập / Đơn vị nhập', key: 'DonGia_ApDung', sortable: false, align: 'left', width: '230px' },
                { title: 'Đơn giá bán / Đơn vị bán', key: 'GiaBan', sortable: false, align: 'left', width: '230px' },

                { title: 'Nhiệt độ bảo quản', key: 'BaoQuan_NhietDo', sortable: false, align: 'center', width: '100px' },
                { title: 'Hạn sử dụng (giờ)', key: 'HanSuDung_Gio', sortable: false, align: 'center', width: '100px' },
                { title: 'Nguồn gốc / Màu sắc / Hình thái', key: 'NguonGoc', sortable: false, align: 'left', width: '300px' },
                { title: 'Thương hiệu / Đặc tính / Thiết bị bảo quản', key: 'ThuongHieu', sortable: false, align: 'left', width: '300px' },
                { title: 'Nơi bảo quản', key: 'BaoQuan_NoiBaoQuan', sortable: false, align: 'left', width: '200px' },
                { title: 'Trạng thái', key: 'TrangThai', sortable: false, align: 'left', width: '450px' },
                { title: 'Mô tả', key: 'MoTa', sortable: false, align: 'left', width: '200px' },
            ],
        }
    },
    mounted() {},
    computed: {
        filteredItems() {
            if (this.search === null || this.search === '') return this.excelData

            const keyword = this.removeAccents(this.search.toLowerCase())

            return this.excelData.filter((item) => {
                return this.removeAccents(item.TenHangHoa).toLowerCase().includes(keyword) || this.removeAccents(item.MaNoiBo).toLowerCase().includes(keyword)
            })
        },
    },
    watch: {
        async fileUpload(val) {
            console.log('fileUpload', val)
            if (val) {
                await this.onLoadDonVi()
                this.DsNhomTinhChat = await this.onLoadNhomTinhChat()
                this.DsNhomVatTu = await this.onLoadNhomVatTu()
                this.DsNhomTenSanPham = await this.onLoadNhomTenSanPham()

                this.readExcel(val)
            } else {
                this.excelData = []
                this.errorArray = []
            }
        },
    },
    methods: {
        removeAccents(str) {
            // Chuyển đổi chuỗi sang dạng không dấu tiếng Việt
            return str ? str.normalize('NFD').replace(/[\u0300-\u036f]/g, '') : ''
        },

        findErrorInArray(maNoiBo) {
            return this.errorArray.find((item) => item === maNoiBo) ? 'errorBg' : ''
        },

        showErrorTenHangHoa(tenHangHoa) {
            return this.errorHangHoa === tenHangHoa ? 'errorBg' : ''
        },

        onAdd() {
            const $this = this
            const payload = []
            this.excelData.forEach((item) => {
                const obj = {
                    EORDER_SanPham_Id: item.EORDER_SanPham_Id,
                    PhanLoai_TinhChat_Id: item.PhanLoai_TinhChat_Id,
                    PhanLoai_NhomVatTu_Id: item.PhanLoai_NhomVatTu_Id,
                    PhanLoai_NhomSanPham_Id: item.PhanLoai_NhomSanPham_Id,
                    Chuan_DonViTinh_Id: item.Chuan_DonViTinh_Id,
                    Ban_DonViTinh_Id: item.Ban_DonViTinh_Id,
                    LoaiNguyenLieu: item.LoaiNguyenLieu,
                    MaNoiBo: item.MaNoiBo,
                    TenHangHoa: item.TenHangHoa,
                    ThuongHieu: item.ThuongHieu,
                    NguonGoc: item.NguonGoc,
                    MauSac: item.MauSac,
                    HinhThai: item.HinhThai,
                    DacTinh: item.DacTinh,
                    TrangThai: item.TrangThai,
                    MoTa: item.MoTa,
                    BaoQuan_NhietDo: item.BaoQuan_NhietDo,
                    BaoQuan_ThietBi: item.BaoQuan_ThietBi,
                    HanSuDung_Gio: item.HanSuDung_Gio,
                    BaoQuan_NoiBaoQuan: item.BaoQuan_NoiBaoQuan,
                    DoUuTien: item.DoUuTien,
                    DonGia_ApDung: item.DonGia_ApDung,
                    GiaBan: item.GiaBan,
                    Is_TamKhoa: item.Is_TamKhoa,
                }

                payload.push(obj)
            })

            if (payload.length > 0) {
                for (const item of payload) {
                    const errorMsg = this.validateItem(item)
                    if (errorMsg) {
                        showToast.error(`Vui lòng chọn ${errorMsg.Rule} cho nguyên liệu: ${errorMsg.TenHangHoa}`)
                        $this.errorHangHoa = errorMsg.TenHangHoa
                        console.log('$this.errorHangHoa', $this.errorHangHoa)
                        return
                    }
                }

                $this.errorHangHoa = null

                apiCall(
                    '/work/MT_NguyenLieu_Import',
                    {
                        JsonNguyenLieu: JSON.stringify(payload),
                    },
                    () => {
                        showToast.success('Thêm nguyên liệu thành công')
                        this.$emit('onReload')
                        this.onClose()
                    },
                    (error) => {
                        const message = error.responseJSON?.Message
                        let result = message

                        if (message?.includes(':')) {
                            result = message.split(':').pop().trim()
                            $this.errorArray = message
                                .split(':')
                                .pop()
                                .trim()
                                .split(',')
                                .map((err) => err.trim())
                        }
                        console.log(result)
                        console.log('$this.errorArray', $this.errorArray)
                        console.log('error', error.responseJSON.Message)

                        showToast.error(error.responseJSON?.Message)
                    },
                )
            }
        },

        validateItem(item) {
            const rules = [
                { key: 'LoaiNguyenLieu', msg: 'loại nguyên liệu' },
                { key: 'PhanLoai_TinhChat_Id', msg: 'nhóm tính chất' },
                { key: 'PhanLoai_NhomVatTu_Id', msg: 'nhóm vật tư' },
                { key: 'PhanLoai_NhomSanPham_Id', msg: 'nhóm sản phẩm' },
                { key: 'Chuan_DonViTinh_Id', msg: 'đơn vị nhập' },
            ]

            for (const rule of rules) {
                if (item[rule.key] === null || item[rule.key] === undefined) {
                    return {
                        Rule: rule.msg,
                        TenHangHoa: item.TenHangHoa,
                    }
                }
            }

            return null
        },

        onTinhChatChange(item) {
            console.log('tinh chat', item)
            item.PhanLoai_NhomVatTu_Id = null
            item.PhanLoai_NhomSanPham_Id = null
            item.DsNhomVatTu = this.DsNhomVatTu.filter((nv) => nv.PhanLoai_TinhChat_Id === item.PhanLoai_TinhChat_Id)
        },

        onVatTuChange(item) {
            console.log('vat tu', item)
            item.PhanLoai_NhomSanPham_Id = null

            const obj = {
                PhanLoai_NhomSanPham_Id: 0,
                TenNhomSanPham: '- Chưa xác định -',
            }

            item.DsNhomTenSanPham.unshift(obj)
        },

        onLoadDonVi() {
            apiCall('/work/HH_DonViTinh_Select_Dropdown', null, (res) => {
                this.DsDonViTinh = res.data
            })
        },

        readExcel(file) {
            const reader = new FileReader()

            reader.onload = (e) => {
                try {
                    const data = e.target.result

                    const workbook = XLSX.read(data, { type: 'array' })

                    const sheetName = workbook.SheetNames[0]
                    const worksheet = workbook.Sheets[sheetName]
                    const json = XLSX.utils.sheet_to_json(worksheet)

                    console.log('Đọc file thành công (ArrayBuffer):', json)

                    this.excelData = json.map((item) => ({
                        EORDER_SanPham_Id: 0,
                        PhanLoai_TinhChat_Id: null,
                        PhanLoai_NhomVatTu_Id: null,
                        PhanLoai_NhomSanPham_Id: null,
                        Chuan_DonViTinh_Id: item['Đơn vị nhập']
                            ? (this.DsDonViTinh.find((dv) => dv.TenDonVi.trim().toLowerCase() === item['Đơn vị nhập'].toString().trim().toLowerCase())?.DonViTinh_Id ?? null)
                            : null,
                        Ban_DonViTinh_Id: item['Đơn vị bán']
                            ? (this.DsDonViTinh.find((dv) => dv.TenDonVi.trim().toLowerCase() === item['Đơn vị bán'].toString().trim().toLowerCase())?.DonViTinh_Id ?? null)
                            : null,
                        LoaiNguyenLieu: null,
                        MaNoiBo: item['Mã nội bộ'] ?? '',
                        TenHangHoa: item['Tên nguyên liệu'] ?? '',
                        ThuongHieu: item['Thương hiệu'] ?? '',
                        NguonGoc: item['Nguồn gốc'] ?? '',
                        MauSac: item['Màu sắc'] ?? '',
                        HinhThai: item['Hình thái'] ?? '',
                        DacTinh: item['Đặc tính'] ?? '',
                        MoTa: item['Mô tả'] ?? '',
                        BaoQuan_NhietDo: item['Nhiệt độ bảo quản'] ?? '',
                        BaoQuan_ThietBi: item['Thiết bị bảo quản'] ?? '',
                        HanSuDung_Gio: item['Hạn sử dụng (giờ)'] ?? null,
                        DonGia_ApDung: item['Đơn giá nhập'] ?? 0,
                        DoUuTien: item['Độ ưu tiên'] ?? null,
                        GiaBan: item['Đơn giá bán'] ?? 0,
                        TrangThai: item['Trạng thái'] ? item['Trạng thái'].toUpperCase() : null,
                        BaoQuan_NoiBaoQuan: item['Nơi bảo quản'] ?? '',
                        Is_TamKhoa: 0,
                        DsDonViTinh: this.DsDonViTinh,
                        DsNhomTinhChat: this.DsNhomTinhChat,
                        DsNhomVatTu: this.DsNhomVatTu,
                        DsNhomTenSanPham: this.DsNhomTenSanPham,
                    }))

                    console.log('this.excelData', this.excelData)
                } catch (error) {
                    showToast.error('Lỗi đọc file excel')
                    console.error('Lỗi đọc file:', error)
                }
            }

            // Đọc excel dưới dạng ArrayBuffer
            reader.readAsArrayBuffer(file)
        },

        onClose() {
            this.fileUpload = null
            this.excelData = []
            this.errorArray = []
            this.errorHangHoa = null
            this.$emit('update:modelValue', false)
        },
    },
}
</script>

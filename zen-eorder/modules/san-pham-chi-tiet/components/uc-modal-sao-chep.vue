<template>
    <v-dialog v-model="vueData.IsShowDialogCloneProduct" scrollable width="550">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Sao chép sản phẩm</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogCloneProduct = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <p class="mb-0 font-weight-bold primary--text">Dữ liệu cơ sở</p>
                <v-text-field class="mt-1" v-model="MaSanPham" label="Mã sản phẩm" outlined dense hide-details></v-text-field>
                <v-text-field class="mt-3" v-model="TenSanPham" label="Tên sản phẩm" outlined dense hide-details></v-text-field>
                <v-checkbox class="mt-2" color="success" v-model="Is_Clone_NhomLienKet" label="Thiết lập nhóm liên kết" :value="Is_Clone_NhomLienKet" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" v-model="Is_Clone_NguyenLieu" label="Thiết lập nguyên liệu" :value="Is_Clone_NguyenLieu" hide-details></v-checkbox>
                <p class="mt-5 mb-0 font-weight-bold primary--text">Dữ liệu theo cửa hàng</p>
                <v-checkbox class="mt-1" color="success" v-model="Is_Clone_CuaHang" label="Sao chép cửa hàng áp dụng" :value="Is_Clone_CuaHang" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_CaiDat" label="Thiết lập cài đặt" :value="Is_Clone_CaiDat" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_TrangThai" label="Thiết lập trạng thái" :value="Is_Clone_TrangThai" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_ThietLapGia" label="Thiết lập giá" :value="Is_Clone_ThietLapGia" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_KhuCheBien" label="Thiết lập khu chế biến" :value="Is_Clone_KhuCheBien" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_MayInTem" label="Thiết lập máy in tem" :value="Is_Clone_MayInTem" hide-details></v-checkbox>
                <v-checkbox class="mt-1" color="success" :disabled="!Is_Clone_CuaHang" v-model="Is_Clone_LichBan" label="Thiết lập lịch bán" :value="Is_Clone_LichBan" hide-details></v-checkbox>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSaveClone" color="success">Sao chép</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["show_dialog", "ct_sanpham"],
    data: function () {
        return {
            MaSanPham: "",
            TenSanPham: "",
            Is_Clone_CuaHang: true,
            Is_Clone_CaiDat: true,
            Is_Clone_TrangThai: true,
            Is_Clone_ThietLapGia: true,
            Is_Clone_KhuCheBien: true,
            Is_Clone_MayInTem: true,
            Is_Clone_LichBan: true,
            Is_Clone_NhomLienKet: true,
            Is_Clone_NguyenLieu: true,
        }
    },
    computed: {
        CTSanPham: function () {
            return this.ct_sanpham ?? {}
        },
    },
    watch: {
        Is_Clone_CuaHang: function (val) {
            this.Is_Clone_CaiDat = val
            this.Is_Clone_TrangThai = val
            this.Is_Clone_ThietLapGia = val
            this.Is_Clone_KhuCheBien = val
            this.Is_Clone_MayInTem = val
            this.Is_Clone_LichBan = val
        },
    },
    methods: {
        onSaveClone: function () {
            const $this = this
            const params = {
                SanPhamID: $this.ct_sanpham.SanPhamID,
                MaSanPham: $this.MaSanPham,
                TenSanPham: $this.TenSanPham,
                Is_Clone_CuaHang: $this.Is_Clone_CuaHang ?? false,
                Is_Clone_CaiDat: $this.Is_Clone_CaiDat ?? false,
                Is_Clone_TrangThai: $this.Is_Clone_TrangThai ?? false,
                Is_Clone_ThietLapGia: $this.Is_Clone_ThietLapGia ?? false,
                Is_Clone_KhuCheBien: $this.Is_Clone_KhuCheBien ?? false,
                Is_Clone_MayInTem: $this.Is_Clone_MayInTem ?? false,
                Is_Clone_LichBan: $this.Is_Clone_LichBan ?? false,
                Is_Clone_NhomLienKet: $this.Is_Clone_NhomLienKet ?? false,
                Is_Clone_NguyenLieu: $this.Is_Clone_NguyenLieu ?? false,
            }
            ajaxCALL("/eorder/SanPham_Clone", params, (res) => {
                if (res.data[0].SanPhamID_Clone > 0) {
                    window.location.href = `san-pham-chi-tiet?spid=${res.data[0].SanPhamID_Clone}`
                }
            })
        },
    },
}
</script>

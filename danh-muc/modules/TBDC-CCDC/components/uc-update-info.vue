<template>
    <v-form ref="form">
        <v-row class="pa-4">
            <v-col cols="12" class="pb-0">
                <div class="font-weight-bold">Phân loại theo nhóm</div>
            </v-col>

            <v-col cols="4">
                <v-autocomplete v-model="selectedItem.PhanLoai_TinhChat_Id" label="* Nhóm tính chất"
                    :items="DSNhomTinhChat" item-title="TenTinhChat" item-value="PhanLoai_TinhChat_Id" density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-autocomplete v-model="selectedItem.PhanLoai_NhomVatTu_Id" label="* Nhóm vật tư"
                    :items="DSNhomVTHHFilter" :disabled="!selectedItem.PhanLoai_TinhChat_Id" item-title="TenNhomVatTu"
                    item-value="PhanLoai_NhomVatTu_Id" density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-autocomplete v-model="selectedItem.PhanLoai_NhomSanPham_Id" label="* Nhóm tên sản phẩm"
                    :items="DSNhomTenSanPham" item-title="TenNhomSanPham" item-value="PhanLoai_NhomSanPham_Id"
                    density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="12" class="pb-0">
                <div class="font-weight-bold">Thông tin CCDC</div>
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.MaNoiBo" label="* Mã nội bộ" density="compact"
                    :rules="[v => !!v || 'Vui lòng nhập mã nội bộ']" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.TenHangHoa" label="* Tên CCDC" density="compact"
                    :rules="[v => !!v || 'Vui lòng nhập tên CCDC']" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-autocomplete v-model="selectedItem.Chuan_DonViTinh_Id" label="* Đơn vị nhập" :items="DSDonViTinh"
                    item-title="TenDonVi" item-value="DonViTinh_Id" density="compact"
                    :rules="[v => !!v || 'Vui lòng chọn đơn vị tính']" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.ThuongHieu" label="Thương hiệu" density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.NguonGoc" label="Nguồn gốc" density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.QuyCach" label="Quy cách" density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="12" class="pb-0">
                <div class="font-weight-bold">Thông tin bổ sung</div>
            </v-col>



            <v-col cols="4">
                <v-text-field v-model="selectedItem.HinhDang" label="Hình dạng" density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.ChatLieu" label="Chất liệu" density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.DoUuTien" label="Độ ưu tiên" type="number" density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="12" class="pb-0">
                <div class="font-weight-bold">Thông tin thuế</div>
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.ThueGTGT" label="Thuế GTGT (%)" type="number" density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.ThueKhac" label="Thuế khác (%)" type="number" density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="4">
                <v-text-field v-model="selectedItem.ThueNhapKhau" label="Thuế nhập khẩu (%)" type="number"
                    density="compact" hide-details="auto" />
            </v-col>

            <v-col cols="12">
                <v-textarea v-model="selectedItem.MoTa" label="Mô tả" rows="3" auto-grow density="compact"
                    hide-details="auto" />
            </v-col>

            <v-col cols="3">
                <v-checkbox v-model="selectedItem.Is_TamKhoa" label="Tạm khoá" color="primary" density="compact"
                    hide-details="auto" />
            </v-col>
            <v-col cols="3">
                <v-checkbox v-model="selectedItem.Is_CaBiet" label="Tài sản" color="primary" density="compact"
                    hide-details="auto" />
            </v-col>
        </v-row>
    </v-form>
    <div class="d-flex pa-4">
        <v-spacer></v-spacer>
        <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="onSubmit">Lưu</v-btn>
    </div>
</template>

<script>
export default {
    props: {
        selectedItem: Object,
        DSNhomTinhChat: Array,
        DSNhomVTHH: Array,
        DSNhomTenSanPham: Array,
        DSDonViTinh: Array,
    },

    data() {
        return {
        }
    },

    mounted() {
    },
    computed: {
        DSNhomVTHHFilter() {
            return this.selectedItem.NhomTinhChat === null ? this.DSNhomVTHH : this.DSNhomVTHH.filter((x) => x.PhanLoai_TinhChat_Id == this.selectedItem.PhanLoai_TinhChat_Id)
        },
    },

    watch: {
    },

    methods: {
        async onSubmit() {
            const { valid } = await this.$refs.form.validate();
            if (!valid) {
                showToast.info('Vui lòng nhập đầy đủ thông tin cần thiết')
                return
            }
            const params = {
                HangHoa_Id: this.selectedItem.HangHoa_Id,
                PhanLoai_TinhChat_Id: this.selectedItem.PhanLoai_TinhChat_Id ?? 0,
                PhanLoai_NhomVatTu_Id: this.selectedItem.PhanLoai_NhomVatTu_Id ?? 0,
                PhanLoai_NhomSanPham_Id: this.selectedItem.PhanLoai_NhomSanPham_Id ?? 0,
                Chuan_DonViTinh_Id: this.selectedItem.Chuan_DonViTinh_Id,
                MaNoiBo: this.selectedItem.MaNoiBo ?? '',
                TenHangHoa: this.selectedItem.TenHangHoa,
                Is_TamKhoa: this.selectedItem.Is_TamKhoa ?? 0,
                Is_CaBiet: this.selectedItem.Is_CaBiet ?? 0,
                ThuongHieu: this.selectedItem.ThuongHieu ?? '',
                NguonGoc: this.selectedItem.NguonGoc ?? '',
                ChatLieu: this.selectedItem.ChatLieu ?? '',
                QuyCach: this.selectedItem.QuyCach ?? '',
                HinhDang: this.selectedItem.HinhDang ?? '',
                DoUuTien: this.selectedItem.DoUuTien ?? '',
                ThueGTGT: this.selectedItem.ThueGTGT ?? '',
                ThueKhac: this.selectedItem.ThueKhac ?? '',
                ThueNhapKhau: this.selectedItem.ThueNhapKhau ?? '',
                MoTa: this.selectedItem.MoTa ?? '',
            }
            apiCall("work/TS_CCDC_Update", params, (res) => {
                if (res) showToast.success("Thành công");
            })
        }
    }

}
</script>

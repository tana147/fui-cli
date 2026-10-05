<template>
    <v-dialog v-model="modelValue" max-width="700">
        <v-card>
            <template v-slot:title>Cập nhật nguyên liệu quy đổi</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose"></v-btn>
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="6">
                        <uc-search-nguyen-lieu v-model:value="formData.NguyenLieu_Id" label="Nguyên liệu" />
                    </v-col>

                    <v-col cols="6">
                        <v-text-field v-model="formData.TenThayThe" label="Tên thay thế" required :rules="[rules.required]" density="compact" />
                    </v-col>

                    <v-col cols="6">
                        <uc-select-don-vi v-model:value="formData.QuyDoi_DonViTinh_Id" label="Đơn vị tính" />
                    </v-col>

                    <v-col cols="6">
                        <v-text-field v-model="formData.QuyDoi_HeSo" label="Quy đổi hệ số" type="number" variant="outlined" density="compact" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.GhiChu" label="Ghi chú" rows="2" auto-grow density="compact" variant="outlined" />
                    </v-col>
                    <v-col cols="4">
                        <v-checkbox v-model="formData.Is_TamKhoa" color="primary" label="Tạm khóa"></v-checkbox>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="onUpdate" prepend-icon="mdi-content-save-outline" variant="flat"> Cập nhật </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['modelValue', 'detailRecord', 'onLoadDonViTinh', 'onLoadNguyenLieu'],
    emits: ['update:modelValue', 'onReload'],
    data() {
        return {
            formData: {
                NguyenLieu_QuyDoi_Id: null,
                NguyenLieu_Id: null,
                TenThayThe: '',
                Is_TamKhoa: 0,
            },
            rules: {
                required: (value) => !!value || 'Trường này không được để trống',
            },
            DsNguyenLieu: [],
            DsDonViTinh: [],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        async modelValue(val) {
            if (val) {
                // this.DsDonViTinh = await this.onLoadDonViTinh()
                // this.DsNguyenLieu = await this.onLoadNguyenLieu()
                this.formData = JSON.parse(JSON.stringify(this.detailRecord))
            }
        },
    },
    methods: {
        onClose() {
            this.$emit('update:modelValue', false)
            this.resetData()
        },

        onUpdate() {
            const $this = this

            // Kiểm tra chọn nguyên liệu
            if (!this.formData.NguyenLieu_Id) {
                showToast.error('Vui lòng chọn nguyên liệu', {
                    position: 'top',
                })
                return
            }

            // Kiểm tra tên thay thế không được null hoặc rỗng
            if (!this.formData.TenThayThe || this.formData.TenThayThe.trim() === '') {
                showToast.error('Vui lòng nhập tên thay thế', {
                    position: 'top',
                })
                return
            }

            // Kiểm tra đơn vị tính
            if (!$this.formData.QuyDoi_DonViTinh_Id) {
                showToast.error('Vui lòng chọn đơn vị tính', {
                    position: 'top',
                })
                return
            }

            apiCall(
                '/work/HH_HangHoaQuyDoi_Update',
                {
                    HangHoa_QuyDoi_Id: $this.formData.HangHoa_QuyDoi_Id,
                    HangHoa_Id: $this.formData.HangHoa_Id,
                    TenThayThe: $this.formData.TenThayThe.trim(),
                    QuyDoi_DonViTinh_Id: $this.formData.QuyDoi_DonViTinh_Id,
                    QuyDoi_HeSo: $this.formData.QuyDoi_HeSo,
                    GhiChu: $this.formData.GhiChu,
                    Is_TamKhoa: $this.formData.Is_TamKhoa,
                },
                (res) => {
                    this.$emit('onReload')
                    this.onClose()
                    showToast.success('Cập nhật thành công!')
                },
            )
        },

        resetData() {
            this.formData.NguyenLieu_QuyDoi_Id = null
            this.formData.NguyenLieu_Id = null
            this.formData.TenThayThe = ''
            this.formData.QuyDoi_DonViTinh_Id = null
            this.formData.QuyDoi_HeSo = ''
            this.formData.GhiChu = ''
            this.formData.Is_TamKhoa = 0
        },
    },
}
</script>

<template>
    <v-dialog v-model="modelValue" max-width="700">
        <v-card>
            <template v-slot:title>Cập nhật nhóm phân loại</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
            </template>

            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <v-text-field
                            v-model="formData.tenNhomPhanLoai"
                            dense
                            label="Tên nhóm phân loại"
                            required
                            density="compact"
                            hide-details="auto"
                        />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.ghiChu" dense label="Ghi chú" density="compact" hide-details="auto" auto-grow :rows="3" no-resize />
                    </v-col>
                    <v-col cols="12">
                        <v-checkbox v-model="formData.isTamKhoa" label="Tạm khóa" dense hide-details="auto" color="primary" />
                    </v-col>
                </v-row>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="submit">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["modelValue", "editItem"],
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                phanLoaiNhaCungCapId: null,
                tenNhomPhanLoai: "",
                ghiChu: "",
                isTamKhoa: false,
            },
        }
    },
    mounted() {},
    computed: {},
    watch: {
        modelValue(isOpen) {
            if (isOpen) {
                this.formData = {
                    phanLoaiNhaCungCapId: this.editItem?.PhanLoai_NhaCungCap_Id ?? null,
                    tenNhomPhanLoai: this.editItem?.TenNhomPhanLoai ?? "",
                    ghiChu: this.editItem?.GhiChu ?? "",
                    isTamKhoa: !!this.editItem?.Is_TamKhoa,
                }
            }
        },
    },
    methods: {
        async submit() {
            if (!this.formData.tenNhomPhanLoai || this.formData.tenNhomPhanLoai.trim() === "") {
                showToast.error("Vui lòng nhập tên nhóm phân loại", { position: "top" })
                return
            }

            const params = {
                PhanLoai_NhaCungCap_Id: this.formData.phanLoaiNhaCungCapId,
                TenNhomPhanLoai: this.formData.tenNhomPhanLoai,
                GhiChu: this.formData.ghiChu,
                Is_TamKhoa: this.formData.isTamKhoa ? 1 : 0,
            }

            apiCall("work/HH_PhanLoai_NCC_Update", params, () => {
                showToast.success("Cập nhật nhóm phân loại thành công")
                this.$emit("onReload")
                this.closeModal()
            })
        },
        closeModal() {
            this.$emit("update:modelValue", false)
        },
    },
}
</script>

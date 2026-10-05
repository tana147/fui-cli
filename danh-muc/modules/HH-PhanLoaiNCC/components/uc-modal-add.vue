<template>
    <v-dialog v-model="modelValue" max-width="700">
        <v-card>
            <template v-slot:title>Thêm mới nhóm phân loại</template>
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
                            autofocus
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
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="submit">Tạo</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["modelValue"],
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                tenNhomPhanLoai: null,
                ghiChu: null,
                isTamKhoa: false,
            },
        }
    },
    mounted() {},
    computed: {},
    watch: {},
    methods: {
        async submit() {
            if (!this.formData.tenNhomPhanLoai || this.formData.tenNhomPhanLoai.trim() === "") {
                showToast.error("Vui lòng nhập tên nhóm phân loại", { position: "top" })
                return
            }

            const params = {
                TenNhomPhanLoai: this.formData.tenNhomPhanLoai,
                GhiChu: this.formData.ghiChu,
                Is_TamKhoa: this.formData.isTamKhoa ? 1 : 0,
            }

            apiCall("work/HH_PhanLoai_NCC_Insert", params, () => {
                showToast.success("Tạo mới nhóm phân loại thành công")
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

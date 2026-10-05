<template>
    <v-dialog v-model="modelValue" width="500">
        <v-card>
            <template v-slot:title>Cập nhật</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <v-text-field v-model="formData.tenTinhChat" label="* Nhập tên phân loại tính chất"
                            hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-text-field v-model="formData.vietTat" label="Viết tắt" hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea rows="2" v-model="formData.ghiChu" label="Ghi chú" hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-checkbox v-model="formData.isTamKhoa" label="Tạm khóa" color="primary" hide-details="auto" />
                    </v-col>
                </v-row>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline"
                    @click="submit">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        modelValue: Boolean,
        editItem: Object,
    },
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                tinhChatId: null,
                tenTinhChat: "",
                vietTat: "",
                ghiChu: "",
                isTamKhoa: false,
            },
        }
    },
    mounted() { },
    computed: {},
    watch: {
        modelValue(isOpen) {
            if (isOpen) {
                this.formData = {
                    tinhChatId: this.editItem?.PhanLoai_TinhChat_Id ?? null,
                    tenTinhChat: this.editItem?.TenTinhChat ?? "",
                    vietTat: this.editItem?.VietTat ?? "",
                    ghiChu: this.editItem?.GhiChu ?? "",
                    isTamKhoa: !!this.editItem?.Is_TamKhoa,
                }
            }
        },
    },
    methods: {
        closeDialog() {
            this.$emit("update:modelValue", false)
        },

        async submit() {
            if (!this.formData.tenTinhChat || this.formData.tenTinhChat.trim() === "") {
                showToast.error("Vui lòng nhập tên phân loại tính chất", { position: "top" })
                return
            }

            const params = {
                PhanLoai_TinhChat_Id: this.formData.tinhChatId,
                TenTinhChat: this.formData.tenTinhChat,
                VietTat: this.formData.vietTat ?? "",
                GhiChu: this.formData.ghiChu,
                Is_TamKhoa: this.formData.isTamKhoa,
            }
            apiCall(
                "work/HH_PhanLoai_TinhChat_Update",
                params,
                () => {
                    showToast.success("Thành công")
                    this.closeDialog()
                    this.$emit("onReload")
                }
            )
        },
    },
}
</script>

<template>
    <v-dialog v-model="modelValue" width="500">
        <v-card>
            <template v-slot:title>Thêm mới</template>
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
    },
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                tenTinhChat: "",
                vietTat: "",
                ghiChu: "",
            },
        }
    },
    mounted() { },
    computed: {},
    watch: {},
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
                TenTinhChat: this.formData.tenTinhChat,
                VietTat: this.formData.vietTat ?? "",
                GhiChu: this.formData.ghiChu,
            }
            apiCall(
                "work/HH_PhanLoai_TinhChat_Insert",
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

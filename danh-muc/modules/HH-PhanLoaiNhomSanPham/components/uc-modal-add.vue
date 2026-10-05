<template>
    <v-dialog v-model="modelValue" width="500">
        <v-card>
            <template v-slot:title>Thêm mới</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>
            <v-card-text class="pt-0">
                <v-row>
                    <v-col cols="12">
                        <v-text-field v-model="formData.tenNhomHangHoa" label="Nhập tên nhóm hàng hoá"
                            hide-details="auto" />
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
                tenNhomHangHoa: "",
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
            if (!this.formData.tenNhomHangHoa || this.formData.tenNhomHangHoa.trim() === "") {
                showToast.error("Vui lòng nhập danh mục", { position: "top" })
                return
            }
            const params = {
                TenNhomSanPham: this.formData.tenNhomHangHoa,
            }
            apiCall(
                "work/HH_PhanLoai_NhomSanPham_Insert",
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

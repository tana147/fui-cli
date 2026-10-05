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
                        <v-autocomplete :clearable="false" density="compact" label="Lọc theo tính chất"
                            :items="nhomTinhChatList" v-model="formData.tinhChatId" item-title="TenTinhChat"
                            item-value="PhanLoai_TinhChat_Id" hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-text-field required v-model="formData.tenNhomVatTu" label="Nhập tên loại danh mục"
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
        nhomTinhChatList: Array,
    },
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                tinhChatId: null,
                tenNhomVatTu: "",
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
            if (!this.formData.tinhChatId) {
                showToast.error("Vui lòng chọn tính chất", { position: "top" })
                return
            }
            if (!this.formData.tenNhomVatTu || this.formData.tenNhomVatTu.trim() === "") {
                showToast.error("Vui lòng nhập loại danh mục", { position: "top" })
                return
            }
            const params = {
                PhanLoai_TinhChat_Id: this.formData.tinhChatId,
                TenNhomVatTu: this.formData.tenNhomVatTu ?? "",
            }
            apiCall(
                "work/HH_PhanLoai_NhomVatTu_Insert",
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

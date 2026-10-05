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
                        <span>
                            Nhóm: <b>{{ tenTinhChat }}</b>
                        </span>
                    </v-col>
                    <v-col cols="12">
                        <v-text-field required v-model="formData.tenNhomVatTu" label="Nhập tên nhóm vật tư"
                            hide-details="auto" />
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
        nhomTinhChatList: Array,
    },
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            formData: {
                nhomVatTuId: null,
                tenNhomVatTu: "",
                isTamKhoa: false,
                tinhChatId: null,
            },
        }
    },
    mounted() { },
    computed: {
        tenTinhChat() {
            const res = this.nhomTinhChatList.find((x) => x.PhanLoai_TinhChat_Id === this.formData.tinhChatId)
            return res?.TenTinhChat ?? "Không rõ"
        },
    },
    watch: {
        modelValue(isOpen) {
            if (isOpen) {
                this.formData = {
                    nhomVatTuId: this.editItem?.PhanLoai_NhomVatTu_Id ?? null,
                    tenNhomVatTu: this.editItem?.TenNhomVatTu ?? "",
                    isTamKhoa: !!this.editItem?.Is_TamKhoa,
                    tinhChatId: this.editItem?.PhanLoai_TinhChat_Id ?? null,
                }
            }
        },
    },
    methods: {
        closeDialog() {
            this.$emit("update:modelValue", false)
        },

        async submit() {
            if (!this.formData.tenNhomVatTu || this.formData.tenNhomVatTu.trim() === "") {
                showToast.error("Vui lòng nhập tên nhóm vật tư", { position: "top" })
                return
            }

            const params = {
                PhanLoai_NhomVatTu_Id: this.formData.nhomVatTuId,
                TenNhomVatTu: this.formData.tenNhomVatTu,
                Is_TamKhoa: this.formData.isTamKhoa ? 1 : 0,
            }
            apiCall(
                "work/HH_PhanLoai_NhomVatTu_Update",
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

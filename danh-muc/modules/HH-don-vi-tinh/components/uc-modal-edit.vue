<template>
    <v-dialog v-model="modelValue" max-width="500">
        <v-card>
            <template v-slot:title>Cập nhật đơn vị tính</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <v-text-field v-model="formData.tenDonVi" label="Tên đơn vị tính" required :rules="[rules.required]" hide-details="auto" />
                    </v-col>

                    <v-col cols="12">
                        <v-textarea v-model="formData.moTa" label="Mô tả" rows="2" auto-grow density="comfortable" variant="outlined" hide-details="auto" />
                    </v-col>

                    <v-col cols="12">
                        <v-checkbox v-model="formData.isTamKhoa" label="Tạm khóa" dense hide-details="auto" color="primary" />
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="save" prepend-icon="mdi-content-save-outline" variant="flat">Lưu</v-btn>
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
                tenDonVi: "",
                moTa: "",
                isTamKhoa: false,
            },
            rules: {
                required: (value) => !!value || "Trường này không được để trống",
            },
        }
    },
    mounted() {},
    computed: {},
    watch: {
        modelValue(isOpen) {
            if (isOpen) {
                this.formData = {
                    tenDonVi: this.editItem?.TenDonVi ?? "",
                    moTa: this.editItem?.MoTa ?? "",
                    isTamKhoa: !!this.editItem?.Is_TamKhoa,
                }
            }
        },
    },
    methods: {
        closeModal() {
            this.$emit("update:modelValue", false)
        },
        save() {
            if (!this.formData.tenDonVi || this.formData.tenDonVi.trim() === "") {
                showToast.error("Vui lòng nhập tên đơn vị", { position: "top" })
                return
            }
            apiCall(
                "/work/HH_DonViTinh_Update",
                {
                    DonViTinh_Id: this.editItem.DonViTinh_Id,
                    TenDonVi: this.formData.tenDonVi,
                    MoTa: this.formData.moTa,
                    Is_TamKhoa: this.formData.isTamKhoa ? 1 : 0,
                },
                () => {
                    this.$emit("onReload")
                    this.closeModal()
                    showToast.success("Cập nhật đơn vị tính thành công!")
                }
            )
        },
    },
}
</script>

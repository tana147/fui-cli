<template>
    <v-dialog v-model="modelValue" max-width="500">
        <v-card>
            <template v-slot:title>Thêm mới địa điểm</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <v-text-field v-model="formData.tenDiaDiem" label="Tên địa điểm" required autofocus :rules="[rules.required]" hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.ghiChu" label="Ghi chú" rows="2" auto-grow density="comfortable" variant="outlined" hide-details="auto" />
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" @click="save" prepend-icon="mdi-content-save-outline" variant="flat">Lưu </v-btn>
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
                tenDiaDiem: "",
                ghiChu: "",
            },
            rules: {
                required: (value) => !!value || "Trường này không được để trống",
            },
        }
    },
    mounted() {},
    computed: {},
    watch: {},
    methods: {
        closeModal() {
            this.$emit("update:modelValue", false)
        },
        save() {
            if (!this.formData.tenDiaDiem || this.formData.tenDiaDiem.trim() === "") {
                showToast.error("Vui lòng nhập tên địa điểm", { position: "top" })
                return
            }
            const params = {
                TenDiaDiem: this.formData.tenDiaDiem,
                GhiChu: this.formData.ghiChu,
            }
            apiCall("/work/HH_DiaDiem_Insert", params, () => {
                this.$emit("onReload")
                this.resetForm()
                this.closeModal()
                showToast.success("Thêm địa điểm thành công!")
            })
        },
        resetForm() {
            this.formData.tenDiaDiem = ""
            this.formData.ghiChu = ""
        },
    },
}
</script>

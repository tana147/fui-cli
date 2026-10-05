<template>
    <v-dialog v-model="modelValue" max-width="500">
        <v-card>
            <template v-slot:title>Cập nhật khu vực</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <v-autocomplete
                            v-model="formData.diaDiemId"
                            label="Chọn địa điểm"
                            :items="diaDiemList"
                            item-title="TenDiaDiem"
                            item-value="DiaDiem_Id"
                            variant="outlined"
                            density="compact"
                            clearable
                            hide-details="auto"
                        />
                    </v-col>
                    <v-col cols="12">
                        <v-text-field v-model="formData.tenKhuVuc" label="Tên khu vực" required :rules="[rules.required]" hide-details="auto" />
                    </v-col>
                    <v-col cols="12">
                        <v-textarea v-model="formData.ghiChu" label="Ghi chú" rows="2" auto-grow density="comfortable" variant="outlined" hide-details="auto" />
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
    props: ["modelValue", "editItem", "diaDiemList"],
    emits: ["update:modelValue", "onReload", "onLoadDiaDiem"],
    data() {
        return {
            formData: {
                diaDiemId: null,
                tenKhuVuc: "",
                ghiChu: "",
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
                    diaDiemId: this.editItem?.DiaDiem_Id ?? null,
                    tenKhuVuc: this.editItem?.TenKhuVuc ?? "",
                    ghiChu: this.editItem?.GhiChu ?? "",
                }
                this.$emit("onLoadDiaDiem")
            }
        },
    },
    methods: {
        closeModal() {
            this.$emit("update:modelValue", false)
        },
        save() {
            if (!this.formData.diaDiemId) {
                showToast.error("Vui lòng chọn địa điểm", { position: "top" })
                return
            }
            if (!this.formData.tenKhuVuc || this.formData.tenKhuVuc.trim() === "") {
                showToast.error("Vui lòng nhập tên khu vực", { position: "top" })
                return
            }
            const params = {
                DiaDiem_Id: this.formData.diaDiemId,
                KhuVuc_Id: this.editItem.KhuVuc_Id,
                TenKhuVuc: this.formData.tenKhuVuc,
                GhiChu: this.formData.ghiChu,
            }
            apiCall("/work/HH_KhuVuc_Update", params, () => {
                this.$emit("onReload")
                this.closeModal()
                showToast.success("Cập nhật khu vực thành công!")
            })
        },
    },
}
</script>

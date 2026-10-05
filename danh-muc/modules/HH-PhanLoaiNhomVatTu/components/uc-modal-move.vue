<template>
    <v-dialog v-model="modelValue" width="500">
        <v-card>
            <template v-slot:title>Chuyển nhóm</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
            </template>
            <v-card-text>
                <v-row>
                    <v-col cols="12">
                        <p>Bạn đang chọn {{ selectedRows?.length }} nhóm vật tư.</p>
                    </v-col>
                    <v-col cols="12">
                        <v-autocomplete :clearable="false" density="compact" label="Chuyển đến nhóm tính chất"
                            :items="nhomTinhChatList" v-model="newTinhChatId" item-title="TenTinhChat"
                            item-value="PhanLoai_TinhChat_Id" hide-details="auto" />
                    </v-col>
                </v-row>
            </v-card-text>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-swap-horizontal" @click="submit">Xác nhận
                    chuyển</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: {
        modelValue: Boolean,
        selectedRows: Array,
        nhomTinhChatList: Array,
        clearSelected: Function,
    },
    emits: ["update:modelValue", "onReload"],
    data() {
        return {
            newTinhChatId: null,
        }
    },
    mounted() { },
    computed: {},
    watch: {},
    methods: {
        closeDialog() {
            this.$emit("update:modelValue", false)
            this.clearSelected?.()
        },

        async submit() {
            if (!this.newTinhChatId) {
                showToast.error("Vui lòng chọn tính chất", { position: "top" })
                return
            }

            const ids = (this.selectedRows || []).map((row) => row.PhanLoai_NhomVatTu_Id)
            const params = {
                ListPhanLoai_NhomVatTu_Id: ids.toString(),
                NewPhanLoai_TinhChat_Id: this.newTinhChatId,
            }
            apiCall(
                "work/HH_PhanLoai_NhomVatTu_ChuyenLoaiDanhMuc",
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

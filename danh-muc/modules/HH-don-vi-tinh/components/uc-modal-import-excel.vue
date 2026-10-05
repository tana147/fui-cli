<template>
    <v-dialog v-model="modelValue" max-width="1000">
        <v-card>
            <template v-slot:title>Import đơn vị tính</template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
            </template>
            <v-card-text>
                <div class="d-flex flex-row gap-dense pb-2">
                    <v-btn @click="handleImport" :prepend-icon="isTableReady ? 'mdi-trash-can-outline' : 'mdi-folder-plus-outline'" :color="isTableReady ? 'red' : 'primary'" variant="flat">
                        <template v-if="isTableReady">Xoá tất cả dữ liệu</template>
                        <template v-else>Chọn tập tin (.xlsx, .xls)</template>
                    </v-btn>
                    <v-btn prepend-icon="mdi-file-download" variant="tonal" :href="urlDownload">Tải mẫu</v-btn>
                </div>
                <z-table v-if="isTableReady" ref="refTableDisplay" :headers="tableHeaders" :items="tableRows" @onEdit="saveImport" height="300px" :options="tableOptions" />
                <z-table v-else ref="refTableImport" :items="[]" :headers="[]" height="300px" :options="{ headerVisible: false }" />
            </v-card-text>
            <v-card-actions>
                <div class="d-flex flex-row ga-5 pl-3">
                    <div>Tổng: {{ tableRows.length }}</div>
                    <div class="text-red">Lỗi: {{ totalError }}</div>
                    <div class="text-primary">Hợp lệ: {{ totalSuccess }}</div>
                </div>
                <v-spacer></v-spacer>
                <v-btn :disabled="totalSuccess === 0" color="primary" @click="saveImport" prepend-icon="mdi-database-arrow-down" variant="flat">Import ({{ totalSuccess }} mục) </v-btn>
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
            isTableReady: false,
            tableOptions: {
                index: "Index",
                rowFormatter: function (row) {
                    const item = row.getData()
                    if (item.Is_Ok === false) {
                        const el = row.getElement()
                        el.style.color = "red"
                        el.style.backgroundColor = "#ffe5e5"
                    }
                },
            },
            tableHeaders: [],
            tableRows: [],
        }
    },
    computed: {
        totalError() {
            return this.tableRows.filter((item) => item.Is_Ok === false).length ?? 0
        },
        totalSuccess() {
            return this.tableRows.filter((item) => item.Is_Ok === true).length ?? 0
        },
        urlDownload() {
            return `/_cdn/danh-muc/template-import/Template_Import_DonViTinh.xlsx`
        },
    },
    methods: {
        initTableHeaders() {
            this.tableHeaders = [
                {
                    title: "",
                    width: 60,
                    hozAlign: "center",
                    headerSort: false,
                    formatter: () => {
                        return `<i class="icon-table text-red mdi mdi-trash-can-outline"></i>`
                    },
                    cellClick: (e, cell) => {
                        const rowData = cell.getRow().getData()
                        this.deleteRow(rowData)
                    },
                },
                {
                    title: "#",
                    formatter: "rownum",
                    width: 80,
                    hozAlign: "center",
                },
                {
                    title: "Tên đơn vị",
                    field: "TenDonVi",
                },
                {
                    title: "Mô tả",
                    field: "MoTa",
                },
                {
                    title: "Tạm khóa",
                    field: "Is_TamKhoa",
                    formatter: (cell) => {
                        return cell.getValue() ? '<i class="icon-table mdi mdi-lock text-primary"></i>' : ""
                    },
                    hozAlign: "center",
                    width: 120,
                },
            ]
        },
        handleImport() {
            this.isTableReady = false
            this.tableRows = []
            this.initTableHeaders()
            const refTable = this.$refs.refTableImport.table
            refTable.import("xlsx", ".xlsx", "buffer")
            refTable.on("importImported", (data) => {
                this.renderImportData(data)
                showToast.success("Xử lý dữ liệu thành công")
                this.isTableReady = true
            })
            refTable.on("importError", (err) => {
                this.isTableReady = false
                showToast.error("Lỗi khi duyệt tập tin: " + err)
            })
        },
        renderImportData(data) {
            this.tableRows = data.map((item, index) => {
                return {
                    Index: index,
                    Is_Ok: this.isValidItem(item),
                    TenDonVi: item.TenDonVi ?? "",
                    MoTa: item.MoTa ?? "",
                    Is_TamKhoa: item.Is_TamKhoa ? 1 : 0,
                }
            })
        },
        isValidItem(item) {
            const tenDonVi = item.TenDonVi?.trim()
            return !!tenDonVi && tenDonVi !== ""
        },
        saveImport() {
            const validRows = this.tableRows.filter((item) => item.Is_Ok === true)
            if (validRows.length === 0) {
                showToast.error("Không tìm thấy dữ liệu hợp lệ")
                return
            }
            const params = {
                JsonDonViTinh: JSON.stringify(validRows),
            }
            apiCall("/work/HH_DonViTinh_Import", params, () => {
                showToast.success("Import dữ liệu thành công")
                this.closeModal()
                this.$emit("onReload")
                this.isTableReady = false
                this.tableRows = []
            })
        },
        deleteRow(item) {
            this.tableRows = this.tableRows.filter((del) => del.Index !== item.Index)
            const tableDisplay = this.$refs.refTableDisplay.table
            tableDisplay.deleteRow(item.Index)
        },
        closeModal() {
            this.$emit("update:modelValue", false)
        },
    },
}
</script>

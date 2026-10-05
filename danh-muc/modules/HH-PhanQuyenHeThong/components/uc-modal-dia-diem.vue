<template>
    <uc-modal-assignment v-model="dialog" :title="'Gán địa điểm - ' + getNhanVienTitle(nhanVien)"
        headline="Chọn địa điểm nhân viên được phép quản lý"
        subtitle="Địa điểm được gán ở đây quyết định phạm vi quản lý thực tế của nhân viên." searchLabel="Tìm địa điểm"
        previewTitle="Địa điểm sẽ được áp dụng" emptySelectionText="Nhân viên này hiện chưa được gán địa điểm nào."
        emptyText="Không tìm thấy địa điểm phù hợp" summaryLabel="địa điểm" summaryColor="success"
        impactIcon="mdi-map-marker-check-outline" :impactText="impactText" :items="diaDiemList"
        :selectedValues="selectedIds" itemTitleKey="TenDiaDiem" itemValueKey="DiaDiem_Id"
        :itemDescription="getItemDescription" :searchFields="['TenDiaDiem', 'GhiChu']" @save="onSave" />
</template>

<script>
    export default {
    name: 'uc-modal-dia-diem',
    props: {
        modelValue: { type: Boolean, required: true },
        nhanVien: { type: Object, required: true },
        diaDiemList: { type: Array, required: true },
        selectedIds: {
            type: Array,
            default: function () {
                return []
            },
        },
    },
    emits: ['update:modelValue', 'save'],
    computed: {
        dialog: {
            get() { return this.modelValue },
            set(value) { this.$emit('update:modelValue', value) },
        },
        impactText() {
            return this.getNhanVienTitle(this.nhanVien) + ' sẽ chỉ quản lý các địa điểm được giữ lại trong cấu hình này.'
        },
    },
    methods: {
        getNhanVienTitle(nhanVien) {
            if (!nhanVien) { return '' }
            return nhanVien.HoVaTenNhanVien || nhanVien.MaNhanVien || 'Nhân viên'
        },
        getItemDescription(diaDiem) {
            return diaDiem.GhiChu || 'Chưa cập nhật ghi chú'
        },
        onSave(selectedIds) {
            this.$emit('save', selectedIds)
        },
    },
}
</script>
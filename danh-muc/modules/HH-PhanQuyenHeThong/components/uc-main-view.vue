<template>
    <v-row class="workspace">
        <v-col cols="12" lg="4" class="workspace__col">
            <div class="panel panel--sidebar">
                <uc-list-bo-phan :boPhanList="boPhanList" :selectedBoPhanId="selectedBoPhanId"
                    @add-bo-phan="emitAddBoPhan" @select-bo-phan="emitSelectBoPhan" @edit-bo-phan="emitEditBoPhan"
                    @config-quyen="emitConfigQuyen" @delete-bo-phan="emitDeleteBoPhan" />
            </div>
        </v-col>

        <v-col cols="12" lg="8" class="workspace__col workspace__col--detail">
            <uc-detail-bo-phan v-if="selectedBoPhan" :selectedBoPhan="selectedBoPhan" :activeTab="activeTab"
                :selectedBoPhanQuyenSummaries="selectedBoPhanQuyenSummaries" :priorityMessage="priorityMessage"
                :nhanVienList="nhanVienListByBoPhan" @update:activeTab="emitUpdateActiveTab"
                @edit-bo-phan="emitEditBoPhan" @config-quyen="emitConfigQuyen" @add-nhan-vien="emitAddNhanVien"
                @edit-nhan-vien="emitEditNhanVien" @delete-nhan-vien="emitDeleteNhanVien"
                @assign-dia-diem="emitAssignDiaDiem" />

            <div v-else class="panel empty-panel">
                <v-icon size="48" color="primary">mdi-account-key-outline</v-icon>
                <div class="empty-panel__title">Chọn một bộ phận để bắt đầu cấu hình</div>
                <div class="empty-panel__description">
                    Màn hình này ưu tiên quản lý quyền theo scope bộ phận. Sau khi chọn bộ phận, bạn có thể cấu hình
                    quyền
                    hiệu lực và rà soát nhân sự áp dụng trên cùng một màn hình.
                </div>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="emitAddBoPhan">Tạo bộ phận mới
                </v-btn>
            </div>
        </v-col>
    </v-row>
</template>

<script>
    export default {
    name: 'uc-main-view',
    props: {
        boPhanList: {
            type: Array,
            default: function () {
                return []
            }
        },
        selectedBoPhanId: {
            type: Number,
            default: null
        },
        selectedBoPhan: {
            type: Object,
            default: null
        },
        activeTab: {
            type: String,
            default: 'quyen'
        },
        selectedBoPhanQuyenSummaries: {
            type: Array,
            default: function () {
                return []
            }
        },
        priorityMessage: {
            type: String,
            default: ''
        },
        nhanVienListByBoPhan: {
            type: Array,
            default: function () {
                return []
            }
        }
    },
    emits: ['add-bo-phan', 'select-bo-phan', 'edit-bo-phan', 'config-quyen', 'delete-bo-phan', 'update:activeTab', 'add-nhan-vien', 'edit-nhan-vien', 'delete-nhan-vien', 'assign-dia-diem'],
    methods: {
        emitAddBoPhan() {
            this.$emit('add-bo-phan')
        },
        emitSelectBoPhan(boPhan) {
            this.$emit('select-bo-phan', boPhan)
        },
        emitEditBoPhan(boPhan) {
            this.$emit('edit-bo-phan', boPhan)
        },
        emitConfigQuyen(boPhan) {
            this.$emit('config-quyen', boPhan)
        },
        emitDeleteBoPhan(boPhan) {
            this.$emit('delete-bo-phan', boPhan)
        },
        emitUpdateActiveTab(tab) {
            this.$emit('update:activeTab', tab)
        },
        emitAddNhanVien() {
            this.$emit('add-nhan-vien')
        },
        emitEditNhanVien(nhanVien) {
            this.$emit('edit-nhan-vien', nhanVien)
        },
        emitDeleteNhanVien(nhanVien) {
            this.$emit('delete-nhan-vien', nhanVien)
        },
        emitAssignDiaDiem(nhanVien) {
            this.$emit('assign-dia-diem', nhanVien)
        }
    }
}
</script>
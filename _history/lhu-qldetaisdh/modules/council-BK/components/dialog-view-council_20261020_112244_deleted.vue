<template>
    <div>
        <v-dialog v-model="vueData.isViewDialog" transition="dialog-bottom-transition" max-width="1024px" persistent>
            <v-card>
                <c-toolbar @onClose="vueData.isViewDialog = false">
                    <template v-slot:title>
                        <p class="title mb-0 primary--text">
                            Cập nhật HV:
                            <span class="red--text">[{{ HoiDong.Student_ID }}] {{ HoiDong.Ho_SV }} {{ HoiDong.Ten_SV }} [{{ HoiDong.Lop_ID }}] </span>
                        </p>
                    </template>
                </c-toolbar>
                <v-card-text class="mt-4">
                    <uc-table-view-hoi-dong :dshdgiangvien="DSHoiDongGiangVien" isWatch="true" />
                </v-card-text>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
export default {
    props: ['editedItem', 'dshoidonggiangvien'],
    data() {
        return {
            DSGiangVienSeleted: [],
        }
    },
    watch: {},
    mounted() {},
    computed: {
        DSHoiDongGiangVien: function () {
            return this.dshoidonggiangvien
        },
        HoiDong: function () {
            return {
                ...this.editedItem,
                ThoiGianBaoVe: this.editedItem.ThoiGianBaoVe ? moment(this.editedItem.ThoiGianBaoVe, 'YYYY-MM-DD').format('DD/MM/YYYY') : null,
            }
        },
        IsViewDialog: function () {
            return vueData.isViewDialog
        },
    },
}
</script>

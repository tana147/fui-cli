<template>
    <v-dialog v-model="vueData.isAddDialog" transition="dialog-bottom-transition" max-width="1300px" persistent>
        <v-card>
            <c-toolbar @onClose="closeDialog">
                <template v-slot:title>
                    <p class="title mb-0 primary--text">
                        Lập hội đồng HV:
                        <span class="red--text">[{{ HoiDong.Student_ID }}] {{ HoiDong.Ho_SV }} {{ HoiDong.Ten_SV }} [{{ HoiDong.Lop_ID }}] </span>
                    </p>
                </template>
            </c-toolbar>
            <v-card-text>
                <uc-table-add-single-hoi-dong
                    :dshdgiangvien="dshoidonggiangvien"
                    :isDialogClosed="vueData.isAddDialog"
                    :hoidong="HoiDong"
                    :dshedaotao="dshedaotao"
                    :hearr="hearr"
                    @onSelected="
                        (ds) => {
                            DSGiangVienSeleted = ds
                        }
                    "
                    :isdialogstate="vueData.isAddDialog"
                    :isadddialog="IsAddDialog"
                ></uc-table-add-single-hoi-dong>
            </v-card-text>
            <v-card-actions>
                <v-spacer></v-spacer>
                <div class="datePicker mr-3">
                    <f-date v-model="time" color="success" label="Ngày bảo vệ luận văn" placeholder="Ngày bảo vệ luận văn" outlined dense hide-details />
                </div>
                <v-btn color="primary" @click="addHoiDong" dark>Lập hội đồng</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ['dshoidonggiangvien', 'editedItem', 'dshedaotao', 'hearr'],
    data() {
        return {
            DSGiangVienSeleted: [],
            time: '',
        }
    },
    mounted() {},
    computed: {
        DSHoiDongGiangVien: function () {
            return this.dshoidonggiangvien
        },
        HoiDong: function () {
            return this.editedItem
        },
        IsAddDialog: function (val) {
            return vueData.isAddDialog
        },
    },
    watch: {
        IsAddDialog: function (val) {
            if (val) {
                console.log('xxxxx', this.HoiDong)
                const dataGet = loadChucTrach(this.HoiDong.Nganh_ID, this.HoiDong.Lop_ID)
                console.log('dataGet', dataGet)
            }
        },
    },
    methods: {
        addHoiDong() {
            const $this = this
            const giaTriChucTrach = new Set()

            if (this.editedItem.Process_ID === 4 ? $this.DSGiangVienSeleted.length < 3 : $this.DSGiangVienSeleted.length < 5) {
                Vue.$toast.error(`Chưa đủ thành viên hội đồng`, { position: 'top' })
                return
            }

            if ($this.time === '') {
                Vue.$toast.error(`Chưa thêm Thời gian bảo vệ`, { position: 'top' })
                return
            }

            for (const giangVien of $this.DSGiangVienSeleted) {
                if (giangVien.ChucTrach === undefined) {
                    Vue.$toast.error(`Có thành viên chưa được gán chức trách`, { position: 'top' })
                    return
                } else {
                    if (giaTriChucTrach.has(giangVien.ChucTrach)) {
                        const viTriTrungLap = $this.DSGiangVienSeleted.findIndex((item) => item.ChucTrach === giangVien.ChucTrach)
                        Vue.$toast.error(`Trùng lặp với giá trị "${giangVien.ChucTrach}"`, { position: 'top' })
                        return // Dừng xử lý nếu có phần tử trùng lặp
                    }
                    giaTriChucTrach.add(giangVien.ChucTrach)
                }
            }

            console.log('$this.DSGiangVienSeleted', $this.DSGiangVienSeleted)
            // Tiếp tục với ajaxCall chỉ khi không có phần tử trùng lặp
            ajaxCALL(
                '/HoiDong_Ins',
                {
                    Student_ID: this.editedItem.Student_ID,
                    HoiDongThanhVienObj_Arr: $this.DSGiangVienSeleted,
                    ThoiGianBaoVe: $this.time,
                },
                (res) => {
                    Vue.$toast.success(`Thêm thành công`, { position: 'top' })
                    $this.closeDialog()
                    CALL('getHoiDongDeTai')
                },
                (error) => {
                    console.log('Add hoi dong failed', error)
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                },
            )
        },
        closeDialog() {
            vueData.isAddDialog = false
            this.DSGiangVienSeleted = []
            this.time = ''
        },
    },
}
</script>

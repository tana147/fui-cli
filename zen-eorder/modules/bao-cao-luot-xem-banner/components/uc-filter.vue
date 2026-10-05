<template>
    <div>
        <v-row>
            <v-col cols="2">
                <f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
            </v-col>
            <v-col cols="2">
                <f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
            </v-col>
            <v-col cols="2">
                <v-btn color="primary" elevation="0" @click="getReportViewer"><v-icon
                        left>mdi-filter</v-icon>Tìm</v-btn>
            </v-col>
        </v-row>
    </div>
</template>
<script>
export default {
    data() {
        return {
            DataResponse: null,
            TableHeader: [
                {
                    text: "Ngày",
                    width: "150px",
                    value: "NgayFormat",
                },
                {
                    text: "Tổng mã QR",
                    value: "TongQrCode",
                    align: 'center'
                },
                {
                    text: "Lượt quét QR",
                    value: "TongQuet",
                    align: 'center'
                },
                {
                    text: 'Lượt xem trên 3s',
                    value: "TongXemLau",
                    align: 'center'
                },
                {
                    text: 'Lượt bấm chuyển',
                    value: "TongChuyen",
                    width: "100px",
                    align: 'center'
                },
                {
                    text: 'Tỷ lệ quét QR (%)/ Tổng số QR',
                    value: 'TiLeQuetQR',
                    align: 'center',
                },
                {
                    text: 'Giao Diện',
                    value: 'GiaoDien'
                }
            ],
            TuNgay: moment().format('YYYY-MM-DD'),
            DenNgay: moment().format('YYYY-MM-DD'),
            vueData
        }
    },
    mounted() {
        this.getReportViewer()
    },
    methods: {
        getReportViewer() {
            const params = {
                TuNgay: this.TuNgay,
                DenNgay: this.DenNgay
            }
            ajaxCALL('/eorder/BaoCao_KhachHang_XemPoster', params, (res) => {
                if (!res.data) return

                let { data } = res
                vueData.TableHeader = this.TableHeader

                //  tiền xử lí
                const sumScanPoster = data.reduce((sum, rowData) => sum + rowData.TongQuet, 0)
                const sumQrCode = data.reduce((sum, rowData) => sum + rowData.TongQrCode, 0)
                const sumNextView = data.reduce((sum, rowData) => sum + rowData.TongChuyen, 0)
                const percentScanPoster = ((sumScanPoster / sumQrCode) * 100).toFixed(2)

                const LuotQuetApp = data.reduce((sum, rowData) => rowData.GiaoDien == "APP" ? sum + rowData.TongQuet : sum , 0)
                const LuotQuetWeb =  data.reduce((sum, rowData) => rowData.GiaoDien == "WEB" ? sum + rowData.TongQuet : sum , 0)

                const topInterfaceByScans = {
                    name: LuotQuetApp > LuotQuetWeb ? 'APP' : 'WEB',
                    percent: (((LuotQuetApp > LuotQuetWeb ? LuotQuetApp : LuotQuetWeb) / sumQrCode) * 100).toFixed(2)
                } 
                
                vueData.DataSummary = { sumScanPoster, percentScanPoster, sumQrCode, sumNextView, topInterfaceByScans }

                vueData.DSViewer = data.map(e => ({ ...e, NgayFormat: moment(e.Ngay).format('DD/MM/YYYY'), TiLeQuetQR: `${((e.TongQuet / sumQrCode) * 100).toFixed(2)}%` }))
            })
        }
    },


}
</script>
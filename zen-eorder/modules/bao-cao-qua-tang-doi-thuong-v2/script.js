function sumFooterTable() {
    const sumFooter = {
        TongLanDoi: 0,
    }
    if (vueData.DSQuaTangNhanVien.length > 0) {
        vueData.DSQuaTangNhanVien.forEach((item) => {
            sumFooter.TongLanDoi += item.TongLanDoi
        })
    }
    vueData.DataSummary = sumFooter
}
Vue.component("uc-summary", {
    props: ["data"],
    computed: {},
    template: /*html*/ `
        <v-row class="row-report-summary">
            <v-col>
                Số lần đổi <br/> <b class="red--text">{{data?.TongLanDoi.toLocaleString('vi-vn')}}</b>
            </v-col>
        </v-row>
    `,
})
function GetDSNam() {
    const yearNow = moment().year()
    let dsYear = []
    for (let y = yearNow; y >= 2024; y--) {
        dsYear.push(y)
    }
    return dsYear
}
function handleColumnHinhThucThoiGian(HinhThucThoiGian) {
    let findIndexHeader = vueData.headers.findIndex(col => col.value && col.value == 'HinhThucThoiGian')
    if (findIndexHeader == -1) return
    vueData.headers[findIndexHeader].text = (vueData.DSHinhThucThoiGian.find(obj => obj.value == HinhThucThoiGian).text) ?? 'Hình thức thời gian'
}
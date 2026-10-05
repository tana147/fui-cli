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
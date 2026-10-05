function sumFooterTable() {
    const sumFooter = {
        TienHang: 0,
        SoTienCK: 0,
    }
    if (vueData.DSChiTietHoaDon.length > 0) {
        vueData.DSChiTietHoaDon.forEach((item) => {
            sumFooter.TienHang += item.TienHang
            sumFooter.SoTienCK += item.SoTienCK
        })
    }
    vueData.DataSummary = sumFooter
}
Vue.component("uc-summary", {
    props: ["data"],
    computed: {},
    template: /*html*/ `
        <v-row class="row-report-summary">
            <v-col cols="2">
                Tiền hàng <br/> <b class="red--text">{{data?.TienHang.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col cols="2">
                Số tiền CK <br/> <b class="red--text">{{data?.SoTienCK.toLocaleString('vi-vn')}}</b>
            </v-col>
        </v-row>
    `,
})
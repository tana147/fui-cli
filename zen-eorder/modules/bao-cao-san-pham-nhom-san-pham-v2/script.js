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
function sumFooterTable() {
    const sumFooter = {
        SoLuongBan: 0,
        DoanhThu: 0,
        SoLuongTang: 0,
        GiaTriTang: 0,
        SoLuongHuy: 0,
        TienHuy: 0,
        SoLuongDoiDiem: 0,
        TienDoiDiem: 0,
        SoLuongTra: 0,
        TienTra: 0,
    }
    if (vueData.DSChiTietHoaDon.length > 0) {
        vueData.DSChiTietHoaDon.forEach((item) => {
            sumFooter.SoLuongBan += item.SoLuongBan
            sumFooter.DoanhThu += item.DoanhThu
            sumFooter.SoLuongTang += item.SoLuongTang
            sumFooter.GiaTriTang += item.GiaTriTang
            sumFooter.SoLuongHuy += item.SoLuongHuy
            sumFooter.TienHuy += item.TienHuy
            sumFooter.SoLuongDoiDiem += item.SoLuongDoiDiem
            sumFooter.TienDoiDiem += item.TienDoiDiem
            sumFooter.SoLuongTra += item.SoLuongTra
            sumFooter.TienTra += item.TienTra
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
                Số lượng bán <br/> <b class="red--text">{{data?.SoLuongBan.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Doanh thu <br/> <b class="red--text">{{data?.DoanhThu.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Số lượng tặng <br/> <b class="red--text">{{data?.SoLuongTang.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Giá trị tặng <br/> <b class="red--text">{{data?.GiaTriTang.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Số lượng hủy <br/> <b class="red--text">{{data?.SoLuongHuy.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tiền hủy <br/> <b class="red--text">{{data?.TienHuy.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Số lượng đổi điểm <br/> <b class="red--text">{{data?.SoLuongDoiDiem.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tiền đổi điểm <br/> <b class="red--text">{{data?.TienDoiDiem.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Số lượng trả <br/> <b class="red--text">{{data?.SoLuongTra.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tiền trả <br/> <b class="red--text">{{data?.TienTra.toLocaleString('vi-vn')}}</b>
            </v-col>
        </v-row>
    `,
})
function sumFooterTable() {
    const sumFooter = {
        TienHang: 0,
        TongVAT: 0,
        TamTinh: 0,
        TongTienThanhToan: 0,
        TienChoThanhToan: 0,
        TongDiemSuDung: 0,
        TienMat: 0,
        ChuyenKhoan: 0,
        KhachTra_SPF: 0,
        KhachTra_XSM: 0,
        KhachTra_GRAB: 0,
        KhachTra_QuetThe: 0,
        KhachTra_HT1: 0,
        KhachTra_HT2: 0,
        KhachTra_HT3: 0,
        KhuyenMai: 0,
        TongTienHuy: 0,
    }
    if (vueData.DSChiTietHoaDon.length > 0) {
        vueData.DSChiTietHoaDon.forEach((item) => {
            sumFooter.TienHang += item.TienHang
            sumFooter.TongVAT += item.TongVAT
            sumFooter.TamTinh += item.TamTinh
            sumFooter.TongTienThanhToan += item.TongTienThanhToan
            sumFooter.TienChoThanhToan += item.TienChoThanhToan
            sumFooter.TongDiemSuDung += item.TongDiemSuDung
            sumFooter.TienMat += item.TienMat
            sumFooter.ChuyenKhoan += item.ChuyenKhoan
            sumFooter.KhachTra_SPF += item.KhachTra_SPF
            sumFooter.KhachTra_XSM += item.KhachTra_XSM
            sumFooter.KhachTra_GRAB += item.KhachTra_GRAB
            sumFooter.KhachTra_QuetThe += item.KhachTra_QuetThe
            sumFooter.KhachTra_HT1 += item.KhachTra_HT1
            sumFooter.KhachTra_HT2 += item.KhachTra_HT2
            sumFooter.KhachTra_HT3 += item.KhachTra_HT3
            sumFooter.KhuyenMai += item.KhuyenMai
            sumFooter.TongTienHuy += item.TongTienHuy
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
                Tiền hàng <br/> <b class="red--text">{{data?.TienHang.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tiền VAT <br/> <b class="red--text">{{data?.TongVAT.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tạm tính <br/> <b class="red--text">{{data?.TamTinh.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Chờ thanh toán <br/> <b class="red--text">{{data?.TienChoThanhToan.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                ZEN <br/> <b class="red--text">{{data?.TongDiemSuDung.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Thanh toán <br/> <b class="red--text">{{data?.TongTienThanhToan.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                TM <br/> <b class="red--text">{{data?.TienMat.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                CK <br/> <b class="red--text">{{data?.ChuyenKhoan.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                SPF <br/> <b class="red--text">{{data?.KhachTra_SPF.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Grab <br/> <b class="red--text">{{data?.KhachTra_GRAB.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                XSM <br/> <b class="red--text">{{data?.KhachTra_XSM.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                QT <br/> <b class="red--text">{{data?.KhachTra_QuetThe.toLocaleString('vi-vn')}}</b>
            </v-col>
             <v-col>
                HT1 <br/> <b class="red--text">{{data?.KhachTra_HT1.toLocaleString('vi-vn')}}</b>
            </v-col>
             <v-col>
                HT2 <br/> <b class="red--text">{{data?.KhachTra_HT2.toLocaleString('vi-vn')}}</b>
            </v-col>
             <v-col>
                HT3 <br/> <b class="red--text">{{data?.KhachTra_HT3.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                KM <br/> <b class="red--text">{{data?.KhuyenMai.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tiền hủy <br/> <b class="red--text">{{data?.TongTienHuy.toLocaleString('vi-vn')}}</b>
            </v-col>
        </v-row>
    `,
})
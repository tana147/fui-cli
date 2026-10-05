function sumFooterTable() {
    const sumFooter = {
        Tong_Ly: 0,
        Tong_LyThoaDieuKien: 0,
        TyLe: 0,
        Tong_QrTrungThuong: 0,
        Tong_ChuaQuet: 0,
        Tong_DaQuet: 0,
        Tong_ChuaNhapMaPin: 0,
        Tong_DaNhapMaPin: 0,
        Tong_ChuaDoiThuong: 0,
        Tong_DaDoiThuong: 0,
        Tong_DaDoiThuong_ThucTe: 0,
    }
    if (vueData.DSChiTietQuaTang.length > 0) {
        vueData.DSChiTietQuaTang.forEach((item) => {
            sumFooter.Tong_Ly += item.Tong_Ly
            sumFooter.Tong_LyThoaDieuKien += item.Tong_LyThoaDieuKien
            sumFooter.TyLe += item.TyLe
            sumFooter.Tong_QrTrungThuong += item.Tong_QrTrungThuong
            sumFooter.Tong_ChuaQuet += item.Tong_ChuaQuet
            sumFooter.Tong_DaQuet += item.Tong_DaQuet
            sumFooter.Tong_ChuaNhapMaPin += item.Tong_ChuaNhapMaPin
            sumFooter.Tong_DaNhapMaPin += item.Tong_DaNhapMaPin
            sumFooter.Tong_ChuaDoiThuong += item.Tong_ChuaDoiThuong
            sumFooter.Tong_DaDoiThuong += item.Tong_DaDoiThuong
            sumFooter.Tong_DaDoiThuong_ThucTe += item.Tong_DaDoiThuong_ThucTe
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
                Tổng ly <br/> <b class="red--text">{{data?.Tong_Ly.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Ly thỏa điều kiện <br/> <b class="red--text">{{data?.Tong_LyThoaDieuKien.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tỷ lệ (%) <br/> <b class="red--text">{{data?.TyLe.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Tổng QR thưởng <br/> <b class="red--text">{{data?.Tong_QrTrungThuong.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Chưa quét mã <br/> <b class="red--text">{{data?.Tong_ChuaQuet.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Đã quét mã <br/> <b class="red--text">{{data?.Tong_DaQuet.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Chưa nhập PIN <br/> <b class="red--text">{{data?.Tong_ChuaNhapMaPin.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Đã nhập PIN <br/> <b class="red--text">{{data?.Tong_DaNhapMaPin.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Chưa đổi thưởng <br/> <b class="red--text">{{data?.Tong_ChuaDoiThuong.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Đã đổi thưởng <br/> <b class="red--text">{{data?.Tong_DaDoiThuong.toLocaleString('vi-vn')}}</b>
            </v-col>
            <v-col>
                Đổi thưởng thực tế <br/> <b class="red--text">{{data?.Tong_DaDoiThuong_ThucTe.toLocaleString('vi-vn')}}</b>
            </v-col>
        </v-row>
    `,
})
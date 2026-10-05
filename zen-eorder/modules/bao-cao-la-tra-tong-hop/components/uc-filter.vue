<template>
    <v-row>
        <v-col cols="4">
            <v-select label="Phân hiệu" outlined dense v-model="PhanHieuID" :items="vueData.DSPhanHieu" item-value="PhanHieuID" item-text="TenPhanHieu" hide-details />
        </v-col>
        <v-col cols="4">
            <v-select label="Khu vực" outlined dense v-model="KhuVucID" :items="vueData.DSKhuVuc" item-value="KhuVucID" item-text="TenKhuVuc" hide-details />
        </v-col>
        <v-col cols="4">
            <v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian" hide-details />
        </v-col>
        <!-- 1: Theo giờ -->
        <v-col cols="2" v-if="HinhThucThoiGian === 1">
            <f-date label="Ngày" outlined dense v-model="Ngay" :date-add="0" hide-details />
        </v-col>
        <!-- 2: Theo ngày -->
        <v-col cols="2" v-if="HinhThucThoiGian === 2">
            <f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
        </v-col>
        <v-col cols="2" v-if="HinhThucThoiGian === 2">
            <f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
        </v-col>
        <!-- 3: Theo tuần -->
        <v-col cols="2" v-if="HinhThucThoiGian === 3">
            <v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
        </v-col>
        <v-col cols="2" v-if="HinhThucThoiGian === 3">
            <v-select label="Tháng" outlined dense v-model="Thang" :items="DSThang" hide-details />
        </v-col>
        <!-- 4: Theo quý || 5: Theo tháng -->
        <v-col cols="2" v-if="HinhThucThoiGian === 4 || HinhThucThoiGian === 5">
            <v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
        </v-col>
        <!-- 6: Theo năm -->
        <v-col cols="2" v-if="HinhThucThoiGian === 6">
            <v-select label="Từ năm" outlined dense v-model="TuNam" :items="DSNam" hide-details />
        </v-col>
        <v-col cols="2" v-if="HinhThucThoiGian === 6">
            <v-select label="Đến năm" outlined dense v-model="DenNam" :items="DSNam" hide-details />
        </v-col>
        <v-col cols="2">
            <v-btn color="primary" elevation="0" @click="getReportLaTra"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
        </v-col>
    </v-row>
</template>

<script>
export default {
    props: [],
    data: function () {
        //Lấy danh sách năm
        const yearNow = moment().year()
        let dsYear = []
        for (let y = yearNow; y >= 2024; y--) {
            dsYear.push(y)
        }
        return {
            PhanHieuID: 0,
            KhuVucID: 0,
            HinhThucThoiGian: 1, //Mặc định theo giờ
            Ngay: moment().format("YYYY-MM-DD"),
            TuNgay: moment().format("YYYY-MM-DD"),
            DenNgay: moment().format("YYYY-MM-DD"),
            Nam: yearNow,
            TuNam: yearNow,
            DenNam: yearNow,
            Thang: moment().month() + 1,
            DSNam: dsYear,
            DSThang: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            DSHinhThucThoiGian: [
                {value: 1, text: "Theo giờ"},
                {value: 2, text: "Theo ngày"},
                {value: 3, text: "Theo tuần"},
                {value: 4, text: "Theo quý"},
                {value: 5, text: "Theo tháng"},
                {value: 6, text: "Theo năm"},
            ],
            DataLaTra: [
                {
                    title: "Tổng số lượng các đơn hàng",
                    flagMap: "TongDonHang",
                },
                {
                    title: "Tổng số lượng đơn hàng thoả điều kiện",
                    flagMap: "TongDonHang_ThoaDieuKien",
                },
                {
                    title: "Tổng số lượng đơn hàng không thoả điều kiện",
                    flagMap: "TongDonHang_KhongThoaDieuKien",
                },
                {
                    title: "Tỉ lệ (Tổng số lượng đơn hàng thoả điều kiện/ Tổng số lượng các đơn hàng)",
                    flagMap: "TongDonHang_TyLe",
                },
                {
                    title: "Tổng doanh thu đơn hàng thoả điều kiện",
                    flagMap: "TongDoanhThu_ThoaDieuKien",
                },
                {
                    title: "Tổng doanh thu đơn hàng không thoả điều kiện",
                    flagMap: "TongDoanhThu_KhongThoaDieuKien",
                },
                {
                    title: "Tỉ lệ (Tổng doanh thu đơn hàng thoả điều kiện/ Tổng doanh thu các đơn hàng)",
                    flagMap: "TongDoanhThu_TyLe",
                },
                {
                    title: "Tổng số tài khoản",
                    flagMap: "TongTaiKhoan",
                },
                {
                    title: "Tổng số tài khoản có lá trà",
                    flagMap: "TongTaiKhoan_CoLaTra",
                },
                {
                    title: "Tổng số lá trà đã tích",
                    flagMap: "TongLaTra_DaTich",
                },
                {
                    title: "Tổng số lá trà đã đổi để thu hoạch",
                    flagMap: "TongLaTra_DaDoi",
                },
                {
                    title: "Tỉ lệ Tổng số lá trà đã đổi để thu hoạch/ Tổng số lá trà đã tích",
                    flagMap: "TongLaTra_TyLe",
                },
            ],
            DataLaTra_Default: [
                {
                    title: "Tổng số lượng các đơn hàng",
                    flagMap: "TongDonHang",
                },
                {
                    title: "Tổng số lượng đơn hàng thoả điều kiện",
                    flagMap: "TongDonHang_ThoaDieuKien",
                },
                {
                    title: "Tổng số lượng đơn hàng không thoả điều kiện",
                    flagMap: "TongDonHang_KhongThoaDieuKien",
                },
                {
                    title: "Tỉ lệ (Tổng số lượng đơn hàng thoả điều kiện/ Tổng số lượng các đơn hàng)",
                    flagMap: "TongDonHang_TyLe",
                },
                {
                    title: "Tổng doanh thu đơn hàng thoả điều kiện",
                    flagMap: "TongDoanhThu_ThoaDieuKien",
                },
                {
                    title: "Tổng doanh thu đơn hàng không thoả điều kiện",
                    flagMap: "TongDoanhThu_KhongThoaDieuKien",
                },
                {
                    title: "Tỉ lệ (Tổng doanh thu đơn hàng thoả điều kiện/ Tổng doanh thu các đơn hàng)",
                    flagMap: "TongDoanhThu_TyLe",
                },
                {
                    title: "Tổng số tài khoản",
                    flagMap: "TongTaiKhoan",
                },
                {
                    title: "Tổng số tài khoản có lá trà",
                    flagMap: "TongTaiKhoan_CoLaTra",
                },
                {
                    title: "Tổng số lá trà đã tích",
                    flagMap: "TongLaTra_DaTich",
                },
                {
                    title: "Tổng số lá trà đã đổi để thu hoạch",
                    flagMap: "TongLaTra_DaDoi",
                },
                {
                    title: "Tỉ lệ Tổng số lá trà đã đổi để thu hoạch/ Tổng số lá trà đã tích",
                    flagMap: "TongLaTra_TyLe",
                },
            ],
            DSQuaTang: [],
            TableHeaderQuaTang: [
                {
                    text: "Quà tặng",
                    value: "TenSanPham",
                    width: 500,
                },
                {
                    text: "Mục",
                    value: "Muc",
                    width: 300,
                },
                {text: "Tổng", value: "Tong", align: "end", width: 150, cellClass: "highlight-total"},
            ],
            TableHeaderQuaTang_Default: [
                {
                    text: "Quà tặng",
                    value: "TenSanPham",
                    width: 500,
                },
                {
                    text: "Mục",
                    value: "Muc",
                    width: 300,
                },
                {text: "Tổng", value: "Tong", align: "end", width: 150, cellClass: "highlight-total"},
            ],
        }
    },
    mounted: function () {
        this.getReportLaTra()
    },
    methods: {
        getReportLaTra() {
            const $this = this
            $this.DataLaTra = [...$this.DataLaTra_Default]
            $this.TableHeaderQuaTang = [...$this.TableHeaderQuaTang_Default]
            $this.DSQuaTang = []
            const params = {
                PhanHieuID: $this.PhanHieuID,
                KhuVucID: $this.KhuVucID,
                HinhThucThoiGian: $this.HinhThucThoiGian,
                Ngay: $this.Ngay,
                TuNgay: $this.TuNgay,
                DenNgay: $this.DenNgay,
                Nam: $this.Nam,
                TuNam: $this.TuNam,
                DenNam: $this.DenNam,
                Thang: $this.Thang,
            }

            ajaxCALL("/eorder/BaoCao_LaTra_TongQuan", params, (res) => {
                let resHeader = res.data[0]
                //Tạo aliasColumn để lấy ra tên cột động
                let aliasColumn = Object.keys(resHeader[0] ?? "")[0]
                let appendColumn = $this.parseAppendColumn(aliasColumn)
                let prefixColumn = $this.parsePrefixColumn(aliasColumn)
                //Map để xử lý tính toán tỷ lệ của dataLaTra
                let dataRes = res.data[1].map((item) => {
                    return {
                        ...item,
                        TongLaTra_TyLe: (item.TongLaTra_DaDoi / (item.TongLaTra_DaTich == 0 ? 1 : item.TongLaTra_DaTich)) * 100,
                        TongDoanhThu_TyLe: (item.TongDoanhThu_ThoaDieuKien / (item.TongDoanhThu_KhongThoaDieuKien == 0 ? 1 : item.TongDoanhThu_KhongThoaDieuKien)) * 100,
                        TongDonHang_TyLe: (item.TongDonHang_ThoaDieuKien / (item.TongDonHang == 0 ? 1 : item.TongDonHang)) * 100,
                    }
                })
                //Xử lý dữ liệu Quà tặng
                let quanTangRes = [...res.data[2]]
                const TongQuaTang = {
                    ChuongTrinhID: -404,
                    MaChuongTrinh: "TONGQUATANG",
                    TenSanPham: "Tổng quà tặng",
                }
                quanTangRes.unshift(TongQuaTang)
                //Số liệu quà tặng
                let dataQuaTangRes = [...res.data[3]]
                resHeader.forEach((item) => {
                    let dataTongQuaTang = {
                        ChuongTrinhID: -404,
                        TongChuaSuDung: dataQuaTangRes
                            .filter((record) => record[aliasColumn] == item[aliasColumn])
                            .reduce((result, record) => {
                                result += record.TongChuaSuDung
                                return result
                            }, 0),
                        TongHetHan: dataQuaTangRes
                            .filter((record) => record[aliasColumn] == item[aliasColumn])
                            .reduce((result, record) => {
                                result += record.TongHetHan
                                return result
                            }, 0),
                        TongQuaTang: dataQuaTangRes
                            .filter((record) => record[aliasColumn] == item[aliasColumn])
                            .reduce((result, record) => {
                                result += record.TongQuaTang
                                return result
                            }, 0),
                        TongSuDung: dataQuaTangRes
                            .filter((record) => record[aliasColumn] == item[aliasColumn])
                            .reduce((result, record) => {
                                result += record.TongSuDung
                                return result
                            }, 0),
                        TongThuHoach: dataQuaTangRes
                            .filter((record) => record[aliasColumn] == item[aliasColumn])
                            .reduce((result, record) => {
                                result += record.TongThuHoach
                                return result
                            }, 0),
                    }
                    dataTongQuaTang[aliasColumn] = item[aliasColumn]
                    dataQuaTangRes.push(dataTongQuaTang)
                })
                if (resHeader.length == 0 || dataRes.length == 0) return
                const dataHead = [
                    {text: "Mục", value: "title", width: 800},
                    {text: "Tổng", value: "Tong", align: "end", width: 150, cellClass: "highlight-total"},
                ]

                const dataTable = []
                //Xử lý cột động cho table header
                resHeader.forEach((head) => {
                    dataHead.push({
                        text: `${prefixColumn} ${head[aliasColumn]}${appendColumn}`,
                        value: `${aliasColumn}_${head[aliasColumn]}`,
                        align: "end",
                        width: "30px",
                    })

                    $this.TableHeaderQuaTang.push({
                        text: `${prefixColumn} ${head[aliasColumn]}${appendColumn}`,
                        value: `${aliasColumn}_${head[aliasColumn]}`,
                        align: "end",
                        width: "30px",
                    })
                })
                //Xử lý thêm tổng quà tặng và các quà tặng vào table
                quanTangRes.forEach((item, index) => {
                    let groupItemLaTra = [
                        {
                            Muc: "Đã phát hành",
                            flagMap: "TongQuaTang",
                            ChuongTrinhID: item.ChuongTrinhID,
                            TenSanPham: item.TenSanPham,
                        },
                        {
                            Muc: "Đã thu hoạch",
                            flagMap: "TongThuHoach",
                            ChuongTrinhID: item.ChuongTrinhID,
                            TenSanPham: item.TenSanPham,
                        },
                        {
                            Muc: "Đã sử dụng",
                            flagMap: "TongSuDung",
                            ChuongTrinhID: item.ChuongTrinhID,
                            TenSanPham: item.TenSanPham,
                        },
                        {
                            Muc: "Chưa sử dụng",
                            flagMap: "TongChuaSuDung",
                            ChuongTrinhID: item.ChuongTrinhID,
                            TenSanPham: item.TenSanPham,
                        },
                        {
                            Muc: "Đã hết hạn",
                            flagMap: "TongHetHan",
                            ChuongTrinhID: item.ChuongTrinhID,
                            TenSanPham: item.TenSanPham,
                        },
                    ]
                    if (item.MaChuongTrinh == "TONGQUATANG") {
                        groupItemLaTra = groupItemLaTra.map((item) => {
                            return {...item, Muc: item.Muc}
                        })
                    }
                    $this.DSQuaTang = [...$this.DSQuaTang, ...groupItemLaTra]
                })
                // //Lặp từng DataLaTra
                $this.DataLaTra.forEach((item, index) => {
                    const dataRow = {
                        title: item.title,
                        GhiChu: item.GhiChu ?? "",
                    }
                    dataRow["Tong"] = 0
                    //Lặp header
                    resHeader.forEach((head) => {
                        let dataMaping = dataRes.find((i) => i[aliasColumn] === head[aliasColumn])
                        if (!dataMaping) {
                            dataRow[`${aliasColumn}_${head[aliasColumn]}`] = 0
                            return
                        }
                        dataRow["Tong"] += dataMaping[item.flagMap]
                        dataRow[`${aliasColumn}_${head[aliasColumn]}`] = $this.formatPrice(dataMaping[item.flagMap])
                    })
                    dataRow["Tong"] = $this.formatPrice(dataRow["Tong"])
                    //Đẩy dữ liệu vào dataTable
                    dataTable.push(dataRow)
                })
                let dataQuaTang = []
                $this.DSQuaTang.forEach((item, index) => {
                    let dataRow = {...item}
                    if (dataQuaTangRes.length !== 0) {
                        dataRow["Tong"] = 0
                        //Lặp header
                        resHeader.forEach((head) => {
                            let dataMaping = dataQuaTangRes.find((i) => i[aliasColumn] === head[aliasColumn] && i.ChuongTrinhID == dataRow.ChuongTrinhID)
                            if (!dataMaping) {
                                dataRow[`${aliasColumn}_${head[aliasColumn]}`] = 0
                                return
                            }
                            dataRow["Tong"] += dataMaping[dataRow.flagMap]
                            dataRow[`${aliasColumn}_${head[aliasColumn]}`] = $this.formatPrice(dataMaping[dataRow.flagMap])
                        })
                        dataRow["Tong"] = $this.formatPrice(dataRow["Tong"])
                    }
                    dataQuaTang.push(dataRow)
                })

                // //Đẩy dữ liệu ra bảng
                vueData.TableHeader = dataHead
                vueData.DSBaoCao = dataTable
                vueData.DSQuaTang = dataQuaTang
                vueData.TableHeaderQuaTang = $this.TableHeaderQuaTang
            })
        },
        formatPrice(value) {
            const num = Number(value)
            return num.toLocaleString("en-US", {
                minimumFractionDigits: 0,
                maximumFractionDigits: 2, // hỗ trợ số thập phân dài, không ép .00
            })
        },
        parseAppendColumn(value) {
            switch (value) {
                case "Gio":
                    return "H"
                default:
                    return ""
            }
        },
        parsePrefixColumn(value) {
            switch (value) {
                case "SoTuan":
                    return "Tuần"
                case "Quy":
                    return "Quý"
                case "Nam":
                    return "Năm"
                case "Thang":
                    return "Tháng"
                default:
                    return ""
            }
        },
    },
}
</script>

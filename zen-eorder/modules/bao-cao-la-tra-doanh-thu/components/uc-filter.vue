<template>
    <v-row>
        <v-col cols="4">
            <v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian"
                hide-details />
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
            <v-btn color="primary" elevation="0" @click="getReport"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
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
                { value: 1, text: "Theo giờ" },
                { value: 2, text: "Theo ngày" },
                { value: 3, text: "Theo tuần" },
                { value: 4, text: "Theo quý" },
                { value: 5, text: "Theo tháng" },
                { value: 6, text: "Theo năm" },
            ],
        }
    },
    mounted: function () {},
    methods: {
        getReport: function () {
	            const $this = this
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
	            ajaxCALL("/eordertest/BaoCao_LaTra_DoanhThuSanPham_ThoaDieuKien", params, (res) => {
	                const resHeader = res.data[0] ?? []
	                const resData = res.data[1] ?? []
	                const dataHead = [
	                    { text: "Nhóm sản phẩm", value: "TenNhomSanPham" },
	                    { text: "Tên món", value: "TenSanPham" },
                        { text: "Tổng", value: "Total" , align: "end",width: "100px"},
	                ]
	
	                const dataTable = []
	                const distinctNhomSanPham = [...new Set(resData.map(item => item.TenNhomSanPham))]
	                const distinctSanPham = [...new Set(resData.map(item => item.TenSanPham))]
	                //Tạo header 
	                const aliasColumn = Object.keys(resHeader[0])[0]
	                let appendColumn = $this.parseAppendColumn(aliasColumn)
	                let prefixColumn = $this.parsePrefixColumn(aliasColumn)
	
	                resHeader.forEach(item => {
	                    let objectColumn = {
	                        text: `${prefixColumn} ${item[aliasColumn]}${appendColumn}`,
	                        value: `${aliasColumn}_${item[aliasColumn]}`,
	                        align: "end",
	                        width: "100px"
	                    }
	                    dataHead.push(objectColumn)
	                })
	                //Tạo data
	                distinctNhomSanPham.forEach(cuaHang => {
	                    distinctSanPham.forEach(quaTang => {
	                        let objCuaHang = {
	                            TenNhomSanPham: cuaHang,
                                TenSanPham:quaTang,
                                Total: 0
	                        }
	                        let dataQuaTangCuaHang = resData.filter(item => item.TenNhomSanPham === cuaHang && item.TenSanPham === quaTang)
	                        if (dataQuaTangCuaHang.length === 0) {
	                            return
	                        }
	                        resHeader.forEach(header => {
	                            objCuaHang[`${aliasColumn}_${header[aliasColumn]}`] = dataQuaTangCuaHang.find(item => item[aliasColumn] === header[aliasColumn])?.DoanhThu ? formatPrice(dataQuaTangCuaHang.find(item => item[aliasColumn] === header[aliasColumn])?.DoanhThu) : 0
                                objCuaHang.Total += objCuaHang[`${aliasColumn}_${header[aliasColumn]}`]
                            })
                             objCuaHang.Total = formatPrice(objCuaHang.Total)
	                        dataTable.push(objCuaHang)
	                    })
	                })
	                //Đẩy dữ liệu ra bảng
	                vueData.TableHeader = dataHead
	                vueData.DSBaoCao = dataTable
	            })
	        },
	        parseAppendColumn(value) {
	            switch (value) {
	                case 'Gio':
	                    return 'H';
	                default:
	                    return '';
	            }
	        },
	        parsePrefixColumn(value) {
	            switch (value) {
	                case 'Tuan':
	                    return 'Tuần';
	                case 'Quy':
	                    return 'Quý';
	                case 'Nam':
	                    return 'Năm';
	                case 'Thang':
	                    return 'Tháng';
	                default:
	                    return '';
	            }
	        }
    },
}
</script>

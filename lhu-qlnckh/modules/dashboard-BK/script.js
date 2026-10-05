const ColorTrongNuoc = "#4db8ff"
const ColorQuocTe = "#ffa64d"
function getColorFromLoaiAnPham(LoaiAnPhamID) {
    switch (LoaiAnPhamID) {
        case 0:
            return "#ff6384"
        case 1:
            return "#ffb1c1"
        case 2:
            return "#36a2eb"
        case 3:
            return "#ffe6aa"
        case 4:
            return "#a5dfdf"
        case 5:
            return "#ccb2ff"
        case 6:
            return "#e4e5e7"
        case 7:
            return "#a0d911"
        case 8:
            return "#13c2c2"
        case 9:
            return "#eb2f96"
        case 10:
            return "#ffcf9f"
    }
}
function initMode() {
    let modeLocalStorage = localStorage.getItem('mode')
    if (modeLocalStorage) {
        vueData.mode = modeLocalStorage === true
    } else {
        localStorage.setItem('mode', false)
    }
}
function isRightAdmin() {
    let flag = false
    let groupID = vueData.user.GroupID
    vueData.SystemRight = [1, 2, 9]
    if (groupID === 1) {
        //Quản trị ko có quyền
        if (vueData.user.SystemRight === null) {
            return true
        }
        if (vueData.SystemRight.indexOf(vueData.user.SystemRight) === -1) {
            return true
        }
        return false
    }
    return flag
}
function checkRole() {
    // 1: là quản trị
    // 2: là học viên
    let groupID = vueData.user.GroupID
    let systemRight = vueData.user.SystemRight
    if (groupID === 2) {
        confirm({
            title: "Thông báo",
            content: "Tài khoản của bạn không có quyền truy cập chức năng này",
            action: () => {
                redirect({ url: "https://me.lhu.edu.vn" })
            },
            cancel: false
        })
    } else if (groupID === 1) {
        let arrSystemRight = [1, 2, 9]
        if (arrSystemRight.indexOf(systemRight) === -1) {
            redirect({ url: window.origin + "/papers-reward" })
        }
    }
}
function jsonToExcel_custom(Obj) {
    if (typeof XLSX == 'undefined') {
        var loadScript = new Loader();
        loadScript.require(["/include/xlsx/xlsx.full.min.js"], function () {
            writeExcelFile(Obj);
        });
    } else writeExcelFile(Obj);
    function writeExcelFile(inputObj) {
        var props = {
            title: [],
            data: null, // Json to download
            filename: "", // filename to export
            worksheet: "SheetFP"
        }
        Object.assign(props, inputObj);
        if (!props.data || !props.data.length) {
            showMessage({ title: "Data Null" })
            return;
        }
        var worksheet = XLSX.utils.json_to_sheet(props.data, {
            header: props.title
        });
        var workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, props.worksheet);
        XLSX.writeFile(workbook, props.filename);
    }
}
Vue.component("uc-anpham-khenthuong", {
    props: ["mode", "datachartpiesummary", "datachartlinedetailsummary", "datachartcolumndetailsummary", "optionSummary", "optionDetailSummary", "optionTrongNuocSummary", "optionQuocTeSummary", "datachartpietrongnuoc", "datachartpiequocte", "plugin"],
    data() {
        const datasetLines = this.datachartlinedetailsummary.reduce((acc, item) => {
            const { TenLoaiAnPham, Nam, SL_BB, LoaiAnPhamID } = item;
            const existingItem = acc.find(entry => entry.label === TenLoaiAnPham);
            if (existingItem) {
                existingItem.data.push(SL_BB);
            } else {
                const newItem = {
                    label: TenLoaiAnPham,
                    data: [SL_BB],
                    type: 'line',
                    backgroundColor: getColorFromLoaiAnPham(LoaiAnPhamID),
                    borderColor: getColorFromLoaiAnPham(LoaiAnPhamID),
                    LoaiAnPhamID: LoaiAnPhamID
                };
                acc.push(newItem);
            }
            return acc;
        }, []);
        const quocTeData = this.datachartcolumndetailsummary.map(item => item.SL_QuocTe);
        const trongNuocData = this.datachartcolumndetailsummary.map(item => item.SL_TrongNuoc);
        const datasetColumn = [
            {
                label: "Trong nước",
                data: trongNuocData,
                stack: 'combined',
                type: 'bar',
                backgroundColor: ColorTrongNuoc,
                borderColor: ColorTrongNuoc,
                LoaiAnPhamID: "TrongNuoc"
            }, {
                label: "Quốc tế",
                data: quocTeData,
                stack: 'combined',
                type: 'bar',
                backgroundColor: ColorQuocTe,
                borderColor: ColorQuocTe,
                LoaiAnPhamID: "QuocTe"
            }]
        const combineData = [...datasetLines, ...datasetColumn]
        const result = combineData.map(item => {
            const sum = item.data.reduce((sum, cur) => sum + cur, 0)
            const phantram = (sum / this.datachartpiesummary.SL_Tong * 100).toFixed(2) + "%"
            item.IsSelected = false
            return { ...item, sum: sum, PhanTram: phantram }
        })
        return {
            Is_Show_ChartCT: false,
            IsShowLabel: false,
            IsShowDetail: false,
            Elevation_0: "elevation-0",
            DataVChipSummary: result,
            LoaiAnPhamID: 1,
            headerTrongNuocQuocTe: [{ text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" }, { text: "Số lượng bài báo", value: "SL_BB" }],
            headerChiTietTrongNuocQuocTe: [{ text: "STT", value: "STT" }, { text: "Năm", value: "Nam" }, { text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" }, { text: "Số lượng bài báo", value: "SL_BB" }],
            TableSelected: [],
            itemKey: null,
            titleTable: "",
            headers: [],
            items: [],
            widthSize: 0,
            DataChartLine: {
                labels: [],
                datasets: [
                    {
                        label: "Tổng số bài báo",
                        type: "bar",
                        data: []
                    },
                    {
                        label: "Bài đăng trong nước",
                        type: "bar",
                        data: [
                        ]
                    },
                    {
                        label: "Bài đăng quốc tế",
                        type: "bar",
                        data: [
                        ]
                    }
                ]
            },
            OptionChartLine: {
                legend: {
                    display: false
                }
            },
            TongSoBaiBao: 0,
            TongSoBaiBaoTrongNuoc: 0,
            TongSoBaiBaoQuocTe: 0,
            Is_Show_SoLieuCT: false,
            Headers_SoLieuCT: [
                { text: "STT", value: "SoThuTu" },
                { text: "Tên tác giả", value: "TenTacGia" },
                { text: "Đơn vị", value: "TenDonVi" },
                { text: "Tên bài báo", value: "TenBaiBao" },
                { text: "Tên tạp chí/ Hội thảo", value: "TenTapChiHoiThao" },
                { text: "Năm học", value: "NamHoc", width: "150px" },
                { text: "Nơi đăng", value: "NoiDang" },
                { text: "Thể loại", value: "TheLoai" },
                { text: "Ghi chú", value: "GhiChu" },
            ],
            Data_SoLieuCT: [],
            Data_BBKH: [],
            Data_LoaiAnPham: [],
            optionChartPie: {
                responsive: true,
                plugins: {
                    title: {
                        display: false,
                        text: `Tổng bài báo trong nước và quốc tế `,
                        font: {
                            size: 16,
                        }
                    },
                    legend: {
                        position: 'bottom',
                    },
                    datalabels: {
                        color: "#ffffff",
                        font: {
                            size: 18,
                        },
                    },
                },
            },
            dataChartPie: {
                datasets: [{
                    data: []
                }],
                // These labels appear in the legend and in the tooltips when hovering different arcs
                labels: []
            }
        }
    },
    computed: {
        DataChartPieSummary: function () {
            if (this.datachartpiesummary) {
                const param = {
                    "labels": ["Trong nước", "Quốc tế"],
                    "datasets": [{
                        "data": [this.datachartpiesummary.SL_TrongNuoc, this.datachartpiesummary.SL_QuocTe]
                    }]
                }
                return param
            }
        },
        DataChartPieTrongNuocSummary: function () {
            if (this.datachartpietrongnuoc) {
                const labels = this.datachartpietrongnuoc.map(item => item.TenLoaiAnPham.toString())
                const datasets = this.datachartpietrongnuoc.map(item => item.SL_BB)
                const colorPie = this.datachartpietrongnuoc.map(item => {
                    return getColorFromLoaiAnPham(item.LoaiAnPhamID)
                })
                const param = {
                    "labels": labels,
                    "datasets": [{
                        data: datasets,
                        backgroundColor: colorPie
                    }],
                }
                return param
            }
        },
        DataChartPieQuocTeSummary: function () {
            if (this.datachartpiequocte) {
                const labels = this.datachartpiequocte.map(item => item.TenLoaiAnPham.toString())
                const datasets = this.datachartpiequocte.map(item => item.SL_BB)
                const colorPie = this.datachartpiequocte.map(item => {
                    return getColorFromLoaiAnPham(item.LoaiAnPhamID)
                })
                const param = {
                    "labels": labels,
                    "datasets": [{
                        data: datasets,
                        backgroundColor: colorPie
                    }]
                }
                return param
            }
        },
        DataChartLineDetailSummary: function () {
            if (this.datachartlinedetailsummary && this.datachartcolumndetailsummary) {
                const labels = [...new Set(this.datachartlinedetailsummary.map(item => item.Nam.toString()))]
                const datasetLines = this.datachartlinedetailsummary.reduce((acc, item) => {
                    const { TenLoaiAnPham, Nam, SL_BB, LoaiAnPhamID } = item;
                    const existingItem = acc.find(entry => entry.label === TenLoaiAnPham);
                    if (existingItem) {
                        existingItem.data.push(SL_BB);
                    } else {
                        const newItem = {
                            label: TenLoaiAnPham,
                            data: [SL_BB],
                            type: 'line',
                            backgroundColor: getColorFromLoaiAnPham(LoaiAnPhamID),
                            borderColor: getColorFromLoaiAnPham(LoaiAnPhamID)
                        };
                        acc.push(newItem);
                    }
                    return acc;
                }, []);
                const quocTeData = this.datachartcolumndetailsummary.map(item => item.SL_QuocTe);
                const trongNuocData = this.datachartcolumndetailsummary.map(item => item.SL_TrongNuoc);
                const datasetColumn = [
                    {
                        label: "Trong nước",
                        data: trongNuocData,
                        stack: 'combined',
                        type: 'bar',
                        backgroundColor: ColorTrongNuoc,
                        borderColor: ColorTrongNuoc
                    }, {
                        label: "Quốc tế",
                        data: quocTeData,
                        stack: 'combined',
                        type: 'bar',
                        backgroundColor: ColorQuocTe,
                        borderColor: ColorQuocTe
                    }
                ]
                const param = {
                    "labels": labels,
                    "datasets": [...datasetLines, ...datasetColumn]
                }
                return param
            }
        },
        DataChartTrongNuocMostSummary: function () {
            if (this.datachartpietrongnuoc) {
                let arr = JSON.parse(JSON.stringify(this.datachartpietrongnuoc))
                arr = arr.sort((a, b) => b.SL_BB - a.SL_BB);
                // Thêm phần trăm chiếm được vào mỗi phần tử
                arr.forEach(element => {
                    element.PhanTram = ((element.SL_BB / this.datachartpiesummary.SL_TrongNuoc) * 100).toFixed(2) + "%";
                });
                return arr
            }
        },
        DataChartQuocTeMostSummary: function () {
            if (this.datachartpiequocte) {
                let arr = JSON.parse(JSON.stringify(this.datachartpiequocte))
                arr = arr.sort((a, b) => b.SL_BB - a.SL_BB);
                // Thêm phần trăm chiếm được vào mỗi phần tử
                arr.forEach(element => {
                    element.PhanTram = ((element.SL_BB / this.datachartpiesummary.SL_QuocTe) * 100).toFixed(2) + "%";
                });
                return arr
            }
        },
        DataTongSummary: function () {
            if (this.datachartpiesummary) {
                let obj = this.datachartpiesummary
                obj.PhanTramQuocTe = (obj.SL_QuocTe / obj.SL_Tong * 100).toFixed(2) + "%"
                obj.PhanTramTrongNuoc = (obj.SL_TrongNuoc / obj.SL_Tong * 100).toFixed(2) + "%"
                obj.IsSelectedQuocTe = false;
                obj.IsSelectedTrongNuoc = false;
                return obj
            }
        },
        DataSummary: function () {
        },
        DataToExecel: function () {
            let convertChartColumnQuocTe = this.datachartcolumndetailsummary.map(item => {
                return {
                    Nam: parseInt(item.Nam),
                    LoaiAnPhamID: 'QuocTe',
                    TenLoaiAnPham: "Quốc Tế",
                    SL_BB: item.SL_QuocTe,
                }
            })
            let convertChartColumnTrongNuoc = this.datachartcolumndetailsummary.map(item => {
                return {
                    Nam: parseInt(item.Nam),
                    LoaiAnPhamID: 'TrongNuoc',
                    TenLoaiAnPham: "Trong Nước",
                    SL_BB: item.SL_TrongNuoc,
                }
            })
            let arr = [...this.datachartlinedetailsummary, ...convertChartColumnQuocTe, ...convertChartColumnTrongNuoc]
            let arrSelected = this.DataSummary.filter(item => !item.IsSelected).map(item => item.LoaiAnPhamID)
            const result = arr.filter(item => arrSelected.includes(item.LoaiAnPhamID));
            return result
        },
        DataSortTNQTSummary: function () {
            if (this.datachartpietrongnuoc && this.datachartpiequocte) {
                const trongnuoc = [...this.datachartpietrongnuoc]
                const quocte = [...this.datachartpiequocte]
                return {
                    TrongNuoc: trongnuoc.sort((a, b) => b.SL_BB - a.SL_BB),
                    QuocTe: quocte.sort((a, b) => b.SL_BB - a.SL_BB)
                }
            }
        }
    },
    mounted() {
        const chart = this.$refs.chartColumn.myChart
        this.API_RPT_BBKH_GroupBy_NamHoc()
        this.API_RPT_BBKH_Summary_ByLoaiAnPhamID()
        this.API_AnPham_LoaiAnPham_Get()
        chart.options.plugins.datalabels.display = false
        chart.update()
        this.widthSize = window.innerWidth
        window.addEventListener("resize", () => {
            this.widthSize = window.innerWidth
        });
    },
    created() {
    },
    watch: {
        IsShowLabel: function (value) {
            const chart = this.$refs.chartColumn.myChart
            chart.options.plugins.datalabels.display = value;
            chart.update()
        },
        widthSize: function (val) {
            const chartTN = this.$refs.chartPieTrongNuoc.myChart
            const charQT = this.$refs.chartPieQuocTe.myChart
            //giao diện điện thoại
            if (val < 600) {
                chartTN.options.plugins.legend.position = "bottom"
                charQT.options.plugins.legend.position = "bottom"
            }//giao diện máy tính bảng
            else if (val < 960) {
                chartTN.options.plugins.legend.position = "bottom"
                charQT.options.plugins.legend.position = "bottom"
            }//giao diện máy laptop
            else if (val < 1264) {
                chartTN.options.plugins.legend.position = "bottom"
                charQT.options.plugins.legend.position = "bottom"
            }//giao diện PC
            else {
                chartTN.options.plugins.legend.position = "bottom"
                charQT.options.plugins.legend.position = "bottom"
            }
            chartTN.update()
            charQT.update()
        }
    },
    methods: {
        toExcelBBKH() {
            jsonToExcel({ data: this.Data_BBKH, filename: "ThongKeBaiBao.xlsx" });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },
        toExcelBBKH_Upgrade() {
            const $this = this
            var loadScript = new Loader()
            //sheet tổng hợp
            const initTitleColumn = [
                "STT",
                "Tên tác giả Lạc Hồng",
                "Đơn vị",
                "Tên bài báo",
                "Tên tạp chí/ hội thảo",
                "Năm đăng",
                "Năm học",
                "Nơi đăng",
                "IF/Điểm HĐGSNN",
                "Thể loại đăng",
                "Ghi chú"
            ]
            const titleColumn = [initTitleColumn]
            let handleFormatData = $this.Data_SoLieuCT.map(item => {
                return {
                    SoThuTu: item.SoThuTu,
                    TenTacGia: item.TenTacGia,
                    TenDonVi: item.TenDonVi,
                    TenBaiBao: item.TenBaiBao,
                    TenTapChiHoiThao: item.TenTapChiHoiThao,
                    NamDang: item.NamDang,
                    NamHoc: item.NamHoc,
                    NoiDang: item.NoiDang,
                    IFDiemHDGSNN: item.IFDiemHDGSNN,
                    TheLoai: item.TheLoai,
                    GhiChu: item.GhiChu
                }
            })
            const keyDataExcel = Object.keys(handleFormatData[0])
            console.log('handleFormatData', handleFormatData)
            loadScript.require(['/include/xlsx/xlsx.full.min.js'], function () {
                var workbook = XLSX.utils.book_new()
                let dataGroupByNamHoc = _.groupBy(handleFormatData, 'NamHoc')
                let keyGroupByNamHoc = Object.keys(dataGroupByNamHoc)
                //BEGIN xử lý data từng sheet của file
                let tabs =
                    [
                        {
                            tabName: "Tổng hợp",
                            header: keyDataExcel,
                            nameHeader: titleColumn,
                            data: handleFormatData
                        }
                    ]
                for (let i = 0; i <= keyGroupByNamHoc.length - 1; i++) {
                    let obj = {
                        tabName: keyGroupByNamHoc[i],
                        header: keyDataExcel,
                        nameHeader: titleColumn,
                        data: dataGroupByNamHoc[keyGroupByNamHoc[i]]
                    }
                    tabs.push(obj)
                }
                //END xử lý data từng sheet của file
                //Ghi file
                for (var item of tabs) {
                    if (item.header && item.header.length > 0) {
                        writeExcelFile(workbook,
                            item.data,
                            item.nameHeader, item.tabName
                        )
                    } else {
                        writeExcelFile(workbook,
                            [],
                            item.nameHeader, item.tabName
                        )
                    }
                }
                XLSX.writeFile(workbook, 'Danh-sach-bai-bao.xlsx')
            })
            function writeExcelFile(workbook, data, headers, nameSheet) {
                var worksheet = XLSX.utils.json_to_sheet(data, { origin: 'A2', skipHeader: true })
                XLSX.utils.sheet_add_aoa(worksheet, headers, { origin: 'A1' })
                XLSX.utils.book_append_sheet(workbook, worksheet, nameSheet)
            }
        },
        API_RPT_BBKH_GroupBy_NamHoc() {
            ajaxCALL('/RPT_BBKH_GroupBy_NamHoc', {}, (res) => {
                this.DataChartLine.labels = res.data[0].map(item => { return item.NamHoc })
                this.DataChartLine.datasets[0].data = res.data[0].map(item => { return item.SL_Tong })
                this.DataChartLine.datasets[1].data = res.data[0].map(item => { return item.SL_TrongNuoc })
                this.DataChartLine.datasets[2].data = res.data[0].map(item => { return item.SL_QuocTe })
                this.Data_BBKH = res.data[0]
                this.Data_SoLieuCT = res.data[1]
                res.data[0].forEach(item => {
                    this.TongSoBaiBao += item.SL_Tong
                    this.TongSoBaiBaoTrongNuoc += item.SL_TrongNuoc
                    this.TongSoBaiBaoQuocTe += item.SL_QuocTe
                })
            }, (err) => {
            })
        },
        toogleLegend(item, index) {
            item.IsSelected = !item.IsSelected
            const chart = this.$refs.chartColumn.myChart
            const currentVisibility = chart.getDatasetMeta(index).hidden;
            chart.getDatasetMeta(index).hidden = !currentVisibility;
            chart.update();
        },
        setItemsTable(headers, items, title, itemKey) {
            const text = "Xem chi tiết"
            this.TableSelected = []
            this.titleTable = text + " " + title
            this.headers = headers
            this.items = items
            this.itemKey = itemKey
            this.IsShowDetail = true
        },
        API_RPT_BBKH_Summary_ByLoaiAnPhamID() {
            if (this.LoaiAnPhamID) {
                ajaxCALL('/RPT_BBKH_Summary_ByLoaiAnPhamID', {
                    LoaiAnPhamID: this.LoaiAnPhamID
                }, (res) => {
                    this.dataChartPie.datasets[0].data = res.data.map(item => { return item.SL_BB })
                    this.dataChartPie.labels = res.data.map(item => { return item.Col_Name })
                })
            }
        },
        API_AnPham_LoaiAnPham_Get() {
            ajaxCALL('/AnPham_LoaiAnPham_Get', {
            }, (res) => {
                this.Data_LoaiAnPham = res.data
            })
        }
    },
    template: `
        <uc-dcard
            title="2.1 Ấn phẩm khoa học công nghệ"
            :loading="vueData.IsLoadingAnPhamSummary"
            detailTitle="Xem chi tiết"
            :hrefDetailTitle="window.location.origin + '/bai-bao-khoa-hoc'"
        >
            <template v-slot:renderBody>
                 <v-row>
                    <v-col cols="12"  sm="4" >
                        <uc-card-item
                            title="Tổng số ấn phẩm trong nước và quốc tế"
                            :description="datachartpiesummary?.SL_Tong"
                            trailingIcon="mdi-earth"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="12"  sm="4" >
                        <uc-card-item
                            title="Tổng số ấn phẩm trong nước"
                            :description="datachartpiesummary?.SL_TrongNuoc"
                            trailingIcon="mdi-town-hall"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="12"  sm="4" >
                        <uc-card-item
                            title="Tổng số ấn phẩm quốc tế"
                            :description="datachartpiesummary?.SL_QuocTe"
                            trailingIcon="mdi-web"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="12"  sm="4">
                        <uc-dchart-card
                            title="Tổng ấn phẩm trong nước và quốc tế"
                        >
                            <template v-slot:renderBody>
                                <uc-chart ref="chartPieSummary" type="pie" :data="DataChartPieSummary" :options="optionSummary" :plugins="plugin"></uc-chart>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <v-col cols="12"  sm="4">
                        <uc-dchart-card
                            title="Tổng ấn phẩm trong nước"
                            :detailTitle="DataTongSummary?.PhanTramTrongNuoc"
                        >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerTrongNuocQuocTe, datachartpietrongnuoc, 'Trong nước','LoaiAnPhamID')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                                <uc-chart ref="chartPieTrongNuoc" type="doughnut" :data="DataChartPieTrongNuocSummary" :options="optionTrongNuocSummary" :plugins="plugin"></uc-chart>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <v-col cols="12" sm="4">
                        <uc-dchart-card
                            title="Tổng ấn phẩm quốc tế"
                            :detailTitle = "DataTongSummary?.PhanTramQuocTe"
                        >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerTrongNuocQuocTe, datachartpiequocte, 'Quốc tế','LoaiAnPhamID')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                                <uc-chart ref="chartPieQuocTe" type="doughnut" :data="DataChartPieQuocTeSummary" :options="optionQuocTeSummary" :plugins="plugin"></uc-chart>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <v-col cols="12"  md="12" lg="12">
                          <uc-dchart-card title="Biểu đồ thống kê ấn phẩm Khoa học qua các năm">
                         <!--   <template v-slot:renderExcel>
                             <v-btn class="mr-6" icon color="primary" @click="toExcelBBKH">
				            <v-icon>mdi-microsoft-excel</v-icon>
			            </v-btn>
                            </template> -->
                              <template v-slot:renderBody>
                                  <uc-chart-line :datachartline="DataChartLine" :optionchartline="OptionChartLine"></uc-chart-line>
                                     <div class="responsive-mobile-chip d-flex align-center justify-center mt-5" style="width:100%;">
                                          <v-chip color="primary">Tổng số ấn phẩm: {{TongSoBaiBao}}</v-chip>
                                          <v-chip color="warning" class="mr-3 ml-3">Bài đăng trong nước: {{TongSoBaiBaoTrongNuoc}}</v-chip>
                                          <v-chip color="success">Bài đăng quốc tế: {{TongSoBaiBaoQuocTe}}</v-chip>
                                     </div>
                                     <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                        <v-switch v-model="Is_Show_SoLieuCT" color="primary" label="Xem số liệu"></v-switch>
                                     </div>
                                    <v-btn class="mr-6" icon color="primary" @click="toExcelBBKH_Upgrade" style="display:none">
				                        <v-icon>mdi-microsoft-excel</v-icon>
			                        </v-btn>
                                    <f-table v-if="Is_Show_SoLieuCT" label="Số liệu chi tiết" :items="Data_SoLieuCT" :mobile-breakpoint="600"  :items-per-page= "50"
                                      :footer-props= "{'items-per-page-options':[50, 100, 200 ,-1]}" :headers="Headers_SoLieuCT" class="mt-5"
                                      :fixed-header= "true" :fixed-cols= "2" :calculate-widths= "true" outlined :show-search="true" :excel="true">
                                    </f-table>
                              </template>
                          </uc-dchart-card>
                    </v-col>
                    <v-col cols="12" lg="4" md="12">
                        <v-row style="height:100%">
                            <v-col cols="12" md="6" lg="12">
                                <uc-card-list
                                    title="Ấn phẩm trong nước"
                                    :detailTitle="datachartpiesummary?.SL_TrongNuoc"
                                    iconTopList="mdi-newspaper"
                                    :titleTopList="DataChartTrongNuocMostSummary[0]?.SL_BB"
                                    :desciptionTopList="DataChartTrongNuocMostSummary[0]?.TenLoaiAnPham"
                                >
                                    <template v-slot:rightTitle>
                                        <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerTrongNuocQuocTe, DataSortTNQTSummary.TrongNuoc, 'Trong nước','LoaiAnPhamID')">
                                        </uc-btn>
                                    </template>
                                    <template v-slot:renderBody>
                                        <v-row v-for="(item, index) in DataChartTrongNuocMostSummary" :key="index">
                                            <v-col cols="12" class="pt-0 pb-0"><v-divider></v-divider></v-col>
                                            <v-col cols="5">{{item.TenLoaiAnPham}}</v-col>
                                            <v-col cols="2">{{item.SL_BB}}</v-col>
                                            <v-col>
                                                <v-progress-linear
                                                    :value="item.PhanTram"
                                                    color="primary"
                                                    height="25"
                                                    rounded
                                                >
                                                    <div >{{item?.PhanTram}}</div>
                                                </v-progress-linear>
                                            </v-col>
                                        </v-row>
                                    </template>
                                </uc-card-list>
                            </v-col>
                            <v-col cols="12" md="6" lg="12">
                                <uc-card-list
                                    title="Ấn phẩm quốc tế"
                                    :detailTitle="datachartpiesummary?.SL_QuocTe"
                                    iconTopList="mdi-newspaper"
                                    :titleTopList="DataChartQuocTeMostSummary[0]?.SL_BB"
                                    :desciptionTopList="DataChartQuocTeMostSummary[0]?.TenLoaiAnPham"
                                >
                                    <template v-slot:rightTitle>
                                        <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerTrongNuocQuocTe, DataSortTNQTSummary.QuocTe, 'Quốc Tế','LoaiAnPhamID')">
                                        </uc-btn>
                                    </template>
                                    <template v-slot:renderBody>
                                        <v-row v-for="(item, index) in DataChartQuocTeMostSummary" :key="index">
                                        <v-col cols="12" class="pt-0 pb-0"><v-divider></v-divider></v-col>
                                            <v-col cols="5">{{item.TenLoaiAnPham}}</v-col>
                                            <v-col cols="2">{{item.SL_BB}}</v-col>
                                            <v-col>
                                                <v-progress-linear
                                                    :value="item.PhanTram"
                                                    color="primary"
                                                    height="25"
                                                    rounded
                                                >
                                                    <div>{{item?.PhanTram}}</div>
                                                </v-progress-linear>
                                            </v-col>
                                        </v-row>
                                    </template>
                                </uc-card-list>
                            </v-col>
                        </v-row>
                    </v-col>
                    <v-col cols="12"  md="12" lg="8">
                        <uc-dchart-card
                            title="Biểu đồ thống kê các ấn phẩm Khoa học Công nghệ"
                        >
                            <template v-slot:rightTitle>
                                <div class="d-flex" style="gap:10px">
                                    <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerChiTietTrongNuocQuocTe, datachartlinedetailsummary, '', 'STT')">
                                    </uc-btn>
                                </div>
                            </template>
                            <template v-slot:checkboxShowNumber>
                                <v-checkbox v-model="IsShowLabel" class="mt-0" style=" align-items: center;" label="Hiển thị số trên biểu đồ" hide-details ></v-checkbox>
                            </template>
                            <template v-slot:renderBody>
                                <uc-chart ref="chartColumn" type="bar" :data="DataChartLineDetailSummary" :options="optionDetailSummary" :plugins="plugin" ></uc-chart>
                                <v-chip class="ml-1 mb-1" v-for="(item, index) in DataVChipSummary" :color="item.IsSelected ? 'gray' : item.backgroundColor" @click="toogleLegend(item, index)">
                                    <span :style="{'text-decoration': item.IsSelected ? 'line-through' : 'unset'}">{{item.label}}: <b> {{item.PhanTram}}</b></span>
                                </v-chip>
                                <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                    <v-switch v-model="Is_Show_ChartCT" color="primary" label="Xem chi tiết"></v-switch>
                                </div>
                            <uc-dchart-card v-if="Is_Show_ChartCT" :elevation="Elevation_0"  style="width: 100%"  >
                                <template v-slot:leftTitle>
                                     <div class="d-flex" style="gap:10px">
                                         <v-select v-model="LoaiAnPhamID" label="Danh mục bài báo/ấn phẩm" :items="Data_LoaiAnPham" item-text="TenLoaiAnPham" item-value="LoaiAnPhamID" outlined dense hide-details style="width:350px" @change="API_RPT_BBKH_Summary_ByLoaiAnPhamID()"></v-select>
                                     </div>
                                </template>
                                <template v-slot:renderBody>
                                    <div class="d-flex justify-center" style="width:100%">
                                        <div  style="width:400px;">
                                            <uc-chart v-if="dataChartPie.datasets[0].data.length > 0"  ref="chartPie" type="pie" :data="dataChartPie" :options="optionChartPie" ></uc-chart>
                                            <h3 v-else style="text-align:center">Không có dữ liệu!</h3>
                                        </div>
                                    </div>
                                </template>
                            </uc-dchart-card>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                </v-row>
                <uc-dialog v-model="IsShowDetail"
                    :title="titleTable"
                >
                    <template v-slot:renderBody>
                        <uc-dtable
                            v-model="TableSelected"
                            :headers="headers"
                            :items="items"
                            isSearch="true"
                            isSelect="true"
                            :itemKey="itemKey"
                        ></uc-dtable>
                    </template>
                </uc-dialog>
            </template>
        </uc-dcard>
    `
})
Vue.component("uc-cgcn", {
    props: ["datacharthopdong", "datachartdonvitiepnhan", "optionHopDong", "optionDonViTiepNhan", "plugin"],
    data() {
        return {
            headers: [
                {
                    text: "Đơn vị tiếp nhận",
                    value: "DonViTiepNhan"
                },
                {
                    text: "Giá trị hợp đồng",
                    value: "GT_HD",
                    align: "right",
                    innerHTML: "<p>{{item.GT_HD.toLocaleString()}}</p>"
                },
                {
                    text: "Số lượng hợp đồng",
                    value: "SL_HD",
                    align: "right"
                },
                {
                    text: "Thao tác",
                    value: "actions",
                }
            ],
            IsChart: false,
            Search: '',
            dialogTable: false,
            itemTable: {},
            IsShowDetail: false,
            titleTable: "",
            TableSelected: [],
            headers: [],
            items: [],
            itemKey: null,
            headerGiaTriHopDong: [{ text: "Năm thực hiện", value: "NamThucHien" }, { text: "Giá trị hợp đồng", value: "GT_HD" }],
            headerSoLuongHopDong: [{ text: "Năm thực hiện", value: "NamThucHien" }, { text: "Số lượng hợp đồng", value: "SL_HD" }],
            headerDonViTiepNhan: [{ text: "Đơn vị tiếp nhận", value: "DonViTiepNhan" }, { text: "Gía trị hợp đồng", value: "GT_HD" }, { text: "Số lượng hợp đồng", value: "SL_HD" }],
            Is_OpenDialog: false
        }
    },
    computed: {
        CGCNHopDong: function () {
            if (this.datacharthopdong) {
                const labels = this.datacharthopdong.map(item => item.NamThucHien.toString())
                const datasetsGT_HD = this.datacharthopdong.map(item => item.GT_HD)
                const param = {
                    "labels": labels,
                    "datasets": [
                        {
                            label: "Giá trị hợp đồng",
                            data: datasetsGT_HD,
                        }
                    ]
                }
                return param
            }
        },
        CGCNSoLuongHopDong: function () {
            if (this.datacharthopdong) {
                const labels = this.datacharthopdong.map(item => item.NamThucHien.toString())
                const datasetsSL_HD = this.datacharthopdong.map(item => item.SL_HD)
                const param = {
                    "labels": labels,
                    "datasets": [
                        {
                            label: "Số lượng hợp đồng",
                            data: datasetsSL_HD
                        }
                    ]
                }
                return param
            }
        },
        CGCNDonViTiepNhan: function () {
            if (this.datachartdonvitiepnhan) {
                const labels = this.datachartdonvitiepnhan.map(item => item.DonViTiepNhan.toString())
                const datasetsGT_HD = this.datachartdonvitiepnhan.map(item => item.GT_HD)
                const datasetsSL_HD = this.datachartdonvitiepnhan.map(item => item.SL_HD)
                const param = {
                    "labels": labels,
                    "datasets": [
                        {
                            label: "Giá trị hợp đồng",
                            data: datasetsGT_HD,
                        },
                        {
                            label: "Số lượng hợp đồng",
                            data: datasetsSL_HD,
                        }
                    ]
                }
                return param
            }
        },
        CGCNSoLuongDonViTiepNhan: function () {
            if (this.datachartdonvitiepnhan) {
                const labels = this.datachartdonvitiepnhan.map(item => item.DonViTiepNhan.toString())
                const datasetsSL_HD = this.datachartdonvitiepnhan.map(item => item.SL_HD)
                const param = {
                    "labels": labels,
                    "datasets": [
                        {
                            label: "Số lượng hợp đồng",
                            data: datasetsSL_HD,
                        }
                    ]
                }
                return param
            }
        },
        CGCNSummary: function () {
            if (this.datacharthopdong) {
                const maxMoney = this.datacharthopdong.map(item => item.GT_HD)
                const maxSoLuongHopDong = this.datacharthopdong.map(item => item.SL_HD)
                let max = Math.max(...maxMoney)
                let maxHD = Math.max(...maxSoLuongHopDong)
                return {
                    GiaTriLonNhat: max.toLocaleString(),
                    SoLuongHopDongLonNhat: maxHD
                }
            }
        },
        CGCNTable: function () {
            if (this.datachartdonvitiepnhan) {
                let arr = this.datachartdonvitiepnhan.sort((a, b) => b.GT_HD - a.GT_HD)
                return arr
            }
        },
        CGCNTableGiaTriHopDong: function () {
            const arr = this.datacharthopdong.map(item => {
                return {
                    GT_HD: item.GT_HD,
                    NamThucHien: item.NamThucHien,
                }
            })
            return arr
        },
        CGCNTableSoLuongHopDong: function () {
            const arr = this.datacharthopdong.map(item => {
                return {
                    NamThucHien: item.NamThucHien,
                    SL_HD: item.SL_HD
                }
            })
            return arr
        }
    },
    methods: {
        editItem(item) {
            this.itemTable = item
            this.dialogTable = true
        },
        setItemsTable(headers, items, title, itemKey) {
            const text = "Xem chi tiết"
            this.TableSelected = []
            this.titleTable = text + " " + title
            this.headers = headers
            this.items = items
            this.itemKey = itemKey
            this.IsShowDetail = true
        },
    },
    template: `
        <uc-dcard
            title="2.2 Chuyển giao Khoa học Công nghệ"
            :loading="vueData.IsLoadingCGCNSummary"
            IsShowBtnDialog = "true"
            :btnOpenDialog="Is_OpenDialog"
        >
            <template v-slot:renderBody>
                  <v-row>
                    <v-col cols="12" >
                        <uc-card title="Giá trị hợp đồng lớn nhất" :description="CGCNSummary?.GiaTriLonNhat" trailingIcon="mdi-cash"></uc-card>
                    </v-col>
                    <v-col cols="12" >
                        <uc-card title="Số lượng hợp đồng nhiều nhất" :description="CGCNSummary?.SoLuongHopDongLonNhat" trailingIcon="mdi-file-document-edit"></uc-card>
                    </v-col>
                    <v-col cols="12" md="6">
                        <uc-dchart-card
                            title="Biểu đồ thống kê giá trị hợp đồng chuyển giao KHCN"
                        >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline" @click="setItemsTable(headerGiaTriHopDong, CGCNTableGiaTriHopDong, 'giá trị hợp đồng','NamThucHien')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                                <uc-chart ref="giatrihopdong" type="bar" :data="CGCNHopDong" :options="optionHopDong" :plugins="plugin"></uc-chart>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <v-col cols="12" md="6">
                        <uc-dchart-card
                        title="Biểu đồ thống kê số lượng hợp đồng chuyển giao KHCN qua các năm"
                        >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline"  @click="setItemsTable(headerSoLuongHopDong, CGCNTableSoLuongHopDong, 'số lượng hợp đồng','NamThucHien')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                                <uc-chart ref="soluonghopdong" type="line" :data="CGCNSoLuongHopDong" :options="optionHopDong" :plugins="plugin"></uc-chart>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <v-col cols="12">
                        <uc-dchart-card
                            title="Đơn vị hợp tác, đối tác chuyển giao công nghệ qua các năm"
                        >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline"  @click="setItemsTable(headerDonViTiepNhan, datachartdonvitiepnhan, 'đơn vị tiếp nhận','DonViTiepNhan')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                            <div style="height:1000px">
                             <uc-chart ref="donvitiepnhan" type="bar" :data="CGCNDonViTiepNhan" :options="optionDonViTiepNhan" :plugins="plugin"></uc-chart>
                            </div>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                </v-row>
                <uc-dialog v-model="IsShowDetail"
                    :title="titleTable"
                >
                    <template v-slot:renderBody>
                        <uc-dtable
                            v-model="TableSelected"
                            :headers="headers"
                            :items="items"
                            isSearch="true"
                            isSelect="true"
                            :itemKey="itemKey"
                        >
                            <template v-slot:item.GT_HD="{ item }">
                                {{item.GT_HD.toLocaleString('vi-VN')}}
                            </template>
                        </uc-dtable>
                    </template>
                </uc-dialog>
            </template>
        </uc-dcard>
    `
})
Vue.component("uc-giaithuong", {
    props: ["giaithuongsummary", "giaithuongnamsummary", "plugin", "mode"],
    data() {
        return {
            optionGiaiThuongSummary: {
                responsive: true,
                indexAxis: 'y',
                plugins: {
                    legend: {
                        position: 'right',
                        display: false
                    },
                    datalabels: {
                        align: 'right',
                        anchor: "end",
                        formatter: (value, context) => {
                            if (value > 0) {
                                return value.toLocaleString()
                            } else {
                                return ''
                            }
                        }
                    }
                },
            },
            optionGiaiThuongNamSummary: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: "y",
                scales: {
                    x: {
                        stacked: true,
                    },
                    y: {
                        stacked: true
                    }
                },
                plugins: {
                    legend: {
                        position: "bottom",
                        display: true
                    },
                    datalabels: {
                        align: 'left',
                        anchor: "end",
                        formatter: (value, context) => {
                            if (value > 0) {
                                return value
                            } else {
                                return ''
                            }
                        }
                    }
                },
            },
            optionGiaiThuongPieSummary: {
                responsive: true,
                plugins: {
                    legend: {
                        display: true,
                        position: "right"
                    },
                }
            },
            optionTableSummary: {
                responsive: true,
                maintainAspectRatio: false,
                layout: {
                    padding: 45
                },
                plugins: {
                    legend: {
                        display: false
                    },
                    datalabels: {
                        align: 'top',
                        anchor: "end",
                        formatter: (value, context) => {
                            if (value > 0) {
                                return value
                            } else {
                                return ''
                            }
                        }
                    }
                }
            },
            headers: [
                { text: "STT", value: "STT", align: 'center' },
                { text: "Tên loại giải thưởng", value: "TenLoaiGiaiThuong" },
                { text: "Số lượng giải thưởng", value: "SL_GT", align: 'right' },
                { text: "Thao tác", value: "actions", align: 'center', sortable: false }
            ],
            IsShowNumberChart: false,
            dialogTable: false,
            itemTable: {
                DataChart: {
                    labels: [],
                    datasets: [
                        {
                            label: "",
                            data: [],
                            type: 'line',
                        }
                    ]
                }
            },
            IsShowDetail: false,
            titleTable: "",
            TableSelected: [],
            headers: [],
            items: [],
            itemKey: null,
            widthSize: 0,
            Is_OpenDialog: false,
            headerGiaTriHopDong: [{ text: "Tên loại giải thưởng", value: "TenLoaiGiaiThuong" }, { text: "Số lượng giải thưởng", value: "SL_GT" }],
            headerChiTietGiaiThuong: [{ text: "STT", value: "STT" }, { text: "Năm đạt giải", value: "NamDatGiai" }, { text: "Tên loại giải thưởng", value: "TenLoaiGiaiThuong" }, { text: "Số lượng giải thưởng", value: "SL_GT" }],
        }
    },
    computed: {
        GiaiThuongTongSummary: function () {
            if (this.giaithuongsummary) {
                const tonggiaithuong = this.giaithuongsummary.reduce((accumulator, currentValue) => accumulator + currentValue.SL_GT, 0);
                const convertArrGiaiThuong = this.giaithuongsummary.map(item => item.SL_GT)
                const giaithuonglonnhat = Math.max(...convertArrGiaiThuong);
                var index = convertArrGiaiThuong.indexOf(giaithuonglonnhat);
                return {
                    TongGiaiThuong: tonggiaithuong,
                    GiaiThuongLonNhat: this.giaithuongsummary[index].TenLoaiGiaiThuong + " (" + this.giaithuongsummary[index].SL_GT + ")",
                }
            }
        },
        GiaiThuongSummary: function () {
            if (this.giaithuongsummary) {
                const labels = this.giaithuongsummary.map(item => item.TenLoaiGiaiThuong)
                const datasets = this.giaithuongsummary.map(item => item.SL_GT)
                const param = {
                    "labels": labels,
                    "datasets": [
                        {
                            label: "Số lượng giải thưởng",
                            data: datasets,
                        }
                    ]
                }
                return param
            }
        },
        GiaiThuongDoughnutSummary: function () {
            const labels = this.giaithuongsummary.map(item => item.TenLoaiGiaiThuong)
            const datasets = this.giaithuongsummary.map(item => item.SL_GT)
            const param = {
                labels: labels,
                datasets: [{
                    data: datasets
                }]
            }
            return param
        },
        GiaiThuongNamSummary: function () {
            if (this.giaithuongnamsummary) {
                const labels = [...new Set(this.giaithuongnamsummary.map(item => item.NamDatGiai))]
                const datasets = this.giaithuongnamsummary.reduce((acc, item) => {
                    const { TenLoaiGiaiThuong, NamDatGiai, SL_GT, LoaiGiaiThuongID } = item;
                    const existingItem = acc.find(entry => entry.label === TenLoaiGiaiThuong);
                    if (existingItem) {
                        existingItem.data.push(SL_GT);
                    } else {
                        const newItem = {
                            label: TenLoaiGiaiThuong,
                            data: [SL_GT],
                            type: 'bar',
                            backgroundColor: getColorFromLoaiAnPham(LoaiGiaiThuongID),
                            borderColor: getColorFromLoaiAnPham(LoaiGiaiThuongID),
                            LoaiGiaiThuongID: LoaiGiaiThuongID
                        };
                        acc.push(newItem);
                    }
                    return acc;
                }, []);
                const param = {
                    labels: labels,
                    datasets: datasets
                }
                return param
            }
        },
        GiaiThuongPieSummary: function () {
            if (this.giaithuongsummary) {
                const labels = this.giaithuongsummary.map(item => item.TenLoaiGiaiThuong)
                const datasets = this.giaithuongsummary.map(item => item.SL_GT)
                const param = {
                    labels: labels,
                    datasets: [{
                        data: datasets
                    }]
                }
                return param
            }
        },
        GiaiThuongListSummary: function () {
            let arr = []
            if (this.giaithuongsummary) {
                const tonggiaithuong = this.giaithuongsummary.reduce((accumulator, currentValue) => accumulator + currentValue.SL_GT, 0);
                arr = this.giaithuongsummary.map(item => {
                    return {
                        ...item,
                        PhanTram: Math.round(item.SL_GT / tonggiaithuong * 100)
                    }
                })
                arr = arr.sort((a, b) => b.PhanTram - a.PhanTram)
            }
            return arr
        }
    },
    mounted() {
        const chart = this.$refs.chartGiaiThuongNam.myChart
        chart.options.plugins.datalabels.display = false
        chart.update()
        this.widthSize = window.innerWidth
        window.addEventListener("resize", () => {
            this.widthSize = window.innerWidth
        });
    },
    watch: {
        IsShowNumberChart: function (val) {
            const chart = this.$refs.chartGiaiThuongNam.myChart
            chart.options.plugins.datalabels.display = val;
            chart.update()
        },
        widthSize: function (val) {
            const chartCTGT = this.$refs.chartGiaiThuongNam.myChart
            const chartGT = this.$refs.chartpiegiaithuong.myChart
            chartGT.options.responsive = true
            //giao diện điện thoại
            if (val < 600) {
                chartCTGT.options.plugins.legend.position = "bottom"
                chartGT.options.plugins.legend.position = "bottom"
            }//giao diện máy tính bảng
            else if (val < 960) {
                chartCTGT.options.plugins.legend.position = "bottom"
                chartGT.options.plugins.legend.position = "bottom"
            }//giao diện máy laptop
            else if (val < 1264) {
                chartCTGT.options.plugins.legend.position = "bottom"
                chartGT.options.plugins.legend.position = "bottom"
            }//giao diện PC
            else {
                chartCTGT.options.plugins.legend.position = "bottom"
                chartGT.options.plugins.legend.position = "bottom"
            }
            chartCTGT.update()
            chartGT.update()
        }
    },
    methods: {
        editItem(item) {
            this.dialogTable = true
            let arr = this.giaithuongnamsummary.filter(gt => gt.LoaiGiaiThuongID === item.LoaiGiaiThuongID)
            const labels = [...new Set(this.giaithuongnamsummary.map(item => item.NamDatGiai.toString()))]
            const data = arr.map(item => item.SL_GT)
            let param = {
                labels: labels,
                datasets: [
                    {
                        label: arr[0].TenLoaiGiaiThuong,
                        data: data,
                        type: 'line',
                    }
                ]
            }
            this.itemTable = item
            this.itemTable.DataChart = param
            this.itemTable.DataToExportExcel = arr
            const colorWhite = "#FFF"
            const colorGray = "#666"
            const chartTable = this.$refs?.chartTable?.myChart
            if (chartTable) {
                if (this.mode) {
                    chartTable.options.plugins.datalabels.color = colorWhite
                    chartTable.options.plugins.title.color = colorWhite
                    chartTable.options.plugins.legend.labels.color = colorWhite
                    chartTable.options.scales.y.ticks.color = colorWhite
                    chartTable.options.scales.x.ticks.color = colorWhite
                } else {
                    chartTable.options.plugins.datalabels.color = colorGray
                    chartTable.options.plugins.title.color = colorGray
                    chartTable.options.plugins.legend.labels.color = colorGray
                    chartTable.options.scales.y.ticks.color = colorGray
                    chartTable.options.scales.x.ticks.color = colorGray
                }
                chartTable.update()
            }
        },
        setItemsTable(headers, items, title, itemKey) {
            const text = "Xem chi tiết"
            this.TableSelected = []
            this.titleTable = text + " " + title
            this.headers = headerschartColumnGiaiThuong
            this.items = items
            this.itemKey = itemKey
            this.IsShowDetail = true
        },
    },
    template: `
        <uc-dcard title="2.3 Giải thưởng Khoa học Công nghệ"
            :loading="vueData.IsLoadingGiaiThuongSummary"
            IsShowBtnDialogGiaiThuong = "true"
            :btnOpenDialogGiaiThuong="Is_OpenDialog"
        >
            <template v-slot:renderBody>
              <v-row>
                    <v-col cols="12" md="6">
                        <uc-card-item title="Tổng số lượng giải thưởng" :description="GiaiThuongTongSummary?.TongGiaiThuong"  trailingIcon="mdi-trophy"></uc-card-item>
                    </v-col>
                    <v-col cols="12" md="6">
                        <uc-card-item title="Giải thưởng có số lượng nhiều nhất" :description="GiaiThuongTongSummary?.GiaiThuongLonNhat" trailingIcon="mdi-robot"></uc-card-item>
                    </v-col>
                    <v-col cols="12" md="4">
                    <!-- Giải thưởng style -->
                        <uc-dchart-card title="Giải thưởng" >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline"  @click="setItemsTable(headerGiaTriHopDong, giaithuongsummary, 'giải thưởng','LoaiGiaiThuongID')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                                <div class="d-flex justify-center align-center">
                                    <uc-chart ref="chartpiegiaithuong" type="doughnut" :data="GiaiThuongDoughnutSummary" :options="optionGiaiThuongPieSummary" :plugins="plugin"></uc-chart>
                                </div>
                            </template>
                        </uc-dchart-card>
                        <!--
                            <uc-card-list
                                iconTopList="mdi-trophy"
                                :titleTopList="GiaiThuongListSummary[0]?.SL_GT"
                                :desciptionTopList="GiaiThuongListSummary[0]?.TenLoaiGiaiThuong"
                                title="Giải thưởng"
                                :detailTitle="GiaiThuongTongSummary.TongGiaiThuong"
                            >
                                <template v-slot:renderBody>
                                        <v-row v-for="(item,index) in GiaiThuongListSummary" :key="index">
                                            <v-col cols="12" class="pt-0 pb-0">
                                                <v-divider></v-divider>
                                            </v-col>
                                            <v-col cols="6" class="d-flex" style="align-items:center">{{item.TenLoaiGiaiThuong}}</v-col>
                                            <v-col cols="3">
                                                <v-progress-circular
                                                    :value="item.PhanTram"
                                                    :rotate="-90"
                                                    :size="40"
                                                    :width="15"
                                                    color="primary"
                                                >
                                                </v-progress-circular>
                                            </v-col>
                                            <v-col cols="3" class="text-center">
                                                <p class="mb-0">Giải thưởng</p>
                                                <p class="mb-0 font-weight-bold">{{item.PhanTram}}%</p>
                                            </v-col>
                                        </v-row>
                                </template>
                            </uc-card-list>
                        -->
                    </v-col>
                   <!-- <v-col cols="12" md="8">
                        <uc-dchart-card title="Biểu đồ thống kê giải thưởng KHCN" >
                            <template v-slot:rightTitle>
                                <uc-btn icon="mdi-square-edit-outline"  @click="setItemsTable(headerGiaTriHopDong, giaithuongsummary, 'giải thưởng','LoaiGiaiThuongID')">
                                </uc-btn>
                            </template>
                            <template v-slot:renderBody>
                            <div class="d-flex justify-center align-center" style="height:600px">
                                <uc-chart ref="chartSoLuongGT" type="bar" :data="GiaiThuongSummary" :options="optionGiaiThuongSummary" :plugins="plugin"></uc-chart>
                            </div>
                            </template>
                        </uc-dchart-card>
                    </v-col> -->
                    <!--
                    <v-col cols="6">
                        <uc-dtable
                            title="Danh sách giải thưởng"
                            isExcel
                            @editItem="editItem"
                            isSearch ="true"
                            :items="giaithuongsummary"
                            :headers= "headers"
                        ></uc-dtable>
                        <uc-dialog
                            v-model="dialogTable"
                            :title="itemTable?.TenLoaiGiaiThuong"
                            isExcel="true"
                            :itemToExcel= "itemTable.DataToExportExcel"
                        >
                            <template v-slot:renderBody>
                                <div style="height: 500px; width:100%">
                                    <uc-chart ref="chartTable" type="line" :data="itemTable.DataChart" :options="optionTableSummary" :plugins="plugin"></uc-chart>
                                </div>
                            </template>
                        </uc-dialog>
                    </v-col>
                    -->
                    <v-col cols="8">
                        <uc-dchart-card
                        title="Biểu đồ thống kê giải thưởng Khoa học Công nghệ qua các năm"
                        >
                            <template v-slot:rightTitle>
                                <div class="d-flex" style="gap:10px">
                                    <uc-btn icon="mdi-square-edit-outline"  @click="setItemsTable(headerChiTietGiaiThuong, giaithuongnamsummary, 'giải thưởng','STT')">
                                    </uc-btn>
                                </div>
                            </template>
                            <template v-slot:checkboxShowNumber>
                                    <v-checkbox v-model="IsShowNumberChart" class="mt-0" style=" align-items: center;" label="Hiển thị số trên biểu đồ" hide-details></v-checkbox>
                            </template>
                            <template v-slot:renderBody>
                            <div style="height:500px">
                                 <uc-chart ref="chartGiaiThuongNam" type="bar" :data="GiaiThuongNamSummary" :options="optionGiaiThuongNamSummary" :plugins="plugin"></uc-chart>
                            </div>
                            </template>
                        </uc-dchart-card>
                    </v-col>
                    <uc-dialog v-model="IsShowDetail"
                        :title="titleTable"
                    >
                    <template v-slot:renderBody>
                        <uc-dtable
                            v-model="TableSelected"
                            :headers="headers"
                            :items="items"
                            isSearch="true"
                            isSelect="true"
                            :itemKey="itemKey"
                        ></uc-dtable>
                    </template>
                </uc-dialog>
                </v-row>
            </template>
        </uc-dcard>
    `
})
Vue.component("uc-api-rpt-temp", {
    props: ["anphamtheonam", "loaianphamtheonam", "anphamtheonamct1", "anphamtheonamct2"],
    data() {
        return {
            headersAnPhamTheoNam: [
                { text: "Năm", value: "NamDangBai", align: "center" },
                { text: "Số ấn phẩm", value: "SL", align: "center" }
            ],
            headersLoaiAnPhamTheoNam: [
                { text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" },
                { text: "Năm đăng bài", value: "NamDangBai", align: "center" },
                { text: "Số ấn phẩm", value: "SL", align: "center" }
            ],
            headersAnPhamTheoNamCT1: [
                { text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" },
                { text: "Nơi đăng bài", value: "NoiDangBai" },
                { text: "Năm đăng bài", value: "NamDangBai", align: "center" },
                { text: "Tên danh mục tạp chí", value: "TenVietTatLoaiDanhMucTapChi" },
                { text: "Số ấn phẩm", value: "SL", align: "center" }
            ],
            headersAnPhamTheoNamCT2: [
                { text: "Tên loại ấn phẩm", value: "TenLoaiAnPham" },
                { text: "Nơi đăng bài", value: "NoiDangBai" },
                { text: "Năm đăng bài", value: "NamDangBai", align: "center" },
                { text: "Tên loại ấn phẩm", value: "TenLoaiSubAnPham" },
                { text: "Tên danh mục tạp chí", value: "TenVietTatLoaiDanhMucTapChi" },
                { text: "Số ấn phẩm", value: "SL", align: "center" }
            ]
        }
    },
    computed: {
        AnPhamTheoNam: function () {
            return this.anphamtheonam
        },
        LoaiAnPhamTheoNam: function () {
            return this.loaianphamtheonam
        },
        AnPhamTheoNamCT1: function () {
            return this.anphamtheonamct1
        },
        AnPhamTheoNamCT2: function () {
            return this.anphamtheonamct2
        }
    },
    methods: {
        toExcelAnPhamTheoNam() {
            jsonToExcel({ data: this.AnPhamTheoNam, filename: "anhLong_new.xlsx" });
            Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        },
        // toExcelLoaiAnPhamTheoNam() {
        //     jsonToExcel_custom({ data: this.LoaiAnPhamTheoNam, filename: "data Moi Nhap.xlsx" });
        //     Vue.$toast.success("Đã xuất Excel", { position: 'top' });
        // },
    },
    template: `
     <v-card>
        <v-card-title>
            <span class="primary--text font-weight-medium">Ấn phẩm chờ ra dashboard</span>
        </v-card-title>
        <v-card-text>
            <v-row>
                <v-col cols="4">
                <v-card>
                    <v-card-title>
                        <span class="primary--text font-weight-medium">Ấn phẩm theo năm</span>
                        <v-spacer></v-spacer>
                        <v-btn class="mr-6" icon color="primary" @click="toExcelAnPhamTheoNam">
				            <v-icon>mdi-microsoft-excel</v-icon>
			            </v-btn>
                    </v-card-title>
                    <v-card-text>
                        <v-data-table :items="AnPhamTheoNam" :headers="headersAnPhamTheoNam">
                        </v-data-table>
                    </v-card-text>
                </v-card>
                    <!--
                    <f-table :items="AnPhamTheoNam" label="Ấn phẩm theo năm" :headers="headersAnPhamTheoNam" :excel="true">
                    </f-table>
                    -->
                </v-col>
                <v-col cols="8">
                    <f-table :items="LoaiAnPhamTheoNam"  :headers="headersLoaiAnPhamTheoNam" :excel="true">
                    </f-table>
                </v-col>
                <v-col cols="12">
                    <f-table :items="AnPhamTheoNamCT1"  :headers="headersAnPhamTheoNamCT1" :excel="true">
                    </f-table>
                </v-col>
                <v-col cols="12">
                    <f-table :items="AnPhamTheoNamCT2"  :headers="headersAnPhamTheoNamCT2" :excel="true">
                    </f-table>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
    `
})
Vue.component("uc-de-tai-nckh", {
    props: [],
    data() {
        return {
            DataChartLine_KHCN: {
                labels: [],
                datasets: [
                    {
                        label: "Số lượng đề tài",
                        type: "bar",
                        data: [],
                        backgroundColor: [
                            '#4db8ff',
                            '#ffa64d',
                            '#6fdc6f',
                            '#ff5c33',
                            '#4dffff',
                            '#ff4dff'
                        ]
                    },
                ]
            },
            OptionChartLine_KHCN: {
                legend: {
                    display: false
                },
                responsive: true, // Đảm bảo biểu đồ responsive
                scales: {
                    y: {
                        beginAtZero: true
                    },
                    x: {
                        ticks: {
                            font: {
                                size: 10
                            },
                        }
                    },
                }
            },
            DataChartLine_NCKHSV: {
                labels: [],
                datasets: [
                    {
                        label: "Số lượng đề tài theo đợt",
                        type: "bar",
                        data: [],
                        backgroundColor: [
                            '#4db8ff',
                            '#ffa64d',
                            '#6fdc6f',
                            '#ff5c33',
                        ],
                    }
                ]
            },
            OptionChartLine_NCKHSV: {
                legend: {
                    display: false
                },
                responsive: true, // Đảm bảo biểu đồ responsive
                scales: {
                    y: {
                        beginAtZero: true
                    },
                    x: {
                        ticks: {
                            font: {
                                size: 12
                            },
                        }
                    },
                },
            },
            DataChartLine_NCKHSV_GroupByKhoa: {
                labels: [],
                axis: 'y',
                datasets: [
                    {
                        type: "bar",
                        label: "Số lượng đề tài theo khoa",
                        data: [],
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.2)',
                            'rgba(255, 159, 64, 0.2)',
                            'rgba(255, 205, 86, 0.2)',
                            'rgba(75, 192, 192, 0.2)',
                            'rgba(54, 162, 235, 0.2)',
                            'rgba(153, 102, 255, 0.2)',
                            'rgba(201, 203, 207, 0.2)',
                            'rgba(0, 255, 65, 0.2)',
                            'rgba(255, 89, 255, 0.2)'
                        ],
                        borderColor: [
                            'rgb(255, 99, 132)',
                            'rgb(255, 159, 64)',
                            'rgb(255, 205, 86)',
                            'rgb(75, 192, 192)',
                            'rgb(54, 162, 235)',
                            'rgb(153, 102, 255)',
                            'rgb(201, 203, 207)',
                            'rgb(0, 255, 65)',
                            'rgb(255, 89, 255)'
                        ],
                        borderWidth: 1
                    }
                ]
            },
            OptionChartLine_NCKHSV_GroupByKhoa: {
                indexAxis: 'y',
                legend: {
                    position: "top"
                },
                responsive: true, // Đảm bảo biểu đồ responsive
                scales: {
                    y: {
                        beginAtZero: true
                    },
                    x: {
                        ticks: {
                            font: {
                                size: 10
                            },
                        }
                    },
                },
            },
            TongSoDeTai_NCKHSV: 0,
            TongSoDeTai_KHCN: 0,
            Is_Show_KHCN: false,
            Headers_KHCN: [
                { text: "STT", value: "SoThuTu", align: "center" },
                { text: "Nhóm đề tài", value: "TenNhomKHCN" },
                { text: "Mã số", value: "MaSoDeTai" },
                { text: "Tên đề tài", value: "TenDeTaiKHCN_Vi" },
                { text: "Đơn vị", value: "DonVi" },
                { text: "Năm đăng ký", value: "NamDangKy", align: "center" },
                { text: "Năm thực hiện", value: "NamThucHien", align: "center" },
                { text: "Tháng bắt đầu", value: "ThangBatDau", align: "center" },
                { text: "Tháng kết thúc", value: "ThangKetThuc", align: "center" },
            ],
            Data_KHCN: [],
            Is_Show_NCKHSV: false,
            Headers_NCKHSV: [
                { text: "STT", value: "SoThuTu", align: "center" },
                { text: "Tên đề tài", value: "TenDeTaiNCKH" },
                { text: "Khoa", value: "KhoaID" },
                { text: "Tên sinh viên", value: "SinhVien" },
                { text: "Tên GVHD", value: "GiaoVien" },
                { text: "Sản phẩm", value: "MoTa_SanPham" },
            ],
            Data_NCKHSV: [],
            Data_KHCN_GroupByKhoa: []
        }
    },
    mounted() { },
    created() {
        this.API_RPT_NCKH_Summary()
        this.API_RPT_KHCN_Summary()
    },
    computed: {},
    methods: {
        getLabelByVal(val) {
            return this.DataChartLine_NCKHSV.labels[val]
        },
        API_RPT_NCKH_Summary() {
            ajaxCALL('/RPT_NCKH_Summary', {}, (res) => {
                this.DataChartLine_NCKHSV.labels = res.data[0].map(item => { return item.TenDot })
                this.DataChartLine_NCKHSV.datasets[0].data = res.data[0].map(item => { return item.SL_DT })
                res.data[0].forEach(item => {
                    this.TongSoDeTai_NCKHSV += item.SL_DT
                })
                this.Data_NCKHSV = res.data[1]
                this.Data_KHCN_GroupByKhoa = res.data[2]
                this.$emit("sumnckhsv", this.TongSoDeTai_NCKHSV)
                this.DataChartLine_NCKHSV_GroupByKhoa.labels = res.data[2].map(item => { return item.TenKhoa })
                this.DataChartLine_NCKHSV_GroupByKhoa.datasets[0].data = res.data[2].map(item => { return item.SL_DT })
            }, (err) => {
            })
        },
        API_RPT_KHCN_Summary() {
            ajaxCALL('/RPT_KHCN_Summary', {}, (res) => {
                this.DataChartLine_KHCN.labels = res.data[0].map(item => { return item.NamThucHien })
                this.DataChartLine_KHCN.datasets[0].data = res.data[0].map(item => { return item.SL_DT })
                res.data[0].forEach(item => {
                    this.TongSoDeTai_KHCN += item.SL_DT
                })
                this.$emit("sumkhcn", this.TongSoDeTai_KHCN)
                this.Data_KHCN = res.data[1]
            }, (err) => {
            })
        }
    },
    template: `
       <v-card>
        <v-card-title>
            <span class="primary--text font-weight-medium">2.4 Đề tài nghiên cứu khoa học</span>
        </v-card-title>
        <v-card-text>
            <v-row>
                <v-col cols="12" md="12">
                     <uc-dchart-card title="2.4.1 Đề tài nghiên cứu khoa học sinh viên">
                       <template v-slot:renderBody>
                            <div class=" d-flex align-center justify-center mt-5" style="width:100%;" >
                                <v-row>
                                    <v-col
                                        cols="6"
                                    >
                                        <div >
                                            <uc-chart-line :datachartline="DataChartLine_NCKHSV" :optionchartline="OptionChartLine_NCKHSV"></uc-chart-line>
                                        </div>
                                    </v-col>
                                    <v-col
                                        cols="6"
                                    >
                                        <div>
                                            <uc-chart-line :datachartline="DataChartLine_NCKHSV_GroupByKhoa" :optionchartline="OptionChartLine_NCKHSV_GroupByKhoa"></uc-chart-line>
                                        </div>
                                    </v-col>
                                </v-row>
                            </div>
                              <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                   <v-chip color="primary">Tổng số đề tài : {{TongSoDeTai_NCKHSV}}</v-chip>
                              </div>
                               <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                    <v-switch v-model="Is_Show_NCKHSV" label="Xem chi tiết"></v-switch>
                              </div>
                              <f-table v-if="Is_Show_NCKHSV"  label="Số liệu chi tiết" :items="Data_NCKHSV"  :items-per-page= "25" class="mt-5"
                                 :footer-props= "{'items-per-page-options':[25, 50,100 ,-1]}" :headers="Headers_NCKHSV"
                                 :fixed-header= "true" :fixed-cols= "2" mobile-breakpoint="600" :calculate-widths= "true" outlined :show-search="true" :excel="true">
                             </f-table>
                       </template>
                     </uc-dchart-card>
                </v-col>
                <v-col cols="12" md="12">
                   <uc-dchart-card title="2.4.2 Đề tài nghiên cứu khoa học cấp cơ sở">
                     <template v-slot:renderBody>
                      <div class=" d-flex align-center justify-center mt-5" style="width:100%;" >
                                    <div style="width:70%;height:70%">
                                       <uc-chart-line :datachartline="DataChartLine_KHCN" :optionchartline="OptionChartLine_KHCN"></uc-chart-line>
                                    </div>
                            </div>
                            <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                 <v-chip color="primary">Tổng số đề tài : {{TongSoDeTai_KHCN}}</v-chip>
                            </div>
                            <!-- <div class=" d-flex align-center justify-center mt-5" style="width:100%;">
                                  <v-switch v-model="Is_Show_KHCN" label="Xem chi tiết"></v-switch>
                            </div>
                            <f-table v-if="Is_Show_KHCN"  label="Số liệu chi tiết" :items="Data_KHCN" class="mt-5" mobile-breakpoint="600"
                               :items-per-page= "25" :footer-props= "{'items-per-page-options':[25, 50,100 ,-1]}" :headers="Headers_KHCN"
                               :fixed-header= "true" :fixed-cols= "2" :calculate-widths= "true" outlined :show-search="true" :excel="true">
                           </f-table> -->
                     </template>
                   </uc-dchart-card>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
    `
})
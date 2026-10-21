const IconC_Process = "mdi-account-check"
const IconP_Process = "mdi-account-clock"
const IconW_Process = "mdi-account-settings"
const ColorC_Process = "#6fdc6f"
const ColorW_Process = "#ffa64d"
const ColorP_Process = "#4db8ff"
function isRightAdmin() {
    let flag = false
    let groupID = vueData.user.GroupID
    vueData.SystemRight = [9, 1, 3, 2]
    if (groupID === 2) {
        return true
    }
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
    // Nếu là học viên thì sẽ chuyển trang
    if (groupID === 2) {
        setTimeout(() => {
            window.location.href = window.location.origin + "/ths-luan-van-cua-toi"
        }, 200)
        return
    }
    //Nếu là quản trị thì phải kiểm tra thêm quyền
    if (isRightAdmin()) {
        confirm({
            title: "Thông báo",
            content: "Tài khoản của bạn không có quyền truy cập chức năng này",
            action: () => {
                redirect({ url: "https://me.lhu.edu.vn" })
            },
            cancel: false
        })
        return
    }
}
function getNienKhoa() {
    const $this = this
    $.ajax({
        type: 'GET',
        headers: {
            authorization: $awt,
        },
        url: `https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`,
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        crossDomain: true,
        success: function (res) {
            vueData.DsNienKhoa = res.data.map((item) => {
                return {
                    ...item,
                    TenNienKhoa: item.NienKhoa,
                    NienKhoa: item.NienKhoa,
                }
            })
            console.log('vueData.DsNienKhoa', vueData.DsNienKhoa)
        },
        error: function (xhr, ajaxOptions, thrownError) {
            $.dialog({
                icon: 'fas fa-exclamation',
                title: 'Error',
                content: xhr.responseJSON ? xhr.responseJSON.Message : xhr.responseText ? xhr.responseText : '',
                type: 'red',
                columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
                closeIcon: true,
                buttons: {
                    ok: {
                        text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
                        btnClass: 'btn-blue',
                    },
                },
            })
        },
    })
}
Vue.component("uc-main-component", {
    props: ["dsdaotaothacsi", "dsdoidtluanvan", "dstongnganh", "dsnganh", "dschitietnganh"],
    data() {
        return {
            pluginChart: [ChartDataLabels]
        }
    },
    template: `
        <v-row>
            <v-col cols="12">
                <uc-summary
                    :dsdaotaothacsi="dsdaotaothacsi"
                    :dsdoidtluanvan="dsdoidtluanvan"
                    :pluginChart="pluginChart"
                ></uc-summary>
            </v-col>
            <v-col cols="12">
                <uc-process
                    :dstongnganh="dstongnganh"
                    :dsnganh="dsnganh"
                    :dschitietnganh="dschitietnganh"
                    :pluginChart="pluginChart"
                >
                </uc-process>
            </v-col>
        </v-row>
    `
})
Vue.component("uc-summary", {
    props: ["dsdaotaothacsi", "dsdoidtluanvan", "pluginChart"],
    data() {
        return {
            DSDaoTaoThacSi: this.dsdaotaothacsi,
            DSDoiDTLuanVan: this.dsdoidtluanvan,
            IsShowLabelDaoTaoThacSiChartLine: false,
            IsShowLabelDoiDTLuanVanChartLine: false,
            headerDaoTaoThacSi: [
                {
                    text: "Niên khóa",
                    value: "NienKhoa",
                    align: "center"
                }, {
                    text: "Hệ đào tạo",
                    value: "HeDaoTao",
                    align: "center"
                }, {
                    text: "Chưa thực hiện",
                    value: "W_Process",
                    align: "center"
                }, {
                    text: "Đang làm",
                    value: "P_Process",
                    align: "center"
                }, {
                    text: "Đã hoàn thành",
                    value: "C_Process",
                    align: "center"
                }, {
                    text: "Tổng số học viên",
                    value: "Total_Student",
                    align: "center"
                },
            ],
            headerDoiDTLuanVan: [
                {
                    text: "Niên khóa",
                    value: "NienKhoa",
                    align: "center"
                }, {
                    text: "Hệ đào tạo",
                    value: "HeDaoTao",
                    align: "center"
                }, {
                    text: "Chưa thực hiện",
                    value: "W_Process",
                    align: "center"
                }, {
                    text: "Đang làm",
                    value: "P_Process",
                    align: "center"
                }, {
                    text: "Đã hoàn thành",
                    value: "C_Process",
                    align: "center"
                }, {
                    text: "Tổng số học viên",
                    value: "Total_Student",
                    align: "center"
                },
            ],
            optionDaoTaoThacSiChartLine: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        grace: '5%',
                    }
                },
                plugins: {
                    datalabels: {
                        align: 'top',
                        anchor: "end",
                    }
                },
            },
            optionDoiDTLuanVanChartLine: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        grace: '5%',
                    }
                },
                plugins: {
                    datalabels: {
                        align: 'top',
                        anchor: "end",
                    }
                },
            },
            optionDaoTaoThacSiChartDoughnut: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right'
                    }
                }
            },
            optionDoiDTLuanVanChartDoughnut: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right'
                    }
                }
            }
        }
    },
    mounted() {
        const chartDaoTaoThacSi = this.$refs.daotaothacsi.myChart
        const charDoiDTLuanVan = this.$refs.doidtluanvan.myChart
        chartDaoTaoThacSi.options.plugins.datalabels.display = false
        charDoiDTLuanVan.options.plugins.datalabels.display = false
        chartDaoTaoThacSi.update()
        charDoiDTLuanVan.update()
        getNienKhoa()
    },
    watch: {
        IsShowLabelDaoTaoThacSiChartLine: function (val) {
            const chartDaoTaoThacSi = this.$refs.daotaothacsi.myChart
            chartDaoTaoThacSi.options.plugins.datalabels.display = val
            chartDaoTaoThacSi.update()
        },
        IsShowLabelDoiDTLuanVanChartLine: function (val) {
            const charDoiDTLuanVan = this.$refs.doidtluanvan.myChart
            charDoiDTLuanVan.options.plugins.datalabels.display = val
            charDoiDTLuanVan.update()
        },
        dsdaotaothacsi(newVal) {
            this.DSDaoTaoThacSi = newVal;
        },
        dsdoidtluanvan(newVal) {
            this.DSDoiDTLuanVan = newVal;
        }
    },
    computed: {
        DaoTaoThacSiSummary: function () {
            let sumTongHocSinh = this.DSDaoTaoThacSi.reduce((acc, current) => acc + current.Total_Student, 0)
            let sumP_Process = this.DSDaoTaoThacSi.reduce((acc, current) => acc + current.P_Process, 0)
            let sumW_Process = this.DSDaoTaoThacSi.reduce((acc, current) => acc + current.W_Process, 0)
            let sumC_Process = this.DSDaoTaoThacSi.reduce((acc, current) => acc + current.C_Process, 0)
            let P_ProcessPhanTram = 0
            let W_ProcessPhanTram = 0
            let C_ProcessPhanTram = 0
            if (isNaN(sumP_Process / sumTongHocSinh) === false) {
                P_ProcessPhanTram = Math.round(sumP_Process / sumTongHocSinh * 100)
            }
            if (isNaN(sumW_Process / sumTongHocSinh) === false) {
                W_ProcessPhanTram = Math.round(sumW_Process / sumTongHocSinh * 100)
            }
            if (isNaN(sumC_Process / sumTongHocSinh) === false) {
                C_ProcessPhanTram = Math.round(sumC_Process / sumTongHocSinh * 100)
            }
            return {
                TongHocSinh: sumTongHocSinh ?? 0,
                P_Process: sumP_Process ?? 0,
                W_Process: sumW_Process ?? 0,
                C_Process: sumC_Process ?? 0,
                P_ProcessPhanTram: P_ProcessPhanTram,
                W_ProcessPhanTram: W_ProcessPhanTram,
                C_ProcessPhanTram: C_ProcessPhanTram,
            }
        },
        DoiDTLuanVanSummary: function () {
            let sumTongHocSinh = this.DSDoiDTLuanVan.reduce((acc, current) => acc + current.Total_Student, 0)
            let sumP_Process = this.DSDoiDTLuanVan.reduce((acc, current) => acc + current.P_Process, 0)
            let sumW_Process = this.DSDoiDTLuanVan.reduce((acc, current) => acc + current.W_Process, 0)
            let sumC_Process = this.DSDoiDTLuanVan.reduce((acc, current) => acc + current.C_Process, 0)
            let P_ProcessPhanTram = 0
            let W_ProcessPhanTram = 0
            let C_ProcessPhanTram = 0
            if (isNaN(sumP_Process / sumTongHocSinh) === false) {
                P_ProcessPhanTram = Math.round(sumP_Process / sumTongHocSinh * 100)
            }
            if (isNaN(sumW_Process / sumTongHocSinh) === false) {
                W_ProcessPhanTram = Math.round(sumW_Process / sumTongHocSinh * 100)
            }
            if (isNaN(sumC_Process / sumTongHocSinh) === false) {
                C_ProcessPhanTram = Math.round(sumC_Process / sumTongHocSinh * 100)
            }
            return {
                TongHocSinh: sumTongHocSinh ?? 0,
                P_Process: sumP_Process ?? 0,
                W_Process: sumW_Process ?? 0,
                C_Process: sumC_Process ?? 0,
                P_ProcessPhanTram: P_ProcessPhanTram,
                W_ProcessPhanTram: W_ProcessPhanTram,
                C_ProcessPhanTram: C_ProcessPhanTram,
            }
        },
        DaoTaoThacSiChartLine: function () {
            const labels = this.DSDaoTaoThacSi.map((item) => item.NienKhoa)
            const dataP_Process = this.DSDaoTaoThacSi.map((item) => item.P_Process)
            const dataW_Process = this.DSDaoTaoThacSi.map((item) => item.W_Process)
            const dataC_Process = this.DSDaoTaoThacSi.map((item) => item.C_Process)
            const dataTotal_Student = this.DSDaoTaoThacSi.map((item) => item.Total_Student)
            const param = {
                labels: labels,
                datasets: [
                    {
                        label: "Chưa thực hiện",
                        data: dataW_Process,
                        type: 'line',
                    },
                    {
                        label: "Đang làm",
                        data: dataP_Process,
                        type: 'line',
                    },
                    {
                        label: "Đã hoàn thành",
                        data: dataC_Process,
                        type: 'line',
                    },
                    {
                        label: "Tổng số học viên",
                        data: dataTotal_Student,
                        backgroundColor: "#ffd8bf",
                        borderColor: "#ff9c6e",
                        stack: 'combined',
                        type: 'bar',
                    },
                ]
            }
            return param
        },
        DaoTaoThacSiChartDoughnut: function () {
            const param = {
                labels: ["Chưa thực hiện", "Đang làm", "Đã hoàn thành"],
                datasets: [
                    {
                        data: [this.DaoTaoThacSiSummary.W_Process, this.DaoTaoThacSiSummary.P_Process, this.DaoTaoThacSiSummary.C_Process,],
                        backgroundColor: [ColorW_Process, ColorP_Process, ColorC_Process]
                    }
                ]
            }
            return param
        },
        DoiDTLuanVanChartLine: function () {
            const labels = this.DSDoiDTLuanVan.map((item) => item.NienKhoa)
            const dataP_Process = this.DSDoiDTLuanVan.map((item) => item.P_Process)
            const dataW_Process = this.DSDoiDTLuanVan.map((item) => item.W_Process)
            const dataC_Process = this.DSDoiDTLuanVan.map((item) => item.C_Process)
            const dataTotal_Student = this.DSDoiDTLuanVan.map((item) => item.Total_Student)
            const param = {
                labels: labels,
                datasets: [
                    {
                        label: "Chưa thực hiện",
                        data: dataW_Process,
                        type: 'line',
                    },
                    {
                        label: "Đang làm",
                        data: dataP_Process,
                        type: 'line',
                    },
                    {
                        label: "Đã hoàn thành",
                        data: dataC_Process,
                        type: 'line',
                    },
                    {
                        label: "Tổng số học viên",
                        data: dataTotal_Student,
                        backgroundColor: "#ffd8bf",
                        borderColor: "#ff9c6e",
                        stack: 'combined',
                        type: 'bar',
                    },
                ]
            }
            return param
        },
        DoiDTLuanVanChartDoughnut: function () {
            const param = {
                labels: ["Chưa thực hiện", "Đang làm", "Đã hoàn thành"],
                datasets: [
                    {
                        data: [this.DoiDTLuanVanSummary.W_Process, this.DoiDTLuanVanSummary.P_Process, this.DoiDTLuanVanSummary.C_Process,]
                    }
                ]
            }
            return param
        },
    },
    template: `
        <v-card>
            <v-card-title class="primary--text">Tiến độ đào tạo thạc sĩ</v-card-title>
            <v-card-text>
                <v-row>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Tổng số học viên"
                            :description ="DaoTaoThacSiSummary?.TongHocSinh"
                             trailingIcon="mdi-account-school"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Chưa thực hiện"
                           :description ="DaoTaoThacSiSummary?.W_Process"
                            :trailingIcon="IconP_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đang làm"
                            :description ="DaoTaoThacSiSummary?.P_Process"
                            :trailingIcon="IconW_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đã hoàn thành"
                            :description ="DaoTaoThacSiSummary?.C_Process"
                            :trailingIcon="IconC_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <v-card>
                            <v-card-title class="primary--text">Biểu đồ hình tròn</v-card-title>
                            <v-card-text class="d-flex">
                                    <uc-chart type="doughnut" :data="DaoTaoThacSiChartDoughnut" :options="optionDaoTaoThacSiChartDoughnut" :plugins="pluginChart"></uc-chart>
                                <!--
                                <v-row>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold ">Chưa thực hiện</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                            :value="DaoTaoThacSiSummary?.W_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DaoTaoThacSiSummary?.W_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold">Đang làm</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                             :value="DaoTaoThacSiSummary?.P_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DaoTaoThacSiSummary?.P_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold">Đã hoàn thành</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                            :value="DaoTaoThacSiSummary?.C_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DaoTaoThacSiSummary?.C_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                </v-row>
                                -->
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="3">
                        <v-card>
                            <v-card-title class="primary--text">Chi tiết tiến độ đào tạo thạc sĩ</v-card-title>
                            <v-card-text class="black--text">
                                <div class="text-center">
                                    <v-btn fab color="primary" small>
                                        <v-icon>mdi-account-school</v-icon>
                                    </v-btn>
                                    <p class="primary--text font-weight-bold text-h6">Tổng - {{DaoTaoThacSiSummary?.TongHocSinh}} học viên </p>
                                </div>
                                <v-row>
                                    <v-col cols="3">Chưa thực hiện</v-col>
                                    <v-col cols="2" class="text-center">{{DaoTaoThacSiSummary?.W_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DaoTaoThacSiSummary?.W_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DaoTaoThacSiSummary?.W_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                                <v-row>
                                    <v-col cols="3">Đang làm</v-col>
                                    <v-col cols="2" class="text-center">{{DaoTaoThacSiSummary?.P_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DaoTaoThacSiSummary?.P_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DaoTaoThacSiSummary?.P_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                                <v-row>
                                    <v-col cols="3">Đã hoàn thành</v-col>
                                    <v-col cols="2" class="text-center">{{DaoTaoThacSiSummary?.C_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DaoTaoThacSiSummary?.C_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DaoTaoThacSiSummary?.C_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="6">
                        <v-card>
                            <v-card-title class="primary--text">Biểu đồ line tiến độ đào tạo thạc sĩ
                                <v-spacer></v-spacer>
                                <v-checkbox v-model="IsShowLabelDaoTaoThacSiChartLine" class="mt-1" label="Hiển thị số trên biểu đồ" hide-details></v-checkbox>
                            </v-card-title>
                            <v-card-text>
                                <uc-chart ref="daotaothacsi" type="line" :data="DaoTaoThacSiChartLine" :options="optionDaoTaoThacSiChartLine" :plugins="pluginChart"></uc-chart>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="12">
                        <f-table
                            label="Danh sách tiến độ đào tạo thạc sĩ"
                            :headers="headerDaoTaoThacSi"
                            :items="DSDaoTaoThacSi"
                            showSearch="true"
                            excel="true"
                        ></f-table>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-title class="primary--text">Tình hình đổi đề tài luận văn</v-card-title>
            <v-card-text>
                <v-row>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Tổng số học viên"
                            :description ="DoiDTLuanVanSummary?.TongHocSinh"
                             trailingIcon="mdi-account-school"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Chưa thực hiện"
                           :description ="DoiDTLuanVanSummary?.W_Process"
                            :trailingIcon="IconP_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đang làm"
                            :description ="DoiDTLuanVanSummary?.P_Process"
                            :trailingIcon="IconW_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đã hoàn thành"
                            :description ="DoiDTLuanVanSummary?.C_Process"
                            :trailingIcon="IconC_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <v-card>
                            <v-card-title class="primary--text">Biểu đồ hình tròn</v-card-title>
                            <v-card-text class="d-flex">
                                <uc-chart type="doughnut" :data="DoiDTLuanVanChartDoughnut" :options="optionDoiDTLuanVanChartDoughnut" :plugins="pluginChart"></uc-chart>
                                <!--
                                <v-row>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold ">Chưa thực hiện</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                            :value="DoiDTLuanVanSummary?.W_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DoiDTLuanVanSummary?.W_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold">Đang làm</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                             :value="DoiDTLuanVanSummary?.P_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DoiDTLuanVanSummary?.P_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                    <v-col class="text-center d-flex" style="flex-direction:column; justify-content:space-between; align-items:center; gap:5px">
                                        <p class="mb-0 text-title font-weight-bold">Đã hoàn thành</p>
                                        <v-progress-circular
                                            :rotate="360"
                                            :size="100"
                                            :width="15"
                                            :value="DoiDTLuanVanSummary?.C_ProcessPhanTram"
                                            color="primary"
                                        >
                                            <p class="mb-0 text-h6 primary--text">{{DoiDTLuanVanSummary?.C_ProcessPhanTram + "%"}}</p>
                                        </v-progress-circular>
                                    </v-col>
                                </v-row>
                                -->
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="3">
                        <v-card>
                            <v-card-title class="primary--text">Chi tiết tình hình đổi đề tài luận văn</v-card-title>
                            <v-card-text class="black--text">
                                <div class="text-center">
                                    <v-btn fab color="primary" small>
                                        <v-icon>mdi-account-school</v-icon>
                                    </v-btn>
                                    <p class="primary--text font-weight-bold text-h6">Tổng - {{DoiDTLuanVanSummary?.TongHocSinh}} học viên </p>
                                </div>
                                <v-row>
                                    <v-col cols="3">Chưa thực hiện</v-col>
                                    <v-col cols="2" class="text-center">{{DoiDTLuanVanSummary?.W_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DoiDTLuanVanSummary?.W_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DoiDTLuanVanSummary?.W_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                                <v-row>
                                    <v-col cols="3">Đang làm</v-col>
                                    <v-col cols="2" class="text-center">{{DoiDTLuanVanSummary?.P_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DoiDTLuanVanSummary?.P_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DoiDTLuanVanSummary?.P_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                                <v-row>
                                    <v-col cols="3">Đã hoàn thành</v-col>
                                    <v-col cols="2" class="text-center">{{DoiDTLuanVanSummary?.C_Process}}</v-col>
                                    <v-col>
                                        <v-progress-linear
                                            :value="DoiDTLuanVanSummary?.C_ProcessPhanTram"
                                            color="primary"
                                            height="25"
                                        >
                                            {{DoiDTLuanVanSummary?.C_ProcessPhanTram + "%"}}
                                        </v-progress-linear>
                                    </v-col>
                                </v-row>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="6">
                        <v-card>
                            <v-card-title class="primary--text">Biểu đồ line tình hình đổi đề tài luận văn
                                <v-spacer></v-spacer>
                                <v-checkbox v-model="IsShowLabelDoiDTLuanVanChartLine" class="mt-1" label="Hiển thị số trên biểu đồ" hide-details></v-checkbox>
                            </v-card-title>
                            <v-card-text>
                                <uc-chart ref="doidtluanvan" type="line" :data="DoiDTLuanVanChartLine" :options="optionDoiDTLuanVanChartLine" :plugins="pluginChart"></uc-chart>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="12">
                        <f-table
                            label="Danh sách tình hình đổi đề tài luận văn"
                            :headers="headerDoiDTLuanVan"
                            :items="DSDoiDTLuanVan"
                            showSearch="true"
                            excel="true"
                        ></f-table>
                    </v-col>
                </v-row>
            </v-card-text>
        </v-card>
    `
})
Vue.component("uc-process", {
    props: ["dstongnganh", "dsnganh", "dschitietnganh", "pluginChart"],
    data() {
        return {
            DSTongNganh: this.dstongnganh,
            DSNganh: this.dsnganh,
            DSChiTietNganh: this.dschitietnganh,
            SelectedBranch: vueData.DSSelectNganh ? vueData.DSSelectNganh[0].value : [],
            // DataSelectBranch: [],
            NienKhoaValue: '2023-01',
            TongNganhSummary: {},
            DataChartDoughnut: {},
            optionSummary: {
                responsive: true,
                plugins: {
                    legend: {
                        position: "right"
                    }
                }
            },
            optionDetailSummary: {
                responsive: true,
                indexAxis: 'y',
                scales: {
                    y: {
                        beginAtZero: true,
                        grace: '5%',
                    },
                    x: {
                        beginAtZero: true,
                        grace: '5%',
                    }
                },
                plugins: {
                    datalabels: {
                        align: 'right',
                        anchor: "end",
                    }
                },
            },
            optionDetailNganhSummary: {
                responsive: true,
                indexAxis: "y",
                scales: {
                    y: {
                        beginAtZero: true,
                        grace: '5%',
                    },
                    x: {
                        beginAtZero: true,
                        grace: '5%',
                    }
                },
                plugins: {
                    datalabels: {
                        align: 'right',
                        anchor: "end",
                    }
                },
            }
        }
    },
    mounted() {
        this.sumaryRefinder()
    },
    watch: {
        NienKhoaValue(val) {
            vueData.NienKhoa = val
            CALL('loadSummaryProcess')
        },
        // Theo dõi props thay đổi (khi API load xong và truyền data mới xuống)
        dstongnganh(newVal) {
            this.DSTongNganh = newVal
            this.sumaryRefinder() // Tính toán lại biểu đồ với data mới
        },
        dsnganh(newVal) {
            this.DSNganh = newVal
        },
        dschitietnganh(newVal) {
            this.DSChiTietNganh = newVal
        }
    },
    methods: {
        sumaryRefinder() {
            let sumTienTrinh = this.DSTongNganh.reduce((acc, current) => acc + current.total, 0)
            let sumP_Process = this.DSTongNganh.reduce((acc, current) => acc + current.P_Process, 0)
            let sumW_Process = this.DSTongNganh.reduce((acc, current) => acc + current.W_Process, 0)
            let sumC_Process = this.DSTongNganh.reduce((acc, current) => acc + current.C_Process, 0)
            let P_ProcessPhanTram = 0
            let W_ProcessPhanTram = 0
            let C_ProcessPhanTram = 0
            if (isNaN(sumP_Process / sumTienTrinh) === false) {
                P_ProcessPhanTram = Math.round(sumP_Process / sumTienTrinh * 100)
            }
            if (isNaN(sumW_Process / sumTienTrinh) === false) {
                W_ProcessPhanTram = Math.round(sumW_Process / sumTienTrinh * 100)
            }
            if (isNaN(sumC_Process / sumTienTrinh) === false) {
                C_ProcessPhanTram = Math.round(sumC_Process / sumTienTrinh * 100)
            }
            this.TongNganhSummary = {
                TongTienTrinh: sumTienTrinh ?? 0,
                P_Process: sumP_Process ?? 0,
                W_Process: sumW_Process ?? 0,
                C_Process: sumC_Process ?? 0,
                P_ProcessPhanTram: P_ProcessPhanTram,
                W_ProcessPhanTram: W_ProcessPhanTram,
                C_ProcessPhanTram: C_ProcessPhanTram,
            }
            /////////////////
            this.DataChartDoughnut = {
                labels: ["Chưa thực hiện", "Đang làm", "Đã hoàn thành"],
                datasets: [{
                    data: [this.TongNganhSummary.W_Process, this.TongNganhSummary.P_Process, this.TongNganhSummary.C_Process,]
                }]
            }
        },
    },
    computed: {
        // TongNganhSummary: function () {
        //     let sumTienTrinh = this.DSTongNganh.reduce((acc, current) => acc + current.total, 0)
        //     let sumP_Process = this.DSTongNganh.reduce((acc, current) => acc + current.P_Process, 0)
        //     let sumW_Process = this.DSTongNganh.reduce((acc, current) => acc + current.W_Process, 0)
        //     let sumC_Process = this.DSTongNganh.reduce((acc, current) => acc + current.C_Process, 0)
        //     let P_ProcessPhanTram = 0
        //     let W_ProcessPhanTram = 0
        //     let C_ProcessPhanTram = 0
        //     if (isNaN(sumP_Process / sumTienTrinh) === false) {
        //         P_ProcessPhanTram = Math.round(sumP_Process / sumTienTrinh * 100)
        //     }
        //     if (isNaN(sumW_Process / sumTienTrinh) === false) {
        //         W_ProcessPhanTram = Math.round(sumW_Process / sumTienTrinh * 100)
        //     }
        //     if (isNaN(sumC_Process / sumTienTrinh) === false) {
        //         C_ProcessPhanTram = Math.round(sumC_Process / sumTienTrinh * 100)
        //     }
        //     return {
        //         TongTienTrinh: sumTienTrinh ?? 0,
        //         P_Process: sumP_Process ?? 0,
        //         W_Process: sumW_Process ?? 0,
        //         C_Process: sumC_Process ?? 0,
        //         P_ProcessPhanTram: P_ProcessPhanTram,
        //         W_ProcessPhanTram: W_ProcessPhanTram,
        //         C_ProcessPhanTram: C_ProcessPhanTram,
        //     }
        // },
        // DataChartDoughnut: function () {
        //     const param = {
        //         labels: ["Chưa thực hiện", "Đang làm", "Đã hoàn thành"],
        //         datasets: [{
        //             data: [this.TongNganhSummary.W_Process, this.TongNganhSummary.P_Process, this.TongNganhSummary.C_Process,]
        //         }]
        //     }
        //     return param
        // },
        DataDetailChartBar: function () {
            const labels = this.DSTongNganh.map(item => item.task_name)
            const dataP_Process = this.DSTongNganh.map(item => item.P_Process)
            const dataW_Process = this.DSTongNganh.map(item => item.W_Process)
            const dataC_Process = this.DSTongNganh.map(item => item.C_Process)
            const param = {
                labels: labels,
                datasets: [{
                    label: "Chưa thực hiện",
                    data: dataW_Process,
                    type: "bar",
                    backgroundColor: ColorP_Process
                }, {
                    label: "Đang làm",
                    data: dataP_Process,
                    type: "bar",
                    backgroundColor: ColorW_Process
                }, {
                    label: "Đã hoàn thành",
                    data: dataC_Process,
                    type: "bar",
                    backgroundColor: ColorC_Process
                },]
            }
            return param
        },
        DataDetailNganhChartBar: function () {
            let arr = this.DSChiTietNganh.filter(item => parseInt(item.NganhID) === this.SelectedBranch)
            const labels = arr.map(item => item.task_name)
            const sum = arr.reduce((acc, current) => acc + current.total, 0)
            const dataP_Process = arr.map(item => item.P_Process)
            const dataW_Process = arr.map(item => item.W_Process)
            const dataC_Process = arr.map(item => item.C_Process)
            let param = {
                labels: labels,
                datasets: [{
                    label: "Chưa thực hiện",
                    data: dataW_Process,
                    type: "bar",
                    backgroundColor: ColorP_Process
                }, {
                    label: "Đang làm",
                    data: dataP_Process,
                    type: "bar",
                    backgroundColor: ColorW_Process
                }, {
                    label: "Đã hoàn thành",
                    data: dataC_Process,
                    type: "bar",
                    backgroundColor: ColorC_Process
                },]
            }
            return {
                Tong: sum,
                Chart: param
            }
        },
        RenderTextDetaiNganh() {
            const obj = vueData.DSSelectNganh.find(item => item.value === this.SelectedBranch)
            if (obj) {
                return obj
            }
            return {}
        }
    },
    template: `
        <v-card>
            <v-card-title class="primary--text">Tiến trình</v-card-title>
            <v-card-text>
                <div class="mb-3 d-flex justify-end wrapSelect">
                    <v-autocomplete
                            v-model="NienKhoaValue"
                            :items="vueData.DsNienKhoa"
                            item-text="TenNienKhoa"
                            item-value="NienKhoa"
                            outlined
                            dense
                            hide-details
                            placeholder="Chọn niên khóa"
                            label="Niên khóa"
                        />
                </div>
                <v-row>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Tổng tiến trình"
                            :description ="TongNganhSummary?.TongTienTrinh"
                            trailingIcon="mdi-progress-clock"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Chưa thực hiện"
                            :description ="TongNganhSummary?.W_Process"
                            :trailingIcon="IconP_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đang làm"
                            :description ="TongNganhSummary?.P_Process"
                            :trailingIcon="IconW_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="3">
                        <uc-card-item
                            title ="Đã hoàn thành"
                            :description ="TongNganhSummary?.C_Process"
                            :trailingIcon="IconC_Process"
                        ></uc-card-item>
                    </v-col>
                    <v-col cols="4">
                        <v-card>
                            <v-card-title class="primary--text">Tiến trình </v-card-title>
                            <v-card-text  >
                                <uc-chart type="doughnut" :data="DataChartDoughnut" :options="optionSummary" :plugins="pluginChart"></uc-chart>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col cols="8">
                        <v-card>
                            <v-card-title class="primary--text">Tiến trình </v-card-title>
                            <v-card-text >
                                <uc-chart type="bar" :data="DataDetailChartBar" :options="optionDetailSummary" :plugins="pluginChart"></uc-chart>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <!-- <v-col cols="12" >
                        <v-card style="max-height: 700px; overflow-y: scroll">
                            <v-card-title class="primary--text" style="position:sticky; z-index: 3; top: 0; background-color: white">
                                Timeline
                            </v-card-title>
                            <v-card-text class="black--text">
                                <v-timeline dense clipped  v-for="item in DSNganhSummary">
                                    <v-timeline-item
                                        color="primary"
                                        icon-color="grey lighten-2"
                                        fill-dot
                                    >
                                    <template v-slot:icon>
                                        <p class="white--text mb-0 font-weight-bold" style="font-size:20px">{{item.STT}}</p>
                                    </template>
                                        <v-expansion-panels  >
                                            <v-expansion-panel>
                                                <v-expansion-panel-header>
                                                    <p class="mb-0 text-h6 font-weight-bold primary--text"> {{item.task_name}} <v-chip class="ml-1" color="primary">{{item.total}}</v-chip> </p>
                                                    /*
                                                    <p class="mb-0">Tổng: </p>
                                                    <v-progress-linear
                                                        :value="item.PhanTram"
                                                        color="primary"
                                                        height="25"
                                                    >
                                                        {{item.PhanTram + "%"}}
                                                    </v-progress-linear>
                                                    */
                                                </v-expansion-panel-header>
                                                <v-expansion-panel-content>
                                                    <v-row>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Ngôn ngữ anh <v-chip color="primary">{{item.NNA_TOTAL}}</v-chip></p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.NNA_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.NNA_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.NNA_C_Process}}</p>
                                                </v-col>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Công nghệ thông tin <v-chip color="primary">{{item.CNTT_TOTAL}}</p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.CNTT_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.CNTT_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.CNTT_C_Process}}</p>
                                                </v-col>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Quản trị kinh doanh <v-chip color="primary">{{item.QTKD_TOTAL}}</p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.QTKD_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.QTKD_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.QTKD_C_Process}}</p>
                                                </v-col>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Kế toán <v-chip color="primary">{{item.KT_TOTAL}}</p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.KT_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.KT_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.KT_C_Process}}</p>
                                                </v-col>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Tài chính Ngân hàng <v-chip color="primary">{{item.TCNH_TOTAL}}</p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.TCNH_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.TCNH_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.TCNH_C_Process}}</p>
                                                </v-col>
                                                <v-col >
                                                    <p class="mb-0 font-weight-bold">Công nghệ KT công trình xây dựng <v-chip color="primary">{{item.KTCT_TOTAL}}</p>
                                                    <p class="mb-0">Chưa thực hiện: {{item.KTCT_P_Process}}</p>
                                                    <p class="mb-0">Đang làm : {{item.KTCT_W_Process}}</p>
                                                    <p class="mb-0">Đã hoàn thành : {{item.KTCT_C_Process}}</p>
                                                </v-col>
                                                    </v-row>
                                                </v-expansion-panel-content>
                                            </v-expansion-panel>
                                        </v-expansion-panels>
                                    </v-timeline-item>
                            </v-card-text>
                        </v-card>
                    </v-col> -->
                    <v-col cols="12" >
                        <v-card>
                            <v-card-title class="primary--text">
                                Chi tiết ngành <span class="red--text ml-1">{{RenderTextDetaiNganh.text}} <v-chip class="ml-1" color="primary"> {{DataDetailNganhChartBar.Tong}}</v-chip></span>
                                <v-spacer></v-spacer>
                                <v-autocomplete v-model="SelectedBranch" :items="vueData.DSSelectNganh" item-text="text" item-value="value" label="Chọn nghành" outlined dense hide-details></v-autocomplete>
                            </v-card-title>
                            <v-card-text class="d-flex">
                                <uc-chart  ref="detailNganh" type="bar" :data="DataDetailNganhChartBar.Chart" :options="optionDetailNganhSummary" :plugins="pluginChart"></uc-chart>
                            </v-card-text>
                        </v-card>
                    </v-col>
                    <v-col></v-col>
                    <v-col></v-col>
                    <v-col></v-col>
                    <v-col></v-col>
                </v-row>
            </v-card-text>
        </v-card>
    `
})
<template>
    <div>
        <v-row>
            <v-col cols="1">
                <v-autocomplete
                    v-model="NienKhoaValue"
                    :items="DsNienKhoa"
                    item-text="NienKhoa"
                    item-value="NienKhoa"
                    outlined
                    dense
                    hide-details
                    placeholder="Chọn niên khóa"
                    label="Niên khóa"
                />
            </v-col>
            <v-col class="pl-0" cols="2">
                <v-autocomplete v-model="major" :items="heArr" outlined dense hide-details label="Lọc theo ngành" item-text="TenNganh" item-value="NganhID" />
            </v-col>
            <v-col class="pl-0" cols="1">
                <v-select v-model="DongBoSelect" outlined dense hide-details :items="DongBoList" item-text="text" item-value="value" label="Lọc theo đồng bộ" />
            </v-col>
            <v-col cols="12" class="pt-0">
                <c-table
                    isSearch
                    label="Danh sách học viên tốt nghiệp"
                    :headers="headerTable"
                    :items="dsDeTai"
                    isNew="false"
                    isEdit="false"
                    items-per-page="-1"
                    :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
                >
                    <template v-slot:item.HocVien="{ item }">
                        <span class="green--text">
                            <b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
                        </span>
                        <br />
                        <b>{{ item.Student_ID }}</b>
                        <span class="amber--text"> [{{ item.Lop_ID }}]</span>
                    </template>
                    <template v-slot:item.TrangThai="{ item }">
                        <v-chip v-if="item.TrangThai === 'Đã tốt nghiệp'" label color="success">
                            {{ item.TrangThai }}
                        </v-chip>
                        <v-chip v-if="item.TrangThai === 'Chưa tốt nghiệp'" label color="error">
                            {{ item.TrangThai }}
                        </v-chip>
                        <v-chip v-if="item.TrangThai === 'Không tìm thấy'" label color="purple" dark>
                            {{ item.TrangThai }}
                        </v-chip>
                    </template>
                    <template v-slot:item.TrangThaiIOT="{ item }">
                        <v-chip v-if="item.TrangThaiIOT === 'Đã tốt nghiệp'" label color="success">
                            {{ item.TrangThaiIOT }}
                        </v-chip>
                        <v-chip v-if="item.TrangThaiIOT === 'Chưa tốt nghiệp'" label color="error">
                            {{ item.TrangThaiIOT }}
                        </v-chip>
                        <v-chip v-if="item.TrangThaiIOT === 'Không tìm thấy'" label color="purple" dark>
                            {{ item.TrangThaiIOT }}
                        </v-chip>
                    </template>
                    <template v-slot:item.DongBo="{ item }">
                        <v-icon v-if="item.DongBo === 1" color="success">mdi-check</v-icon>
                        <v-icon v-if="item.DongBo === 0" color="error">mdi-close</v-icon>
                    </template>
                </c-table>
            </v-col>
        </v-row>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            heArr: [],
            DsNienKhoa: [],
            NienKhoaValue: null,
            major: null,

            dsDeTai: [],
            DongBoSelect: -1,
            DongBoList: [
                { text: '- Tất cả -', value: -1 },
                { text: 'Đã đồng bộ', value: 1 },
                { text: 'Chưa đồng bộ', value: 0 },
            ],
            dsDeTaiLHU: [
                {
                    STT: 1,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'A',
                    Lop_ID: 'CNTT 01',
                    Student_ID: '20180001',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Đã tốt nghiệp',
                    DongBo: null,
                },
                {
                    STT: 2,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'B',
                    Lop_ID: 'CNTT 02',
                    Student_ID: '20180002',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Đã tốt nghiệp',
                    DongBo: null,
                },
                {
                    STT: 3,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'C',
                    Lop_ID: 'CNTT 02',
                    Student_ID: '20180003',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Chưa tốt nghiệp',
                    DongBo: null,
                },
            ],

            dsDeTaiIOT: [
                {
                    STT: 1,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'A',
                    Lop_ID: 'CNTT 01',
                    Student_ID: '20180001',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Đã tốt nghiệp',
                    DongBo: null,
                },
                {
                    STT: 2,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'B',
                    Lop_ID: 'CNTT 02',
                    Student_ID: '20180002',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Chưa tốt nghiệp',
                    DongBo: null,
                },
                {
                    STT: 3,
                    Ho_SV: 'Nguyễn Văn',
                    Ten_SV: 'D',
                    Lop_ID: 'CNTT 02',
                    Student_ID: '20180004',
                    Nganh: 'Công nghệ thông tin',
                    NienKhoa: '2018-2022',
                    TrangThai: 'Đã tốt nghiệp',
                    DongBo: null,
                },
            ],

            headerTable: [
                {
                    text: 'STT',
                    align: 'center',
                    sortable: false,
                    width: 50,
                    value: 'STT',
                },
                {
                    text: 'Học viên',
                    value: 'HocVien',
                },
                {
                    text: 'Ngành',
                    value: 'Nganh',
                },
                {
                    text: 'Niên khóa',
                    value: 'NienKhoa',
                    align: 'center',
                    sortable: false,
                    width: 100,
                },
                {
                    text: 'Trạng thái trên LHU',
                    value: 'TrangThai',
                    align: 'center',
                    sortable: false,
                    width: 180,
                },
                {
                    text: 'Trạng thái trên hệ thống',
                    value: 'TrangThaiIOT',
                    align: 'center',
                    sortable: false,
                    width: 180,
                },
                {
                    text: 'Đồng bộ',
                    value: 'DongBo',
                    align: 'center',
                    sortable: false,
                },
            ],
        }
    },
    mounted() {
        this.getNienKhoa()
        this.getHeDaoTao()
        this.compareArr()
    },
    computed: {},
    watch: {},
    methods: {
        compareArr() {
            // Trường hợp IOT có học viên mà LHU không có
            const diff = this.dsDeTaiIOT.filter((item1) => {
                const match = this.dsDeTaiLHU.find((item2) => item1.Student_ID === item2.Student_ID)
                return !match
            })

            const result = this.dsDeTaiLHU.map((item) => {
                const finder = this.dsDeTaiIOT.find((item2) => item.Student_ID === item2.Student_ID)

                let dongBoStatus
                if (finder) {
                    dongBoStatus = item.TrangThai === finder.TrangThai ? 1 : 0
                } else {
                    dongBoStatus = 0
                }

                return {
                    ...item,
                    DongBo: dongBoStatus,
                    // Không tìm thấy, tức là LHU có học viên này nhưng IOT lại không có
                    TrangThaiIOT: finder ? finder.TrangThai : 'Không tìm thấy',
                }
            })

            // Push array
            this.dsDeTai = result
            if (diff.length > 0) {
                diff.forEach((item) => {
                    this.dsDeTai.push({
                        ...item,
                        DongBo: 0,
                        TrangThai: 'Không tìm thấy',
                        TrangThaiIOT: item.TrangThai,
                    })
                })
            }
            this.resetSTT(this.dsDeTai)
            console.log('this.dsDeTai', this.dsDeTai)
        },
        resetSTT(arr){
            arr.forEach((item, index) => {
                item.STT = index + 1
            })
            return arr
        },
        getDsDeTai() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/Public_SelectDeTai`,
            })
        },
        getHeDaoTao() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/Public_SelectHeDaoTao`,
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                crossDomain: true,
                success: function (res) {},
            })
        },
        getNienKhoa() {
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
                    $this.DsNienKhoa = res.data
                    $this.NienKhoaValue = res.data[0].NienKhoa
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
        },
        getHeDaoTao() {
            const $this = this
            $.ajax({
                type: 'GET',
                headers: {
                    authorization: $awt,
                },
                url: `https://tapi.lhu.edu.vn/hoso/AUTH/Public_SelectNganh_CaoHoc`,
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                crossDomain: true,
                success: function (res) {
                    const allListObj = {
                        NganhID: '0',
                        TenNganh: '- Tất cả -',
                    }
                    $this.heArr = res.data
                    $this.heArr.unshift(allListObj)
                    console.log('$this.heArr', $this.heArr)
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
        },
    },
}
</script>

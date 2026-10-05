<template>
	<div>
        <!-- <v-btn @click="onOpenDialog">test</v-btn> -->
        <!-- <f-table
            :headers="headerTable"
            :items="GetAllGV"
            label="Danh sách giảng viên"
            showSearch="true"
            :excel="false"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
            itemsPerPage="-1"
            dense="true"
        /> -->
        <c-table
            isSearch
            label="Danh sách giảng viên"
            :headers="headerCTable"
            :items="GetAllGV"
            isNew="false"
            isEdit="false"
            items-per-page="-1"
            :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
        >
            <template v-slot:item.InpTime="{ item }">
                <f-date v-model="item.ThoiGian" color="success" placeholder="Chọn thời gian" outlined dense hide-details />
            </template>
            <template v-slot:item.printInvite="{ item }">
                <v-btn color="primary" @click="onOpenDialog(item)" :disabled="item.ThoiGian === '' || item.ThoiGian === null" text>In giấy mời</v-btn>
            </template>
        </c-table>

        <select-student-dialog :getgvhd="GetGVHD" />
    </div>
</template>

<script>
	export default {
		props: [],
    data() {
        return {
            NganhHoc: [],
            nganhHocValue: 0,
            DsTaskRegisted: [],
            FilterList: [],
            GetAllGV: [],
            getDetai: [],
            GetGVHD: {},

            headerCTable: [
                {
                    text: 'STT',
                    value: 'STT',
                    sortable: false,
                    align: 'center',
                    width: 50,
                },
                {
                    text: 'Giảng viên hướng dẫn',
                    value: 'GVHD',
                    width: 800,
                },
                {
                    text: 'Thời gian xác định tên đề tài',
                    value: 'InpTime',
                    sortable: false,
                    width: 200,
                },
                {
                    value: 'printInvite',
                },
                {
                    value: 'onPrintInvite',
                },
            ],
        }
    },
    mounted() {
        this.getHeDaoTao()
        this.onLoadTaskRegist()
    },
    computed: {},
    watch: {
        nganhHocValue: function (val) {
            if (val !== null && val !== '') {
            }
        },
        DsTaskRegisted: function (val) {
            if (val) {
                this.FilterList = this.filterUniqueTasks()
                console.log('xxxxxx', this.filterUniqueTasks())
            }
        },
    },
    methods: {
        onOpenDialog(item) {
            this.GetGVHD = item
            vueData.isSelectDialog = true
        },
        async getHeDaoTao() {
            this.NganhHoc = await getNganhCaoHocPromise();
            console.log('$this.heArr', this.NganhHoc);
        },
        onLoadTaskRegist() {
            ajaxCALL(
                '/GetALLGiangVienHuongDan',
                null,
                (res) => {
                    this.GetAllGV = res.data.map((item, index) => {
                        return {
                            ...item,
                            STT: index + 1,
                            ThoiGian: '',
                        }
                    })
                    console.log('this.GetAllGV', this.GetAllGV)
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Fail to load task regist', error)
                },
            )
        },
        filterUniqueTasks() {
            const uniqueTasks = []
            const uniqueValues1 = {}
            const uniqueValues2 = {}

            // Lọc theo ThesisesProf1
            this.DsTaskRegisted.forEach((task) => {
                const key = `${task.ThesisesProf1}`
                if (!uniqueValues1[key]) {
                    uniqueValues1[key] = true
                    uniqueTasks.push(task)
                }
            })

            // Lọc theo ThesisesProf2
            const filteredTasks = []
            uniqueTasks.forEach((task) => {
                const key = `${task.ThesisesProf2}`
                if (!uniqueValues2[key]) {
                    uniqueValues2[key] = true
                    filteredTasks.push(task)
                }
            })

            return filteredTasks
        },
    },
	}
</script>
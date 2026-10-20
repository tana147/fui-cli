<template>
	<div>
		<v-row>
			<v-col cols="4">
				<v-card>
					<v-card-title class="primary--text mb-0 pb-0">
						Danh sách học viên ({{ WaitList.length }})
						<v-spacer></v-spacer>
						<v-text-field class="mb-5" v-model="search" append-icon="mdi-magnify" label="Search"
							single-line="" hide-details="">
						</v-text-field></v-card-title>

					<v-btn class="mb-3 ml-3" @click="addAllHV" color="primary"><v-icon dense="" smal=""
							left="">mdi-plus</v-icon> Thêm tất cả</v-btn>
					<v-data-table :items="WaitList" :headers="headerTable" :search="search" dense items-per-page="-1"
						:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
						<template v-slot:item.STT="{ item, index }">
							{{ index + 1 }}
						</template>
						<template v-slot:item.Select="{ item }">
							<v-btn @click="addHV(item)" x-small fab icon>
								<v-icon color="primary">mdi-plus</v-icon>
							</v-btn>
						</template>
						<template v-slot:item.Student_ID="{ item }">
							<span class="primary--text">
								<b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
							</span>
							<br />
							<b>{{ item.Student_ID }}</b>
							<span class="amber--text"> [{{ item.Lop_ID }}]</span>
						</template>
						<template v-slot:item.Topic="{ item }">
							<b>{{ item.Thesis_Name }}</b> <br />
							<span v-if="!item.Thesises_Prof2"> GVHD: {{ item.Thesises_Prof1 }} </span>
							<span v-else>
								GVHD 1: {{ item.Thesises_Prof1 }} <br />
								GVHD 2: {{ item.Thesises_Prof2 }}
							</span>
						</template>
					</v-data-table>
				</v-card>
			</v-col>
			<v-col cols="8">
				<!-- Danh sách đã chọn -->
				<v-card>
					<v-card-title class="primary--text mb-0 pb-0">
						Học viên đã chọn ({{ localStudentList.length }})
						<v-spacer></v-spacer>
						<v-text-field class="mb-5" v-model="searchHV" append-icon="mdi-magnify" label="Search"
							single-line="" hide-details="">
						</v-text-field></v-card-title>

					<v-btn class="mb-3 ml-3" @click="deleteAll" color="error"><v-icon dense="" smal=""
							left="">mdi-trash-can</v-icon> Xóa tất cả</v-btn>

					<v-data-table :items="localStudentList" :headers="headerSelectTable" :search="searchHV" dense=""
						items-per-page="-1" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
						<template v-slot:item.STT="{ item, index }">
							{{ index + 1 }}
						</template>
						<template v-slot:item.Student_ID="{ item }">
							<span class="primary--text">
								<b> {{ item.Ho_SV }} {{ item.Ten_SV }}</b>
							</span>
							<br>
							<b>{{ item.Student_ID }}</b>
							<span class="amber--text"> [{{ item.Lop_ID }}]</span>
						</template>
						<template v-slot:item.Thesis_Name="{ item }">
							<b>{{ item.Thesis_Name }}</b> <br>
							<span v-if="!item.Thesises_Prof2"> GVHD: {{ item.Thesises_Prof1 }} </span>
							<span v-else="">
								GVHD 1: {{ item.Thesises_Prof1 }} <br>
								GVHD 2: {{ item.Thesises_Prof2 }}
							</span>
						</template>
						<template v-slot:item.DelHV="{ item }">
							<v-btn @click="removeHV(item)" x-small="" fab="" icon="">
								<v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
							</v-btn>
						</template>
					</v-data-table>
				</v-card>
			</v-col>
		</v-row>
	</div>
</template>

<script>
	export default {
		props: ['onChangeData', 'nganhid', 'detailstudent', 'detaildecision', 'isedit', 'waitlistprop', 'studentdata', 'nienkhoa', 'studentlist', 'thstype'],
	    data() {
	        return {
	            WaitList: [],
	            MajorList: [],
	            SelectedList: [],
	            search: '',
	            searchHV: '',
	            localStudentList: [],
	
	            headerTable: [
	                {
	                    text: 'Chọn',
	                    value: 'Select',
	                    width: 50,
	                    sortable: false,
	                    align: 'center',
	                },
	                {
	                    text: 'STT',
	                    value: 'STT',
	                    sortable: false,
	                    align: 'center',
	                    width: 50,
	                },
	                {
	                    text: 'Học viên',
	                    value: 'Student_ID',
	                    width: 150,
	                },
	                {
	                    text: 'Niên khóa',
	                    value: 'Nien_Khoa',
	                    width: 100,
	                    sortable: false,
	                    align: 'center',
	                },
	                {
	                    text: 'Tên đề tài',
	                    value: 'Topic',
	                },
	            ],
	            headerSelectTable: [
	                {
	                    text: 'STT',
	                    value: 'STT',
	                    sortable: false,
	                    align: 'center',
	                    width: 50,
	                },
	                {
	                    text: 'Học viên',
	                    value: 'Student_ID',
	                    width: 150,
	                },
	                {
	                    text: 'Niên khóa',
	                    value: 'Nien_Khoa',
	                    width: 150,
	                },
	                {
	                    text: 'Tên đề tài',
	                    value: 'Thesis_Name',
	                },
	                {
	                    text: 'Xóa',
	                    value: 'DelHV',
	                    width: 50,
	                    sortable: false,
	                    align: 'center',
	                },
	            ],
	        }
	    },
	    computed: {
	        NganhID: function () {
	            return this.nganhid
	        },
	        DetailStudent: function () {
	            console.log('this.detailstudent', this.detailstudent)
	            return this.detailstudent
	        },
	        DetailDecision: function () {
	            return this.detaildecision
	        },
	        NienKhoa: function () {
	            return this.nienkhoa
	        },
	    },
	    watch: {
            isedit(val){
                console.log("val tttttt", val)
            },
	        NganhID: function () {
	            this.getStudentByMajor()
	        },
	        studentlist: function (val) {
	            console.log('studentlistxxxxxx', val)
                this.localStudentList = val
	        },
	        localStudentList: {
	            handler: function (val) {
	                const $this = this
	                this.$emit('waitlistprop', val)
	                this.$emit('studentdata', val)
	                $this.$emit('onChangeData', val)
	            },
	            deep: true,
	        },
	        NienKhoa: function (val) {
	            this.getStudentByMajor()
	        },
	        thsType: function (val) {
	            if (this.NienKhoa == '106' && val) {
	                this.getStudentByMajor()
	            }
	        },
	    },
	    mounted() {
	        this.getStudentByMajor()
	        console.log('this.studentlistxxxxxx', this.studentlist)
	        this.localStudentList = this.studentlist
	    },
	    methods: {
	        resetSTT(arr) {
	            return arr.map((item, index) => {
	                return {
	                    ...item,
	                    SoThuTu: index + 1,
	                }
	            })
	        },
	        addAllHV() {
	            const $this = this
	            console.log(this.WaitList, this.localStudentList) // Kiểm tra giá trị
	
	            $this.WaitList.forEach((item) => {
	                if (!$this.localStudentList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
	                    $this.localStudentList.push(item)
	                }
	            })
	
	            // Gọi hàm resetSTT để cập nhật lại STT
	            $this.localStudentList = $this.resetSTT($this.localStudentList)
	        },
	        addHV(item) {
	            const $this = this
	            if (!$this.localStudentList.some((selectedItem) => selectedItem.Student_ID === item.Student_ID)) {
	                $this.localStudentList.push(item)
	            } else {
	                Vue.$toast.error(`Học viên đã tồn tại`, { position: 'top' })
	            }
	
	            $this.localStudentList = $this.resetSTT($this.localStudentList)
	        },
	        deleteAll() {
	            this.localStudentList = []
	        },
	        removeHV(item) {
	            const index = this.localStudentList.indexOf(item)
	            console.log('this.localStudentList', this.localStudentList)
	
	            if (index !== -1) {
	                this.localStudentList.splice(index, 1) // Xóa phần tử
	
	                // Gọi lại resetSTT để cập nhật lại STT
	                this.localStudentList = this.resetSTT(this.localStudentList)
	            }
	        },
	        getStudentByMajor() {
	            const $this = this
	            let processId = 1
	            console.log('this.thsType', this.thsType)
	            if (this.thsType == '1') {
	                if ($this.NganhID == '102' || $this.NganhID == '106') {
	                    processId = 4
	                }
	            } else if (this.thsType == '2') {
	                if ($this.NganhID == '102' || $this.NganhID == '106') {
	                    processId = 1
	                }
	            }
	            if ($this.NganhID) {
	                ajaxCALL(
	                    '/Get_StudentWaitForThesisConfirm',
	                    {
	                        Process_ID: processId,
	                        Nganh_ID: $this.NganhID,
	                        Nien_Khoa: $this.NienKhoa,
	                    },
	                    (res) => {
	                        $this.WaitList = res.data.map((item, index) => {
	                            return {
	                                ...item,
	                                IsSelected: this.DetailStudent.filter((itemST) => itemST.Student_ID === item.Student_ID).length > 0 ? true : false,
	                                SoThuTu: index + 1,
	                            }
	                        })
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    },
	                )
	            }
	        },
	    },
	}
</script>
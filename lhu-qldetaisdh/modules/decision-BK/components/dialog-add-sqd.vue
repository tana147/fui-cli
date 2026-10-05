<template>
	<v-dialog v-model="isDialogAdd" transition="dialog-bottom-transition" fullscreen persistent>
		<v-card>
			<v-toolbar color="primary" dark class="toolbar">
				<h3>Thêm mới quyết định</h3>
				<v-spacer></v-spacer>
				<v-icon @click="onClose">mdi-close</v-icon>
			</v-toolbar>
			<v-card-text class="mt-3">
				<h3 class="primary--text mb-3">Thông tin quyết định</h3>
				<v-row>
					<v-col cols="1">
						<v-autocomplete v-model="AddData.Decision_Type" outlined label="Hệ đào tạo" item-text="VALUE"
							item-value="KEY" dense :items="heDaoTaoValues" hide-details />
					</v-col>

					<v-col cols="2">
						<v-autocomplete v-model="AddData.Decision_NganhID" outlined label="Lọc theo ngành" dense
							:items="nganhArr" item-text="TenNganh" item-value="NganhID" hide-details
							style="width: 100%" />
					</v-col>

					<v-col cols="1">
						<v-select outlined color="success" dense label="Niên khóa" :items="NienKhoaArr"
							v-model="AddData.Decision_NienKhoa" hide-details item-text="Nien_Khoa"
							item-value="Nien_Khoa" :disabled="AddData.Decision_NganhID === null" />
					</v-col>
					<v-col cols="1">
						<v-text-field outlined color="success" dense label="Mã ngành" placeholder="Nhập mã ngành"
							v-model="AddData.Decision_MaSo" hide-details disabled />
					</v-col>
					<v-col cols="1">
						<v-text-field outlined color="success" dense label="Đợt" placeholder="Nhập đợt"
							v-model="AddData.Decision_Dot" hide-details />
					</v-col>
					<v-col cols="3">
						<v-select v-model="decisionTypeSelect" :items="decistionTypeList" item-text="text"
							item-value="value" label="Loại quyết định" outlined dense hide-details />
					</v-col>
				</v-row>
				<div v-if="AddData.Decision_NganhID == '106' || AddData.Decision_NganhID == '102'">
					<v-radio-group v-model="thsType" row mandatory>
						<v-radio value="1" label="Thạc sĩ ứng dụng" />
						<v-radio value="2" label="Thạc sĩ nghiên cứu" />
					</v-radio-group>
				</div>
				<v-row>
					<v-col>
						<student-list-add :nienkhoa="AddData.Decision_NienKhoa" :thstype="thsType"
							@onChangeData="(value) => (Student_Obj = value)" :NganhID="AddData.Decision_NganhID"
							@waitlistprop="(val) => (propData = val)" @studentdata="(val) => (studentData = val)"
							:isdelete="isDelete" />
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<div class="selectNienKhoaWrap mr-3">
					<v-select outlined color="success" dense label="Niên khóa QĐ" :items="NienKhoaArr"
						v-model="AddData.Decision_Ins_NienKhoa" hide-details item-text="Nien_Khoa"
						item-value="Nien_Khoa" :disabled="AddData.Decision_NganhID === null" />
				</div>
				<v-btn color="success" @click="onAddDecision" :disabled="Student_Obj.length === 0">
					<v-icon>mdi-plus</v-icon>Tạo </v-btn>
				<!--  -->
				<v-btn color="info" :disabled="Student_Obj.length === 0" @click="addAndPrint">
					<v-icon>mdi-printer</v-icon>In </v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ['isDialogAdd', 'nganhArr'],
	    data() {
	        return {
	            AddData: {
	                Decision_TieuDe: '',
	                Decision_Nganh: '',
	                Decision_NienKhoa: '',
	                Decision_Ins_NienKhoa: '',
	                Decision_Dot: '',
	                Decision_MaSo: '',
	                Decision_Type: '',
	                Decision_NganhID: null,
	                Decision_Description: '',
	            },
	            thsType: '1',
	            typeList: ['Thạc sĩ', 'Tiến sĩ'],
	            Student_Obj: [],
	            heTemp: [],
	            propData: [],
	            studentData: [],
	            NienKhoaArr: [],
	            isEmptySudent: false,
	            isDelete: false,
	
	            decisionTypeSelect: 1,
	
	            decistionTypeList: [
	                {
	                    text: 'Giao đề tài',
	                    tieuDe: 'Về việc công nhận tên đề tài và giảng viên hướng dẫn luận văn thạc sĩ',
	                    value: 1,
	                },
	                {
	                    text: 'Đổi tên đề tài',
	                    tieuDe: 'Về việc đổi tên đề tài luận văn thạc sĩ',
	                    value: 2,
	                },
	                {
	                    text: 'Đổi tên Giảng viên hướng dẫn',
	                    tieuDe: 'Về việc đổi giảng viên hướng dẫn luận văn thạc sĩ',
	                    value: 3,
	                },
	                {
	                    text: 'Điều chỉnh đề tài',
	                    tieuDe: 'Về việc điều chỉnh tên đề tài luận văn thạc sĩ',
	                    value: 4,
	                },
	                {
	                    text: 'Điều chỉnh giảng viên hướng dẫn',
	                    tieuDe: 'Về việc điều chỉnh giảng viên hướng dẫn luận văn thạc sĩ',
	                    value: 5,
	                },
	                {
	                    text: 'Đổi tên đề tài và giảng viên hướng dẫn',
	                    tieuDe: 'Về việc đổi tên đề tài và giảng viên hướng dẫn',
	                    value: 6,
	                },
	            ],
	        }
	    },
	    computed: {
	        heDaoTaoValues() {
	            // Chuyển đổi mảng heDaoTao thành mảng chứa các giá trị VALUE
	            return vueData.heDaoTao
	        },
	    },
	    watch: {
	        'AddData.Decision_NienKhoa': function (val) {
	            if (val) {
	                console.log('val vvvvvvvvvv', val)
	                this.AddData.Decision_Ins_NienKhoa = val
	            }
	        },
	        isDialogAdd: function (val) {
	            if (val) {
	                // getHeByID()
	            }
	        },
	
	        'AddData.Decision_NganhID': function (newVal) {
	            if (newVal) {
	                console.log('newVal xxxx', newVal)
	                this.onLoadNienKhoa(newVal)
	                this.AddData.Decision_NienKhoa = null
	
	                const selectMajor = this.nganhArr.find((item) => item.NganhID === newVal)
	                console.log('selectMajor', selectMajor)
	                if (selectMajor) {
	                    this.AddData.Decision_MaSo = selectMajor.MaNganh ?? ""
	                    this.AddData.Decision_Nganh = selectMajor
	                        ? (selectMajor.OriginalName || selectMajor.TenNganh || "")
	                        : "";
	                    console.log('this.AddData.Decision_Nganh', this.AddData.Decision_Nganh)
	                }
	            }
	        },
	
	        'AddData.Decision_Type': function (val) {
	            console.log('val', val)
	            const $this = this
	            console.log('$this.decisionTypeSelect', $this.decisionTypeSelect)
	
	            const selectedType = vueData.heDaoTao.find((item) => item.KEY === val)
	            const filterDecision = this.decistionTypeList.find((item) => item.value === $this.decisionTypeSelect)
	            console.log('filterDecision YYYY', filterDecision)
	            console.log('selectedType CCCCCC', selectedType)
	            if (selectedType) {
	                const isC = selectedType.KEY === 'C'
	                $this.AddData.Decision_TieuDe = isC ? ($this.decisionTypeSelect == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe) : selectedType.SUBJECT
	                // getHeByID(selectedType.KEY)
	                console.log('$this.AddData.Decision_TieuDe YYYYYYYYY', $this.AddData.Decision_TieuDe)
	            }
	        },
	
	        decisionTypeSelect: function (val) {
	            const $this = this
	            const selectedType = vueData.heDaoTao.find((item) => item.KEY === $this.AddData.Decision_Type)
	            const filterDecision = this.decistionTypeList.find((item) => item.value === val)
	            console.log('filterDecision', filterDecision)
	            console.log('selectedTypexxx', selectedType)
	            if (selectedType) {
	                const isC = selectedType.KEY === 'C'
	                $this.AddData.Decision_TieuDe = isC ? (val == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe) : selectedType.SUBJECT
	
	                console.log('$this.AddData.Decision_TieuDe XXXXXXXXXX', $this.AddData.Decision_TieuDe)
	            }
	        },
	
	        propData: function (val) {
	            if (this.studentData.length > 0) {
	                // this.isEmptySudent = false
	                if (val.length === 0 && this.studentData.length > 0) {
	                    Vue.$toast.error(`Không được bỏ chọn toàn bộ học viên`, { position: 'top' })
	                    this.isEmptySudent = true
	                    console.log('studentData', this.studentData)
	                } else {
	                    this.isEmptySudent = false
	                }
	            } else {
	                this.isEmptySudent = true
	            }
	        },
	        thsType: function (val) {
	            console.log('val yyy', val, this.AddData.Decision_NganhID)
	            if (this.AddData.Decision_NganhID == '106' || (this.AddData.Decision_NganhID == '102' && val)) {
	                this.onLoadNienKhoa(this.AddData.Decision_NganhID)
	            }
	        },
	    },
	    mounted() {
	        getHeDaoTao()
	    },
	    methods: {
	        onClose() {
	            this.isDelete = true
	            this.resetAddData()
	            this.$emit('update:isDialogAdd', false)
	        },
	
	        resetAddData() {
	            this.AddData.Decision_TieuDe = ''
	            this.AddData.Decision_Nganh = ''
	            this.AddData.Decision_NganhID = 0
	            this.AddData.Decision_NienKhoa = ''
	            this.AddData.Decision_Dot = ''
	            this.AddData.Decision_MaSo = ''
	            this.AddData.Decision_Type = ''
	            this.AddData.Decision_Description = ''
	            this.decisionTypeSelect = 1
	            this.studentData = []
	        },
	
	        onAddDecision() {
	            const $this = this
	            if (!this.AddData.Decision_Type) {
	                Vue.$toast.error(`Không được bỏ trống hệ đào tạo`, { position: 'top' })
	                return
	            }
	            if (!this.AddData.Decision_NganhID) {
	                Vue.$toast.error(`Không được bỏ trống ngành học`, { position: 'top' })
	                return
	            }
	
	            if (this.AddData.Decision_NienKhoa !== '' && this.AddData.Decision_MaSo !== '') {
	                // Lọc StudentID
	                let filterStudent_ObjID = this.Student_Obj.map((item) => item.Student_ID)
	                const type = $this.AddData.Decision_Type === 'C' || $this.AddData.Decision_Type === 'N' ? 'Cao Học' :
	                    $this.AddData.Decision_Type
	                if (filterStudent_ObjID.length > 0) {
	                    console.log('filterStudent_ObjIDxxx', filterStudent_ObjID)
	                    const ajaxPromise = new Promise((resolve, reject) => {
	                        ajaxCALL(
	                            '/Decision_Ins',
	                            {
	                                Decision_Obj: {
	                                    Decision_TieuDe: $this.AddData.Decision_TieuDe,
	                                    Decision_NganhID: $this.AddData.Decision_NganhID,
	                                    Decision_Nganh: $this.AddData.Decision_Nganh,
	                                    Decision_NienKhoa: $this.AddData.Decision_Ins_NienKhoa,
	                                    Decision_Dot: $this.AddData.Decision_Dot,
	                                    Decision_MaSo: $this.AddData.Decision_MaSo,
	                                    Decision_Type: type,
	                                    Decision_Description: $this.AddData.Decision_Description,
	                                    Decision_TemplateID: 1,
	                                },
	                                Student_Obj: {
	                                    Student_ID: filterStudent_ObjID,
	                                },
	                            },
	                            (res) => {
	                                resolve(res) // Giải quyết Promise nếu API gọi thành công
	                            },
	                            (error) => {
	                                Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                                reject(error) // Từ chối Promise nếu có lỗi
	                            },
	                        )
	                    })
	                    // Xử lý Promise
	                    ajaxPromise
	                        .then((res) => {
	                            Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
	                            getDecision()
	                            // this.AddData.Decision_NganhID = null
	                            this.resetAddData()
	                            this.$emit('update:isDialogAdd', false)
	                        })
	                        .catch((error) => {
	                            console.log('Add decision error: ', error)
	                            this.isDialogAdd = false
	                        })
	                } else {
	                    Vue.$toast.error(`Chưa chọn học viên`, { position: 'top' })
	                }
	            } else {
	                Vue.$toast.error(`Chưa nhập đủ Đợt, Niên Khóa, Mã ngành`, { position: 'top' })
	            }
	        },
	
	        addAndPrint() {
	            const $this = this
                if(!this.AddData.Decision_Nganh){
                    Vue.$toast.error(`Không tìm thấy ngành`, { position: 'top' })
                    return
                }

	            if (this.AddData.Decision_Type !== '' && this.AddData.Decision_NganhID !== '') {
	                if (this.AddData.Decision_NienKhoa !== '' && this.AddData.Decision_MaSo !== '') {
	                    //Lọc StudentID
	                    let filterStudent_ObjID = this.Student_Obj.map((item) => item.Student_ID)
	                    if (filterStudent_ObjID.length > 0) {
	                        ajaxCALL(
	                            '/Decision_Ins',
	                            {
	                                Decision_Obj: {
	                                    Decision_TieuDe: $this.AddData.Decision_TieuDe,
	                                    Decision_Nganh: $this.AddData.Decision_Nganh,
	                                    Decision_NganhID: $this.AddData.Decision_NganhID,
	                                    Decision_NienKhoa: $this.AddData.Decision_Ins_NienKhoa,
	                                    Decision_Dot: $this.AddData.Decision_Dot,
	                                    Decision_MaSo: $this.AddData.Decision_MaSo,
	                                    Decision_Type: $this.AddData.Decision_Type,
	                                    Decision_Description: $this.AddData.Decision_Description,
	                                    Decision_TemplateID: 1,
	                                },
	                                Student_Obj: {
	                                    Student_ID: filterStudent_ObjID,
	                                },
	                            },
	                            (res) => {
	                                Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
	                                htmlToPdf(parseInt(res.data[0].Decision_ID), $this.AddData.Decision_Type)
	                                getDecision()
	                                this.$emit('update:isDialogAdd', false)
	                            },
	                            (error) => {
	                                console.log('Add decision error: ', error)
	                                Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                            },
	                        )
	                        this.isDialogAdd = false
	                    } else {
	                        Vue.$toast.error(`Chưa chọn học viên`, { position: 'top' })
	                    }
	                } else {
	                    Vue.$toast.error(`Chưa nhập đủ Đợt, Niên Khóa, Mã ngành`, { position: 'top' })
	                }
	            } else {
	                Vue.$toast.error(`Không được bỏ trống hệ đào tạo và ngành học`, { position: 'top' })
	            }
	        },
	
	        onLoadNienKhoa(nganhID) {
	            let processId = 1
	            console.log('this.thsType', this.thsType)
	            if (this.thsType === '1') {
	                if (nganhID == '102' || nganhID == '106') {
	                    processId = 4
	                }
	            } else if (this.thsType === '2') {
	                if (nganhID == '102' || nganhID == '106') {
	                    processId = 1
	                }
	            }
	            console.log('processId', processId)
	            ajaxCALL(
	                '/Get_NienKhoa_StudentWaitForThesisConfirm',
	                {
	                    // nganhID == '102' || (nganhID == '106' && this.thsType === '1') ? 4 : 1,
	                    // (nganhID == '102' && this.thsType === '1' ? 4 : nganhID == '102' && this.thsType === '2' ? 1 : nganhID == '106' &&
	                    // this.thsType === '1' ? 4 : 1)
	                    Process_ID: processId,
	                    // nganhID == 102 ? 4 : 1
	                    Nganh_ID: nganhID,
	                },
	                (res) => {
	                    this.NienKhoaArr = res.data
	                    console.log('this.NienKhoaArr', this.NienKhoaArr)
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('fail to load nien khoa', error)
	                },
	            )
	        },
	    },
	}
</script>
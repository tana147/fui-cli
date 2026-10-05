<template>
	<v-dialog v-model="isEdit" transition="dialog-bottom-transition" fullscreen="" persistent="">
		<v-card>
			<v-toolbar class="toolbar" color="info" dark="">
				<h3 class="mb-0">Cập nhật quyết định</h3>
				<v-spacer></v-spacer>
				<v-icon @click="$emit('update:isEdit', false)">mdi-close</v-icon>
			</v-toolbar>
			<v-card-text class="mt-3">
				<h3 class="primary--text mb-3">Thông tin quyết định</h3>
				<v-row>
					<!-- <v-col cols="1">
                        <v-autocomplete
                            outlined
                            label="Hệ đào tạo"
                            dense
                            :items="heDaoTaoValues"
                            hide-details
                            v-model="DetailDecision.Decision_Type"
                            :disabled="DetailDecision.Decision_Status === 3"
                        />
                    </v-col> -->
					<v-col cols="2">
						<v-autocomplete v-model="DetailDecision.Decision_NganhID" outlined="" label="Lọc theo ngành"
							dense="" :items="nganhArr" item-text="TenNganh" item-value="NganhID" hide-details=""
							:disabled="DetailDecision.Decision_Status === 3">
						</v-autocomplete></v-col>
					<!-- <v-col cols="2">
                        <v-text-field
                            outlined
                            color="success"
                            dense
                            label="Ngành"
                            placeholder="Nhập ngành"
                            v-model="DetailDecision.Decision_Nganh"
                            hide-details
                            :disabled="DetailDecision.Decision_Status === 3"
                        />
                    </v-col> -->
					<v-col cols="1">
						<div v-if="DetailDecision.Decision_NienKhoa">
							<v-autocomplete outlined="" color="success" dense="" label="Niên khóa"
								placeholder="Nhập niên khóa" v-model="DetailDecision.Decision_NienKhoa" hide-details=""
								:disabled="DetailDecision.Decision_Status === 3" :items="NienKhoaArr"
								item-text="Nien_Khoa" item-value="Nien_Khoa">
							</v-autocomplete>
						</div>
						<div v-else="">
							<v-text-field outlined="" color="success" dense="" label="Mã ngành"
								placeholder="Nhập mã ngành" v-model="nienKhoaData" hide-details="" disabled="">
							</v-text-field>
						</div>
					</v-col>
					<v-col cols="1">
						<v-text-field outlined="" color="success" dense="" label="Mã ngành" placeholder="Nhập mã ngành"
							v-model="DetailDecision.Decision_MaSo" hide-details="" disabled="">
						</v-text-field></v-col>
					<v-col cols="1">
						<v-text-field outlined="" color="success" dense="" label="Đợt" placeholder="Nhập đợt"
							v-model="DetailDecision.Decision_Dot" hide-details=""
							:disabled="DetailDecision.Decision_Status === 3">
						</v-text-field></v-col>
					<v-col cols="3">
						<v-select v-model="decisionTypeSelect" :items="decistionTypeList" item-text="text"
							item-value="value" label="Loại quyết định" outlined="" dense="" hide-details="">
						</v-select></v-col>
				</v-row>
				<div v-if="DetailDecision.Decision_NganhID == 106">
                    <v-radio-group v-model="thsType" row mandatory>
                        <v-radio value="1" label="Thạc sĩ ứng dụng" />
                        <v-radio value="2" label="Thạc sĩ nghiên cứu" />
                    </v-radio-group>
				</div>
				<v-row>
					<v-col>
						<student-edit-table v-if="DetailDecision.Decision_Status !== 3"
							:studentlist="vueData.detailStudent" :thstype="thsType"
							@onChangeData="(value) => (Student_Obj = value)" :detailstudent="DetailStudent"
							:nganhid="DetailDecision.Decision_NganhID" :detaildecision="DetailDecision" :isedit="isEdit"
							@waitlistprop="(val) => (propData = val)" @studentdata="(val) => (studentData = val)"
							:nienkhoa="DetailDecision.Decision_NienKhoa" />
						<student-detail-table v-else :studentlist="vueData.detailStudent"
							:nganhid="DetailDecision.Decision_NienKhoa" />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<div class="selectNienKhoaWrap mr-3">
					<v-autocomplete outlined="" color="success" dense="" label="Niên khóa" placeholder="Nhập niên khóa"
						v-model="nienKhoaSelected" hide-details="" :disabled="DetailDecision.Decision_Status === 3"
						:items="NienKhoaArr" item-text="Nien_Khoa" item-value="Nien_Khoa">
					</v-autocomplete>
				</div>
				<!--disabled: DetailDecision.Decision_Status === 3 || -->
				<v-btn color="success" @click="onUpdateDecision" :disabled="isEmptySudent"><v-icon
						class="mr-1 mb-1">mdi-update</v-icon>Cập nhật</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: ['isEdit', 'majorlist', 'detaildecision', 'detailstudent', 'hearr', 'nganhArr'],
	    data() {
	        return {
	            typeList: ['Thạc sĩ', 'Tiến sĩ'],
	            Student_Obj: [],
	            propData: [],
	            studentData: [],
	            NienKhoaArr: [],
	            nienKhoaData: '',
	            isEmptySudent: false,
	            selectMajor: '',
	            nienKhoaSelected: '',
	            thsType: '1',
	            decisionTypeSelect: 1,
	
	            decistionTypeList: [
	                {
	                    text: 'Giao đề tài',
	                    tieuDe: null,
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
	        MajorList: function () {
	            return this.majorlist
	        },
	        DetailDecision: function () {
	            return this.detaildecision
	        },
	        DetailStudent: function () {
	            return this.detailstudent
	        },
	        heDaoTaoValues() {
	            // Chuyển đổi mảng heDaoTao thành mảng chứa các giá trị VALUE
	            return vueData.heDaoTao.map((item) => item.VALUE)
	        },
	    },
	    watch: {
	        isEdit(val) {
	            if (val) {
	                this.DetailDecision.Decision_NganhID = this.DetailDecision.Decision_NganhID ? this.DetailDecision.Decision_NganhID.toString() : this.DetailDecision.Decision_NganhID
	            }
	        },
	        'DetailDecision.Decision_NganhID': function (val) {
	            this.onLoadNienKhoa(val)
	
	            //lấy niên khóa từ vueData.detailStudent
	            this.nienKhoaData = vueData.detailStudent[0]?.Nien_Khoa
	
	            const selectNganh = this.nganhArr.find((item) => item.NganhID === val)
	
	            this.DetailDecision.Decision_Nganh = selectNganh
	                ? (selectNganh.OriginalName || selectNganh.TenNganh || "")
	                : ""
	        },
	        propData: function (val) {
	            if (this.studentData.length > 0) {
	                if (val.length === 0) {
	                    Vue.$toast.error(`Danh sách không có học viên`, { position: 'top' })
	                    this.isEmptySudent = true
	                } else {
	                    this.isEmptySudent = false
	                }
	            } else {
	                this.isEmptySudent = true
	            }
	        },
	        'DetailDecision.Decision_NienKhoa': function (val) {
	            if (val) {
	                this.nienKhoaSelected = val
	            }
	        },
	        thsType: function (val) {
	            if (this.DetailDecision.Decision_NganhID == '106' && val) {
	                this.onLoadNienKhoa('106')
	            }
	        },
	        decisionTypeSelect: function (val) {
	            const $this = this
	            const selectedType = vueData.heDaoTao.find((item) => item.KEY === $this.DetailDecision.Decision_Type)
	            const filterDecision = this.decistionTypeList.find((item) => item.value === val)
	            if (selectedType) {
	                const isC = selectedType.KEY === 'C'
	                $this.DetailDecision.Decision_TieuDe = isC ? (val == 1 ? selectedType.SUBJECT : filterDecision?.tieuDe) : selectedType.SUBJECT
	            }
	        },
	        detaildecision: function (val) {
	            if (val) {
	                this.decisionTypeSelect = val.Decision_TieuDe.includes('đổi tên đề tài') ? 2 : val.Decision_TieuDe.includes('điều chỉnh tên đề tài') ? 3 : 1
	            }
	        },
	    },
	    mounted() { },
	    methods: {
	        onUpdateDecision() {
	            const $this = this
	            let filterStudent_ObjID = this.Student_Obj.map((item) => item.Student_ID)
	
	            if (
	                $this.DetailDecision.Decision_Nganh &&
	                $this.DetailDecision.Decision_Dot !== '' &&
	                $this.DetailDecision.Decision_NienKhoa !== '' &&
	                $this.DetailDecision.Decision_MaSo !== ''
	            ) {
	                ajaxCALL(
	                    '/Decision_Udp',
	                    {
	                        Decision_Obj: {
	                            Decision_ID: $this.DetailDecision.Decision_ID,
	                            Decision_TieuDe: $this.DetailDecision.Decision_TieuDe,
	                            Decision_NganhID: $this.DetailDecision.Decision_NganhID,
	                            Decision_Nganh: $this.DetailDecision.Decision_Nganh,
	                            Decision_NienKhoa: $this.nienKhoaSelected,
	                            Decision_Dot: $this.DetailDecision.Decision_Dot,
	                            Decision_MaSo: $this.DetailDecision.Decision_MaSo,
	                            Decision_Type: $this.DetailDecision.Decision_Type,
	                            Decision_Description: $this.DetailDecision.Decision_Description,
	                            Decision_TemplateID: 1,
	                        },
	
	                        Student_Obj: {
	                            Student_ID: filterStudent_ObjID,
	                            Decision_ID: $this.DetailDecision.Decision_ID,
	                        },
	                    },
	                    (res) => {
	                        Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
	                        $this.$emit('update:isEdit', false)
	                        getDecision()
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('Update fail', error)
	                    },
	                )
	            } else {
	                Vue.$toast.error(`Không được bỏ trống Ngành, Đợt, Niên khóa, Mã ngành`, { position: 'top' })
	            }
	        },
	
	        onLoadNienKhoa(nganhID) {
	            ajaxCALL(
	                '/Get_NienKhoa_StudentWaitForThesisConfirm',
	                {
	                    Process_ID: nganhID == '102' || (nganhID == '106' && this.thsType === '1') ? 4 : 1,
	                    Nganh_ID: nganhID,
	                },
	                (res) => {
	                    this.NienKhoaArr = res.data
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
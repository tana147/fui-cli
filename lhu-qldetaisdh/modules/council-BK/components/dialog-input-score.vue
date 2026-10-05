<template>
	<div>
		<v-dialog v-model="vueData.isInputDialog" transition="dialog-bottom-transition" max-width="1600px" persistent>
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">
							Nhập điểm HV:
							<span class="red--text">[{{ thongTinHocVien.Student_ID }}] {{ thongTinHocVien.Ho_SV }}
								{{ thongTinHocVien.Ten_SV }}
								[{{ thongTinHocVien.Lop_ID }}] <v-chip v-if="dshoidongId?.Is_PublishDiem === 1"
									color="primary">Đã công bố điểm</v-chip>
							</span>
						</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-row>
						<v-col cols="12" class="p-0 pb-0">
							<h3>Biên bản họp</h3>
							<file-comp-custom :publishstatus="dshoidongId?.Is_PublishDiem" :getdiem="getdiem"
								:item="hoiDongObj"></file-comp-custom>
						</v-col>
						<v-col cols="12" class="p-0 pb-0 pt-0">
							<div>
								<h3>Biển bản kiểm phiếu</h3>
								<file-comp-custom-KD :publishstatus="dshoidongId?.Is_PublishDiem" :getdiem="getdiem"
									:item="hoiDongObj"></file-comp-custom-KD>
							</div>
						</v-col>
						<v-col cols="12" class="p-0 pb-0 pt-0">
							<v-textarea auto-grow rows="1" placeholder="Nhập ghi chú" label="Ghi chú"
								v-model="hoiDongObj.NhanXet" outlined dense hide-details
								:readonly="dshoidongId?.Is_PublishDiem === 1" />
						</v-col>
						<v-col class="pb-0">
							<div>
								<v-data-table :headers="headertable" :items="dsHoiDong" hide-default-footer dense>
									<template v-slot:item.stt="{ item, index }">
										{{ index + 1 }}
									</template>
									<template v-slot:item.FileNhanXet="{ item, index }">
										<file-comp class="ml-14" :getdiem="getdiem[1][index]" :item="item" />
									</template>
									<template v-slot:item.FileDiem="{ item, index }">
										<file-comp-diem class="ml-14" :getdiem="getdiem[1][index]" :item="item" />
									</template>
									<template v-slot:item.NhanXet="{ item, index }">
										<v-textarea hide-details outlined dense auto-grow rows="1"
											v-model="item.NhanXet" :readonly="item.Is_PublishDiem === 1" />
										<!-- :readonly="item.Is_PublishDiem === 1" -->
									</template>
									<template v-slot:item.Diem="{ item, index }">
										<v-text-field reverse outlined hide-details dense v-model="item.Diem"
											type="number" :hint="item.Data_Exp" @input="updateDiem(item)"
											@blur="formatDiem(item)" :readonly="item.Is_PublishDiem === 1" />
										<!-- :readonly="item.Is_PublishDiem === 1" -->
									</template>
								</v-data-table>

								<div class="d-flex mt-2 justify-end">
									<div class="d-flex justify-center align-center">
										<h3>Điểm trung bình: {{ ' ' }}</h3>
										<h3 class="red--text ml-1">{{ isNaN(DiemTrungBinh) ? 0.0 : DiemTrungBinh }}</h3>
									</div>
								</div>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<!-- v-if="dshoidongId?.Is_PublishDiem === 0" -->
					<v-btn v-if="dshoidongId?.Is_PublishDiem === 0" color="success" @click="onSave"> Lưu tạm </v-btn>
					<!-- v-if="dshoidongId?.Is_PublishDiem === 0" -->
					<v-btn v-if="dshoidongId?.Is_PublishDiem === 0" color="warning" @click="publicScore"> Công bố điểm
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ['editedItem', 'dshoidonggiangvien', 'getdiem', 'dshoidongId'],
	    data() {
	        return {
	            flagNhanXet: 0,
	            flagKiemDinh: 1,
	            arr: [],
	            test: null,
	            dsHoiDong: [],
	            hoiDongObj: {
	                DiemHoiDong: 0,
	                FileNhanXetID: null,
	                FileNhanXetName: null,
	                Is_PublishDiem: 0,
	                FileKiemPhieuID: null,
	                FileKiemPhieuName: null,
	                FILE_UPLOAD: {
	                    File_Name: this.test,
	                    File_ID: null,
	                    File_Type: null,
	                    File_URL: null,
	                },
	                FILE_UPLOAD_1: {
	                    File_Name: null,
	                    File_ID: null,
	                    File_Type: null,
	                    File_URL: null,
	                },
	                NhanXet: null,
	            },
	
	            headertable: [
	                {
	                    text: 'STT',
	                    value: 'stt',
	                    sortable: false,
	                    align: 'center',
	                    class: 'sttCol',
	                },
	                {
	                    text: 'Thành viên',
	                    value: 'HoTenHocHamHocVi',
	                    class: 'customCol2',
	                    width: 180,
	                },
	                {
	                    text: 'Chức trách',
	                    value: 'ChucTrach',
	                    class: 'chucTrachWrap',
	                    width: 120,
	                },
	                {
	                    text: 'File nhận xét',
	                    value: 'FileNhanXet',
	                    class: 'cmtFileInput',
	                    align: 'center',
	                    sortable: false,
	                    width: 50,
	                },
	                {
	                    text: 'File Điểm',
	                    value: 'FileDiem',
	                    class: 'cmtFileInput',
	                    align: 'center',
	                    sortable: false,
	                    width: 50,
	                },
	                {
	                    text: 'Điểm ',
	                    value: 'Diem',
	                    align: 'center',
	                    width: '100',
	                    sortable: false,
	                },
	                {
	                    text: 'Ghi chú',
	                    value: 'NhanXet',
	                    align: 'center',
	                    width: 200,
	                },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        DiemTrungBinh() {
	            let sum = 0
	            let sumTrungBinh = 0
	            console.log('Diem raw', this.dsHoiDong)
	
	            const filterDiem = this.dsHoiDong.filter((item) => item.Diem && parseFloat(item.Diem) > 0)
	            console.log('Diem filter !', this.dsHoiDong)
	
	            filterDiem.forEach((item) => {
	                sum += parseFloat(item.Diem ?? 0)
	            })
	
	            //Tính điểm trung bình
	            sumTrungBinh = sum / filterDiem.length
	            //Set điểm trung bình vào param
	            this.hoiDongObj.DiemHoiDong = sumTrungBinh
	            return sumTrungBinh.toFixed(2)
	        },
	        thongTinHocVien: function () {
	            return this.editedItem
	        },
	        isInpScoreModel: function () {
	            return vueData.isInputDialog
	        },
	    },
	    watch: {
	        dshoidonggiangvien: function (val) {
	            if (val) {
	                this.dsHoiDong = this.dshoidonggiangvien.map((item, index) => {
	                    return {
	                        ...item,
	                        HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
	                        FILE_UPLOAD: {
	                            File_Name: null,
	                            File_ID: null,
	                            File_Type: null,
	                            File_URL: null,
	                        },
	                        FILE_UPLOAD_DIEM: {
	                            File_Name: null,
	                            File_ID: null,
	                            File_Type: null,
	                            File_URL: null,
	                        },
	                    }
	                })
	            }
	        },
	        getdiem: function (val) {
	            this.test = this.getdiem[0][0].FileNhanXetName
	            this.hoiDongObj.NhanXet = val[0][0].NhanXet
	        },
	        isInpScoreModel: function (val) {
	            // Filter bỏ những thành viên bị null trong hội đồng (VD: ngành NNA)
	            if (val) {
	                this.dsHoiDong = this.dsHoiDong.filter((item) => item.GiangVienID)
                    this.getdiem[1] = this.sortThanhVien(this.getdiem[1])
	                console.log("getdiem", this.getdiem)
	            }
	        },
	    },
	    methods: {
	        sortThanhVien(arr) {
	            if (!Array.isArray(arr)) return arr;
	
	            if (arr.length === 3) {
	                const order = ["Chủ tịch", "Phản biện", "Thư ký"];
	                return arr.slice().sort((a, b) => {
	                    return order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach);
	                });
	            }
	
	            if (arr.length === 5) {
	                const order = ["Chủ tịch", "Phản biện 1", "Phản biện 2", "Ủy viên", "Thư ký"];
	                return arr.slice().sort((a, b) => {
	                    return order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach);
	                });
	            }
	
	            // ngoài 2 trường hợp thì trả nguyên
	            return arr;
	        },
	
	        // Chuyển đổi giá trị thành số để xử lý khi người dùng nhập
	        updateDiem(item) {
	            item.Diem = Number(item.Diem)
	        },
	        // Làm tròn giá trị và giữ lại số 0 cuối cùng khi người dùng click vào nơi khác
	        formatDiem(item) {
	            item.Diem = Number(item.Diem).toFixed(2)
	        },
	        closeDialog() {
	            vueData.isInputDialog = false
	        },
	        onSave() {
	            const $this = this
	            ajaxCALL(
	                '/HoiDong_GiangVien_Upd_Diem',
	                {
	                    HoiDongID: $this.thongTinHocVien.HoiDongID,
	                    StudentID: $this.thongTinHocVien.Student_ID,
	                    DiemHoiDongObj: $this.hoiDongObj,
	                    HoiDongThanhVienObj_Arr: $this.dsHoiDong,
	                },
	                (res) => {
	                    Vue.$toast.success(`Nhập điểm thành công`, { position: 'top' })
	                    this.closeDialog()
	                },
	                (error) => {
	                    Vue.$toast.error(error?.Response?.Message, { position: 'top' })
	                    console.log('Fail to input score', error)
	                },
	            )
	        },
	        loadScore() {
	            ajaxCALL(
	                '/HoiDong_GiangVien_Get_Diem',
	                {
	                    HoiDongID: this.thongTinHocVien.HoiDongID,
	                },
	                (res) => {
	                    this.arr = res.data
	                    console.log('arr', this.arr)
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('error', error)
	                },
	            )
	        },
	        publicScore() {
	            let checkHDThanhVien = true
	            console.log('this.hoiDongObj', this.hoiDongObj)
	            console.log('this.dsHoiDong', this.dsHoiDong)
	            if (this.hoiDongObj.FileKiemPhieuID === null && this.hoiDongObj.FileNhanXetID === null) {
	                Vue.$toast.error(`Chưa đủ file biên bản`, { position: 'top' })
	                return
	            }
	            this.dsHoiDong.find((item) => {
	                if (item.FileNhanXetID === null) {
	                    Vue.$toast.error(`Giảng viên ${item.HoTenHocHamHocVi} chưa có file nhận xét`, { position: 'top' })
	                    checkHDThanhVien = false
	                    return
	                }
	                if (item.Diem === null || item.Diem === '') {
	                    Vue.$toast.error(`Giảng viên ${item.HoTenHocHamHocVi} chưa nhập điểm`, { position: 'top' })
	                    checkHDThanhVien = false
	                    return
	                }
	            })
	
	            if (!checkHDThanhVien) {
	                return
	            }
	
	            this.onSave()
	            ajaxCALL(
	                '/HoiDong_Pub_Diem',
	                {
	                    HoiDong_ID: this.thongTinHocVien.HoiDongID,
	                    Student_ID: this.thongTinHocVien.Student_ID,
	                },
	                (res) => {
	                    Vue.$toast.success(`Công bố điểm thành công`, { position: 'top' })
	                    this.closeDialog()
	                },
	                (error) => {
	                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                    console.log('Fail to public', error)
	                },
	            )
	        },
	    },
	}
</script>
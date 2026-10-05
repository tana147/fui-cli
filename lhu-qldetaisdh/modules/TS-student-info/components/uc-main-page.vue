<template>
	<div>
		<uc-main-view
			:is-table-ready="isTableReady"
			:items="DSStudentFilter"
			:ds-nien-khoa="DsNienKhoa"
			:he-arr="heArr"
			:selected-nien-khoa="nienKhoaValue"
			:selected-major="major"
			@update:selected-nien-khoa="onNienKhoaChange"
			@update:selected-major="onMajorChange"
			@on-save-all="onSaveAll"
			@on-save-student="onSaveSingle"
			@on-delete-student="onDeleteStudent"
			@on-xuly-hocvu="onXuLyHocVu"
			@on-select-student="openUpdateTask"
			@on-reset-process="openResetProcess"
			@on-view-old-process="openViewOldProcess"
			@on-open-import="isImportModalOpen = true"
			@on-open-import-new="isImportNewModalOpen = true"
			@on-open-sync-gvhd="isSyncGVHDModalOpen = true"
			@on-open-update-student-id="isUpdateStudentIDModalOpen = true"
		/>

		<uc-modal-update-student-id
			v-model="isUpdateStudentIDModalOpen"
			:ds-exist-student="DsExistStudent"
			@on-reload="reloadStudentData"
		/>

		<uc-modal-import-new-student
			v-model="isImportNewModalOpen"
			:ds-nien-khoa="DsNienKhoa"
			:he-arr="heArr"
			:current-nien-khoa="nienKhoaValue"
			@on-reload="reloadStudentData"
		/>

		<uc-modal-import-update-student
			v-model="isImportModalOpen"
			:ds-nien-khoa="DsNienKhoa"
			@on-reload="reloadStudentData"
		/>

		<uc-modal-sync-gvhd
			v-model="isSyncGVHDModalOpen"
			@on-reload="reloadStudentData"
		/>

		<uc-modal-reset-process
			v-model="isResetModalOpen"
			:student-item="selectedStudent"
			@on-reload="reloadStudentData"
		/>

		<uc-modal-view-old-process
			v-model="isViewOldModalOpen"
			:student-item="selectedStudent"
		/>

		<uc-modal-update-task
			v-model="isUpdateTaskModalOpen"
			:student-item="selectedStudent"
			:ds-exist-student="DsExistStudent"
			@on-reload="reloadStudentData"
		/>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				isTableReady: false,
				DsNienKhoa: [],
				DSStudentFilter: [],
				DsExistStudent: [],
				heArr: [],
				nienKhoaValue: null,
				major: "0",
				selectedStudent: {},
				isImportModalOpen: false,
				isImportNewModalOpen: false,
				isSyncGVHDModalOpen: false,
				isResetModalOpen: false,
				isViewOldModalOpen: false,
				isUpdateTaskModalOpen: false,
				isUpdateStudentIDModalOpen: false,
			}
		},
		mounted() {
			this.initData()
		},
		methods: {
			async initData() {
				this.isTableReady = false
				await Promise.all([this.getNienKhoa(), this.getHeDaoTao()])
				this.isTableReady = true
			},

			async onNienKhoaChange(val) {
				this.nienKhoaValue = val
				this.major = "0"
				this.isTableReady = false
				await this.onLoadStudentGetNienKhoa(val)
				this.applyFilter()
				this.isTableReady = true
			},

			onMajorChange(val) {
				this.major = val || "0"
				this.applyFilter()
			},

			async reloadStudentData() {
				await this.onLoadStudentGetNienKhoa(this.nienKhoaValue)
				this.applyFilter()
			},

			applyFilter() {
				let filtered = []
				const selectedMajor = this.major

				if (selectedMajor && selectedMajor !== '0') {
					filtered = this.DsExistStudent.filter((item) => item.NganhID == selectedMajor)
				} else {
					filtered = [...this.DsExistStudent]
				}

				filtered = filtered.map((item) => {
					let hoTen = item.HoTen || `${item.HoSV || ''} ${item.TenSV || ''}`.trim()
					return {
						...item,
						HoTen: hoTen,
						isExist: true,
						isSelect: false,
						isCanDelete: item.Seq === 1 && item.Flow_Status === 'W' && item.TotalChangeThesis === 1,
					}
				})

				this.DSStudentFilter = this.resetSTT(filtered)
			},

			resetSTT(ds) {
				return ds.map((item, index) => ({
					...item,
					stt: index + 1,
				}))
			},

			async getNienKhoa() {
				try {
					const res = await ajaxGETCALLPromise('https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa');
					const obj = {
						TenNienKhoa: '- Tất cả học viên đã được thêm -',
						NienKhoa: '0',
					};
					const list = ((res && res.data) || []).map((item) => ({
						...item,
						TenNienKhoa: item.NienKhoa,
						NienKhoa: item.NienKhoa,
					}));
					list.unshift(obj);
					this.DsNienKhoa = list;
					this.nienKhoaValue = list[0]?.NienKhoa;

					if (this.nienKhoaValue !== null && this.nienKhoaValue !== undefined) {
						await this.onLoadStudentGetNienKhoa(this.nienKhoaValue);
						this.applyFilter();
					}
				} catch (error) {
					Vue.$toast.error('Lỗi tải danh sách niên khóa', { position: 'top' });
				}
			},

			async getHeDaoTao() {
				const res = await ajaxCALLPromise('/Nganh_Get_ByHeID', { HeID: 'N' })
				const allListObj = {
					NganhID: '0',
					TenNganh: '- Tất cả -',
				}

				const mapped = (res || []).map((item) => ({
					...item,
					NganhID: String(item.Nganh_ID),
					TenNganh: item.Ten_Nganh_HienThi || item.Ten_Nganh,
					OriginalName: item.Ten_Nganh,
				}))

				mapped.unshift(allListObj)
				this.heArr = mapped
			},

			async onLoadStudentGetNienKhoa(nienKhoa) {
				const res = await ajaxCALLPromise('/Student_Get_NienKhoa_TS', { NienKhoa: nienKhoa })
				this.DsExistStudent = (res || []).map((item) => {
					let ngaySinh = null
					if (item.NgaySinh) {
						const parts = item.NgaySinh.split('/')
						if (parts.length === 3) {
							const [d, m, y] = parts
							ngaySinh = new Date(y, m - 1, d)
						} else {
							ngaySinh = new Date(item.NgaySinh)
						}
					}
					return {
						...item,
						NgaySinh: ngaySinh,
					}
				})
			},

			onSaveAll() {
				confirm({
					title: 'Bạn có muốn thêm tất cả học viên không?',
					action: async () => {
						const ds = [...this.DSStudentFilter]
						ds.forEach((item) => (item.isSelect = true))
						await ajaxCALLPromise('/Student_INS_obj', {
							StudentObjArr: JSON.stringify(ds),
							Process_Action: 4,
						})
						Vue.$toast.success('Thêm tất cả học viên thành công', { position: 'top' })
						await this.reloadStudentData()
					},
				})
			},

			async onSaveSingle(item) {
				item.isSelect = true
				await ajaxCALLPromise('/Student_INS_obj', {
					StudentObjArr: JSON.stringify(item),
					Process_Action: 4,
				})
				Vue.$toast.success('Thêm học viên thành công', { position: 'top' })
				item.isCanDelete = true
				await this.reloadStudentData()
			},

			onDeleteStudent(item) {
				confirm({
					title: 'Xóa học viên',
					content: `Bạn có muốn xóa học viên ${item.HoTen || ''} không?`,
					action: async () => {
						await ajaxCALLPromise('/Student_Remove', {
							StudentID: item.StudentID,
						})
						Vue.$toast.success(`Xóa học viên ${item.HoTen || ''} thành công`, { position: 'top' })
						item.isExist = false
						item.isSelect = false
						await this.reloadStudentData()
					},
				})
			},

			onXuLyHocVu(item) {
				confirm({
					title: `Bạn có muốn xử lý học vụ học viên ${item.HoTen || (item.HoSV + ' ' + item.TenSV)} không?`,
					action: async () => {
						await ajaxCALLPromise('/Student_XuLyHocVu', {
							Student_ID: item.StudentID,
						})
						item.IsXuLyHocVu = true
						Vue.$toast.success(`Đã xử lý học vụ ${item.HoTen || (item.HoSV + ' ' + item.TenSV)}`, { position: 'top' })
						await this.reloadStudentData()
					},
				})
			},

			openUpdateTask(item) {
				this.selectedStudent = item
				this.isUpdateTaskModalOpen = true
			},

			openResetProcess(item) {
				this.selectedStudent = item
				this.isResetModalOpen = true
			},

			openViewOldProcess(item) {
				this.selectedStudent = item
				this.isViewOldModalOpen = true
			},
		},
	}
</script>
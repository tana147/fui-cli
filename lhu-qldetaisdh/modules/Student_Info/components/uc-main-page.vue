<template>
	<div>
		<!-- Giao diện danh sách và bộ lọc chính -->
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
			@on-open-sync-gvhd="isSyncGVHDModalOpen = true"
		/>

		<!-- Modal Cập nhật thông tin học viên bằng Excel -->
		<uc-modal-import-update-student
			v-model="isImportModalOpen"
			@on-reload="reloadStudentData"
		/>

		<!-- Modal Đồng bộ phân công GVHD -->
		<uc-modal-sync-gvhd
			v-model="isSyncGVHDModalOpen"
			@on-reload="reloadStudentData"
		/>

		<!-- Modal Xác nhận Đăng ký mới -->
		<uc-modal-reset-process
			v-model="isResetModalOpen"
			:student-item="selectedStudent"
			@on-reload="reloadStudentData"
		/>

		<!-- Modal Xem dữ liệu đăng ký cũ -->
		<uc-modal-view-old-process
			v-model="isViewOldModalOpen"
			:student-item="selectedStudent"
		/>

		<!-- Modal Cập nhật chi tiết nhiệm vụ và thông tin học viên (giữ tương thích) -->
		<dialog-upd-task :dsexiststudent="DsExistStudent" />
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
				DsPortalStudent: [],
				heArr: [],
				nienKhoaValue: null,
				major: "0",
				selectedStudent: {},
				isImportModalOpen: false,
				isSyncGVHDModalOpen: false,
				isResetModalOpen: false,
				isViewOldModalOpen: false,
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

			async getNienKhoa() {
				try {
					const res = await ajaxGETCALLPromise("https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa")
					const list = ((res && res.data) || []).map((item) => ({
						...item,
						TenNienKhoa: item.NienKhoa,
						NienKhoa: item.NienKhoa,
					}))
					list.unshift({
						TenNienKhoa: "- Tất cả học viên đã được thêm -",
						NienKhoa: "0",
					})
					this.DsNienKhoa = list
					this.nienKhoaValue = list[0]?.NienKhoa

					if (this.nienKhoaValue !== null && this.nienKhoaValue !== undefined) {
						await this.loadDataForNienKhoa(this.nienKhoaValue)
					}
				} catch (error) {
					console.error("Lỗi tải niên khóa:", error)
					Vue.$toast.error("Lỗi tải danh sách niên khóa", { position: "top" })
				}
			},

			async getHeDaoTao() {
				try {
					if (typeof getNganhCaoHocPromise === "function") {
						this.heArr = await getNganhCaoHocPromise({ hasAllOption: true })
					} else {
						const res = await ajaxGETCALLPromise("https://tapi.lhu.edu.vn/hoso/SDH_SelectNganh_CaoHoc")
						const list = (res && res.data) ? res.data : []
						const mapped = list.map((item) => ({
							...item,
							NganhID: String(item.NganhID),
							TenNganh: item.TenNganh,
						}))
						mapped.unshift({ NganhID: "0", TenNganh: "- Tất cả -" })
						this.heArr = mapped
					}
				} catch (error) {
					console.error("Lỗi tải danh sách ngành:", error)
				}
			},

			async onNienKhoaChange(val) {
				this.nienKhoaValue = val
				this.major = "0"
				this.isTableReady = false
				await this.loadDataForNienKhoa(val)
				this.isTableReady = true
			},

			onMajorChange(val) {
				this.major = val || "0"
				this.applyFilter()
			},

			async reloadStudentData() {
				await this.loadDataForNienKhoa(this.nienKhoaValue)
			},

			async loadDataForNienKhoa(nienKhoa) {
				if (!nienKhoa && nienKhoa !== "0") return

				try {
					if (nienKhoa === "0") {
						// Chỉ tải toàn bộ học viên đã được thêm vào hệ thống
						const resDb = await ajaxCALLPromise("/Student_Get_NienKhoa", { NienKhoa: "0" })
						this.DsExistStudent = this.parseDateRows(resDb || [])
						this.DsPortalStudent = []
					} else {
						// Tải song song: Học viên từ Cổng đào tạo LHU và Học viên đã có trong QLĐTSĐH
						const [resPortal, resDb] = await Promise.all([
							ajaxGETCALLPromise(`https://tapi.lhu.edu.vn/hoso/StudentInfoByStudentID_CaoHoc?NienKhoa=${nienKhoa}`),
							ajaxCALLPromise("/Student_Get_NienKhoa", { NienKhoa: nienKhoa }),
						])

						this.DsPortalStudent = ((resPortal && resPortal.data) || []).map((item) => ({
							...item,
							HoTen: item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
							Email: item.Email || "",
							NoiSinh: item.NoiSinh || "",
							SoDienThoai: item.SoDienThoai || "",
						}))

						this.DsExistStudent = this.parseDateRows(resDb || [])
					}

					this.applyFilter()
				} catch (error) {
					console.error("Lỗi tải dữ liệu học viên:", error)
					Vue.$toast.error("Lỗi tải dữ liệu học viên", { position: "top" })
				}
			},

			parseDateRows(rows) {
				return (rows || []).map((item) => {
					let ngaySinh = null
					if (item.NgaySinh) {
						if (typeof item.NgaySinh === "string" && item.NgaySinh.includes("/")) {
							const parts = item.NgaySinh.split("/")
							if (parts.length === 3) {
								const [d, m, y] = parts
								ngaySinh = new Date(y, m - 1, d)
							}
						} else {
							ngaySinh = new Date(item.NgaySinh)
						}
					}
					return {
						...item,
						NgaySinh: ngaySinh,
						HoTen: item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim(),
					}
				})
			},

			applyFilter() {
				let list = []
				const selectedMajor = this.major

				if (this.nienKhoaValue === "0") {
					// Hiển thị toàn bộ học viên đã được thêm
					list = this.DsExistStudent.map((item) => ({
						...item,
						isExist: true,
						isSelect: false,
						isCanDelete: item.Seq === 1 && item.Flow_Status === "W" && item.TotalChangeThesis === 1,
					}))
				} else {
					// Ghép danh sách từ Portal và DB
					const matchedStudentIds = new Set()

					list = this.DsPortalStudent.map((portalItem) => {
						const exist = this.DsExistStudent.find((x) => x.StudentID === portalItem.StudentID)
						if (exist) {
							matchedStudentIds.add(exist.StudentID)
							return {
								...portalItem,
								...exist,
								HoTen: exist.HoTen || portalItem.HoTen,
								isExist: true,
								isSelect: false,
								isCanDelete: exist.Seq === 1 && exist.Flow_Status === "W" && exist.TotalChangeThesis === 1,
								HasResetProcess: exist.HasResetProcess,
								IsXuLyHocVu: exist.IsXuLyHocVu,
							}
						}
						return {
							...portalItem,
							isExist: false,
							isSelect: false,
							isCanDelete: false,
							HasResetProcess: 0,
							IsXuLyHocVu: false,
						}
					})

					// Bổ sung các học viên có trong DB nhưng không có trong đợt tải portal
					for (const exist of this.DsExistStudent) {
						if (!matchedStudentIds.has(exist.StudentID)) {
							list.push({
								...exist,
								isExist: true,
								isSelect: false,
								isCanDelete: exist.Seq === 1 && exist.Flow_Status === "W" && exist.TotalChangeThesis === 1,
							})
						}
					}
				}

				// Lọc theo ngành nếu có chọn
				if (selectedMajor && selectedMajor !== "0") {
					list = list.filter((item) => String(item.NganhID) === String(selectedMajor))
				}

				// Gán số thứ tự
				list = list.map((item, index) => ({
					...item,
					stt: index + 1,
				}))

				this.DSStudentFilter = list
			},

			onSaveAll() {
				if (this.nienKhoaValue === "0" || this.nienKhoaValue === 0 || !this.nienKhoaValue) {
					return
				}
				confirm({
					title: "Bạn có muốn thêm tất cả không?",
					content: "",
					action: async () => {
						try {
							const list = this.DSStudentFilter
							list.forEach((item) => (item.isSelect = true))
							await ajaxCALLPromise("/Student_INS_obj", {
								StudentObjArr: JSON.stringify(list),
								Process_Action: 1,
							})
							Vue.$toast.success("Thêm tất cả học viên thành công", { position: "top" })
							await this.reloadStudentData()
						} catch (error) {
							const msg = error?.responseJSON?.Message || error?.message || "Lỗi thêm học viên"
							Vue.$toast.error(msg, { position: "top" })
						}
					},
				})
			},

			async onSaveSingle(item) {
				try {
					item.isSelect = true
					await ajaxCALLPromise("/Student_INS_obj", {
						StudentObjArr: JSON.stringify(item),
						Process_Action: 1,
					})
					Vue.$toast.success(`Thêm học viên ${item.HoTen || item.StudentID} thành công`, { position: "top" })
					item.isCanDelete = true
					await this.reloadStudentData()
				} catch (error) {
					item.isSelect = false
					const msg = error?.responseJSON?.Message || error?.message || "Lỗi thêm học viên"
					Vue.$toast.error(msg, { position: "top" })
				}
			},

			onDeleteStudent(item) {
				const name = item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim()
				confirm({
					title: "Xóa học viên",
					content: `Bạn có chắc muốn xóa học viên ${name} (${item.StudentID}) khỏi đề tài?`,
					action: async () => {
						try {
							await ajaxCALLPromise("/Student_Remove", {
								StudentID: item.StudentID,
							})
							Vue.$toast.success(`Xóa học viên ${name} thành công`, { position: "top" })
							await this.reloadStudentData()
						} catch (error) {
							const msg = error?.responseJSON?.Message || error?.message || "Lỗi xóa học viên"
							Vue.$toast.error(msg, { position: "top" })
						}
					},
				})
			},

			onXuLyHocVu(item) {
				const name = item.HoTen || `${item.HoSV || ""} ${item.TenSV || ""}`.trim()
				confirm({
					title: "Xử lý học vụ",
					content: `Bạn có muốn xử lý học vụ cho học viên ${name} (${item.StudentID}) không?`,
					action: async () => {
						try {
							await ajaxCALLPromise("/Student_XuLyHocVu", {
								Student_ID: item.StudentID,
							})
							item.IsXuLyHocVu = true
							Vue.$toast.success(`Đã xử lý học vụ học viên ${name}`, { position: "top" })
							await this.reloadStudentData()
						} catch (error) {
							const msg = error?.responseJSON?.Message || error?.message || "Lỗi xử lý học vụ"
							Vue.$toast.error(msg, { position: "top" })
						}
					},
				})
			},

			openUpdateTask(item) {
				this.selectedStudent = item
				// Gán vào vueData để dialog-upd-task legacy tự nhận
				if (typeof vueData !== "undefined") {
					vueData.hocVienObj = item
					vueData.isUpdTask = true
				}
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
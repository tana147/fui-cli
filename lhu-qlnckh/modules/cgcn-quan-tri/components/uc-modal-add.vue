<template>
	<v-dialog v-model="dialog" max-width="1050" persistent>
		<v-card class="rounded-xs d-flex flex-column">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					Thêm mới dự án / hợp đồng chuyển giao công nghệ
				</span>
				<v-spacer />
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4 pb-2 px-4">
				<v-row dense>
					<v-col cols="12">
						<v-textarea
							v-model="form.TenDuAn"
							label="Tên Dự án / Hợp đồng *"
							rows="2"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<!-- Khối Danh sách thành viên thực hiện hợp đồng CGCN -->
					<v-col cols="12">
						<div class="d-flex align-center justify-space-between mb-1">
							<span class="font-weight-bold text-subtitle-2 primary--text">
								Thành viên thực hiện hợp đồng chuyển giao công nghệ *
							</span>
							<v-chip v-if="membersList.length" x-small color="primary" outlined>
								{{ membersList.length }} thành viên
							</v-chip>
						</div>

						<!-- Thanh tìm kiếm và thêm thành viên -->
						<v-card outlined class="pa-2 mb-2 bg-light rounded-xs">
							<v-row dense align="center">
								<v-col cols="12" sm="4">
									<v-autocomplete
										v-model="selectedMemberSearch"
										:items="searchMemberResults"
										:loading="isSearchingMember"
										:search-input.sync="searchMemberKeyword"
										item-text="HoTen"
										item-value="MaNV"
										return-object
										label="Tìm nhân sự LHU (tên hoặc Mã NV)"
										placeholder="Gõ từ 2 ký tự..."
										outlined
										dense
										hide-details
										clearable
										no-data-text="Không tìm thấy nhân sự"
										@change="onSelectSearchedMember"
									>
										<template v-slot:item="{ item }">
											<v-list-item-content>
												<v-list-item-title class="font-weight-medium">
													{{ item.HoTen }}
													<span class="primary--text text-caption ml-1">({{ item.MaNV }})</span>
												</v-list-item-title>
												<v-list-item-subtitle class="text-caption text--secondary">
													{{ item.TenPhongBan || 'Chưa rõ đơn vị' }}
												</v-list-item-subtitle>
											</v-list-item-content>
										</template>
									</v-autocomplete>
								</v-col>
								<v-col cols="12" sm="4">
									<v-text-field
										v-model="newMemberNameInput"
										label="Họ tên thành viên *"
										placeholder="Nhập họ tên nếu ngoài LHU"
										outlined
										dense
										hide-details
										@keyup.enter="addMemberToList"
									/>
								</v-col>
								<v-col cols="7" sm="2">
									<v-select
										v-model="newMemberRole"
										:items="memberRoleOptions"
										item-text="text"
										item-value="val"
										label="Vai trò"
										outlined
										dense
										hide-details
									/>
								</v-col>
								<v-col cols="5" sm="2" class="d-flex align-center pl-3">
									<v-btn
										color="primary"
										small
										depressed
										class="text-none px-3"
										:disabled="!canAddMember"
										@click="addMemberToList"
										title="Thêm thành viên"
									>
										<v-icon small left>mdi-plus</v-icon> Thêm
									</v-btn>
								</v-col>
							</v-row>
						</v-card>

						<!-- Bảng danh sách thành viên -->
						<v-data-table
							dense
							:headers="memberHeaders"
							:items="membersList"
							hide-default-footer
							:items-per-page="-1"
							no-data-text="Chưa có thành viên nào trong hợp đồng"
							class="elevation-1 mb-3"
						>
							<template v-slot:item.stt="{ index }">
								{{ index + 1 }}
							</template>
							<template v-slot:item.HoTen="{ item }">
								<span class="font-weight-medium">{{ item.HoTen }}</span>
								<span v-if="item.MaDinhDanh" class="primary--text caption ml-1 font-italic">
									({{ item.MaDinhDanh }})
								</span>
							</template>
							<template v-slot:item.TenPhongBan="{ item }">
								<span class="text-caption">{{ item.TenPhongBan || '—' }}</span>
							</template>
							<template v-slot:item.VaiTro="{ item }">
								<v-chip x-small :color="item.VaiTro === 1 ? 'primary' : 'grey darken-1'" outlined>
									{{ item.TenVaiTro || (item.VaiTro === 1 ? 'Chủ nhiệm' : 'Thành viên') }}
								</v-chip>
							</template>
							<template v-slot:item.actions="{ index }">
								<v-btn
									icon
									x-small
									color="red"
									title="Xóa thành viên"
									@click="removeMember(index)"
								>
									<v-icon x-small>mdi-delete</v-icon>
								</v-btn>
							</template>
						</v-data-table>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViChuNhiem"
							label="Đơn vị chủ nhiệm"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViTiepNhan"
							label="Đơn vị tiếp nhận"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.GiaTriHopDong"
							label="Giá trị hợp đồng (VNĐ)"
							type="number"
							outlined
							dense
							:hint="formatMoney(form.GiaTriHopDong) + ' VNĐ'"
							persistent-hint
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.SoHopDong"
							label="Số hợp đồng"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-select
							v-model="form.NamHoc"
							:items="namHocOptions"
							label="Năm học"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-text-field
							v-model="form.NamThucHien"
							label="Năm TH"
							type="number"
							outlined
							dense
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>
				</v-row>

				<v-divider class="my-3" />

				<div class="d-flex align-center justify-space-between mb-2">
					<span class="font-weight-bold text-body-2">Danh sách tập tin đính kèm</span>
					<div class="compact-upload-wrapper">
						<f-file-upload
							v-model="uploadResult"
							label="Tải lên tập tin"
							color="primary"
							:filters="fileFilters"
							:url="vSet.apiFile"
							@input="handleFileUploaded"
						/>
					</div>
				</div>

				<v-data-table
					dense
					:headers="fileHeaders"
					:items="attachedFiles"
					item-key="FILE_ID"
					hide-default-footer
					:items-per-page="-1"
					no-data-text="Chưa có tập tin đính kèm"
					class="elevation-1 cgcn-file-table"
				>
					<template v-slot:item.FILE_NAME="{ item }">
						<a
							:href="getFileUrl(item)"
							target="_blank"
							class="text-decoration-none font-weight-medium"
						>
							<v-icon small color="primary" class="mr-1">mdi-file-document-outline</v-icon>
							{{ item.FILE_NAME }}
						</a>
						<span v-if="item.FILE_SIZE" class="grey--text text-caption ml-1">
							({{ item.FILE_SIZE }} KB)
						</span>
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn
							icon
							x-small
							color="red darken-2"
							title="Xóa tập tin"
							@click="removeAttachedFile(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-actions class="pa-3 flex-grow-0 border-top">
				<v-spacer />
				<v-btn small text color="grey darken-2" class="text-capitalize px-3 rounded-xs" @click="closeModal">
					Hủy
				</v-btn>
				<v-btn
					color="primary"
					small
					elevation="0"
					class="text-capitalize px-4 ml-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="saveItem"
				>
					<v-icon left small>mdi-content-save-outline</v-icon>
					Lưu
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-add",
	props: {
		value: {
			type: Boolean,
			default: false
		},
		vSet: {
			type: Object,
			default: () => ({
				apiFile: "",
				urlReturnFile: ""
			})
		}
	},
	emits: ["input", "on-reload"],
	data() {
		return {
			// 1. Data arrays/objects
			attachedFiles: [],
			uploadedFileIDs: [],
			fileHeaders: [
				{ text: "Tập tin", value: "FILE_NAME" },
				{ text: "Xóa", value: "actions", align: "right", sortable: false, width: 80 }
			],
			fileFilters: {
				max_file_size: "15mb",
				mime_types: [{ title: "All files", extensions: "*" }]
			},

			// 2. Local form & state
			saving: false,
			uploadResult: null,
			// Thành viên CGCN
			membersList: [],
			memberHeaders: [
				{ text: "STT", value: "stt", width: 50, sortable: false },
				{ text: "Họ và tên", value: "HoTen", sortable: false },
				{ text: "Đơn vị / Phòng ban", value: "TenPhongBan", sortable: false },
				{ text: "Vai trò", value: "VaiTro", width: 120, align: "center", sortable: false },
				{ text: "Thao tác", value: "actions", width: 60, align: "center", sortable: false }
			],
			selectedMemberSearch: null,
			searchMemberKeyword: "",
			searchMemberResults: [],
			isSearchingMember: false,
			searchTimer: null,
			newMemberNameInput: "",
			newMemberRole: 2,
			memberRoleOptions: [
				{ text: "Chủ nhiệm", val: 1 },
				{ text: "Thành viên", val: 2 },
				{ text: "Thư ký", val: 3 }
			],
			form: {
				SoThuTu: 0,
				TenDuAn: "",
				ChuNhiemDeTai: "",
				ThanhVienDeTai: "",
				DonViChuNhiem: "Trường Đại học Lạc Hồng",
				DonViTiepNhan: "",
				GiaTriHopDong: 0,
				SoHopDong: "",
				NamHoc: "",
				NamThucHien: new Date().getFullYear()
			}
		}
	},
	computed: {
		dialog: {
			get() {
				return this.value
			},
			set(val) {
				this.$emit("input", val)
			}
		},
		canAddMember() {
			return !!(this.newMemberNameInput && String(this.newMemberNameInput).trim())
		},
		namHocOptions() {
			const currentYear = new Date().getFullYear()
			const list = []
			for (let y = currentYear + 1; y >= currentYear - 7; y--) {
				list.push(`${y - 1}-${y}`)
			}
			if (this.form && this.form.NamHoc && !list.includes(this.form.NamHoc)) {
				list.unshift(this.form.NamHoc)
			}
			return list
		}
	},
	watch: {
		value(isOpen) {
			if (!isOpen) {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
					this.uploadedFileIDs = []
				}
				this.resetForm()
			}
		},
		searchMemberKeyword(val) {
			if (!val || val.trim().length < 2) {
				this.searchMemberResults = []
				return
			}
			clearTimeout(this.searchTimer)
			this.searchTimer = setTimeout(() => {
				this.searchMembers(val.trim())
			}, 300)
		}
	},
	methods: {
		async searchMembers(keyword) {
			this.isSearchingMember = true
			try {
				let res = await ajaxCALLPromise("/TaiKhoan_Search", { Keyword: keyword })
				if (!res || !res.length) {
					res = await ajaxCALLPromise("/TaiKhoan_Seach", { Keyword: keyword })
				}
				this.searchMemberResults = res || []
			} catch (e) {
				this.searchMemberResults = []
			} finally {
				this.isSearchingMember = false
			}
		},
		onSelectSearchedMember(item) {
			if (!item) return
			this.newMemberNameInput = item.HoTen || `${item.HoNV || ""} ${item.TenNV || ""}`.trim()
		},
		addMemberToList() {
			const name = (this.newMemberNameInput || "").trim()
			if (!name) return

			const selected = this.selectedMemberSearch
			const isLHU = selected && selected.HoTen && selected.HoTen.trim() === name
			const maNV = isLHU ? selected.MaNV : ""
			const donVi = isLHU ? (selected.TenPhongBan || "") : ""
			const email = isLHU ? (selected.Email || "") : ""

			const isDup = this.membersList.some(m => (maNV && m.MaDinhDanh === maNV) || (!maNV && m.HoTen.toLowerCase() === name.toLowerCase()))
			if (isDup) {
				Vue.$toast.warning("Thành viên này đã có trong danh sách", { position: "top" })
				return
			}

			this.membersList.push({
				VaiTro: this.newMemberRole,
				TenVaiTro: this.newMemberRole === 1 ? "Chủ nhiệm" : (this.newMemberRole === 3 ? "Thư ký" : "Thành viên"),
				HoTen: name,
				MaDinhDanh: maNV,
				Email: email,
				TenPhongBan: donVi,
				Is_NhanVien: !!maNV,
				Is_SinhVien: false
			})

			this.syncTextFromMembers()
			this.selectedMemberSearch = null
			this.newMemberNameInput = ""
			this.newMemberRole = 2
		},
		removeMember(index) {
			this.membersList.splice(index, 1)
			this.syncTextFromMembers()
		},
		syncTextFromMembers() {
			const leaders = this.membersList.filter(m => m.VaiTro === 1).map(m => m.HoTen)
			const members = this.membersList.filter(m => m.VaiTro !== 1).map(m => m.HoTen)
			this.form.ChuNhiemDeTai = leaders.join(", ")
			this.form.ThanhVienDeTai = members.join(", ")
		},
		resetForm() {
			const currentYear = new Date().getFullYear()
			const currentSchoolYear = `${currentYear - 1}-${currentYear}`
			const userInfo = (window.vueData && window.vueData.user) || {}
			const defaultLeader = userInfo.FullName || userInfo.TenNhanVien || ""
			const defaultMaNV = userInfo.MaNV || userInfo.UserID || ""
			const defaultDonVi = userInfo.TenDonVi || userInfo.TenPhongBan || "Trường Đại học Lạc Hồng"

			this.form = {
				SoThuTu: 0,
				TenDuAn: "",
				ChuNhiemDeTai: defaultLeader,
				ThanhVienDeTai: "",
				DonViChuNhiem: defaultDonVi,
				DonViTiepNhan: "",
				GiaTriHopDong: 0,
				SoHopDong: "",
				NamHoc: currentSchoolYear,
				NamThucHien: currentYear
			}
			this.membersList = defaultLeader ? [{
				VaiTro: 1,
				TenVaiTro: "Chủ nhiệm",
				HoTen: defaultLeader,
				MaDinhDanh: defaultMaNV,
				Email: userInfo.Email || "",
				TenPhongBan: defaultDonVi,
				Is_NhanVien: true
			}] : []
			this.attachedFiles = []
			this.uploadedFileIDs = []
			this.uploadResult = null
			this.selectedMemberSearch = null
			this.newMemberNameInput = ""
			this.newMemberRole = 2
		},
		formatMoney(val) {
			if (val === null || val === undefined || val === "") return "0"
			if (typeof formatAsCurrency === "function") {
				return formatAsCurrency(Number(val) || 0, 0)
			}
			return Number(val || 0).toLocaleString("vi-VN")
		},
		getFileUrl(file) {
			const baseUrl = (this.vSet && this.vSet.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
			return `${baseUrl}/FileData/${file.FILE_ID}`
		},
		async saveItem() {
			if (!this.form.TenDuAn || !String(this.form.TenDuAn).trim()) {
				Vue.$toast.warning("Vui lòng nhập Tên dự án / Hợp đồng", { position: "top" })
				return
			}
			if (!this.membersList || this.membersList.length === 0) {
				Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên vào hợp đồng", { position: "top" })
				return
			}
			const hasLeader = this.membersList.some(m => m.VaiTro === 1)
			if (!hasLeader) {
				Vue.$toast.warning("Hợp đồng cần có ít nhất 1 thành viên là Chủ nhiệm", { position: "top" })
				return
			}

			confirm({
				title: "Bạn có muốn thêm mới dự án/hợp đồng chuyển giao công nghệ?",
				action: async () => {
					this.saving = true
					try {
						this.syncTextFromMembers()
						const params = {
							SoThuTu: Number(this.form.SoThuTu) || 0,
							TenDuAn: this.form.TenDuAn,
							NamHoc: this.form.NamHoc,
							ChuNhiemDeTai: this.form.ChuNhiemDeTai,
							ThanhVienDeTai: this.form.ThanhVienDeTai,
							DonViChuNhiem: this.form.DonViChuNhiem,
							DonViTiepNhan: this.form.DonViTiepNhan,
							GiaTriHopDong: Number(this.form.GiaTriHopDong) || 0,
							NamThucHien: Number(this.form.NamThucHien) || null,
							SoHopDong: this.form.SoHopDong || "",
							DS_FileID: this.attachedFiles.map(item => item.FILE_ID).join(","),
							TrangThai: 3
						}
						let res = await ajaxCALLPromise("/CGCN_Ins", params)
						let targetCGCNID = null
						if (res && res[0] && res[0].NewCGCNID) {
							targetCGCNID = res[0].NewCGCNID
						} else if (res && res.data && res.data[0] && res.data[0].NewCGCNID) {
							targetCGCNID = res.data[0].NewCGCNID
						}

						if (targetCGCNID && this.membersList && this.membersList.length > 0) {
							await ajaxCALLPromise("/CGCN_ThanhVien_Save", {
								CGCNID: targetCGCNID,
								MembersJSON: JSON.stringify(this.membersList)
							})
						}

						this.uploadedFileIDs = []
						Vue.$toast.success("Thêm mới dự án/hợp đồng chuyển giao công nghệ thành công", { position: "top" })
						this.$emit("on-reload")
						this.closeModal()
					} finally {
						this.saving = false
					}
				}
			})
		},
		handleFileUploaded(payload) {
			const result = payload || this.uploadResult
			if (result && Array.isArray(result.Files) && result.Files.length > 0) {
				result.Files.forEach(file => {
					if (file && file.FILE_ID) {
						const exists = this.attachedFiles.some(item => item.FILE_ID === file.FILE_ID)
						if (!exists) {
							this.attachedFiles.push(file)
							this.uploadedFileIDs.push(file.FILE_ID)
						}
					}
				})
				this.uploadResult = null
			}
		},
		removeAttachedFile(file) {
			if (file && file.FILE_ID) {
				if (this.uploadedFileIDs.includes(file.FILE_ID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: file.FILE_ID }, () => {})
					this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== file.FILE_ID)
				}
			}
			this.attachedFiles = this.attachedFiles.filter(item => item.FILE_ID !== file.FILE_ID)
		},
		closeModal() {
			if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
				ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
			}
			this.uploadedFileIDs = []
			this.resetForm()
			this.dialog = false
		}
	}
	}
</script>
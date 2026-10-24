<template>
	<v-dialog v-model="dialog" max-width="1050" persistent>
		<v-card class="rounded-xs d-flex flex-column">
			<v-card-title class="py-2 px-4 d-flex align-center">
				<span class="primary--text font-weight-bold text-subtitle-1">
					{{ isEdit ? (isReadOnly ? "Chi tiết hồ sơ chuyển giao công nghệ" : "Chi tiết / Cập nhật hồ sơ chuyển giao công nghệ") : "Kê khai hồ sơ chuyển giao công nghệ mới" }}
				</span>
				<v-spacer />
				<v-btn icon small @click="closeModal">
					<v-icon small>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<v-divider />

			<v-card-text class="pt-4 pb-2 px-4">
				<!-- Banner hiển thị lý do cần bổ sung / từ chối -->
				<v-alert
					v-if="form.TrangThai === 4 && form.LyDoReject"
					type="error"
					dense
					outlined
					prominent
					class="mb-3"
				>
					<div class="font-weight-bold">Yêu cầu bổ sung / Lý do trả về từ Quản trị KH&CN:</div>
					<div class="mt-1 text-body-2">{{ form.LyDoReject }}</div>
					<div class="mt-1 caption font-italic text-secondary">
						* Vui lòng hoàn thiện các thông tin/minh chứng theo yêu cầu và bấm <b>"Gửi thẩm định lại"</b>.
					</div>
				</v-alert>

				<!-- Banner thông báo khi đang chờ duyệt -->
				<v-alert
					v-if="form.TrangThai === 2"
					type="info"
					dense
					outlined
					class="mb-3"
				>
					Hồ sơ đang trong quá trình thẩm định / xét duyệt. Không thể chỉnh sửa lúc này.
				</v-alert>

				<!-- Banner thông báo khi đã duyệt -->
				<v-alert
					v-if="form.TrangThai === 3"
					type="success"
					dense
					outlined
					class="mb-3"
				>
					Hồ sơ đã được Quản trị phê duyệt chính thức.
				</v-alert>

				<v-row dense>
					<v-col cols="12">
						<v-textarea
							v-model="form.TenDuAn"
							label="Tên Dự án / Hợp đồng chuyển giao công nghệ *"
							rows="2"
							outlined
							dense
							:readonly="isReadOnly"
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

						<!-- Thanh tìm kiếm và thêm thành viên (chỉ khi không ở chế độ chỉ xem) -->
						<v-card v-if="!isReadOnly" outlined class="pa-2 mb-2 bg-light rounded-xs">
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
									v-if="!isReadOnly"
									icon
									x-small
									color="red darken-2"
									title="Xóa thành viên"
									@click="removeMember(index)"
								>
									<v-icon small>mdi-delete-outline</v-icon>
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
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="6">
						<v-text-field
							v-model="form.DonViTiepNhan"
							label="Đơn vị tiếp nhận / Đối tác *"
							placeholder="Tên doanh nghiệp, tổ chức tiếp nhận CGCN"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.GiaTriHopDong"
							label="Giá trị hợp đồng (VNĐ) *"
							type="number"
							outlined
							dense
							:readonly="isReadOnly"
							:hint="formatMoney(form.GiaTriHopDong) + ' VNĐ'"
							persistent-hint
							class="mb-2"
						/>
					</v-col>

					<v-col cols="12" md="4">
						<v-text-field
							v-model="form.SoHopDong"
							label="Số hợp đồng *"
							outlined
							dense
							:readonly="isReadOnly"
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
							:readonly="isReadOnly"
							:disabled="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>

					<v-col cols="6" md="2">
						<v-text-field
							v-model="form.NamThucHien"
							label="Năm TH"
							type="number"
							placeholder="VD: 2024"
							outlined
							dense
							:readonly="isReadOnly"
							hide-details="auto"
							class="mb-2"
						/>
					</v-col>
				</v-row>

				<v-divider class="my-3" />

				<div class="d-flex align-center justify-space-between mb-2">
					<div>
						<span class="font-weight-bold text-body-2">
							Tập tin minh chứng (Hợp đồng, Biên bản nghiệm thu, Thanh lý...)
						</span>
						<div class="caption grey--text text--darken-2 mt-1">
							Định dạng cho phép: <strong>.pdf, .doc, .docx, .xls, .xlsx, .png, .jpg, .zip, .rar</strong> (tối đa 20MB).
						</div>
					</div>
					<div class="compact-upload-wrapper">
						<f-file-upload
							v-if="!isReadOnly"
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
					class="elevation-1"
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
							v-if="!isReadOnly"
							icon
							x-small
							color="red darken-2"
							title="Xóa tập tin"
							@click="removeAttachedFile(item)"
						>
							<v-icon small>mdi-trash-can-outline</v-icon>
						</v-btn>
						<v-btn
							v-else
							icon
							x-small
							color="primary"
							:href="getFileUrl(item)"
							target="_blank"
							title="Xem tập tin"
						>
							<v-icon small>mdi-download</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>

			<v-card-actions class="pa-3 flex-grow-0 border-top">
				<v-spacer />
				<v-btn small text color="grey darken-2" class="text-capitalize px-3 rounded-xs" @click="closeModal">
					Đóng
				</v-btn>

				<!-- Nút Lưu dự thảo: chỉ hiển thị khi tạo mới hoặc đang là Dự thảo (1) -->
				<v-btn
					v-if="!isReadOnly && (form.TrangThai === 1 || !form.CGCNID)"
					small
					color="amber darken-3"
					outlined
					class="text-capitalize px-3 ml-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="saveItem(1)"
				>
					<v-icon left small>mdi-file-document-edit-outline</v-icon>
					Lưu dự thảo
				</v-btn>

				<!-- Nút Gửi thẩm định: Tạo mới, hoặc Dự thảo (1), hoặc Cần bổ sung (4) -->
				<v-btn
					v-if="!isReadOnly"
					small
					color="primary"
					elevation="0"
					class="text-capitalize px-4 ml-2 font-weight-medium rounded-xs"
					:loading="saving"
					@click="saveItem(2)"
				>
					<v-icon left small>mdi-send-outline</v-icon>
					{{ form.TrangThai === 4 ? "Gửi thẩm định lại" : "Lưu & Gửi thẩm định" }}
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-contract",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			itemData: {
				type: Object,
				default: () => ({})
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
				saving: false,
				uploadResult: null,
				attachedFiles: [],
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
				fileHeaders: [
					{ text: "Tập tin minh chứng", value: "FILE_NAME" },
					{ text: "Thao tác", value: "actions", align: "right", sortable: false, width: 80 }
				],
				fileFilters: {
					max_file_size: "20mb",
					mime_types: [{ title: "Tài liệu", extensions: "pdf,doc,docx,xls,xlsx,png,jpg,jpeg,zip,rar" }]
				},
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
					CGCNID: null,
					SoThuTu: 0,
					TenDuAn: "",
					ChuNhiemDeTai: "",
					ThanhVienDeTai: "",
					DonViChuNhiem: "Trường Đại học Lạc Hồng",
					DonViTiepNhan: "",
					GiaTriHopDong: 0,
					SoHopDong: "",
					NamHoc: "",
					NamThucHien: null,
					TrangThai: 1,
					LyDoReject: ""
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
			isEdit() {
				return !!(this.form && this.form.CGCNID)
			},
			isReadOnly() {
				// TrangThai = 2 (Chờ duyệt) hoặc 3 (Đã duyệt) thì chỉ xem, không được sửa
				return this.form.TrangThai === 2 || this.form.TrangThai === 3
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
				if (isOpen) {
					if (this.itemData && this.itemData.CGCNID) {
						this.syncFormFromItem(this.itemData)
					} else {
						this.resetForm()
					}
				} else {
					if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
						this.uploadedFileIDs = []
					}
					this.pendingDeleteFileIDs = []
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
			fallbackMembersFromText(chuNhiem, thanhVien, donVi) {
				const list = []
				if (chuNhiem && String(chuNhiem).trim()) {
					list.push({
						VaiTro: 1,
						TenVaiTro: "Chủ nhiệm",
						HoTen: String(chuNhiem).trim(),
						MaDinhDanh: "",
						TenPhongBan: donVi || "",
						Is_NhanVien: true
					})
				}
				if (thanhVien && String(thanhVien).trim()) {
					String(thanhVien).split(",").forEach(name => {
						const trimmed = name.trim()
						if (trimmed) {
							list.push({
								VaiTro: 2,
								TenVaiTro: "Thành viên",
								HoTen: trimmed,
								MaDinhDanh: "",
								TenPhongBan: "",
								Is_NhanVien: true
							})
						}
					})
				}
				this.membersList = list
			},
			resetForm() {
				const currentYear = new Date().getFullYear()
				const currentSchoolYear = `${currentYear - 1}-${currentYear}`
				const userInfo = (window.vueData && window.vueData.user) || {}
				const defaultLeader = userInfo.FullName || userInfo.TenNhanVien || ""
				const defaultMaNV = userInfo.MaNV || userInfo.UserID || ""
				const defaultDonVi = userInfo.TenDonVi || userInfo.TenPhongBan || "Trường Đại học Lạc Hồng"

				this.form = {
					CGCNID: null,
					SoThuTu: 0,
					TenDuAn: "",
					ChuNhiemDeTai: defaultLeader,
					ThanhVienDeTai: "",
					DonViChuNhiem: defaultDonVi,
					DonViTiepNhan: "",
					GiaTriHopDong: 0,
					SoHopDong: "",
					NamHoc: currentSchoolYear,
					NamThucHien: currentYear,
					TrangThai: 1,
					LyDoReject: ""
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
				this.pendingDeleteFileIDs = []
				this.uploadResult = null
				this.selectedMemberSearch = null
				this.newMemberNameInput = ""
			},
			parseFileData(rawFileData) {
				if (!rawFileData) return []
				if (Array.isArray(rawFileData)) return [...rawFileData]
				if (typeof rawFileData === "string") {
					try {
						const parsed = JSON.parse(rawFileData)
						return Array.isArray(parsed) ? parsed : []
					} catch (e) {
						return []
					}
				}
				return []
			},
			async syncFormFromItem(item) {
				this.form = {
					CGCNID: item.CGCNID || null,
					SoThuTu: item.SoThuTu || 0,
					TenDuAn: item.TenDuAn || "",
					ChuNhiemDeTai: item.ChuNhiemDeTai || "",
					ThanhVienDeTai: item.ThanhVienDeTai || "",
					DonViChuNhiem: item.DonViChuNhiem || "Trường Đại học Lạc Hồng",
					DonViTiepNhan: item.DonViTiepNhan || "",
					GiaTriHopDong: item.GiaTriHopDong || 0,
					SoHopDong: item.SoHopDong || "",
					NamHoc: item.NamHoc || "",
					NamThucHien: item.NamThucHien || null,
					TrangThai: item.TrangThai || 1,
					LyDoReject: item.LyDoReject || ""
				}
				this.attachedFiles = this.parseFileData(item.FileData)
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.uploadResult = null
				this.selectedMemberSearch = null
				this.newMemberNameInput = ""

				// Load thành viên từ ThanhVienList (JSON) hoặc gọi SP
				if (item.ThanhVienList) {
					try {
						this.membersList = typeof item.ThanhVienList === "string" ? JSON.parse(item.ThanhVienList) : item.ThanhVienList
					} catch (e) {
						this.membersList = []
					}
				} else if (item.CGCNID) {
					try {
						const tvRes = await ajaxCALLPromise("/CGCN_ThanhVien_Get", { CGCNID: item.CGCNID })
						this.membersList = tvRes && Array.isArray(tvRes) ? tvRes : (tvRes && tvRes.data ? tvRes.data : [])
					} catch (err) {
						this.membersList = []
					}
				} else {
					this.membersList = []
				}

				// Fallback nếu hồ sơ cũ chưa có thành viên
				if (!this.membersList || this.membersList.length === 0) {
					this.fallbackMembersFromText(item.ChuNhiemDeTai, item.ThanhVienDeTai, item.DonViChuNhiem)
				}
			},
			getFileUrl(file) {
				const baseUrl = (this.vSet && this.vSet.urlReturnFile) || "https://file.lhu.edu.vn/qlnckh"
				return `${baseUrl}/FileData/${file.FILE_ID}`
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
					} else {
						this.pendingDeleteFileIDs.push(file.FILE_ID)
					}
				}
				this.attachedFiles = this.attachedFiles.filter(item => item.FILE_ID !== file.FILE_ID)
			},
			closeModal() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.uploadedFileIDs.join(',') }, () => {})
				}
				this.uploadedFileIDs = []
				this.pendingDeleteFileIDs = []
				this.dialog = false
			},
			formatMoney(val) {
				if (val === null || val === undefined || val === "") return "0"
				if (typeof formatAsCurrency === "function") {
					return formatAsCurrency(Number(val) || 0, 0)
				}
				return Number(val || 0).toLocaleString("vi-VN")
			},
			validateForm() {
				if (!this.form.TenDuAn || !String(this.form.TenDuAn).trim()) {
					Vue.$toast.warning("Vui lòng nhập Tên dự án / Hợp đồng", { position: "top" })
					return false
				}
				if (!this.membersList || this.membersList.length === 0) {
					Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên vào hợp đồng", { position: "top" })
					return false
				}
				const hasLeader = this.membersList.some(m => m.VaiTro === 1)
				if (!hasLeader) {
					Vue.$toast.warning("Hợp đồng cần có ít nhất 1 thành viên là Chủ nhiệm", { position: "top" })
					return false
				}
				if (!this.form.DonViTiepNhan || !String(this.form.DonViTiepNhan).trim()) {
					Vue.$toast.warning("Vui lòng nhập Đơn vị tiếp nhận", { position: "top" })
					return false
				}
				return true
			},
			async saveItem(targetStatus) {
				if (!this.validateForm()) return

				const confirmMsg = targetStatus === 2
					? `Bạn có chắc muốn gửi hồ sơ <b><i>${this.form.TenDuAn}</i></b> để thẩm định?`
					: `Bạn có muốn lưu hồ sơ <b><i>${this.form.TenDuAn}</i></b> dưới dạng dự thảo?`

				confirm({
					title: confirmMsg,
					action: async () => {
						this.saving = true
						try {
							const fileIdList = this.attachedFiles.map(item => item.FILE_ID).join(",")
							this.syncTextFromMembers()
							const params = {
								TenDuAn: this.form.TenDuAn,
								ChuNhiemDeTai: this.form.ChuNhiemDeTai,
								ThanhVienDeTai: this.form.ThanhVienDeTai,
								DonViChuNhiem: this.form.DonViChuNhiem,
								DonViTiepNhan: this.form.DonViTiepNhan,
								GiaTriHopDong: Number(this.form.GiaTriHopDong) || 0,
								NamThucHien: Number(this.form.NamThucHien) || null,
								SoHopDong: this.form.SoHopDong || "",
								DS_FileID: fileIdList,
								NamHoc: this.form.NamHoc,
								TrangThai: targetStatus
							}

							let res
							let targetCGCNID = this.form.CGCNID
							if (this.isEdit) {
								params.CGCNID = this.form.CGCNID
								res = await ajaxCALLPromise("/CGCN_Upd", params)
								Vue.$toast.success(
									targetStatus === 2
										? "Đã gửi hồ sơ thẩm định thành công!"
										: "Đã cập nhật dự thảo thành công!",
									{ position: "top" }
								)
							} else {
								res = await ajaxCALLPromise("/CGCN_Ins", params)
								if (res && res[0] && res[0].NewCGCNID) {
									targetCGCNID = res[0].NewCGCNID
								} else if (res && res.data && res.data[0] && res.data[0].NewCGCNID) {
									targetCGCNID = res.data[0].NewCGCNID
								}
								Vue.$toast.success(
									targetStatus === 2
										? "Kê khai & gửi thẩm định hồ sơ thành công!"
										: "Đã tạo dự thảo hồ sơ thành công!",
									{ position: "top" }
								)
							}

							// Lưu danh sách thành viên vào bảng riêng ChuyenGiaoCongNghe_ThanhVien
							if (targetCGCNID && this.membersList && this.membersList.length > 0) {
								await ajaxCALLPromise("/CGCN_ThanhVien_Save", {
									CGCNID: targetCGCNID,
									MembersJSON: JSON.stringify(this.membersList)
								})
							}

							if (this.pendingDeleteFileIDs && this.pendingDeleteFileIDs.length > 0) {
								ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: this.pendingDeleteFileIDs.join(',') }, () => {})
							}
							this.uploadedFileIDs = []
							this.pendingDeleteFileIDs = []
							this.$emit("on-reload")
							this.closeModal()
						} finally {
							this.saving = false
						}
					}
				})
			}
		}
	}
</script>

<template>
	<div class="menu-container">
		<div class="page-navigation pa-2">
			<div class="d-flex justify-space-between align-center">
				<div class="d-flex flex-row">
					<v-select v-model="selectedTenPhanHieu" :items="phanHieuOptions" label="Chọn phân hiệu" outlined
						dense hide-details />
					<v-btn color="primary" @click="onAddCategory" class="ml-2" elevation="0">
						<v-icon left>mdi-plus</v-icon>Thêm mới
					</v-btn>

				</div>
			</div>
		</div>
		<!-- ========== MAIN SECTION ========== -->
		<div class="menu-main-section">
			<div class="select-center"></div>
			<!-- === BOOKSHELF === -->
			<div class="bookshelf">
				<div class="shelf">
					<div class="items-row">
						<div v-for="item in displayedItems" :key="item.id || item.MenuBookID" class="menu-item"
							:class="{'has-badge': item.badge}">
							<div class="item-card" @click="openItemModal(item)">
								<!-- TAG -->
								<div v-if="item.Is_TamKhoa === 1" class="lock-overlay">
									<v-icon color="red" size="32">mdi-lock</v-icon>
								</div>
								<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
									<span class="ribbon__content"
										:style="{backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022'}">
										{{ item.TagBook }}
									</span>
								</div>
								<div class="item-image">
									<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
										:alt="item.TenBook" />
								</div>
								<!-- Phần hiện khi hover -->
								<div class="item-info-on-hover">
									<h3 class="menu-title">{{ item.TenBook }}</h3>
									<p class="menu-pages">Số trang: {{ getPageCount(item) }}</p>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- ========== DIALOG: Add New Menu ========== -->
		<v-dialog v-model="dialogAdd" width="1000">
			<v-card>
				<v-toolbar dense flat>
					<v-toolbar-title>Thêm mới menu</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogAdd = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-form ref="formAdd" v-model="formValid">
						<v-container>
							<v-row>
								<v-col cols="4">
									<p class="mb-0 font-weight-bold">
										Chọn cửa hàng áp dụng <span class="success--text ml-1">({{
											selectedCuaHang.length }} cửa hàng)</span>
									</p>
									<v-treeview class="store-list" v-model="selectedCuaHang" selectable
										:items="DSCuaHang_Tree" selected-color="primary" hoverable="true" dense>
									</v-treeview>
								</v-col>
								<v-col cols="8">
									<v-row>
										<!-- Tên menu -->
										<v-col cols="12">
											<v-text-field v-model="newItem.name" label="Tên menu"
												:rules="[(v) => !!v || 'Tên menu là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<!-- Chọn phân hiệu -->
										<v-col cols="4">
											<v-select v-model="newItem.PhanHieu_ID" :items="vueData.DSPhanHieu"
												item-text="TenPhanHieu" item-value="PhanHieuID" label="Phân hiệu"
												:rules="[(v) => (v !== null && v !== undefined && v !== '') || 'Phân hiệu là bắt buộc']"
												outlined dense hide-details />
										</v-col>
										<!-- Template -->
										<v-col cols="3">
											<v-select v-model="newItem.selectedTemplateType" :items="[
                                                    {text: 'Desktop', value: 'TemplateDesktop'},
                                                    {text: 'iPad', value: 'TemplateIpad'},
                                                    {text: 'Mobile', value: 'TemplateMobile'},
                                                ]" label="Màn hình"
												:rules="[(v) => !!v || 'Loại màn hình là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="2">
											<v-select v-model="newItem.TagBook" :items="[
                                                    {text: 'KHÔNG', value: 'NO'},
                                                    {text: 'HOT', value: 'HOT'},
                                                    {text: 'NEW', value: 'NEW'},
                                                ]" label="Tag" outlined dense hide-details />
										</v-col>
										<v-col cols="3">
											<v-select v-model="newItem.Is_TamKhoa" :items="[
                                                    {text: 'Hoạt động', value: 0},
                                                    {text: 'Tạm khóa', value: 1},
                                                ]" label="Tình trạng" outlined dense hide-details />
										</v-col>
										<!-- Upload ảnh -->
										<v-col cols="12" sm="12" class="mb-1">
											<f-image-update v-model="newItem.imageUrl" v-on:update="onImageUploaded"
												:api-upload="'https://file.zenfoodcourt.vn/eorder/upload/FileData'"
												label="Ảnh Bìa" dialog-width="600" dialog-height="400"
												:size="{width: 500, height: 500}" quality="1" :croper-attr="{
                                                    'stencil-props': {aspectRatio: null},
                                                    'default-size': {width: 9999, height: 9999},
                                                    transitions: true,
                                                    'image-restriction': 'fit-area',
                                                }" />
										</v-col>
									</v-row>
								</v-col>
							</v-row>
						</v-container>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn text color="primary" @click="submitNewItem">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- ========== DIALOG: Chi tiết menu ========== -->
		<v-dialog v-model="dialog" width="500">
			<v-card>
				<v-toolbar dense flat>
					<v-toolbar-title> {{ selectedItem?.TenBook }} ({{ totalPagesFromSelectedItem }}
						trang)</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialog = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text class="pa-6">
					<v-row>
						<v-col cols="12">
							<div v-if="totalPagesFromSelectedItem !== null" style="color: #7f8c8d">
								<v-select v-if="hasCuaHangID" v-model="CuaHangID" :items="filteredCuaHangList"
									item-value="CuaHangID" item-text="TenCuaHang" label="Cửa hàng" outlined dense
									hide-details></v-select>
							</div>
						</v-col>
						<!-- Image Section -->
						<v-col cols="7">
							<div class="image-container">
								<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + selectedItem?.Thumbnail_FileID"
									:alt="selectedItem?.TenBook"
									style="width: 100%; height: auto; object-fit: cover; border-radius: 8px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1)" />
							</div>
						</v-col>
						<!-- Content Section -->
						<v-col cols="5">
							<!-- Action Buttons -->
							<div class="d-flex flex-wrap" style="gap: 12px" v-if="selectedItem?.MenuBookID">
								<v-btn block elevation="0" color="success"
									:href="'https://eorder.zenfoodcourt.vn/menu-online?MenuBookID=' + selectedItem.MenuBookID + '&CuaHangID=' + (hasCuaHangID ? CuaHangID : 0)"
									target="_blank">
									<v-icon left>mdi-open-in-new</v-icon>Xem menu
								</v-btn>
								<v-btn block elevation="0" color="success" @click="openEditDialog(selectedItem)">
									<v-icon left>mdi-square-edit-outline</v-icon>Cập nhật
								</v-btn>
								<v-btn block elevation="0" color="success"
									:href="'https://eorder.zenfoodcourt.vn/menu-online-thiet-lap?MenuBookID=' + selectedItem.MenuBookID + '&PhanHieu_ID=' + newItem.PhanHieu_ID"
									target="_blank">
									<v-icon left>mdi-cog</v-icon>Thiết lập
								</v-btn>
								<v-btn block elevation="0" color="info" @click="openCopyDialog(selectedItem)">
									<v-icon left>mdi-content-copy</v-icon>Sao chép
								</v-btn>
								<v-btn block elevation="0" color="error" @click="onDeleteItem(selectedItem)">
									<v-icon left>mdi-trash-can-outline</v-icon>Xoá menu
								</v-btn>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog>
		<v-dialog v-model="dialogEdit" width="1000">
			<v-card>
				<v-toolbar dense flat>
					<v-toolbar-title>Cập nhật menu</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogEdit = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-form ref="formEdit" v-model="formValid">
						<v-container>
							<v-row>
								<v-col cols="4">
									<p class="mb-0 font-weight-bold">
										Chọn cửa hàng áp dụng <span class="success--text ml-1">({{
											selectedCuaHang.length }} cửa hàng)</span>
									</p>
									<v-treeview class="store-list" v-model="selectedCuaHang" selectable
										:items="DSCuaHang_Tree" selected-color="primary" hoverable="true" dense>
									</v-treeview>
								</v-col>
								<v-col cols="8">
									<v-row>
										<v-col cols="12">
											<v-text-field v-model="editItem.name" label="Tên Menu"
												:rules="[(v) => !!v || 'Tên menu là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="4">
											<v-select v-model="editItem.PhanHieu_ID" :items="vueData.DSPhanHieu"
												item-text="TenPhanHieu" item-value="PhanHieuID" label="Chọn phân hiệu"
												:rules="[(v) => !!v || 'Phân hiệu là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="3">
											<v-select v-model="editItem.selectedTemplateType" :items="[
                                                    {text: 'Desktop', value: 'TemplateDesktop'},
                                                    {text: 'iPad', value: 'TemplateIpad'},
                                                    {text: 'Mobile', value: 'TemplateMobile'},
                                                ]" label="Chọn loại màn hình" item-text="text" item-value="value"
												:rules="[(v) => !!v || 'Loại màn hình là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="2">
											<v-select v-model="editItem.TagBook" :items="[
                                                    {text: 'KHÔNG', value: 'NO'},
                                                    {text: 'HOT', value: 'HOT'},
                                                    {text: 'NEW', value: 'NEW'},
                                                ]" label="Tag" outlined dense hide-details />
										</v-col>
										<v-col cols="3">
											<v-select v-model="editItem.Is_TamKhoa" :items="[
                                                    {text: 'Hoạt động', value: 0},
                                                    {text: 'Tạm khóa', value: 1},
                                                ]" label="Tình trạng" outlined dense hide-details />
										</v-col>
										<v-col cols="12">
											<f-image-update v-model="editItem.imageUrl"
												v-on:update="onEditImageUploaded"
												:api-upload="'https://file.zenfoodcourt.vn/eorder/upload/FileData'"
												label="Ảnh bìa" dialog-width="600" dialog-height="400"
												:size="{width: 500, height: 500}" quality="1" :croper-attr="{
                                                    'stencil-props': {aspectRatio: null},
                                                    'default-size': {width: 9999, height: 9999},
                                                    transitions: true,
                                                    'image-restriction': 'fit-area',
                                                }" />
										</v-col>
									</v-row>
								</v-col>
							</v-row>
						</v-container>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn text color="primary" @click="submitEditItem">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
		<v-dialog v-model="dialogCopy" width="1000">
			<v-card>
				<v-toolbar dense flat>
					<v-toolbar-title>Sao chép menu</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="dialogCopy = false">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-form ref="formCopy" v-model="formValid">
						<v-container>
							<v-row>
								<v-col cols="4">
									<p class="mb-0 font-weight-bold">
										Chọn cửa hàng áp dụng
										<span class="success--text ml-1">({{ selectedCuaHang.length }} cửa hàng)</span>
									</p>
									<v-treeview class="store-list" v-model="selectedCuaHang" selectable
										:items="DSCuaHang_Tree" selected-color="primary" hoverable dense></v-treeview>
								</v-col>
								<v-col cols="8">
									<v-row>
										<v-col cols="12">
											<v-text-field v-model="copyItem.name" label="Tên Menu"
												:rules="[(v) => !!v || 'Tên menu là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="4">
											<v-select v-model="copyItem.PhanHieu_ID" :items="vueData.DSPhanHieu"
												item-text="TenPhanHieu" item-value="PhanHieuID" label="Chọn phân hiệu"
												outlined dense hide-details />
										</v-col>
										<v-col cols="3">
											<v-select v-model="copyItem.selectedTemplateType" :items="[
										      { text: 'Desktop', value: 'TemplateDesktop' },
										      { text: 'iPad', value: 'TemplateIpad' },
										      { text: 'Mobile', value: 'TemplateMobile' },
										    ]" label="Chọn loại màn hình" item-text="text" item-value="value"
												:rules="[(v) => !!v || 'Loại màn hình là bắt buộc']" outlined dense
												hide-details />
										</v-col>
										<v-col cols="2">
											<v-select v-model="copyItem.TagBook" :items="[
                      {text: 'KHÔNG', value: 'NO'},
                      {text: 'HOT', value: 'HOT'},
                      {text: 'NEW', value: 'NEW'},
                    ]" label="Tag" outlined dense hide-details />
										</v-col>
										<v-col cols="3">
											<v-select v-model="copyItem.Is_TamKhoa" :items="[
                      {text: 'Hoạt động', value: 0},
                      {text: 'Tạm khóa', value: 1},
                    ]" label="Tình trạng" outlined dense hide-details />
										</v-col>
										<v-col cols="12">
											<f-image-update v-model="copyItem.imageUrl"
												v-on:update="onCopyImageUploaded"
												:api-upload="'https://file.zenfoodcourt.vn/eorder/upload/FileData'"
												label="Ảnh bìa" dialog-width="600" dialog-height="400"
												:size="{width: 500, height: 500}" quality="1" :croper-attr="{
                      'stencil-props': {aspectRatio: null},
                      'default-size': {width: 9999, height: 9999},
                      transitions: true,
                      'image-restriction': 'fit-area',
                    }" />
										</v-col>
									</v-row>
								</v-col>
							</v-row>
						</v-container>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn text color="primary" @click="submitCopyItem">Sao chép menu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: "ZenMenuUI",
		props: {
			category_list: { type: Array, default: () => [] },
			loading: { type: Boolean, default: false },
			phanhieu: {
				type: String,
				default: "Tất cả",
			},
		},
		data() {
			return {
				dialogEdit: false,
				editItem: {
					name: "",
					PhanHieu_ID: 0,
					selectedTemplateType: "",
					imageUrl: "",
					imageFileID: "",
					TagBook: "NO",
					Is_TamKhoa: 0, // mặc định mở
				},
				dialogCopy: false,
				copyItem: {
					name: "",
					PhanHieu_ID: 0,
					selectedTemplateType: "",
					imageUrl: "",
					imageFileID: "",
					TagBook: "NO",
					Is_TamKhoa: 0,
				},
				DSCuaHang_Tree: [],
				selectedTenPhanHieu: "Tất cả",
				selectedCuaHang: [],
				currentPage: 1,
				totalPages: 1,
				v_loading: false,
				form_visible: false,
				dialog: false,
				openUploadDialog: false,
				selectedItem: null,
				dialogAdd: false,
				sortBy: "name", // 'name' or 'date'
				sortAsc: true, // true = ascending, false = descending
				newItem: {
					name: "",
					PhanHieu_ID: 0,
					TagBook: "NO", // mặc định là None
					Is_TamKhoa: 0,
					selectedTemplateType: "TemplateDesktop",
				},
				imageUrl: "", // ảnh đã upload
				imageFileID: "", // ID để lưu backend nếu cần
				formValid: true,
				CuaHangID: null,
			}
		},
	
		computed: {
			hasCuaHangID() {
				return !!this.selectedItem?.PhanHieu_ID
			},
			DSCuaHang() {
				return vueData?.DSCuaHang || []
			},
			filteredCuaHangList() {
				if (!this.selectedItem?.PhanHieu_ID || !Array.isArray(this.DSCuaHang)) return []
				return this.DSCuaHang.filter((c) => String(c.PhanHieuID) === String(this.selectedItem.PhanHieu_ID))
			},
			totalPagesFromSelectedItem() {
				if (!this.selectedItem) return null
				let templateJson = ""
				if (this.selectedItem.TemplateDesktop) {
					templateJson = this.selectedItem.TemplateDesktop
				} else if (this.selectedItem.TemplateIpad) {
					templateJson = this.selectedItem.TemplateIpad
				} else if (this.selectedItem.TemplateMobile) {
					templateJson = this.selectedItem.TemplateMobile
				} else {
					return null
				}
				try {
					const parsed = JSON.parse(templateJson)
					return parsed.length || 0
				} catch (e) {
					return 0
				}
			},
			phanHieuOptions() {
				const ds = vueData.DSPhanHieu || []
				return ["Tất cả", ...ds.map((p) => p.TenPhanHieu)]
			},
			displayedItems() {
				// Lọc theo selectedTenPhanHieu nếu có
				let filteredItems = this.category_list
				if (this.selectedTenPhanHieu && this.selectedTenPhanHieu !== "Tất cả") {
					// Tìm PhanHieu_ID từ tên
					const matched = vueData.DSPhanHieu.find((p) => p.TenPhanHieu === this.selectedTenPhanHieu)
					if (matched) {
						filteredItems = filteredItems.filter((item) => item.PhanHieu_ID === matched.PhanHieuID)
					} else {
						filteredItems = [] // không tìm thấy thì trả về rỗng
					}
				}
				// Tính lại totalPages
				this.totalPages = Math.ceil(filteredItems.length / 16)
				// Trả về các item trang hiện tại
				const startIndex = (this.currentPage - 1) * 16
				const endIndex = startIndex + 16
				return filteredItems.slice(startIndex, endIndex)
			},
		},
		mounted() {
			this.getStore()
			setTimeout(() => {
				if (this.vueData && Array.isArray(this.vueData.DSCuaHang) && this.vueData.DSCuaHang.length > 0 && !this.CuaHangID) {
					this.CuaHangID = this.vueData.DSCuaHang[0].CuaHangID
				}
			}, 500)
		},
		methods: {
			openCopyDialog(item) {
				this.copyItem = {
					name: item.TenBook + " (Copy)",
					PhanHieu_ID: item.PhanHieu_ID,
					selectedTemplateType: item.TemplateDesktop
						? "TemplateDesktop"
						: item.TemplateIpad
							? "TemplateIpad"
							: item.TemplateMobile
								? "TemplateMobile"
								: "TemplateDesktop", // fallback
					imageUrl: "https://file.zenfoodcourt.vn/eorder/auth/FileData/" + item.Thumbnail_FileID,
					imageFileID: item.Thumbnail_FileID,
					TagBook: item.TagBook,
					Is_TamKhoa: item.Is_TamKhoa ?? 0,
					MenuBookID: item.MenuBookID,
				}
				this.dialogCopy = true
			},
	
			onCopyImageUploaded($event) {
				const file = $event.returnData.Files[0]
				this.copyItem.imageFileID = file.FileID
				this.copyItem.imageUrl = "https://file.zenfoodcourt.vn/eorder/auth/" + file.Url
			},
	
			async submitCopyItem() {
				const isValid = this.$refs.formCopy?.validate?.()
				if (!isValid) {
					Vue.$toast.error("Vui lòng nhập đầy đủ thông tin trước khi sao chép.", { position: "top" })
					return
				}
				if (!this.copyItem.imageFileID) {
					Vue.$toast.error("Vui lòng chọn ảnh.", { position: "top" })
					return
				}
	
				let TemplateDesktop = ""
				let TemplateIpad = ""
				let TemplateMobile = ""
				if (this.copyItem.selectedTemplateType === "TemplateDesktop") TemplateDesktop = "default"
				if (this.copyItem.selectedTemplateType === "TemplateIpad") TemplateIpad = "default"
				if (this.copyItem.selectedTemplateType === "TemplateMobile") TemplateMobile = "default"
	
				let param = {
					MenuBookID: this.copyItem.MenuBookID,
					TenBook: this.copyItem.name,
					TagBook: this.copyItem.TagBook,
					PhanHieu_ID: this.copyItem.PhanHieu_ID,
					CuaHangApDungID: this.selectedCuaHang ? this.selectedCuaHang.join(",") : "",
					Is_TamKhoa: this.copyItem.Is_TamKhoa,
					Thumbnail_FileID: this.copyItem.imageFileID,
					TemplateDesktop,
					TemplateIpad,
					TemplateMobile,
				}
	
				ajaxCALL("/eorder/MenuBook_Clone", param, (res) => {
					this.dialogCopy = false
					Vue.$toast.success("Sao chép Menu thành công!", { position: "top" })
					runAction(vueData.apiGetList)
				})
			},
	
			getStore() {
				const $this = this
				ajaxCALL("/eorder/CuaHang_Select_Tree", {}, (res) => {
					$this.DSCuaHang_Tree = convertJsonToTree(res.data)
				})
			},
			getPageCount(item) {
				try {
					if (item.TemplateDesktop) return JSON.parse(item.TemplateDesktop).length
					if (item.TemplateIpad) return JSON.parse(item.TemplateIpad).length
					if (item.TemplateMobile) return JSON.parse(item.TemplateMobile).length
					return 0
				} catch (e) {
					return 0
				}
			},
			handleImageUpdate($event) {
				const file = $event.returnData.Files[0]
				vueData.AnhSanPham_FileID = file.FileID
				vueData.AnhSanPham_Url = "https://file.zenfoodcourt.vn/eorder/" + file.Url
			},
			openItemModal(item) {
				this.selectedItem = item
				const matchedCuaHang = this.DSCuaHang.filter((c) => c.PhanHieuID === item.PhanHieu_ID)
				this.CuaHangID = matchedCuaHang.length > 0 ? matchedCuaHang[0].CuaHangID : null
				//Set cửa hàng vào TreeView
				const arrSelectedStore = item.ApDung_CuaHangID.split(',')
				let cuaHangSelected = arrSelectedStore.map((item) => {
					return "C" + item
				})
				this.selectedCuaHang = cuaHangSelected
				this.dialog = true
			},
			badgeColor(type) {
				switch (type) {
					case "green":
						return "green"
					case "red":
						return "red"
					case "orange":
						return "orange darken-2"
					case "gold":
						return "yellow darken-3"
					default:
						return "grey"
				}
			},
			sortByField(field) {
				if (this.sortBy === field) {
					this.sortAsc = !this.sortAsc
				} else {
					this.sortBy = field
					this.sortAsc = true
				}
				this.category_list.sort((a, b) => {
					let valA = a[field]
					let valB = b[field]
					if (field === "date") {
						valA = new Date(valA).getTime()
						valB = new Date(valB).getTime()
					}
					if (valA < valB) return this.sortAsc ? -1 : 1
					if (valA > valB) return this.sortAsc ? 1 : -1
					return 0
				})
			},
			loadStoreList() {
				ajaxCALL("/eorder/MenuBook_Select", {}, (res) => {
					this.category_list = res || []
				})
			},
			openImageUploader() {
				this.openUploadDialog = true
			},
			onImageUploaded($event) {
				const file = $event.returnData.Files[0]
				this.newItem.imageFileID = file.FileID
				this.newItem.imageUrl = "https://file.zenfoodcourt.vn/eorder/auth/" + file.Url
				this.openUploadDialog = false
			},
			prevPage() {
				if (this.currentPage > 1) {
					this.currentPage--
				}
			},
			nextPage() {
				if (this.currentPage < this.totalPages) {
					this.currentPage++
				}
			},
			onAddCategory() {
				this.newItem = {
					name: "",
					PhanHieu_ID: 0,
					TagBook: "NO",
					Is_TamKhoa: 0,
					selectedTemplateType: "TemplateDesktop",
				}
				// Mở modal thêm mới
				this.dialogAdd = true
			},
			// Hàm xử lý khi ấn "Thêm" - đã sửa
			async submitNewItem() {
				const $this = this
				const isValid = $this.$refs.formAdd?.validate?.()
				if (!isValid) {
					Vue.$toast.error("Vui lòng nhập đầy đủ thông tin trước khi thêm.", { position: "top" })
					return
				}
				if (!$this.newItem.imageFileID) {
					Vue.$toast.error("Vui lòng chọn ảnh trước khi thêm.", { position: "top" })
					return
				}
				// Gán giá trị "default" vào trường template tương ứng
				if ($this.newItem.selectedTemplateType) {
					$this.newItem[$this.newItem.selectedTemplateType] = "default"
				}
				let param = {
					TenBook: $this.newItem.name,
					PhanHieu_ID: $this.newItem.PhanHieu_ID,
					Thumbnail_FileID: $this.newItem.imageFileID || "",
					TagBook: $this.newItem.TagBook || "",
					Is_TamKhoa: $this.newItem.Is_TamKhoa || 0,
					CuaHangApDungID: $this.selectedCuaHang ? $this.selectedCuaHang.join(",") : "",
				}
				ajaxCALL("/eorder/MenuBook_Insert", param, (res) => {
					this.dialogAdd = false
					Vue.$toast.success("Thêm Menu thành công!", { position: "top" })
					runAction(vueData.apiGetList)
				})
			},
			onDeleteItem(selectedItem) {
				const $this = this
				vueData.selectedItem = selectedItem
				confirm({
					title: `<b>Xác nhận</b>`,
					message: `Bạn có muốn xóa Menu không?`,
					action: function () {
						ajaxCALL(
							"/eorder/MenuBook_Delete",
							{
								MenuBookID: vueData.selectedItem.MenuBookID,
							},
							(res) => {
								$this.dialog = false
								Vue.$toast.success("Xóa Menu thành công!", { position: "top" })
								runAction(vueData.apiGetList)
							},
						)
					},
				})
			},
			onCloseForm() {
				this.form_visible = false
			},
			openEditDialog(item) {
				this.editItem = {
					name: item.TenBook,
					PhanHieu_ID: item.PhanHieu_ID,
					selectedTemplateType: item.TemplateDesktop ? "TemplateDesktop" : item.TemplateIpad ? "TemplateIpad" : item.TemplateMobile ? "TemplateMobile" : "",
					imageUrl: "https://file.zenfoodcourt.vn/eorder/auth/FileData/" + item.Thumbnail_FileID,
					imageFileID: item.Thumbnail_FileID,
					MenuBookID: item.MenuBookID,
					TagBook: item.TagBook,
					Is_TamKhoa: item.Is_TamKhoa ?? 0,
				}
	
				this.dialogEdit = true
			},
			onEditImageUploaded($event) {
				const file = $event.returnData.Files[0]
				this.editItem.imageFileID = file.FileID
				this.editItem.imageUrl = "https://file.zenfoodcourt.vn/eorder/auth/" + file.Url
			},
			async submitEditItem() {
				const $this = this
				const isValid = $this.$refs.formEdit?.validate?.()
				if (!isValid) {
					Vue.$toast.error("Vui lòng nhập đầy đủ thông tin trước khi cập nhật.", { position: "top" })
					return
				}
				if (!$this.editItem.imageFileID) {
					Vue.$toast.error("Vui lòng chọn ảnh.", { position: "top" })
					return
				}
				// Gán lại giá trị Template (reset hết, chỉ chọn 1 cái active)
				let TemplateDesktop = ""
				let TemplateIpad = ""
				let TemplateMobile = ""
				if ($this.editItem.selectedTemplateType === "TemplateDesktop") TemplateDesktop = "default"
				if ($this.editItem.selectedTemplateType === "TemplateIpad") TemplateIpad = "default"
				if ($this.editItem.selectedTemplateType === "TemplateMobile") TemplateMobile = "default"
				const param = {
					MenuBookID: this.editItem.MenuBookID,
					TenBook: this.editItem.name,
					TagBook: this.editItem.TagBook,
					PhanHieu_ID: this.editItem.PhanHieu_ID,
					CuaHangApDungID: this.selectedCuaHang ? this.selectedCuaHang.join(",") : "",
					Is_TamKhoa: this.editItem.Is_TamKhoa ?? 0,
					Thumbnail_FileID: this.editItem.imageFileID,
				}
				ajaxCALL("/eorder/MenuBook_Update", param, (res) => {
					const index = this.category_list.findIndex((item) => item.MenuBookID === this.editItem.MenuBookID)
					if (index !== -1) {
						const updatedItem = {
							...this.category_list[index],
							TenBook: this.editItem.name,
							PhanHieu_ID: this.editItem.PhanHieu_ID,
							Thumbnail_FileID: this.editItem.imageFileID,
							TagBook: this.editItem.TagBook,
							Is_TamKhoa: this.editItem.Is_TamKhoa,
						}
						this.$set(this.category_list, index, updatedItem)
						this.selectedItem = { ...updatedItem }
					}
					this.dialogEdit = false
					Vue.$toast.success("Cập nhật menu thành công!", { position: "top" })
				})
			},
		},
	}
</script>
<template>
	<v-form v-model="valid" lazy-validation ref="ValidForm">
		<v-row>
			<v-col cols="12" sm="6" md="12" class="pb-0">
				<v-text-field v-model="AnPhamObj.TenAnPham" label="Tên bài báo/Ấn phẩm" outlined dense></v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.LoaiAnPhamID" :items="DanhMucLoaiAnPhamArr" item-text="TenLoaiAnPham"
					item-value="LoaiAnPhamID" label="Danh mục bài báo/ấn phẩm" outlined dense
					@change="getDM_By_LoaiAnPhamID(AnPhamObj.LoaiAnPhamID)"></v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.LoaiSubAnPhamID" label="Thuộc danh mục tạp chí" :items="DMTC_Arr"
					item-text="TenLoaiSubAnPham" item-value="LoaiSubAnPhamID" :disabled="disabled_field_DMTC"
					@change="getTenDMTC_By_LoaiAnPhamID()" outlined dense>
				</v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.DanhMucLoaiTapChiID" label="Tên danh mục tạp chí" :items="TenDMTC_Arr"
					item-text="TenLoaiDanhMucTapChi" item-value="DanhMucLoaiTapChiID" :disabled="disabled_field_TDMTC"
					@change="get_TenLoaiDMTapChi" outlined dense>
				</v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.TenLoaiDanhMucTapChi" v-if="AnPhamObj.DanhMucLoaiTapChiID === 0"
					label="Tên loại danh mục tạp chí" outlined dense>
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="12" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.TenTapChi" ref="text" label="Tên Hội thảo/Tạp chí/Sách" outlined dense>
				</v-text-field>
			</v-col>


			<v-col cols="3" sm="3" md="2" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.NoiDangBai" :items="NoiDangBaiArr" label="Nơi đăng (Trong nước/ Quốc tế)"
					outlined dense></v-select>
			</v-col>
			<v-col cols="3" sm="3" md="2" class="pb-0 pt-0">
				<v-autocomplete v-model="AnPhamObj.NamDangBai" :items="NamArr" item-text="Nam" item-value="Nam"
					label="Năm đăng bài" outlined dense>
				</v-autocomplete>
			</v-col>
			<v-col cols="12" sm="6" md="4" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.DuongDanBaiBao" label="Link DOI/Link bài báo/minh chứng bài báo"
					outlined dense></v-text-field>
			</v-col>
			<v-col cols="3" sm="3" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.ISSN" label="ISSN/ISBN" outlined dense></v-text-field>
			</v-col>
			<v-col cols="3" sm="3" md="2" class="pb-0 pt-0">
				<v-text-field outlined dense v-model="AnPhamObj.HeSo_IF" :rules="DiemRules" @blur="setNullToZero()"
					label="Hệ số IF"></v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.DiemHoiDong" @blur="setNullToZero()" :rules="DiemRules"
					label="Điểm HĐCDGSNN" outlined dense>
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-autocomplete outlined dense v-model="AnPhamObj.HeSoChatLuongID" label="Điểm hệ số chất lượng"
					:items="dshesochatluong" item-text="DiemHeSoChatLuong" item-value="HeSoChatLuongID"
					:disabled="AnPhamObj.LoaiAnPhamID == 3">
					<template v-slot:item="data">
						<template v-if="typeof data.item !== 'object'">
							<v-list-item-content v-text="data.item"></v-list-item-content>
						</template>
						<template v-else>
							<v-list-item-content>
								<v-list-item-title v-html="data.item.TenHeSoChatLuong"></v-list-item-title>
							</v-list-item-content>
						</template>
					</template>
				</v-autocomplete>
			</v-col>
			<v-col cols="12">
				<v-card>
					<v-card-title class="primary--text">File Minh Chứng</v-card-title>
					<v-card-text>
						<v-data-table :headers="headersFile" :items="[{}]" :hide-default-footer="true">
							<template v-slot:item.minhchungbaibao="{ item }">
								<v-chip v-if="AnPhamObj.FileIDAnPham" label outlined color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlAnPham" target="_blank" close
									@click:close="del_fileItem">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameAnPham.slice(0, AnPhamObj.FileNameAnPham.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameAnPham.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else>
									<f-file-upload v-model="AnPhamObj.FileIDAnPham" class=" mr-4 mobile-f-file-upload"
										:filters="fileEX" label="Upload FILE" :url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileAnPham(value)" />
								</div>
							</template>
							<template v-slot:item.wos="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungWos" label outlined color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungWos" target="_blank"
									close @click:close="del_fileMinhChungWos">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameMinhChungWos.slice(0, AnPhamObj.FileNameMinhChungWos.length
											- 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameMinhChungWos.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else>
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungWos"
										class=" mr-4 mobile-f-file-upload" :filters="fileEX" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileMinhChungWos(value)" />
								</div>
							</template>
							<template v-slot:item.scopus="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungScopus" label outlined
									color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungScopus"
									target="_blank" close @click:close="del_fileMinhChungScopus">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameMinhChungScopus.slice(0,
											AnPhamObj.FileNameMinhChungScopus.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameMinhChungScopus.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else>
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungScopus"
										class=" mr-4 mobile-f-file-upload" :filters="fileEX" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileMinhChungScopus(value)" />
								</div>
							</template>
							<template v-slot:item.hdcdgsnn="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungHDCDGSNN" label outlined
									color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungHDCDGSNN"
									target="_blank" close @click:close="del_fileMinhChungHDCDGSNN">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameMinhChungHDCDGSNN.slice(0,
											AnPhamObj.FileNameMinhChungHDCDGSNN.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameMinhChungHDCDGSNN.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else>
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungHDCDGSNN"
										class=" mr-4 mobile-f-file-upload" :filters="fileEX" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white"
										@input="(value) => uploadFileMinhChungHDCDGSNN(value)" />
								</div>
							</template>
						</v-data-table>
					</v-card-text>
				</v-card>
			</v-col>

			<!-- MinhChungCaoHoc -->
			<v-col cols="12" sm="3" md="5" class="pb-0 pt-0 mb-3"
				v-if="AnPhamObj.NhomAnPham === 2 || AnPhamObj.NhomAnPham === 3">
				<v-toolbar-title class="primary--text mb-3">
					{{ AnPhamObj.NhomAnPham === 2 ? "File minh chứng Hỗ trợ đầu vào Cao học" :
						"File minh chứng có hướng dẫn Cao học" }}
				</v-toolbar-title>
				<f-file-upload v-model="AnPhamObj.FileIDMinhChungHoTroCaoHoc" :filters="fileEX" label="Upload"
					:url="vueData.v_Set.apiFile" color="white"
					@input="(value) => uploadFileAnPhamMinhChungHoTroCaoHoc(value)">
				</f-file-upload>
				<v-chip class="ml-4" v-if="AnPhamObj.FileIDMinhChungHoTroCaoHoc" label outlined
					color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungHoTroCaoHoc" target="_blank" close
					@click:close="del_fileMinhChungHoTroCaoHoc">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameMinhChungHoTroCaoHoc.slice(0, AnPhamObj.FileNameMinhChungHoTroCaoHoc.length
							- 4) }}
					</span>
					<span>{{ AnPhamObj.FileNameMinhChungHoTroCaoHoc.slice(-4) }}</span>
				</v-chip>
				<v-chip class="ml-4" v-else-if="AnPhamObj.NhomAnPham === 2" color="warning" label outlined>
					Upload file minh chứng Hỗ trợ Đầu vào Cao học (nếu có)
				</v-chip>
				<v-chip class="ml-4" v-else-if="AnPhamObj.NhomAnPham === 3" color="warning" label outlined>
					Upload file minh chứng hướng dẫn cao học (nếu có)
				</v-chip>
			</v-col>
			<v-col cols="12" class="pt-0">
				<v-toolbar-title class="primary--text">
					Phí đăng bài của BTC/ Ban biên tập
				</v-toolbar-title>
			</v-col>
			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-text-field class="text-input-right" v-model="PhiThongBao_Format"
					label="Phí đăng bài của BTC/ Ban biên tập" prefix="VNĐ" reverse outlined dense readonly>
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-text-field readonly reverse outlined dense class="text-input-right v-input--is-focused change-color"
					v-model="HoanPhiDangBaiTamTinh_Format" background-color="#E0F7FA"
					label="Phí hỗ trợ đăng bài (Tạm tính)" prefix="VNĐ">
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-text-field class="text-input-right warning--text v-input--is-focused change-color"
					v-model="HoanPhiDangBai_Format" label="Phí hỗ trợ đăng bài (Đã lưu)" prefix="VNĐ"
					background-color="#fffbe9" color="warning" reverse outlined dense>
				</v-text-field>
			</v-col>
			<v-col cols="3" sm="3" md="4" class="pb-0 pt-0 d-flex" style="gap:10px; align-items: center;">
				<f-file-upload v-model="ProofsObjArr" :filters="fileEX" label="Upload" :url="vueData.v_Set.apiFile"
					color="white" @input="(value) => uploadFileMinhChung(value)"></f-file-upload>
				<span v-if="ProofsObjArr[0].FileList.length > 0" class="d-flex flex-row">
					<v-chip class="me-3" close label outlined v-for="(item, index) in ProofsObjArr[0].FileList"
						color="deep-purple accent-4" target="_blank"
						:href="vueData.v_Set.urlReturnFile + item.FileUrlMinhChung"
						@click:close="del_fileMinhChung(index)">
						<v-icon left>mdi-file-check-outline</v-icon>
						{{ item.FileNameMinhChung }}
					</v-chip>
				</span>
				<v-chip v-else color="warning" label outlined>
					Upload file minh chứng chi phí (nếu có)
				</v-chip>
			</v-col>
		</v-row>
	</v-form>

</template>

<script>
export default {
	props: ["value", "editedindex", "danhmuctapchiarr", "danhmucloaianphamarr", "namarr", "dshesochatluong"],
	data() {
		return {
			valid: false,
			DMTC_Arr: [],
			TenDMTC_Arr: [],
			NoiDangBaiArr: ["Trong nước", "Quốc tế"],
			DiemRules: [
				v => /^\d*\.?\d*$/.test(v) || 'Điểm không hợp lệ'
			],
			fileEX: {
				max_file_size: '20mb',
				mime_types: [{ title: "All files", extensions: "*" }]
			},
			DSFileMinhChung: [
				{
					value: 1,
					title: 'Upload file minh chứng bài báo'
				},
				{
					value: 2,
					title: 'Upload file minh chứng wos(IF, Q)'
				},
				{
					value: 3,
					title: 'Upload file minh chứng Scopus'
				},
				{
					value: 4,
					title: 'Upload file minh chứng HĐGSNN'
				}
			],
			headersFile: [
				{ text: 'File minh chứng bài báo', sortable: false, value: "minhchungbaibao", align: "center" },
				{ text: 'File minh chứng wos(IF, Q)', sortable: false, value: "wos", align: "center" },
				{ text: 'File minh chứng Scopus', sortable: false, value: "scopus", align: "center" },
				{ text: 'File minh chứng HĐGSNN', sortable: false, value: "hdcdgsnn", align: "center" },
			],
			FileMinhChungID: 1,
			LoaiSubAnPhamID: null,
			DanhMucLoaiTapChi: null,
			disabled_field_TDMTC: false,
			disabled_field_DMTC: false
		}
	},
	computed: {
		PhiThongBao_Format: {
			get: function () {
				return formatAsCurrency(this.AnPhamObj.PhiThongBao, 0)
			},
			set: function (newValue) {
				this.AnPhamObj.PhiThongBao = Number(newValue.replace(/[^0-9\.]/g, ''))
			}
		},
		HoanPhiDangBai_Format: {
			get: function () {

				return formatAsCurrency(this.AnPhamObj.HoanPhiDangBai, 0)
			},
			set: function (newValue) {
				this.AnPhamObj.HoanPhiDangBai = Number(newValue.replace(/[^0-9\.]/g, ''))
			}
		},
		HoanPhiDangBaiTamTinh_Format: {
			get: function () {
				return formatAsCurrency(this.AnPhamObj.HoanPhiDangBaiTamTinh, 0)
			},
			set: function (newValue) {
				this.AnPhamObj.HoanPhiDangBaiTamTinh = Number(newValue.replace(/[^0-9\.]/g, ''))
			}
		},
		AnPhamObj: function () {
			return this.value.AnPhamObj
		},
		ProofsObjArr: function () {
			return this.value.ProofsObjArr
		},
		DanhMucTapChiArr: function () {
			return this.danhmuctapchiarr
		},
		DanhMucLoaiAnPhamArr: function () {
			return this.danhmucloaianphamarr.splice(1)
		},
		NamArr: function () {
			return this.namarr
		},

	},
	watch: {

	},
	methods: {
		uploadFileMinhChung(value) {
			let file = value.Files[0]
			let objfile = {
				FileIDMinhChung: file.FILE_ID,
				FileNameMinhChung: file.FILE_NAME,
				FileUrlMinhChung: file.FILE_URL
			}
			this.ProofsObjArr[0].FileList.push(objfile)
		},
		uploadFileAnPham(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDAnPham = file.FILE_ID
			this.AnPhamObj.FileUrLAnPham = file.FILE_URL
			this.AnPhamObj.FileNameAnPham = file.FILE_NAME
		},
		uploadFileMinhChungWos(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungWos = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungWos = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungWos = file.FILE_NAME
		},
		uploadFileMinhChungScopus(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungScopus = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungScopus = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungScopus = file.FILE_NAME
		},
		uploadFileMinhChungHDCDGSNN(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungHDCDGSNN = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungHDCDGSNN = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungHDCDGSNN = file.FILE_NAME
		},

		del_fileMinhChungScopus() {
			this.AnPhamObj.FileIDMinhChungScopus = null
			this.AnPhamObj.FileUrlMinhChungScopus = null
			this.AnPhamObj.FileNameMinhChungScopus = null
		},
		del_fileMinhChungHDCDGSNN() {
			this.AnPhamObj.FileIDMinhChungHDCDGSNN = null
			this.AnPhamObj.FileUrlMinhChungHDCDGSNN = null
			this.AnPhamObj.FileNameMinhChungHDCDGSNN = null
		},
		del_fileMinhChungWos() {
			this.AnPhamObj.FileIDMinhChungWos = null
			this.AnPhamObj.FileUrlMinhChungWos = null
			this.AnPhamObj.FileNameMinhChungWos = null
		},
		del_fileItem() {
			this.AnPhamObj.FileIDAnPham = null
			this.AnPhamObj.FileUrLAnPham = null
			this.AnPhamObj.FileNameAnPham = null
		},
		del_fileMinhChung(index) {
			this.value.ProofsObjArr[0].FileList.splice(index, 1)
		},
		get_TenLoaiDMTapChi() {
			const DMTapChi_Obj = this.DanhMucTapChiArr.find(item =>
				item.DanhMucLoaiTapChiID === this.value.AnPhamObj.DanhMucLoaiTapChiID
			)
			if (this.value.AnPhamObj.DanhMucLoaiTapChiID === 0) {
				this.value.AnPhamObj.TenLoaiDanhMucTapChi = ""
			} else {
				this.value.AnPhamObj.TenLoaiDanhMucTapChi = DMTapChi_Obj.TenLoaiDanhMucTapChi
			}
		},
		//Hàm để sau khi người dùng click vào field xong xóa 0.0 và để field null
		setNullToZero() {
			if (this.AnPhamObj.HeSo_IF === null || this.AnPhamObj.HeSo_IF === "") {
				this.AnPhamObj.HeSo_IF = convertDiem(0)
			} else if (this.AnPhamObj.DiemHoiDong === null || this.AnPhamObj.DiemHoiDong === "") {
				this.AnPhamObj.DiemHoiDong = convertDiem(0)
			}
		},
		//Hàm lấy dữ liệu của field Thuộc danh mục tạp chí
		getDM_By_LoaiAnPhamID() {
			if (this.AnPhamObj.LoaiAnPhamID === 1 || this.AnPhamObj.LoaiAnPhamID === 3) {
				this.AnPhamObj.NoiDangBai = this.NoiDangBaiArr[0]
			} else if (this.AnPhamObj.LoaiAnPhamID === 2 || this.AnPhamObj.LoaiAnPhamID === 4) {
				this.AnPhamObj.NoiDangBai = this.NoiDangBaiArr[1]
			}
			this.AnPhamObj.LoaiSubAnPhamID = null
			this.AnPhamObj.DanhMucLoaiTapChiID = null
			this.TenDMTC_Arr = [],
				this.AnPhamObj.TenLoaiDanhMucTapChi = ""
			ajaxCALL("/AnPham_Loai_Sub_Get", {
				LoaiAnPhamID: this.AnPhamObj.LoaiAnPhamID
			}, res => {
				this.DMTC_Arr = res.data
				if (this.DMTC_Arr.length < 2) {
					this.disabled_field_DMTC = true
					this.disabled_field_TDMTC = true
					this.$refs.text.focus()
				} else {
					this.disabled_field_DMTC = false
					this.disabled_field_TDMTC = false
				}
			}, err => {
				console.log(err)
			})
		},
		//Hàm lấy dữ liệu của field Tên danh mục tạp chí
		getTenDMTC_By_LoaiAnPhamID() {

			this.AnPhamObj.DanhMucLoaiTapChiID = null
			if (this.AnPhamObj.LoaiSubAnPhamID === 9) {
				this.AnPhamObj.DanhMucLoaiTapChiID = 34
				this.AnPhamObj.TenTapChi = "Tạp chí Khoa học Lạc Hồng"
				this.AnPhamObj.TenLoaiDanhMucTapChi = "Tạp chí Khoa học Lạc Hồng"
			}
			ajaxCALL("/LoaiDMTapChi_Get_ByLoaiSubAnPhamID", {
				LoaiSubAnPhamID: this.AnPhamObj.LoaiSubAnPhamID
			}, res => {
				this.TenDMTC_Arr = res.data
				if (this.TenDMTC_Arr.length < 2) {
					this.disabled_field_TDMTC = true
					this.$refs.text.focus()
				}
				else {
					this.disabled_field_TDMTC = false
				}
			}, err => {
				console.log(err)
			})
		},
		//----------
		getDM_By_LoaiAnPhamID_Edit() {
			ajaxCALL("/AnPham_Loai_Sub_Get", {
				LoaiAnPhamID: this.AnPhamObj.LoaiAnPhamID
			}, res => {
				this.DMTC_Arr = res.data
				if (this.DMTC_Arr.length < 2) {
					this.disabled_field_DMTC = true
					this.disabled_field_TDMTC = true
					this.$refs.text.focus()
				}
				else {
					this.disabled_field_DMTC = false
					this.disabled_field_TDMTC = false
				}
			}, err => {
				console.log(err)
			})
		},
		//-----
		getTenDMTC_By_LoaiAnPhamID_Edit() {
			ajaxCALL("/LoaiDMTapChi_Get_ByLoaiSubAnPhamID", {
				LoaiSubAnPhamID: this.AnPhamObj.LoaiSubAnPhamID
			}, res => {
				this.TenDMTC_Arr = res.data
				if (this.TenDMTC_Arr.length < 2) {
					this.disabled_field_TDMTC = true
					if (this.editedindex !== -1) {

					} else {
						this.$refs.text.focus()
					}

				}
				else {
					this.disabled_field_TDMTC = false
				}
			}, err => {
				console.log(err)
			})
		},
		getDM_By_LoaiAnPhamID_from_parent() {
			this.$nextTick(async () => {
				await this.$refs.FormAnPham.getDM_By_LoaiAnPhamID_Edit()
			})

		},
		getDM_By_LoaiSubAnPhamID_from_parent() {
			this.$nextTick(async () => {
				await this.$refs.FormAnPham.getTenDMTC_By_LoaiAnPhamID_Edit()
			})

		},
		uploadFileAnPhamMinhChungHoTroCaoHoc(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungHoTroCaoHoc = file.FILE_ID
			this.AnPhamObj.FileNameMinhChungHoTroCaoHoc = file.FILE_NAME
			this.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = file.FILE_URL
		},
		del_fileMinhChungHoTroCaoHoc() {
			this.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null
			this.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null
			this.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null
		},
	},
}
</script>
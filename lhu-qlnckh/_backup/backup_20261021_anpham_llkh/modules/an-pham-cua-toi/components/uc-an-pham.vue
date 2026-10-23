<template>
	<v-form ref="ValidForm" v-model="valid" lazy-validation>
		<v-row>
			<v-col cols="12" sm="12" md="12" class="pb-0">
				<v-text-field v-model="AnPhamObj.TenAnPham" label="Tên bài báo/Ấn phẩm" outlined dense readonly />
			</v-col>

			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.LoaiAnPhamID" :items="DanhMucLoaiAnPhamArr" item-text="TenLoaiAnPham"
					item-value="LoaiAnPhamID" label="Danh mục bài báo/ấn phẩm" outlined dense
					@change="getDM_By_LoaiAnPhamID(AnPhamObj.LoaiAnPhamID)" readonly></v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.LoaiSubAnPhamID" label="Thuộc danh mục tạp chí" :items="DMTC_Arr"
					item-text="TenLoaiSubAnPham" item-value="LoaiSubAnPhamID" :disabled="disabled_field_DMTC"
					@change="getTenDMTC_By_LoaiAnPhamID()" outlined dense readonly>
				</v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.DanhMucLoaiTapChiID" label="Tên danh mục tạp chí" :items="TenDMTC_Arr"
					item-text="TenLoaiDanhMucTapChi" :disabled="disabled_field_TDMTC" item-value="DanhMucLoaiTapChiID"
					@change="get_TenLoaiDMTapChi" outlined dense readonly>
				</v-select>
			</v-col>
			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.TenLoaiDanhMucTapChi" v-if="AnPhamObj.DanhMucLoaiTapChiID === 0"
					label="Tên loại danh mục tạp chí" outlined dense readonly>
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="12" class="pb-0 pt-0">
				<v-text-field readonly v-model="AnPhamObj.TenTapChi" ref="text" label="Tên Hội thảo/Tạp chí/Sách"
					outlined dense>
				</v-text-field>
			</v-col>

			<v-col cols="6" sm="6" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.NoiDangBai" label="Nơi đăng (Trong nước/ Quốc tế)" outlined dense
					readonly></v-text-field>
			</v-col>
			<v-col cols="6" sm="6" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.NamDangBai" label="Năm đăng bài" outlined dense readonly>
				</v-text-field>
			</v-col>
			<v-col cols="12" sm="6" md="4" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.DuongDanBaiBao" readonly
					label="Link DOI/Link bài báo/minh chứng bài báo" outlined dense></v-text-field>
			</v-col>

			<v-col cols="12" sm="3" md="2" class="pb-0 pt-0 margin-mobile">
				<v-text-field v-model="AnPhamObj.ISSN" label="ISSN/ISBN" outlined dense readonly></v-text-field>
			</v-col>
			<v-col cols="6" sm="3" md="2" class="pb-0 pt-0">
				<v-text-field outlined dense v-model="AnPhamObj.HeSo_IF" label="Hệ số IF" readonly>
				</v-text-field>
			</v-col>
			<v-col cols="6" sm="6" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.DiemHoiDong" label="Điểm HĐCDGSNN" outlined dense readonly>
				</v-text-field>
			</v-col>
			<v-col cols="6" sm="6" md="2" class="pb-0 pt-0">
				<v-text-field dense outlined v-model="AnPhamObj.DiemHeSoChatLuong" label="Điểm hệ số chất lượng"
					readonly>

				</v-text-field>
			</v-col>
			<!-- File minh chứng bài báo -->
			<v-col cols="12" class="pb-0 pt-0 mb-2 d-flex flex-row">
				<span class="font-weight-medium ">File minh chứng bài báo:</span>
				<v-chip class="ml-4" v-if="AnPhamObj.FileIDAnPham" label outlined color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlAnPham" target="_blank">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameAnPham.slice(0, AnPhamObj.FileNameAnPham.length - 4) }}
					</span>
					<span>{{ AnPhamObj.FileNameAnPham.slice(-4) }}</span>
				</v-chip>
				<v-chip class="ml-4" v-else color="warning" label outlined>
					Chưa upload file
				</v-chip>
			</v-col>
			<!-- File minh chứng Wos -->
			<v-col cols="12" class="pb-0 pt-0 mb-2 d-flex flex-row">
				<span class="font-weight-medium ">File minh chứng Wos:</span>
				<v-chip class="ml-4" v-if="AnPhamObj.FileIDMinhChungWos" label outlined color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungWos" target="_blank">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameMinhChungWos.slice(0, AnPhamObj.FileNameMinhChungWos.length - 4) }}
					</span>
					<span>{{ AnPhamObj.FileNameMinhChungWos.slice(-4) }}</span>
				</v-chip>
				<v-chip class="ml-4" v-else color="warning" label outlined>
					Chưa upload file
				</v-chip>
			</v-col>
			<!-- File minh chứng Scopus -->
			<v-col cols="12" class="pb-0 pt-0 mb-2 d-flex flex-row">
				<span class="font-weight-medium ">File minh chứng Scopus:</span>
				<v-chip class="ml-4" v-if="AnPhamObj.FileIDMinhChungScopus" label outlined color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungScopus" target="_blank">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameMinhChungScopus.slice(0, AnPhamObj.FileNameMinhChungScopus.length - 4) }}
					</span>
					<span>{{ AnPhamObj.FileNameMinhChungScopus.slice(-4) }}</span>
				</v-chip>
				<v-chip class="ml-4" v-else color="warning" label outlined>
					Chưa upload file
				</v-chip>
			</v-col>
			<!-- File minh chứng HĐCDGSNN -->
			<v-col cols="12" class="pb-0 pt-0 mb-2 d-flex flex-row">
				<span class="font-weight-medium">File minh chứng HĐCDGSNN:</span>
				<v-chip class="ml-4" v-if="AnPhamObj.FileIDMinhChungHDCDGSNN" label outlined
					color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungHDCDGSNN" target="_blank">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameMinhChungHDCDGSNN.slice(0, AnPhamObj.FileNameMinhChungHDCDGSNN.length - 4)
						}}
					</span>
					<span>{{ AnPhamObj.FileNameMinhChungHDCDGSNN.slice(-4) }}</span>
				</v-chip>
				<v-chip class="ml-4" v-else color="warning" label outlined>
					Chưa upload file
				</v-chip>
			</v-col>
			<v-col cols="12" class=" pb-0" v-if="AnPhamObj.TrangThaiID === 5">
				<v-toolbar-title class="error--text font-weight-medium ">
					Lý do từ chối
				</v-toolbar-title>
			</v-col>
			<v-col cols="12" md="6" sm="12" class="pt-0 mt-1" v-if="AnPhamObj.TrangThaiID === 5">
				<v-textarea v-model="AnPhamObj.LyDoReject" dense hide-details outlined readonly="true"></v-textarea>
			</v-col>
			<v-col cols="12" class="mt-2 pt-0">
				<v-toolbar-title class="primary--text">
					Phí đăng bài của BTC/ Ban biên tập
				</v-toolbar-title>
			</v-col>
			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-text-field class="text-input-right" v-model="PhiThongBao_Format"
					label="Phí đăng bài của BTC/ Ban biên tập" prefix="VNĐ" reverse outlined dense readonly>
				</v-text-field>
			</v-col>
			<v-col class="pb-0 pt-0 d-flex" style=" gap:10px;">

				<span v-if="ProofsObjArr[0].FileList.length > 0" class="d-flex mt-1 " style="flex-wrap:wrap ;gap:10px">
					<v-chip close label outlined v-for="(item, index) in ProofsObjArr[0].FileList"
						color="deep-purple accent-4" :href="vueData.v_Set.urlReturnFile + item.FileUrlMinhChung"
						target="_blank">
						<v-icon left>mdi-file-check-outline</v-icon>
						{{ item.FileNameMinhChung }}
					</v-chip>
				</span>
			</v-col>
		</v-row>
	</v-form>
</template>

<script>
export default {
	props: ["value", "editedindex", "danhmuctapchiarr", "danhmucloaianphamarr", "namarr", "checkvalidate", "refFormAnPham", "dshesochatluong"],
	data() {
		return {
			DMTC_Arr: [],
			TenDMTC_Arr: [],
			valid: false,
			LoaiSubAnPhamID: null,
			DanhMucLoaiTapChi: null,
			disabled_field_TDMTC: false,
			disabled_field_DMTC: false

		}

	},
	mounted() {


	},
	computed: {
		PhiThongBao_Format: {
			get: function () {
				return formatAsCurrency(this.AnPhamObj.PhiThongBao, 0)
			},
			set: function (newValue) {
				this.AnPhamObj.PhiThongBao = Number(newValue.replace(/[^0-9\.]/g, ''));
			}
		},

		AnPhamObj: function () {
			return this.value.AnPhamObj
		},
		ProofsObjArr: function () {
			return this.value.ProofsObjArr
		},
		DanhMucLoaiAnPhamArr: function () {
			return this.danhmucloaianphamarr
		}


	},
	watch: {
	},
	methods: {
		get_TenLoaiDMTapChi() {
			const DMTapChi_Obj = this.TenDMTC_Arr.find(item =>
				item.DanhMucLoaiTapChiID === this.value.AnPhamObj.DanhMucLoaiTapChiID
			)
			if (this.value.AnPhamObj.DanhMucLoaiTapChiID === 0) {
				this.value.AnPhamObj.TenLoaiDanhMucTapChi = ""
			} else {
				this.value.AnPhamObj.TenLoaiDanhMucTapChi = DMTapChi_Obj.TenLoaiDanhMucTapChi
			}
		},

		//Hàm lấy dữ liệu của field Thuộc danh mục tạp chí
		getDM_By_LoaiAnPhamID() {
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
		//---------- Hàm này được gọi để lấy dữ liệu field Thuộc danh mục tạp chí, khi ấn Edit ở component uc-money-back-1 để binding lên field
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
		//---------- Hàm này được gọi để lấy dữ liệu field Tên danh mục tạp chí, khi ấn Edit ở component uc-money-back-1 
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
	},
}
</script>
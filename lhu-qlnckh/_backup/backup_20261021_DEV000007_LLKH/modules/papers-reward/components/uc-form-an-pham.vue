<template>
	<v-form ref="ValidForm" v-model="valid" lazy-validation>
		<v-row>
			<v-col cols="12" class="pb-0">
				<v-text-field v-model="AnPhamObj.TenAnPham" label="Tên bài báo/Ấn phẩm"
					:rules="[v => !!v || 'Trường này bắt buộc nhập']" outlined dense />
			</v-col>

			<v-col cols="12" class="pb-0 pt-0">
				<v-menu v-model="isPublicationTypeMenuOpen" offset-y open-on-click :close-on-content-click="false">
					<template v-slot:activator="{ on, attrs }">
						<v-text-field :value="selectedLoaiAnPhamText" label="Danh mục bài báo/ấn phẩm" readonly outlined
							dense append-icon="mdi-menu-down" v-bind="attrs" v-on="on"></v-text-field>
					</template>
					<v-card class="d-flex publication-type-menu" flat>
						<v-list dense width="280">
							<v-list-item v-for="item in DanhMucLoaiAnPhamArr" :key="item.LoaiAnPhamID"
								:class="{ 'publication-type-item-active': activeLoaiAnPham && activeLoaiAnPham.LoaiAnPhamID === item.LoaiAnPhamID }"
								@mouseenter="setActiveLoaiAnPham(item)" @click="handleLoaiAnPhamClick(item)">
								<v-list-item-content>
									<v-list-item-title>{{ item.TenLoaiAnPham }}</v-list-item-title>
								</v-list-item-content>
								<v-list-item-icon v-if="hasSubAnPham(item)">
									<v-icon small>mdi-chevron-right</v-icon>
								</v-list-item-icon>
							</v-list-item>
						</v-list>
						<v-divider vertical v-if="activeSubAnPhamArr.length > 0"></v-divider>
						<v-list dense v-if="activeSubAnPhamArr.length > 0" :style="publicationSubColumnStyle">
							<v-list-item v-for="subItem in activeSubAnPhamArr" :key="subItem.LoaiSubAnPhamID"
								:class="{ 'publication-type-item-active': activeLoaiSubAnPham && activeLoaiSubAnPham.LoaiSubAnPhamID === subItem.LoaiSubAnPhamID }"
								@mouseenter="setActiveLoaiSubAnPham(subItem)"
								@click="handleLoaiSubAnPhamClick(subItem)">
								<v-list-item-content>
									<v-list-item-title>{{ subItem.TenLoaiSubAnPham }}</v-list-item-title>
								</v-list-item-content>
								<v-list-item-icon v-if="hasDanhMucTapChi(subItem)">
									<v-icon small>mdi-chevron-right</v-icon>
								</v-list-item-icon>
							</v-list-item>
						</v-list>
						<v-divider vertical v-if="activeDanhMucTapChiArr.length > 0"></v-divider>
						<v-list dense v-if="activeDanhMucTapChiArr.length > 0" :style="publicationDanhMucColumnStyle">
							<v-list-item v-for="danhMucItem in activeDanhMucTapChiArr"
								:key="danhMucItem.DanhMucLoaiTapChiID"
								:class="{ 'publication-type-item-active': activeTapChi && activeTapChi.DanhMucLoaiTapChiID === danhMucItem.DanhMucLoaiTapChiID }"
								@mouseenter="setActiveDanhMucTapChi(danhMucItem)"
								@click="selectDanhMucTapChi(activeLoaiAnPham, activeLoaiSubAnPham, danhMucItem)">
								<v-list-item-content>
									<v-list-item-title>{{ danhMucItem.TenLoaiDanhMucTapChi }}</v-list-item-title>
								</v-list-item-content>
							</v-list-item>
						</v-list>
					</v-card>
				</v-menu>
			</v-col>

			<v-col cols="12" md="6" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.TenTapChi" ref="text" label="Tên Hội thảo/Tạp chí/Sách"
					:rules="[v => !!v || 'Trường này bắt buộc nhập']" outlined dense>
				</v-text-field>
			</v-col>

			<v-col cols="12" sm="6" md="6" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.DuongDanBaiBao" label="Link DOI/Link bài báo/minh chứng bài báo"
					outlined dense>
				</v-text-field>
			</v-col>

			<v-col cols="6" sm="3" md="4" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.NoiDangBai" :items="noiDangBaiArr" label="Nơi đăng (Trong nước/ Quốc tế)"
					outlined dense></v-select>
			</v-col>

			<v-col cols="6" sm="3" md="2" class="pb-0 pt-0">
				<v-autocomplete v-model="AnPhamObj.NamDangBai" :items="NamArr" item-text="Nam" item-value="Nam"
					label="Năm đăng bài" outlined dense>
				</v-autocomplete>
			</v-col>

			<v-col cols="12" sm="3" md="2" class="pb-0 pt-0 margin-mobile">
				<v-text-field v-model="AnPhamObj.ISSN" label="ISSN/ISBN" outlined dense></v-text-field>
			</v-col>

			<v-col cols="6" sm="3" md="2" class="pb-0 pt-0">
				<v-text-field v-model="AnPhamObj.TapSoTrang" label="Tập, số, trang" hint="Ví dụ: Vol. 7, No. 2, pp. 12-20"
					outlined dense></v-text-field>
			</v-col>

			<v-col cols="6" sm="3" md="2" class="pb-0 pt-0">
				<v-select v-model="AnPhamObj.ThangDang" :items="thangArr" label="Tháng đăng" clearable outlined dense></v-select>
			</v-col>

			<v-col cols="12" sm="6" md="4" class="pb-0 pt-0" v-if="AnPhamObj.LoaiAnPhamID === 6">
				<v-select v-model="AnPhamObj.TheLoaiBienSoanID" :items="theLoaiBienSoanArr" item-text="title"
					item-value="value" label="Thể loại sách (chuyên khảo, chương sách, giáo trình...)" clearable outlined
					dense></v-select>
			</v-col>

			<v-col cols="6" sm="6" md="2" class="pb-0 pt-0 ">
				<v-text-field v-model="AnPhamObj.DiemHoiDong" hint="Ví dụ: 9.0" label="Điểm HĐCDGSNN"
					@click="clearDiemHoiDong" :rules="diemRules" outlined dense @blur="setNullToZero()">
				</v-text-field>
			</v-col>

			<v-col cols="6" sm="3" md="2" class="pb-0 pt-0 ">
				<v-text-field outlined dense v-model="AnPhamObj.HeSo_IF" hint="Ví dụ: 9.0" @click="clearIF"
					v-if="!isAnPhamTrongNuoc" :rules="diemRules" label="Hệ số IF" @blur="setNullToZero()">
				</v-text-field>
			</v-col>

			<v-col cols="12">
				<v-card>
					<v-card-title class="primary--text">File Minh Chứng</v-card-title>
					<v-card-text>
						<v-data-table :headers="headersFile" :items="[{}]" :hide-default-footer="true">
							<template v-slot:item.minhchungbaibao="{ item }">
								<v-chip v-if="AnPhamObj.FileIDAnPham || AnPhamObj.FileUrlAnPham" key="chip-baibao" label
									outlined color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlAnPham" target="_blank" close
									@click:close="del_fileItem">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameAnPham.slice(0, AnPhamObj.FileNameAnPham.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameAnPham.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else key="upload-baibao">
									<f-file-upload v-model="AnPhamObj.FileIDAnPham" class=" mr-4 mobile-f-file-upload"
										:filters="fileEx" label="Upload FILE" :url="vueData.v_Set.apiFile" color="white"
										@input="uploadFileAnPham" />
								</div>
							</template>
							<template v-slot:item.wos="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungWos || AnPhamObj.FileUrlMinhChungWos"
									key="chip-wos" label outlined color="deep-purple accent-4"
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
								<div class="w-100" v-else key="upload-wos">
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungWos"
										class=" mr-4 mobile-f-file-upload" :filters="fileEx" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white" @input="uploadFileMinhChungWos" />
								</div>
							</template>
							<template v-slot:item.scopus="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungScopus || AnPhamObj.FileUrlMinhChungScopus"
									key="chip-scopus" label outlined color="deep-purple accent-4"
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
								<div class="w-100" v-else key="upload-scopus">
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungScopus"
										class=" mr-4 mobile-f-file-upload" :filters="fileEx" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white" @input="uploadFileMinhChungScopus" />
								</div>
							</template>
							<template v-slot:item.hdcdgsnn="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungHDCDGSNN || AnPhamObj.FileUrlMinhChungHDCDGSNN"
									key="chip-hdcdgsnn" label outlined color="deep-purple accent-4"
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
								<div class="w-100" v-else key="upload-hdcdgsnn">
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungHDCDGSNN"
										class=" mr-4 mobile-f-file-upload" :filters="fileEx" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white"
										@input="uploadFileMinhChungHDCDGSNN" />
								</div>
							</template>
							<template v-slot:item.lacHong="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungLacHong || AnPhamObj.FileUrlMinhChungLacHong"
									key="chip-lachong" label outlined color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungLacHong"
									target="_blank" close @click:close="del_fileMinhChungLacHong">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameMinhChungLacHong.slice(0,
										AnPhamObj.FileNameMinhChungLacHong.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameMinhChungLacHong.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else key="upload-lachong">
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungLacHong"
										class=" mr-4 mobile-f-file-upload" :filters="fileEx" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white"
										@input="uploadFileMinhChungLacHong" />
								</div>
							</template>
							<template v-slot:item.minhchungkhac="{ item }">
								<v-chip v-if="AnPhamObj.FileIDMinhChungKhac || AnPhamObj.FileUrlMinhChungKhac"
									key="chip-khac" label outlined color="deep-purple accent-4"
									:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungKhac" target="_blank"
									close @click:close="del_fileMinhChungKhac">
									<v-icon left>mdi-file-check-outline</v-icon>
									<span
										style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
										{{ AnPhamObj.FileNameMinhChungKhac.slice(0,
										AnPhamObj.FileNameMinhChungKhac.length - 4) }}
									</span>
									<span>{{ AnPhamObj.FileNameMinhChungKhac.slice(-4) }}</span>
								</v-chip>
								<div class="w-100" v-else key="upload-khac">
									<f-file-upload v-model="AnPhamObj.FileIDMinhChungKhac"
										class=" mr-4 mobile-f-file-upload" :filters="fileEx" label="Upload FILE"
										:url="vueData.v_Set.apiFile" color="white" @input="uploadFileMinhChungKhac" />
								</div>
							</template>
						</v-data-table>
					</v-card-text>
				</v-card>
			</v-col>

			<v-col cols="12" class=" pb-0" v-if="AnPhamObj.TrangThaiID === 5">
				<v-toolbar-title class="error--text font-weight-medium ">
					Lý do từ chối
				</v-toolbar-title>
			</v-col>

			<v-col cols="12" md="6" sm="12" class="pt-0 mt-1" v-if="AnPhamObj.TrangThaiID === 5">
				<v-textarea v-model="AnPhamObj.LyDoReject" dense hide-details outlined readonly="true"></v-textarea>
			</v-col>
			<!-- MinhChungCaoHoc -->
			<v-col cols="12" sm="3" md="5" class="pb-0 pt-0"
				v-if="AnPhamObj.NhomAnPham === 2 || AnPhamObj.NhomAnPham === 3">
				<v-toolbar-title class="primary--text mb-3">
					{{ AnPhamObj.NhomAnPham === 2 ? "File minh chứng Hỗ trợ đầu vào Cao học" : 'File minh chứng có hướng
					dẫn Cao học' }}
				</v-toolbar-title>
				<f-file-upload v-model="AnPhamObj.FileIDMinhChungHoTroCaoHoc" class="mr-4 mobile-f-file-upload"
					:filters="fileEx" label="Upload" :url="vueData.v_Set.apiFile" color="white"
					@input="uploadFileAnPhamMinhChungHoTroCaoHoc"></f-file-upload>
				<v-chip v-if="AnPhamObj.FileIDMinhChungHoTroCaoHoc || AnPhamObj.FileUrlMinhChungHoTroCaoHoc" label
					outlined color="deep-purple accent-4"
					:href="vueData.v_Set.urlReturnFile + AnPhamObj.FileUrlMinhChungHoTroCaoHoc" target="_blank" close
					@click:close="del_fileMinhChungHoTroCaoHoc">
					<v-icon left>mdi-file-check-outline</v-icon>
					<span style="max-width: 230px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
						{{ AnPhamObj.FileNameMinhChungHoTroCaoHoc.slice(0, AnPhamObj.FileNameMinhChungHoTroCaoHoc.length
						- 4) }}
					</span>
					<span>{{ AnPhamObj.FileNameMinhChungHoTroCaoHoc.slice(-4) }}</span>
				</v-chip>
				<v-chip v-else-if="AnPhamObj.NhomAnPham === 2" color="warning" label outlined>
					Upload file minh chứng Hỗ trợ Đầu vào Cao học (nếu có)
				</v-chip>
				<v-chip v-else-if="AnPhamObj.NhomAnPham === 3" color="warning" label outlined>
					Upload file minh chứng hướng dẫn cao học (nếu có)
				</v-chip>
			</v-col>

			<v-col cols="12" class="margin-top-mobile">
				<v-toolbar-title class="primary--text">
					Phí đăng bài của BTC/ Ban biên tập
				</v-toolbar-title>
			</v-col>

			<v-col cols="12" sm="6" md="3" class="pb-0 pt-0">
				<v-text-field class="text-input-right" v-model="phiThongBaoFormat"
					label="Phí đăng bài của BTC/ Ban biên tập" prefix="VNĐ" reverse outlined dense>
				</v-text-field>
			</v-col>

			<v-col cols="12" sm="6" md="9" class="pb-0 pt-0 d-flex" style=" gap:10px;">
				<f-file-upload v-model="ProofsObjArr" label="Upload" :filters="fileEx" :url="vueData.v_Set.apiFile"
					color="white" @input="uploadFileMinhChung"></f-file-upload>
				<span v-if="ProofsObjArr[0].FileList.length > 0" class="d-flex mt-1 " style="flex-wrap:wrap ;gap:10px">
					<v-chip close label outlined v-for="(item, index) in ProofsObjArr[0].FileList" :key="index"
						color="deep-purple accent-4" target="_blank"
						:href="vueData.v_Set.urlReturnFile + item.FileUrlMinhChung"
						@click:close="del_fileMinhChung(index)">
						<v-icon left>mdi-file-check-outline</v-icon>
						{{ item.FileNameMinhChung }}
					</v-chip>
				</span>
				<v-chip class="ml-4 mt-1" v-else color="warning" label outlined>
					Upload file minh chứng (nếu có)
				</v-chip>
			</v-col>
		</v-row>
	</v-form>
</template>

<script>
	export default {
		name: "uc-form-an-pham",
	props: {
		value: { type: Object, default: () => ({ AnPhamObj: {}, ProofsObjArr: [] }) },
		editedIndex: { type: Number, default: -1 },
		danhMucTapChiArr: { type: Array, default: () => [] },
		danhMucLoaiAnPhamArr: { type: Array, default: () => [] },
		namArr: { type: Array, default: () => [] },
		checkvalidate: { type: Boolean, default: false },
		refFormAnPham: { type: String, default: "" }
	},
	data() {
		return {
			// 1. Controls
			isPublicationTypeMenuOpen: false,

			// 2. API / Static arrays
			danhMucSubAnPhamArr: [],
			theLoaiBienSoanArr: [],
			thangArr: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
			noiDangBaiArr: ["Trong nước", "Quốc tế"],
			headersFile: [
				{ text: 'File minh chứng bài báo', sortable: false, value: "minhchungbaibao", align: "center" },
				{ text: 'File minh chứng wos(IF, Q)', sortable: false, value: "wos", align: "center" },
				{ text: 'File minh chứng Scopus', sortable: false, value: "scopus", align: "center" },
				{ text: 'File minh chứng HĐGSNN', sortable: false, value: "hdcdgsnn", align: "center" },
				{ text: 'File minh chứng tạp chí Lạc Hồng', sortable: false, value: "lacHong", align: "center" },
				{ text: 'File minh chứng khác', sortable: false, value: "minhchungkhac", align: "center" },
			],
			dsFileMinhChung: [
				{ value: 1, title: 'Upload file minh chứng bài báo' },
				{ value: 2, title: 'Upload file minh chứng wos(IF, Q)' },
				{ value: 3, title: 'Upload file minh chứng Scopus' },
				{ value: 4, title: 'Upload file minh chứng HĐGSNN' },
				{ value: 5, title: 'Upload file minh chứng tạp chí Lạc Hồng' },
				{ value: 6, title: 'Upload file minh chứng khác' }
			],
			fileEx: {
				max_file_size: '20mb',
				mime_types: [{ title: "All files", extensions: "*" }]
			},
			diemRules: [
				v => /^\d*\.?\d*$/.test(v) || 'Điểm không hợp lệ'
			],
			defaultFile: {
				LoaiFile: 2,
				FileIDList: "",
				FileList: [],
				MoTa: ""
			},

			// 3. Local state
			activeLoaiAnPham: null,
			activeLoaiSubAnPham: null,
			activeTapChi: null,
			valid: false,
			fileMinhChungId: 1,
			uploadedFileIDs: [],
			pendingDeleteFileIDs: []
		}
	},
	computed: {
		phiThongBaoFormat: {
			get() {
				return formatAsCurrency(this.AnPhamObj.PhiThongBao, 0)
			},
			set(newValue) {
				this.AnPhamObj.PhiThongBao = Number(newValue.replace(/[^0-9\.]/g, ''));
			}
		},
		phiDangBaiFormat: {
			get() {
				return formatAsCurrency(this.AnPhamObj.PhiDangBai, 0)
			},
			set(newValue) {
				this.AnPhamObj.PhiDangBai = Number(newValue.replace(/[^0-9\.]/g, ''));
			}
		},
		AnPhamObj() {
			return this.value.AnPhamObj
		},
		ProofsObjArr() {
			return this.value.ProofsObjArr
		},
		DanhMucTapChiArr() {
			return this.danhMucTapChiArr
		},
		DanhMucLoaiAnPhamArr() {
			return this.danhMucLoaiAnPhamArr
		},
		NamArr() {
			return this.namArr
		},
		selectedLoaiAnPhamText() {
			const loaiAnPham = this.DanhMucLoaiAnPhamArr.find(item =>
				item.LoaiAnPhamID === this.AnPhamObj.LoaiAnPhamID
			)
			if (!loaiAnPham) {
				return ''
			}
			const subAnPhamArr = this.getSubAnPhamArr(loaiAnPham)
			const subAnPham = subAnPhamArr.find(item =>
				item.LoaiSubAnPhamID === this.AnPhamObj.LoaiSubAnPhamID
			)
			if (subAnPham) {
				const danhMucTapChi = this.getDanhMucTapChiArr(subAnPham).find(item =>
					item.DanhMucLoaiTapChiID === this.AnPhamObj.DanhMucLoaiTapChiID
				)
				if (danhMucTapChi) {
					return loaiAnPham.TenLoaiAnPham + ' / ' + subAnPham.TenLoaiSubAnPham + ' / ' + danhMucTapChi.TenLoaiDanhMucTapChi
				}
				return loaiAnPham.TenLoaiAnPham + ' / ' + subAnPham.TenLoaiSubAnPham
			}
			return loaiAnPham.TenLoaiAnPham
		},
		activeSubAnPhamArr() {
			return this.getSubAnPhamArr(this.activeLoaiAnPham)
		},
		activeDanhMucTapChiArr() {
			return this.getDanhMucTapChiArr(this.activeLoaiSubAnPham)
		},
		publicationSubColumnStyle() {
			return this.activeDanhMucTapChiArr.length > 0
				? { flex: '2 1 0', minWidth: 0, overflowY: 'auto' }
				: { flex: '1 1 auto' }
		},
		publicationDanhMucColumnStyle() {
			return {
				flex: '1 1 0',
				minWidth: 0,
				overflowY: 'auto'
			}
		},
		isAnPhamTrongNuoc() {
			return this.activeLoaiAnPham?.TenLoaiAnPham.includes('trong nước')
		},
	},
	mounted() {
		ajaxCALL('/HDKH_DM_GetAll', {}, d => {
			const sets = Array.isArray(d.data && d.data[0]) ? d.data : [d.data || []]
			this.theLoaiBienSoanArr = [].concat(...sets).filter(x => x.DanhMucCode === 'TheLoaiBienSoan')
		}, () => { })
	},
	watch: {
		isPublicationTypeMenuOpen(val) {
			if (val) {
				this.initPublicationTypeMenu()
			}
		}
	},
	methods: {
		getSubAnPhamArr(item) {
			if (!item) {
				return []
			}
			if (Array.isArray(item.DSSubAnPham)) {
				return item.DSSubAnPham
			}
			if (!item.sub) {
				return []
			}
			return JSON.parse(item.sub)
		},
		getDanhMucTapChiArr(item) {
			if (!item) {
				return []
			}
			if (Array.isArray(item.sub)) {
				return item.sub
			}
			return []
		},
		hasSubAnPham(item) {
			return this.getSubAnPhamArr(item).length > 0
		},
		hasDanhMucTapChi(item) {
			return this.getDanhMucTapChiArr(item).length > 0
		},
		initPublicationTypeMenu() {
			const selectedLoaiAnPham = this.DanhMucLoaiAnPhamArr.find(item =>
				item.LoaiAnPhamID === this.AnPhamObj.LoaiAnPhamID
			)
			this.setActiveLoaiAnPham(selectedLoaiAnPham || this.DanhMucLoaiAnPhamArr[0])
		},
		setActiveLoaiAnPham(item) {
			if (!item) {
				this.activeLoaiAnPham = null
				this.activeLoaiSubAnPham = null
				this.activeTapChi = null
				return
			}
			this.activeLoaiAnPham = item
			const subAnPhamArr = this.getSubAnPhamArr(item)
			this.activeLoaiSubAnPham = subAnPhamArr.find(subItem =>
				subItem.LoaiSubAnPhamID === this.AnPhamObj.LoaiSubAnPhamID
			) || subAnPhamArr[0] || null
			const danhMucTapChiArr = this.getDanhMucTapChiArr(this.activeLoaiSubAnPham)
			this.activeTapChi = danhMucTapChiArr.find(danhMucItem =>
				danhMucItem.DanhMucLoaiTapChiID === this.AnPhamObj.DanhMucLoaiTapChiID
			) || danhMucTapChiArr[0] || null
		},
		setActiveLoaiSubAnPham(item) {
			this.activeLoaiSubAnPham = item
			const danhMucTapChiArr = this.getDanhMucTapChiArr(item)
			this.activeTapChi = danhMucTapChiArr.find(danhMucItem =>
				danhMucItem.DanhMucLoaiTapChiID === this.AnPhamObj.DanhMucLoaiTapChiID
			) || danhMucTapChiArr[0] || null
		},
		setActiveDanhMucTapChi(item) {
			this.activeTapChi = item
		},
		handleLoaiAnPhamClick(item) {
			if (!this.hasSubAnPham(item)) {
				this.selectLoaiAnPham(item)
			}
		},
		handleLoaiSubAnPhamClick(item) {
			if (!this.hasDanhMucTapChi(item)) {
				this.selectLoaiSubAnPham(this.activeLoaiAnPham, item)
			}
		},
		setNoiDangBaiByLoaiAnPhamID(LoaiAnPhamID) {
			if (LoaiAnPhamID === 1 || LoaiAnPhamID === 3) {
				this.AnPhamObj.NoiDangBai = this.noiDangBaiArr[0]
			} else if (LoaiAnPhamID === 2 || LoaiAnPhamID === 4) {
				this.AnPhamObj.NoiDangBai = this.noiDangBaiArr[1]
			}
		},
		resetDanhMucTapChi() {
			this.AnPhamObj.DanhMucLoaiTapChiID = null
			this.AnPhamObj.TenLoaiDanhMucTapChi = null
		},
		selectLoaiAnPham(item) {
			this.AnPhamObj.LoaiAnPhamID = item.LoaiAnPhamID
			this.AnPhamObj.TenLoaiAnPham = item.TenLoaiAnPham
			this.AnPhamObj.LoaiSubAnPhamID = null
			this.AnPhamObj.TenLoaiSubAnPham = ""
			this.danhMucSubAnPhamArr = []
			this.setNoiDangBaiByLoaiAnPhamID(item.LoaiAnPhamID)
			this.resetDanhMucTapChi()
			this.isPublicationTypeMenuOpen = false
			this.$refs.text.focus()
		},
		selectLoaiSubAnPham(item, subItem) {
			this.AnPhamObj.LoaiAnPhamID = item.LoaiAnPhamID
			this.AnPhamObj.TenLoaiAnPham = item.TenLoaiAnPham
			this.AnPhamObj.LoaiSubAnPhamID = subItem.LoaiSubAnPhamID
			this.AnPhamObj.TenLoaiSubAnPham = subItem.TenLoaiSubAnPham
			this.danhMucSubAnPhamArr = this.getSubAnPhamArr(item)
			this.setNoiDangBaiByLoaiAnPhamID(item.LoaiAnPhamID)
			this.resetDanhMucTapChi()
			this.isPublicationTypeMenuOpen = false
		},
		selectDanhMucTapChi(item, subItem, danhMucItem) {
			this.activeTapChi = danhMucItem
			this.AnPhamObj.LoaiAnPhamID = item.LoaiAnPhamID
			this.AnPhamObj.TenLoaiAnPham = item.TenLoaiAnPham
			this.AnPhamObj.LoaiSubAnPhamID = subItem.LoaiSubAnPhamID
			this.AnPhamObj.TenLoaiSubAnPham = subItem.TenLoaiSubAnPham
			this.AnPhamObj.DanhMucLoaiTapChiID = danhMucItem.DanhMucLoaiTapChiID
			this.AnPhamObj.TenLoaiDanhMucTapChi = danhMucItem.TenLoaiDanhMucTapChi
			this.danhMucSubAnPhamArr = this.getSubAnPhamArr(item)
			this.setNoiDangBaiByLoaiAnPhamID(item.LoaiAnPhamID)
			this.isPublicationTypeMenuOpen = false
		},
		uploadFileAnPham(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDAnPham = file.FILE_ID
			this.AnPhamObj.FileUrlAnPham = file.FILE_URL
			this.AnPhamObj.FileNameAnPham = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		uploadFileMinhChungWos(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungWos = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungWos = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungWos = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		uploadFileMinhChungScopus(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungScopus = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungScopus = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungScopus = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		uploadFileMinhChungHDCDGSNN(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungHDCDGSNN = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungHDCDGSNN = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungHDCDGSNN = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		uploadFileMinhChungLacHong(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungLacHong = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungLacHong = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungLacHong = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		del_fileMinhChungScopus() {
			const fileID = this.AnPhamObj.FileIDMinhChungScopus
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungScopus = null
			this.AnPhamObj.FileUrlMinhChungScopus = null
			this.AnPhamObj.FileNameMinhChungScopus = null
		},
		del_fileMinhChungHDCDGSNN() {
			const fileID = this.AnPhamObj.FileIDMinhChungHDCDGSNN
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungHDCDGSNN = null
			this.AnPhamObj.FileUrlMinhChungHDCDGSNN = null
			this.AnPhamObj.FileNameMinhChungHDCDGSNN = null
		},
		del_fileMinhChungWos() {
			const fileID = this.AnPhamObj.FileIDMinhChungWos
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungWos = null
			this.AnPhamObj.FileUrlMinhChungWos = null
			this.AnPhamObj.FileNameMinhChungWos = null
		},
		del_fileMinhChungLacHong() {
			const fileID = this.AnPhamObj.FileIDMinhChungLacHong
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungLacHong = null
			this.AnPhamObj.FileUrlMinhChungLacHong = null
			this.AnPhamObj.FileNameMinhChungLacHong = null
		},
		uploadFileAnPhamMinhChungHoTroCaoHoc(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungHoTroCaoHoc = file.FILE_ID
			this.AnPhamObj.FileNameMinhChungHoTroCaoHoc = file.FILE_NAME
			this.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = file.FILE_URL
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		uploadFileMinhChungKhac(value) {
			let file = value.Files[0]
			this.AnPhamObj.FileIDMinhChungKhac = file.FILE_ID
			this.AnPhamObj.FileUrlMinhChungKhac = file.FILE_URL
			this.AnPhamObj.FileNameMinhChungKhac = file.FILE_NAME
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		del_fileMinhChungKhac() {
			const fileID = this.AnPhamObj.FileIDMinhChungKhac
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungKhac = null
			this.AnPhamObj.FileUrlMinhChungKhac = null
			this.AnPhamObj.FileNameMinhChungKhac = null
		},
		uploadFileMinhChung(value) {
			let file = value.Files[0]
			let objfile = {
				FileIDMinhChung: file.FILE_ID,
				FileNameMinhChung: file.FILE_NAME,
				FileUrlMinhChung: file.FILE_URL
			}
			this.ProofsObjArr[0].FileList.push(objfile)
			this.uploadedFileIDs.push(file.FILE_ID)
		},
		del_fileItem() {
			const fileID = this.AnPhamObj.FileIDAnPham
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá file thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDAnPham = null
			this.AnPhamObj.FileUrlAnPham = null
			this.AnPhamObj.FileNameAnPham = null
		},
		del_fileMinhChungHoTroCaoHoc() {
			const fileID = this.AnPhamObj.FileIDMinhChungHoTroCaoHoc
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null
			this.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null
			this.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null
		},
		del_fileMinhChung(index) {
			const fileID = this.value.ProofsObjArr[0].FileList[index].FileIDMinhChung
			if (fileID) {
				if (this.uploadedFileIDs.includes(fileID)) {
					ajaxCALL('/FILE_FileDelete', { FileID: fileID }, () => {
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' })
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID)
					})
				} else {
					this.pendingDeleteFileIDs.push(fileID)
				}
			}
			this.value.ProofsObjArr[0].FileList.splice(index, 1)
		},
		resetFileStates() {
			this.uploadedFileIDs = []
			this.pendingDeleteFileIDs = []
		},
		setNullToZero() {
			if (this.AnPhamObj.HeSo_IF === null || this.AnPhamObj.HeSo_IF === "") {
				this.AnPhamObj.HeSo_IF = convertDiem(0)
			} else if (this.AnPhamObj.DiemHoiDong === null || this.AnPhamObj.DiemHoiDong === "") {
				this.AnPhamObj.DiemHoiDong = convertDiem(0)
			}
		},
		clearIF() {
			this.AnPhamObj.HeSo_IF = null
		},
		clearDiemHoiDong() {
			this.AnPhamObj.DiemHoiDong = null
		},
		getDM_By_LoaiAnPhamID() {
			this.setNoiDangBaiByLoaiAnPhamID(this.AnPhamObj.LoaiAnPhamID)
			this.AnPhamObj.LoaiSubAnPhamID = null
			this.AnPhamObj.TenLoaiSubAnPham = ""
			this.resetDanhMucTapChi()
			const loaiAnPham = this.DanhMucLoaiAnPhamArr.find(item =>
				item.LoaiAnPhamID === this.AnPhamObj.LoaiAnPhamID
			)
			this.danhMucSubAnPhamArr = this.getSubAnPhamArr(loaiAnPham)
			if (this.danhMucSubAnPhamArr.length === 0) {
				this.$refs.text.focus()
			}
		},
		getTenDMTC_By_LoaiAnPhamID() {
		},
		getDM_By_LoaiAnPhamID_Edit() {
			const loaiAnPham = this.DanhMucLoaiAnPhamArr.find(item =>
				item.LoaiAnPhamID === this.AnPhamObj.LoaiAnPhamID
			)
			this.danhMucSubAnPhamArr = this.getSubAnPhamArr(loaiAnPham)
			if (this.danhMucSubAnPhamArr.length < 2) {
				this.$refs.text.focus()
			}
		},
		getTenDMTC_By_LoaiAnPhamID_Edit() {
		},
	},
	}
</script>
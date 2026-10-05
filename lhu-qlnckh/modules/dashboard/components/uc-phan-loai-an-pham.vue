<template>
	<v-dialog v-model="value" persistent scrollable width="96vw" max-width="96vw">
		<v-card outlined class="rounded-xs">
			<v-card-title class="d-flex align-center primary white--text py-2 px-4">
				<span class="text-subtitle-1 font-weight-bold">Phân loại ấn phẩm/ bài báo ({{ year }})</span>
				<v-spacer></v-spacer>
				<v-btn icon dark small @click="onClose" title="Đóng"><v-icon>mdi-close</v-icon></v-btn>
			</v-card-title>
			<v-card-text class="pa-3 overflow-hidden">
				<v-tabs v-model="tab">
					<v-tab v-for="loai in items" :key="loai.typeID" :href="'#' + loai.typeID">
						{{ loai.title }} ({{ (loai.DSAnPham || []).length }})
					</v-tab>
				</v-tabs>
				<v-tabs-items v-model="tab">
					<v-tab-item v-for="loai in items" :key="loai.typeID" :value="loai.typeID">
						<v-card-title class="px-0 py-2 d-flex align-center">
							<v-btn @click="onOpenModalChuyen(null, 'multiple')" color="primary" rounded small
								v-if="[1, 2, 9].includes(vueData.user?.SystemRight)"
								:disabled="AnPhamSelected.length == 0">
								Chuyển nhiều <span>({{ AnPhamSelected.length }})</span>
							</v-btn>
							<v-spacer></v-spacer>
							<v-btn icon color="success" class="mr-2"
								@click="onExportExcel(loai.DSAnPham, loai.title)"
								title="Xuất file Excel">
								<v-icon>mdi-microsoft-excel</v-icon>
							</v-btn>
							<v-text-field label="Tìm kiếm..." v-model="searchText" single-line dense hide-details clearable
								prepend-inner-icon="mdi-magnify"
								class="c-underline-search dashboard-search-field"></v-text-field>
						</v-card-title>

						<v-data-table v-model="AnPhamSelected" :headers="loai.headers" :items="loai.DSAnPham"
							:search="searchText" :key="keyComp" dense fixed-header height="calc(100vh - 380px)"
							:items-per-page="50" :footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
							:show-select="[1, 2, 9].includes(vueData.user?.SystemRight)" item-key="AnPhamID">
							<template v-slot:item.TenAnPham="{ item }">
								<p class="font-weight-medium">{{ toTitleCase(item.TenAnPham) }}</p>
							</template>
							<template v-slot:item.STT="{ item }">
								<span>{{
									loai.DSAnPham.indexOf(item)
									+ 1 }}</span>
							</template>
							<template v-slot:item.TenLoaiAnPham="{ item }">
								<div class="d-flex ga-1 align-center" v-if="!item.isEditTenLoaiAnPham">
									<v-btn icon small color="success"
										v-if="[9, 1, 2].includes(vueData.user.SystemRight)"
										@click="item.isEditTenLoaiAnPham = !item.isEditTenLoaiAnPham"><v-icon
											small>mdi-square-edit-outline</v-icon>
									</v-btn>
									<div class="d-flex flex-column ga-1">
										<p class="font-weight-medium my-0">{{ item.TenLoaiAnPham }} </p>
										<span v-if="item.LoaiAnPhamID == 4" class="text-caption">({{
											item.TenLoaiSubAnPham }})</span>
									</div>


								</div>
								<div class="d-flex ga-1 align-center my-0" v-else>
									<v-text-field v-model="item.TenLoaiAnPham" dense :hide-details="true"
										outlined></v-text-field>
									<v-btn icon small color="error"
										@click="item.isEditTenLoaiAnPham = !item.isEditTenLoaiAnPham">
										<v-icon small>mdi-close</v-icon>
									</v-btn>
									<v-btn icon small color="success"
										@click="item.isEditTenLoaiAnPham = !item.isEditTenLoaiAnPham; updateItem(item)"><v-icon
											small>mdi-check</v-icon>
									</v-btn>
								</div>
							</template>
							<template v-slot:item.DiemHeSoChatLuong="{ item }">
								<div class="d-flex ga-1 align-center" v-if="!item.isEditHSCL">
									<v-btn icon small color="success" @click="item.isEditHSCL = !item.isEditHSCL"
										v-if="[9, 1, 2].includes(vueData.user.SystemRight)"><v-icon
											small>mdi-square-edit-outline</v-icon>
									</v-btn>
									<p class="font-weight-medium my-0" v-if="![15, 16].includes(item.LoaiAnPhamID)">{{
										GetQIndex_HSCL(vueData.DSHeSoChatLuong?.find(h => h.HeSoChatLuongID ==
										item.HeSoChatLuongID)?.TenHeSoChatLuong)}}
										<span v-if="item.LoaiSubAnPhamID == 12"> (Scopus)</span>
										<span v-if="item.LoaiSubAnPhamID == 59"> (WoS)</span>
									</p>
									<p class="font-weight-medium my-0" v-if="[15, 16].includes(item.LoaiAnPhamID)">{{
										GetQIndex_HSCL(vueData.DSHeSoChatLuongDacThu?.find(h => h.LoaiAnPhamID ==
										item.LoaiAnPhamID && h.LoaiSubAnPhamID ==
										item.LoaiSubAnPhamID)?.TenLoaiSubAnPham).replace("Tạp chí ", "")}}

									</p>

								</div>
								<div class="d-flex ga-1 align-center my-0" v-else>
									<v-autocomplete outlined dense v-model="item.HeSoChatLuongID"
										label="Điểm hệ số chất lượng" :items="vueData.DSHeSoChatLuong"
										item-text="DiemHeSoChatLuong" item-value="HeSoChatLuongID"
										:disabled="item.LoaiAnPhamID == 3" :hide-details="true"
										v-if="![15, 16].includes(item.LoaiAnPhamID)">
										<template v-slot:item="data">
											<template v-if="typeof data.item !== 'object'">
												<v-list-item-content v-text="data.item"></v-list-item-content>
											</template>
											<template v-else>
												<v-list-item-content>
													<v-list-item-title
														v-html="data.item.TenHeSoChatLuong"></v-list-item-title>
												</v-list-item-content>
											</template>
										</template>
									</v-autocomplete>
									<v-autocomplete outlined dense v-model="item.HeSoChatLuongID"
										label="Điểm hệ số chất lượng"
										:items="vueData.DSHeSoChatLuongDacThu.filter(i => i.LoaiAnPhamID == item.LoaiAnPhamID)"
										item-text="TenLoaiSubAnPham" item-value="LoaiSubAnPhamID"
										:disabled="item.LoaiAnPhamID == 3" :hide-details="true"
										v-if="[15, 16].includes(item.LoaiAnPhamID)">
										<template v-slot:item="data">
											<template v-if="typeof data.item !== 'object'">
												<v-list-item-content v-text="data.item"></v-list-item-content>
											</template>
											<template v-else>
												<v-list-item-content>
													<v-list-item-title
														v-html="data.item.TenLoaiSubAnPham"></v-list-item-title>
												</v-list-item-content>
											</template>
										</template>
									</v-autocomplete>
									<v-btn icon small color="error" @click="item.isEditHSCL = !item.isEditHSCL">
										<v-icon small>mdi-close</v-icon>
									</v-btn>
									<v-btn icon small color="success"
										@click="item.isEditHSCL = !item.isEditHSCL; updateItem(item)"><v-icon
											small>mdi-check</v-icon>
									</v-btn>
								</div>
							</template>

							<template v-slot:item.actions="{ item }">
								<v-btn @click="onOpenModalChuyen(item)" color="primary" rounded small>Chuyển</v-btn>
							</template>
						</v-data-table>
					</v-tab-item>
				</v-tabs-items>
			</v-card-text>
			<v-divider></v-divider>
			<v-card-actions class="px-4 py-2">
				<v-spacer></v-spacer>
				<v-btn text small color="grey darken-1" @click="onClose">Đóng</v-btn>
			</v-card-actions>
		</v-card>
		<v-dialog v-model='isShowModalChuyen' max-width="600px" v-if="isShowModalChuyen">
			<v-card>
				<v-card-title class="d-flex">
					Chuyển loại
					<v-spacer></v-spacer>
					<v-btn variant="text" icon @click="onCloseChuyen">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="pt-3">
					<v-row>
						<v-col v-if="!isMoveMutiple">
							<b>Tên bài báo/ ấn phẩm: </b>
							<span>{{ ItemSelected.TenAnPham }}</span>
						</v-col>
						<v-col cols="12">
							<v-select v-model="Loai" label="Loại" :items="items" item-text="title" item-value="typeID"
								outlined dense :hide-details="true"></v-select>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn text color="primary" small @click="updateItem(ItemSelected, 1)" :loading="isLoading">Xác
						nhận</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-dialog>
</template>

<script>
	export default {
		props: ["value", "year", "initialTab"],
		emits: ["update:isOpen"],
		data() {
			return {
				keyComp: 1,
				tab: this.initialTab || '1',
				vueData,
				searchText: '',
				Loai: null,
				items: [
					{
						title: 'Wos/Scopus',
						typeID: '1',
						DSAnPham: this.initEditFlag(vueData.SoBaiDangQT[this.year]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px",
							},
							{
								text: 'ISSN',
								value: "ISSN",
								sortable: false,
								width: "150px",
							},
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'HSCL',
								value: "DiemHeSoChatLuong",
								sortable: false
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					},
					{
						title: 'Hội đồng Giáo sư nhà nước',
						typeID: '2',
						DSAnPham: this.initEditFlag(vueData.SoBaiDangHDGSNN[this.year]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Điểm HĐGSNN',
								value: "DiemHoiDong",
								sortable: false
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					},
					{
						title: 'Hội thảo',
						typeID: '3',
						DSAnPham: this.initEditFlag([...vueData.SoBaiDangKYHT[this.year]]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px"
							},
							{
								text: 'ISSN',
								value: "ISSN",
								width: "150px",
								sortable: false
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					},
					{
						title: 'Sách',
						typeID: '5',
						DSAnPham: this.initEditFlag(vueData.SoBaiDangSach[this.year]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
	
	
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px"
							},
							{
								text: 'ISSN',
								value: "ISSN",
								sortable: false,
								width: "150px"
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					},
					{
						title: 'Tạp chí khoa học Lạc Hồng (HĐGSNN)',
						typeID: '6',
						DSAnPham: this.initEditFlag(vueData.SoBaiDangTapChiKHLH_GSNN[this.year]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
	
	
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px"
							},
							{
								text: 'ISSN',
								value: "ISSN",
								sortable: false,
								width: "150px"
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					},
					{
						title: 'Tạp chí khoa học Lạc Hồng (Khác)',
						typeID: '4',
						DSAnPham: this.initEditFlag(vueData.SoBaiDangTCLH[this.year]),
						headers: [
							{
								text: 'STT',
								value: "STT",
								width: "50px",
								align: 'center',
								sortable: false
							},
							{
								text: 'Tác giả',
								value: "TacGia",
								width: "300px",
								sortable: false
							},
							{
								text: 'Tên ấn phẩm/ bài báo',
								value: "TenAnPham",
								sortable: false
							},
	
	
							{
								text: 'Danh mục bài báo/ ấn phẩm',
								value: "TenLoaiAnPham",
								sortable: false,
								width: "300px"
							},
							{
								text: 'Tên tạp chí',
								value: "TenTapChi",
								sortable: false,
								width: "300px"
							},
							{
								text: 'ISSN',
								value: "ISSN",
								sortable: false,
								width: "150px"
							},
							{
								text: 'Thao tác',
								value: "actions",
								sortable: false
							},
						],
					}
				],
				isShowModalChuyen: false,
				ItemSelected: {},
				rules: {
	
				},
				AnPhamSelected: [],
				isMoveMutiple: false,
				isLoading: false
			}
		},
		mounted() {
			if (![9, 1, 2].includes(vueData.user.SystemRight)) {
				this.items.forEach(loai => {
					loai.headers.splice(1, 1)
				})
	
				this.items = this.items.map(i => {
					i.headers = i.headers.filter(h => h.value != "actions")
					return i
				})
			}
	
		},
		computed: {
		},
		watch: {
			initialTab: {
				immediate: true,
				handler(val) {
					if (val) {
						this.tab = String(val)
					}
				}
			},
			value(val) {
				if (val && this.initialTab) {
					this.tab = String(this.initialTab)
				}
			},
			tab: function (val) {
				if (val) {
					this.AnPhamSelected = []
				}
				console.log('tab', val)
			},
			'vueData.keyComp': function (val) {
				if (val) {
					console.log('keyComp', val)
					this.items = this.items.map(item => {
						switch (item.typeID) {
							case '1':
								item.DSAnPham = this.initEditFlag(vueData.SoBaiDangQT[this.year])
								break;
							case '2':
								item.DSAnPham = this.initEditFlag(vueData.SoBaiDangHDGSNN[this.year])
								break;
							case '3':
								item.DSAnPham = this.initEditFlag([...vueData.SoBaiDangKYHT[this.year]])
								break;
							case '4':
								item.DSAnPham = this.initEditFlag(vueData.SoBaiDangTCLH[this.year])
								break;
							case '5':
								item.DSAnPham = this.initEditFlag(vueData.SoBaiDangSach[this.year])
								break;
							case '6':
								item.DSAnPham = this.initEditFlag(vueData.SoBaiDangTapChiKHLH_GSNN[this.year])
								break;
						}
						return item
					})
				}
			},
			AnPhamSelected: function (val) {
				console.log('val', val)
			},
		},
		methods: {
			onExportExcel(data, title) {
				jsonToExcel({
					data: data || [],
					filename: (title || "Danh-sach") + ".xlsx"
				})
			},
			onClose() {
				this.$emit("input", false)
			},
			onCloseChuyen() {
				this.isShowModalChuyen = false
				this.isMoveMutiple = false
			},
			onOpenModalChuyen(item, type) {
				if (type == 'multiple') {
					this.isMoveMutiple = true
					console.log('multiple')
				} else {
					console.log('single')
					this.ItemSelected = Object.assign({}, item)
				}
	
				this.isShowModalChuyen = true
			},
			initEditFlag(array) {
				if (!array || !Array.isArray(array)) return []
				return array.map(item => ({
					...item,
					isEditTenLoaiAnPham: false,
					isEditHSCL: false   // thêm thuộc tính reactive
				}))
			},
			async updateItem(item, isMove = 0) {
				if (![1, 2, 9].includes(vueData.user.SystemRight)) return
				let GroupAnPham_Edit = null
				if (isMove == 1) {
					item.GroupAnPham_Edit = this.Loai ?? item.GroupAnPham_Edit
					GroupAnPham_Edit = this.Loai ?? item.GroupAnPham_Edit
				}
	
				if (this.isMoveMutiple) {
					this.isLoading = true
					// 👉 trường hợp này cần xử lý async/await thực sự
					for (const ap of this.AnPhamSelected) {
						const params = {
							AnPhamID: ap.AnPhamID,
							TenLoaiAnPham_Edit: ap.TenLoaiAnPham,
							GroupAnPham_Edit: parseInt(GroupAnPham_Edit),
							HeSoChatLuongID_Edit: ap.HeSoChatLuongID,
							DiemHeSoChatLuong_Edit: ap.DiemHeSoChatLuong ?? -1,
						}
	
						await this.API_RPT_AnPham_NamDang_Dashboard_Update(params)
	
					}
	
					Vue.$toast.success("Cập nhật thành công!", { position: "top" })
					await this.Reload_CALL()
					this.isLoading = false
					this.keyComp++
					this.isShowModalChuyen = false
					this.Loai = null
					this.isMoveMutiple = false
					this.AnPhamSelected = []
				} else {
					this.isLoading = true
					const params = {
						AnPhamID: item.AnPhamID,
						TenLoaiAnPham_Edit: item.TenLoaiAnPham,
						GroupAnPham_Edit: parseInt(item.GroupAnPham_Edit),
						HeSoChatLuongID_Edit: item.HeSoChatLuongID,
						DiemHeSoChatLuong_Edit: item.DiemHeSoChatLuong ?? -1,
					}
	
					await this.API_RPT_AnPham_NamDang_Dashboard_Update(params)
	
					Vue.$toast.success("Cập nhật thành công!", { position: "top" })
					await this.Reload_CALL()
					this.isLoading = false
					this.keyComp++
					this.isShowModalChuyen = false
					this.Loai = null
	
				}
	
			},
			toTitleCase(text) {
				if (!text) return text;
				return text.toLowerCase().replace(/^\w/, c => c.toUpperCase());
			},
			GetQIndex_HSCL(val) {
				if (val == null) return val;
				let split = String(val).split(':')
				return split[0] ?? val
			},
			async API_RPT_AnPham_NamDang_Dashboard_Update(params) {
				return await new Promise(resolve => {
					ajaxCALL('/RPT_AnPham_NamDang_Dashboard_Update', params, res => {
						resolve(res)
					})
				})
			},
			async Reload_CALL() {
				this.$emit('reload')
				if (typeof vueData.reloadAnPhamNamDang === 'function') {
					await vueData.reloadAnPhamNamDang()
				}
				return 1
			}
		},
	}
</script>
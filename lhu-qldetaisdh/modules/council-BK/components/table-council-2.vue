<template>
	<div>
		<v-tabs :value="vueData.activeCouncilType - 1" @change="val => vueData.activeCouncilType = val + 1" color="primary" class="mb-4">
			<v-tab>Bảo vệ chuyên đề</v-tab>
			<v-tab>Bảo vệ luận án ĐVCM</v-tab>
			<v-tab>Bảo vệ luận án cấp trường</v-tab>
		</v-tabs>

		<!-- Add council -->
		<!-- khi them hoi dong thanh cong thi disable nut them moi hoi dong -->
		<dialog-add-council :active-council-type="vueData.activeCouncilType" :council-config="vueData.COUNCIL_CONFIG" :editedItem="editedItem" :dshoidonggiangvien="DSHoiDongGiangVien"
			:dshdchuctrach="DSHoiDongChucTrach" :dshedaotao="dshedaotao" :hearr="hearr"> </dialog-add-council>

		<!-- give SQD -->
		<dialog-give-sqd :isqsddialog="vueData.isSQDDialog" :thongtinhocvien="dataUpdateHD.HoiDong"
			:editedItem="editedItem" :dsgiangvien="dataUpdateHD.GiangVienSelected" />

		<!-- update council -->
		<dialog-update-council :active-council-type="vueData.activeCouncilType" :council-config="vueData.COUNCIL_CONFIG" :editedItem="editedItem" :dshoidonggiangvien="dataUpdateHD.GiangVienSelected"
			:thongtinhocvien="dataUpdateHD.HoiDong" :dshedaotao="dshedaotao" :hearr="hearr"></dialog-update-council>
		<!-- view council -->
		<dialog-view-council :editedItem="editedItem"
			:dshoidonggiangvien="dataUpdateHD.GiangVienMergeSelected"></dialog-view-council>
		<!-- temp council -->
		<dialog-council-temp :editedItem="editedItem" :dshoidonggiangvien="DSHDGiangVienEstablishCouncil"
			:dsgiangviendukien="DSGiangVienDuKien" :dsgiangviendukiendefault="DSGiangVienDuKienDefault"
			:dshdchuctrach="DSHoiDongChucTrach" :dsdetai="DSDeTaiCoHoiDong" :hearr="hearr" />
		<!-- input score -->
		<dialog-input-score :getdiem="getDiem" :editedItem="editedItem"
			:dshoidonggiangvien="dataUpdateHD.GiangVienSelected" />
		<!-- Major filter -->
		<v-row class="mb-3">
			<v-col cols="2">
				<v-select v-model="type" label="Chọn theo hệ đào tạo" outlined dense :items="dshedaotao"
					item-text="VALUE" item-value="KEY" hide-details />
			</v-col>
			<v-col cols="3">
				<v-select v-model="major" :items="heArr" outlined dense hide-details label="Lọc theo ngành"
					item-text="Ten_Nganh_HienThi" item-value="Nganh_ID" />
			</v-col>
			<v-col class="d-flex justify-content-end">
				<v-btn class="ml-auto mb-3" color="primary" @click="fn_EstablishCouncil">Lập nhiều danh sách hội
					đồng</v-btn>
			</v-col>
		</v-row>
		<!-- <v-btn @click="clearAllData">Clear all data</v-btn> -->
		<div>
			<c-table isSearch label="Danh sách {{ vueData.COUNCIL_CONFIG[vueData.activeCouncilType].name }}" :headers="headerCTable"
				:items="dsDeTai" isNew="false" isEdit="false">
				<template v-slot:item.Student_ID="{item}">
					<span class='green--text'>
						<b> {{item.Ho_SV}} {{ item.Ten_SV}}</b>
					</span>
					<br />
					<b>{{item.Student_ID}}</b>
					<span class='amber--text'> [{{item.Lop_ID}}]</span>
				</template>
				<template v-slot:item.Thesises_Prof1="{item}">
					<span>
						{{item.Thesises_Prof1}}</br>{{item.Thesises_Prof2}}
					</span>
				</template>
				<template v-slot:item.ThaoTacHoiDongBTN="{item}">
					<div class="d-flex">
						<v-btn v-if="!item.HoiDongID" text @click='addCouncil(item)'
							class='ml-5 theme--light v-size--default pink--text'>
							Lập Hội Đồng
						</v-btn>
						<v-btn v-else-if="item.HoiDongID && !item.Decision_SoQD" text @click='onUpdateHoiDong(item)'
							class='ml-5 theme--light v-size--default cyan--text'>
							Xem & Cập nhật
						</v-btn>
						<v-btn v-else text @click='onViewHoiDong(item)'
							class='ml-5 theme--light v-size--default success--text'>
							Xem Hội Đồng
						</v-btn>

					</div>
				</template>
				<template v-slot:item.ThaoTacSQDBTN="{item}">
					<v-btn text @click='giveSQD(item)'
						v-bind:class="{'success--text': item.Decision_SoQD, 'purple--text': !item.Decision_SoQD}"
						class='v-btn theme--light v-size--default purple--text'
						:disabled="sqdCheckStatus(item.HoiDongID)">
						{{item.Decision_SoQD ? item.Decision_SoQD : 'Cập nhật'}}
					</v-btn>
				</template>
				<template v-slot:item.InputScore="{item}">
					<v-btn @click="onInputScore(item)" text class='v-btn theme--light v-size--default teal--text'
						:disabled="sqdCheckStatus(item.HoiDongID)">
						Nhập điểm
					</v-btn>
				</template>
				<template v-slot:item.ThaoTacInQDBTN="{item}">
					<v-icon class="mr-5" @click='printQD_LV_Ths(item.HoiDongID)' color='success'
						:disabled="sqdCheckStatus(item.HoiDongID)"> mdi-printer</v-icon>
				</template>
			</c-table>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["dshdgiangvien", "dshdchuctrach", "dshddetai", "dshedaotao", "hearr"],
		data() {
			return {
				type: null,
				major: "",
				heArr: [],
				getDiem: [],
				headerCTable: [
					{
						text: "STT",
						value: "STT",
						sortable: false,
						align: "center"
					},
					{
						text: "Học viên",
						value: "Student_ID",
					},
					{
						text: "Ngành",
						value: "Ten_Nganh"
					},
					{
						text: "Tên đề tài",
						value: "Thesis_Name",
					},
					{
						text: "Hướng dẫn Khoa học",
						value: "Thesises_Prof1",
						class: "customCol"
					},
					{
						text: "Hội đồng",
						value: "ThaoTacHoiDongBTN",
						align: "center",
						attr: {
							margin: "200px"
						}
	
					},
					{
						text: "Số quyết định",
						value: "ThaoTacSQDBTN",
						sortable: false,
						align: "center",
					},
					{
						text: "Nhập điểm",
						value: "InputScore",
						sortable: false,
						align: "center",
					},
					{
						text: "In QĐ",
						value: "ThaoTacInQDBTN",
						class: "printerCol",
						align: "center"
					},
				],
				editedItem: {},
				dataUpdateHD: {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				},
				DSHDGiangVienEstablishCouncil: [],
				DSGiangVienDuKien: [],
				DSGiangVienDuKienDefault: [],
				DSDeTaiCoHoiDong: [],
	
			}
		},
		computed: {
			dsDeTai: function () {
				return this.dshddetai
			},
			DSHoiDongGiangVien: function () {
				return this.dshdgiangvien
			},
			DSHoiDongChucTrach: function () {
				return this.dshdchuctrach
			},
			DSGiangVienDuKienTemp: function () {
				let tempHDGV = this.DSHoiDongGiangVien
				let arrPush = []
				this.DSHDGiangVienEstablishCouncil = tempHDGV.map((item) => {
					return {
						...item,
						Is_Chon: false,
						Is_Selected: false,
						HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
					}
				})
	
				this.DSHDGiangVienEstablishCouncil.forEach(giangVien => {
					const existIndex = this.dsDeTai.findIndex(deTai => deTai.GiangVienID1 === giangVien.GiangVienID);
					// console.log("!this.isGiangVienInSuggestList(giangVien)", !this.isGiangVienInSuggestList(giangVien))
					if (existIndex !== -1) {
						this.DSGiangVienDuKien.push({ ...giangVien, Is_Chon: true });
					}
				});
	
				this.DSGiangVienDuKienDefault = this.DSGiangVienDuKien
				console.log("DSGiangVienDuKien", this.DSGiangVienDuKien)
				return arrPush
			}
	
		},
		watch: {
			"type": function (val) {
				this.getHeByID(val)
			},
			"major": function (val) {
				vueData.nganhID = parseInt(val)
			}
		},
		methods: {
			addCouncil(item) {
				this.editedItem = item
				vueData.isAddDialog = true
			},
			onUpdateHoiDong(item) {
				this.editedItem = item
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				}
				ajaxCALL("/HoiDong_Get_ByHoiDongID", {
					HoiDong_ID: item.HoiDongID
				},
					(res) => {
						let hoidong = res.data[0][0]
						let gvSelected = res.data[1]
	
						this.dataUpdateHD.HoiDong = hoidong
						this.dataUpdateHD.GiangVienSelected = gvSelected
	
						let tempArr = JSON.parse(JSON.stringify(this.DSHoiDongGiangVien.filter((itemGV) => itemGV.NganhID === item.Nganh_ID)))
	
						let resultArr = tempArr.map((item, index) => {
							let matchingElement = gvSelected.find(element => element.GiangVienID === item.GiangVienID);
							if (matchingElement) {
								matchingElement.Is_Chon = matchingElement.Is_Chon === 0 ? false : true
								matchingElement.STT = index + 1
								return Object.assign({}, item, matchingElement)
							} else {
								// item.Is_Chon = false
								item.STT = index + 1
								return item;
							}
						});
						console.log("vueData.DSHoiDongGiangVien", tempArr.filter(item => item.Is_Chon))
						console.log("resultArr", resultArr.filter(item => item.Is_Chon))
						this.dataUpdateHD.GiangVienMergeSelected = resultArr
	
						vueData.isUpdateDialog = true
					},
					(error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					})
				console.log(item)
			},
			onViewHoiDong(item) {
				this.editedItem = item
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				}
				ajaxCALL("/HoiDong_Get_ByHoiDongID", {
					HoiDong_ID: item.HoiDongID
				}, (res) => {
					let hoidong = res.data[0][0]
					let gvSelected = res.data[1].map((item) => {
						return {
							...item,
							HoTenHocHamHocVi: item.HocViHocHam + ". " + item.HoTenGiangVien
						}
					})
					let dshdgv = this.DSHoiDongGiangVien
	
					this.dataUpdateHD.HoiDong = hoidong
					this.dataUpdateHD.GiangVienSelected = gvSelected
	
					let resultArr = gvSelected.map(item => ({ ...item, Is_Chon: true }))
					this.dataUpdateHD.GiangVienMergeSelected = resultArr
					vueData.isViewDialog = true
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
				})
			},
			onInputScore(item) {
	
				let flag_1 = false
				let flag_2 = false
	
				this.editedItem = item
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				}
	
				ajaxCALL("/HoiDong_Get_ByHoiDongID", {
					HoiDong_ID: item.HoiDongID
				}, (res) => {
					let hoidong = res.data[0][0]
					let gvSelected = res.data[1].map((item) => {
						return {
							...item,
							HoTenHocHamHocVi: item.HocViHocHam + ". " + item.HoTenGiangVien
						}
					})
					let dshdgv = this.DSHoiDongGiangVien
	
					this.dataUpdateHD.HoiDong = hoidong
					this.dataUpdateHD.GiangVienSelected = gvSelected
	
					let resultArr = gvSelected.map(item => ({ ...item, Is_Chon: true }))
					this.dataUpdateHD.GiangVienMergeSelected = resultArr
					flag_1 = true
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
				})
	
				ajaxCALL("/HoiDong_GiangVien_Get_Diem", {
					HoiDongID: this.editedItem.HoiDongID
				}, (res) => {
					this.getDiem = res.data;
					console.log("arr", this.getDiem);
					vueData.isInputDialog = true
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("error", error);
				});
	
				if (flag_1 && flag_2) {
	
				}
			},
			giveSQD(item) {
				this.editedItem = item
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				}
				console.log("edit item", item)
				ajaxCALL("/HoiDong_Get_ByHoiDongID", {
					HoiDong_ID: item.HoiDongID
				}, (res) => {
					let hoidong = res.data[0][0]
					let gvSelected = res.data[1].map((item) => {
						return {
							...item,
							HoTenHocHamHocVi: item.HocViHocHam + ". " + item.HoTenGiangVien
						}
					})
	
					this.dataUpdateHD.HoiDong = hoidong
					this.dataUpdateHD.GiangVienSelected = gvSelected
					console.log("this.dataUpdateHD.HoiDong", this.dataUpdateHD.HoiDong)
					vueData.isSQDDialog = true
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to get data update hoi dong", error)
				})
			},
			getHeByID(heID) {
				ajaxCALL("/Nganh_Get_ByHeID", {
					HeID: heID
				}, (res) => {
					this.heArr = res.data
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to get he dao tao", error)
				})
			},
			clearAllData() {
				ajaxCALL("/HoiDong_ClearData", null,
					(res) => {
						console.log("Clear success")
						CALL('getHoiDongDeTai')
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("Fail to get he dao tao", error)
					})
			},
			fn_EstablishCouncil() {
				this.DSGiangVienDuKien = this.DSGiangVienDuKienTemp
				this.DSGiangVienDuKienDefault = this.DSGiangVienDuKienTemp
				this.DSDeTaiCoHoiDong = this.dsDeTai.filter(item => item.HoiDongID === null)
					.map((item, index) => {
						return {
							...item,
							STT: index + 1, // Cập nhật STT dựa trên index
							GiangVienObj: [],
						};
					});
				console.log("DSGiangVienDuKienDefault", this.DSGiangVienDuKien)
				console.log("this.DSDeTaiCoHoiDong", this.DSDeTaiCoHoiDong)
				vueData.isTempDialog = true
			}
		},
	}
</script>
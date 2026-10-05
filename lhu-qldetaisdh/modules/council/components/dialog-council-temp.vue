<template>
	<div>
		<v-dialog persistent eager v-model="vueData.isTempDialog" transition="dialog-bottom-transition"
			max-width="1680px">
			<v-card>
				<c-toolbar @onClose="vueData.isTempDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Lập nhiều danh sách hội đồng</p>
					</template>
				</c-toolbar>
				<v-card-text class="mt-3">
					<v-row class="pb-0">
						<v-col cols="3" class="pb-0">
							<v-select v-model="nganhID" :items="heArr" outlined dense hide-details
								label="Lọc theo ngành" item-text="Ten_Nganh" item-value="Nganh_ID"></v-select>
						</v-col>
					</v-row>
					<v-row>
						<v-col cols="4">
							<c-table label="Giảng viên" :items="dshoidonggiangvien" :headers="headerTempList"
								isNew="false" isEdit="false" height="200" isSearch fixed-header items-per-page="-1"
								hide-default-footer dense="true">
								<template v-slot:item.btn="{ item }">
									<v-btn text @click="addGiangVien(item)" color="success">
										<v-icon size="20">mdi-plus</v-icon>
									</v-btn>
								</template>
							</c-table>
						</v-col>
						<v-col cols="8">
							<c-table label="Giảng viên dự kiến" :items="DSGiangVienDuKien" :headers="headerSuggestList"
								isNew="false" isEdit="false" height="200" fixed-header items-per-page="-1" isSearch
								hide-default-footer>
								<template v-slot:item.count="{ item, index }">
									{{ index + 1 }}
								</template>
								<template v-slot:item.btnDelete="{ item }">
									<v-btn @click="deleteGiangVien(item)" text color="error">
										<v-icon size="20">mdi-trash-can-outline</v-icon>
									</v-btn>
								</template>
							</c-table>
						</v-col>
					</v-row>

					<v-row>
						<v-col>
							<v-card>
								<v-card-title style="display: flex; align-items: center">
									<span class="primary--text">Dự kiến phân bổ hội đồng</span>
								</v-card-title>
								<v-card-text>
									<v-simple-table>
										<thead>
											<tr>
												<th class="text-center">STT</th>
												<th class="SmallerRenderCol">Học viên</th>
												<th class="renderCol">Tên đề tài</th>
												<th class="renderCol">Hướng dẫn khoa học</th>
												<th class="renderCol text-center" v-for="(item, index) in dshdchuctrach"
													:key="index">
													{{item.ChucTrach}}
												</th>
												<th class="SmallerRenderCol text-center">Tạm xóa đề tài</th>
											</tr>
										</thead>
										<tbody v-if="dsdetai.length > 0">
											<tr :style="{ backgroundColor: item.Validate_Exist ? 'pink' : ''}"
												v-for="(item, index) in dsdetai" :key="'row_' + index">
												<td>{{index + 1}}</td>
												<td>
													<span class='green--text'>
														<b> {{item.Ho_SV}} {{ item.Ten_SV}}</b>
													</span>
													<br />
													<b>{{item.Student_ID}}</b>
													<span class='amber--text'> [{{item.Lop_ID}}]</span>
												</td>
												<td>{{item.Thesis_Name}}</td>
												<td>{{item.Thesises_Prof1}}</td>
												<td v-for="(itemCT) in item.DeTai_DSChucTrach" class="renderCol">
													<!-- {{itemCT}} -->
													<v-autocomplete :items="DSGiangVienDuKien" outlined dense
														hide-details placeholder="Chọn giảng viên" :item-text="getName"
														item-value="GiangVienID" v-model="itemCT.GiangVienID"
														:no-data-text="'Chưa có dữ liệu từ ngành học'"
														:class="{ 'white-text': item.Validate_Exist }" />
												</td>
												<td class="text-center">
													<v-btn @click="deleteDeTai(index)" text color="error">
														<v-icon size="20">mdi-trash-can-outline</v-icon>
													</v-btn>
												</td>
											</tr>
										</tbody>
										<tbody v-else>
											<tr class="v-data-table__empty-wrapper">
												<td colspan="12">Không có đề tài</td>
											</tr>
										</tbody>
									</v-simple-table>
									<!-- <v-pagination v-model="currentPage" :length="totalPages" @input="changePage">
									</v-pagination> -->
								</v-card-text>
							</v-card>
						</v-col>
					</v-row>
					<v-row>
						<V-col>
							<v-card-actions>
								<v-spacer></v-spacer>
								<div class="datePicker mr-3">
									<f-date v-model="councilTime" color="success" label="Ngày bảo vệ luận văn"
										placeholder="Ngày bảo vệ luận văn" outlined dense hide-details />
								</div>
								<v-btn :disabled="dsdetai.length == 0" color="primary" dark @click="addCouncil">Lập hội
									đồng</v-btn>
							</v-card-actions>
						</V-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["dshoidonggiangvien", "dsdetai", "hearr", "dshdchuctrach", "dsgiangviendukien", "dsgiangviendukiendefault"],
		data() {
			return {
				nganhID: null,
				selectedGiangVien: [],
				dsSelected: [],
				listTemp: [],
				temp: [],
				countNumber: 1,
				dsDeTaiTemp: this.dsdetai,
				itemsPerPage: 10,
				currentPage: 1,
				originalData: null,
				DSDeTai: this.dsdetai,
				DSGiangVienDuKien: this.dsgiangviendukien,
				DSGiangVienDuKienDefault: this.dsgiangviendukiendefault,
				councilTime: "",
				search: "",
				headerTempList: [
					{
						text: "STT",
						value: "STT",
						sortable: false,
						align: "center"
					},
					{
						text: "Họ tên giảng viên",
						value: "HoTenHocHamHocVi"
					},
					{
						text: "Thêm giảng viên",
						value: "btn",
						sortable: false,
						align: "center"
					},
				],
				headerSuggestList: [
					{
						text: "STT",
						value: "count",
						sortable: false,
						align: "center"
					},
					{
						text: "Họ tên giảng viên",
						value: "HoTenHocHamHocVi"
					},
					{
						text: "Ngành giảng dạy",
						value: "NganhGiangDay"
					},
					{
						text: "Cơ quan công tác",
						value: "CoQuanCongTac"
					},
					{
						text: "Xóa giảng viên",
						value: "btnDelete",
						sortable: false,
						align: "center"
					}
				],
				headerTable: [
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
						text: "Tên đề tài",
						value: "Thesis_Name",
						width: "180"
					},
					{
						text: "Hướng dẫn Khoa học",
						value: "Thesises_Prof1",
						width: "120"
					},
					{
						text: "Chủ tịch",
						sortable: false,
						align: "center",
						value: "ChuTich",
						width: "210"
					},
					{
						text: "Phản biện 1",
						sortable: false,
						align: "center",
						value: "PhanBien1",
						width: "210"
					},
					{
						text: "Phản biện 2",
						sortable: false,
						align: "center",
						value: "PhanBien2",
						width: "210"
					},
					{
						text: "Ủy viên",
						sortable: false,
						align: "center",
						value: "UyVien",
						width: "210"
					},
					{
						text: "Thư ký",
						sortable: false,
						align: "center",
						value: "ThuKy",
						width: "210"
					}
				]
			}
		},
		computed: {
			totalPages() {
				return Math.ceil(this.dsdetai.length / this.itemsPerPage);
			},
			DSHoiDongGiangVien: function () {
				return this.dshoidonggiangvien
			},
			heArr: function () {
				return this.hearr
			},
			footerProps() {
				// Tính toán các tùy chọn, đảm bảo -1 được chọn đầu tiên
				const options = [-1, 5, 10, 20]; // -1 đầu tiên, sau đó các tùy chọn khác
				return { 'items-per-page-options': options };
			},
			IsTempDialog: function () {
				return vueData.isTempDialog
			}
		},
		watch: {
			nganhID(newVal) {
				this.getGiangVien(newVal)
			},
			IsTempDialog: function(val){
				if(val){
					console.log("dsdetai", this.dsdetai)
				}
			}
		},
		methods: {
			changePage(page) {
				this.currentPage = page;
			},
			removeDiacriticsAndSpaces(str) {
				// Xóa dấu
				const removedDiacritics = str.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
				// Xóa khoảng trắng
				const removedSpaces = removedDiacritics.replace(/\s/g, '');
	
				return removedSpaces;
			},
			getGiangVien(val) {
				ajaxCALL("/HoiDong_GiangVien_Get", {
					NganhID: parseInt(val),
				}, (res) => {
					// this.DSGiangVien = res.data
					this.dshoidonggiangvien = res.data.map((item) => {
						return {
							...item,
							Is_Chon: false,
							HoTenHocHamHocVi: item.HocViHocHam + '. ' + item.HoTenGiangVien,
						}
					})
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail to get DSGiangVien", error)
				})
			},
			/** Thêm giảng viên vào danh sách giảng viên dự kiến */
			addGiangVien(item) {
				//Kiểm tra giảng viên thêm vào có tồn tại trong suggestList
				const giangvienDuplicate = this.DSGiangVienDuKien.find(giangvien => item.GiangVienID === giangvien.GiangVienID)
				if (!giangvienDuplicate) {
					this.DSGiangVienDuKien.push(item)
					this.DSGiangVienDuKien.sort((a, b) => a.STT - b.STT);
				}
				else Vue.$toast.error(`Đã tồn tại giảng viên ${giangvienDuplicate.HoTenGiangVien} trong danh sách giảng viên dự kiến`, { position: 'top' });
			},
			deleteGiangVien(item) {
				const index = this.DSGiangVienDuKien.indexOf(item);
				if (index !== -1) {
					this.DSGiangVienDuKien.splice(index, 1);
					this.DSGiangVienDuKien.sort((a, b) => a.STT - b.STT);
				}
			},
			addCouncil() {
				const $this = this;
				let check = true
	
				const detaiFilter = this.dsdetai.filter(item => {
					// Kiểm tra nếu tất cả các GiangVienID đều khác null
					return item.DeTai_DSChucTrach.every(chucTrach => chucTrach.GiangVienID !== null);
				});
				console.log("this.dsdetai", this.dsdetai)
	
				const uploadPromises = detaiFilter.map((itemDetai, index) => {
					if (itemDetai.DeTai_DSChucTrach.length !== 0) {
						if ($this.councilTime !== "") {
							console.log("itemDetai", itemDetai.DeTai_DSChucTrach)
	
							console.log("itemDetai", itemDetai)
							let ctrach = $this.DSGiangVienDuKien.map(chucTrach => {
								const info = itemDetai.DeTai_DSChucTrach.find(item => item.GiangVienID === chucTrach.GiangVienID);
								return {
									...chucTrach,
									ChucTrach: info ? info.ChucTrach : null,
									value: info ? info.value : null
								};
							});
							ctrach = ctrach.filter(item => item.ChucTrach !== null)
							console.log("$this.DSHoiDongGiangVien", $this.DSHoiDongGiangVien)
							// console.log("ctrach", ctrach)
	
							const selectGVHD = ctrach.find(item => item.GiangVienID === itemDetai.GiangVienID1)
	
							if (selectGVHD) {
								Vue.$toast.error(`Không được chọn GVHD làm thành viên làm thành viên hội đồng của HV ${itemDetai.Ho_SV} ${itemDetai.Ten_SV}`, { position: 'top' });
								itemDetai.Validate_Exist = true
								console.log("itemDetai.Validate_Exist", itemDetai.Validate_Exist)
								return Promise.reject();
							}
							else {
								if (ctrach.length < $this.dshdchuctrach.length) {
									console.log("ctrach xxxx", $this.DSHoiDongGiangVien)
									Vue.$toast.error(`Hội đồng của HV ${itemDetai.Ho_SV} ${itemDetai.Ten_SV} bị trùng hoặc chưa đủ thành viên`, { position: 'top' });
									itemDetai.Validate_Exist = true
									return Promise.reject();
								}
								else {
									console.log("itemDetai xxxxx", itemDetai)
									console.log("ctrach", ctrach)
									itemDetai.Validate_Exist = false
	
									// return ajaxCALL("/HoiDong_Ins", {
									// 	Student_ID: itemDetai.Student_ID,
									// 	HoiDongThanhVienObj_Arr: ctrach,
									// 	ThoiGianBaoVe: $this.councilTime,
									// }, (res) => {
									// 	console.log("itemDetai", itemDetai);
									// 	// $this.DSGiangVienDuKien = $this.DSGiangVienDuKienDefault;
	
									// 	//Sau khi call api ins thành công, gọi hàm deleteDeTai để delete đề tài luôn
									// 	this.deleteDeTai(index)
	
									// 	console.log("$this.DSGiangVienDuKienDefault", $this.DSGiangVienDuKienDefault)
									// }, (error) => {
									// 	Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
									// 	return Promise.reject(); // Reject promise when there is an error
									// });
	
								}
							}
						} else {
							Vue.$toast.error(`Chưa thêm Thời gian bảo vệ`, { position: 'top' });
							return Promise.reject(); // Reject promise when there is an error
						}
					} else {
						// Return a resolved promise for items with no council members
						return Promise.resolve();
					}
				});
	
				Promise.allSettled(uploadPromises).then((results) => {
					const isAllResolved = results.every(result => result.status === 'fulfilled');
	
					if (isAllResolved) {
						// $this.DSGiangVienDuKien = [];
						Vue.$toast.success(`Thêm thành công`, { position: 'top' });
						vueData.isTempDialog = false;
						CALL('getHoiDongDeTai');
					} else {
						console.log("$this.DSGiangVienDuKienDefault", $this.DSGiangVienDuKienDefault)
						console.log("Có lỗi xảy ra trong quá trình thêm")
					}
				});
			},
			validateAddCouncil() {
				let flag = false
				this.dsdetai.forEach(itemDetai => {
					if (itemDetai.HoiDongThanhVienObj_Arr.length !== 0 && itemDetai.HoiDongThanhVienObj_Arr.length < this.dshdchuctrach.length) {
						flag = true
						console.log("itemDetai", itemDetai)
						Vue.$toast.error(`Hội đồng của học viên ${itemDetai.Ho_SV} ${itemDetai.Ten_SV} chưa đủ`, { position: 'top' })
					}
				})
				return flag
			},
			// getTenHocVien(id) {
			// 	let flag = false;
			// 	let tenHocVien = null;
	
			// 	this.dsdetai.find(item => {
			// 		if (item.Student_ID === id) {
			// 			flag = true;
			// 			tenHocVien = item.Ho_SV + " " + item.Ten_SV;
			// 			return true; // Dừng vòng lặp khi tìm thấy phần tử khớp
			// 		}
			// 	});
	
			// 	if (flag) {
			// 		return tenHocVien;
			// 	} else {
			// 		return null;
			// 	}
			// },
			// getGiangVienInfo(gvid, chuctrach, detai) {
			// 	console.table("this.DSGiangVienDuKien", this.DSGiangVienDuKien)
			// 	let giangvienDuKien = this.DSGiangVienDuKien.find(item => item.GiangVienID === gvid)
			// 	console.log("giangvienDuKien xxx", giangvienDuKien)
	
			// 	//kiểm tra xem GV được chọn có phải là GVHD không
			// 	if (gvid !== detai.GiangVienID1 && gvid !== detai.GiangVienID2) {
			// 		for (let i = 0; i < this.dsdetai.length; i++) {
			// 			var itemdetai = this.dsdetai[i]
			// 			// console.log("chuc trach", chuctrach)
			// 			if (itemdetai.Student_ID === detai.Student_ID) {
			// 				giangvienDuKien.ChucTrach = chuctrach.text
			// 				giangvienDuKien.ChucTrachID = chuctrach.value
			// 				console.log("itemdetai", itemdetai)
	
			// 				const existIndex = itemdetai.HoiDongThanhVienObj_Arr.findIndex((item) => item.ChucTrachID === chuctrach.value)
	
			// 				console.log("existIndex", existIndex)
			// 				if (existIndex === -1) {
			// 					itemdetai.HoiDongThanhVienObj_Arr.push(giangvienDuKien);
			// 				}
			// 				else {
			// 					console.log("giangvienDuKien.ChucTrachID", giangvienDuKien.ChucTrachID, itemdetai.HoiDongThanhVienObj_Arr[existIndex].ChucTrachID)
			// 					itemdetai.HoiDongThanhVienObj_Arr[existIndex] = giangvienDuKien
			// 					console.log("itemdetai duplicate", itemdetai)
			// 					if (itemdetai.HoiDongThanhVienObj_Arr[existIndex].ChucTrachID === giangvienDuKien.ChucTrachID) {
			// 						Vue.$toast.warning(`Hãy cẩn thận chọn trùng giảng viên`, { position: 'top' })
	
			// 					}
			// 					else {
			// 						Vue.$toast.error(`Giảng viên ${giangvienDuKien.HoTenHocHamHocVi} đã được chọn trước đó`, { position: 'top' })
			// 					}
			// 				}
			// 			}
			// 		}
			// 		// console.log("this.DSGiangVienDuKien AFTER ->", this.DSGiangVienDuKien)
			// 		// this.DSGiangVienDuKien = [...this.DSGiangVienDuKien, giangvienDuKien]
			// 		// console.log("this.DSGiangVienDuKien BEFORE ->", this.DSGiangVienDuKien)
			// 		// console.log("---------------RESPONE API----------------")
			// 		// this.dsdetai.forEach(itemDetai => {
			// 		// 	console.log("itemDetai", itemDetai.Ten_SV)
			// 		// 	console.log("itemDetai.HoiDongThanhVienObj_Arr", itemDetai.HoiDongThanhVienObj_Arr)
			// 		// 	itemDetai.HoiDongThanhVienObj_Arr.forEach((chuctrach) => {
			// 		// 		console.log("chuc trach->", chuctrach.ChucTrach, chuctrach.HoTenHocHamHocVi, chuctrach.Is_Selected)
			// 		// 	})
			// 		// })
			// 	}
			// 	else {
			// 		giangvienDuKien.Is_Selected = false
			// 		Vue.$toast.error(`Không được chọn GVHD làm thành viên`, { position: 'top' })
			// 	}
			// },
			deleteDeTai(index) {
				if (index !== -1) {
					this.originalData = null
					this.dsdetai.splice(index, 1);
					console.log("this.dsdetai", this.dsdetai)
					this.dsdetai.sort((a, b) => a.STT - b.STT);
				}
			},
			getName(obj) {
				let text = obj.HoTenHocHamHocVi
				return text
			}
		},
	}
</script>
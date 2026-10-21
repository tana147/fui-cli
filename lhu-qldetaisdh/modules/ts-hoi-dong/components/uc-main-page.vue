<template>
	<div>
		<uc-main-view
			:items="DSHoiDongDeTai"
			:he-arr="heArrWithAll"
			:selected-major="major"
			:is-table-ready="isTableReady"
			@update:selected-major="onMajorChange"
			@on-open-excel="isTempDialog = true"
			@on-add-council="addCouncil"
			@on-update-council="onUpdateHoiDong"
			@on-give-sqd="giveSQD"
			@on-input-score="onInputScore"
		/>

		<!-- Add council modal -->
		<uc-modal-add-council
			v-model="isAddDialog"
			:council-config="COUNCIL_CONFIG"
			:edited-item="editedItem"
			:dshoidonggiangvien="DSHoiDongGiangVien"
			:dshdchuctrach="DSHoiDongChucTrach"
			:hearr="heArr"
			@update-nganh-giang-day="getDSGiangVien"
			@on-reload="getHoiDongDeTai"
		/>

		<!-- Give SQD modal -->
		<uc-modal-give-sqd
			v-model="isSQDDialog"
			:thongtinhocvien="dataUpdateHD.HoiDong"
			:edited-item="editedItem"
			:dsgiangvien="dataUpdateHD.GiangVienSelected"
			@on-reload="getHoiDongDeTai"
		/>

		<!-- Update council modal -->
		<uc-modal-update-council
			v-model="isUpdateDialog"
			:council-config="COUNCIL_CONFIG"
			:edited-item="editedItem"
			:dshoidonggiangvien="dataUpdateHD.GiangVienSelected"
			:thongtinhocvien="dataUpdateHD.HoiDong"
			:hearr="heArr"
			@update-nganh-giang-day="getDSGiangVien"
			@on-reload="getHoiDongDeTai"
		/>

		<!-- Excel import council modal -->
		<uc-modal-import-excel
			v-model="isTempDialog"
			:dshoidonggiangvien="DSHoiDongGiangVien"
			:dsdetai="DSHoiDongDeTai"
			:hearr="heArr"
			:dshdchuctrach="DSHoiDongChucTrach"
			@on-reload="getHoiDongDeTai"
		/>

		<!-- Input score modal -->
		<uc-modal-input-score
			v-model="isInputDialog"
			:getdiem="getDiem"
			:edited-item="editedItem"
			:dshoidong-id="dataUpdateHD.HoiDong"
			:dshoidonggiangvien="dataUpdateHD.GiangVienSelected"
			@on-reload="getHoiDongDeTai"
		/>
	</div>
</template>

<script>
	export default {
		name: "uc-main-page",
		data() {
			return {
				isTableReady: false,
				isAddDialog: false,
				isTempDialog: false,
				isSQDDialog: false,
				isUpdateDialog: false,
				isInputDialog: false,
				COUNCIL_CONFIG: {
					DSHoiDongChucTrach: [],
					2: { name: "Chuyên đề 1 NCS", minMembers: 3 },
					3: { name: "Chuyên đề 2 NCS", minMembers: 3 },
					4: { name: "Chuyên đề 3 NCS", minMembers: 3 },
					5: { name: "Luận án TS", minMembers: 5 }
				},
				DSHoiDongGiangVien: [],
				DSHoiDongChucTrach: [],
				DSHoiDongDeTai: [],
				heArr: [],
				major: 0,
				getDiem: [],
				editedItem: {},
				dataUpdateHD: {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				}
			};
		},
		computed: {
			heArrWithAll() {
				return [
					{ Nganh_ID: 0, Ten_Nganh_HienThi: "Tất cả ngành", Ten_Nganh: "Tất cả ngành" },
					...(this.heArr || [])
				];
			}
		},
		watch: {
			DSHoiDongChucTrach(val) {
				this.COUNCIL_CONFIG.DSHoiDongChucTrach = val || [];
			}
		},
		mounted() {
			this.initData();
		},
		methods: {
			async initData() {
				this.isTableReady = false;
				try {
					const [resCT, resNganh] = await Promise.all([
						ajaxCALLPromise("/HoiDong_ChucTrach_Get", { NganhID: 0, LopID: "" }),
						ajaxCALLPromise("/Nganh_Get_ByHeID", { HeID: "N" }),
						this.getDSGiangVien(0)
					]);

					this.DSHoiDongChucTrach = resCT || [];
					this.COUNCIL_CONFIG.DSHoiDongChucTrach = this.DSHoiDongChucTrach;
					this.heArr = resNganh || [];

					await this.getHoiDongDeTai();
				} catch (error) {
					console.error("Error initData:", error);
				} finally {
					this.isTableReady = true;
				}
			},
			async getDSGiangVien(nganhID = 0) {
				try {
					const resGV = await ajaxCALLPromise("/HoiDong_GiangVien_Get", { NganhID: nganhID });
					this.DSHoiDongGiangVien = (resGV || []).map((item, index) => ({
						...item,
						HoTenHocHamHocVi: (item.HocViHocHam ? item.HocViHocHam + ". " : "") + (item.HoTenGiangVien || ""),
						STT: index + 1,
						Is_Chon: item.Is_Chon !== 0
					}));
				} catch (error) {
					console.error("Error getDSGiangVien:", error);
				}
			},
			async getHoiDongDeTai() {
				this.isTableReady = false;
				try {
					const resDT = await ajaxCALLPromise("/HoiDong_DeTai_Get", {
						NganhID: this.major ? parseInt(this.major) : 0,
						BacDaoTao: "TS"
					});

					// Nhóm theo Student_ID để tạo Ma trận đa hội đồng (Phương án 2)
					const studentMap = {};
					(resDT || []).forEach((row) => {
						const sid = row.Student_ID;
						if (!studentMap[sid]) {
							studentMap[sid] = {
								...row,
								councils: {
									2: null,
									3: null,
									4: null,
									5: null
								}
							};
						}

						const loai = parseInt(row.LoaiHoiDong);
						if ([2, 3, 4, 5].includes(loai) && row.HoiDongID) {
							studentMap[sid].councils[loai] = {
								HoiDongID: row.HoiDongID,
								LoaiHoiDong: loai,
								Decision_ID: row.Decision_ID,
								Decision_SoQD: row.Decision_SoQD,
								Decision_NgayQD: row.Decision_NgayQD,
								Decision_ThangQD: row.Decision_ThangQD,
								Decision_NamQD: row.Decision_NamQD,
								DiemHoiDong: row.DiemHoiDong,
								KetQuaHoiDong: row.KetQuaHoiDong,
								HoiDong_Status: row.HoiDong_Status,
								ThoiGianBaoVe: row.ThoiGianBaoVe,
								NhanXet: row.NhanXet
							};
						}
					});

					this.DSHoiDongDeTai = Object.values(studentMap).map((item, index) => ({
						...item,
						stt: index + 1,
						HoTenMaSV: `${item.Ho_SV || ""} ${item.Ten_SV || ""} ${item.Student_ID || ""} ${item.Lop_ID || ""}`
					}));
				} catch (error) {
					console.error("Error getHoiDongDeTai:", error);
				} finally {
					this.isTableReady = true;
				}
			},
			onMajorChange(val) {
				this.major = val;
				this.getHoiDongDeTai();
			},
			addCouncil({ student, loaiHoiDong }) {
				this.editedItem = {
					...student,
					LoaiHoiDong: loaiHoiDong
				};
				this.isAddDialog = true;
			},
			async onUpdateHoiDong({ student, council, loaiHoiDong }) {
				this.editedItem = {
					...student,
					...council,
					HoiDongID: council.HoiDongID,
					LoaiHoiDong: loaiHoiDong
				};
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				};

				try {
					const res = await ajaxCALLPromise("/HoiDong_Get_ByHoiDongID", {
						HoiDong_ID: council.HoiDongID
					});
					if (!res || !res[0]) return;
					const hoidong = res[0][0];
					const gvSelected = res[1] || [];

					this.dataUpdateHD.HoiDong = hoidong;
					this.dataUpdateHD.GiangVienSelected = gvSelected;

					const tempArr = JSON.parse(
						JSON.stringify(this.DSHoiDongGiangVien.filter((itemGV) => itemGV.NganhID === student.Nganh_ID))
					);

					const resultArr = tempArr.map((itemGV, index) => {
						const matching = (gvSelected || []).find((el) => el.GiangVienID === itemGV.GiangVienID);
						if (matching) {
							matching.Is_Chon = matching.Is_Chon !== 0;
							matching.STT = index + 1;
							return Object.assign({}, itemGV, matching);
						}
						itemGV.STT = index + 1;
						return itemGV;
					});
					this.dataUpdateHD.GiangVienMergeSelected = resultArr;
					this.isUpdateDialog = true;
				} catch (error) {
					console.error("Error onUpdateHoiDong:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				}
			},
			async onInputScore({ student, council, loaiHoiDong }) {
				this.editedItem = {
					...student,
					...council,
					HoiDongID: council.HoiDongID,
					LoaiHoiDong: loaiHoiDong
				};
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				};

				try {
					const [resHD, resDiem] = await Promise.all([
						ajaxCALLPromise("/HoiDong_Get_ByHoiDongID", { HoiDong_ID: council.HoiDongID }),
						ajaxCALLPromise("/HoiDong_GiangVien_Get_Diem", { HoiDongID: council.HoiDongID })
					]);

					if (resHD && resHD[0]) {
						const hoidong = resHD[0][0];
						const gvSelected = (resHD[1] || []).map((itemGV) => ({
							...itemGV,
							HoTenHocHamHocVi: (itemGV.HocViHocHam ? itemGV.HocViHocHam + ". " : "") + (itemGV.HoTenGiangVien || "")
						}));
						this.dataUpdateHD.HoiDong = hoidong;
						this.dataUpdateHD.GiangVienSelected = gvSelected;
						this.dataUpdateHD.GiangVienMergeSelected = gvSelected.map((itemGV) => ({ ...itemGV, Is_Chon: true }));
					}
					this.getDiem = resDiem || [];
					this.isInputDialog = true;
				} catch (error) {
					console.error("Error onInputScore:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				}
			},
			async giveSQD({ student, council, loaiHoiDong }) {
				this.editedItem = {
					...student,
					...council,
					HoiDongID: council.HoiDongID,
					LoaiHoiDong: loaiHoiDong
				};
				this.dataUpdateHD = {
					HoiDong: null,
					GiangVienSelected: null,
					GiangVienMergeSelected: []
				};

				try {
					const res = await ajaxCALLPromise("/HoiDong_Get_ByHoiDongID", {
						HoiDong_ID: council.HoiDongID
					});
					if (res && res[0]) {
						const hoidong = res[0][0];
						const gvSelected = (res[1] || []).map((itemGV) => ({
							...itemGV,
							HoTenHocHamHocVi: (itemGV.HocViHocHam ? itemGV.HocViHocHam + ". " : "") + (itemGV.HoTenGiangVien || "")
						}));
						this.dataUpdateHD.HoiDong = hoidong;
						this.dataUpdateHD.GiangVienSelected = gvSelected;
						this.dataUpdateHD.GiangVienMergeSelected = gvSelected.map((itemGV) => ({ ...itemGV, Is_Chon: true }));
					}
					this.isSQDDialog = true;
				} catch (error) {
					console.error("Error giveSQD:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				}
			}
		}
	}
</script>
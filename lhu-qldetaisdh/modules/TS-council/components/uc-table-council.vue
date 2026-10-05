<template>
	<div>
		<v-row dense>
			<!-- Panel trái: Danh sách giảng viên -->
			<v-col cols="12" md="6">
				<v-card outlined class="rounded-xs d-flex flex-column" height="520">
					<v-card-title class="pa-2 grey lighten-4 d-flex align-center">
						<v-icon small color="primary" class="mr-2">mdi-account-search-outline</v-icon>
						<span class="body-2 font-weight-bold primary--text">Danh sách giảng viên</span>
						<v-spacer></v-spacer>
						<span class="caption text--secondary font-italic font-weight-normal">Bấm (+) để thêm vào HĐ</span>
					</v-card-title>

					<div class="px-2 pt-2">
						<v-row dense align="center">
							<v-col cols="6">
								<v-autocomplete
									v-model="selectNganhID"
									:items="heArrWithAll"
									item-text="Ten_Nganh_HienThi"
									item-value="Nganh_ID"
									outlined
									dense
									hide-details
									label="Ngành giảng dạy"
									placeholder="Tất cả ngành"
									class="rounded-xs"
								/>
							</v-col>
							<v-col cols="6">
								<v-text-field
									v-model="search"
									class="c-underline-search"
									prepend-inner-icon="mdi-magnify"
									label="Tìm theo tên giảng viên..."
									dense
									hide-details
									single-line
									clearable
								/>
							</v-col>
						</v-row>
					</div>

					<v-divider class="mt-2" />

					<v-data-table
						:headers="GiangViengHeaders"
						:items="DSHoiDongFilter"
						item-key="GiangVienID"
						:search="search"
						:items-per-page="50"
						height="390"
						fixed-header
						dense
						class="elevation-0 flex-grow-1"
						no-data-text="Không tìm thấy giảng viên phù hợp"
					>
						<template v-slot:item.STT="{ index }">
							<span class="caption text--secondary">{{ index + 1 }}</span>
						</template>
						<template v-slot:item.HoTenHocHamHocVi="{ item }">
							<div>
								<span
									:class="{
										'text--secondary font-italic': isLecturerSelected(item) || isGVHD(item),
										'font-weight-bold text--primary': !isLecturerSelected(item) && !isGVHD(item)
									}"
								>
									{{ item.HoTenHocHamHocVi }}
								</span>
								<v-chip v-if="isGVHD(item)" x-small color="amber darken-3" outlined label class="ml-1">
									GVHD
								</v-chip>
								<v-chip v-else-if="isLecturerSelected(item)" x-small color="teal" outlined label class="ml-1">
									Đã chọn
								</v-chip>
							</div>
						</template>
						<template v-slot:item.addBtn="{ item }">
							<v-btn
								@click="addGiangVien(item)"
								icon
								small
								color="primary"
								:disabled="isLecturerSelected(item) || isEnoughMembers || isGVHD(item)"
								:title="isGVHD(item) ? 'Không được chọn GVHD vào HĐ' : isEnoughMembers ? 'Hội đồng đã đủ thành viên' : 'Thêm vào hội đồng'"
							>
								<v-icon size="18">mdi-plus-circle-outline</v-icon>
							</v-btn>
						</template>
					</v-data-table>
				</v-card>
			</v-col>

			<!-- Panel phải: Thành viên hội đồng đã chọn -->
			<v-col cols="12" md="6">
				<v-card outlined class="rounded-xs d-flex flex-column" height="520">
					<v-card-title class="pa-2 grey lighten-4 d-flex align-center">
						<v-icon small color="teal" class="mr-2">mdi-account-group-outline</v-icon>
						<span class="body-2 font-weight-bold teal--text text--darken-2">Thành viên hội đồng</span>
						<v-chip
							small
							label
							:color="isEnoughMembers ? 'success' : 'amber darken-2'"
							outlined
							class="ml-2 font-weight-bold"
						>
							Đã chọn: {{ temp.length }} / {{ currentMinMembers }} thành viên
						</v-chip>
						<v-spacer></v-spacer>
						<span class="caption text--secondary font-italic font-weight-normal">Gán chức trách</span>
					</v-card-title>

					<v-divider />

					<v-data-table
						:headers="GiangVienSelectedHeaders"
						:items="temp"
						item-key="GiangVienID"
						class="elevation-0 flex-grow-1"
						height="440"
						fixed-header
						hide-default-footer
						dense
						no-data-text="Chưa có thành viên nào. Hãy bấm (+) ở bảng bên trái để thêm."
					>
						<template v-slot:item.count="{ index }">
							<v-avatar size="20" color="blue-grey lighten-4" class="caption font-weight-bold">
								{{ index + 1 }}
							</v-avatar>
						</template>
						<template v-slot:item.HoTenHocHamHocVi="{ item }">
							<span class="font-weight-bold text--primary">{{ item.HoTenHocHamHocVi }}</span>
						</template>
						<template v-slot:item.ChucTrach="{ item }">
							<v-autocomplete
								outlined
								hide-details
								dense
								class="rounded-xs my-1"
								v-model="item.ChucTrach"
								:items="getAvailableChucTrach(item)"
								item-text="ChucTrach"
								item-value="ChucTrach"
								placeholder="Chọn chức trách..."
								clearable
								color="primary"
								@change="handleChucTrachChange(item)"
							/>
						</template>
						<template v-slot:item.deleteBtn="{ item }">
							<v-btn @click="deleteGiangVien(item)" icon color="error" small title="Xóa khỏi hội đồng">
								<v-icon size="18">mdi-trash-can-outline</v-icon>
							</v-btn>
						</template>
					</v-data-table>
				</v-card>
			</v-col>
		</v-row>
	</div>
</template>

<script>
	export default {
		name: "uc-table-council",
		props: {
			activeCouncilType: {
				type: Number,
				default: 2
			},
			councilConfig: {
				type: Object,
				default: () => ({})
			},
			dshdgiangvien: {
				type: Array,
				default: () => []
			},
			hoidong: {
				type: Object,
				default: () => ({})
			},
			isDialogClosed: {
				type: Boolean,
				default: false
			},
			hearr: {
				type: Array,
				default: () => []
			}
		},
		emits: ["onSelected", "update-nganh-giang-day"],
		data() {
			return {
				search: "",
				DSHoiDongFilter: [],
				temp: [],
				selectNganhID: 0,
				GiangViengHeaders: [
					{ text: "STT", value: "STT", sortable: false, align: "center", width: 45 },
					{ text: "Họ tên giảng viên", value: "HoTenHocHamHocVi", width: 170 },
					{ text: "Ngành giảng dạy", value: "NganhGiangDay", width: 140 },
					{ text: "Cơ quan công tác", value: "CoQuanCongTac" },
					{ text: "Thêm", value: "addBtn", sortable: false, align: "center", width: 50 }
				],
				GiangVienSelectedHeaders: [
					{ text: "STT", value: "count", sortable: false, align: "center", width: 45 },
					{ text: "Họ tên thành viên", value: "HoTenHocHamHocVi", width: 170 },
					{ text: "Cơ quan công tác", value: "CoQuanCongTac" },
					{ text: "Chức trách", value: "ChucTrach", align: "start", sortable: false, width: 190 },
					{ text: "Xóa", value: "deleteBtn", sortable: false, align: "center", width: 50 }
				]
			};
		},
		computed: {
			HoiDong() {
				return this.hoidong || {};
			},
			heArrWithAll() {
				return [
					{ Nganh_ID: 0, Ten_Nganh: "Tất cả ngành", Ten_Nganh_HienThi: "Tất cả ngành" },
					...(this.hearr || [])
				];
			},
			currentMinMembers() {
				return this.activeCouncilType === 5 ? 5 : 3;
			},
			isEnoughMembers() {
				return (this.temp || []).length >= this.currentMinMembers;
			}
		},
		watch: {
			activeCouncilType(val) {
				const maxMembers = val === 5 ? 5 : 3;
				if (this.temp && this.temp.length > maxMembers) {
					this.temp = this.temp.slice(0, maxMembers);
				}
				if (val !== 5 && this.temp) {
					this.temp.forEach((gv) => {
						if (gv.ChucTrach === "Phản biện 2" || gv.ChucTrach === "Ủy viên") {
							gv.ChucTrach = undefined;
						}
					});
				}
				this.$emit("onSelected", this.temp);
			},
			selectNganhID(val) {
				if (val !== undefined && val !== null) {
					this.handleNganhChange(val);
				}
			},
			isDialogClosed: {
				handler(newVal) {
					if (newVal) {
						const nganhId =
							this.HoiDong && this.HoiDong.Nganh_ID !== undefined && this.HoiDong.Nganh_ID !== null
								? parseInt(this.HoiDong.Nganh_ID)
								: 0;
						this.selectNganhID = nganhId;
						this.handleNganhChange(nganhId);

						// Khởi tạo thành viên đã có nếu mở modal Cập nhật
						if (this.dshdgiangvien && Array.isArray(this.dshdgiangvien) && this.dshdgiangvien.length > 0) {
							const assigned = this.dshdgiangvien.filter((item) => item && (item.ChucTrach || item.Is_Chon === true));
							this.temp = JSON.parse(JSON.stringify(assigned)).map((item) => ({
								...item,
								HoTenHocHamHocVi:
									item.HoTenHocHamHocVi ||
									`${item.HocViHocHam ? item.HocViHocHam + ". " : ""}${item.HoTenGiangVien || ""}`
							}));
							this.$emit("onSelected", this.temp);
						} else {
							this.temp = [];
						}
					} else {
						this.temp = [];
					}
				},
				immediate: true
			}
		},
		mounted() {
			const nganhId =
				this.HoiDong && this.HoiDong.Nganh_ID !== undefined && this.HoiDong.Nganh_ID !== null
					? parseInt(this.HoiDong.Nganh_ID)
					: 0;
			this.selectNganhID = nganhId;
			this.handleNganhChange(nganhId);
		},
		methods: {
			getAvailableChucTrach(item) {
				let baseList = [];
				if (this.activeCouncilType === 5) {
					baseList = [
						{ ChucTrach: "Chủ tịch" },
						{ ChucTrach: "Phản biện 1" },
						{ ChucTrach: "Phản biện 2" },
						{ ChucTrach: "Ủy viên" },
						{ ChucTrach: "Thư ký" }
					];
				} else {
					baseList = [
						{ ChucTrach: "Chủ tịch" },
						{ ChucTrach: "Phản biện 1" },
						{ ChucTrach: "Thư ký" }
					];
				}

				const selectedByOthers = (this.temp || [])
					.filter((gv) => gv.GiangVienID !== item.GiangVienID && gv.ChucTrach)
					.map((gv) => gv.ChucTrach);

				return baseList.filter((ct) => !selectedByOthers.includes(ct.ChucTrach));
			},
			async handleNganhChange(val) {
				const numVal = parseInt(val) || 0;
				this.$emit("update-nganh-giang-day", numVal);
				try {
					const res = await ajaxCALLPromise("/HoiDong_GiangVien_Get", { NganhID: numVal });
					this.DSHoiDongFilter = (res || []).map((item, index) => ({
						...item,
						STT: index + 1,
						HoTenHocHamHocVi: `${item.HocViHocHam ? item.HocViHocHam + ". " : ""}${item.HoTenGiangVien || ""}`
					}));
				} catch (error) {
					console.error("Error to call HoiDong_GiangVien_Get:", error);
				}
			},
			deleteGiangVien(item) {
				const index = this.temp.indexOf(item);
				if (index !== -1) {
					this.temp.splice(index, 1);
					this.$emit("onSelected", this.temp);
				}
			},
			addGiangVien(item) {
				const { GiangVienID } = item;
				const { GiangVienID1, GiangVienID2 } = this.HoiDong || {};

				const isDuplicate = this.temp.some((gv) => gv.GiangVienID === GiangVienID);
				const minMembers = this.activeCouncilType === 5 ? 5 : 3;
				const isOverLimit = this.temp.length >= minMembers;
				const isGVHD = GiangVienID === GiangVienID1 || GiangVienID === GiangVienID2;

				if (isDuplicate) {
					Vue.$toast.error("Giảng viên này đã được chọn", { position: "top" });
					return;
				}

				if (isOverLimit) {
					Vue.$toast.error(`Hội đồng đã đủ ${minMembers} thành viên`, { position: "top" });
					return;
				}

				if (isGVHD) {
					Vue.$toast.error("Không được chọn GVHD làm thành viên hội đồng", { position: "top" });
					return;
				}

				this.temp.push({ ...item, ChucTrach: undefined });
				this.$emit("onSelected", this.temp);
			},
			handleChucTrachChange(item) {
				this.$emit("onSelected", this.temp);
			},
			isLecturerSelected(item) {
				return (this.temp || []).some((gv) => gv.GiangVienID === item.GiangVienID);
			},
			isGVHD(item) {
				const gvId = item.GiangVienID;
				return !!(this.HoiDong && (gvId === this.HoiDong.GiangVienID1 || gvId === this.HoiDong.GiangVienID2));
			}
		}
	}
</script>
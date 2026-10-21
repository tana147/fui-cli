<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="pa-3">
			<v-row dense align="center">
				<v-col cols="12" sm="3" md="2">
					<v-autocomplete
						v-model="majorModel"
						:items="heArr"
						item-text="Ten_Nganh_HienThi"
						item-value="Nganh_ID"
						outlined
						dense
						hide-details
						label="Lọc theo ngành"
						placeholder="Tất cả ngành"
						class="rounded-xs"
					/>
				</v-col>

				<v-col cols="12" sm="3" md="2">
					<v-select
						v-model="stageFilter"
						:items="dsStageFilter"
						item-text="name"
						item-value="id"
						outlined
						dense
						hide-details
						label="Giai đoạn HĐ"
						class="rounded-xs"
					/>
				</v-col>

				<v-col cols="12" sm="3" md="2">
					<v-select
						v-model="statusFilter"
						:items="dsStatusFilter"
						item-text="name"
						item-value="id"
						outlined
						dense
						hide-details
						label="Trạng thái"
						class="rounded-xs"
					/>
				</v-col>

				<v-col cols="12" sm="3" md="2" class="d-flex align-center">
					<v-btn color="success" class="rounded-xs" depressed @click="$emit('on-open-excel')">
						<v-icon left small>mdi-file-excel-box</v-icon>
						Lập HĐ bằng Excel
					</v-btn>
				</v-col>

				<v-col cols="12" sm="12" md="4" class="d-flex align-center">
					<v-btn
						icon
						color="success"
						class="mr-2"
						:loading="isLoadingExport"
						@click="onPrintExcel"
						title="Xuất file Excel"
					>
						<v-icon>mdi-microsoft-excel</v-icon>
					</v-btn>
					<v-text-field
						v-model="searchText"
						class="c-underline-search flex-grow-1"
						label="Tìm kiếm nhanh NCS, đề tài..."
						dense
						hide-details
						single-line
						clearable
						prepend-inner-icon="mdi-magnify"
					/>
				</v-col>
			</v-row>
		</v-card-title>

		<v-divider />

		<v-data-table
			:headers="tableHeaders"
			:items="filteredItems"
			:search="searchText"
			:loading="!isTableReady"
			height="calc(100vh - 210px)"
			fixed-header
			dense
			:items-per-page="50"
			:footer-props="{ 'items-per-page-options': [25, 50, 100, -1] }"
			class="elevation-0 rounded-xs"
		>
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu học viên Tiến sĩ" />
			</template>

			<template v-slot:no-results>
				<c-empty-state text="Không tìm thấy kết quả phù hợp" />
			</template>

			<template v-slot:item.stt="{ item, index }">
				<span>{{ item.stt || (index + 1) }}</span>
			</template>

			<template v-slot:item.Student_ID="{ item }">
				<div class="py-1">
					<span class="primary--text font-weight-bold">{{ item.Ho_SV }} {{ item.Ten_SV }}</span>
					<br />
					<span class="font-weight-medium">{{ item.Student_ID }}</span>
					<span v-if="item.Lop_ID" class="amber--text text--darken-3 font-weight-medium"> [{{ item.Lop_ID }}]</span>
				</div>
			</template>

			<template v-slot:item.Ten_Nganh="{ item }">
				<span class="text-caption font-weight-medium">{{ item.Ten_Nganh }}</span>
			</template>

			<template v-slot:item.Thesis_Name="{ item }">
				<div class="py-1 text-body-2 font-weight-medium text--primary" style="max-width: 320px;">
					{{ item.Thesis_Name }}
				</div>
			</template>

			<template v-slot:item.Thesises_Prof1="{ item }">
				<div class="py-1 text-caption" style="max-width: 220px;">
					<div class="font-weight-medium text--primary">{{ item.Thesises_Prof1 || '-' }}</div>
					<div v-if="item.Thesises_Prof2" class="text--secondary">{{ item.Thesises_Prof2 }}</div>
				</div>
			</template>

			<!-- Ma trận các Hội đồng (Phương án 2) -->
			<template v-slot:item.CouncilsMatrix="{ item }">
				<div class="d-flex align-center flex-wrap py-1" style="gap: 4px;">
					<template v-for="stage in visibleStages">
						<!-- Trường hợp: Đã lập hội đồng -->
						<v-menu
							v-if="item.councils && item.councils[stage.id]"
							:key="'menu-' + stage.id"
							offset-y
							open-on-hover
							close-on-content-click
						>
							<template v-slot:activator="{ on, attrs }">
								<v-chip
									v-bind="attrs"
									v-on="on"
									small
									label
									:color="stage.color"
									:outlined="!item.councils[stage.id].DiemHoiDong"
									:class="item.councils[stage.id].DiemHoiDong ? 'white--text font-weight-bold cursor-pointer' : 'font-weight-bold cursor-pointer'"
								>
									<v-icon left x-small>
										{{
											item.councils[stage.id].DiemHoiDong
												? 'mdi-check-circle'
												: item.councils[stage.id].Decision_SoQD
												? 'mdi-file-certificate'
												: 'mdi-account-group'
										}}
									</v-icon>
									{{ stage.shortName }}:
									<span v-if="item.councils[stage.id].DiemHoiDong" class="ml-1 font-weight-black">
										{{ item.councils[stage.id].DiemHoiDong }}đ
									</span>
									<span v-else-if="item.councils[stage.id].Decision_SoQD" class="ml-1">
										{{ item.councils[stage.id].Decision_SoQD }}
									</span>
									<span v-else class="ml-1">Đã lập</span>
									<v-icon right x-small>mdi-menu-down</v-icon>
								</v-chip>
							</template>

							<v-list dense class="py-1">
								<v-subheader class="text-caption font-weight-bold py-0" style="height: 26px;">
									{{ stage.fullName }} (Tối thiểu {{ stage.minMembers }} thành viên)
								</v-subheader>
								<v-list-item
									@click="
										$emit('on-update-council', {
											student: item,
											council: item.councils[stage.id],
											loaiHoiDong: stage.id
										})
									"
								>
									<v-list-item-icon class="mr-2 my-1">
										<v-icon small color="cyan darken-2">mdi-account-edit-outline</v-icon>
									</v-list-item-icon>
									<v-list-item-content class="py-1">
										<v-list-item-title class="caption">Xem & Sửa thành viên HĐ</v-list-item-title>
									</v-list-item-content>
								</v-list-item>

								<v-list-item
									@click="
										$emit('on-give-sqd', {
											student: item,
											council: item.councils[stage.id],
											loaiHoiDong: stage.id
										})
									"
								>
									<v-list-item-icon class="mr-2 my-1">
										<v-icon small color="purple">mdi-file-document-edit-outline</v-icon>
									</v-list-item-icon>
									<v-list-item-content class="py-1">
										<v-list-item-title class="caption">
											{{
												item.councils[stage.id].Decision_SoQD
													? `Số QĐ: ${item.councils[stage.id].Decision_SoQD}`
													: 'Cập nhật Số QĐ'
											}}
										</v-list-item-title>
									</v-list-item-content>
								</v-list-item>

								<v-list-item
									@click="
										$emit('on-input-score', {
											student: item,
											council: item.councils[stage.id],
											loaiHoiDong: stage.id
										})
									"
								>
									<v-list-item-icon class="mr-2 my-1">
										<v-icon small color="teal">mdi-star-outline</v-icon>
									</v-list-item-icon>
									<v-list-item-content class="py-1">
										<v-list-item-title class="caption">
											{{
												item.councils[stage.id].DiemHoiDong
													? `Điểm TB: ${item.councils[stage.id].DiemHoiDong}`
													: 'Nhập điểm & Biên bản'
											}}
										</v-list-item-title>
									</v-list-item-content>
								</v-list-item>
							</v-list>
						</v-menu>

						<!-- Trường hợp: Chưa lập hội đồng -->
						<v-btn
							v-else
							:key="'btn-' + stage.id"
							x-small
							outlined
							color="grey darken-1"
							class="rounded-xs font-weight-medium ma-0"
							@click="$emit('on-add-council', { student: item, loaiHoiDong: stage.id })"
							title="Bấm để lập hội đồng cho giai đoạn này"
						>
							<v-icon left x-small>mdi-plus</v-icon>
							{{ stage.shortName }}
						</v-btn>
					</template>
				</div>
			</template>
		</v-data-table>
	</v-card>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			items: {
				type: Array,
				default: () => []
			},
			heArr: {
				type: Array,
				default: () => []
			},
			selectedMajor: {
				type: [Number, String],
				default: 0
			},
			isTableReady: {
				type: Boolean,
				default: false
			}
		},
		emits: [
			"update:selected-major",
			"on-open-excel",
			"on-add-council",
			"on-update-council",
			"on-give-sqd",
			"on-input-score"
		],
		data() {
			return {
				searchText: "",
				stageFilter: 0,
				statusFilter: 0,
				isLoadingExport: false,
				councilStages: [
					{ id: 2, shortName: "CĐ 1", fullName: "Chuyên đề 1", color: "blue", minMembers: 3 },
					{ id: 3, shortName: "CĐ 2", fullName: "Chuyên đề 2", color: "teal", minMembers: 3 },
					{ id: 4, shortName: "CĐ 3", fullName: "Chuyên đề 3", color: "indigo", minMembers: 3 },
					{ id: 5, shortName: "Luận án", fullName: "Luận án Tiến sĩ", color: "deep-purple", minMembers: 5 }
				],
				dsStageFilter: [
					{ id: 0, name: "Tất cả giai đoạn" },
					{ id: 2, name: "Chuyên đề 1" },
					{ id: 3, name: "Chuyên đề 2" },
					{ id: 4, name: "Chuyên đề 3" },
					{ id: 5, name: "Luận án TS" }
				],
				dsStatusFilter: [
					{ id: 0, name: "Tất cả trạng thái" },
					{ id: 1, name: "Đã có ít nhất 1 HĐ" },
					{ id: 2, name: "Chưa có HĐ nào" },
					{ id: 3, name: "Đủ 4 hội đồng" },
					{ id: 4, name: "Có HĐ chờ điểm" }
				],
				tableHeaders: [
					{ title: "STT", text: "STT", value: "stt", width: 50, sortable: false, align: "center" },
					{ title: "Học viên", text: "Học viên", value: "Student_ID", width: 170 },
					{ title: "Ngành", text: "Ngành", value: "Ten_Nganh", width: 130 },
					{ title: "Tên đề tài / Luận án", text: "Tên đề tài / Luận án", value: "Thesis_Name" },
					{ title: "GVHD", text: "GVHD", value: "Thesises_Prof1", width: 170 },
					{
						title: "Tiến độ Hội đồng (CĐ1 • CĐ2 • CĐ3 • Luận án)",
						text: "Tiến độ Hội đồng (CĐ1 • CĐ2 • CĐ3 • Luận án)",
						value: "CouncilsMatrix",
						width: 420,
						sortable: false
					}
				]
			};
		},
		computed: {
			majorModel: {
				get() {
					return this.selectedMajor;
				},
				set(val) {
					this.$emit("update:selected-major", val);
				}
			},
			visibleStages() {
				if (!this.stageFilter || this.stageFilter === 0) {
					return this.councilStages;
				}
				return this.councilStages.filter((s) => s.id === this.stageFilter);
			},
			filteredItems() {
				let list = this.items || [];

				if (this.stageFilter > 0) {
					// Lọc các NCS có liên quan đến giai đoạn này nếu lọc thêm trạng thái
					if (this.statusFilter === 1) {
						list = list.filter((item) => item.councils && item.councils[this.stageFilter]);
					} else if (this.statusFilter === 2) {
						list = list.filter((item) => !item.councils || !item.councils[this.stageFilter]);
					}
				} else {
					if (this.statusFilter === 1) {
						list = list.filter(
							(item) => item.councils && Object.values(item.councils).some((c) => c !== null)
						);
					} else if (this.statusFilter === 2) {
						list = list.filter(
							(item) => !item.councils || Object.values(item.councils).every((c) => c === null)
						);
					} else if (this.statusFilter === 3) {
						list = list.filter(
							(item) => item.councils && [2, 3, 4, 5].every((id) => item.councils[id] !== null)
						);
					} else if (this.statusFilter === 4) {
						list = list.filter(
							(item) =>
								item.councils &&
								Object.values(item.councils).some((c) => c !== null && !c.DiemHoiDong)
						);
					}
				}

				return list;
			}
		},
		methods: {
			onPrintExcel() {
				this.isLoadingExport = true;
				try {
					const dataExport = (this.filteredItems || []).map((item, index) => {
						const c2 = (item.councils && item.councils[2]) || {};
						const c3 = (item.councils && item.councils[3]) || {};
						const c4 = (item.councils && item.councils[4]) || {};
						const c5 = (item.councils && item.councils[5]) || {};

						return {
							STT: index + 1,
							MaNCS: item.Student_ID,
							HoTen: `${item.Ho_SV || ""} ${item.Ten_SV || ""}`.trim(),
							Lop: item.Lop_ID || "",
							Nganh: item.Ten_Nganh || "",
							TenDeTai: item.Thesis_Name || "",
							GVHD1: item.Thesises_Prof1 || "",
							GVHD2: item.Thesises_Prof2 || "",
							CD1_TrangThai: c2.HoiDongID ? "Đã lập" : "Chưa lập",
							CD1_SoQD: c2.Decision_SoQD || "",
							CD1_Diem: c2.DiemHoiDong || "",
							CD2_TrangThai: c3.HoiDongID ? "Đã lập" : "Chưa lập",
							CD2_SoQD: c3.Decision_SoQD || "",
							CD2_Diem: c3.DiemHoiDong || "",
							CD3_TrangThai: c4.HoiDongID ? "Đã lập" : "Chưa lập",
							CD3_SoQD: c4.Decision_SoQD || "",
							CD3_Diem: c4.DiemHoiDong || "",
							LuanAn_TrangThai: c5.HoiDongID ? "Đã lập" : "Chưa lập",
							LuanAn_SoQD: c5.Decision_SoQD || "",
							LuanAn_Diem: c5.DiemHoiDong || ""
						};
					});

					jsonToExcel({
						data: dataExport,
						filename: "Tien_Do_Hoi_Dong_Tien_Si.xlsx",
						worksheet: "HoiDongNCS"
					});
					Vue.$toast.success("Xuất file Excel ma trận hội đồng thành công", { position: "top" });
				} catch (err) {
					console.error("Export Excel error:", err);
					Vue.$toast.error("Có lỗi khi xuất file Excel", { position: "top" });
				} finally {
					this.isLoadingExport = false;
				}
			}
		}
	}
</script>
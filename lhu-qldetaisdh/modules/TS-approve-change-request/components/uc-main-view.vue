<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden;">
		<v-row class="mb-2 align-center shrink pt-2">
			<v-col cols="12" md="5">
				<v-select :items="heArr" label="Lọc theo ngành" outlined dense v-model="major" multiple small-chips
					item-text="TenNganh" item-value="NganhID" hide-details />
			</v-col>
			<v-col cols="12" md="7" class="d-flex align-center">
				<v-btn @click="applyLocalFilters" color="primary" class="mr-2">
					<v-icon left>mdi-filter</v-icon> Lọc
				</v-btn>
				<!-- Tạm ẩn chức năng In QĐ Đổi/Điều chỉnh -->
				<!-- <v-btn color="success" @click="isPrintModalOpen = true">
					<v-icon left>mdi-printer</v-icon> In QĐ Đổi/Điều chỉnh
				</v-btn> -->
			</v-col>
		</v-row>

		<v-data-table :headers="headerTable" :items="dsFlowStatusFilter" :search="search"
			:custom-filter="customSearchFilter" dense :items-per-page="-1"
			hide-default-footer class="elevation-1 flex-grow-1"
			fixed-header height="calc(100vh - 220px)" style="border: 1px solid #dbe7ee !important;">
			<template v-slot:top>
				<v-toolbar flat dense color="transparent">
					<v-toolbar-title class="subtitle-1 font-weight-bold">{{ labelTable }}</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm nhanh..."
						single-line hide-details dense class="c-underline-search" style="max-width: 300px;" />
				</v-toolbar>
			</template>

			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu yêu cầu đổi đề tài" />
			</template>

			<template v-slot:no-results>
				<c-empty-state text="Không tìm thấy kết quả phù hợp" />
			</template>
			<template v-slot:item.Student_ID="{ item }">
				<div class="py-1">
					<span class="primary--text font-weight-bold">{{ item.Student_Name }}</span><br />
					<span class="font-weight-bold">{{ item.Student_ID }}</span>
					<span class="amber--text text--darken-4"> [{{ item.Class_ID }}]</span>
				</div>
			</template>
			<template v-slot:item.action="{ item }">
				<v-btn text color="success" small @click="onSelectStudent(item)">
					Xem chi tiết
				</v-btn>
			</template>
		</v-data-table>

		<!-- <uc-modal-print-qd v-model="isPrintModalOpen" /> -->
	</div>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			dsFlowStatus: {
				type: Array,
				default: () => [],
			},
		},
		emits: ["on-select-student", "on-filter-nganh"],
		data() {
			return {
				isPrintModalOpen: false,
				heArr: [],
				dsFlowStatusFilter: [],
				search: "",
				major: [0],
				headerTable: [
					{ text: "STT", value: "STT", align: "center", width: "70px" },
					{ text: "Học viên", value: "Student_ID" },
					{ text: "Bước", value: "Task_Name" },
					{ text: "Chọn", value: "action", align: "center", sortable: false, width: "120px" },
				],
			};
		},
		computed: {
			labelTable() {
				return `Danh sách yêu cầu đổi đề tài (${this.dsFlowStatusFilter.length})`;
			},
		},
		watch: {
			dsFlowStatus: function () {
				this.applyLocalFilters();
			},
			major: function (newVal, oldVal) {
				if (!newVal || newVal.length === 0) {
					this.major = [0];
					return;
				}
				const hadZero = oldVal?.includes(0) || oldVal?.includes("0");
				const hasZero = newVal.includes(0) || newVal.includes("0");

				if (!hadZero && hasZero) {
					this.major = [0];
				} else if (hadZero && hasZero && newVal.length > 1) {
					this.major = newVal.filter((x) => x !== 0 && x !== "0");
				}
			},
		},
		mounted() {
			this.fetchHeNganh();
		},
		methods: {
			applyLocalFilters() {
				const isAllMajor = this.major.includes(0) || this.major.includes("0");
				this.dsFlowStatusFilter = this.dsFlowStatus.filter((item) => {
					let checkNganh = true;
					if (!isAllMajor) {
						const itemNganhId = item.Nganh_ID ?? item.NganhID;
						checkNganh = this.major.some(
							(m) => String(m) === String(itemNganhId)
						);
					}
					return checkNganh;
				});

				this.dsFlowStatusFilter.forEach((item, index) => {
					item.STT = index + 1;
				});
			},
			customSearchFilter(value, search, item) {
				if (!search) return true;
				const s = String(search).toLowerCase();
				const name = String(item.Student_Name || "").toLowerCase();
				const id = String(item.Student_ID || "").toLowerCase();
				const cls = String(item.Class_ID || item.LopID || "").toLowerCase();
				const task = String(item.Task_Name || "").toLowerCase();
				return name.includes(s) || id.includes(s) || cls.includes(s) || task.includes(s);
			},
			onSelectStudent(item) {
				this.$emit("on-select-student", item);
			},
			async fetchHeNganh() {
				try {
					const res = await ajaxCALLPromise('/Nganh_Get_ByHeID', { HeID: 'N' });
					const allListObj = {
						NganhID: 0,
						TenNganh: "- Tất cả -",
					};
					const mapped = (res || []).map((item) => ({
						...item,
						NganhID: item.Nganh_ID,
						TenNganh: item.Ten_Nganh_HienThi || item.Ten_Nganh,
					}));
					mapped.unshift(allListObj);
					this.heArr = mapped;
				} catch (error) {
					console.error("Lỗi khi tải danh sách ngành Tiến sĩ", error);
				}
			},
		},
	}
</script>
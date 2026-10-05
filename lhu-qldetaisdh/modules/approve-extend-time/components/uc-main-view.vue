<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<v-row class="mb-2 shrink">
			<v-col cols="8">
				<v-select
					:items="heArr"
					label="Lọc theo ngành"
					outlined
					dense
					v-model="major"
					multiple
					small-chips
					item-text="TenNganh"
					item-value="NganhID"
					hide-details
					no-data-text="Vui lòng chọn hệ đào tạo"
				/>
			</v-col>
			<v-col cols="4" class="d-flex align-start">
				<v-btn @click="applyLocalFilters" color="primary">
					<v-icon left>mdi-filter</v-icon>
					Lọc
				</v-btn>
			</v-col>
		</v-row>

		<v-data-table
			:headers="headerTable"
			:items="DSFlowStatusFilter"
			:search="search"
			dense
			:items-per-page="-1"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }"
			class="elevation-1 flex-grow-1"
			fixed-header
			height="calc(100vh - 250px)"
			style="border: 1px solid #dbe7ee !important;"
		>
			<template v-slot:top>
				<v-toolbar flat dense color="transparent">
					<v-toolbar-title class="subtitle-1 font-weight-bold">
						Danh sách đề tài ({{ DSFlowStatusFilter.length }})
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-text-field
						v-model="search"
						prepend-inner-icon="mdi-magnify"
						label="Tìm kiếm nhanh..."
						single-line
						hide-details
						dense
						class="c-underline-search"
						style="max-width: 250px;"
					/>
				</v-toolbar>
			</template>

			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu" />
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
				<v-btn text color="success" small @click="selectStudent(item)">
					Xem chi tiết
				</v-btn>
			</template>
		</v-data-table>
	</div>
</template>

<script>
	export default {
		name: "uc-main-view",
	props: {
		dsFlowStatus: {
			type: Array,
			default: () => []
		},
		selectedStudent: {
			type: Object,
			default: null
		}
	},
	emits: ['on-select-student', 'on-reload'],
	data() {
		return {
			heArr: [],
			major: [0],
			search: '',
			DSFlowStatusFilter: [],
			headerTable: [
				{
					text: 'STT',
					value: 'STT',
					align: 'center',
					width: '60px',
				},
				{
					text: 'Học viên',
					value: 'Student_ID',
				},
				{
					text: 'Bước',
					value: 'Task_Name',
				},
				{
					text: 'Chọn',
					value: 'action',
					align: 'center',
					sortable: false,
					width: '110px',
				},
			],
		};
	},
	async mounted() {
		await this.getHeByID();
	},
	watch: {
		dsFlowStatus: {
			handler() {
				this.applyLocalFilters();
			},
			immediate: true
		},
		major(newVal, oldVal) {
			if (!newVal || newVal.length === 0) {
				this.major = [0];
				return;
			}
			const hadZero = oldVal?.includes(0) || oldVal?.includes('0');
			const hasZero = newVal.includes(0) || newVal.includes('0');

			if (!hadZero && hasZero) {
				this.major = [0];
			} else if (hadZero && hasZero && newVal.length > 1) {
				this.major = newVal.filter((x) => x !== 0 && x !== '0');
			}
		},
	},
	methods: {
		applyLocalFilters() {
			let dsFlow = this.dsFlowStatus || [];
			this.DSFlowStatusFilter = dsFlow.filter((item) => {
				let checkNganh = false;
				if (this.major.includes(0) || this.major.includes('0') || this.major.length === 0) {
					checkNganh = true;
				} else {
					let itemNganhID = item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major;
					checkNganh = this.major.some((m) => String(m) === String(itemNganhID));
				}
				return checkNganh;
			});

			this.DSFlowStatusFilter.forEach((item, index) => {
				item.STT = index + 1;
			});
		},
		selectStudent(item) {
			this.$emit('on-select-student', item);
		},
		async getHeByID() {
			this.heArr = await getNganhCaoHocPromise({ hasAllOption: true });
		},
	},
	}
</script>
<template>
	<v-card
		flat
		:outlined="bordered"
		class="rounded-xs mb-2 pa-3 grey lighten-5"
	>
		<!-- Header tiêu chí -->
		<div class="d-flex align-center justify-space-between mb-2">
			<div class="d-flex align-center">
				<v-avatar v-if="index !== undefined && index !== null" size="20" color="primary" class="white--text text-caption font-weight-bold mr-2">
					{{ typeof index === 'number' ? (index + 1) : index }}
				</v-avatar>
				<span class="text-body-2 font-weight-bold grey--text text--darken-3">
					{{ item.Task_Detail_Description || 'Tiêu chí' }}
				</span>
			</div>
			<v-chip v-if="showType && item.Task_Detail_Type" x-small outlined color="grey darken-1" class="font-weight-medium text-uppercase">
				{{ typeLabel }}
			</v-chip>
		</div>

		<!-- Nội dung theo kiểu dữ liệu -->
		<div :class="index !== undefined && index !== null ? 'pl-6' : ''">
			<!-- File đính kèm -->
			<div v-if="item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW'">
				<c-chip-file
					v-if="item.File_ID"
					:file-id="item.File_ID"
					:url="fileUrl"
					:label="item.File_Name"
				/>
				<v-chip v-else color="grey lighten-2" class="grey--text text--darken-2" small label>
					<v-icon left x-small>mdi-file-outline</v-icon>
					Chưa có file đính kèm
				</v-chip>
			</div>

			<!-- Điểm số -->
			<div v-else-if="item.Task_Detail_Type === 'DIEM' || item.Task_Detail_Type === 'FORMULAR'" class="d-flex align-center">
				<v-chip color="success" outlined class="font-weight-bold px-3" small>
					<v-icon left small>mdi-numeric</v-icon>
					Điểm: {{ item.Text_Content || '—' }}
				</v-chip>
				<span v-if="item.Data_Exp" class="text-caption grey--text text--darken-1 ml-2">
					Công thức: {{ item.Data_Exp }}
				</span>
			</div>

			<!-- Checkbox xác nhận -->
			<div v-else-if="item.Task_Detail_Type === 'CHECKBOX'" class="d-flex align-center">
				<v-chip
					v-if="isChecked"
					color="success"
					small
					class="white--text font-weight-medium"
				>
					<v-icon left small>mdi-check-circle</v-icon>
					Đã xác nhận / Hoàn thành
				</v-chip>
				<v-chip v-else color="grey lighten-2" class="grey--text text--darken-2" small label>
					<v-icon left small>mdi-close-circle-outline</v-icon>
					Chưa xác nhận
				</v-chip>
			</div>

			<!-- Ngày tháng -->
			<div v-else-if="item.Task_Detail_Type === 'DATE' || item.Task_Detail_Type === 'DATEVIEW'" class="d-flex align-center">
				<v-chip color="blue-grey lighten-5" class="blue-grey--text text--darken-3 font-weight-medium" small label>
					<v-icon left small color="primary">mdi-calendar-clock</v-icon>
					{{ formattedDate || 'Chưa cập nhật' }}
				</v-chip>
			</div>

			<!-- Ghi chú / Textarea -->
			<div v-else-if="item.Task_Detail_Type === 'TEXTAREA' || item.Task_Detail_Type === 'TEXTAREAVIEW' || item.Task_Detail_Type === 'TEXTAREA | FUN'">
				<v-card flat outlined class="pa-2 white rounded-xs">
					<div class="text-body-2 grey--text text--darken-4">
						{{ item.Text_Content || 'Không có nội dung ghi chú' }}
					</div>
				</v-card>
			</div>

			<!-- Text mặc định -->
			<div v-else>
				<v-card flat outlined class="pa-2 white rounded-xs">
					<div class="text-body-2 grey--text text--darken-4 font-weight-medium">
						{{ item.Text_Content || '—' }}
					</div>
				</v-card>
			</div>
		</div>
	</v-card>
</template>

<script>
	export default {
		name: "c-detail-item-view",
		props: {
			item: {
				type: Object,
				default: () => ({}),
			},
			index: {
				type: [Number, String],
				default: null,
			},
			showType: {
				type: Boolean,
				default: true,
			},
			bordered: {
				type: Boolean,
				default: true,
			},
		},
		computed: {
			fileUrl() {
				const baseUrl = window.vueData?.v_Set?.urlReadFile || ""
				return this.item.File_URL ? `${baseUrl}${this.item.File_URL}` : ""
			},
			isChecked() {
				const val = this.item.Text_Content
				return val === "True" || val === true || val === "1" || val === 1
			},
			typeLabel() {
				switch (this.item.Task_Detail_Type) {
					case "FILE":
					case "FILEVIEW":
						return "File đính kèm"
					case "DIEM":
					case "FORMULAR":
						return "Điểm đánh giá"
					case "CHECKBOX":
						return "Xác nhận"
					case "DATE":
					case "DATEVIEW":
						return "Ngày tháng"
					case "TEXTAREA":
					case "TEXTAREAVIEW":
					case "TEXTAREA | FUN":
						return "Ghi chú"
					default:
						return "Thông tin"
				}
			},
			formattedDate() {
				const val = this.item.Text_Content
				if (!val) return ""
				if (typeof moment !== "undefined") {
					const m = moment(val)
					if (m.isValid()) return m.format("DD/MM/YYYY")
				}
				return val
			},
		},
	}
</script>
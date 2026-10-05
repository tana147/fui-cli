<template>
	<v-card class="mb-4 pa-4 rounded-sm elevation-1">
		<v-row align="center">
			<v-col cols="12" sm="4" md="3">
				<v-select :items="dsNam" :model-value="selectedYear"
					@update:model-value="$emit('on-year-change', $event)" label="Chọn năm học" dense outlined
					hide-details prepend-inner-icon="mdi-calendar-range" />
			</v-col>
			<v-col cols="12" sm="8" md="9" class="d-flex flex-wrap align-center">
				<v-btn color="primary" depressed class="mr-2 my-1" @click="$emit('on-get-summary')">
					<v-icon left>mdi-file-eye-outline</v-icon>
					Xem trước báo cáo
				</v-btn>

				<v-btn color="error" depressed class="mr-2 my-1" :disabled="!hasData" @click="$emit('on-submit')">
					<v-icon left>mdi-lock-outline</v-icon>
					Thực hiện chốt sổ
				</v-btn>

				<v-btn color="success" depressed class="mr-2 my-1" :disabled="!hasData" @click="$emit('on-export')">
					<v-icon left>mdi-file-export-outline</v-icon>
					Xuất báo cáo PDF
				</v-btn>

				<v-btn color="success" depressed class="my-1" :disabled="!hasData" @click="$emit('on-export-excel')">
					<v-icon left>mdi-file-excel-outline</v-icon>
					Xuất báo cáo Excel
				</v-btn>
			</v-col>
		</v-row>
	</v-card>
</template>

<script>
	export default {
		name: "uc-topbar",
	props: {
		selectedYear: {
			type: [Number, String],
			default: null
		},
		dsNam: {
			type: Array,
			default: () => []
		},
		hasData: {
			type: Boolean,
			default: false
		}
	},
	emits: ["on-year-change", "on-get-summary", "on-submit", "on-export","on-export-excel"]
	}
</script>
<template>
	<v-dialog v-model="value" width="96vw" max-width="96vw" persistent scrollable eager>
		<v-card outlined class="rounded-xs">
			<v-card-title class="py-2 px-4 primary white--text d-flex align-center">
				<span class="text-subtitle-1 font-weight-bold">{{ title }}</span>
				<v-spacer></v-spacer>
				<v-btn icon dark small @click="$emit('input', false)">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-divider></v-divider>
			<v-card-text class="pa-3 black--text overflow-hidden">
				<slot name="renderBody"></slot>
			</v-card-text>
			<v-divider></v-divider>
			<v-card-actions class="px-4 py-2">
				<v-spacer></v-spacer>
				<v-btn v-if="isExcel" icon color="success" class="mr-2"
					@click="onExportExcel"
					title="Xuất file Excel">
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-btn text small color="grey darken-1" @click="$emit('input', false)">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
		value: {
			type: Boolean
		},
		isExcel: {
			type: Boolean,
			default: false
		},
		dialog: {
			type: Boolean,
			default: false
		},
		title: {
			type: String,
			default: ""
		},
		itemToExcel: null
	},
	methods: {
		onExportExcel() {
			jsonToExcel({
				data: this.itemToExcel || [],
				filename: (this.title || "Export") + ".xlsx"
			})
		}
	}
	}
</script>
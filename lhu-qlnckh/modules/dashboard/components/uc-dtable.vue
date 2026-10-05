<template>
	<v-card outlined class="rounded-xs">
		<v-card-title class="py-2 px-3 d-flex align-center flex-wrap">
			<span v-if="showTitle && title" class="text-subtitle-2 font-weight-bold primary--text">{{ title }}</span>
			<v-spacer></v-spacer>
			<v-btn icon color="success" class="mr-2" @click="onPrintExcel" title="Xuất file Excel">
				<v-icon>mdi-microsoft-excel</v-icon>
			</v-btn>
			<v-text-field v-if="isSearch" v-model="search" label="Tìm kiếm..." single-line dense hide-details clearable
				prepend-inner-icon="mdi-magnify" class="c-underline-search dashboard-search-field"></v-text-field>
		</v-card-title>
		<v-divider></v-divider>
		<v-card-text class="pa-0">
			<v-data-table v-model="selectedItems" v-bind="$attrs" :items="items" :headers="headers" :search="search"
				:show-select="isSelect" :item-key="itemKey" dense fixed-header
				:height="tableHeight || 'calc(100vh - 320px)'" :items-per-page="50"
				:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
				<template v-for="(_, slot) of $scopedSlots" v-slot:[slot]="scope">
					<slot v-bind="scope" :name="slot" />
				</template>
				<template v-slot:item.actions="{ item }">
					<v-tooltip left color="success">
						<template v-slot:activator="{ on }">
							<v-btn @click="$emit('editItem', item)" v-on="on" x-small fab icon>
								<v-icon color="green darken-2">mdi-square-edit-outline</v-icon>
							</v-btn>
						</template>
						<span>Sửa</span>
					</v-tooltip>
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: [
		"value",
		"title",
		"showTitle",
		"tableHeight",
		"isExcel",
		"editItem",
		"isSearch",
		"items",
		"headers",
		"isSelect",
		"itemKey"
	],
	data() {
		return {
			search: ""
		}
	},
	computed: {
		selectedItems: {
			get() {
				return Array.isArray(this.value) ? this.value : []
			},
			set(val) {
				this.$emit("input", val)
			}
		}
	},
	methods: {
		onPrintExcel() {
			const exportData = (Array.isArray(this.value) && this.value.length > 0) ? this.value : (this.items || [])
			jsonToExcel({
				data: exportData,
				filename: (this.title || "Danh-sach") + ".xlsx"
			})
		}
	}
	}
</script>
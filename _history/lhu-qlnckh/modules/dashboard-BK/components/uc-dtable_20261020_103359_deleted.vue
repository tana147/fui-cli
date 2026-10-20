<template>
	<v-card :style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}"
		:dark="vueData.mode">
		<v-card-title :class="vueData.mode ? 'white--text' : 'primary--text'">
			{{title}}
			<v-spacer></v-spacer>
			<v-spacer></v-spacer>
			<v-spacer></v-spacer>
			<uc-excel-btn @click="jsonToExcel({data : value.length === 0 ? items : value})"></uc-excel-btn>
			<v-text-field v-if="isSearch" v-model="search" label="Tìm kiếm" single-line dense hide-details
				prepend-icon="mdi-filter-outline"></v-text-field>
		</v-card-title>
		<v-card-text>
			<v-data-table v-model="value" v-bind="$attrs" :items="items" :headers="headers"
				:style="{'background-color': vueData.mode ? vueData.colorMode.dark.tertiary : 'white'}" :search="search"
				:show-select="isSelect" :item-key="itemKey">
				<template v-for="(_, slot) of $scopedSlots" v-slot:[slot]="scope">
					<slot v-bind="scope" :name="slot" />
				</template>
				<template v-slot:item.actions="{item}">
					<v-tooltip left color="success">
						<template v-slot:activator="{ on, attrs }">
							<v-btn @click="$emit('editItem', item)" v-on="on" x-small fab icon>
								<v-icon
									:color="vueData.mode ? 'white' : 'green darken-2'">mdi-square-edit-outline</v-icon>
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
		props: ["value", "title", "isExcel", "editItem", "isSearch", "items", "headers", "isSelect", "itemKey"],
		data() {
			return {
				search: "",
			}
		},
		mounted() { },
		computed: {},
		watch: {
			value: {
				handler: function (val) {
					console.log('vale', val)
				}, deep: true
			}
		},
		methods: {},
	}
</script>
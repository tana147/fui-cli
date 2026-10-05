<template>
	<v-card>
		<v-card-title  >
			<span :class="classLabel">{{ label }}</span>
			<v-spacer></v-spacer>
			<v-spacer></v-spacer>
			<v-text-field v-if="isSearch === true" v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm"
				hide-details dense ></v-text-field> 
			<v-btn v-if="isNew === true" fab outlined small color="primary" dark @click="dialog = true"
			:style="{'margin-right': '15px'}"
			>
				<v-icon>mdi-plus</v-icon>
			</v-btn>
		</v-card-title>
		<v-data-table :headers="headers" :items="items" class="elevation-1" :search="search" v-bind="$attrs"
			loading-text="Đang tải dữ liệu..." no-data-text="Không có dữ liệu...">
			<!-- 
				:custom-filter="(value, search, item) => {
				const tenSearch = xulyDauLower(item.Ten)
				const tendeTaiSearch = xulyDauLower(item.Ten)
				? true : false
				console.log('item ->',item);
				return false;
				}" 
			-->
			<!-- Custom actions -->
			<template v-slot:item.actions="{ item }">
				<div>
					<v-tooltip left color="warning">
						<template v-slot:activator="{ on, attrs }">
							<v-btn @click="deleteItem(item)" v-on="on" x-small fab icon>
								<v-icon color="red darken-3">mdi-trash-can-outline</v-icon>
							</v-btn>
						</template>
						<span>Xóa</span>
					</v-tooltip>
					<v-tooltip left color="success" v-if="isEdit ===true">
						<template v-slot:activator="{ on, attrs }">
							<v-btn @click="editItem(item)" v-on="on" x-small fab icon>
								<v-icon color="green darken-2">mdi-square-edit-outline</v-icon>
							</v-btn>
						</template>
						<span>Sửa</span>
					</v-tooltip>
				</div>
			</template>
			<!-- custom row -->
			<template v-for="(_, slot) of $scopedSlots" v-slot:[slot]="scope">
				<slot v-bind="scope" :name="slot" />
			</template>
		</v-data-table>
		<v-dialog v-model="dialog" :max-width="widthDialog" persistent>
			<v-card>
				<v-card-title>
					<p>{{ formTitle }}</p>
					<v-spacer></v-spacer>
					<v-icon @click="closeDialog">mdi-close</v-icon>
				</v-card-title>
				<v-card-text>
					<v-form ref="form" v-model="valid" v-if="data.isInitBeforeEditView">
						<slot name="renderForm" :editedItem="data.editedItem"> </slot>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="closeDialog">Đóng</v-btn>
					<v-btn @click="onSubmit"> Thêm</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-card>
</template>

<script>
	export default {
		name: "c-table",
		props: {
			label: {
				type: String,
				required: true,
			},
			classLabel: {
				type: String,
				default: "primary--text",
			},
			headers: {
				type: Array,
			},
			items: {
				type: Array,
			},
			defaultItem: {
				type: Object,
				require: true
			},
			onFinishDelete: {
				type: Function,
			},
			onFinishEdit: {
				type: Function,
			},
			isNew: {
				type: Boolean,
				default: true,
			},
			isEdit: {
				type: Boolean,
				default: true,
			},
			widthDialog: {
				type: Number,
				default: 1028
			},
			isSearch: {
				type: Boolean,
				default: false,
			},
			initBeforeEditView: {
				type: Function,
			},
		},
		data() {
			return {
				search: "",
				valid: null,
				dialog: false,
				data: {
					isInitBeforeEditView: false,
					editedIndex: -1,
					editedItem: this.defaultItem,
				}
			};
		},
		mounted() { },
		computed: {
			formTitle() {
				return this.data.editedIndex === -1 ? "New Item" : "Edit Item";
			},
		},
		watch: {
			isNew: function (val) {
				console.log("isNew", val)
			},
			'data.isInitBeforeEditView': function (val) {
				if (val) {
					console.log("ROW ->", this.data.editedItem)
					this.dialog = true
				}
				console.log("opendialog...", val)
			},
			'data.editedIndex': function (val) {
				console.log('val index', val)
			}
		},
		methods: {
			async editItem(item) {
				this.data.editedItem = Object.assign({}, item);
				this.data.editedIndex = this.items.indexOf(item);
				this.$emit("initBeforeEditView", this.data)
			},
			deleteItem(item) {
				this.data.editedIndex = this.items.indexOf(item);
				this.$emit("onFinishDelete", item);
			},
			closeDialog() {
				this.data.editedIndex = -1;
				this.data.editedItem = Object.assign({}, this.defaultItem);
				this.dialog = false;
				console.log("data when close dialog->", this.data.editedItem)
				this.$refs.form.reset();
			},
			onSubmit() {
				let valid = this.$refs.form.validate();
				if (valid) {
					this.$emit("onFinishEdit", this.data.editedItem);
				}
			},
		},
	}
</script>
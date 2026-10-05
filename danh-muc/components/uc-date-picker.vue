<template>
	<v-menu v-model="menu" :close-on-content-click="false" offset-y :max-width="maxWidth" :min-width="minWidth">
		<template v-slot:activator="{ props }">
			<v-text-field :rules="rules" :label="label" :color="color" v-model="computedDateFormatted"
				v-bind="{ ...props, class: [customClass, props.class] }" append-inner-icon="mdi-calendar-month" readonly
				@click:append-inner="props.onClick" icon-color="true" :disabled="disabled">
			</v-text-field>
		</template>
		<v-date-picker hide-header first-day-of-week=1 :color="color" ref="myPicker" v-model="date" :min="min"
			:max="max" v-bind="picker" @update:model-value="change" :disabled="disabled">
		</v-date-picker>
	</v-menu>
</template>

<script>
export default {
	props: {
		iconColor: { type: String },
		min: {
			type: String,
			default: ''
		},
		max: {
			type: String,
			default: ''
		},
		disabled: {
			type: Boolean,
			default: false,
		},
		class: {
			type: String,
		},
		maxWidth: {
			type: String,
			default: "290px"
		},
		minWidth: {
			type: String,
			default: "290px"
		},
		label: {
			type: String,
			default: "",
		},
		modelValue: {
			type: [String, Date],
			default: null,
		},
		color: {
			type: String,
			default: "primary"
		},
		picker: {
			type: Object,
			default: () => ({}),
		},
		birthday: {
			type: Boolean,
			default: false,
		},
		dateAdd: {
			type: [Number, String],
			default: undefined,
		},
		action: {
			type: [String, Function],
			default: null,
		},
		rules: {
			type: Object,
			default: () => ({
				required: value => !!value || "Không được để trống"
			})
		},
	},
	data() {
		return {
			date: this.dateDef(this.modelValue), // Trả về đối tượng Date
			menu: false,
			locale: 'vi',
			messages: {
				vi: {
					// ...defaultVi,
					datePicker: {
						// ...defaultVi.datePicker,
						header: 'Chọn ngày',
					},
					input: {
						// ...defaultVi.input,
						appendAction: 'Chọn',
					},
				},
			},
		};
	},
	computed: {
		customClass() {
			return this.class || '';
		},
		computedDateFormatted: {
			get() {
				if (!this.date) return null;
				const d = this.date instanceof Date ? this.date : new Date(this.date);
				const year = d.getFullYear();
				const month = String(d.getMonth() + 1).padStart(2, '0');
				const day = String(d.getDate()).padStart(2, '0');
				return `${day}/${month}/${year}`;
			},
			set(newValue) {
				if (!newValue) {
					this.date = null;
					return;
				}
				const [day, month, year] = newValue.split('/').map(Number);
				this.date = new Date(year, month - 1, day);
			},
		},
	},
	watch: {
		menu(val) {
			if (this.birthday && val) {
				this.$nextTick(() => {
					this.$refs.myPicker.activePicker = 'year';
				});
			}
		},
		modelValue(newValue) {
			this.date = this.dateDef(newValue);
		},
	},
	methods: {
		change(date) {
			this.menu = false;

			if (!date) {
				this.date = null;
				this.$emit('update:model-value', null);
				return;
			}

			// Chuyển đổi ngày thành đối tượng Date
			const selectedDate = new Date(date);

			// Lấy phần ngày (bỏ thời gian và múi giờ)
			const year = selectedDate.getFullYear();
			const month = String(selectedDate.getMonth() + 1).padStart(2, '0');
			const day = String(selectedDate.getDate()).padStart(2, '0');
			const dateString = `${year}-${month}-${day}`; // Định dạng yyyy-MM-dd

			// Cập nhật this.date để đồng bộ với v-date-picker
			this.date = new Date(year, selectedDate.getMonth(), day);

			// Emit giá trị dưới dạng chuỗi yyyy-MM-dd để insert vào database
			this.$emit('update:model-value', dateString);
		},
		dateDef(modelValue) {
			if (modelValue) {
				const d = modelValue instanceof Date ? modelValue : new Date(modelValue);
				if (isNaN(d.getTime())) return null;
				return d;
			} else if (this.dateAdd !== undefined) {
				const today = new Date();
				today.setDate(today.getDate() + parseInt(this.dateAdd));
				return today;
			}
			return null;
		},
		runAction(action) {
			if (typeof action === 'function') {
				action();
			} else if (typeof action === 'string') {
				this.$emit(action, this.date);
			}
		},
	},
}
</script>
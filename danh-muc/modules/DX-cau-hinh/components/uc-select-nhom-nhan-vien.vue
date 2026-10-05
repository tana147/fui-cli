<template>
	<v-autocomplete v-model="internalValue" v-model:search="search" :items="items"
		:variant="isUnderlined ? 'underlined' : 'outlined'" :menu-icon="isDropdownIcon ? 'mdi-menu-down' : null"
		:placeholder="placeholder" :label="label" :clearable="isClearable"
		:hide-details="isHideDetail" :loading="loading" item-title="title" item-value="value"
		return-object autocomplete="off" density="compact" hide-no-data multiple chips closable-chips
		:custom-filter="customFilter">
        <template v-slot:chip="{ props, item, index }">
            <v-chip v-if="index < 2" v-bind="props" size="small" :text="item.raw.title"></v-chip>
            <span v-if="index === 2" class="text-caption text-grey ml-1">
                (+{{ internalValue.length - 2 }} nhóm)
            </span>
        </template>
    </v-autocomplete>
</template>

<script>
export default {
	props: {
		modelValue: {
			type: Array,
			default: () => [],
		},
		initValue: {
			type: Array,
			default: () => [],
		},
		isUnderlined: { type: Boolean, default: false },
		isDropdownIcon: { type: Boolean, default: false },
		placeholder: { type: String, default: 'Chọn nhóm nhân viên...' },
		label: { type: String, default: '' },
		isClearable: { type: Boolean, default: true },
		isHideDetail: { type: Boolean, default: true },
	},

	emits: ['update:modelValue'],

	data() {
		return {
			loading: false,
			items: [],
			search: null,
			isSelecting: false,
		}
	},

	computed: {
		internalValue: {
			get() {
				// return mảng các object đã chọn phù hợp với các ID trong modelValue
                if (!this.modelValue) return [];
				return this.items.filter((item) => this.modelValue.includes(item.value));
			},

			set(val) {
				this.isSelecting = true

				// emit ra ngoài mảng array chỉ chứa ID
                const emitVals = val ? val.map(i => i.value) : [];
				this.$emit('update:modelValue', emitVals);

				this.$nextTick(() => {
					this.isSelecting = false
				})
			},
		},
	},

	watch: {
		// 🔹 init hiển thị lại
		initValue: {
			immediate: true,
			handler(val) {
				if (!val || val.length === 0) return
				this.isSelecting = true

				this.items = [...val] 
				this.$emit('update:modelValue', val.map(i => i.value))

				this.$nextTick(() => {
					this.isSelecting = false
				})
			},
		},

		search(val) {
			if (this.isSelecting) return
		},
	},
    mounted() {
        this.loadAll();
    },

	methods: {
		loadAll() {
			this.loading = true
			apiCall(
				'/work/HR_NhomNhanVien_Select',
				null, 
				(res) => {
                    const rawData = res?.data || res || [];
					const resultItems = rawData.map((item) => ({
						...item,
						title: `[${item.MaNhom}] ${item.TenNhom}`,
						value: item.NhomNhanVien_Id,
					}));

                    const selectedItems = this.items.filter(i => this.modelValue && this.modelValue.includes(i.value));
                    const map = new Map();
                    [...selectedItems, ...resultItems].forEach(item => map.set(item.value, item));
                    this.items = Array.from(map.values());

					this.loading = false
				},
				() => { this.loading = false }
			)
		},
		customFilter(value, query, item) {
			if (!query) return true;
			const text = `[${item.raw.MaNhom}] ${item.raw.TenNhom}`.toLowerCase();
			return text.includes(query.toLowerCase());
		},
	},
}
</script>

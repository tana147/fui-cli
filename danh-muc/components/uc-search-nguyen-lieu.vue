<template>
	<v-autocomplete v-model="internalValue" v-model:search="search" :items="items"
		:variant="isUnderlined ? 'underlined' : 'outlined'" :menu-icon="isDropdownIcon ? 'mdi-menu-down' : null"
		:placeholder="placeholder" :label="label" :clearable="isClearable ? true : false"
		:hide-details="isHideDetail ? true : false" dense :loading="loading" item-title="title" item-value="value"
		return-object autocomplete="off" density="compact" hide-no-data />
</template>

<script>
export default {
	props: {
		modelValue: {
			type: Number,
			default: null,
		},
		initValue: {
			type: Object,
			default: null,
		},
		isUnderlined: {
			type: Boolean,
			default: false,
		},
		isDropdownIcon: {
			type: Boolean,
			default: false,
		},
		placeholder: {
			type: String,
			default: 'Nhập mã hoặc tên hàng hóa...',
		},
		label: {
			type: String,
			default: 'Chọn hàng hóa',
		},
		isClearable: {
			type: Boolean,
			default: false,
		},
		isHideDetail: {
			type: Boolean,
			default: true,
		},
		loaiNguyenLieu: {
			type: String,
			default: '',
		},
		loaiHangHoa: {
			type: String,
			default: '',
		},
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
				// tìm object tương ứng với ID
				return this.items.find((item) => item.value === this.modelValue) || null
			},

			set(val) {
				this.isSelecting = true

				// 👈 emit ra ngoài chỉ ID
				this.$emit('update:modelValue', val ? val.value : null)

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
				if (!val) return
				this.isSelecting = true

				this.items = [val] // 👈 object phải nằm trong items
				this.search = val.title // 👈 text hiển thị

				this.$emit('update:modelValue', val.value)

				this.$nextTick(() => {
					this.isSelecting = false
				})
			},
		},

		search(val) {
			if (this.isSelecting) return

			if (!val) {
				this.items = []
				return
			}

			this.querySelections(val)
		},
	},

	methods: {
		querySelections(keyword) {
			const $this = this
			this.loading = true

			setTimeout(() => {
				if (keyword !== this.search) return

				apiCall(
					'/work/HH_HangHoa_Select_Dropdown',
					{
						TimKiem: keyword.trim(),
						LoaiNguyenLieu: $this.loaiNguyenLieu,
						LoaiHangHoa: $this.loaiHangHoa,
					},
					(res) => {
						this.items = res.data.map((item) => ({
							...item,
							title: `${item.MaNoiBo} - ${item.TenHangHoa}`,
							value: item.HangHoa_Id,
						}))
						this.loading = false
					},
					() => {
						this.loading = false
					},
				)
			}, 500)
		},
	},
}
</script>
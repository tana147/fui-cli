<template>
	<v-autocomplete v-model="internalValue" v-model:search="search" :items="items"
		:variant="isUnderlined ? 'underlined' : 'outlined'" :menu-icon="isDropdownIcon ? 'mdi-menu-down' : null"
		:placeholder="placeholder" :label="label" :clearable="isClearable"
		:hide-details="isHideDetail" :loading="loading" item-title="title" item-value="value"
		return-object autocomplete="off" density="compact" hide-no-data>
    </v-autocomplete>
</template>

<script>
export default {
	props: {
		modelValue: {
			type: [String, Number],
			default: null,
		},
		initValue: {
			type: Object,
			default: null,
		},
		isUnderlined: { type: Boolean, default: false },
		isDropdownIcon: { type: Boolean, default: false },
		placeholder: { type: String, default: 'Nhập mã, tên nhân viên...' },
		label: { type: String, default: '' },
		isClearable: { type: Boolean, default: true },
		isHideDetail: { type: Boolean, default: true },
		autoReset: { type: Boolean, default: false }, // Khi true, sau khi chọn sẽ clear ngay
        // Giữ lại prop của bản cũ
        isQuanLy: { type: Boolean, default: false },
        initData: { type: Array, default: () => [] },
	},

	emits: ['update:modelValue', 'onSelect'],

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
				// Tìm object tương ứng với ID
				return this.items.find((item) => item.value === this.modelValue) || null;
			},

			set(val) {
				if (!val) return;
				this.isSelecting = true

				// emit ID ra ngoài (dùng v-model thông thường)
				this.$emit('update:modelValue', val.value);
				// emit full object ra ngoài để parent dùng trực tiếp không cần gọi thêm API
				this.$emit('onSelect', val);

				// Nếu autoReset=true (chế độ "chọn xong clear"), xoá trắng sau khi chọn
				if (this.autoReset) {
					this.$nextTick(() => {
						this.isSelecting = false; // tắt cờ trước
						this.search = null;        // rồi mới clear → watch sẽ gọi querySelections('')
					})
				} else {
					this.$nextTick(() => { this.isSelecting = false })
				}
			},
		},
	},

	watch: {
		initValue: {
			immediate: true,
			handler(val) {
				if (!val) return
				this.isSelecting = true

				this.items = [val] // object phải nằm trong items
                this.search = val.title || val.text

				this.$emit('update:modelValue', val.value)

				this.$nextTick(() => {
					this.isSelecting = false
				})
			},
		},
        initData: {
			immediate: true,
			handler(val) {
				if (val && val.length > 0 && val[0].value) {
                    this.isSelecting = true
                    const item = { ...val[0], title: val[0].text || val[0].title };
                    
                    this.items = [item] 
                    this.search = item.title

                    this.$emit('update:modelValue', item.value)

                    this.$nextTick(() => {
                        this.isSelecting = false
                    })
                }
			},
		},

		search(val) {
			if (this.isSelecting) return
			// Chỉ gọi API khi có keyword thực sự, tránh pre-load dữ liệu thừa
			if (!val || typeof val !== 'string') return;
			this.querySelections(val)
		},
	},


	methods: {
		querySelections(keyword) {
			this.loading = true

			setTimeout(() => {
				if (keyword !== (this.search || '')) return

				apiCall(
					'/work/HR_NhanVien_Select_Search',
					{
						TimKiem: keyword.trim()
					},
					(res) => {
                        const rawData = res?.data || res || [];
						const resultItems = rawData.map((item) => ({
							...item,
							title: item.MaNhanVien ? `${item.MaNhanVien} - ${item.TenNhanVien}` : item.TenNhanVien,
							value: item.NhanVien_Id,
						}));

                        // Giữ lại item đang được chọn để dropdown không bị rớt binding name
                        const selectedItem = this.items.find(i => i.value === this.modelValue);
                        
                        const map = new Map();
                        if (selectedItem) {
                            map.set(selectedItem.value, selectedItem);
                        }
                        resultItems.forEach(item => map.set(item.value, item));
                        
                        this.items = Array.from(map.values());

						this.loading = false
					},
					(err) => {
						this.loading = false
                        console.error('Lỗi load nhân viên:', err);
					},
				)
			}, 300) // Delay 300ms chống spam thay thế cho _.debounce
		},
	},
}
</script>

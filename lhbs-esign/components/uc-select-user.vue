<template>
	<v-autocomplete v-model="internalValue" :items="items" :loading="loading" item-title="FullName"
		item-value="EmployeeCode" :placeholder="placeholder" :label="label" :disabled="disabled" :readonly="readonly"
		variant="outlined" class="wf-ant-input bg-white mb-2" hide-details="auto" density="compact"
		:clearable="clearable" style="text-align: left; font-size: 10.5px !important;"
		:custom-filter="customSignerFilter" @update:search="onSearchInput" @update:modelValue="onSelectChange"
		:multiple="multiple" :clear-on-select="multiple">
		<template v-slot:selection="{ item }">
			<v-chip v-if="item.value" size="x-small" :style="{
          backgroundColor: '#e8f5e9',
          color: '#2e7d32',
          border: '1px solid #c8e6c9',
          fontSize: '9px',
          height: '18px',
          fontWeight: '700',
          borderRadius: '4px',
          margin: '1px',
          gap: '3px'
        }" class="px-1 d-flex align-center">
				<uc-avatar :name="item.raw ? item.raw.FullName : ''"
					:image="item.raw ? (item.raw.Avatar || item.raw.Photo || item.raw.Image) : ''" :size="14"
					font-size="5px" class="mr-1" />
				{{ item.raw ? item.raw.FullName : (item.title || item.value || '') }}
			</v-chip>
		</template>
		<template v-slot:item="{ props, item }">
			<v-list-item v-bind="props" density="compact" class="py-0.5 min-height-24">
				<template v-slot:prepend="{ isSelected }">
					<v-checkbox-btn :model-value="isSelected" density="compact" color="primary" class="mr-1">
					</v-checkbox-btn>
					<uc-avatar :name="item.raw ? item.raw.FullName : ''"
						:image="item.raw ? (item.raw.Avatar || item.raw.Photo || item.raw.Image) : ''" :size="20"
						font-size="8px" />
				</template>
				<template v-slot:title>
					<span style="font-size: 10.5px !important; font-weight: 600; color: #374151;"
						v-html="highlightText(item.raw ? item.raw.FullName : '', searchQuery)"></span>
				</template>
				<template v-slot:subtitle>
					<span style="font-size: 9.5px !important; color: #94a3b8;">
						<span v-html="highlightText(item.raw ? item.raw.EmployeeCode : '', searchQuery)"></span>
						<span v-if="item.raw && item.raw.DepartmentName"> · {{ item.raw.DepartmentName }}</span>
					</span>
				</template>
			</v-list-item>
		</template>
	</v-autocomplete>
</template>

<script>
	export default {
		name: 'uc-select-user',
  props: {
    modelValue: { type: [String, Number, Array], default: null },
    placeholder: { type: String, default: 'Chọn người dùng...' },
    initData: { type: [Object, Array], default: () => null },
    defaultData: { type: [Object, Array], default: () => null },
    label: { type: String, default: '' },
    disabled: { type: Boolean, default: false },
    readonly: { type: Boolean, default: false },
    multiple: { type: Boolean, default: false },
    clearable: { type: Boolean, default: false }
  },
  data() {
    return {
      internalValue: this.modelValue,
      items: [],
      loading: false,
      searchQuery: '',
      debounceTimer: null
    }
  },
  watch: {
    modelValue(newVal) {
      this.internalValue = newVal
      this.ensureValueInItems()
    },
    internalValue(newVal) {
      this.$emit('update:modelValue', newVal)
      if (this.multiple) {
        const arr = Array.isArray(newVal) ? newVal : (newVal ? [newVal] : [])
        const selectedItems = this.items.filter(item => arr.indexOf(item.EmployeeCode) !== -1)
        this.$emit('change', newVal, selectedItems)
      } else {
        const selectedItem = this.items.find(item => item.EmployeeCode === newVal)
        this.$emit('change', newVal, selectedItem)
      }
    },
    initData: {
      immediate: true,
      handler() {
        this.ensureValueInItems()
      }
    },
    defaultData: {
      immediate: true,
      handler() {
        this.ensureValueInItems()
      }
    }
  },
  created() {
    this.ensureValueInItems()
    this.fetchUsers('')
  },
  methods: {
    ensureValueInItems() {
      const vals = this.multiple
        ? (Array.isArray(this.internalValue) ? this.internalValue : (this.internalValue ? [this.internalValue] : []))
        : (this.internalValue ? [this.internalValue] : [])

      vals.forEach(val => {
        if (!val) return
        const exists = this.items.some(item => item.EmployeeCode === val)
        if (!exists) {
          const findInSource = (source) => {
            if (!source) return null
            if (Array.isArray(source)) {
              return source.find(s => s.EmployeeCode === val || s.value === val)
            }
            if (source.EmployeeCode === val || source.value === val) return source
            return null
          }

          const sourceObj = findInSource(this.initData) || findInSource(this.defaultData)

          if (sourceObj) {
            this.items.push({
              EmployeeCode: val,
              FullName: sourceObj.FullName || sourceObj.title || val,
              Avatar: sourceObj.Avatar || sourceObj.Photo || sourceObj.Image || '',
              DepartmentName: sourceObj.DepartmentName || ''
            })
          } else {
            this.items.push({ EmployeeCode: val, FullName: val })
          }
        }
      })
    },

    // Fix: clear searchQuery ngay sau khi chọn item
    onSelectChange() {
      this.searchQuery = ''
    },

    onSearchInput(searchVal) {
      const q = String(searchVal || '').trim()

      //  Fix: nếu q rỗng (do clear-on-select hoặc blur) thì bỏ qua, không fetch
      if (!q) {
        clearTimeout(this.debounceTimer)
        this.searchQuery = ''
        return
      }

      if (q === this.searchQuery) return

      // Nếu trùng tên người dùng đang được chọn thì bỏ qua
      if (!this.multiple && this.internalValue) {
        const currentItem = this.items.find(item => item.EmployeeCode === this.internalValue)
        if (currentItem && currentItem.FullName === searchVal) return
      } else if (this.multiple && Array.isArray(this.internalValue)) {
        const selectedItems = this.items.filter(item => this.internalValue.includes(item.EmployeeCode))
        const matchesAnyName = selectedItems.some(item => item.FullName === searchVal)
        if (matchesAnyName) return
      }

      this.searchQuery = q

      clearTimeout(this.debounceTimer)
      this.debounceTimer = setTimeout(() => {
        this.fetchUsers(q)
      }, 350)
    },

    async fetchUsers(query) {
      this.loading = true
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_SignerProfile_GetList', { Keyword: query })
          let fetchedItems = Array.isArray(res) ? res : []

          // Giữ lại các item đang được chọn không bị mất sau khi fetch
          const selectedVal = this.internalValue
          if (selectedVal) {
            const vals = this.multiple
              ? (Array.isArray(selectedVal) ? selectedVal : [selectedVal])
              : [selectedVal]

            vals.forEach(val => {
              const foundInFetched = fetchedItems.some(item => item.EmployeeCode === val)
              if (!foundInFetched) {
                const currentItem = this.items.find(item => item.EmployeeCode === val)
                if (currentItem) fetchedItems.unshift(currentItem)
              }
            })
          }

          this.items = fetchedItems
        }
      } catch (err) {
        console.error('Lỗi khi tải danh sách người dùng:', err)
      } finally {
        this.loading = false
      }
    },

    customSignerFilter(value, query, item) {
      if (!query) return true
      const q = String(query).toLowerCase().trim()
      const fullName = String(item && item.raw && item.raw.FullName || '').toLowerCase().trim()
      const empCode = String(item && item.raw && item.raw.EmployeeCode || '').toLowerCase().trim()
      return fullName.indexOf(q) !== -1 || empCode.indexOf(q) !== -1
    },

    highlightText(text, query) {
      if (!text) return ''
      if (!query) return text
      const escapedQuery = String(query).replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
      const regex = new RegExp(`(${escapedQuery})`, 'gi')
      return text.replace(regex, '<mark style="background-color: #fff59d; color: inherit; padding: 0 2px; border-radius: 2px;">$1</mark>')
    }
  }
	}
</script>
<template>
    <v-dialog :modelValue="modelValue" max-width="500" @update:modelValue="onDialogChange">
        <v-card>
            <template v-slot:title>
                {{ isEdit ? 'Cập nhật bộ phận' : 'Thêm mới bộ phận' }}
            </template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </template>

            <v-card-text>
                <v-form ref="refForm">
                    <v-row class="mt-2">
                        <v-col cols="12">
                            <v-text-field v-model="formData.TenBoPhan" label="Tên bộ phận" required autofocus
                                :rules="[rules.required]" variant="outlined" density="comfortable" />
                        </v-col>

                        <v-col cols="12">
                            <v-textarea v-model="formData.MoTaNhiemVu" label="Mô tả nhiệm vụ" required
                                :rules="[rules.required]" rows="3" auto-grow variant="outlined" density="comfortable" />
                        </v-col>

                        <v-col cols="12" md="6">
                            <v-switch v-model="formData.Is_NhieuDiaDiem" :true-value="1" :false-value="0"
                                color="primary" inset label="Áp dụng nhiều địa điểm" hide-details />
                        </v-col>

                        <v-col cols="12" md="6">
                            <v-select v-model="formData.TinhTrang" label="Tình trạng" :items="statusOptions"
                                item-title="label" item-value="value" variant="outlined" density="comfortable" />
                        </v-col>
                    </v-row>
                </v-form>
            </v-card-text>

            <v-card-actions>
                <v-spacer />
                <v-btn color="default" variant="text" @click="onClose">Hủy</v-btn>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="onSave">
                    Lưu
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
    export default {
  name: 'uc-modal-bo-phan',
  props: {
    modelValue: {
      type: Boolean, 
      required: true,
    },
    boPhanDetail: {
      type: Object,
      default: null,
    },
    isEdit: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:modelValue', 'save'],
  data() {
    return {
      formData: this.createEmptyForm(),
      rules: {
        required: function (value) {
          return !!(value || '').toString().trim() || 'Không được để trống'
        },
      },
      statusOptions: [
        { label: 'Hoạt động', value: 0 },
        { label: 'Tạm khóa', value: 1 },
      ],
    }
  },
  watch: {
    boPhanDetail: {
      handler(val) {
        if (val) {
          this.formData = this.cloneFormData(val)
        } else {
          this.resetForm()
        }
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    createEmptyForm() {
      return {
        BoPhan_Id: null,
        TenBoPhan: '',
        MoTaNhiemVu: '',
        Is_NhieuDiaDiem: 0,
        TinhTrang: 0,
      }
    },
    cloneFormData(source) {
      return {
        BoPhan_Id: source && source.BoPhan_Id ? source.BoPhan_Id : null,
        TenBoPhan: source && source.TenBoPhan ? source.TenBoPhan : '',
        MoTaNhiemVu: source && source.MoTaNhiemVu ? source.MoTaNhiemVu : (source && source.MoTa ? source.MoTa : ''),
        Is_NhieuDiaDiem: Number(source && source.Is_NhieuDiaDiem ? source.Is_NhieuDiaDiem : 0),
        TinhTrang: source && source.TinhTrang !== undefined ? Number(source.TinhTrang) : 0,
      }
    },
    resetForm() {
      this.formData = this.createEmptyForm()
      if (this.$refs.refForm && this.$refs.refForm.resetValidation) {
        this.$refs.refForm.resetValidation()
      }
    },
    onDialogChange(value) {
      this.$emit('update:modelValue', value)
    },
    onClose() {
      this.$emit('update:modelValue', false)
      setTimeout(() => {
        this.resetFormAfterClose()
      }, 300)
    },
    resetFormAfterClose() {
      this.resetForm()
    },
    async onSave() {
      const validation = await this.$refs.refForm.validate()
      if (!validation.valid) { return }
      this.$emit('save', this.cloneFormData(this.formData))
    },
  },
}
</script>
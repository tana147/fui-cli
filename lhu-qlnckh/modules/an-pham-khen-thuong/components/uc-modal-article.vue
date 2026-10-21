<template>
	<v-dialog v-model="dialog" max-width="1500px">
		<v-card>
			<v-card-title class="pa-3 pa-sm-4 d-flex flex-wrap align-center justify-space-between mobile-dialog-title" style="gap: 12px;">
				<span class="text-subtitle-1 text-sm-h5 primary--text font-weight-bold me-auto">{{ formTitle }}</span>
				<div class="d-flex align-center flex-grow-1 flex-sm-grow-0" style="gap: 8px;">
					<v-select class="mobile-dialog-select" v-model="editedItem.AnPhamObj.NhomAnPham" :items="loaiBaiBao"
						item-text="TenLoai" item-value="LoaiID" label="Nhóm ấn phẩm" outlined dense hide-details
						style="min-width: 180px; max-width: 260px;" @change="changeNhomAnPham"></v-select>
					<v-btn fab small icon @click="close" class="mobile-dialog-button-close">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</div>
			</v-card-title>
			<v-card-text class="pa-2 pa-sm-4">
				<uc-form-an-pham ref="FormAnPham" class="mb-5" v-model="editedItem"
					:danh-muc-tap-chi-arr="danhMucTapChiArr" :danh-muc-loai-an-pham-arr="danhMucLoaiAnPhamArr"
					:nam-arr="namArr" :edited-index="editedIndex">
				</uc-form-an-pham>
				<uc-table-tac-gia ref="checkTG" v-model="editedItem.AuthorsObjArr"
					:an-pham-id="editedItem.AnPhamObj.AnPhamID" :tong-tac-gia-lhu="editedItem.AnPhamObj.SoTacGia_LHU"
					:loai-an-pham-id="editedItem.AnPhamObj.LoaiAnPhamID"
					:tong-tac-gia="editedItem.AnPhamObj.TongSoTacGia" :ds-ngan-hang="dsNganHang"
					:an-pham-obj="editedItem.AnPhamObj"></uc-table-tac-gia>
			</v-card-text>

			<v-card-actions class="d-flex flex-wrap pa-3 pa-sm-4" style="gap: 8px;">
				<v-spacer class="d-none d-sm-block"></v-spacer>
				<v-btn @click="close">Đóng</v-btn>
				<v-btn @click="saveTemp" color="primary" v-if="editedIndex === -1" outlined>
					Lưu tạm</v-btn>
				<v-btn @click="save" color="primary" :loading="isLoadingSave"
					v-if="editedItem.AnPhamObj.TrangThaiID !== 3">
					{{ editedIndex === -1 ? "Lưu và gửi đề xuất" : "Cập nhật và lưu tạm" }}</v-btn>
				<v-btn @click="submitProposal" color="success"
					v-if="editedIndex !== -1 && editedItem.AnPhamObj.TrangThaiID !== 3">
					Cập nhật và gửi đề xuất</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-modal-article',
	props: {
		value: { type: Boolean, default: false },
		editedItem: { type: Object, default: () => ({ AnPhamObj: {}, AuthorsObjArr: [], ProofsObjArr: [] }) },
		editedIndex: { type: Number, default: -1 },
		danhMucTapChiArr: { type: Array, default: () => [] },
		danhMucLoaiAnPhamArr: { type: Array, default: () => [] },
		namArr: { type: Array, default: () => [] },
		dsNganHang: { type: Array, default: () => [] },
		isLoadingSave: { type: Boolean, default: false }
	},
	emits: ['input', 'on-close', 'on-save', 'on-save-temp', 'on-submit-proposal', 'on-change-nhom-an-pham'],
	data() {
		return {
			loaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có tham gia đào tạo nghiên cứu sính", LoaiID: 3 }
			]
		}
	},
	computed: {
		dialog: {
			get() { return this.value },
			set(value) { this.$emit('input', value) }
		},
		formTitle() {
			return this.editedIndex === -1 ? 'Thêm mới bài báo' : 'Chi tiết bài báo'
		}
	},
	methods: {
		close() {
			this.$emit('on-close')
		},
		save() {
			this.$emit('on-save')
		},
		saveTemp() {
			this.$emit('on-save-temp')
		},
		submitProposal() {
			this.$emit('on-submit-proposal', this.editedItem.AnPhamObj.AnPhamID)
		},
		changeNhomAnPham() {
			this.$emit('on-change-nhom-an-pham')
		},
		validateForm() {
			return this.$refs.FormAnPham?.$refs.ValidForm.validate()
		},
		resetFormState() {
			if (this.$refs.FormAnPham) {
				this.$refs.FormAnPham.danhMucSubAnPhamArr = []
			}
		},
		getDM_By_LoaiAnPhamID_Edit() {
			return this.$refs.FormAnPham?.getDM_By_LoaiAnPhamID_Edit()
		},
		getTenDMTC_By_LoaiAnPhamID_Edit() {
			return this.$refs.FormAnPham?.getTenDMTC_By_LoaiAnPhamID_Edit()
		}
	}
	}
</script>